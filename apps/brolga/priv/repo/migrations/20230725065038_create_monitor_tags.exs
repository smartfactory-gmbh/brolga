defmodule Brolga.Repo.Migrations.CreateMonitorTags do
  use Ecto.Migration

  def change do
    create table(:monitor_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :name, :string

      timestamps()
    end
    create unique_index(:monitor_tags, [:name])

    create table(:monitors_tags) do
      add :monitor_id, references(:monitors, on_delete: :delete_all, type: :binary_id)
      add :monitor_tag_id, references(:monitor_tags, on_delete: :delete_all, type: :binary_id)
    end
    create unique_index(:monitors_tags, [:monitor_id, :monitor_tag_id])

  end
end
