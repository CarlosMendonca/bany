defmodule BanyWeb.AccountLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Accounts
        <:actions>
          <.button variant="primary" navigate={accounts_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Account
          </.button>
        </:actions>
      </.header>

      <.table
        id="accounts"
        rows={@streams.accounts}
        row_click={fn {_id, account} -> JS.navigate(account_path(@current_plan, account)) end}
      >
        <:col :let={{_id, account}} label="Name">{account.name}</:col>
        <:action :let={{_id, account}}>
          <div class="sr-only">
            <.link navigate={account_path(@current_plan, account)}>Show</.link>
          </div>
          <.link navigate={account_edit_path(@current_plan, account)}>Edit</.link>
        </:action>
        <:action :let={{id, account}}>
          <.link
            phx-click={JS.push("delete", value: %{id: account.id}) |> hide("##{id}")}
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

    accounts =
      if current_plan,
        do: Ledger.list_accounts_for_plan(current_plan.id),
        else: Ledger.list_accounts()

    {:ok,
     socket
     |> assign(:page_title, "Listing Accounts")
     |> stream(:accounts, accounts)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    account = Ledger.get_account!(id)
    {:ok, _} = Ledger.delete_account(account)

    {:noreply, stream_delete(socket, :accounts, account)}
  end

  defp accounts_new_path(nil), do: ~p"/accounts/new"
  defp accounts_new_path(plan), do: ~p"/plans/#{plan}/accounts/new"

  defp account_path(nil, a), do: ~p"/accounts/#{a}"
  defp account_path(plan, a), do: ~p"/plans/#{plan}/accounts/#{a}"

  defp account_edit_path(nil, a), do: ~p"/accounts/#{a}/edit"
  defp account_edit_path(plan, a), do: ~p"/plans/#{plan}/accounts/#{a}/edit"
end
