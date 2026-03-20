defmodule BanyWeb.TransactionLive.Show do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan}>
      <.header>
        Transaction {@transaction.id}
        <:subtitle>This is a transaction record from your database.</:subtitle>
        <:actions>
          <.button navigate={transactions_path(@current_plan)}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={transaction_edit_path(@current_plan, @transaction)}>
            <.icon name="hero-pencil-square" /> Edit transaction
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Memo">{@transaction.memo}</:item>
        <:item title="Date">{@transaction.date}</:item>
        <:item title="Amount">{@transaction.amount}</:item>
        <:item title="Category">
          <%= if @transaction.category do %>
            <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/categories/#{@transaction.category}", else: ~p"/categories/#{@transaction.category}"}>
              {@transaction.category.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:item>
        <:item title="Account">
          <%= if @transaction.account do %>
            <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/accounts/#{@transaction.account}", else: ~p"/accounts/#{@transaction.account}"}>
              {@transaction.account.name}
            </.link>
          <% else %>
            (none)
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Transaction")
     |> assign(:transaction, Ledger.get_transaction!(id) |> Repo.preload([:category, :account]))}
  end

  defp transactions_path(nil), do: ~p"/transactions"
  defp transactions_path(plan), do: ~p"/plans/#{plan}/transactions"

  defp transaction_edit_path(nil, t), do: ~p"/transactions/#{t}/edit?return_to=show"
  defp transaction_edit_path(plan, t), do: ~p"/plans/#{plan}/transactions/#{t}/edit?return_to=show"
end
