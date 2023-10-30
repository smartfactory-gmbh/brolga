defmodule Brolga.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_add_apps: [:mix]
      ],
      test_coverage: [
        summary: [
          threshold: 85
        ],
        ignore_modules: [
          BrolgaWeb.Application,
          BrolgaWeb.Telemetry,
          BrolgaWeb.Release,
          BrolgaWeb.PageHTML,
          BrolgaWeb.Layouts,
          Brolga.Watcher.Redix,
          Mix.Tasks.TestNotifiers
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:inets]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    [
      # Required to run "mix format" on ~H/.heex files from the umbrella root
      {:phoenix_live_view, ">= 0.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:tzdata, "~> 1.1"},
      {:pre_commit, "~> 0.3.4", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      sentry_recompile: ["compile", "deps.compile sentry --force"]
    ]
  end
end
