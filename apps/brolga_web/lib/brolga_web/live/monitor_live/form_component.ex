defmodule BrolgaWeb.MonitorLive.FormComponent do
  use BrolgaWeb, :live_component

  alias Brolga.Monitoring
  import BrolgaWeb.MonitorComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage monitor records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="monitor-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:interval_in_minutes]} type="number" label="Interval in minutes" />
        <.input field={@form[:timeout_in_seconds]} type="number" label="Timeout in seconds" />
        <.input field={@form[:active]} type="checkbox" label="Active?" />
        <.monitor_tags_select
          field={@form[:monitor_tags]}
          label="Tags"
          multiple={true}
          value={@form.data.id && pluck_ids(@form.data.monitor_tags)}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Monitor</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{monitor: monitor} = assigns, socket) do
    changeset = Monitoring.change_monitor(monitor)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"monitor" => monitor_params}, socket) do
    changeset =
      socket.assigns.monitor
      |> Monitoring.change_monitor(monitor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"monitor" => monitor_params}, socket) do
    save_monitor(socket, socket.assigns.action, monitor_params)
  end

  defp save_monitor(socket, :edit, monitor_params) do
    case Monitoring.update_monitor(socket.assigns.monitor, monitor_params) do
      {:ok, monitor} ->
        notify_parent({:saved, monitor})

        {:noreply,
         socket
         |> put_flash(:info, "Monitor updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_monitor(socket, :new, monitor_params) do
    case Monitoring.create_monitor(monitor_params) do
      {:ok, monitor} ->
        notify_parent({:saved, monitor})

        {:noreply,
         socket
         |> put_flash(:info, "Monitor created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
