defmodule Bany.Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :memo, :string
    field :date, :date
    field :amount, :decimal
    belongs_to :category, Bany.Budget.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:memo, :date, :amount, :category_id])
    |> validate_required([:memo, :date, :amount, :category_id])
  end
end
