defmodule BanyWeb.PlanLive.Show do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Plan {@plan.id}
        <:subtitle>This is a plan record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/plans"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/plans/#{@plan}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit plan
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@plan.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Plan")
     |> assign(:plan, Budget.get_plan!(id))}
  end
end
