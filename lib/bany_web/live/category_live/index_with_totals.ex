defmodule BanyWeb.CategoryLive.IndexWithTotals do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Plan for <%= Calendar.strftime(@dates.selected, "%B %Y") %>
        <:actions>
          <.button navigate={~p"/categories/with_totals/#{@dates.previous.year}/#{@dates.previous.month}"}>
            <.icon name="hero-chevron-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/categories/with_totals/#{@dates.current.year}/#{@dates.current.month}"}
          >
            <.icon name="hero-calendar-days" /> Today
          </.button>
          <.button navigate={~p"/categories/with_totals/#{@dates.next.year}/#{@dates.next.month}"}>
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
    today = Date.utc_today()
    {year, month} = get_year_and_month(params)
    selected_date = Date.new!(year, month, 1)

    dates = %{
      selected: selected_date,
      current: today,
      previous: Date.shift(selected_date, day: -1),
      next: Date.shift(selected_date, month: 1)
    }

    socket =
      socket
      |> assign(:page_title, "Listing Categories with Totals")
      |> assign(:category_groups, Budget.list_categories_with_totals(month, year))
      |> assign(:dates, dates)

    {:ok, socket}
  end

  defp get_year_and_month(%{"year" => year, "month" => month}) do
    {String.to_integer(year), String.to_integer(month)}
  end
end
