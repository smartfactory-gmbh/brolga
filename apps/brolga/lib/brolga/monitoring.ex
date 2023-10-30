defmodule Brolga.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Brolga.CustomSql
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]
  alias Brolga.Alerting.Incident
  alias Brolga.Repo

  alias Brolga.Monitoring.Monitor
  alias Brolga.Monitoring.MonitorResult
  alias Brolga.Alerting
  alias Brolga.Alerting.Incident

  @last_results_count 25

  defp get_config do
    Application.get_env(:brolga, :monitoring)
  end

  @doc """
  Returns the list of monitors.

  ## Examples

      iex> list_monitors()
      [%Monitor{}, ...]

  """
  def list_monitors do
    config = get_config()
    lookback_start = Timex.now() |> Timex.shift(days: -config[:uptime_lookback_days])

    down_monitor_ids =
      from i in Incident,
        where: is_nil(i.ended_at),
        select: i.monitor_id

    uptime_query =
      from mr in MonitorResult,
        where: mr.inserted_at >= ^lookback_start,
        group_by: mr.monitor_id,
        select: %{monitor_id: mr.monitor_id, uptime: avg(case_when(mr.reached, 1, 0))}

    monitor_query =
      from m in Monitor,
        as: :monitor,
        left_join: up in subquery(uptime_query),
        on: up.monitor_id == m.id,
        order_by: m.name,
        # The select below populates the virtual field(s), since they are not persisted
        select_merge: %{
          is_down: case_when(m.id in subquery(down_monitor_ids), true, false),
          uptime: up.uptime |> coalesce(0)
        }

    Repo.all(monitor_query)
  end

  def list_monitors_with_latest_results do
    result_partition_query =
      from result in MonitorResult,
        order_by: [desc: :inserted_at],
        select: %{
          id: result.id,
          reached: result.reached,
          row_number: over(row_number(), :results_partition)
        },
        windows: [results_partition: [partition_by: :monitor_id, order_by: [desc: :inserted_at]]]

    results_query =
      from result in MonitorResult,
        join: r in subquery(result_partition_query),
        on: result.id == r.id and r.row_number <= @last_results_count

    monitor_query =
      from m in Monitor,
        as: :monitor,
        preload: [monitor_results: ^results_query],
        order_by: m.name

    Repo.all(monitor_query)
  end

  def list_active_monitor_ids do
    Repo.all(from m in Monitor, select: m.id, where: m.active == true)
  end

  @doc """
  Gets a single monitor.

  Raises `Ecto.NoResultsError` if the Monitor does not exist.

  ## Examples

      iex> get_monitor!(123)
      %Monitor{}

      iex> get_monitor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor!(id), do: Repo.get!(Monitor, id)
  def get_monitors!(ids), do: Repo.all(from m in Monitor, where: m.id in ^ids)

  def get_monitor_with_details!(id) do
    config = get_config()
    lookback_start = Timex.now() |> Timex.shift(days: -config[:uptime_lookback_days])

    down_monitor_ids =
      from i in Incident,
        where: is_nil(i.ended_at),
        select: i.monitor_id

    uptime_query =
      from mr in MonitorResult,
        where: mr.inserted_at >= ^lookback_start,
        group_by: mr.monitor_id,
        select: %{monitor_id: mr.monitor_id, uptime: avg(case_when(mr.reached, 1, 0))}

    results_query = from r in MonitorResult, order_by: [desc: r.inserted_at], limit: 25
    incidents_query = from i in Incident, order_by: [desc: i.started_at], limit: 5

    monitor_query =
      from m in Monitor,
        where: m.id == ^id,
        preload: [
          :monitor_tags,
          incidents: ^incidents_query,
          monitor_results: ^results_query
        ],
        left_join: up in subquery(uptime_query),
        on: up.monitor_id == m.id,
        select_merge: %{
          is_down: case_when(m.id in subquery(down_monitor_ids), true, false),
          uptime: up.uptime
        }

    Repo.one!(monitor_query)
  end

  def get_active_monitor!(id), do: Repo.get_by!(Monitor, id: id, active: true)

  @doc """
  Creates a monitor.

  ## Examples

      iex> create_monitor(%{field: value})
      {:ok, %Monitor{}}

      iex> create_monitor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor(attrs \\ %{}) do
    tags =
      if attrs["monitor_tags"] do
        get_monitor_tags!(attrs["monitor_tags"])
      else
        []
      end

    result =
      %Monitor{}
      |> Monitor.changeset(attrs)
      |> put_assoc(:monitor_tags, tags)
      |> Repo.insert()

    case result do
      {:ok, monitor} ->
        # An new worker is started, matching this new monitor
        Brolga.Watcher.Worker.start(monitor.id)

      _ ->
        nil
    end

    result
  end

  @spec update_monitor(
          Brolga.Monitoring.Monitor.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  @doc """
  Updates a monitor.
  If "active" is set to "true", then a worker is fired up to ping the target

  ## Examples

      iex> update_monitor(monitor, %{field: new_value})
      {:ok, %Monitor{}}

      iex> update_monitor(monitor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor(%Monitor{} = monitor, attrs) do
    tags =
      if attrs["monitor_tags"] do
        get_monitor_tags!(attrs["monitor_tags"])
      else
        []
      end

    result =
      monitor
      |> Monitor.changeset(attrs)
      |> put_assoc(:monitor_tags, tags)
      |> Repo.update()

    case result do
      {:ok, monitor} ->
        # Note: we start it *even* if active = false, because it will cleanup previous workers as well
        # if active is false, it will stop directly anyway
        Brolga.Watcher.Worker.start(monitor.id)

      _ ->
        nil
    end

    result
  end

  @doc """
  Deletes a monitor.

  ## Examples

      iex> delete_monitor(monitor)
      {:ok, %Monitor{}}

      iex> delete_monitor(monitor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor(%Monitor{} = monitor) do
    Brolga.Watcher.Worker.stop(monitor.id)
    Repo.delete(monitor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor changes.

  ## Examples

      iex> change_monitor(monitor)
      %Ecto.Changeset{data: %Monitor{}}

  """
  def change_monitor(%Monitor{} = monitor, attrs \\ %{}) do
    Monitor.changeset(monitor, attrs)
  end

  alias Brolga.Monitoring.MonitorResult

  @doc """
  Returns the list of monitor_results.

  ## Examples

      iex> list_monitor_results()
      [%MonitorResult{}, ...]

  """
  def list_monitor_results do
    Repo.all(MonitorResult)
  end

  @doc """
  Gets a single monitor_result.

  Raises `Ecto.NoResultsError` if the Monitor result does not exist.

  ## Examples

      iex> get_monitor_result!(123)
      %MonitorResult{}

      iex> get_monitor_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor_result!(id), do: Repo.get!(MonitorResult, id)

  defp get_closed_incident_pattern do
    config = get_config()
    (0..(config[:attempts_before_notification] - 1) |> Enum.map(fn _i -> true end)) ++ [false]
  end

  @doc """
  Creates a monitor_result.

  ## Examples

      iex> create_monitor_result(%{field: value})
      {:ok, %MonitorResult{}}

      iex> create_monitor_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor_result(attrs \\ %{}) do
    config = get_config()

    result =
      %MonitorResult{}
      |> MonitorResult.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, monitor_result} ->
        monitor = get_monitor_with_details!(monitor_result.monitor_id)

        last_results =
          monitor.monitor_results
          |> Enum.slice(0..config[:attempts_before_notification])
          |> Enum.map(fn monitor_result -> monitor_result.reached end)

        closed_incident = get_closed_incident_pattern()
        open_incident = closed_incident |> Enum.map(fn value -> not value end)

        case last_results do
          ^closed_incident ->
            # If reached correctly twice, we close the incident
            Alerting.close_incident(monitor)

          ^open_incident ->
            # If reached incorrectly twice, we open an incident
            Alerting.open_incident(monitor)

          _ ->
            nil
        end

      _ ->
        nil
    end

    result
  end

  @doc """
  Updates a monitor_result.

  ## Examples

      iex> update_monitor_result(monitor_result, %{field: new_value})
      {:ok, %MonitorResult{}}

      iex> update_monitor_result(monitor_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor_result(%MonitorResult{} = monitor_result, attrs) do
    monitor_result
    |> MonitorResult.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monitor_result.

  ## Examples

      iex> delete_monitor_result(monitor_result)
      {:ok, %MonitorResult{}}

      iex> delete_monitor_result(monitor_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor_result(%MonitorResult{} = monitor_result) do
    Repo.delete(monitor_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor_result changes.

  ## Examples

      iex> change_monitor_result(monitor_result)
      %Ecto.Changeset{data: %MonitorResult{}}

  """
  def change_monitor_result(%MonitorResult{} = monitor_result, attrs \\ %{}) do
    MonitorResult.changeset(monitor_result, attrs)
  end

  alias Brolga.Monitoring.MonitorTag

  @doc """
  Returns the list of monitor_tags.

  ## Examples

      iex> list_monitor_tags()
      [%MonitorTag{}, ...]

  """
  def list_monitor_tags do
    Repo.all(MonitorTag)
  end

  @doc """
  Gets a single monitor_tag.

  Raises `Ecto.NoResultsError` if the Monitor tag does not exist.

  ## Examples

      iex> get_monitor_tag!(123)
      %MonitorTag{}

      iex> get_monitor_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monitor_tag!(id), do: Repo.get!(MonitorTag, id)

  def get_monitor_tags!(ids), do: Repo.all(from t in MonitorTag, where: t.id in ^ids)

  @doc """
  Creates a monitor_tag.

  ## Examples

      iex> create_monitor_tag(%{field: value})
      {:ok, %MonitorTag{}}

      iex> create_monitor_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monitor_tag(attrs \\ %{}) do
    %MonitorTag{}
    |> MonitorTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a monitor_tag.

  ## Examples

      iex> update_monitor_tag(monitor_tag, %{field: new_value})
      {:ok, %MonitorTag{}}

      iex> update_monitor_tag(monitor_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monitor_tag(%MonitorTag{} = monitor_tag, attrs) do
    monitor_tag
    |> MonitorTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monitor_tag.

  ## Examples

      iex> delete_monitor_tag(monitor_tag)
      {:ok, %MonitorTag{}}

      iex> delete_monitor_tag(monitor_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monitor_tag(%MonitorTag{} = monitor_tag) do
    Repo.delete(monitor_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monitor_tag changes.

  ## Examples

      iex> change_monitor_tag(monitor_tag)
      %Ecto.Changeset{data: %MonitorTag{}}

  """
  def change_monitor_tag(%MonitorTag{} = monitor_tag, attrs \\ %{}) do
    MonitorTag.changeset(monitor_tag, attrs)
  end
end
