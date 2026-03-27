defmodule BanyWeb.TagLive.Index do
  use BanyWeb, :live_view

  alias Bany.Ledger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>
        Tags
        <:actions>
          <.button variant="primary" navigate={tag_new_path(@current_plan)}>
            <.icon name="hero-plus" /> New Tag
          </.button>
        </:actions>
      </.header>

      <.table id="tags" rows={@streams.tags}>
        <:col :let={{_id, tag}} label="Name">
          <.tag_chip tag={tag} />
        </:col>
        <:action :let={{_id, tag}}>
          <.link navigate={tag_edit_path(@current_plan, tag)}>Edit</.link>
        </:action>
        <:action :let={{_id, tag}}>
          <.link
            phx-click={JS.push("delete", value: %{id: tag.id})}
            data-confirm={"Delete tag \"#{tag.name}\"? It will be removed from all transactions."}
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
    user = socket.assigns.current_scope.user
    tags = Ledger.list_tags_for_user(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Tags")
     |> stream(:tags, tags)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Ledger.get_tag!(id)
    {:ok, _} = Ledger.delete_tag(tag)
    {:noreply, stream_delete(socket, :tags, tag)}
  end

  defp tag_new_path(nil), do: ~p"/tags/new"
  defp tag_new_path(plan), do: ~p"/plans/#{plan}/tags/new"

  defp tag_edit_path(nil, tag), do: ~p"/tags/#{tag}/edit"
  defp tag_edit_path(plan, tag), do: ~p"/plans/#{plan}/tags/#{tag}/edit"
end
