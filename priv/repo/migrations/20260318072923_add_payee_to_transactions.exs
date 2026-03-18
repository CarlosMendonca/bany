defmodule Bany.Repo.Migrations.AddPayeeToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :payee, :string
    end
  end
end
