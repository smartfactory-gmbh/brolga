defmodule Brolga.Repo.Migrations.AddStatusCodeToResults do
  use Ecto.Migration

  def change do
    alter table(:monitor_results) do
      add :status_code, :integer, default: nil, null: true
    end
  end
end
