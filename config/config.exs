import Config

config :cashier,
  ecto_repos: [Cashier.Repo]

config :cashier, Cashier.Repo,
  database: "cashier_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
