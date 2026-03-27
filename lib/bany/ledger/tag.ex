defmodule Bany.Ledger.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @colors ~w(slate red orange amber yellow lime green teal cyan blue indigo violet purple fuchsia pink rose)

  def colors, do: @colors

  schema "tags" do
    field :name,  :string
    field :color, :string
    belongs_to :user, Bany.Accounts.User
    many_to_many :transactions, Bany.Ledger.Transaction, join_through: "transaction_tags"
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :color])
    |> validate_required([:name, :color])
    |> validate_inclusion(:color, @colors)
  end
end
