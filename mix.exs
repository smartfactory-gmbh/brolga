defmodule Brolga.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      cli: cli(),
      test_coverage: [
        summary: [
          threshold: 85
        ],
        ignore_modules: [
          Brolga.AccountsFixtures,
          Brolga.AlertingFixtures,
          Brolga.DashboardsFixtures,
          BrolgaWeb.Application,
          BrolgaWeb.Telemetry,
          BrolgaWeb.Release,
          BrolgaWeb.PageHTML,
          BrolgaWeb.Layouts,
          Mix.Tasks.TestNotifiers,
          Mix.Tasks.CleanupOldResults,
          Brolga,
          Brolga.Repo
        ]
      ],
      releases: [
        brolga_umbrella: [
          applications: [
            brolga: :permanent,
            brolga_web: :permanent,
            brolga_cron: :permanent
          ]
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
      {:tzdata, "~> 1.1"}
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
      setup: ["deps.get", "cmd mix setup"],
      sentry_recompile: ["compile", "deps.compile sentry --force"],
      coverage: ["test --cover --export-coverage default", "test.coverage"]
    ]
  end

  def cli do
    [preferred_envs: [coverage: :test]]
  end
end
