defmodule Bany.Budget do
  @moduledoc """
  The Budget context.
  """

  import Ecto.Query, warn: false
  alias Bany.Repo

  alias Bany.Budget.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  alias Bany.Budget.Plan

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans()
      [%Plan{}, ...]

  """
  def list_plans do
    Repo.all(Plan)
  end

  @doc """
  Gets a single plan.

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan!(123)
      %Plan{}

      iex> get_plan!(456)
      ** (Ecto.NoResultsError)

  """
  def get_plan!(id), do: Repo.get!(Plan, id)

  @doc """
  Creates a plan.

  ## Examples

      iex> create_plan(%{field: value})
      {:ok, %Plan{}}

      iex> create_plan(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_plan(attrs) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{field: new_value})
      {:ok, %Plan{}}

      iex> update_plan(plan, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a plan.

  ## Examples

      iex> delete_plan(plan)
      {:ok, %Plan{}}

      iex> delete_plan(plan)
      {:error, %Ecto.Changeset{}}

  """
  def delete_plan(%Plan{} = plan) do
    Repo.delete(plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Ecto.Changeset{data: %Plan{}}

  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  alias Bany.Budget.CategoryGroup

  @doc """
  Returns the list of category_groups.

  ## Examples

      iex> list_category_groups()
      [%CategoryGroup{}, ...]

  """
  def list_category_groups do
    Repo.all(CategoryGroup)
  end

  @doc """
  Gets a single category_group.

  Raises `Ecto.NoResultsError` if the Category group does not exist.

  ## Examples

      iex> get_category_group!(123)
      %CategoryGroup{}

      iex> get_category_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category_group!(id), do: Repo.get!(CategoryGroup, id)

  @doc """
  Creates a category_group.

  ## Examples

      iex> create_category_group(%{field: value})
      {:ok, %CategoryGroup{}}

      iex> create_category_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category_group(attrs) do
    categories = Map.get(attrs, "category_ids", []) |> Enum.map(&get_category!/1)
    %CategoryGroup{}
    |> CategoryGroup.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:categories, categories)
    |> Repo.insert()
  end

  @doc """
  Updates a category_group.

  ## Examples

      iex> update_category_group(category_group, %{field: new_value})
      {:ok, %CategoryGroup{}}

      iex> update_category_group(category_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category_group(%CategoryGroup{} = category_group, attrs) do
    categories = Map.get(attrs, "category_ids", []) |> Enum.map(&get_category!/1)
    category_group
    |> CategoryGroup.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:categories, categories)
    |> Repo.update()
  end

  @doc """
  Deletes a category_group.

  ## Examples

      iex> delete_category_group(category_group)
      {:ok, %CategoryGroup{}}

      iex> delete_category_group(category_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category_group(%CategoryGroup{} = category_group) do
    Repo.delete(category_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category_group changes.

  ## Examples

      iex> change_category_group(category_group)
      %Ecto.Changeset{data: %CategoryGroup{}}

  """
  def change_category_group(%CategoryGroup{} = category_group, attrs \\ %{}) do
    CategoryGroup.changeset(category_group, attrs)
  end
end
