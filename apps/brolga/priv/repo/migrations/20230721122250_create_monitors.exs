defmodule Brolga.Repo.Migrations.CreateMonitors do
  use Ecto.Migration

  def change do
    create table(:monitors, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :name, :string, null: false
      add :url, :string, null: false
      add :interval_in_minutes, :integer, null: false

      timestamps()
    end
  end
end
