import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :brolga, Brolga.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
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

config :brolga, :redis,
  host: "localhost",
  port: 6379,
  username: nil,
  password: nil

config :brolga, :auth,
  default_admin_email: "test-admin@brolga.test",
  default_admin_password: "test-admin-password"
