defmodule Bany.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name,    :string, null: false
      add :color,   :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:tags, [:user_id])

    create table(:transaction_tags, primary_key: false) do
      add :transaction_id, references(:transactions, on_delete: :delete_all), null: false
      add :tag_id,         references(:tags,         on_delete: :delete_all), null: false
    end

    create unique_index(:transaction_tags, [:transaction_id, :tag_id])
  end
end
