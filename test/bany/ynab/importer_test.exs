defmodule Bany.YNAB.ImporterTest do
  use Bany.DataCase

  import Bany.AccountsFixtures

  alias Bany.YNAB.Importer
  alias Bany.{Ledger, Repo}
  alias Bany.Ledger.Transaction

  @fixture_path "test/support/fixtures/ynab_transactions.csv"
  @plan_name "Test Budget"

  setup do
    %{user: user_fixture()}
  end

  describe "import_csv/3" do
    test "returns a report with total_rows, transactions, accounts, category_groups, categories", %{user: user} do
      assert {:ok, report} = Importer.import_csv(@fixture_path, @plan_name, user)
      assert report.total_rows > 0
      assert report.transactions.imported > 0
      assert report.transactions.failed == []
      assert report.accounts.created > 0
      assert report.accounts.failed == 0
      assert report.category_groups.created > 0
      assert report.category_groups.failed == 0
      assert report.categories.created > 0
      assert report.categories.failed == 0
    end

    test "imported transaction count matches the DB", %{user: user} do
      {:ok, report} = Importer.import_csv(@fixture_path, @plan_name, user)
      assert report.transactions.imported == Repo.aggregate(Transaction, :count)
    end

    test "creates a plan with the given name", %{user: user} do
      Importer.import_csv(@fixture_path, @plan_name, user)
      assert Repo.get_by(Bany.Budget.Plan, name: @plan_name)
    end

    test "creates accounts from the CSV", %{user: user} do
      Importer.import_csv(@fixture_path, @plan_name, user)
      accounts = Ledger.list_accounts()
      assert length(accounts) > 0
      assert Enum.any?(accounts, &String.contains?(&1.name, "VISA"))
    end

    test "creates category groups linked to the plan", %{user: user} do
      Importer.import_csv(@fixture_path, @plan_name, user)
      plan = Repo.get_by(Bany.Budget.Plan, name: @plan_name)
      groups = Repo.all(from g in Bany.Budget.CategoryGroup, where: g.plan_id == ^plan.id)
      assert length(groups) > 0
    end

    test "transactions have payee, date, and amount set", %{user: user} do
      Importer.import_csv(@fixture_path, @plan_name, user)
      transaction = Repo.one(from t in Transaction, order_by: [asc: t.id], limit: 1)
      assert transaction.payee_id != nil
      assert transaction.date != nil
      assert transaction.amount != nil
    end

    test "running import twice does not create duplicate plans or accounts", %{user: user} do
      {:ok, _first} = Importer.import_csv(@fixture_path, @plan_name, user)
      {:ok, second} = Importer.import_csv(@fixture_path, @plan_name, user)

      assert Repo.aggregate(Bany.Budget.Plan, :count) == 1
      assert second.accounts.created == 0
      assert second.category_groups.created == 0
      assert second.categories.created == 0
    end
  end
end
