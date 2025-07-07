defmodule Bany.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :transaction, :string
      add :memo, :string
      add :date, :date
      add :amount, :decimal
      add :category_id, references(:categories, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:category_id])
  end
end
