defmodule Brolga.AlertNotifiers.SlackNotifier do
  @moduledoc false

  alias Brolga.Alerting.Incident
  use Timex

  @headers [{"Accept", "application/json"}]

  @error_color "#DF3617"
  @success_color "#2EB886"

  defp get_config do
    Application.get_env(:brolga, :slack_notifier)
  end

  def enabled? do
    get_config()[:enabled] == true
  end

  @spec new_incident(Incident.t()) :: :ok | :error
  def new_incident(incident) do
    incident_timestamp = incident.started_at |> Timex.to_unix()

    send(%{
      icon_emoji: ":x:",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "An incident occurred"
          }
        }
      ],
      attachments: [
        %{
          color: @error_color,
          blocks: [
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text:
                  "The monitor *#{incident.monitor.name}* failed to reach the host at url #{incident.monitor.url}"
              }
            },
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text:
                  "Time of alert: <!date^#{incident_timestamp}^{date_short} {time_secs}|#{DateTime.to_string(incident.started_at)}>"
              }
            }
          ]
        }
      ]
    })
  end

  @spec incident_resolved(Incident.t()) :: :ok | :error
  def incident_resolved(incident) do
    incident_start_timestamp = incident.started_at |> Timex.to_unix()
    incident_end_timestamp = incident.ended_at |> Timex.to_unix()

    elapsed = Incident.formatted_duration(incident)

    send(%{
      icon_emoji: ":white_check_mark:",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "An incident has been resolved"
          }
        }
      ],
      attachments: [
        %{
          color: @success_color,
          blocks: [
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text:
                  "The monitor *#{incident.monitor.name}* can reach again the host at url #{incident.monitor.url}"
              }
            },
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text:
                  "Time of alert: <!date^#{incident_start_timestamp}^{date_short} {time_secs}|#{DateTime.to_string(incident.started_at)}>"
              }
            },
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text:
                  "Time of resolution: <!date^#{incident_end_timestamp}^{date_short} {time_secs}|#{DateTime.to_string(incident.ended_at)}>"
              }
            },
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text: "Downtime duration: #{elapsed}"
              }
            }
          ]
        }
      ]
    })
  end

  @spec test_notification() :: :ok | :error
  def test_notification() do
    send(%{
      icon_emoji: ":construction:",
      text: "Test notification",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "This is a test notification"
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "If you see this message in Slack, it's working well :smile:"
          }
        }
      ]
    })
  end

  defp send(data) do
    config = get_config()
    username = config[:username]
    channel = config[:channel]
    webhook_url = config[:webhook_url]

    case webhook_url do
      nil ->
        :error

      url ->
        encoded_data =
          data |> Map.merge(%{username: username, channel: channel})

        make_request(url, encoded_data)
    end
  end

  defp make_request(url, encoded_data) do
    req =
      Req.new(
        url: url,
        headers: @headers,
        json: encoded_data
      )

    case Req.post(req) do
      {:ok, response} ->
        if response.status in 200..299 do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end
end
