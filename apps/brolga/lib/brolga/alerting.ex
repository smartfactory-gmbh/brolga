defmodule Brolga.Alerting do
  @moduledoc """
  The Alerting context.
  """

  import Ecto.Query, warn: false
  alias Brolga.Repo

  alias Brolga.Monitoring.Monitor
  alias Brolga.Alerting.Incident

  @doc """
  Returns the list of incidents.

  ## Examples

      iex> list_incidents()
      [%Incident{}, ...]

  """
  def list_incidents do
    Repo.all(Incident)
  end

  @doc """
  Gets a single incident.

  Raises `Ecto.NoResultsError` if the Incident does not exist.

  ## Examples

      iex> get_incident!(123)
      %Incident{}

      iex> get_incident!(456)
      ** (Ecto.NoResultsError)

  """
  def get_incident!(id), do: Repo.get!(Incident, id)

  def get_last_incidents!(monitor_id) do
    alias Brolga.Alerting.Incident.Query

    Query.base()
    |> Query.filter_monitor_id(monitor_id)
    |> Query.order_by_latest()
    |> limit(5)
    |> Repo.all()
  end

  @doc """
  Creates a incident.

  ## Examples

      iex> create_incident(%{field: value})
      {:ok, %Incident{}}

      iex> create_incident(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_incident(attrs \\ %{}) do
    %Incident{}
    |> Incident.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a incident.

  ## Examples

      iex> update_incident(incident, %{field: new_value})
      {:ok, %Incident{}}

      iex> update_incident(incident, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_incident(%Incident{} = incident, attrs) do
    incident
    |> Incident.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a incident.

  ## Examples

      iex> delete_incident(incident)
      {:ok, %Incident{}}

      iex> delete_incident(incident)
      {:error, %Ecto.Changeset{}}

  """
  def delete_incident(%Incident{} = incident) do
    Repo.delete(incident)
  end

  @spec open_incident(monitor :: Monitor.t()) :: Incident.t()
  def open_incident(monitor) do
    results =
      create_incident(%{
        started_at: DateTime.utc_now(),
        monitor_id: monitor.id
      })

    case results do
      {:ok, incident} ->
        incident
        |> Repo.preload(:monitor)
        |> Brolga.AlertNotifiers.new_incident()

      _ ->
        nil
    end

    results
  end

  @spec close_incident(monitor :: Monitor.t()) :: Incident.t()
  def close_incident(monitor) do
    incident =
      Repo.one(from i in Incident, where: is_nil(i.ended_at) and i.monitor_id == ^monitor.id)

    case incident do
      nil ->
        nil

      incident ->
        results = update_incident(incident, %{ended_at: DateTime.utc_now()})

        case results do
          {:ok, incident} ->
            incident
            |> Repo.preload(:monitor)
            |> Brolga.AlertNotifiers.incident_resolved()

          _ ->
            nil
        end

        results
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking incident changes.

  ## Examples

      iex> change_incident(incident)
      %Ecto.Changeset{data: %Incident{}}

  """
  def change_incident(%Incident{} = incident, attrs \\ %{}) do
    Incident.changeset(incident, attrs)
  end
end
