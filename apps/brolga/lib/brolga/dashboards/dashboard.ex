defmodule Brolga.Dashboards.Dashboard do
  @moduledoc """
  Represent a dashboard config, which will define which monitors are shown
  It can use either tags or specific monitors (or both) to filter what will be shown.
  If no tag and no specific monitor is selected, it will show all
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Brolga.Repo

  alias Brolga.Monitoring.{Monitor, MonitorTag}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          monitors: [Monitor.t()]
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "dashboards" do
    field :name, :string

    many_to_many :monitors, Monitor, join_through: "monitors_dashboards", on_replace: :delete

    many_to_many :monitor_tags, MonitorTag,
      join_through: "monitor_tags_dashboards",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def resolved_monitors(dashboard) do
    Brolga.Monitoring.list_monitors() |> where([m], m.dashboards == ^dashboard) |> Repo.all()
  end
end
