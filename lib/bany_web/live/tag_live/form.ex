defmodule BanyWeb.TagLive.Form do
  use BanyWeb, :live_view

  alias Bany.Ledger
  alias Bany.Ledger.Tag

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_plan={@current_plan} current_scope={@current_scope}>
      <.header>{@page_title}</.header>

      <.form for={@form} id="tag-form" phx-change="validate" phx-submit="save" class="flex flex-col gap-4 max-w-sm">
        <.input field={@form[:name]} type="text" label="Name" />

        <%!-- Color picker --%>
        <div class="flex flex-col gap-1.5">
          <label class="text-sm font-medium">Color</label>
          <div class="flex flex-wrap gap-2">
            <label :for={color <- Tag.colors()} class="cursor-pointer">
              <input
                type="radio"
                name={@form[:color].name}
                value={color}
                checked={@form[:color].value == color}
                class="sr-only peer"
              />
              <span
                data-tag-color={color}
                title={color}
                class="block w-7 h-7 rounded-full border-2 peer-checked:ring-2 peer-checked:ring-offset-2 peer-checked:ring-current"
                style="background:var(--tag-bg);border-color:var(--tag-border)"
              />
            </label>
          </div>
          <.error :for={msg <- Enum.map(@form[:color].errors, &translate_error/1)}>{msg}</.error>
        </div>

        <%!-- Live preview --%>
        <div :if={@form[:color].value not in [nil, ""]} class="flex flex-col gap-1">
          <span class="text-xs opacity-60">Preview</span>
          <.tag_chip tag={%{name: (@form[:name].value || "Tag name"), color: @form[:color].value}} />
        </div>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Tag</.button>
          <.button navigate={return_path(@current_plan)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    tag = %Tag{}
    socket
    |> assign(:page_title, "New Tag")
    |> assign(:tag, tag)
    |> assign(:form, to_form(Ledger.change_tag(tag)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    tag = Ledger.get_tag!(id)
    socket
    |> assign(:page_title, "Edit Tag")
    |> assign(:tag, tag)
    |> assign(:form, to_form(Ledger.change_tag(tag)))
  end

  @impl true
  def handle_event("validate", %{"tag" => params}, socket) do
    changeset = Ledger.change_tag(socket.assigns.tag, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"tag" => params}, socket) do
    save_tag(socket, socket.assigns.live_action, params)
  end

  defp save_tag(socket, :new, params) do
    user = socket.assigns.current_scope.user

    case Ledger.create_tag(params, user) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag created successfully")
         |> push_navigate(to: return_path(socket.assigns.current_plan))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_tag(socket, :edit, params) do
    case Ledger.update_tag(socket.assigns.tag, params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag updated successfully")
         |> push_navigate(to: return_path(socket.assigns.current_plan))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(nil), do: ~p"/tags"
  defp return_path(plan), do: ~p"/plans/#{plan}/tags"
end
