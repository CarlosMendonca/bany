defmodule Bany.LedgerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bany.Ledger` context.
  """

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    {:ok, transaction} =
      attrs
      |> Enum.into(%{
        amount: "120.5",
        date: ~D[2025-07-06],
        memo: "some memo",
        transaction: "some transaction"
      })
      |> Bany.Ledger.create_transaction()

    transaction
  end
end
