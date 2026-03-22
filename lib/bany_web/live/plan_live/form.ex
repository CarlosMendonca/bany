defmodule BanyWeb.PlanLive.Form do
  use BanyWeb, :live_view

  alias Bany.Budget
  alias Bany.Budget.Plan

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage plan records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="plan-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:currency]} type="select" label="Currency"
          options={Enum.map(@currencies, &{&1, &1})} />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Plan</.button>
          <.button navigate={return_path(@return_to, @plan)}>Cancel</.button>
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
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    plan = Budget.get_plan!(id)

    socket
    |> assign(:page_title, "Edit Plan")
    |> assign(:plan, plan)
    |> assign(:currencies, Plan.supported_currencies())
    |> assign(:form, to_form(Budget.change_plan(plan)))
  end

  defp apply_action(socket, :new, _params) do
    plan = %Plan{}

    socket
    |> assign(:page_title, "New Plan")
    |> assign(:plan, plan)
    |> assign(:currencies, Plan.supported_currencies())
    |> assign(:form, to_form(Budget.change_plan(plan)))
  end

  @impl true
  def handle_event("validate", %{"plan" => plan_params}, socket) do
    changeset = Budget.change_plan(socket.assigns.plan, plan_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"plan" => plan_params}, socket) do
    save_plan(socket, socket.assigns.live_action, plan_params)
  end

  defp save_plan(socket, :edit, plan_params) do
    case Budget.update_plan(socket.assigns.plan, plan_params) do
      {:ok, plan} ->
        {:noreply,
         socket
         |> put_flash(:info, "Plan updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_plan(socket, :new, plan_params) do
    case Budget.create_plan(plan_params, socket.assigns.current_scope.user) do
      {:ok, plan} ->
        {:noreply,
         socket
         |> put_flash(:info, "Plan created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _plan), do: ~p"/plans"
  defp return_path("show", plan), do: ~p"/plans/#{plan}"
end
