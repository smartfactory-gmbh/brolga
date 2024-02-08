defmodule Brolga.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Brolga.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Brolga.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Brolga.DataCase
    end
  end

  setup tags do
    Brolga.DataCase.setup_sandbox(tags)
    :ok
  end

  setup do
    Application.put_env(:brolga, :slack_notifier,
      enabled: true,
      webhook_url: "http://localhost:7777",
      username: "slack_user",
      channel: "#slack_channel"
    )

    {
      :ok,
      slack_bypass: Bypass.open(port: 7777)
    }
  end

  setup do
    {
      :ok,
      target_bypass: Bypass.open(port: 8888)
    }
  end

  @doc """
  Make sure that the scheduler canceled all timers that may have been setup in test cases 
  Is always set as a cleanup method when Brolga.DataCase is used
  """
  @spec stop_scheduled_timers(term()) :: :ok
  def stop_scheduled_timers(_context \\ %{}) do
    on_exit(&Brolga.Scheduler.stop_all/0)
  end

  setup :stop_scheduled_timers

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Brolga.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
