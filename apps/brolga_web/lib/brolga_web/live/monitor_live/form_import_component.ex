defmodule BrolgaWeb.MonitorLive.FormImportComponent do
  use BrolgaWeb, :live_component

  alias Brolga.Monitoring
  import BrolgaWeb.MonitorComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to import monitor records in your database.</:subtitle>
      </.header>

      <form
        id="monitor-import-form"
        class="flex flex-col gap-y-4 py-4 items-start"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <section
          class="border border-white w-full rounded p-8"
          phx-drop-target={@uploads.import_file.ref}
        >
          <.live_file_input class="hidden" upload={@uploads.import_file} />
          <ul>
            <%= for entry <- @uploads.import_file.entries do %>
              <li>
                <%= entry.client_name %>
              </li>
            <% end %>
          </ul>
        </section>
        <.button phx-disable-with="Saving...">Import</.button>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:import_uploads, [])
      |> allow_upload(:import_file, accept: ~w(.json), max_entries: 1)
    }
  end

  @impl true
  def handle_event("validate", _params, socket) do
    IO.puts("Validate")
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    monitors =
      consume_uploaded_entries(socket, :import_file, fn %{path: path}, entry ->
        {:ok, path |> File.read!() |> Jason.decode!(keys: :atoms!)}
      end)
      |> List.flatten()

    socket = socket |> save_monitors(monitors)

    {:noreply, socket}
  end

  defp save_monitors(socket, monitors) do
    monitors =
      monitors
      |> Enum.map(fn monitor ->
        %{inserted_at: inserted_at, updated_at: updated_at} = monitor
        {:ok, inserted_at} = inserted_at |> NaiveDateTime.from_iso8601()
        {:ok, updated_at} = updated_at |> NaiveDateTime.from_iso8601()
        %{monitor | inserted_at: inserted_at, updated_at: updated_at}
      end)

    Monitoring.bulk_create_monitors(monitors)

    socket
    |> put_flash(:info, "File was imported")
    |> push_patch(to: ~p"/admin/monitors/")
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
