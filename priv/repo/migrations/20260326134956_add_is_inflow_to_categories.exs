defmodule Bany.Repo.Migrations.AddIsInflowToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :is_inflow, :boolean, default: false, null: false
    end
  end
end
