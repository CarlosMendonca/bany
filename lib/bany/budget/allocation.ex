defmodule Bany.Budget.Allocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Bany.Budget.Category
  alias Bany.Budget.Plan

  schema "allocations" do
    field :amount, :decimal
    field :allocated_on, :date
    belongs_to :category, Category
    belongs_to :plan, Plan

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(allocation, attrs) do
    allocation
    |> cast(attrs, [:amount, :allocated_on, :plan_id, :category_id])
    |> validate_required([:amount, :allocated_on, :plan_id, :category_id])
    |> assoc_constraint(:plan)
    |> assoc_constraint(:category)
    |> normalize_to_first_day()
  end

  defp normalize_to_first_day(changeset) do
    case get_change(changeset, :allocated_on) do
      nil ->
        changeset

      allocated_on when not is_nil(allocated_on) ->
        put_change(changeset, :allocated_on, Date.beginning_of_month(allocated_on))

      _ ->
        changeset
    end
  end
end
