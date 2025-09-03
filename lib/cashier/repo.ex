defmodule Cashier.Repo do
  use Ecto.Repo,
    otp_app: :cashier,
    adapter: Ecto.Adapters.Postgres
end
