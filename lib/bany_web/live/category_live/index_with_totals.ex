defmodule BanyWeb.CategoryLive.IndexWithTotals do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Plan for <%= Calendar.strftime(@dates.selected, "%B %Y") %>
        <:actions>
          <.button navigate={~p"/plans/#{@current_plan.id}/categories/with_totals/#{@dates.previous.year}/#{@dates.previous.month}"}>
            <.icon name="hero-chevron-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/plans/#{@current_plan.id}/categories/with_totals/#{@dates.current.year}/#{@dates.current.month}"}
          >
            <.icon name="hero-calendar-days" /> Today
          </.button>
          <.button navigate={~p"/plans/#{@current_plan.id}/categories/with_totals/#{@dates.next.year}/#{@dates.next.month}"}>
            <.icon name="hero-chevron-right" />
          </.button>
        </:actions>
      </.header>

      <%!-- TBB header --%>
      <div class="flex flex-wrap gap-4 mb-4 p-4 bg-base-200 rounded-lg">
        <div class="flex flex-col gap-0.5">
          <span class="text-xs opacity-60">Ready to Assign</span>
          <span class={[
            "text-xl font-semibold",
            Decimal.gt?(@tbb_data.tbb, 0) && "text-success",
            Decimal.lt?(@tbb_data.tbb, 0) && "text-error"
          ]}>
            {format_amount(@tbb_data.tbb, @current_plan && @current_plan.currency)}
          </span>
        </div>
        <div class="divider divider-horizontal" />
        <div class="flex flex-col gap-0.5">
          <span class="text-xs opacity-60">Last month's income</span>
          <span class="text-xl font-semibold">
            {format_amount(@tbb_data.last_month_inflow, @current_plan && @current_plan.currency)}
          </span>
        </div>
        <div class="flex flex-col gap-0.5">
          <span class="text-xs opacity-60">This month's allocations</span>
          <span class="text-xl font-semibold">
            {format_amount(@tbb_data.this_month_allocated, @current_plan && @current_plan.currency)}
          </span>
        </div>
        <div class="flex flex-col gap-0.5">
          <span class="text-xs opacity-60">vs. last month</span>
          <% delta = Decimal.sub(@tbb_data.last_month_inflow, @tbb_data.this_month_allocated) %>
          <span class={[
            "text-xl font-semibold",
            Decimal.lt?(delta, 0) && "text-error"
          ]}>
            {format_amount(delta, @current_plan && @current_plan.currency)}
          </span>
        </div>
      </div>

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
                <td>{format_amount(category.total_assigned, @current_plan && @current_plan.currency)}</td>
                <td>{format_amount(category.total_spent, @current_plan && @current_plan.currency)}</td>
                <td>{format_amount(category.total_available, @current_plan && @current_plan.currency)}</td>
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
    current_plan = socket.assigns.current_plan

    dates = %{
      selected: selected_date,
      current: today,
      previous: Date.shift(selected_date, day: -1),
      next: Date.shift(selected_date, month: 1)
    }

    {groups, tbb_data} = Budget.list_categories_with_totals(current_plan.id, month, year)

    socket =
      socket
      |> assign(:page_title, "Listing Categories with Totals")
      |> assign(:category_groups, groups)
      |> assign(:tbb_data, tbb_data)
      |> assign(:dates, dates)

    {:ok, socket}
  end

  defp get_year_and_month(%{"year" => year, "month" => month}) do
    {String.to_integer(year), String.to_integer(month)}
  end
end
