defmodule Brolga.Repo.Migrations.CreateMonitorResults do
  use Ecto.Migration

  def change do
    create table(:monitor_results, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :reached, :boolean, default: false, null: false
      add :monitor_id, references(:monitors, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:monitor_results, [:monitor_id, :inserted_at])
  end
end
