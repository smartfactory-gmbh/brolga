defmodule BrolgaCron.MixProject do
  use Mix.Project

  @description "Dead simple application that runs tasks periodically"

  def project do
    [
      app: :brolga_cron,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: @description
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BrolgaCron.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:brolga, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
