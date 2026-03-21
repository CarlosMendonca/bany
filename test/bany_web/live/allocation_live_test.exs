defmodule BanyWeb.AllocationLiveTest do
  use BanyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bany.BudgetFixtures

  @create_attrs %{amount: "120.5", allocated_on: "2025-08-01"}
  @update_attrs %{amount: "456.7", allocated_on: "2025-08-01"}
  @invalid_attrs %{amount: nil, allocated_on: nil}

  setup :register_and_log_in_user

  defp create_allocation(%{user: user}) do
    allocation = allocation_fixture(%{}, user)
    %{allocation: allocation, plan_id: allocation.plan_id}
  end

  describe "Index" do
    setup [:create_allocation]

    test "lists all allocations", %{conn: conn, plan_id: plan_id} do
      {:ok, _index_live, html} = live(conn, ~p"/plans/#{plan_id}/allocations")

      assert html =~ "Listing Allocations"
    end

    test "saves new allocation", %{conn: conn, allocation: allocation, plan_id: plan_id} do
      {:ok, index_live, _html} = live(conn, ~p"/plans/#{plan_id}/allocations")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Allocation")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations/new")

      assert render(form_live) =~ "New Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#allocation-form", allocation: Map.put(@create_attrs, :category_id, allocation.category_id))
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations")

      html = render(index_live)
      assert html =~ "Allocation created successfully"
    end

    test "updates allocation in listing", %{conn: conn, allocation: allocation, plan_id: plan_id} do
      {:ok, index_live, _html} = live(conn, ~p"/plans/#{plan_id}/allocations")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#allocations-#{allocation.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations/#{allocation}/edit")

      assert render(form_live) =~ "Edit Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#allocation-form", allocation: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations")

      html = render(index_live)
      assert html =~ "Allocation updated successfully"
    end

    test "deletes allocation in listing", %{conn: conn, allocation: allocation, plan_id: plan_id} do
      {:ok, index_live, _html} = live(conn, ~p"/plans/#{plan_id}/allocations")

      assert index_live |> element("#allocations-#{allocation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#allocations-#{allocation.id}")
    end
  end

  describe "Show" do
    setup [:create_allocation]

    test "displays allocation", %{conn: conn, allocation: allocation, plan_id: plan_id} do
      {:ok, _show_live, html} = live(conn, ~p"/plans/#{plan_id}/allocations/#{allocation}")

      assert html =~ "Show Allocation"
    end

    test "updates allocation and returns to show", %{conn: conn, allocation: allocation, plan_id: plan_id} do
      {:ok, show_live, _html} = live(conn, ~p"/plans/#{plan_id}/allocations/#{allocation}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations/#{allocation}/edit?return_to=show")

      assert render(form_live) =~ "Edit Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#allocation-form", allocation: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans/#{plan_id}/allocations/#{allocation}")

      html = render(show_live)
      assert html =~ "Allocation updated successfully"
    end
  end
end
