defmodule BanyWeb.PlanContext do
  import Phoenix.Component, only: [assign: 2]
  alias Bany.Budget

  def on_mount(:require_plan, params, _session, socket) do
    plans = Budget.list_plans()
    current_plan = resolve_current_plan(plans, params)
    socket = assign(socket, current_plan: current_plan, plans: plans)

    if current_plan do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/plans")}
    end
  end

  def on_mount(:default, params, _session, socket) do
    plans = Budget.list_plans()
    {:cont, assign(socket, current_plan: resolve_current_plan(plans, params), plans: plans)}
  end

  defp resolve_current_plan(plans, %{"plan_id" => plan_id}),
    do: Enum.find(plans, &(to_string(&1.id) == plan_id))

  defp resolve_current_plan(_plans, _params), do: nil
end
