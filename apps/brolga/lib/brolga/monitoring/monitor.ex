defmodule Brolga.Monitoring.Monitor do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "monitors" do
    field :name, :string
    field :url, :string
    field :interval_in_minutes, :integer

    timestamps()
  end

  @doc false
  def changeset(monitor, attrs) do
    monitor
    |> cast(attrs, [:name, :url, :interval_in_minutes])
    |> validate_required([:name, :url, :interval_in_minutes])
    |> validate_length(:name, min: 5)
    |> validate_length(:url, min: 5)
    |> validate_number(:interval_in_minutes, greater_than_or_equal_to: 0)
  end
end
