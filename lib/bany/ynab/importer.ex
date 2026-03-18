defmodule Bany.YNAB.Importer do
  @moduledoc """
  Imports transactions from a YNAB CSV export file.

  The CSV represents a single YNAB budget, which maps to a Plan in Bany.
  Accounts, CategoryGroups, and Categories are created as needed.
  """

  NimbleCSV.define(Bany.YNAB.CSVParser, separator: ",", escape: "\"")

  alias Bany.Repo
  alias Bany.Budget.{Plan, CategoryGroup, Category}
  alias Bany.Ledger.{Account, Transaction}
  import Ecto.Query

  @doc """
  Imports transactions from a YNAB CSV export file.

  Creates or finds a Plan with the given name, then for each row
  finds-or-creates the Account, CategoryGroup, and Category before
  inserting the Transaction.

  Returns `{:ok, count}` on success or `{:error, reason}` on failure.
  """
  def import_csv(file_path, plan_name) do
    plan = find_or_create_plan(plan_name)

    rows =
      file_path
      |> File.stream!()
      |> Bany.YNAB.CSVParser.parse_stream(skip_headers: true)
      |> Enum.to_list()

    result =
      Repo.transaction(fn ->
        {count, _cache} =
          Enum.reduce(rows, {0, empty_cache()}, fn row, {count, cache} ->
            [account_name, _flag, date_str, payee, _combined, group_name, category_name, memo,
             outflow_str, inflow_str, _cleared] = row

            {account, cache} = find_or_create_account(account_name, cache)
            {group, cache} = find_or_create_category_group(group_name, plan, cache)
            {category, cache} = find_or_create_category(category_name, group, cache)

            {:ok, _} =
              Repo.insert(%Transaction{
                date: parse_date(date_str),
                payee: payee,
                memo: memo,
                amount: parse_amount(inflow_str, outflow_str),
                account_id: account.id,
                category_id: category.id
              })

            {count + 1, cache}
          end)

        count
      end)

    case result do
      {:ok, count} -> {:ok, count}
      {:error, reason} -> {:error, reason}
    end
  end

  defp empty_cache, do: %{accounts: %{}, groups: %{}, categories: %{}}

  defp find_or_create_plan(name) do
    case Repo.get_by(Plan, name: name) do
      nil ->
        {:ok, plan} = Repo.insert(%Plan{name: name})
        plan

      plan ->
        plan
    end
  end

  defp find_or_create_account(name, cache) do
    case Map.get(cache.accounts, name) do
      nil ->
        account =
          case Repo.get_by(Account, name: name) do
            nil ->
              {:ok, acc} = Repo.insert(%Account{name: name})
              acc

            acc ->
              acc
          end

        {account, put_in(cache, [:accounts, name], account)}

      account ->
        {account, cache}
    end
  end

  defp find_or_create_category_group(name, plan, cache) do
    cache_key = {name, plan.id}

    case Map.get(cache.groups, cache_key) do
      nil ->
        group =
          case Repo.get_by(CategoryGroup, name: name, plan_id: plan.id) do
            nil ->
              {:ok, g} = Repo.insert(%CategoryGroup{name: name, plan_id: plan.id})
              g

            g ->
              g
          end

        {group, put_in(cache, [:groups, cache_key], group)}

      group ->
        {group, cache}
    end
  end

  defp find_or_create_category(name, group, cache) do
    cache_key = {name, group.id}

    case Map.get(cache.categories, cache_key) do
      nil ->
        category =
          case Repo.one(
                 from c in Category,
                   join: cgc in "category_groups_categories",
                   on: cgc.category_id == c.id,
                   where: c.name == ^name and cgc.category_group_id == ^group.id,
                   limit: 1
               ) do
            nil ->
              {:ok, cat} = Repo.insert(%Category{name: name})

              Repo.insert_all(
                "category_groups_categories",
                [%{category_group_id: group.id, category_id: cat.id}],
                on_conflict: :nothing
              )

              cat

            cat ->
              cat
          end

        {category, put_in(cache, [:categories, cache_key], category)}

      category ->
        {category, cache}
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
end
