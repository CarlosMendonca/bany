defmodule BanyWeb.PayeeLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Payees
        <:actions>
          <.button variant="primary" navigate={payees_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Payee
          </.button>
        </:actions>
      </.header>

      <.table
        id="payees"
        rows={@streams.payees}
        row_click={fn {_id, payee} -> JS.navigate(payee_path(@current_plan, payee)) end}
      >
        <:col :let={{_id, payee}} label="Name">{payee.name}</:col>
        <:action :let={{_id, payee}}>
          <div class="sr-only">
            <.link navigate={payee_path(@current_plan, payee)}>Show</.link>
          </div>
          <.link navigate={payee_edit_path(@current_plan, payee)}>Edit</.link>
        </:action>
        <:action :let={{id, payee}}>
          <.link
            phx-click={JS.push("delete", value: %{id: payee.id}) |> hide("##{id}")}
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

    payees =
      if current_plan,
        do: Ledger.list_payees_for_plan(current_plan.id),
        else: Ledger.list_payees()

    {:ok,
     socket
     |> assign(:page_title, "Listing Payees")
     |> stream(:payees, payees)}
  end

  defp payees_new_path(nil), do: ~p"/payees/new"
  defp payees_new_path(plan), do: ~p"/plans/#{plan}/payees/new"

  defp payee_path(nil, p), do: ~p"/payees/#{p}"
  defp payee_path(plan, p), do: ~p"/plans/#{plan}/payees/#{p}"

  defp payee_edit_path(nil, p), do: ~p"/payees/#{p}/edit"
  defp payee_edit_path(plan, p), do: ~p"/plans/#{plan}/payees/#{p}/edit"

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    payee = Ledger.get_payee!(id)
    {:ok, _} = Ledger.delete_payee(payee)

    {:noreply, stream_delete(socket, :payees, payee)}
  end
end
