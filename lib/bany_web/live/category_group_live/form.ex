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
        <label :for={category <- @categories}>
          <input
            type="checkbox"
            name="category_group[category_ids][]"
            value={category.id}
            checked={MapSet.member?(@selected_category_ids, category.id)}
          />
          {category.name}
        </label>
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
    changeset = Budget.change_category_group(category_group)
    selected_category_ids = Enum.map(category_group.categories, & &1.id) |> MapSet.new()

    socket
    |> assign(:page_title, "Edit Category group")
    |> assign(:category_group, category_group)
    |> assign(:selected_category_ids, selected_category_ids)
    |> assign(:form, changeset |> to_form())
  end

  defp apply_action(socket, :new, _params) do
    category_group = %CategoryGroup{categories: []}
    changeset = Budget.change_category_group(category_group)
    selected_category_ids = []

    socket
    |> assign(:page_title, "New Category group")
    |> assign(:category_group, category_group)
    |> assign(:selected_category_ids, selected_category_ids)
    |> assign(:form, changeset |> to_form())
  end

  @impl true
  def handle_event("validate", %{"category_group" => params}, socket) do
    selected_category_ids =
      params
      |> Map.get("category_ids", [])
      |> Enum.map(&String.to_integer/1)
      |> MapSet.new()

    selected_categories =
      Budget.list_categories()
      |> Enum.filter(&MapSet.member?(selected_category_ids, &1.id))

    # TODO: move put_assoc to the changeset function
    changeset =
      socket.assigns.category_group
      |> Budget.change_category_group(params)
      |> Ecto.Changeset.put_assoc(:categories, selected_categories)

    # TODO: how to update the changeset with the selected_category_ids and trigger its validation?

    {:noreply,
     socket
     |> assign(:selected_category_ids, selected_category_ids)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category_group" => params}, socket) do
    save_category_group(socket, socket.assigns.live_action, params)
  end

  defp save_category_group(socket, :edit, params) do
    #TODO: establish that a list of category_ids is passed to the changeset and repo update

    case Budget.update_category_group(socket.assigns.category_group, params) do
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
