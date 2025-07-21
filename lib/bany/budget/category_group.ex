defmodule Bany.Budget.CategoryGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "category_groups" do
    field :name, :string
    belongs_to :plan, Bany.Budget.Plan
    many_to_many :categories, Bany.Budget.Category, join_through: "category_groups_categories"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category_group, attrs) do
    category_group
    |> cast(attrs, [:name, :plan_id])
    |> validate_required([:name, :plan_id])
  end
end
