defmodule Brolga.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :monitor_id, references(:monitors, on_delete: :delete_all, type: :binary_id)
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime

      timestamps()
    end
  end
end
