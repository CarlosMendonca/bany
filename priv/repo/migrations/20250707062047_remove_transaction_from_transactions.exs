defmodule Bany.Repo.Migrations.RemoveTransactionFromTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      remove(:transaction)
    end
  end
end
