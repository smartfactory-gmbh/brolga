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

Brolga.Monitoring.create_monitor_tag(%{name: "Prod"})
Brolga.Monitoring.create_monitor_tag(%{name: "Test"})
