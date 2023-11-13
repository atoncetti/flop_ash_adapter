defmodule FlopAshAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :flop_ash_adapter,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_else), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 2.15"},
      {:ash_postgres, "~> 1.3", only: :test},
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:ex_machina, "~> 2.7", only: :test},
      {:flop, "~> 0.23.0"}
    ]
  end
end
