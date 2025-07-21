defmodule BanyWeb.CategoryGroupLive.Index do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Category groups
        <:actions>
          <.button variant="primary" navigate={~p"/category_groups/new"}>
            <.icon name="hero-plus" /> New Category group
          </.button>
        </:actions>
      </.header>

      <.table
        id="category_groups"
        rows={@streams.category_groups}
        row_click={fn {_id, category_group} -> JS.navigate(~p"/category_groups/#{category_group}") end}
      >
        <:col :let={{_id, category_group}} label="Name">{category_group.name}</:col>
        <:action :let={{_id, category_group}}>
          <div class="sr-only">
            <.link navigate={~p"/category_groups/#{category_group}"}>Show</.link>
          </div>
          <.link navigate={~p"/category_groups/#{category_group}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, category_group}}>
          <.link
            phx-click={JS.push("delete", value: %{id: category_group.id}) |> hide("##{id}")}
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
    {:ok,
     socket
     |> assign(:page_title, "Listing Category groups")
     |> stream(:category_groups, Budget.list_category_groups())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category_group = Budget.get_category_group!(id)
    {:ok, _} = Budget.delete_category_group(category_group)

    {:noreply, stream_delete(socket, :category_groups, category_group)}
  end
end
