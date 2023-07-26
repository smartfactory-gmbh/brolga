defmodule Brolga.Repo.Migrations.AddMonitorActiveAndTimeout do
  use Ecto.Migration

  def change do
    alter table(:monitors) do
      add :timeout_in_seconds, :integer, default: 10
      add :active, :boolean, default: true
    end

    create constraint(:monitors, :timout_lower_than_interval,
             check: "timeout_in_seconds < ( interval_in_minutes * 60 )"
           )
  end
end
