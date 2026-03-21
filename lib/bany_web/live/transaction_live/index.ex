defmodule BanyWeb.TransactionLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan}>
      <.header>
        Listing Transactions
        <:actions>
          <.button variant="primary" navigate={transactions_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Transaction
          </.button>
        </:actions>
      </.header>

      <.table
        id="transactions"
        rows={@streams.transactions}
        row_click={fn {_id, transaction} -> JS.navigate(transaction_path(@current_plan, transaction)) end}
      >
        <:col :let={{_id, transaction}} label="Account">
          <%= if transaction.account do %>
            <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/accounts/#{transaction.account}", else: ~p"/accounts/#{transaction.account}"}>
              {transaction.account.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:col>
        <:col :let={{_id, transaction}} label="Date">{transaction.date}</:col>
        <:col :let={{_id, transaction}} label="Category">
          <%= if transaction.category do %>
            <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/categories/#{transaction.category}", else: ~p"/categories/#{transaction.category}"}>
              {transaction.category.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:col>
        <:col :let={{_id, transaction}} label="Memo">{transaction.memo}</:col>
        <:col :let={{_id, transaction}} label="Amount">{transaction.amount}</:col>
        <:action :let={{_id, transaction}}>
          <div class="sr-only">
            <.link navigate={transaction_path(@current_plan, transaction)}>Show</.link>
          </div>
          <.link navigate={transaction_edit_path(@current_plan, transaction)}>Edit</.link>
        </:action>
        <:action :let={{id, transaction}}>
          <.link
            phx-click={JS.push("delete", value: %{id: transaction.id}) |> hide("##{id}")}
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

    transactions =
      if current_plan,
        do: Ledger.list_transactions_for_plan(current_plan.id) |> Repo.preload([:category, :account]),
        else: Ledger.list_transactions() |> Repo.preload([:category, :account])

    {:ok,
     socket
     |> assign(:page_title, "Listing Transactions")
     |> stream(:transactions, transactions)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    transaction = Ledger.get_transaction!(id)
    {:ok, _} = Ledger.delete_transaction(transaction)

    {:noreply, stream_delete(socket, :transactions, transaction)}
  end

  defp transactions_new_path(nil), do: ~p"/transactions/new"
  defp transactions_new_path(plan), do: ~p"/plans/#{plan}/transactions/new"

  defp transaction_path(nil, t), do: ~p"/transactions/#{t}"
  defp transaction_path(plan, t), do: ~p"/plans/#{plan}/transactions/#{t}"

  defp transaction_edit_path(nil, t), do: ~p"/transactions/#{t}/edit"
  defp transaction_edit_path(plan, t), do: ~p"/plans/#{plan}/transactions/#{t}/edit"
end
