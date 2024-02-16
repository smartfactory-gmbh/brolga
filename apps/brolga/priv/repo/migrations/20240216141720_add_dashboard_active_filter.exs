defmodule Brolga.Repo.Migrations.AddDashboardActiveFilter do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      add :hide_inactives, :boolean, default: false, null: false
    end
  end
end
