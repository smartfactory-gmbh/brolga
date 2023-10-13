defmodule Brolga.Watcher.Redix.RedixBehaviour do
  @moduledoc """
  Simple behaviour made primarily to allow easy mocking for unit tests
  This allows to define any caching system, but is solely used for Redix
  """

  @callback store!(key :: String.t(), value :: String.t()) :: Redix.Protocol.redis_value()
  @callback get!(key :: String.t()) :: Redix.Protocol.redis_value()
end
