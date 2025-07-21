defmodule Bany.Repo.Migrations.CreateCategoryGroups do
  use Ecto.Migration

  def change do
    create table(:category_groups) do
      add :name, :string
      add :plan_id, references(:plans, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:category_groups, [:plan_id])
  end
end
