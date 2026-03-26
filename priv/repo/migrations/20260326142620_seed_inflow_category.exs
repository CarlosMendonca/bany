defmodule Bany.Repo.Migrations.SeedInflowCategory do
  use Ecto.Migration
  import Ecto.Query

  def up do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {1, [%{id: id}]} =
      repo().insert_all(
        "categories",
        [%{name: "Inflow: Ready to Assign", is_inflow: true, inserted_at: now, updated_at: now}],
        returning: [:id]
      )

    plan_ids = repo().all(from p in "plans", select: p.id)

    unless plan_ids == [] do
      repo().insert_all(
        "plan_categories",
        Enum.map(plan_ids, &%{plan_id: &1, category_id: id}),
        on_conflict: :nothing
      )
    end
  end

  def down do
    repo().delete_all(from c in "categories", where: c.is_inflow)
  end
end
