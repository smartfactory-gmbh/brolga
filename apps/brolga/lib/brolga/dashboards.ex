defmodule Brolga.Dashboards do
  @moduledoc """
  The Dashboards context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]
  alias Brolga.Repo
  alias Brolga.Monitoring

  alias Brolga.Dashboards.Dashboard

  @doc """
  Returns the list of dashboards.

  ## Examples

      iex> list_dashboards()
      [%Dashboard{}, ...]

  """
  def list_dashboards do
    Repo.all(Dashboard)
  end

  @doc """
  Gets the count of exiting dashboards.

  ## Examples

      iex> count_dashboards()
      0

  """
  def count_dashboards do
    Repo.one!(from d in Dashboard, select: count(d.id, :distinct))
  end

  @doc """
  Gets a single dashboard.

  Raises `Ecto.NoResultsError` if the Dashboard does not exist.

  ## Examples

      iex> get_dashboard!(123)
      %Dashboard{}

      iex> get_dashboard!(456)
      ** (Ecto.NoResultsError)

  """
  def get_dashboard!(id), do: Repo.get!(Dashboard, id)

  @doc """
  ## Examples

      iex> get_default_dashboard()
      %Dashboard{}

      iex> get_default_dashboard()
      nil

  """
  def get_default_dashboard() do
    case Repo.one(from d in Dashboard, where: d.default == true) do
      {:ok, dashboard} -> dashboard
      _ -> nil
    end
  end

  @doc """
  ## Examples

      iex> get_default_dashboard(dashboard)
      {:ok, %Dashboard{}}

      iex> set_default_dashboard(dashboard)
      {:error, %Ecto.Changeset{}}

  """
  def set_default_dashboard(dashboard) do
    Repo.update_all(Dashboard, set: [default: false])

    dashboard
    |> Dashboard.changeset(%{"default" => true})
    |> Repo.update()
  end

  @doc """
  Creates a dashboard.

  ## Examples

      iex> create_dashboard(%{field: value})
      {:ok, %Dashboard{}}

      iex> create_dashboard(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_dashboard(attrs \\ %{}) do
    %Dashboard{}
    |> Dashboard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a dashboard.

  ## Examples

      iex> update_dashboard(dashboard, %{field: new_value})
      {:ok, %Dashboard{}}

      iex> update_dashboard(dashboard, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_dashboard(%Dashboard{} = dashboard, attrs) do
    tags =
      if attrs["monitor_tags"] do
        Monitoring.get_monitor_tags!(attrs["monitor_tags"])
      else
        []
      end

    monitors =
      if attrs["monitors"] do
        Monitoring.get_monitors!(attrs["monitors"])
      else
        []
      end

    dashboard
    |> Dashboard.changeset(attrs)
    |> put_assoc(:monitor_tags, tags)
    |> put_assoc(:monitors, monitors)
    |> Repo.update()
  end

  @doc """
  Deletes a dashboard.

  ## Examples

      iex> delete_dashboard(dashboard)
      {:ok, %Dashboard{}}

      iex> delete_dashboard(dashboard)
      {:error, %Ecto.Changeset{}}

  """
  def delete_dashboard(%Dashboard{} = dashboard) do
    Repo.delete(dashboard)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking dashboard changes.

  ## Examples

      iex> change_dashboard(dashboard)
      %Ecto.Changeset{data: %Dashboard{}}

  """
  def change_dashboard(%Dashboard{} = dashboard, attrs \\ %{}) do
    Dashboard.changeset(dashboard, attrs)
  end
end
