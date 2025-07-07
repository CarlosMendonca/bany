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
end
