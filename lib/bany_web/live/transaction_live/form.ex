defmodule BanyWeb.TransactionLive.Form do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Ledger.Transaction
  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage transaction records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="transaction-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:memo]} type="text" label="Memo" />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:amount]} type="number" label="Amount" step="any" />
        <.input field={@form[:payee_id]} type="select" label="Payee" prompt="(none)" options={@payees} />
        <.input field={@form[:category_id]} type="select" label="Category" prompt="(none)" options={@categories} />
        <.input field={@form[:account_id]} type="select" label="Account" prompt="(none)" options={@accounts} />

        <%!-- Tags --%>
        <fieldset :if={@tags != []} class="fieldset mb-2">
          <label>
            <span class="label mb-1">Tags</span>
            <div class="flex flex-wrap gap-2">
              <label :for={tag <- @tags} class="flex items-center gap-1.5 cursor-pointer">
                <input
                  type="checkbox"
                  class="checkbox checkbox-sm"
                  name="transaction[tag_ids][]"
                  value={tag.id}
                  checked={tag.id in @selected_tag_ids}
                />
                <.tag_chip tag={tag} />
              </label>
            </div>
          </label>
        </fieldset>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Transaction</.button>
          <.button navigate={return_path(@return_to, @transaction, @current_plan)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
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

    user = socket.assigns.current_scope.user
    tags = Ledger.list_tags_for_user(user.id)

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:categories, Enum.map(categories, &{&1.name, &1.id}))
     |> assign(:accounts, Enum.map(accounts, &{&1.name, &1.id}))
     |> assign(:payees, Enum.map(payees, &{&1.name, &1.id}))
     |> assign(:tags, tags)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    transaction = Ledger.get_transaction_with_tags!(id)

    socket
    |> assign(:page_title, "Edit Transaction")
    |> assign(:transaction, transaction)
    |> assign(:selected_tag_ids, Enum.map(transaction.tags, & &1.id))
    |> assign(:form, to_form(Ledger.change_transaction(transaction)))
  end

  defp apply_action(socket, :new, _params) do
    transaction = %Transaction{}

    socket
    |> assign(:page_title, "New Transaction")
    |> assign(:transaction, transaction)
    |> assign(:selected_tag_ids, [])
    |> assign(:form, to_form(Ledger.change_transaction(transaction)))
  end

  @impl true
  def handle_event("validate", %{"transaction" => transaction_params}, socket) do
    changeset = Ledger.change_transaction(socket.assigns.transaction, transaction_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"transaction" => transaction_params}, socket) do
    {tag_ids_raw, transaction_params} = Map.pop(transaction_params, "tag_ids", [])
    tag_ids = Enum.map(List.wrap(tag_ids_raw), &String.to_integer/1)
    save_transaction(socket, socket.assigns.live_action, transaction_params, tag_ids)
  end

  defp save_transaction(socket, :edit, transaction_params, tag_ids) do
    case Ledger.update_transaction(socket.assigns.transaction, transaction_params) do
      {:ok, transaction} ->
        Ledger.set_transaction_tags(transaction, tag_ids)

        {:noreply,
         socket
         |> put_flash(:info, "Transaction updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, transaction, socket.assigns.current_plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_transaction(socket, :new, transaction_params, tag_ids) do
    case Ledger.create_transaction(transaction_params) do
      {:ok, transaction} ->
        Ledger.set_transaction_tags(transaction, tag_ids)

        {:noreply,
         socket
         |> put_flash(:info, "Transaction created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, transaction, socket.assigns.current_plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _t, nil), do: ~p"/transactions"
  defp return_path("index", _t, plan), do: ~p"/plans/#{plan}/transactions"
  defp return_path("show", t, nil), do: ~p"/transactions/#{t}"
  defp return_path("show", t, plan), do: ~p"/plans/#{plan}/transactions/#{t}"
end
