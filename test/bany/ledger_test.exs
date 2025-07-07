defmodule Bany.LedgerTest do
  use Bany.DataCase

  alias Bany.Ledger

  describe "transactions" do
    alias Bany.Ledger.Transaction

    import Bany.LedgerFixtures

    @invalid_attrs %{date: nil, transaction: nil, memo: nil, amount: nil}

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      assert Ledger.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Ledger.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      valid_attrs = %{date: ~D[2025-07-06], transaction: "some transaction", memo: "some memo", amount: "120.5"}

      assert {:ok, %Transaction{} = transaction} = Ledger.create_transaction(valid_attrs)
      assert transaction.date == ~D[2025-07-06]
      assert transaction.transaction == "some transaction"
      assert transaction.memo == "some memo"
      assert transaction.amount == Decimal.new("120.5")
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ledger.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()
      update_attrs = %{date: ~D[2025-07-07], transaction: "some updated transaction", memo: "some updated memo", amount: "456.7"}

      assert {:ok, %Transaction{} = transaction} = Ledger.update_transaction(transaction, update_attrs)
      assert transaction.date == ~D[2025-07-07]
      assert transaction.transaction == "some updated transaction"
      assert transaction.memo == "some updated memo"
      assert transaction.amount == Decimal.new("456.7")
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Ledger.update_transaction(transaction, @invalid_attrs)
      assert transaction == Ledger.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Ledger.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Ledger.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Ledger.change_transaction(transaction)
    end
  end
end
