defmodule Bany.Repo.Migrations.CreatePlanAccounts do
  use Ecto.Migration

  def change do
    create table(:plan_accounts) do
      add :plan_id, references(:plans, on_delete: :delete_all), null: false
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
    end

    create unique_index(:plan_accounts, [:plan_id, :account_id])
  end
end
