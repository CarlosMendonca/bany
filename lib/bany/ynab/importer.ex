defmodule Bany.YNAB.Importer do
  @moduledoc """
  Imports transactions from a YNAB CSV export file.

  The CSV represents a single YNAB budget, which maps to a Plan in Bany.
  Accounts, CategoryGroups, and Categories are created as needed.

  Each row is processed independently — failures do not stop the import.
  Returns a detailed report of what was created and what failed.
  """

  NimbleCSV.define(Bany.YNAB.CSVParser, separator: ",", escape: "\"")

  alias Bany.Repo
  alias Bany.Budget.{Plan, CategoryGroup, Category}
  alias Bany.Ledger.{Account, Transaction, Payee}
  alias Bany.Ledger
  import Ecto.Query

  @doc """
  Imports transactions from a YNAB CSV export file.

  Creates or finds a Plan with the given name, then for each row
  finds-or-creates the Account, CategoryGroup, and Category before
  inserting the Transaction. Each row is processed independently so
  failures do not stop the import.

  Returns `{:ok, report}` where report contains per-entity counts:

      %{
        total_rows: 1115,
        transactions:    %{imported: 1113, failed: [{45, "reason"}, ...]},
        accounts:        %{created: 3,    failed: 0},
        category_groups: %{created: 6,    failed: 0},
        categories:      %{created: 18,   failed: 0}
      }
  """
  def import_csv(file_path, plan_name, user) do
    plan = find_or_create_plan(plan_name)
    Repo.insert_all("user_plans", [%{user_id: user.id, plan_id: plan.id}], on_conflict: :nothing)

    rows =
      file_path
      |> File.stream!()
      |> Bany.YNAB.CSVParser.parse_stream(skip_headers: true)
      |> Enum.to_list()

    {stats, _cache} =
      rows
      |> Enum.with_index(1)
      |> Enum.reduce({initial_stats(length(rows)), empty_cache()}, fn {row, row_num},
                                                                       {stats, cache} ->
        case import_row(row, plan, user, cache, stats) do
          {:ok, new_cache, new_stats} ->
            {new_stats, new_cache}

          {:error, reason, cache, stats} ->
            stats = update_in(stats.transactions.failed, &[{row_num, reason} | &1])
            {stats, cache}
        end
      end)

    stats = update_in(stats.transactions.failed, &Enum.reverse/1)
    {:ok, stats}
  end

  defp initial_stats(total_rows) do
    %{
      total_rows: total_rows,
      transactions: %{imported: 0, failed: []},
      accounts: %{created: 0, failed: 0},
      category_groups: %{created: 0, failed: 0},
      categories: %{created: 0, failed: 0}
    }
  end

  defp empty_cache, do: %{accounts: %{}, groups: %{}, categories: %{}, payees: %{}}

  defp import_row(row, plan, user, cache, stats) do
    try do
      [account_name, _flag, date_str, payee_name, _combined, group_name, category_name, memo,
       outflow_str, inflow_str, _cleared] = row

      with {:ok, account, cache, stats} <- find_or_create_account(account_name, plan, user, cache, stats),
           {:ok, category_id, cache, stats} <-
             resolve_category(group_name, category_name, plan, cache, stats),
           {payee_id, cache} <- resolve_payee(payee_name, cache) do
        case Repo.insert(%Transaction{
               date: parse_date(date_str),
               memo: memo,
               amount: parse_amount(inflow_str, outflow_str),
               account_id: account.id,
               category_id: category_id,
               payee_id: payee_id
             }) do
          {:ok, _} ->
            {:ok, cache, update_in(stats.transactions.imported, &(&1 + 1))}

          {:error, changeset} ->
            {:error, format_changeset_errors(changeset), cache, stats}
        end
      end
    rescue
      e -> {:error, Exception.message(e), cache, stats}
    end
  end

  defp resolve_payee("", cache), do: {nil, cache}

  defp resolve_payee(name, cache) do
    case Map.get(cache.payees, name) do
      nil ->
        payee = Ledger.find_or_create_payee_by_name(name)
        id = if payee, do: payee.id, else: nil
        {id, put_in(cache, [:payees, name], id)}

      id ->
        {id, cache}
    end
  end

  defp resolve_category("", _category_name, _plan, cache, stats), do: {:ok, nil, cache, stats}
  defp resolve_category(_group_name, "", _plan, cache, stats), do: {:ok, nil, cache, stats}

  defp resolve_category(group_name, category_name, plan, cache, stats) do
    with {:ok, group, cache, stats} <- find_or_create_category_group(group_name, plan, cache, stats),
         {:ok, category, cache, stats} <- find_or_create_category(category_name, group, plan, cache, stats) do
      {:ok, category.id, cache, stats}
    end
  end

  defp find_or_create_plan(name) do
    case Repo.get_by(Plan, name: name) do
      nil ->
        case Repo.insert(Plan.changeset(%Plan{}, %{name: name})) do
          {:ok, plan} -> plan
          {:error, changeset} -> raise "failed to create plan: #{format_changeset_errors(changeset)}"
        end

      plan ->
        plan
    end
  end

  defp find_or_create_account(name, plan, user, cache, stats) do
    case Map.get(cache.accounts, name) do
      nil ->
        case Repo.get_by(Account, name: name) do
          nil ->
            case Repo.insert(Account.changeset(%Account{}, %{name: name})) do
              {:ok, acc} ->
                Repo.insert_all("plan_accounts", [%{plan_id: plan.id, account_id: acc.id}], on_conflict: :nothing)
                Repo.insert_all("user_accounts", [%{user_id: user.id, account_id: acc.id}], on_conflict: :nothing)
                cache = put_in(cache, [:accounts, name], acc)
                stats = update_in(stats.accounts.created, &(&1 + 1))
                {:ok, acc, cache, stats}

              {:error, _changeset} ->
                stats = update_in(stats.accounts.failed, &(&1 + 1))
                {:error, "failed to create account \"#{name}\"", cache, stats}
            end

          acc ->
            Repo.insert_all("plan_accounts", [%{plan_id: plan.id, account_id: acc.id}], on_conflict: :nothing)
            Repo.insert_all("user_accounts", [%{user_id: user.id, account_id: acc.id}], on_conflict: :nothing)
            {:ok, acc, put_in(cache, [:accounts, name], acc), stats}
        end

      account ->
        {:ok, account, cache, stats}
    end
  end

  defp find_or_create_category_group(name, plan, cache, stats) do
    cache_key = {name, plan.id}

    case Map.get(cache.groups, cache_key) do
      nil ->
        case Repo.get_by(CategoryGroup, name: name, plan_id: plan.id) do
          nil ->
            case Repo.insert(CategoryGroup.changeset(%CategoryGroup{}, %{name: name, plan_id: plan.id})) do
              {:ok, group} ->
                cache = put_in(cache, [:groups, cache_key], group)
                stats = update_in(stats.category_groups.created, &(&1 + 1))
                {:ok, group, cache, stats}

              {:error, _changeset} ->
                stats = update_in(stats.category_groups.failed, &(&1 + 1))
                {:error, "failed to create category group \"#{name}\"", cache, stats}
            end

          group ->
            {:ok, group, put_in(cache, [:groups, cache_key], group), stats}
        end

      group ->
        {:ok, group, cache, stats}
    end
  end

  defp find_or_create_category(name, group, plan, cache, stats) do
    cache_key = {name, group.id}

    case Map.get(cache.categories, cache_key) do
      nil ->
        existing =
          Repo.one(
            from c in Category,
              join: cgc in "category_groups_categories",
              on: cgc.category_id == c.id,
              where: c.name == ^name and cgc.category_group_id == ^group.id,
              limit: 1
          )

        case existing do
          nil ->
            case Repo.insert(Category.changeset(%Category{}, %{name: name})) do
              {:ok, cat} ->
                Repo.insert_all(
                  "category_groups_categories",
                  [%{category_group_id: group.id, category_id: cat.id}],
                  on_conflict: :nothing
                )
                Repo.insert_all("plan_categories", [%{plan_id: plan.id, category_id: cat.id}], on_conflict: :nothing)

                cache = put_in(cache, [:categories, cache_key], cat)
                stats = update_in(stats.categories.created, &(&1 + 1))
                {:ok, cat, cache, stats}

              {:error, _changeset} ->
                stats = update_in(stats.categories.failed, &(&1 + 1))
                {:error, "failed to create category \"#{name}\"", cache, stats}
            end

          cat ->
            Repo.insert_all("plan_categories", [%{plan_id: plan.id, category_id: cat.id}], on_conflict: :nothing)
            {:ok, cat, put_in(cache, [:categories, cache_key], cat), stats}
        end

      category ->
        {:ok, category, cache, stats}
    end
  end

  defp parse_date(date_str) do
    [month, day, year] = String.split(date_str, "/")

    Date.new!(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day)
    )
  end

  defp parse_amount(inflow_str, outflow_str) do
    inflow = parse_money(inflow_str)
    outflow = parse_money(outflow_str)
    Decimal.sub(inflow, outflow)
  end

  defp parse_money(str) do
    str
    |> String.replace("$", "")
    |> String.replace(",", "")
    |> Decimal.new()
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r/%{(\w+)}/, msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join(", ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end
end
