defmodule BrolgaCron.Task do
  @moduledoc false

  @enforce_keys [:id, :interval_in_seconds, :action]
  defstruct [
    :id,
    :interval_in_seconds,
    :action,
    args: []
  ]

  @type t :: %__MODULE__{
          id: atom(),
          interval_in_seconds: non_neg_integer(),
          action: (... -> any),
          args: list()
        }
end
