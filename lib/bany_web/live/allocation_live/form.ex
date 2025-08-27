defmodule BanyWeb.AllocationLive.Form do
  use BanyWeb, :live_view

  alias Bany.Budget
  alias Bany.Budget.Allocation

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage allocation records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="allocation-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:amount]} type="number" label="Amount" step="any" />
        <.input field={@form[:allocated_on]} type="date" label="Allocated on" />
        <.input
          field={@form[:plan_id]}
          type="select"
          label="Plan"
          options={Enum.map(@plans, &{&1.name, &1.id})}
        />
        <.input
          field={@form[:category_id]}
          type="select"
          label="Category"
          options={Enum.map(@categories, &{&1.name, &1.id})}
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Allocation</.button>
          <.button navigate={return_path(@return_to, @allocation)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:plans, Budget.list_plans())
     |> assign(:categories, Budget.list_categories())
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    allocation = Budget.get_allocation!(id)

    socket
    |> assign(:page_title, "Edit Allocation")
    |> assign(:allocation, allocation)
    |> assign(:form, to_form(Budget.change_allocation(allocation)))
  end

  defp apply_action(socket, :new, _params) do
    allocation = %Allocation{}

    socket
    |> assign(:page_title, "New Allocation")
    |> assign(:allocation, allocation)
    |> assign(:form, to_form(Budget.change_allocation(allocation)))
  end

  @impl true
  def handle_event("validate", %{"allocation" => allocation_params}, socket) do
    changeset = Budget.change_allocation(socket.assigns.allocation, allocation_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"allocation" => allocation_params}, socket) do
    save_allocation(socket, socket.assigns.live_action, allocation_params)
  end

  defp save_allocation(socket, :edit, allocation_params) do
    case Budget.update_allocation(socket.assigns.allocation, allocation_params) do
      {:ok, allocation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Allocation updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, allocation))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_allocation(socket, :new, allocation_params) do
    case Budget.create_allocation(allocation_params) do
      {:ok, allocation} ->
        {:noreply,
         socket
         |> put_flash(:info, "Allocation created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, allocation))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _allocation), do: ~p"/allocations"
  defp return_path("show", allocation), do: ~p"/allocations/#{allocation}"
end
