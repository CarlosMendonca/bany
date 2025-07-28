defmodule Bany.Budget.CategoryGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "category_groups" do
    field :name, :string
    belongs_to :plan, Bany.Budget.Plan
    many_to_many :categories, Bany.Budget.Category, join_through: "category_groups_categories", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category_group, attrs) do
    category_group
    |> cast(attrs, [:name, :plan_id])
    |> validate_required([:name, :plan_id])
    # |> put_assoc(:categories, Enum.map(attrs["category_ids"], &Bany.Budget.get_category!/1)) when is_list(attrs["category_ids"])

    # TODO: add put_assoc for categories; this is better than casting category_ids because guarantees categories exist in the database; should only put assoc if category_ids are present
    # TODO: consider adding put_assoc for plan instead of casting plan_id
  end
end
