defmodule BanyWeb.CategoryLive.Index do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Listing Categories
        <:actions>
          <.button variant="primary" navigate={categories_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Category
          </.button>
        </:actions>
      </.header>

      <.table
        id="categories"
        rows={@streams.categories}
        row_click={fn {_id, category} -> JS.navigate(category_path(@current_plan, category)) end}
      >
        <:col :let={{_id, category}} label="Name">{category.name}</:col>
        <:action :let={{_id, category}}>
          <div class="sr-only">
            <.link navigate={category_path(@current_plan, category)}>Show</.link>
          </div>
          <.link navigate={category_edit_path(@current_plan, category)}>Edit</.link>
        </:action>
        <:action :let={{id, category}}>
          <.link
            :if={not category.is_inflow}
            phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
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

    {:ok,
     socket
     |> assign(:page_title, "Listing Categories")
     |> stream(:categories, categories)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Budget.get_category!(id)

    case Budget.delete_category(category) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :categories, category)}

      {:error, :inflow_category_protected} ->
        {:noreply, put_flash(socket, :error, "The inflow category cannot be deleted.")}
    end
  end

  defp categories_new_path(nil), do: ~p"/categories/new"
  defp categories_new_path(plan), do: ~p"/plans/#{plan}/categories/new"

  defp category_path(nil, c), do: ~p"/categories/#{c}"
  defp category_path(plan, c), do: ~p"/plans/#{plan}/categories/#{c}"

  defp category_edit_path(nil, c), do: ~p"/categories/#{c}/edit"
  defp category_edit_path(plan, c), do: ~p"/plans/#{plan}/categories/#{c}/edit"
end
