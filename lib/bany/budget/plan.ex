defmodule Bany.Budget.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :name, :string

    many_to_many :accounts, Bany.Ledger.Account, join_through: "plan_accounts"
    many_to_many :categories, Bany.Budget.Category, join_through: "plan_categories"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
