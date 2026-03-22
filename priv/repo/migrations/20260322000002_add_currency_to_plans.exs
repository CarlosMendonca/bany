defmodule Bany.Repo.Migrations.AddCurrencyToPlans do
  use Ecto.Migration

  def change do
    alter table(:plans) do
      add :currency, :string, default: "USD", null: false
    end
  end
end
