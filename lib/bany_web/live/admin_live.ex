defmodule BanyWeb.AdminLive do
  use BanyWeb, :live_view

  alias Bany.{Budget, Ledger}
  alias Bany.YNAB.Importer

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Admin
        <:subtitle>Import data or reset the database.</:subtitle>
      </.header>

      <section class="space-y-4">
        <h2 class="text-lg font-semibold">Import YNAB CSV</h2>

        <form phx-submit="import" phx-change="validate">
          <div class="space-y-3">
            <.input
              type="text"
              name="plan_name"
              value={@plan_name}
              label="Budget / Plan name"
              placeholder="My Budget"
              required
            />

            <div class="form-control">
              <label class="label">
                <span class="label-text">CSV file</span>
              </label>
              <.live_file_input upload={@uploads.csv_file} class="file-input file-input-bordered w-full" />
            </div>

            <.button type="submit" variant="primary" phx-disable-with="Importing...">
              Import
            </.button>
          </div>
        </form>
      </section>

      <div class="divider" />

      <section class="space-y-4">
        <h2 class="text-lg font-semibold">Clear Database</h2>
        <p class="text-sm opacity-70">
          Deletes all transactions, accounts, categories, category groups, plans, and allocations.
        </p>

        <%= if @confirm_clear do %>
          <div class="alert alert-warning">
            <span>Are you sure? This cannot be undone.</span>
            <div class="flex gap-2">
              <.button phx-click="clear_confirmed" variant="primary">Yes, clear everything</.button>
              <.button phx-click="cancel_clear">Cancel</.button>
            </div>
          </div>
        <% else %>
          <.button phx-click="clear_database">Clear all data</.button>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:plan_name, "")
     |> assign(:confirm_clear, false)
     |> allow_upload(:csv_file, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", %{"plan_name" => plan_name}, socket) do
    {:noreply, assign(socket, :plan_name, plan_name)}
  end

  def handle_event("import", %{"plan_name" => plan_name}, socket) do
    result =
      consume_uploaded_entries(socket, :csv_file, fn %{path: path}, _entry ->
        Importer.import_csv(path, plan_name)
      end)

    socket =
      case result do
        [{:ok, count}] ->
          put_flash(socket, :info, "Imported #{count} transactions.")

        [] ->
          put_flash(socket, :error, "No file selected.")

        _ ->
          put_flash(socket, :error, "Import failed. Check the file format and try again.")
      end

    {:noreply, socket}
  end

  def handle_event("clear_database", _params, socket) do
    {:noreply, assign(socket, :confirm_clear, true)}
  end

  def handle_event("cancel_clear", _params, socket) do
    {:noreply, assign(socket, :confirm_clear, false)}
  end

  def handle_event("clear_confirmed", _params, socket) do
    Ledger.delete_all()
    Budget.delete_all()

    {:noreply,
     socket
     |> assign(:confirm_clear, false)
     |> put_flash(:info, "Database cleared.")}
  end
end
