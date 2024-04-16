defmodule Brolga do
  @moduledoc """
  Brolga keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Populate the whole app with mandatory data if it is not already present.
  """
  def init() do
    if Brolga.Monitoring.list_monitor_tags() == [] do
      IO.puts("[*] No tags found, creating default ones...")
      Brolga.Monitoring.create_monitor_tag(%{name: "Prod"})
      Brolga.Monitoring.create_monitor_tag(%{name: "Test"})
    end

    if Brolga.Accounts.count_users() == 0 do
      auth = Application.fetch_env!(:brolga, :auth)

      credentials = %{
        email: auth[:default_admin_email],
        password: auth[:default_admin_password]
      }

      Brolga.Accounts.register_user(credentials)
    end

    if Brolga.Dashboards.count_dashboards() == 0 do
      Brolga.Dashboards.create_dashboard(%{
        name: "Default",
        default: true
      })
    end
  end
end
