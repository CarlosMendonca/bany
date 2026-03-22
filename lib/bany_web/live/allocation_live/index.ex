defmodule BanyWeb.AllocationLive.Index do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Allocations
        <:actions>
          <.button variant="primary" navigate={~p"/plans/#{@current_plan.id}/allocations/new"}>
            <.icon name="hero-plus" /> New Allocation
          </.button>
        </:actions>
      </.header>

      <.table
        id="allocations"
        rows={@streams.allocations}
        row_click={fn {_id, allocation} -> JS.navigate(~p"/plans/#{@current_plan.id}/allocations/#{allocation}") end}
      >
        <:col :let={{_id, allocation}} label="Amount">
          {format_amount(allocation.amount, @current_plan && @current_plan.currency)}
        </:col>
        <:col :let={{_id, allocation}} label="Allocated on">{allocation.allocated_on}</:col>
        <:action :let={{_id, allocation}}>
          <div class="sr-only">
            <.link navigate={~p"/plans/#{@current_plan.id}/allocations/#{allocation}"}>Show</.link>
          </div>
          <.link navigate={~p"/plans/#{@current_plan.id}/allocations/#{allocation}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, allocation}}>
          <.link
            phx-click={JS.push("delete", value: %{id: allocation.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_plan = socket.assigns.current_plan

    {:ok,
     socket
     |> assign(:page_title, "Listing Allocations")
     |> stream(:allocations, Budget.list_allocations_for_plan(current_plan.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    allocation = Budget.get_allocation!(id)
    {:ok, _} = Budget.delete_allocation(allocation)

    {:noreply, stream_delete(socket, :allocations, allocation)}
  end
end
