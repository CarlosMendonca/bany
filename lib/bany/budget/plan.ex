defmodule Bany.Budget.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  @supported_currencies ~w(USD EUR GBP JPY CAD AUD CHF CNY INR BRL MXN SGD HKD NOK SEK DKK NZD ZAR)

  schema "plans" do
    field :name, :string
    field :currency, :string, default: "USD"

    many_to_many :accounts, Bany.Ledger.Account, join_through: "plan_accounts"
    many_to_many :categories, Bany.Budget.Category, join_through: "plan_categories"
    many_to_many :users, Bany.Accounts.User, join_through: "user_plans"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:name, :currency])
    |> validate_required([:name, :currency])
    |> validate_inclusion(:currency, @supported_currencies)
  end

  def supported_currencies, do: @supported_currencies
end
