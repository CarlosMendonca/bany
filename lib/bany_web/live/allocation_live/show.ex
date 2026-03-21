defmodule BanyWeb.AllocationLive.Show do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Allocation {@allocation.id}
        <:subtitle>This is a allocation record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/plans/#{@current_plan.id}/allocations"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/plans/#{@current_plan.id}/allocations/#{@allocation}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit allocation
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Amount">{@allocation.amount}</:item>
        <:item title="Allocated on">{@allocation.allocated_on}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Allocation")
     |> assign(:allocation, Budget.get_allocation!(id))}
  end
end
