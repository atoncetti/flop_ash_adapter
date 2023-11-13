import Config

config :flop_ash_adapter,
  ash_apis: [MyApp.Thing]

config :flop_ash_adapter,
  ecto_repos: [FlopAshAdapter.Repo],
  repo: FlopAshAdapter.Repo

config :flop_ash_adapter, FlopAshAdapter.Repo,
  username: "root",
  password: "",
  database: "flop_ash_adapter_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :flop_ash_adapter, FlopAshAdapter.Repo,
  migration_primary_key: [name: :id, type: :binary_id],
  migration_foreign_key: [column: :id, type: :binary_id]

config :stream_data,
  max_runs: if(System.get_env("CI"), do: 100, else: 50),
  max_run_time: if(System.get_env("CI"), do: 3000, else: 200)

config :logger, level: :warning
