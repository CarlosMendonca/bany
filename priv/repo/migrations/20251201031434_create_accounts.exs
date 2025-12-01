defmodule Bany.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
