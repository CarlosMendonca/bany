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

        <details id="tag-filter" class="dropdown" phx-hook="FilterDropdown">
          <summary class="btn btn-outline btn-sm">
            {tag_filter_label(@selected_tag_ids, @tags)}
            <.icon name="hero-chevron-down-micro" />
          </summary>
          <div class="dropdown-content z-10 bg-base-100 rounded-box shadow-lg p-2 min-w-48 max-h-72 overflow-y-auto flex flex-col gap-1">
            <a
              phx-click="select_all_tags"
              class={["link link-hover text-sm px-1", @selected_tag_ids == nil && "font-bold"]}
            >
              All
            </a>
            <div class="divider my-0" />
            <label
              :for={tag <- @tags}
              class="flex items-center gap-2 cursor-pointer hover:bg-base-200 rounded px-1 py-0.5 text-sm"
            >
              <input
                type="checkbox"
                class="checkbox checkbox-sm"
                checked={item_selected?(@selected_tag_ids, tag.id)}
                phx-click="toggle_tag"
                phx-value-id={tag.id}
              />
              <.tag_chip tag={tag} />
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
        <%= if filters_active?(@query, @selected_category_ids, @selected_account_ids, @date_preset, @selected_tag_ids) do %>
          <button phx-click="reset_filters" class="btn btn-ghost btn-sm text-error">
            <.icon name="hero-x-mark-micro" /> Clear filters
          </button>
        <% end %>
      </div>

      <div class="flex items-center justify-between text-sm opacity-60">
        <span>
          <%= if @filtered_total == @total_count do %>
            {@total_count} transactions
          <% else %>
            {@filtered_total} of {@total_count} transactions match
          <% end %><span id="selected-count-display" class="hidden">, <span id="selected-count-n">0</span> selected</span>
        </span>

        <%= if @total_pages > 1 do %>
          <div class="flex items-center gap-2">
            <button phx-click="prev_page" disabled={@page <= 1} class="btn btn-sm btn-outline">
              <.icon name="hero-chevron-left-micro" />
            </button>
            <span>Page {@page} of {@total_pages}</span>
            <button phx-click="next_page" disabled={@page >= @total_pages} class="btn btn-sm btn-outline">
              <.icon name="hero-chevron-right-micro" />
            </button>
          </div>
        <% end %>
      </div>

      <table id="transactions-table" phx-hook="TransactionTable" data-total={@filtered_total} class="table table-zebra">
        <thead>
          <tr>
            <th class="w-0">
              <input type="checkbox" id="select-all-checkbox" class="checkbox checkbox-sm" tabindex="-1" />
            </th>
            <th><.col_header col={:account} sort_by={@sort_by} sort_dir={@sort_dir}>Account</.col_header></th>
            <th><.col_header col={:date} sort_by={@sort_by} sort_dir={@sort_dir}>Date</.col_header></th>
            <th><.col_header col={:category} sort_by={@sort_by} sort_dir={@sort_dir}>Category</.col_header></th>
            <th><.col_header col={:payee} sort_by={@sort_by} sort_dir={@sort_dir}>Payee</.col_header></th>
            <th><.col_header col={:memo} sort_by={@sort_by} sort_dir={@sort_dir}>Memo</.col_header></th>
            <th>Tags</th>
            <th><.col_header col={:amount} sort_by={@sort_by} sort_dir={@sort_dir}>Amount</.col_header></th>
            <th><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody id="transactions" phx-update="stream">
          <tr :for={{id, transaction} <- @streams.transactions} id={id} data-id={transaction.id}>
            <td class="w-0">
              <input type="checkbox" class="checkbox checkbox-sm" tabindex="-1" />
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              <%= if transaction.account do %>
                <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/accounts/#{transaction.account}", else: ~p"/accounts/#{transaction.account}"}>
                  {transaction.account.name}
                </.link>
              <% else %>
                (none)
              <% end %>
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              {transaction.date}
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              <%= if transaction.category do %>
                <.link navigate={if @current_plan, do: ~p"/plans/#{@current_plan}/categories/#{transaction.category}", else: ~p"/categories/#{transaction.category}"}>
                  {transaction.category.name}
                </.link>
              <% else %>
                (none)
              <% end %>
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              <%= if transaction.payee do %>
                <.link navigate={payee_path(@current_plan, transaction.payee)}>
                  {highlight(transaction.payee.name, @query)}
                </.link>
              <% end %>
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              {highlight(transaction.memo, @query)}
            </td>
            <td>
              <%= case transaction.tags do %>
                <% [] -> %>
                <% [tag] -> %>
                  <.tag_chip tag={tag} />
                <% tags -> %>
                  <div class="flex gap-0.5">
                    <.tag_dot :for={tag <- tags} tag={tag} />
                  </div>
              <% end %>
            </td>
            <td phx-click={JS.navigate(transaction_path(@current_plan, transaction))} class="hover:cursor-pointer">
              {highlight(format_amount(transaction.amount, @current_plan && @current_plan.currency), @query)}
            </td>
            <td class="w-0 font-semibold">
              <div class="flex gap-4">
                <div class="sr-only">
                  <.link navigate={transaction_path(@current_plan, transaction)}>Show</.link>
                </div>
                <.link navigate={transaction_edit_path(@current_plan, transaction)}>Edit</.link>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <div id="edit-bar" class="sticky bottom-0 z-10 bg-base-100 border-t border-base-300 py-2">
        <.form
          :if={@edit_changeset}
          for={@edit_changeset}
          id="edit-bar-form"
          phx-submit="edit_bar_save"
          class="flex flex-wrap items-end gap-2 mb-2 p-2 bg-base-200 rounded-lg"
        >
          <%!-- Date --%>
          <label class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Date</span>
            <input
              type="date"
              name="edit_bar[date]"
              value={if :date in @edit_multi_fields, do: "", else: Phoenix.HTML.Form.input_value(@edit_changeset, :date)}
              placeholder={if :date in @edit_multi_fields, do: "(multiple)", else: ""}
              class={["input input-sm input-bordered w-36",
                @edit_changeset[:date].errors != [] && "input-error"]}
            />
            <span :for={{msg, opts} <- @edit_changeset[:date].errors} class="text-xs text-error">
              {translate_error({msg, opts})}
            </span>
          </label>

          <%!-- Category --%>
          <label class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Category</span>
            <select name="edit_bar[category_id]" class="select select-sm select-bordered">
              <%= if :category_id in @edit_multi_fields do %>
                <option value="__unchanged__" selected>(multiple values)</option>
              <% else %>
                <option value="" selected={is_nil(Phoenix.HTML.Form.input_value(@edit_changeset, :category_id))}>
                  (none)
                </option>
              <% end %>
              <option
                :for={cat <- @categories}
                value={cat.id}
                selected={not (:category_id in @edit_multi_fields) and Phoenix.HTML.Form.input_value(@edit_changeset, :category_id) == cat.id}
              >{cat.name}</option>
            </select>
          </label>

          <%!-- Payee --%>
          <label class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Payee</span>
            <input
              type="text"
              name="edit_bar[payee_name]"
              list="payee-options"
              value={payee_name_value(@edit_changeset, @edit_multi_fields, @payees)}
              placeholder={if :payee_id in @edit_multi_fields, do: "(multiple values)", else: ""}
              class="input input-sm input-bordered w-40"
              autocomplete="off"
            />
            <datalist id="payee-options">
              <option :for={payee <- @payees} value={payee.name} />
            </datalist>
          </label>

          <%!-- Memo --%>
          <label class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Memo</span>
            <input
              type="text"
              name="edit_bar[memo]"
              value={if :memo in @edit_multi_fields, do: "", else: (Phoenix.HTML.Form.input_value(@edit_changeset, :memo) || "")}
              placeholder={if :memo in @edit_multi_fields, do: "(multiple values)", else: ""}
              class="input input-sm input-bordered w-40"
            />
          </label>

          <%!-- Tags (single-row edit only) --%>
          <label :if={length(@edit_ids) == 1} class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Tags</span>
            <details id="edit-bar-tags-dropdown" class="dropdown" phx-hook="FilterDropdown">
              <summary class="input input-sm input-bordered w-36 cursor-pointer flex items-center">
                {tag_edit_label(@edit_tag_ids, @tags)}
              </summary>
              <div class="dropdown-content z-10 bg-base-100 rounded-box shadow-lg p-2 min-w-48 max-h-60 overflow-y-auto flex flex-col gap-1">
                <label
                  :for={tag <- @tags}
                  class="flex items-center gap-2 cursor-pointer hover:bg-base-200 rounded px-1 py-0.5 text-sm"
                >
                  <input
                    type="checkbox"
                    class="checkbox checkbox-xs"
                    name="edit_bar[tag_ids][]"
                    value={tag.id}
                    checked={tag.id in @edit_tag_ids}
                  />
                  <.tag_chip tag={tag} />
                </label>
              </div>
            </details>
          </label>

          <%!-- Amount --%>
          <label class="flex flex-col gap-0.5">
            <span class="text-xs opacity-60">Amount</span>
            <input
              type="number"
              name="edit_bar[amount]"
              value={if :amount in @edit_multi_fields, do: "", else: (Phoenix.HTML.Form.input_value(@edit_changeset, :amount) || "")}
              placeholder={if :amount in @edit_multi_fields, do: "(multiple)", else: ""}
              step="any"
              class={["input input-sm input-bordered w-28",
                @edit_changeset[:amount].errors != [] && "input-error"]}
            />
            <span :for={{msg, opts} <- @edit_changeset[:amount].errors} class="text-xs text-error">
              {translate_error({msg, opts})}
            </span>
          </label>

          <button type="submit" class="btn btn-sm btn-success btn-square" title="Save">
            <.icon name="hero-check" />
          </button>

          <button type="button" phx-click="edit_bar_cancel" class="btn btn-sm btn-ghost btn-square" title="Cancel">
            <.icon name="hero-x-mark" />
          </button>
        </.form>

        <%!-- Always in DOM so JS hook can cache on mounted() --%>
        <button id="delete-selected-btn" class="btn btn-error btn-sm" disabled>
          <.icon name="hero-trash" />
          Delete (<span id="delete-selected-count">0</span>)
        </button>
      </div>
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

    payees =
      if current_plan,
        do: Ledger.list_payees_for_plan(current_plan.id),
        else: Ledger.list_payees()

    total_count = Ledger.count_transactions(current_plan && current_plan.id)
    user = socket.assigns.current_scope.user
    tags = Ledger.list_tags_for_user(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Listing Transactions")
     |> assign(:query, "")
     |> assign(:selected_category_ids, nil)
     |> assign(:selected_account_ids, nil)
     |> assign(:selected_tag_ids, nil)
     |> assign(:date_preset, "all_time")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:categories, categories)
     |> assign(:accounts, accounts)
     |> assign(:payees, payees)
     |> assign(:tags, tags)
     |> assign(:total_count, total_count)
     |> assign(:page, 1)
     |> assign(:page_size, 50)
     |> assign(:sort_by, :date)
     |> assign(:sort_dir, :desc)
     |> assign(:edit_ids, [])
     |> assign(:edit_changeset, nil)
     |> assign(:edit_multi_fields, MapSet.new())
     |> assign(:edit_tag_ids, [])
     |> assign(:page_loaded, false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page =
      case Integer.parse(Map.get(params, "page", "1")) do
        {n, ""} when n > 0 -> n
        _ -> 1
      end

    if socket.assigns.page_loaded and socket.assigns.page == page do
      {:noreply, socket}
    else
      {:noreply, socket |> assign(:page_loaded, true) |> assign(:page, page) |> reload_transactions()}
    end
  end

  @impl true
  def handle_event("search", %{"query" => q}, socket) do
    {:noreply, socket |> assign(:query, String.trim(q)) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("toggle_category", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    all_ids = Enum.map(socket.assigns.categories, & &1.id)
    new_ids = toggle_id(socket.assigns.selected_category_ids, id, all_ids)
    {:noreply, socket |> assign(:selected_category_ids, new_ids) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("select_all_categories", _params, socket) do
    {:noreply, socket |> assign(:selected_category_ids, nil) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("toggle_account", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    all_ids = Enum.map(socket.assigns.accounts, & &1.id)
    new_ids = toggle_id(socket.assigns.selected_account_ids, id, all_ids)
    {:noreply, socket |> assign(:selected_account_ids, new_ids) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("select_all_accounts", _params, socket) do
    {:noreply, socket |> assign(:selected_account_ids, nil) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("toggle_tag", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    all_ids = Enum.map(socket.assigns.tags, & &1.id)
    new_ids = toggle_id(socket.assigns.selected_tag_ids, id, all_ids)
    {:noreply, socket |> assign(:selected_tag_ids, new_ids) |> assign(:page, 1) |> reload_transactions_with_reset()}
  end

  def handle_event("select_all_tags", _params, socket) do
    {:noreply, socket |> assign(:selected_tag_ids, nil) |> assign(:page, 1) |> reload_transactions_with_reset()}
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
     |> assign(:page, 1)
     |> reload_transactions_with_reset()}
  end

  def handle_event("reset_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:query, "")
     |> assign(:selected_category_ids, nil)
     |> assign(:selected_account_ids, nil)
     |> assign(:selected_tag_ids, nil)
     |> assign(:date_preset, "all_time")
     |> assign(:date_from, nil)
     |> assign(:date_to, nil)
     |> assign(:page, 1)
     |> reload_transactions_with_reset()}
  end

  @sortable_columns [:account, :date, :category, :payee, :memo, :amount]

  def handle_event("sort_column", %{"col" => col_str}, socket) do
    col = String.to_existing_atom(col_str)

    if col in @sortable_columns do
      new_dir =
        if socket.assigns.sort_by == col,
          do: (if socket.assigns.sort_dir == :asc, do: :desc, else: :asc),
          else: :asc

      {:noreply,
       socket
       |> assign(:sort_by, col)
       |> assign(:sort_dir, new_dir)
       |> assign(:page, 1)
       |> reload_transactions_with_reset()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("prev_page", _params, socket) do
    {:noreply, push_patch(socket, to: page_path(socket, max(1, socket.assigns.page - 1)))}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply, push_patch(socket, to: page_path(socket, min(socket.assigns.total_pages, socket.assigns.page + 1)))}
  end

  def handle_event("select_all", _params, socket) do
    ids = socket |> build_filter_opts() |> Map.delete(:page) |> Map.delete(:page_size) |> Map.delete(:sort_by) |> Map.delete(:sort_dir) |> Ledger.get_filtered_transaction_ids()
    {:noreply, push_event(socket, "all_ids_selected", %{ids: ids})}
  end

  def handle_event("delete_selected", %{"ids" => ids}, socket) when is_list(ids) do
    int_ids = Enum.map(ids, &String.to_integer/1)
    Ledger.delete_transactions(int_ids)
    {:noreply, socket |> assign(:page, 1) |> push_patch(to: page_path(socket, 1)) |> reload_transactions()}
  end

  def handle_event("selection_changed", %{"ids" => []}, socket) do
    {:noreply, clear_edit_state(socket)}
  end

  def handle_event("selection_changed", %{"ids" => ids}, socket) do
    transactions = Ledger.get_transactions_for_edit(ids)
    {common, multi_fields} = compute_common_values(transactions)
    base = struct(%Bany.Ledger.Transaction{}, common)
    changeset = to_form(Ledger.change_transaction(base), as: :edit_bar)

    edit_tag_ids =
      if length(ids) == 1 do
        t = Enum.find(transactions, fn t -> to_string(t.id) == hd(ids) end)
        if t, do: Enum.map(t.tags, & &1.id), else: []
      else
        []
      end

    {:noreply,
     socket
     |> assign(:edit_ids, ids)
     |> assign(:edit_changeset, changeset)
     |> assign(:edit_multi_fields, multi_fields)
     |> assign(:edit_tag_ids, edit_tag_ids)}
  end

  def handle_event("edit_bar_save", %{"edit_bar" => params}, socket) do
    {tag_ids_raw, params} = Map.pop(params, "tag_ids", [])
    params = resolve_payee_param(params)
    ids = socket.assigns.edit_ids

    if length(ids) == 1 do
      t = Ledger.get_transaction!(String.to_integer(hd(ids)))

      case Ledger.update_transaction(t, params) do
        {:ok, updated} ->
          tag_ids = Enum.map(List.wrap(tag_ids_raw), &String.to_integer/1)
          Ledger.set_transaction_tags(updated, tag_ids)

          {:noreply,
           socket
           |> clear_edit_state()
           |> push_event("clear-table-selection", %{})
           |> reload_transactions()}

        {:error, cs} ->
          {:noreply, assign(socket, :edit_changeset, to_form(cs, as: :edit_bar, action: :validate))}
      end
    else
      multi_fields = socket.assigns.edit_multi_fields

      clean_params =
        params
        |> Enum.reject(fn {k, v} ->
          field = String.to_existing_atom(k)
          v == "__unchanged__" or (v in ["", nil] and MapSet.member?(multi_fields, field))
        end)
        |> Map.new()

      case Ledger.bulk_update_transactions(ids, clean_params) do
        :ok ->
          {:noreply,
           socket
           |> clear_edit_state()
           |> push_event("clear-table-selection", %{})
           |> reload_transactions()}

        {:error, cs} ->
          {:noreply, assign(socket, :edit_changeset, to_form(cs, as: :edit_bar, action: :validate))}
      end
    end
  end

  def handle_event("edit_bar_cancel", _params, socket) do
    {:noreply, socket |> clear_edit_state() |> push_event("clear-table-selection", %{})}
  end

  defp reload_transactions_with_reset(socket) do
    socket
    |> clear_edit_state()
    |> push_event("clear-table-selection", %{})
    |> push_patch(to: page_path(socket, 1))
    |> reload_transactions()
  end

  defp clear_edit_state(socket) do
    socket
    |> assign(:edit_ids, [])
    |> assign(:edit_changeset, nil)
    |> assign(:edit_multi_fields, MapSet.new())
    |> assign(:edit_tag_ids, [])
  end

  defp payee_name_value(changeset, multi_fields, payees) do
    if :payee_id in multi_fields do
      ""
    else
      case Phoenix.HTML.Form.input_value(changeset, :payee_id) do
        nil -> ""
        id  -> Enum.find_value(payees, "", fn p -> if p.id == id, do: p.name end)
      end
    end
  end

  defp resolve_payee_param(params) do
    case Map.pop(params, "payee_name") do
      {nil, params} ->
        params
      {"", rest} ->
        Map.put(rest, "payee_id", "")
      {name, rest} ->
        case Ledger.find_or_create_payee_by_name(name) do
          nil   -> rest
          payee -> Map.put(rest, "payee_id", to_string(payee.id))
        end
    end
  end

  defp compute_common_values([]), do: {%{}, MapSet.new()}

  defp compute_common_values(transactions) do
    fields = [:date, :amount, :memo, :category_id, :payee_id]

    Enum.reduce(fields, {%{}, MapSet.new()}, fn field, {common, multi} ->
      unique = transactions |> Enum.map(&Map.get(&1, field)) |> Enum.uniq()

      if length(unique) == 1,
        do: {Map.put(common, field, hd(unique)), multi},
        else: {common, MapSet.put(multi, field)}
    end)
  end

  defp build_filter_opts(socket) do
    %{
      current_plan: plan,
      query: query,
      selected_category_ids: cat_ids,
      selected_account_ids: acc_ids,
      selected_tag_ids: tag_ids,
      date_preset: preset,
      date_from: date_from,
      date_to: date_to,
      page: page,
      page_size: page_size,
      sort_by: sort_by,
      sort_dir: sort_dir,
      current_scope: scope
    } = socket.assigns

    {resolved_from, resolved_to} =
      if preset == "custom", do: {date_from, date_to}, else: date_range_for_preset(preset)

    %{
      plan_id: plan && plan.id,
      query: query,
      category_ids: cat_ids,
      account_ids: acc_ids,
      tag_ids: tag_ids,
      user_id: scope.user.id,
      date_from: resolved_from,
      date_to: resolved_to,
      page: page,
      page_size: page_size,
      sort_by: sort_by,
      sort_dir: sort_dir
    }
  end

  defp reload_transactions(socket) do
    filter_opts = build_filter_opts(socket)
    page_size = socket.assigns.page_size
    page = socket.assigns.page

    filtered_total = Ledger.count_filtered_transactions(filter_opts)
    total_pages    = max(1, ceil(filtered_total / page_size))

    if page > total_pages do
      socket
      |> assign(:filtered_total, filtered_total)
      |> assign(:total_pages, total_pages)
      |> push_patch(to: page_path(socket, 1))
    else
      transactions = Ledger.filter_transactions(filter_opts)

      socket
      |> assign(:filtered_total, filtered_total)
      |> assign(:total_pages, total_pages)
      |> stream(:transactions, transactions, reset: true)
    end
  end

  attr :col, :atom, required: true
  attr :sort_by, :atom, required: true
  attr :sort_dir, :atom, required: true
  slot :inner_block, required: true

  defp col_header(assigns) do
    ~H"""
    <button phx-click="sort_column" phx-value-col={@col} class="flex items-center gap-1">
      {render_slot(@inner_block)}
      <.icon
        :if={@sort_by == @col}
        name={if @sort_dir == :asc, do: "hero-chevron-up-micro", else: "hero-chevron-down-micro"}
      />
    </button>
    """
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

  defp tag_filter_label(nil, _), do: "Tags"
  defp tag_filter_label(ids, _), do: "#{length(ids)} selected"

  defp tag_edit_label([], _tags), do: "No tags"
  defp tag_edit_label(ids, tags) do
    names = tags |> Enum.filter(&(&1.id in ids)) |> Enum.map(& &1.name)
    Enum.join(names, ", ")
  end

  defp date_filter_label("all_time", _, _), do: "Date"
  defp date_filter_label("current_month", _, _), do: "This Month"
  defp date_filter_label("previous_month", _, _), do: "Last Month"
  defp date_filter_label("custom", nil, nil), do: "Custom Range"
  defp date_filter_label("custom", f, nil), do: "From #{f}"
  defp date_filter_label("custom", nil, t), do: "Until #{t}"
  defp date_filter_label("custom", f, t), do: "#{f} – #{t}"

  defp filters_active?(query, cat_ids, acc_ids, date_preset, tag_ids) do
    query != "" or cat_ids != nil or acc_ids != nil or date_preset != "all_time" or tag_ids != nil
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

  defp page_path(socket, 1) do
    plan = socket.assigns.current_plan
    if plan, do: ~p"/plans/#{plan}/transactions", else: ~p"/transactions"
  end

  defp page_path(socket, page) do
    plan = socket.assigns.current_plan
    if plan, do: ~p"/plans/#{plan}/transactions?#{[page: page]}", else: ~p"/transactions?#{[page: page]}"
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
