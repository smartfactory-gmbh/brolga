# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Brolga.Repo.insert!(%Brolga.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if length(Brolga.Monitoring.list_monitor_tags()) == 0 do
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
