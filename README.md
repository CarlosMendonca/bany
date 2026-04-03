# Bany

**A personal budgeting app inspired by YNAB.**

Bany is an envelope budgeting application built for individuals and households who want full control over their financial data. It supports multi-currency budgets, real-time UI updates via Phoenix LiveView, and importing existing YNAB export files.

<!-- screenshot: app overview / dashboard -->

---

## Features

### Budget Plans

- Create named budgets with a currency selection (20+ supported currencies)
- Share plans across multiple users

<!-- screenshot: plans list -->

### Category Groups & Categories

- Organize spending into groups (e.g. Housing → Rent, Utilities)
- Per-category totals: assigned, spent, and available
- Inflow categories for tracking income sources

<!-- screenshot: categories view -->

### Monthly Allocations

- Assign money to categories per month (YNAB-style envelope budgeting)
- "Ready to Assign" calculation: all-time inflows minus all-time allocations

<!-- screenshot: allocations / budget view -->

### Transactions

- Full-text search across memo, payee, and amount
- Multi-filter panels: category, account, tag, and date range
- Inline editing for single rows and batch multi-row edits
- Column sorting with URL-persisted pagination

<!-- screenshot: transactions list with filters -->

### Accounts

- Track financial accounts (checking, savings, etc.)
- Scoped per user and plan

<!-- screenshot: accounts list -->

### Payees

- Auto-created from imports or manual transaction entry
- Searchable payee input on transaction forms

<!-- screenshot: payees -->

### Tags

- Color-coded labels (21 color options) for transactions
- Filter transactions by one or multiple tags

<!-- screenshot: tags -->

### YNAB CSV Import

- Import existing YNAB export files
- Auto-creates plans, accounts, category groups, categories, and payees
- Row-level error reporting with import statistics

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | **Elixir / Phoenix 1.8** |
| UI | **Phoenix LiveView 1.0** — real-time interactive UI without writing JS |
| Large lists | **LiveView Streams** — efficient DOM diffing for large transaction lists |
| Database | **PostgreSQL** via Ecto |
| Styling | **Tailwind CSS** |
| Icons | **Heroicons** |
| Currency | **`money`** — multi-currency support |
| CSV parsing | **`nimble_csv`** — YNAB CSV import |
| Auth | **`bcrypt_elixir`** — password hashing |
| Dev environment | **devenv** — reproducible Nix-based setup |

## Running Locally

### Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- [devenv](https://devenv.sh/getting-started/)

### 1. Enter the devenv shell (activates Elixir, tools, and environment variables)

```sh
devenv shell
```

### 2. Start Phoenix + PostgreSQL as background processes

```sh
devenv up
```

### 3. (First run only) Set up the database and assets

```sh
mix setup
```

The app will be available at [http://localhost:4000](http://localhost:4000).

- `devenv shell` activates the Nix environment with Elixir and all dependencies
- `devenv up` launches both the Phoenix server and a local PostgreSQL instance — no manual role or database creation needed
- PostgreSQL connection is configured automatically via environment variables in the devenv shell
