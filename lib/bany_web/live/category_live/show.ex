defmodule BanyWeb.CategoryLive.Show do
  use BanyWeb, :live_view

  alias Bany.Budget

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan}>
      <.header>
        Category {@category.id}
        <:subtitle>This is a category record from your database.</:subtitle>
        <:actions>
          <.button navigate={categories_path(@current_plan)}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={category_edit_path(@current_plan, @category)}>
            <.icon name="hero-pencil-square" /> Edit category
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@category.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Category")
     |> assign(:category, Budget.get_category!(id))}
  end

  defp categories_path(nil), do: ~p"/categories"
  defp categories_path(plan), do: ~p"/plans/#{plan}/categories"

  defp category_edit_path(nil, c), do: ~p"/categories/#{c}/edit?return_to=show"
  defp category_edit_path(plan, c), do: ~p"/plans/#{plan}/categories/#{c}/edit?return_to=show"
end
