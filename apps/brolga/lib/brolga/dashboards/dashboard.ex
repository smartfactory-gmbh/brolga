defmodule Brolga.Dashboards.Dashboard do
  @moduledoc """
  Represent a dashboard config, which will define which monitors are shown
  It can use either tags or specific monitors (or both) to filter what will be shown.
  If no tag and no specific monitor is selected, it will show all
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Brolga.Monitoring.{Monitor, MonitorTag}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          default: boolean(),
          hide_inactives: boolean(),
          monitors: [Monitor.t()]
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "dashboards" do
    field :name, :string
    field :hide_inactives, :boolean, default: false
    field :default, :boolean, default: false

    many_to_many :monitors, Monitor, join_through: "monitors_dashboards", on_replace: :delete

    many_to_many :monitor_tags, MonitorTag,
      join_through: "monitor_tags_dashboards",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:name, :default, :hide_inactives])
    |> validate_required([:name])
  end
end
