defmodule Bany.Repo.Migrations.CreateAllocations do
  use Ecto.Migration

  def change do
    create table(:allocations) do
      add :amount, :decimal
      add :allocated_on, :date
      add :category_id, references(:categories, on_delete: :nothing)
      add :plan_id, references(:plans, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:allocations, [:category_id])
    create index(:allocations, [:plan_id])
  end
end
