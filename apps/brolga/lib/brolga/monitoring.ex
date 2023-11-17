defmodule Brolga.Monitoring do
  @moduledoc """
  The Monitoring context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Brolga.Repo
  alias Brolga.Monitoring.{Monitor, MonitorResult, MonitorTag}
  alias Brolga.Alerting

  @last_results_count 25
  # keeping a bit more than a month to be sure
  @retention_days 32

  defp get_config do
    Application.get_env(:brolga, :monitoring)
  end

  defp get_base_monitor_query() do
    alias Brolga.Monitoring.Monitor.Query
    config = get_config()

    Query.base()
    |> Query.with_down_state()
    |> Query.with_uptime(config[:uptime_lookback_days])
    |> Query.order_by_name()
  end

  @doc """
  Returns the list of monitors.

  ## Examples

      iex> list_monitors()
      [%Monitor{}, ...]

  """
  def list_monitors do
    Repo.all(get_base_monitor_query())
  end

  def list_monitors_for_dashboard(dashboard_id) do
    alias Brolga.Monitoring.Monitor.Query
    query = get_base_monitor_query()

    monitors =
      query
      |> Query.where_dashboard(dashboard_id)
      |> Repo.all()

    if monitors == [] do
      list_monitors()
    else
      monitors
    end
  end

  def list_monitors_with_latest_results(opts \\ []) do
    alias Brolga.Monitoring.Monitor.Query

    with_tags = opts |> Keyword.get(:with_tags, false)

    if with_tags do
      Query.base() |> Query.with_monitor_tags()
    else
      Query.base()
    end
    |> Query.with_latest_results(@last_results_count)
    |> Query.order_by_name()
    |> Repo.all()
  end

  def list_active_monitor_ids do
    alias Brolga.Monitoring.Monitor.Query

    Query.base()
    |> Query.filter_active(true)
    |> Query.to_ids()
    |> Repo.all()
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
    alias Brolga.Monitoring.Monitor.Query
    config = get_config()

    monitor_query =
      Query.base()
      |> Query.with_uptime(config[:uptime_lookback_days])
      |> Query.with_down_state()
      |> Query.with_monitor_tags()
      |> Query.with_latest_incidents(5)
      |> Query.with_latest_results(25)

    Repo.one!(from monitor_query, where: [id: ^id])
  end

  def get_active_monitor!(id) do
    alias Brolga.Monitoring.Monitor.Query

    Query.base()
    |> Query.filter_active(true)
    |> where([m], m.id == ^id)
    |> Repo.one!()
  end

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

  ## Options

  * `:with_monitors` - Preloads the related monitors
  * `:order` - Specifies the order to use

  ## Examples

      iex> list_monitor_results()
      [%MonitorResult{}, ...]

  """
  def list_monitor_results(options \\ []) do
    with_monitors = options |> Keyword.get(:with_monitors, false)
    query = from(m in MonitorResult)
    order = options |> Keyword.get(:order, nil)

    query =
      if with_monitors do
        query |> preload(:monitor)
      else
        query
      end

    query =
      if order do
        query |> order_by(^order)
      else
        query
      end

    Repo.all(query)
  end

  defp get_previous_monitor_results_query(options) do
    length = options |> Keyword.get(:length, 15)
    cutoff_date = options |> Keyword.get(:cutoff_date, nil)

    query = from(m in MonitorResult)

    query =
      if is_nil(cutoff_date) do
        query
      else
        query |> where([m], m.inserted_at <= ^cutoff_date)
      end

    query
    |> order_by(desc: :inserted_at)
    |> limit(^length)
    |> preload(:monitor)
  end

  @doc """
  Returns the previous result related to the row number given in the param

  ## Options

  * `:length` - Specifies how many records should be returned
  * `:cutoff_date` - from which date it should count (should reuse the attribute used for order)

  ## Examples

      iex> get_previous_monitor_results(5, length: 10)
      [%MonitorResult{}, ...]

  """
  def get_previous_monitor_results(last_number, options \\ [])
  def get_previous_monitor_results(nil, options), do: get_previous_monitor_results(0, options)

  def get_previous_monitor_results(last_number, options) do
    query = get_previous_monitor_results_query(options)
    Repo.all(query |> offset(^last_number))
  end

  @doc """
  Returns the previous result related to the row number given in the param.
  Only fetches results for a specific monitor

  ## Options

  * `:length` - Specifies how many records should be returned
  * `:cutoff_date` - from which date it should count (should reuse the attribute used for order)

  ## Examples

      iex> get_previous_monitor_results_for("id", 5, length: 10)
      [%MonitorResult{}, ...]

  """
  def get_previous_monitor_results_for(monitor_id, last_number, options \\ [])

  def get_previous_monitor_results_for(monitor_id, nil, options),
    do: get_previous_monitor_results_for(monitor_id, 0, options)

  def get_previous_monitor_results_for(monitor_id, last_number, options) do
    query =
      get_previous_monitor_results_query(options)
      |> where(monitor_id: ^monitor_id)

    Repo.all(query |> offset(^last_number))
  end

  @doc """
  Deletes all the monitor results that are older than the retention threshold.
  This should be run regularly to avoid clutering the database with data that is not
  relevant anymore

  ## Examples

      iex> cleanup_monitor_results()
      {1, [%MonitorResult{}]}

      iex> cleanup_monitor_results()
      {0, nil}

  """
  @spec cleanup_monitor_results() ::
          {count :: non_neg_integer(), results :: [MonitorResult.t()] | nil}
  def cleanup_monitor_results do
    threshold = Timex.now() |> Timex.shift(days: -@retention_days)

    Repo.delete_all(
      from r in MonitorResult,
        where: r.inserted_at <= ^threshold
    )
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
