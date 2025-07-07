defmodule BanyWeb.PlanLiveTest do
  use BanyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bany.BudgetFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}
  defp create_plan(_) do
    plan = plan_fixture()

    %{plan: plan}
  end

  describe "Index" do
    setup [:create_plan]

    test "lists all plans", %{conn: conn, plan: plan} do
      {:ok, _index_live, html} = live(conn, ~p"/plans")

      assert html =~ "Listing Plans"
      assert html =~ plan.name
    end

    test "saves new plan", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/plans")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Plan")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/new")

      assert render(form_live) =~ "New Plan"

      assert form_live
             |> form("#plan-form", plan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#plan-form", plan: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans")

      html = render(index_live)
      assert html =~ "Plan created successfully"
      assert html =~ "some name"
    end

    test "updates plan in listing", %{conn: conn, plan: plan} do
      {:ok, index_live, _html} = live(conn, ~p"/plans")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#plans-#{plan.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/#{plan}/edit")

      assert render(form_live) =~ "Edit Plan"

      assert form_live
             |> form("#plan-form", plan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#plan-form", plan: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans")

      html = render(index_live)
      assert html =~ "Plan updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes plan in listing", %{conn: conn, plan: plan} do
      {:ok, index_live, _html} = live(conn, ~p"/plans")

      assert index_live |> element("#plans-#{plan.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#plans-#{plan.id}")
    end
  end

  describe "Show" do
    setup [:create_plan]

    test "displays plan", %{conn: conn, plan: plan} do
      {:ok, _show_live, html} = live(conn, ~p"/plans/#{plan}")

      assert html =~ "Show Plan"
      assert html =~ plan.name
    end

    test "updates plan and returns to show", %{conn: conn, plan: plan} do
      {:ok, show_live, _html} = live(conn, ~p"/plans/#{plan}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/plans/#{plan}/edit?return_to=show")

      assert render(form_live) =~ "Edit Plan"

      assert form_live
             |> form("#plan-form", plan: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#plan-form", plan: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/plans/#{plan}")

      html = render(show_live)
      assert html =~ "Plan updated successfully"
      assert html =~ "some updated name"
    end
  end
end
