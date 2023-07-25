defmodule Brolga.Repo.Migrations.AddMessageToMonitorResult do
  use Ecto.Migration

  def change do
    alter table(:monitor_results) do
      add :message, :string, default: "", null: false
    end
  end
end
