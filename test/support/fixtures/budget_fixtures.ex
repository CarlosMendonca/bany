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
  Generate a plan.
  """
  def plan_fixture(attrs \\ %{}) do
    {:ok, plan} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Bany.Budget.create_plan()

    plan
  end

  @doc """
  Generate a category_group.
  """
  def category_group_fixture(attrs \\ %{}) do
    {:ok, category_group} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Bany.Budget.create_category_group()

    category_group
  end
end
