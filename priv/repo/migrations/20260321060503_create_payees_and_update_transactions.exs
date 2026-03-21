defmodule Bany.Repo.Migrations.CreatePayeesAndUpdateTransactions do
  use Ecto.Migration

  def change do
    create table(:payees) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create index(:payees, [:user_id])

    alter table(:transactions) do
      add :payee_id, references(:payees, on_delete: :nilify_all)
      remove :payee, :string
    end

    create index(:transactions, [:payee_id])
  end
end
