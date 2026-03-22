defmodule BanyWeb.TransactionLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Transactions
        <:actions>
          <.button variant="primary" navigate={transactions_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Transaction
          </.button>
        </:actions>
      </.header>

      <form phx-change="search" class="flex items-center gap-2">
        <input
          id="transaction-search"
          type="search"
          name="query"
          value={@query}
          placeholder="Search memo, payee, amount… (press / to focus)"
          class="input input-bordered w-full max-w-md"
          phx-debounce="200"
          phx-hook="FocusOnSlash"
          autocomplete="off"
        />
      </form>

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
        <:col :let={{_id, transaction}} label="Payee">
          <%= if transaction.payee do %>
            <.link navigate={payee_path(@current_plan, transaction.payee)}>
              {highlight(transaction.payee.name, @query)}
            </.link>
          <% end %>
        </:col>
        <:col :let={{_id, transaction}} label="Memo">{highlight(transaction.memo, @query)}</:col>
        <:col :let={{_id, transaction}} label="Amount">{highlight(to_string(transaction.amount), @query)}</:col>
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
        do: Ledger.list_transactions_for_plan(current_plan.id) |> Repo.preload([:category, :account, :payee]),
        else: Ledger.list_transactions() |> Repo.preload([:category, :account, :payee])

    {:ok,
     socket
     |> assign(:page_title, "Listing Transactions")
     |> assign(:query, "")
     |> stream(:transactions, transactions)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    current_plan = socket.assigns.current_plan
    query = String.trim(query)

    transactions =
      if current_plan,
        do: Ledger.search_transactions_for_plan(current_plan.id, query),
        else: Ledger.search_transactions(query)

    {:noreply,
     socket
     |> assign(:query, query)
     |> stream(:transactions, transactions, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    transaction = Ledger.get_transaction!(id)
    {:ok, _} = Ledger.delete_transaction(transaction)

    {:noreply, stream_delete(socket, :transactions, transaction)}
  end

  defp highlight(nil, _query), do: ""
  defp highlight(text, query) when query in ["", nil], do: text

  defp highlight(text, query) do
    text_str = to_string(text)
    escaped_query = Regex.escape(query)

    case Regex.compile(escaped_query, [:caseless]) do
      {:ok, regex} ->
        parts = Regex.split(regex, text_str, include_captures: true)

        html =
          Enum.map_join(parts, fn part ->
            safe = part |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

            if part != "" and Regex.match?(regex, part) do
              "<mark class=\"bg-yellow-200 dark:bg-yellow-800 rounded\">#{safe}</mark>"
            else
              safe
            end
          end)

        Phoenix.HTML.raw(html)

      {:error, _} ->
        text
    end
  end

  defp payee_path(nil, p), do: ~p"/payees/#{p}"
  defp payee_path(plan, p), do: ~p"/plans/#{plan}/payees/#{p}"

  defp transactions_new_path(nil), do: ~p"/transactions/new"
  defp transactions_new_path(plan), do: ~p"/plans/#{plan}/transactions/new"

  defp transaction_path(nil, t), do: ~p"/transactions/#{t}"
  defp transaction_path(plan, t), do: ~p"/plans/#{plan}/transactions/#{t}"

  defp transaction_edit_path(nil, t), do: ~p"/transactions/#{t}/edit"
  defp transaction_edit_path(plan, t), do: ~p"/plans/#{plan}/transactions/#{t}/edit"
end
