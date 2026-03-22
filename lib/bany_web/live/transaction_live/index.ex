defmodule BanyWeb.TransactionLive.Index do
  use BanyWeb, :live_view

  alias Bany.Budget
  alias Bany.Ledger

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

      <div class="flex flex-wrap items-center gap-2">
        <form phx-change="search" class="flex-1 min-w-48">
          <input
            id="transaction-search"
            type="search"
            name="query"
            value={@query}
            placeholder="Search memo, payee, amount… (press / to focus)"
            class="input input-bordered w-full"
            phx-debounce="200"
            phx-hook="FocusOnSlash"
            autocomplete="off"
          />
        </form>

        <details id="category-filter" class="dropdown" phx-hook="FilterDropdown">
          <summary class="btn btn-outline btn-sm">
            {category_filter_label(@selected_category_ids, @categories)}
            <.icon name="hero-chevron-down-micro" />
          </summary>
          <div class="dropdown-content z-10 bg-base-100 rounded-box shadow-lg p-2 min-w-48 max-h-72 overflow-y-auto flex flex-col gap-1">
            <a
              phx-click="select_all_categories"
              class={["link link-hover text-sm px-1", @selected_category_ids == nil && "font-bold"]}
            >
              All
            </a>
            <div class="divider my-0" />
            <label
              :for={cat <- @categories}
              class="flex items-center gap-2 cursor-pointer hover:bg-base-200 rounded px-1 py-0.5 text-sm"
            >
              <input
                type="checkbox"
                class="checkbox checkbox-sm"
                checked={item_selected?(@selected_category_ids, cat.id)}
                phx-click="toggle_category"
                phx-value-id={cat.id}
              />
              {cat.name}
            </label>
          </div>
        </details>

        <details id="account-filter" class="dropdown" phx-hook="FilterDropdown">
          <summary class="btn btn-outline btn-sm">
            {account_filter_label(@selected_account_ids, @accounts)}
            <.icon name="hero-chevron-down-micro" />
          </summary>
          <div class="dropdown-content z-10 bg-base-100 rounded-box shadow-lg p-2 min-w-48 max-h-72 overflow-y-auto flex flex-col gap-1">
            <a
              phx-click="select_all_accounts"
              class={["link link-hover text-sm px-1", @selected_account_ids == nil && "font-bold"]}
            >
              All
            </a>
            <div class="divider my-0" />
            <label
              :for={acc <- @accounts}
              class="flex items-center gap-2 cursor-pointer hover:bg-base-200 rounded px-1 py-0.5 text-sm"
            >
              <input
                type="checkbox"
                class="checkbox checkbox-sm"
                checked={item_selected?(@selected_account_ids, acc.id)}
                phx-click="toggle_account"
                phx-value-id={acc.id}
              />
              {acc.name}
            </label>
          </div>
        </details>

        <details id="date-filter" class="dropdown" phx-hook="FilterDropdown">
          <summary class="btn btn-outline btn-sm">
            {date_filter_label(@date_preset, @date_from, @date_to)}
            <.icon name="hero-chevron-down-micro" />
          </summary>
          <div class="dropdown-content z-10 bg-base-100 rounded-box shadow-lg p-4 min-w-64 flex flex-col gap-2">
            <form phx-change="filter_date" class="flex flex-col gap-2">
              <label
                :for={
                  {value, label} <- [
                    {"all_time", "All Time"},
                    {"current_month", "This Month"},
                    {"previous_month", "Last Month"},
                    {"custom", "Custom Range"}
                  ]
                }
                class="flex items-center gap-2 cursor-pointer text-sm"
              >
                <input
                  type="radio"
                  name="preset"
                  value={value}
                  checked={@date_preset == value}
                  class="radio radio-sm"
                />
                {label}
              </label>
              <%= if @date_preset == "custom" do %>
                <div class="flex flex-col gap-1 mt-1 pl-5">
                  <label class="text-xs opacity-60">From</label>
                  <input
                    type="date"
                    name="date_from"
                    value={@date_from}
                    class="input input-bordered input-sm"
                    phx-debounce="blur"
                  />
                  <label class="text-xs opacity-60">To</label>
                  <input
                    type="date"
                    name="date_to"
                    value={@date_to}
                    class="input input-bordered input-sm"
                    phx-debounce="blur"
                  />
                </div>
              <% end %>
            </form>
          </div>
        </details>
        <%= if filters_active?(@query, @selected_category_ids, @selected_account_ids, @date_preset) do %>
          <button phx-click="reset_filters" class="btn btn-ghost btn-sm text-error">
            <.icon name="hero-x-mark-micro" /> Clear filters
          </button>
        <% end %>
      </div>

      <p class="text-sm opacity-60">
        <%= if @filtered_count == @total_count do %>
          {@total_count} transactions
        <% else %>
          Showing {@filtered_count} of {@total_count} transactions
        <% end %>
      </p>

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

    categories =
      if current_plan,
        do: Budget.list_categories_for_plan(current_plan.id),
        else: Budget.list_categories()

    accounts =
      if current_plan,
        do: Ledger.list_accounts_for_plan(current_plan.id),
        else: Ledger.list_accounts()

    total_count = Ledger.count_transactions(current_plan && current_plan.id)

    {:ok,
     socket
     |> assign(:page_title, "Listing Transactions")
     |> assign(:query, "")
     |> assign(:selected_category_ids, nil)
     |> assign(:selected_account_ids, nil)
     |> assign(:date_preset, "all_time")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:categories, categories)
     |> assign(:accounts, accounts)
     |> assign(:total_count, total_count)
     |> assign(:filtered_count, total_count)
     |> reload_transactions()}
  end

  @impl true
  def handle_event("search", %{"query" => q}, socket) do
    {:noreply, socket |> assign(:query, String.trim(q)) |> reload_transactions()}
  end

  def handle_event("toggle_category", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    all_ids = Enum.map(socket.assigns.categories, & &1.id)
    new_ids = toggle_id(socket.assigns.selected_category_ids, id, all_ids)
    {:noreply, socket |> assign(:selected_category_ids, new_ids) |> reload_transactions()}
  end

  def handle_event("select_all_categories", _params, socket) do
    {:noreply, socket |> assign(:selected_category_ids, nil) |> reload_transactions()}
  end

  def handle_event("toggle_account", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    all_ids = Enum.map(socket.assigns.accounts, & &1.id)
    new_ids = toggle_id(socket.assigns.selected_account_ids, id, all_ids)
    {:noreply, socket |> assign(:selected_account_ids, new_ids) |> reload_transactions()}
  end

  def handle_event("select_all_accounts", _params, socket) do
    {:noreply, socket |> assign(:selected_account_ids, nil) |> reload_transactions()}
  end

  def handle_event("filter_date", params, socket) do
    preset = Map.get(params, "preset", "all_time")

    {from, to} =
      if preset == "custom",
        do: {parse_date_input(params["date_from"]), parse_date_input(params["date_to"])},
        else: {nil, nil}

    {:noreply,
     socket
     |> assign(:date_preset, preset)
     |> assign(:date_from, from)
     |> assign(:date_to, to)
     |> reload_transactions()}
  end

  def handle_event("reset_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:query, "")
     |> assign(:selected_category_ids, nil)
     |> assign(:selected_account_ids, nil)
     |> assign(:date_preset, "all_time")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> reload_transactions()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    transaction = Ledger.get_transaction!(id)
    {:ok, _} = Ledger.delete_transaction(transaction)
    {:noreply, stream_delete(socket, :transactions, transaction)}
  end

  defp reload_transactions(socket) do
    %{
      current_plan: plan,
      query: query,
      selected_category_ids: cat_ids,
      selected_account_ids: acc_ids,
      date_preset: preset,
      date_from: date_from,
      date_to: date_to
    } = socket.assigns

    {resolved_from, resolved_to} =
      if preset == "custom", do: {date_from, date_to}, else: date_range_for_preset(preset)

    transactions =
      Ledger.filter_transactions(%{
        plan_id: plan && plan.id,
        query: query,
        category_ids: cat_ids,
        account_ids: acc_ids,
        date_from: resolved_from,
        date_to: resolved_to
      })

    socket
    |> assign(:filtered_count, length(transactions))
    |> stream(:transactions, transactions, reset: true)
  end

  defp toggle_id(nil, id, all_ids), do: List.delete(all_ids, id)

  defp toggle_id(ids, id, all_ids) do
    new = if id in ids, do: List.delete(ids, id), else: [id | ids]

    cond do
      new == [] -> nil
      Enum.sort(new) == Enum.sort(all_ids) -> nil
      true -> new
    end
  end

  defp date_range_for_preset("all_time"), do: {nil, nil}

  defp date_range_for_preset("current_month") do
    today = Date.utc_today()
    first = Date.new!(today.year, today.month, 1)
    {first, Date.end_of_month(first)}
  end

  defp date_range_for_preset("previous_month") do
    last_month = Date.shift(Date.utc_today(), month: -1)
    first = Date.new!(last_month.year, last_month.month, 1)
    {first, Date.end_of_month(first)}
  end

  defp parse_date_input(s) when s in [nil, ""], do: nil

  defp parse_date_input(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp category_filter_label(nil, _), do: "Category"
  defp category_filter_label(ids, _), do: "#{length(ids)} selected"

  defp account_filter_label(nil, _), do: "Account"
  defp account_filter_label(ids, _), do: "#{length(ids)} selected"

  defp date_filter_label("all_time", _, _), do: "Date"
  defp date_filter_label("current_month", _, _), do: "This Month"
  defp date_filter_label("previous_month", _, _), do: "Last Month"
  defp date_filter_label("custom", nil, nil), do: "Custom Range"
  defp date_filter_label("custom", f, nil), do: "From #{f}"
  defp date_filter_label("custom", nil, t), do: "Until #{t}"
  defp date_filter_label("custom", f, t), do: "#{f} – #{t}"

  defp filters_active?(query, cat_ids, acc_ids, date_preset) do
    query != "" or cat_ids != nil or acc_ids != nil or date_preset != "all_time"
  end

  defp item_selected?(nil, _id), do: true
  defp item_selected?(ids, id), do: id in ids

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
