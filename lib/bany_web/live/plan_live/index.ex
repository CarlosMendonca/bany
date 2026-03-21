defmodule BanyWeb.PlanLive.Index do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Plans
        <:actions>
          <.button variant="primary" navigate={~p"/plans/new"}>
            <.icon name="hero-plus" /> New Plan
          </.button>
        </:actions>
      </.header>

      <.table
        id="plans"
        rows={@streams.plans}
        row_click={fn {_id, plan} -> JS.navigate(~p"/plans/#{plan}") end}
      >
        <:col :let={{_id, plan}} label="Name">{plan.name}</:col>
        <:action :let={{_id, plan}}>
          <.link href={~p"/plans/#{plan}/category_groups"} class="btn btn-sm btn-secondary">
            Select
          </.link>
        </:action>
        <:action :let={{_id, plan}}>
          <div class="sr-only">
            <.link navigate={~p"/plans/#{plan}"}>Show</.link>
          </div>
          <.link navigate={~p"/plans/#{plan}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, plan}}>
          <.link
            phx-click={JS.push("delete", value: %{id: plan.id}) |> hide("##{id}")}
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
    {:ok,
     socket
     |> assign(:page_title, "Listing Plans")
     |> stream(:plans, Budget.list_plans())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    plan = Budget.get_plan!(id)
    {:ok, _} = Budget.delete_plan(plan)

    {:noreply, stream_delete(socket, :plans, plan)}
  end
end
