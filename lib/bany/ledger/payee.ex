defmodule Bany.Ledger.Payee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payees" do
    field :name, :string
    belongs_to :user, Bany.Accounts.User
    has_many :transactions, Bany.Ledger.Transaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payee, attrs) do
    payee
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name])
  end
end
