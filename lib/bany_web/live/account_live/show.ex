defmodule BanyWeb.AccountLive.Show do
  use BanyWeb, :live_view

  alias Bany.Ledger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan}>
      <.header>
        Account {@account.id}
        <:subtitle>This is an account record from your database.</:subtitle>
        <:actions>
          <.button navigate={accounts_path(@current_plan)}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={account_edit_path(@current_plan, @account)}>
            <.icon name="hero-pencil-square" /> Edit account
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@account.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Account")
     |> assign(:account, Ledger.get_account!(id))}
  end

  defp accounts_path(nil), do: ~p"/accounts"
  defp accounts_path(plan), do: ~p"/plans/#{plan}/accounts"

  defp account_edit_path(nil, a), do: ~p"/accounts/#{a}/edit?return_to=show"
  defp account_edit_path(plan, a), do: ~p"/plans/#{plan}/accounts/#{a}/edit?return_to=show"
end
