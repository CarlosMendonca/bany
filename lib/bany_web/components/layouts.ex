defmodule BanyWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use BanyWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the app layout

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layout.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_plan, :map, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen">
      <%!-- Sidebar --%>
      <aside
        id="sidebar"
        class="flex flex-col w-64 h-screen sticky top-0 shrink-0 border-r border-base-300 bg-base-100 transition-[width] duration-200 overflow-hidden data-[collapsed]:w-16"
      >
        <%!-- Header row: logo + toggle --%>
        <div class="flex items-center justify-between px-3 py-3 border-b border-base-300">
          <a href="/" class="flex items-center gap-2 [[data-collapsed]_&]:hidden">
            <img src={~p"/images/logo.svg"} width="28" />
            <span class="text-sm font-semibold">Bany</span>
          </a>
          <button
            phx-click={JS.toggle_attribute({"data-collapsed", ""}, to: "#sidebar")}
            class="btn btn-ghost btn-sm btn-square shrink-0"
          >
            <.icon name="hero-bars-3" />
          </button>
        </div>

        <%!-- Current plan name --%>
        <div class="px-3 py-2 text-xs opacity-50 truncate [[data-collapsed]_&]:hidden">
          {if @current_plan, do: @current_plan.name, else: "No plan selected"}
        </div>

        <%!-- Nav --%>
        <nav class="flex-1 flex flex-col gap-0.5 px-2 py-2">
          <a
            href={~p"/admin"}
            class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
          >
            <.icon name="hero-wrench-screwdriver" class="size-5 shrink-0" />
            <span class="[[data-collapsed]_&]:hidden">Admin</span>
          </a>
          <a
            href={~p"/plans"}
            class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
          >
            <.icon name="hero-clipboard-document-list" class="size-5 shrink-0" />
            <span class="[[data-collapsed]_&]:hidden">Plans</span>
          </a>
          <%= if @current_plan do %>
            <a
              href={~p"/plans/#{@current_plan}/accounts"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-banknotes" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Accounts</span>
            </a>
            <a
              href={~p"/plans/#{@current_plan}/allocations"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Allocations</span>
            </a>
            <a
              href={~p"/plans/#{@current_plan}/categories/with_totals/#{Date.utc_today().year}/#{Date.utc_today().month}"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-calculator" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Budgets</span>
            </a>
          <% end %>
          <a
            href={categories_href(@current_plan)}
            class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
          >
            <.icon name="hero-tag" class="size-5 shrink-0" />
            <span class="[[data-collapsed]_&]:hidden">Categories</span>
          </a>
          <%= if @current_plan do %>
            <a
              href={~p"/plans/#{@current_plan}/category_groups"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-folder-open" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Category Groups</span>
            </a>
          <% end %>
          <a
            href={payees_href(@current_plan)}
            class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
          >
            <.icon name="hero-users" class="size-5 shrink-0" />
            <span class="[[data-collapsed]_&]:hidden">Payees</span>
          </a>
          <a
            href={transactions_href(@current_plan)}
            class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
          >
            <.icon name="hero-list-bullet" class="size-5 shrink-0" />
            <span class="[[data-collapsed]_&]:hidden">Transactions</span>
          </a>
        </nav>

        <%!-- Bottom: user + theme --%>
        <div class="flex flex-col gap-1 px-2 py-3 border-t border-base-300">
          <%= if @current_scope && @current_scope.user do %>
            <div class="px-2 py-1 text-xs opacity-60 truncate [[data-collapsed]_&]:hidden">
              {@current_scope.user.email}
            </div>
            <.link
              href={~p"/users/settings"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-cog-6-tooth" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Settings</span>
            </.link>
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-arrow-left-start-on-rectangle" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Log out</span>
            </.link>
          <% else %>
            <.link
              href={~p"/users/register"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-user-plus" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Register</span>
            </.link>
            <.link
              href={~p"/users/log-in"}
              class="flex items-center gap-3 px-2 py-2 rounded-lg hover:bg-base-200"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-5 shrink-0" />
              <span class="[[data-collapsed]_&]:hidden">Log in</span>
            </.link>
          <% end %>
          <div class="px-2 py-2 [[data-collapsed]_&]:hidden">
            <.theme_toggle />
          </div>
        </div>
      </aside>

      <%!-- Main content --%>
      <div class="flex-1 min-w-0 overflow-y-auto">
        <main class="px-4 py-8 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-6xl space-y-4">
            {render_slot(@inner_block)}
          </div>
        </main>
        <.flash_group flash={@flash} />
      </div>
    </div>
    """
  end

  defp transactions_href(nil), do: ~p"/transactions"
  defp transactions_href(plan), do: ~p"/plans/#{plan}/transactions"

  defp categories_href(nil), do: ~p"/categories"
  defp categories_href(plan), do: ~p"/plans/#{plan}/categories"

  defp payees_href(nil), do: ~p"/payees"
  defp payees_href(plan), do: ~p"/plans/#{plan}/payees"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
