defmodule BanyWeb.PayeeLive.Form do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Ledger.Payee

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage payee records.</:subtitle>
      </.header>

      <.form for={@form} id="payee-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Payee</.button>
          <.button navigate={return_path(@return_to, @payee, @current_plan)}>Cancel</.button>
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
    payee = Ledger.get_payee!(id)

    socket
    |> assign(:page_title, "Edit Payee")
    |> assign(:payee, payee)
    |> assign(:form, to_form(Ledger.change_payee(payee)))
  end

  defp apply_action(socket, :new, _params) do
    payee = %Payee{}

    socket
    |> assign(:page_title, "New Payee")
    |> assign(:payee, payee)
    |> assign(:form, to_form(Ledger.change_payee(payee)))
  end

  @impl true
  def handle_event("validate", %{"payee" => payee_params}, socket) do
    changeset = Ledger.change_payee(socket.assigns.payee, payee_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"payee" => payee_params}, socket) do
    save_payee(socket, socket.assigns.live_action, payee_params)
  end

  defp save_payee(socket, :edit, payee_params) do
    case Ledger.update_payee(socket.assigns.payee, payee_params) do
      {:ok, payee} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payee updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, payee, socket.assigns.current_plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_payee(socket, :new, payee_params) do
    case Ledger.create_payee(payee_params) do
      {:ok, payee} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payee created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, payee, socket.assigns.current_plan))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _p, nil), do: ~p"/payees"
  defp return_path("index", _p, plan), do: ~p"/plans/#{plan}/payees"
  defp return_path("show", p, nil), do: ~p"/payees/#{p}"
  defp return_path("show", p, plan), do: ~p"/plans/#{plan}/payees/#{p}"
end
