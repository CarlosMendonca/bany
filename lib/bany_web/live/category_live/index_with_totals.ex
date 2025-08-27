defmodule BanyWeb.CategoryLive.IndexWithTotals do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Categories with Totals for <%= Calendar.strftime(@selected_month, "%B %Y") %>
      </.header>

      <div class="flex justify-between items-center mb-4">
        <.link navigate={~p"/categories/with_totals/#{@previous_month.year}/#{@previous_month.month}"}>
          <.button>Previous Month</.button>
        </.link>
        <.link navigate={~p"/categories/with_totals/#{@current_month.year}/#{@current_month.month}"}>
          <.button>Today</.button>
        </.link>
        <.link navigate={~p"/categories/with_totals/#{@next_month.year}/#{@next_month.month}"}>
          <.button>Next Month</.button>
        </.link>
      </div>

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
