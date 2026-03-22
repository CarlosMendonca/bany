defmodule Bany.Repo.Migrations.AddTransactionIndexes do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    # Date filter — used in every date-range query
    create index(:transactions, [:date])

    # Composite indexes for common filter + date combinations
    create index(:transactions, [:account_id, :date])
    create index(:transactions, [:category_id, :date])

    # Trigram indexes — make ILIKE '%query%' index-able
    execute "CREATE INDEX transactions_memo_trgm_idx ON transactions USING GIN (memo gin_trgm_ops)"
    execute "CREATE INDEX payees_name_trgm_idx ON payees USING GIN (name gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS transactions_memo_trgm_idx"
    execute "DROP INDEX IF EXISTS payees_name_trgm_idx"
    drop_if_exists index(:transactions, [:category_id, :date])
    drop_if_exists index(:transactions, [:account_id, :date])
    drop_if_exists index(:transactions, [:date])
    # Leave pg_trgm extension in place — may be used elsewhere
  end
end
