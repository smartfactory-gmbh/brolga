defmodule Brolga.Monitoring.Monitor do
  @moduledoc """
  A model that represents a target to be watched.
  Updating a monitor will stop (if it was running) and restart the
  corresponding worker.
  """

  alias Brolga.Monitoring.{MonitorResult, MonitorTag}
  alias Brolga.Alerting.Incident
  alias Brolga.Dashboards.Dashboard
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Jason.Encoder,
    only: [
      :id,
      :name,
      :url,
      :interval_in_minutes,
      :active,
      :timeout_in_seconds,
      :inserted_at,
      :updated_at
    ]
  }

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          name: String.t(),
          url: String.t(),
          interval_in_minutes: non_neg_integer(),
          updated_at: DateTime.t(),
          inserted_at: DateTime.t(),
          timeout_in_seconds: non_neg_integer(),
          active: boolean(),
          up: boolean(),
          is_down: boolean() | nil,
          uptime: float() | nil,
          host: String.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "monitors" do
    field :name, :string
    field :url, :string
    field :host, :string, virtual: true
    field :up, :boolean, default: true
    field :interval_in_minutes, :integer
    field :active, :boolean, default: true
    field :timeout_in_seconds, :integer, default: 10

    has_many :monitor_results, MonitorResult, preload_order: [desc: :inserted_at]
    has_many :incidents, Incident, preload_order: [desc: :started_at]
    many_to_many :monitor_tags, MonitorTag, join_through: "monitors_tags", on_replace: :delete
    many_to_many :dashboards, Dashboard, join_through: "monitors_dashboards", on_replace: :delete

    timestamps()

    field(:is_down, :boolean, virtual: true)
    field(:uptime, :float, virtual: true)
  end

  @doc false
  def changeset(monitor, attrs) do
    monitor
    |> cast(attrs, [:name, :url, :timeout_in_seconds, :active, :interval_in_minutes])
    |> validate_required([:name, :url, :interval_in_minutes])
    |> validate_length(:name, min: 5)
    |> validate_length(:url, min: 5)
    |> validate_format(:url, ~r"^https?://", message: "should start with http:// or https://")
    |> validate_number(:interval_in_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:timeout_in_seconds, greater_than_or_equal_to: 1)
    |> check_constraint(:timeout_in_seconds,
      name: :timout_lower_than_interval,
      message: "Timout cannot exceed the interval timing"
    )
  end

  def changeset_toggle_state(monitor, attrs) do
    monitor
    |> cast(attrs, [:up])
    |> validate_required([:up])
  end

  @spec populate_host(monitor :: t()) :: t()
  @doc """
  Populates the virtual host field based on the persisted url field
  """
  def populate_host(monitor) do
    host =
      Regex.replace(~r"^https?://", monitor.url, "")
      |> String.split("/")
      |> Enum.at(0)

    %{monitor | host: host}
  end

  @spec populate_hosts(monitors :: [t()]) :: [t()]
  @doc """
  Populates the host for a whole list of monitors
  """
  def populate_hosts(monitors) do
    monitors |> Enum.map(&populate_host/1)
  end
end
