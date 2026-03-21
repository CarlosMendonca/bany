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

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:memo, :date, :amount, :category_id, :account_id, :payee_id])
    |> validate_required([:date, :amount])
  end
end
