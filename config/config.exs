# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configure Mix tasks and generators
config :brolga,
  ecto_repos: [Brolga.Repo],
  default_timezone: System.get_env("BROLGA_DEFAULT_TZ", "Etc/UTC"),
  incident_mail_config: [
    from: {
      System.get_env("BROLGA_INCIDENT_MAIL_FROM_NAME", "Example"),
      System.get_env("BROLGA_INCIDENT_MAIL_FROM_EMAIL", "test@Example.com"),
    },
    to: {
      System.get_env("BROLGA_INCIDENT_MAIL_TO_NAME", "Example recipient"),
      System.get_env("BROLGA_INCIDENT_MAIL_TO_EMAIL", "test-recipient@Example.com"),
    },
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :brolga, Brolga.Mailer, adapter: Swoosh.Adapters.Local

config :brolga_web,
  ecto_repos: [Brolga.Repo],
  generators: [context_app: :brolga]

# Configures the endpoint
config :brolga_web, BrolgaWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: BrolgaWeb.ErrorHTML, json: BrolgaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Brolga.PubSub,
  live_view: [signing_salt: "99Crn4H4"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/brolga_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/brolga_web/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


config :brolga_watcher,
  redis: [
    host: nil,
    port: nil,
    username: nil,
    password: nil,
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
