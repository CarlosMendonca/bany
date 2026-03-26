defmodule Bany.Budget do
  @moduledoc """
  The Budget context.
  """

  import Ecto.Query, warn: false
  alias Bany.Repo

  alias Bany.Budget.Allocation
  alias Bany.Budget.Category
  alias Bany.Ledger.{Account, Transaction}

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  def list_categories_for_plan(plan_id) do
    from(c in Category,
      join: pc in "plan_categories", on: pc.category_id == c.id and pc.plan_id == ^plan_id
    )
    |> Repo.all()
  end

  def list_categories_with_totals(plan_id, month, year) do
    date_range = month_date_range(month, year)
    prev_date_range = prev_month_date_range(month, year)

    groups =
      query_categories_with_totals(date_range, plan_id)
      |> compute_category_totals()
      |> group_by_category_group()
      |> append_uncategorized_transactions(date_range)

    tbb_data = compute_tbb(plan_id, date_range, prev_date_range)

    {groups, tbb_data}
  end

  defp month_date_range(month, year) do
    first_day = Date.new!(year, month, 1)
    {first_day, Date.end_of_month(first_day)}
  end

  defp prev_month_date_range(month, year) do
    prev = Date.shift(Date.new!(year, month, 1), month: -1)
    {prev, Date.end_of_month(prev)}
  end

  defp query_categories_with_totals({first_day, end_of_month}, plan_id) do
    transactions_query =
      from(
        t in Transaction,
        where: t.date >= ^first_day and t.date <= ^end_of_month,
        group_by: t.category_id,
        select: %{category_id: t.category_id, total_spent: sum(t.amount)}
      )

    from(
      c in Category,
      join: pc in "plan_categories", on: pc.category_id == c.id and pc.plan_id == ^plan_id,
      left_join: a in Allocation,
      on: a.category_id == c.id and a.allocated_on == ^first_day and a.plan_id == ^plan_id,
      left_join: t_sums in subquery(transactions_query),
      on: t_sums.category_id == c.id,
      where: not c.is_inflow,
      preload: [:category_groups],
      select: {c, a.amount, t_sums.total_spent}
    )
    |> Repo.all()
  end

  defp compute_category_totals(rows) do
    Enum.map(rows, fn {category, assigned, spent} ->
      assigned = assigned || Decimal.new(0)
      spent = spent || Decimal.new(0)

      %{
        category
        | total_spent: spent,
          total_assigned: assigned,
          total_available: Decimal.sub(assigned, spent)
      }
    end)
  end

  defp group_by_category_group(categories) do
    categories
    |> Enum.group_by(fn category ->
      case category.category_groups do
        [] -> :ungrouped
        [group | _] -> group
      end
    end)
    |> Map.put_new(:ungrouped, [])
  end

  defp append_uncategorized_transactions(grouped, {first_day, end_of_month}) do
    {total, count} =
      from(
        t in Transaction,
        where: t.date >= ^first_day and t.date <= ^end_of_month and is_nil(t.category_id),
        select: {coalesce(sum(t.amount), 0), count(t.id)}
      )
      |> Repo.one()

    if count > 0 do
      # TODO: YNAB doesn't show Assigned for Uncategorized Transactions and assumes
      # Available equals Activity; consider doing the same, which may leak decimal
      # representation to the view
      entry = %{
        name: "Uncategorized Transactions (#{count})",
        total_assigned: Decimal.new(0),
        total_spent: total,
        total_available: Decimal.negate(total)
      }

      Map.update!(grouped, :ungrouped, &[entry | &1])
    else
      grouped
    end
  end

  defp compute_tbb(plan_id, {this_first, _this_last}, {prev_first, prev_last}) do
    # Cumulative TBB: all-time inflows in plan's accounts - all-time allocations for plan
    tbb_inflow =
      from(t in Transaction,
        join: a in Account, on: a.id == t.account_id,
        join: pa in "plan_accounts", on: pa.account_id == a.id and pa.plan_id == ^plan_id,
        join: c in Category, on: c.id == t.category_id and c.is_inflow,
        select: coalesce(sum(t.amount), 0)
      )
      |> Repo.one()

    tbb_allocated =
      from(a in Allocation,
        where: a.plan_id == ^plan_id,
        select: coalesce(sum(a.amount), 0)
      )
      |> Repo.one()

    # Last month's inflow for the monthly reference row
    last_month_inflow =
      from(t in Transaction,
        join: a in Account, on: a.id == t.account_id,
        join: pa in "plan_accounts", on: pa.account_id == a.id and pa.plan_id == ^plan_id,
        join: c in Category, on: c.id == t.category_id and c.is_inflow,
        where: t.date >= ^prev_first and t.date <= ^prev_last,
        select: coalesce(sum(t.amount), 0)
      )
      |> Repo.one()

    # This month's allocations for the monthly reference row
    this_month_allocated =
      from(a in Allocation,
        where: a.plan_id == ^plan_id and a.allocated_on == ^this_first,
        select: coalesce(sum(a.amount), 0)
      )
      |> Repo.one()

    %{
      tbb: Decimal.sub(tbb_inflow, tbb_allocated),
      last_month_inflow: last_month_inflow,
      this_month_allocated: this_month_allocated
    }
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
  def delete_category(%Category{is_inflow: true}), do: {:error, :inflow_category_protected}
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

  def list_plans_for_user(user_id) do
    from(p in Plan,
      join: up in "user_plans", on: up.plan_id == p.id and up.user_id == ^user_id
    )
    |> Repo.all()
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
  def create_plan(attrs, user) do
    with {:ok, plan} <- %Plan{} |> Plan.changeset(attrs) |> Repo.insert() do
      Repo.insert_all("user_plans", [%{user_id: user.id, plan_id: plan.id}])
      associate_inflow_category(plan)
      {:ok, plan}
    end
  end

  defp associate_inflow_category(plan) do
    case Repo.get_by(Category, is_inflow: true) do
      nil -> :ok
      cat -> Repo.insert_all("plan_categories", [%{plan_id: plan.id, category_id: cat.id}], on_conflict: :nothing)
    end
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

  def list_category_groups_for_plan(plan_id) do
    from(cg in CategoryGroup, where: cg.plan_id == ^plan_id)
    |> Repo.all()
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
    |> Repo.preload(:categories)
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

  @doc """
  Returns the list of allocations.

  ## Examples

      iex> list_allocations()
      [%Allocation{}, ...]

  """
  def list_allocations do
    Repo.all(Allocation)
  end

  def list_allocations_for_plan(plan_id) do
    from(a in Allocation, where: a.plan_id == ^plan_id)
    |> Repo.all()
  end

  @doc """
  Gets a single allocation.

  Raises `Ecto.NoResultsError` if the Allocation does not exist.

  ## Examples

      iex> get_allocation!(123)
      %Allocation{}

      iex> get_allocation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_allocation!(id), do: Repo.get!(Allocation, id)

  @doc """
  Creates a allocation.

  ## Examples

      iex> create_allocation(%{field: value})
      {:ok, %Allocation{}}

      iex> create_allocation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_allocation(attrs) do
    %Allocation{}
    |> Allocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a allocation.

  ## Examples

      iex> update_allocation(allocation, %{field: new_value})
      {:ok, %Allocation{}}

      iex> update_allocation(allocation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_allocation(%Allocation{} = allocation, attrs) do
    allocation
    |> Allocation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a allocation.

  ## Examples

      iex> delete_allocation(allocation)
      {:ok, %Allocation{}}

      iex> delete_allocation(allocation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_allocation(%Allocation{} = allocation) do
    Repo.delete(allocation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking allocation changes.

  ## Examples

      iex> change_allocation(allocation)
      %Ecto.Changeset{data: %Allocation{}}

  """
  def change_allocation(%Allocation{} = allocation, attrs \\ %{}) do
    Allocation.changeset(allocation, attrs)
  end

  def delete_all do
    Repo.delete_all(Allocation)
    Repo.delete_all(Category)
    Repo.delete_all(CategoryGroup)
    Repo.delete_all(Plan)
  end
end
