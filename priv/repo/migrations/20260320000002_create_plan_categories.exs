defmodule Bany.Repo.Migrations.CreatePlanCategories do
  use Ecto.Migration

  def change do
    create table(:plan_categories) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false
    end

    create unique_index(:plan_categories, [:plan_id, :category_id])
  end
end
