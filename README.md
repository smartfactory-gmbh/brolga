<p align="center">
    <img src="https://github.com/smartfactory-gmbh/brolga/assets/22151261/8e13d6c8-e01b-4016-a17f-0a10b56532e3" />
</p>

# Brolga


Brolga is a monitoring tool that allows you to setup multiple http(s) endpoints and an interval at which they will get tested by a simple GET request.

Named after the Australian bird known for its alertness and watchfulness, Brolga ensures that your online services stay up and running smoothly.

## Key Features

- **Easy Setup and Management**: Brolga simplifies the process of setting up and managing monitors for your http(s) endpoints.
- **Real-time Monitoring**: The user-friendly web-based UI allows you to track the status of all your monitors, providing you with real-time updates on their performance.
- **Dashboard**: The dashboard provides an overview of your monitors' health, helping you quickly identify potential issues and take necessary actions.
- **Smart Notifications**: Brolga offers proactive monitoring by notifying you through Slack and SMTP when any of your monitors experience downtime or are restored to normal operation.

## Getting started

A good starting point is to reuse the example docker-compose file of
this repository.

Just copy the `docker-compose.example.yml` file as `docker-compose.yml`
where you would like to deploy it, **CHANGE THE SECRET KEY**, and run it with

```shell
docker-compose up -d
```

It will serve it on port 4000. The admin GUI is located on `/monitors`

**Note**: The key has to be at least 64 bytes long.


### Available settings
These are the settings you can modify with environment variables (i.e. by putting them in the `environment` key in the compose file)

#### General

| Variable                       | Default value | Notes                                                                        |
| ------------------------------ | ------------- | ---------------------------------------------------------------------------- |
| `SECRET_KEY_BASE`              | -             | (required) Random string of at least 64 bytes length                         |
| `REDIS_HOST`                   | `localhost`   | Host of the Redis DB                                                         |
| `REDIS_PORT`                   | `6379`        | Port to use with the Redis connection                                        |
| `REDIS_USER`                   | -             | Username to use with the Redis connection                                    |
| `REDIS_PASSWORD`               | -             | Password to use with the Redis connection                                    |
| `DEFAULT_TZ`                   | `Etc/UTC`     | The default timezone to use for datetime displays                            |
| `UPTIME_LOOKBACK_DAYS`         | `30`          | The number of days to take in account when calculating the uptime percentage |
| `ATTEMPTS_BEFORE_NOTIFICATION` | `1`           | Number of failed hit to get in order to trigger a notification               |
| `DATABASE_URL`                 | -             | (required) Currently only works with postgres                                |

#### Notifiers configuration

| Variable                     | Default value      | Notes                                                                                |
| ---------------------------- | ------------------ | ------------------------------------------------------------------------------------ |
| `EMAIL_NOTIFIER_ENABLED`     | `false`            | Whether the SMTP notifier should be enabled or not                                   |
| `EMAIL_NOTIFIER_FROM_NAME`   | -                  | (required if enabled)  The "From" user name that will be displayed on sent emails    |
| `EMAIL_NOTIFIER_FROM_EMAIL`  | `test@example.com` | (required if enabled) The "From" email address that will be displayed on sent emails |
| `SLACK_NOTIFIER_ENABLED`     | `false`            | Whether the Slack notifier should be enabled or not                                  |
| `SLACK_NOTIFIER_WEBHOOK_URL` | -                  | (required if enabled) The webhook url for your Slack app                             |
| `SLACK_NOTIFIER_USERNAME`    | -                  | The username to use for display (falls back to your app config)                      |
| `SLACK_NOTIFIER_CHANNEL`     | -                  | The channel to send the message to (falls back to your app config)                   |

#### Email configuration

As of now, you can either use SMTP to setup your email configuration, or use Postmark. Please use only one method with the env variables below

| Variable                  | Default value | Notes                                                                |
| ------------------------- | ------------- | -------------------------------------------------------------------- |
| `SMTP_HOST`               | -             | (required if using SMTP) The host to use for SMTP communication      |
| `SMTP_PORT`               | `1025`        | The port to use for SMTP communication                               |
| `SMTP_USERNAME`           | -             | (required if using SMTP) The username to use for SMTP communication  |
| `SMTP_PASSWORD`           | -             | (required if using SMTP) The password to use for SMTP  communication |
| `SMTP_SSL`                | `"true"`      | Whether or not the SMTP connection should use SSL                    |
| `SMTP_TLS`                | `"true"`      | Whether or not the SMTP connection should use TLS                    |
| `POSTMARK_API_KEY`        | -             | (required if using Postmark) The API key provided by Postmark        |
| `POSTMARK_MESSAGE_STREAM` | -             | The message stream to be used in Postmark                            |

### Security considerations

As of the writing of this README, there is no user auth system setup yet.
In the case you would like to use it still, we can only recommend you to run
it behind a proxy (typically Nginx) and add a basic auth there for instance.

In this case, you can remove the port mapping in the example compose file,
assuming you added the proxy in the compose file it will be able to access it
anyways.

## Contribute

1. Fork this project
2. Make your changes
    - Make sure that your commits are following the [conventional commits guidelines](https://www.conventionalcommits.org/en/v1.0.0/)
    - There are pre-commit hooks that will ensure that the code is correctly formatted
3. Open a pull request against the main branch and make sure the following points are covered:
    - Are the changes documented?
    - Are the changes covered by the tests?

### Local setup

In order to make your changes, you have to get the application up and running. Here is how to do so:

1. Startup the dev database/redis: `docker-compose -f docker-compose.dev.yml up -d`
2. Run the migrations: `mix ecto.migrate`
3. Seed the database: `mix run apps/brolga/priv/repo/seeds.exs`
3. Run `iex -S mix phx.server`, `mix phx.server` or through your IDE if supported
