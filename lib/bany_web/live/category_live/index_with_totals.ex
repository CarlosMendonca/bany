defmodule BanyWeb.CategoryLive.IndexWithTotals do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Categories with Totals
      </.header>

      <%= for {group, categories} <- @category_groups do %>
        <div class="mb-8">
          <h2 class="text-sm font-semibold mb-4">
            <%= if group == :ungrouped do %>
              Ungrouped Categories
            <% else %>
              <%= group.name %>
            <% end %>
          </h2>
          <.table
            id={"categories-#{if group == :ungrouped, do: "ungrouped", else: group.id}"}
            rows={categories}
          >
            <:col :let={category} label="Name"><%= category.name %></:col>
            <:col :let={category} label="Assigned"><%= category.total_assigned %></:col>
            <:col :let={category} label="Spent"><%= category.total_spent %></:col>
            <:col :let={category} label="Available"><%= category.total_available %></:col>
          </.table>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {year, month} = get_year_and_month(params)

    socket =
      socket
      |> assign(:page_title, "Listing Categories with Totals")
      |> assign(:category_groups, Budget.list_categories_with_totals(month, year))

    {:ok, socket}
  end

  defp get_year_and_month(%{"year" => year, "month" => month}) do
    {String.to_integer(year), String.to_integer(month)}
  end
end
