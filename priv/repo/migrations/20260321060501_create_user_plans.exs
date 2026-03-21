defmodule Bany.Repo.Migrations.CreateUserPlans do
  use Ecto.Migration

  def change do
    create table(:user_plans) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
    end

    create unique_index(:user_plans, [:user_id, :plan_id])
  end
end
