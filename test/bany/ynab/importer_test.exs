defmodule Bany.YNAB.ImporterTest do
  use Bany.DataCase

  alias Bany.YNAB.Importer
  alias Bany.{Ledger, Repo}
  alias Bany.Ledger.Transaction

  @fixture_path "test/support/fixtures/ynab_transactions.csv"
  @plan_name "Test Budget"

  describe "import_csv/2" do
    test "imports all transactions from the fixture file" do
      assert {:ok, count} = Importer.import_csv(@fixture_path, @plan_name)
      assert count == Repo.aggregate(Transaction, :count)
      assert count > 0
    end

    test "creates a plan with the given name" do
      Importer.import_csv(@fixture_path, @plan_name)
      assert Repo.get_by(Bany.Budget.Plan, name: @plan_name)
    end

    test "creates accounts from the CSV" do
      Importer.import_csv(@fixture_path, @plan_name)
      accounts = Ledger.list_accounts()
      assert length(accounts) > 0
      assert Enum.any?(accounts, &String.contains?(&1.name, "VISA"))
    end

    test "creates category groups linked to the plan" do
      Importer.import_csv(@fixture_path, @plan_name)
      plan = Repo.get_by(Bany.Budget.Plan, name: @plan_name)
      groups = Repo.all(from g in Bany.Budget.CategoryGroup, where: g.plan_id == ^plan.id)
      assert length(groups) > 0
    end

    test "transactions have payee, date, and amount set" do
      Importer.import_csv(@fixture_path, @plan_name)
      transaction = Repo.one(from t in Transaction, order_by: [asc: t.id], limit: 1)
      assert transaction.payee != nil
      assert transaction.date != nil
      assert transaction.amount != nil
    end

    test "running import twice does not create duplicate plans or accounts" do
      Importer.import_csv(@fixture_path, @plan_name)
      {:ok, _} = Importer.import_csv(@fixture_path, @plan_name)

      assert Repo.aggregate(Bany.Budget.Plan, :count) == 1
      accounts_after_second = Ledger.list_accounts()

      Importer.import_csv(@fixture_path, @plan_name)
      accounts_after_third = Ledger.list_accounts()

      assert length(accounts_after_second) == length(accounts_after_third)
    end
  end
end
