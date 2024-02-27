defmodule Brolga.Repo.Migrations.AddIndicesToResults do
  use Ecto.Migration

  def change do
    create index(:monitor_results, [:inserted_at, :monitor_id])
  end
end
