defmodule BanyWeb.AdminLiveTest do
  use BanyWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Admin page" do
    test "renders the import form and clear section", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/admin")
      assert html =~ "Import YNAB CSV"
      assert html =~ "Budget / Plan name"
      assert html =~ "Clear Database"
    end

    test "shows validation error when plan name is empty on submit", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      html =
        live
        |> form("#import-form", %{"import" => %{"plan_name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "imports CSV file via upload and shows report", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      csv_content = """
      "Account","Flag","Date","Payee","Category Group/Category","Category Group","Category","Memo","Outflow","Inflow","Cleared"
      "VISA United Explorer (9655)","","03/17/2026","Zipcar","Flexible Expenses this Month: Transportation","Flexible Expenses this Month","Transportation","mom",$62.86,$0.00,"Cleared"
      "VISA United Explorer (9655)","","03/17/2026","CVS Pharmacy","Unplanned Expenses this Month: Groceries & Pharmacy","Unplanned Expenses this Month","Groceries & Pharmacy","",$12.49,$0.00,"Cleared"
      """

      upload =
        file_input(live, "#import-form", :csv_file, [
          %{
            name: "test.csv",
            content: csv_content,
            type: "text/csv"
          }
        ])

      render_upload(upload, "test.csv", 100)

      html =
        live
        |> form("#import-form", %{"import" => %{"plan_name" => "Test Budget"}})
        |> render_submit()

      assert html =~ "Import complete"
    end

    test "confirm/cancel clear database flow", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/admin")

      html = live |> element("button", "Clear all data") |> render_click()
      assert html =~ "Are you sure?"

      html = live |> element("button", "Cancel") |> render_click()
      refute html =~ "Are you sure?"
    end
  end
end
