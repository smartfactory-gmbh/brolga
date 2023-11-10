defmodule BrolgaWeb.MonitorTagLive.FormComponent do
  use BrolgaWeb, :live_component

  alias Brolga.Monitoring

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage monitor tags in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="monitor_tag-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input label="Name" field={@form[:name]} />

        <:actions>
          <.button phx-disable-with="Saving...">Save Monitor tag</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{monitor_tag: monitor_tag} = assigns, socket) do
    changeset = Monitoring.change_monitor_tag(monitor_tag)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"monitor_tag" => monitor_tag_params}, socket) do
    changeset =
      socket.assigns.monitor_tag
      |> Monitoring.change_monitor_tag(monitor_tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"monitor_tag" => monitor_tag_params}, socket) do
    save_monitor_tag(socket, socket.assigns.action, monitor_tag_params)
  end

  defp save_monitor_tag(socket, :edit, monitor_tag_params) do
    case Monitoring.update_monitor_tag(socket.assigns.monitor_tag, monitor_tag_params) do
      {:ok, monitor_tag} ->
        notify_parent({:saved, monitor_tag})

        {:noreply,
         socket
         |> put_flash(:info, "Monitor tag updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_monitor_tag(socket, :new, monitor_tag_params) do
    case Monitoring.create_monitor_tag(monitor_tag_params) do
      {:ok, monitor_tag} ->
        notify_parent({:saved, monitor_tag})

        {:noreply,
         socket
         |> put_flash(:info, "Monitor tag created successfully")
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
