defmodule BanyWeb.AllocationLiveTest do
  use BanyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bany.BudgetFixtures

  @create_attrs %{amount: "120.5", allocated_on: "2025-08-26"}
  @update_attrs %{amount: "456.7", allocated_on: "2025-08-27"}
  @invalid_attrs %{amount: nil, allocated_on: nil}
  defp create_allocation(_) do
    allocation = allocation_fixture()

    %{allocation: allocation}
  end

  describe "Index" do
    setup [:create_allocation]

    test "lists all allocations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/allocations")

      assert html =~ "Listing Allocations"
    end

    test "saves new allocation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/allocations")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Allocation")
               |> render_click()
               |> follow_redirect(conn, ~p"/allocations/new")

      assert render(form_live) =~ "New Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#allocation-form", allocation: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/allocations")

      html = render(index_live)
      assert html =~ "Allocation created successfully"
    end

    test "updates allocation in listing", %{conn: conn, allocation: allocation} do
      {:ok, index_live, _html} = live(conn, ~p"/allocations")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#allocations-#{allocation.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/allocations/#{allocation}/edit")

      assert render(form_live) =~ "Edit Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#allocation-form", allocation: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/allocations")

      html = render(index_live)
      assert html =~ "Allocation updated successfully"
    end

    test "deletes allocation in listing", %{conn: conn, allocation: allocation} do
      {:ok, index_live, _html} = live(conn, ~p"/allocations")

      assert index_live |> element("#allocations-#{allocation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#allocations-#{allocation.id}")
    end
  end

  describe "Show" do
    setup [:create_allocation]

    test "displays allocation", %{conn: conn, allocation: allocation} do
      {:ok, _show_live, html} = live(conn, ~p"/allocations/#{allocation}")

      assert html =~ "Show Allocation"
    end

    test "updates allocation and returns to show", %{conn: conn, allocation: allocation} do
      {:ok, show_live, _html} = live(conn, ~p"/allocations/#{allocation}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/allocations/#{allocation}/edit?return_to=show")

      assert render(form_live) =~ "Edit Allocation"

      assert form_live
             |> form("#allocation-form", allocation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#allocation-form", allocation: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/allocations/#{allocation}")

      html = render(show_live)
      assert html =~ "Allocation updated successfully"
    end
  end
end
