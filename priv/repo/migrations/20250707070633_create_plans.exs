defmodule Bany.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
