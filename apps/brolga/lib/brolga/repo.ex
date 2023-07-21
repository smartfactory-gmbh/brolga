defmodule Brolga.Repo do
  use Ecto.Repo,
    otp_app: :brolga,
    adapter: Ecto.Adapters.Postgres
end
