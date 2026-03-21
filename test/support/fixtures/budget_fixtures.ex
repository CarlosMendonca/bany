defmodule Bany.BudgetFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bany.Budget` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Bany.Budget.create_category()

    category
  end

  @doc """
  Generate a plan. Accepts an optional user (or creates one) for ownership.
  """
  def plan_fixture(attrs \\ %{}, user \\ nil) do
    user = user || Bany.AccountsFixtures.user_fixture()

    {:ok, plan} =
      attrs
      |> Enum.into(%{name: "some name"})
      |> Bany.Budget.create_plan(user)

    plan
  end

  @doc """
  Generate a category_group. Creates a plan automatically if plan_id is not provided.
  """
  def category_group_fixture(attrs \\ %{}, user \\ nil) do
    plan_id = Map.get(attrs, :plan_id) || plan_fixture(%{}, user).id

    {:ok, category_group} =
      attrs
      |> Enum.into(%{
        name: "some name",
        plan_id: plan_id
      })
      |> Bany.Budget.create_category_group()

    # Re-fetch to get the struct as it would appear from Repo.get! (no preloaded assocs)
    Bany.Repo.get!(Bany.Budget.CategoryGroup, category_group.id)
  end

  @doc """
  Generate an allocation. Creates a plan and category automatically if not provided.
  """
  def allocation_fixture(attrs \\ %{}, user \\ nil) do
    plan_id = Map.get(attrs, :plan_id) || plan_fixture(%{}, user).id
    category_id = Map.get(attrs, :category_id) || category_fixture().id

    # Ensure the category is linked to the plan so form selects populate correctly
    Bany.Repo.insert_all("plan_categories", [%{plan_id: plan_id, category_id: category_id}], on_conflict: :nothing)

    {:ok, allocation} =
      attrs
      |> Enum.into(%{
        allocated_on: ~D[2025-08-01],
        amount: "120.5",
        plan_id: plan_id,
        category_id: category_id
      })
      |> Bany.Budget.create_allocation()

    allocation
  end
end
