defmodule BanyWeb.CategoryGroupLive.Form do
  use BanyWeb, :live_view

  alias Bany.Budget
  alias Bany.Budget.CategoryGroup

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage category_group records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="category_group-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:plan_id]} type="select" label="Plan" options={Enum.map(@plans, &{&1.name, &1.id})} />
        <.input field={@form[:category_ids]} type="select" label="Categories" options={Enum.map(@categories, &{&1.name, &1.id})} multiple />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Category group</.button>
          <.button navigate={return_path(@return_to, @category_group)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    plans = Budget.list_plans()
    categories = Budget.list_categories()
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:plans, plans)
     |> assign(:categories, categories)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    category_group = Budget.get_category_group!(id) |> Bany.Repo.preload(:categories)
    form =
      category_group
      |> Budget.change_category_group()
      |> Map.update!(:params, fn params ->
        Map.put(params, "category_ids", Enum.map(category_group.categories, & &1.id))
      end)
      |> to_form()

    socket
    |> assign(:page_title, "Edit Category group")
    |> assign(:category_group, category_group)
    |> assign(:form, form)
  end

  defp apply_action(socket, :new, _params) do
    category_group = %CategoryGroup{categories: []}
    form =
      category_group
      |> Budget.change_category_group()
      |> Map.update!(:params, fn params -> Map.put(params, "category_ids", []) end)
      |> to_form()

    socket
    |> assign(:page_title, "New Category group")
    |> assign(:category_group, category_group)
    |> assign(:form, form)
  end

  @impl true
  def handle_event("validate", %{"category_group" => category_group_params}, socket) do
    changeset =
      socket.assigns.category_group
      |> Budget.change_category_group(category_group_params)
      |> Map.update!(:params, fn params ->
        Map.put(params, "category_ids", Map.get(category_group_params, "category_ids", []))
      end)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category_group" => category_group_params}, socket) do
    save_category_group(socket, socket.assigns.live_action, category_group_params)
  end

  defp save_category_group(socket, :edit, category_group_params) do
    case Budget.update_category_group(socket.assigns.category_group, category_group_params) do
      {:ok, category_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category group updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, category_group))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category_group(socket, :new, category_group_params) do
    case Budget.create_category_group(category_group_params) do
      {:ok, category_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category group created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, category_group))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _category_group), do: ~p"/category_groups"
  defp return_path("show", category_group), do: ~p"/category_groups/#{category_group}"
end
