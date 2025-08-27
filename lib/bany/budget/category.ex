defmodule Bany.Budget.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    has_many :transactions, Bany.Ledger.Transaction
    many_to_many :category_groups, Bany.Budget.CategoryGroup, join_through: "category_groups_categories"

    field :total_spent, :decimal, virtual: true
    field :total_assigned, :decimal, virtual: true
    field :total_available, :decimal, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
