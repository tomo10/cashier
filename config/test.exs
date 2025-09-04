import Config

config :cashier, Cashier.Repo,
  database: "cashier_repo_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
