{:ok, _pid} = FlopAshAdapter.Repo.start_link()
_migrated = Ecto.Migrator.run(FlopAshAdapter.Repo, :up, all: true)
{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
