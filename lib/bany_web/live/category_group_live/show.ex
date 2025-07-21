defmodule BanyWeb.CategoryGroupLive.Show do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Category group {@category_group.id}
        <:subtitle>This is a category_group record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/category_groups"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/category_groups/#{@category_group}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit category_group
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@category_group.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Category group")
     |> assign(:category_group, Budget.get_category_group!(id))}
  end
end
