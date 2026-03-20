defmodule Bany.BudgetTest do
  use Bany.DataCase

  alias Bany.Budget

  describe "categories" do
    alias Bany.Budget.Category

    import Bany.BudgetFixtures

    @invalid_attrs %{name: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Budget.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Budget.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Category{} = category} = Budget.create_category(valid_attrs)
      assert category.name == "some name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budget.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Category{} = category} = Budget.update_category(category, update_attrs)
      assert category.name == "some updated name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Budget.update_category(category, @invalid_attrs)
      assert category == Budget.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Budget.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Budget.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Budget.change_category(category)
    end
  end

  describe "plans" do
    alias Bany.Budget.Plan

    import Bany.BudgetFixtures

    @invalid_attrs %{name: nil}

    test "list_plans/0 returns all plans" do
      plan = plan_fixture()
      assert Budget.list_plans() == [plan]
    end

    test "get_plan!/1 returns the plan with given id" do
      plan = plan_fixture()
      assert Budget.get_plan!(plan.id) == plan
    end

    test "create_plan/1 with valid data creates a plan" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Plan{} = plan} = Budget.create_plan(valid_attrs)
      assert plan.name == "some name"
    end

    test "create_plan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budget.create_plan(@invalid_attrs)
    end

    test "update_plan/2 with valid data updates the plan" do
      plan = plan_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Plan{} = plan} = Budget.update_plan(plan, update_attrs)
      assert plan.name == "some updated name"
    end

    test "update_plan/2 with invalid data returns error changeset" do
      plan = plan_fixture()
      assert {:error, %Ecto.Changeset{}} = Budget.update_plan(plan, @invalid_attrs)
      assert plan == Budget.get_plan!(plan.id)
    end

    test "delete_plan/1 deletes the plan" do
      plan = plan_fixture()
      assert {:ok, %Plan{}} = Budget.delete_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> Budget.get_plan!(plan.id) end
    end

    test "change_plan/1 returns a plan changeset" do
      plan = plan_fixture()
      assert %Ecto.Changeset{} = Budget.change_plan(plan)
    end
  end

  describe "category_groups" do
    alias Bany.Budget.CategoryGroup

    import Bany.BudgetFixtures

    @invalid_attrs %{name: nil}

    test "list_category_groups/0 returns all category_groups" do
      category_group = category_group_fixture()
      assert Budget.list_category_groups() == [category_group]
    end

    test "get_category_group!/1 returns the category_group with given id" do
      category_group = category_group_fixture()
      assert Budget.get_category_group!(category_group.id) == category_group
    end

    test "create_category_group/1 with valid data creates a category_group" do
      plan = plan_fixture()
      valid_attrs = %{name: "some name", plan_id: plan.id}

      assert {:ok, %CategoryGroup{} = category_group} = Budget.create_category_group(valid_attrs)
      assert category_group.name == "some name"
    end

    test "create_category_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budget.create_category_group(@invalid_attrs)
    end

    test "update_category_group/2 with valid data updates the category_group" do
      category_group = category_group_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %CategoryGroup{} = category_group} = Budget.update_category_group(category_group, update_attrs)
      assert category_group.name == "some updated name"
    end

    test "update_category_group/2 with invalid data returns error changeset" do
      category_group = category_group_fixture()
      assert {:error, %Ecto.Changeset{}} = Budget.update_category_group(category_group, @invalid_attrs)
      assert category_group == Budget.get_category_group!(category_group.id)
    end

    test "delete_category_group/1 deletes the category_group" do
      category_group = category_group_fixture()
      assert {:ok, %CategoryGroup{}} = Budget.delete_category_group(category_group)
      assert_raise Ecto.NoResultsError, fn -> Budget.get_category_group!(category_group.id) end
    end

    test "change_category_group/1 returns a category_group changeset" do
      category_group = category_group_fixture()
      assert %Ecto.Changeset{} = Budget.change_category_group(category_group)
    end
  end

  describe "allocations" do
    alias Bany.Budget.Allocation

    import Bany.BudgetFixtures

    @invalid_attrs %{amount: nil, allocated_on: nil}

    test "list_allocations/0 returns all allocations" do
      allocation = allocation_fixture()
      assert Budget.list_allocations() == [allocation]
    end

    test "get_allocation!/1 returns the allocation with given id" do
      allocation = allocation_fixture()
      assert Budget.get_allocation!(allocation.id) == allocation
    end

    test "create_allocation/1 with valid data creates a allocation" do
      plan = plan_fixture()
      category = category_fixture()
      valid_attrs = %{amount: "120.5", allocated_on: ~D[2025-08-01], plan_id: plan.id, category_id: category.id}

      assert {:ok, %Allocation{} = allocation} = Budget.create_allocation(valid_attrs)
      assert allocation.amount == Decimal.new("120.5")
      assert allocation.allocated_on == ~D[2025-08-01]
    end

    test "create_allocation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budget.create_allocation(@invalid_attrs)
    end

    test "update_allocation/2 with valid data updates the allocation" do
      allocation = allocation_fixture()
      update_attrs = %{amount: "456.7", allocated_on: ~D[2025-09-15]}

      assert {:ok, %Allocation{} = allocation} = Budget.update_allocation(allocation, update_attrs)
      assert allocation.amount == Decimal.new("456.7")
      assert allocation.allocated_on == ~D[2025-09-01]
    end

    test "update_allocation/2 with invalid data returns error changeset" do
      allocation = allocation_fixture()
      assert {:error, %Ecto.Changeset{}} = Budget.update_allocation(allocation, @invalid_attrs)
      assert allocation == Budget.get_allocation!(allocation.id)
    end

    test "delete_allocation/1 deletes the allocation" do
      allocation = allocation_fixture()
      assert {:ok, %Allocation{}} = Budget.delete_allocation(allocation)
      assert_raise Ecto.NoResultsError, fn -> Budget.get_allocation!(allocation.id) end
    end

    test "change_allocation/1 returns a allocation changeset" do
      allocation = allocation_fixture()
      assert %Ecto.Changeset{} = Budget.change_allocation(allocation)
    end
  end
end
