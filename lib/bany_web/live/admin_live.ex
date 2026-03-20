defmodule BanyWeb.AdminLive do
  use BanyWeb, :live_view

  alias Bany.{Budget, Ledger}
  alias Bany.YNAB.Importer

  @types %{plan_name: :string}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan}>
      <.header>
        Admin
        <:subtitle>Import data or reset the database.</:subtitle>
      </.header>

      <section class="space-y-4">
        <h2 class="text-lg font-semibold">Import YNAB CSV</h2>

        <.form for={@form} id="import-form" phx-submit="import" phx-change="validate">
          <.input field={@form[:plan_name]} type="text" label="Budget / Plan name" placeholder="My Budget" />

          <fieldset class="fieldset mb-2">
            <label class="label">
              <span class="label-text">CSV file</span>
            </label>
            <.live_file_input upload={@uploads.csv_file} class="file-input file-input-bordered w-full" />
          </fieldset>

          <footer>
            <.button type="submit" variant="primary" phx-disable-with="Importing...">
              Import
            </.button>
          </footer>
        </.form>

        <%= if @import_result do %>
          <div class="mt-4 p-4 rounded-box border border-base-300 space-y-3 text-sm">
            <p class="font-semibold">
              Import complete — {@import_result.total_rows} rows processed
            </p>

            <div class="space-y-1">
              <p>
                <span class="font-medium">Transactions:</span>
                {@import_result.transactions.imported} imported,
                {length(@import_result.transactions.failed)} failed
              </p>
              <%= if @import_result.transactions.failed != [] do %>
                <ul class="ml-4 list-disc text-error space-y-0.5">
                  <li :for={{row_num, reason} <- @import_result.transactions.failed}>
                    Row {row_num}: {reason}
                  </li>
                </ul>
              <% end %>
            </div>

            <div class="grid grid-cols-1 gap-1">
              <p>
                <span class="font-medium">Accounts:</span>
                {@import_result.accounts.created} created,
                {@import_result.accounts.failed} failed
              </p>
              <p>
                <span class="font-medium">Category groups:</span>
                {@import_result.category_groups.created} created,
                {@import_result.category_groups.failed} failed
              </p>
              <p>
                <span class="font-medium">Categories:</span>
                {@import_result.categories.created} created,
                {@import_result.categories.failed} failed
              </p>
            </div>
          </div>
        <% end %>
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
     |> assign(:form, to_form(import_changeset(), as: :import))
     |> assign(:import_result, nil)
     |> assign(:confirm_clear, false)
     |> allow_upload(:csv_file, accept: ~w(.csv), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form =
      params
      |> Map.get("import", %{})
      |> import_changeset()
      |> to_form(action: :validate, as: :import)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("import", %{"import" => params}, socket) do
    changeset = import_changeset(params)

    if changeset.valid? do
      plan_name = Ecto.Changeset.get_field(changeset, :plan_name)

      result =
        consume_uploaded_entries(socket, :csv_file, fn %{path: path}, _entry ->
          Importer.import_csv(path, plan_name)
        end)

      socket =
        case result do
          [report] when is_map(report) ->
            socket
            |> assign(:import_result, report)
            |> assign(:form, to_form(import_changeset(), as: :import))

          [] ->
            put_flash(socket, :error, "No file selected.")

          _ ->
            put_flash(socket, :error, "Import failed. Check the file format and try again.")
        end

      {:noreply, socket}
    else
      {:noreply, assign(socket, :form, to_form(changeset, action: :validate, as: :import))}
    end
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
     |> assign(:import_result, nil)
     |> put_flash(:info, "Database cleared.")}
  end

  defp import_changeset(params \\ %{}) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, [:plan_name])
    |> Ecto.Changeset.validate_required([:plan_name])
  end
end
