defmodule Bany.Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :memo, :string
    field :date, :date
    field :amount, :decimal
    belongs_to :category, Bany.Budget.Category
    belongs_to :account, Bany.Ledger.Account
    belongs_to :payee, Bany.Ledger.Payee
    many_to_many :tags, Bany.Ledger.Tag, join_through: "transaction_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:memo, :date, :amount, :category_id, :account_id, :payee_id])
    |> validate_required([:date, :amount])
  end

  def partial_changeset(transaction, attrs) do
    changeset = cast(transaction, attrs, [:memo, :date, :amount, :category_id, :payee_id])
    changeset = if Map.has_key?(attrs, "amount") or Map.has_key?(attrs, :amount),
      do: validate_required(changeset, [:amount]), else: changeset
    if Map.has_key?(attrs, "date") or Map.has_key?(attrs, :date),
      do: validate_required(changeset, [:date]), else: changeset
  end
end
