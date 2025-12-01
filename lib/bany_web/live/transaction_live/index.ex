defmodule BanyWeb.TransactionLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Transactions
        <:actions>
          <.button variant="primary" navigate={~p"/transactions/new"}>
            <.icon name="hero-plus" /> New Transaction
          </.button>
        </:actions>
      </.header>

      <.table
        id="transactions"
        rows={@streams.transactions}
        row_click={fn {_id, transaction} -> JS.navigate(~p"/transactions/#{transaction}") end}
      >
        <:col :let={{_id, transaction}} label="Memo">{transaction.memo}</:col>
        <:col :let={{_id, transaction}} label="Date">{transaction.date}</:col>
        <:col :let={{_id, transaction}} label="Amount">{transaction.amount}</:col>
        <:col :let={{_id, transaction}} label="Category">
          <%= if transaction.category do %>
            <.link navigate={~p"/categories/#{transaction.category}"}>
              {transaction.category.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:col>
        <:col :let={{_id, transaction}} label="Account">
          <%= if transaction.account do %>
            <.link navigate={~p"/accounts/#{transaction.account}"}>
              {transaction.account.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:col>
        <:action :let={{_id, transaction}}>
          <div class="sr-only">
            <.link navigate={~p"/transactions/#{transaction}"}>Show</.link>
          </div>
          <.link navigate={~p"/transactions/#{transaction}/edit"}>Edit</.link>
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
    {:ok,
     socket
     |> assign(:page_title, "Listing Transactions")
     |> stream(:transactions, Ledger.list_transactions() |> Repo.preload([:category, :account]))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    transaction = Ledger.get_transaction!(id)
    {:ok, _} = Ledger.delete_transaction(transaction)

    {:noreply, stream_delete(socket, :transactions, transaction)}
  end
end
