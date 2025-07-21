defmodule Bany.Repo.Migrations.CreateCategoryGroupsCategories do
  use Ecto.Migration

  def change do
    create table(:category_groups_categories) do
      add :category_group_id, references(:category_groups, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :delete_all)
    end

    create unique_index(:category_groups_categories, [:category_group_id, :category_id])
  end
end
