defmodule Brolga.CustomSql do
  @moduledoc """
  Add some utility macros that you can use when setting up your queries
  """

  defmacro case_when(condition, then, otherwise) do
    quote do
      fragment(
        """
        CASE WHEN ? THEN ?
          ELSE ?
        END
        """,
        unquote(condition),
        unquote(then),
        unquote(otherwise)
      )
    end
  end
end
