import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

running_in_docker = System.get_env("RUNNING_IN_DOCKER", "false") == "true"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# Setting the hosts of difference services depending on whether or not it's running in docker
{db_host} =
  if running_in_docker do
    {"db"}
  else
    {"localhost"}
  end

config :brolga, Brolga.Repo,
  username: "postgres",
  password: "postgres",
  hostname: db_host,
  database: "brolga_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :brolga_web, BrolgaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XLN4pvPa+LkeoJD+u0oAcbhi+vsPYMr2YHSkEw55SP6fEkhFnTgSAkWxANFW9S5Z",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails.
config :brolga, Brolga.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :brolga, :auth,
  default_admin_email: "test-admin@brolga.test",
  default_admin_password: "test-admin-password"

config :brolga, :email_notifier,
  enabled: true,
  from: {
    "Exemple admin",
    "admin@example.com"
  },
  to: {
    "Example recipient",
    "recipient@example.com"
  }

config :brolga, :slack_notifier,
  enabled: true,
  webhook_url: "https://hooks.slack.com/services/FaKe/WeBhOoK",
  username: "Brolga",
  channel: "#sysops"
