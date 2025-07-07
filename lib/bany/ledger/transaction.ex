defmodule Bany.Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :transaction, :string
    field :memo, :string
    field :date, :date
    field :amount, :decimal
    field :category_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:transaction, :memo, :date, :amount])
    |> validate_required([:transaction, :memo, :date, :amount])
  end
end
