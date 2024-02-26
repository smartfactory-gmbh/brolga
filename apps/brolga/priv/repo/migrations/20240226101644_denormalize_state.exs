defmodule Brolga.Repo.Migrations.DenormalizeState do
  use Ecto.Migration

  def change do
    alter table(:monitors) do
      add :up, :boolean, default: true, null: false
    end
  end
end
