defmodule BanyWeb.CategoryLive.IndexWithTotals do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Plan for <%= Calendar.strftime(@selected_month, "%B %Y") %>
        <:actions>
          <.button navigate={~p"/categories/with_totals/#{@previous_month.year}/#{@previous_month.month}"}>
            <.icon name="hero-chevron-left" />
          </.button>
          <.button variant="primary" navigate={~p"/categories/with_totals/#{@current_month.year}/#{@current_month.month}"}>
            <.icon name="hero-calendar-days" /> Today
          </.button>
          <.button navigate={~p"/categories/with_totals/#{@next_month.year}/#{@next_month.month}"}>
            <.icon name="hero-chevron-right" />
          </.button>
        </:actions>
      </.header>
      <table class="table table-zebra">
        <thead>
          <tr>
            <th>Category</th>
            <th>Assigned</th>
            <th>Activity</th>
            <th>Available</th>
          </tr>
        </thead>
        <tbody>
          <%= for {group, categories} <- @category_groups do %>
            <tr>
              <th colspan="4">
                <%= if group == :ungrouped do %>
                  Ungrouped Categories
                <% else %>
                  <%= group.name %>
                <% end %>
              </th>
            </tr>
            <%= for category <- categories do %>
              <tr>
                <td><%= category.name %></td>
                <td><%= category.total_assigned %></td>
                <td><%= category.total_spent %></td>
                <td><%= category.total_available %></td>
              </tr>
            <% end %>
          <% end %>
        </tbody>
      </table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {year, month} = get_year_and_month(params)
    selected_month = Date.new!(year, month, 1)

    previous_month = Date.shift(selected_month, day: -1)
    next_month = Date.shift(selected_month, month: 1)

    socket =
      socket
      |> assign(:page_title, "Listing Categories with Totals")
      |> assign(:category_groups, Budget.list_categories_with_totals(month, year))
      |> assign(:selected_month, selected_month)
      |> assign(:current_month, Date.utc_today())
      |> assign(:previous_month, previous_month)
      |> assign(:next_month, next_month)

    {:ok, socket}
  end

  defp get_year_and_month(%{"year" => year, "month" => month}) do
    {String.to_integer(year), String.to_integer(month)}
  end
end
