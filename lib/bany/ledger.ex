defmodule Bany.Ledger do
  @moduledoc """
  The Ledger context.
  """

  import Ecto.Query, warn: false
  alias Bany.Repo

  alias Bany.Ledger.Account
  alias Bany.Ledger.Transaction
  alias Bany.Ledger.Payee

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  def list_transactions_for_plan(plan_id) do
    from(t in Transaction,
      join: pa in "plan_accounts", on: pa.account_id == t.account_id and pa.plan_id == ^plan_id
    )
    |> Repo.all()
  end

  def search_transactions(query) when is_binary(query) and query != "" do
    search = "%#{query}%"

    from(t in Transaction,
      left_join: p in assoc(t, :payee),
      where:
        ilike(t.memo, ^search) or
          ilike(p.name, ^search) or
          ilike(fragment("CAST(? AS TEXT)", t.amount), ^search),
      preload: [:category, :account, :payee]
    )
    |> Repo.all()
  end

  def search_transactions(_), do: list_transactions() |> Repo.preload([:category, :account, :payee])

  def search_transactions_for_plan(plan_id, query) when is_binary(query) and query != "" do
    search = "%#{query}%"

    from(t in Transaction,
      join: pa in "plan_accounts", on: pa.account_id == t.account_id and pa.plan_id == ^plan_id,
      left_join: p in assoc(t, :payee),
      where:
        ilike(t.memo, ^search) or
          ilike(p.name, ^search) or
          ilike(fragment("CAST(? AS TEXT)", t.amount), ^search),
      preload: [:category, :account, :payee]
    )
    |> Repo.all()
  end

  def search_transactions_for_plan(plan_id, _),
    do: list_transactions_for_plan(plan_id) |> Repo.preload([:category, :account, :payee])

  def count_transactions(nil), do: Repo.aggregate(Transaction, :count)

  def count_transactions(plan_id) do
    from(t in Transaction,
      join: pa in "plan_accounts", on: pa.account_id == t.account_id and pa.plan_id == ^plan_id
    )
    |> Repo.aggregate(:count)
  end

  def filter_transactions(opts) do
    page      = Map.get(opts, :page, 1)
    page_size = Map.get(opts, :page_size, 50)

    Transaction
    |> maybe_scope_to_plan(opts[:plan_id])
    |> maybe_search(opts[:query])
    |> maybe_filter_categories(opts[:category_ids])
    |> maybe_filter_accounts(opts[:account_ids])
    |> maybe_filter_date(opts[:date_from], opts[:date_to])
    |> order_by([t], desc: t.date, desc: t.id)
    |> limit(^page_size)
    |> offset(^((page - 1) * page_size))
    |> Repo.all()
    |> Repo.preload([:category, :account, :payee])
  end

  def count_filtered_transactions(opts) do
    Transaction
    |> maybe_scope_to_plan(opts[:plan_id])
    |> maybe_search(opts[:query])
    |> maybe_filter_categories(opts[:category_ids])
    |> maybe_filter_accounts(opts[:account_ids])
    |> maybe_filter_date(opts[:date_from], opts[:date_to])
    |> Repo.aggregate(:count)
  end

  defp maybe_scope_to_plan(q, nil), do: q

  defp maybe_scope_to_plan(q, plan_id) do
    from t in q,
      join: pa in "plan_accounts",
      on: pa.account_id == t.account_id and pa.plan_id == ^plan_id
  end

  defp maybe_search(q, term) when term in [nil, ""], do: q

  defp maybe_search(q, term) do
    like = "%#{term}%"

    from t in q,
      left_join: p in assoc(t, :payee),
      where:
        ilike(t.memo, ^like) or
          ilike(p.name, ^like) or
          ilike(fragment("CAST(? AS TEXT)", t.amount), ^like)
  end

  defp maybe_filter_categories(q, ids) when ids in [nil, []], do: q
  defp maybe_filter_categories(q, ids), do: from t in q, where: t.category_id in ^ids

  defp maybe_filter_accounts(q, ids) when ids in [nil, []], do: q
  defp maybe_filter_accounts(q, ids), do: from t in q, where: t.account_id in ^ids

  defp maybe_filter_date(q, nil, nil), do: q
  defp maybe_filter_date(q, from, nil), do: from t in q, where: t.date >= ^from
  defp maybe_filter_date(q, nil, to), do: from t in q, where: t.date <= ^to
  defp maybe_filter_date(q, from, to), do: from t in q, where: t.date >= ^from and t.date <= ^to

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  def list_accounts_for_plan(plan_id) do
    from(a in Account,
      join: pa in "plan_accounts", on: pa.account_id == a.id and pa.plan_id == ^plan_id
    )
    |> Repo.all()
  end

  def list_accounts_for_user(user_id) do
    from(a in Account,
      join: ua in "user_accounts", on: ua.account_id == a.id and ua.user_id == ^user_id
    )
    |> Repo.all()
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates an account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs, user) do
    with {:ok, account} <- %Account{} |> Account.changeset(attrs) |> Repo.insert() do
      Repo.insert_all("user_accounts", [%{user_id: user.id, account_id: account.id}])
      {:ok, account}
    end
  end

  @doc """
  Updates an account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  def list_payees do
    Repo.all(Payee)
  end

  def list_payees_for_plan(plan_id) do
    from(p in Payee,
      join: t in Transaction, on: t.payee_id == p.id,
      join: pa in "plan_accounts", on: pa.account_id == t.account_id and pa.plan_id == ^plan_id,
      distinct: true
    )
    |> Repo.all()
  end

  def get_payee!(id), do: Repo.get!(Payee, id)

  def create_payee(attrs) do
    %Payee{}
    |> Payee.changeset(attrs)
    |> Repo.insert()
  end

  def change_payee(%Payee{} = payee, attrs \\ %{}) do
    Payee.changeset(payee, attrs)
  end

  def update_payee(%Payee{} = payee, attrs) do
    payee |> Payee.changeset(attrs) |> Repo.update()
  end

  def delete_payee(%Payee{} = payee) do
    Repo.delete(payee)
  end

  def find_or_create_payee_by_name(name) when is_binary(name) and byte_size(name) > 0 do
    case Repo.get_by(Payee, name: name) do
      nil ->
        case Repo.insert(Payee.changeset(%Payee{}, %{name: name})) do
          {:ok, payee} -> payee
          {:error, _} -> nil
        end

      payee ->
        payee
    end
  end

  def find_or_create_payee_by_name(_), do: nil

  def delete_all do
    Repo.delete_all(Transaction)
    Repo.delete_all(Payee)
    Repo.delete_all(Account)
  end
end
