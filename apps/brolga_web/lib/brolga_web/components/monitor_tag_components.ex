defmodule BrolgaWeb.MonitorTagComponents do
  @moduledoc """
  Provides UI components specific to monitor tags
  """
  use Phoenix.Component
  alias Brolga.Monitoring.{MonitorTag}

  attr :tag, MonitorTag, required: true

  defp tag_badge(assigns) do
    ~H"""
    <div class="rounded-lg px-2 py-1 bg-blue-500 text-white italic">
      <%= @tag.name %>
    </div>
    """
  end

  attr :tags, :list, required: true

  def tags(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.tag_badge :for={tag <- @tags} tag={tag} />
    </div>
    """
  end
end
