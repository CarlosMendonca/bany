defmodule BanyWeb.PayeeLive.Show do
  use BanyWeb, :live_view

  alias Bany.Ledger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        {@payee.name}
        <:subtitle>Payee</:subtitle>
        <:actions>
          <.button navigate={payees_index_path(@current_plan)}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={payee_edit_path(@current_plan, @payee)}>
            <.icon name="hero-pencil-square" /> Edit payee
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@payee.name}</:item>
        <:item title="Linked user">
          {if @payee.user, do: @payee.user.email, else: "(none)"}
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    payee = Ledger.get_payee!(id) |> Bany.Repo.preload(:user)

    {:ok,
     socket
     |> assign(:page_title, "Show Payee")
     |> assign(:payee, payee)}
  end

  defp payees_index_path(nil), do: ~p"/payees"
  defp payees_index_path(plan), do: ~p"/plans/#{plan}/payees"

  defp payee_edit_path(nil, p), do: ~p"/payees/#{p}/edit?return_to=show"
  defp payee_edit_path(plan, p), do: ~p"/plans/#{plan}/payees/#{p}/edit?return_to=show"
end
