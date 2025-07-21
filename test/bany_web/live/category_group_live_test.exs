defmodule BanyWeb.CategoryGroupLiveTest do
  use BanyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bany.BudgetFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}
  defp create_category_group(_) do
    category_group = category_group_fixture()

    %{category_group: category_group}
  end

  describe "Index" do
    setup [:create_category_group]

    test "lists all category_groups", %{conn: conn, category_group: category_group} do
      {:ok, _index_live, html} = live(conn, ~p"/category_groups")

      assert html =~ "Listing Category groups"
      assert html =~ category_group.name
    end

    test "saves new category_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/category_groups")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Category group")
               |> render_click()
               |> follow_redirect(conn, ~p"/category_groups/new")

      assert render(form_live) =~ "New Category group"

      assert form_live
             |> form("#category_group-form", category_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category_group-form", category_group: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category_groups")

      html = render(index_live)
      assert html =~ "Category group created successfully"
      assert html =~ "some name"
    end

    test "updates category_group in listing", %{conn: conn, category_group: category_group} do
      {:ok, index_live, _html} = live(conn, ~p"/category_groups")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#category_groups-#{category_group.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/category_groups/#{category_group}/edit")

      assert render(form_live) =~ "Edit Category group"

      assert form_live
             |> form("#category_group-form", category_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category_group-form", category_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category_groups")

      html = render(index_live)
      assert html =~ "Category group updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes category_group in listing", %{conn: conn, category_group: category_group} do
      {:ok, index_live, _html} = live(conn, ~p"/category_groups")

      assert index_live |> element("#category_groups-#{category_group.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#category_groups-#{category_group.id}")
    end
  end

  describe "Show" do
    setup [:create_category_group]

    test "displays category_group", %{conn: conn, category_group: category_group} do
      {:ok, _show_live, html} = live(conn, ~p"/category_groups/#{category_group}")

      assert html =~ "Show Category group"
      assert html =~ category_group.name
    end

    test "updates category_group and returns to show", %{conn: conn, category_group: category_group} do
      {:ok, show_live, _html} = live(conn, ~p"/category_groups/#{category_group}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/category_groups/#{category_group}/edit?return_to=show")

      assert render(form_live) =~ "Edit Category group"

      assert form_live
             |> form("#category_group-form", category_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#category_group-form", category_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category_groups/#{category_group}")

      html = render(show_live)
      assert html =~ "Category group updated successfully"
      assert html =~ "some updated name"
    end
  end
end
