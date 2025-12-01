defmodule Bany.Repo.Migrations.AddAccountIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :account_id, references(:accounts, on_delete: :nothing)
    end

    create index(:transactions, [:account_id])
  end
end
