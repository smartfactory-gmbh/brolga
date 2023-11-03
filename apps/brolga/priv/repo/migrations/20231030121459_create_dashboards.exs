defmodule Brolga.Repo.Migrations.CreateDashboards do
  use Ecto.Migration

  def change do
    create table(:dashboards, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :name, :string
      add :default, :boolean, default: false

      timestamps()
    end

    create table(:monitors_dashboards) do
      add :monitor_id, references(:monitors, on_delete: :delete_all, type: :binary_id)
      add :dashboard_id, references(:dashboards, on_delete: :delete_all, type: :binary_id)
    end

    create table(:monitor_tags_dashboards) do
      add :monitor_tag_id, references(:monitor_tags, on_delete: :delete_all, type: :binary_id)
      add :dashboard_id, references(:dashboards, on_delete: :delete_all, type: :binary_id)
    end
  end
end
