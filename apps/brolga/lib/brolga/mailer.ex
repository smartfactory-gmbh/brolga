defmodule Brolga.Mailer do
  @moduledoc false
  use Swoosh.Mailer, otp_app: :brolga
  import Swoosh.Email

  @default_provider_options []

  defp get_provider_options() do
    Keyword.get(
      Application.get_env(:brolga, __MODULE__),
      :provider_options,
      @default_provider_options
    )
  end

  @spec new() :: Swoosh.Email.t()
  def new() do
    email =
      Enum.reduce(
        get_provider_options(),
        Swoosh.Email.new(),
        fn {key, val}, acc -> put_provider_option(acc, key, val) end
      )

    email
  end
end
