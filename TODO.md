## TODO

* add some zero state (e.g. CategoryGroup needs a Plan)
* on CategoryGroup, add labels for how many categories are associated
* on Categories, add labels for how many Plans/CategoryGroups are associated
* include a special category for to-be-budgeted inflow; should be added on priv/repo/seeds.exs for test/development and as a migration
* on categories with totals, show total assigned/activity/available for each category group
* on categories with totals, show how much is available from the special inflow category
* implement transaction splits between categories
* implement transaction splits between categories between Plans;
* assign transactions to an Account; Account may be associated with two Plans
* an Account can be associated with more than one Plan; on the Transaction screen, we only show the Transaction of the current Plan
* introduce Plan as a an application context (https://hexdocs.pm/phoenix/contexts.html)

* clean up application
* fix tests
* check import error

## Scratch pad
* Transaction has a refence to Account
* TransactionSplits has a reference to a Transaction, which informs the total value
* TransactionSplit has rerence to a Category and a Plan; it cannot refer to an Account, because it's not a real Transaction