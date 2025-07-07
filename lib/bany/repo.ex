defmodule Bany.Repo do
  use Ecto.Repo,
    otp_app: :bany,
    adapter: Ecto.Adapters.Postgres
end
