# TODO

### P0 -- core feature
* single edit and multi edit -- tweak cursor position after OK/Cancel; keyboard shortcuts to enter / exit mode
* on categories with totals, show how much is available from the special inflow category
* include a special category for to-be-budgeted inflow; should be added on priv/repo/seeds.exs for test/development and as a migration 
* implement transaction splits between categories
* implement transaction splits between categories between Plans
* Plaid import with async workers

### P1 -- quality-of-life features & chores
* on CategoryGroup, add labels for how many categories are associated
* on Categories, add labels for how many Plans/CategoryGroups are associated
* clean up application
* fix tests
* fix import error
* refactor YNAB importer as an async worker
* make all index views sortable

### P2 -- polish
* add some zero state (e.g. CategoryGroup needs a Plan)

### DONE
* assign transactions to an Account; Account may be associated with two Plans
* an Account can be associated with more than one Plan; on the Transaction screen, we only show the Transaction of the current Plan
* on categories with totals, show total assigned/activity/available for each category group
* introduce Plan as a an application context (https://hexdocs.pm/phoenix/contexts.html)
* global select all on header
* three states selector
* redesign -- move navigation row to left sidebar

## Scratch pad

### Inflows
* One inflow category versus multiple
* One inflow: single rule -- only assign to this month what you got last month (or take from Savings)
* We take from Savings, since we don't budget for future months when we know there will be no inflow, so maybe go with one inflow category
* Adding positive money to inflow 

### TransactionSplits
* Transaction has a refence to Account
* TransactionSplits has a reference to a Transaction, which informs the total value
* TransactionSplit has rerence to a Category and a Plan; it cannot refer to an Account, because it's not a real Transaction
