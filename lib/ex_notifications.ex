defmodule ExNotifications do
  @moduledoc """
  This library takes care of ensuring your applicaiton is correctly configured to use [Notifications](https://notifications.geeks.solutions).
  It also expose a set of function to directly send notifications.
  It supports email, webhook, iOs and Android push and web push.
  """

  alias ExGeeks.Helpers, as: GeeksHelpers
  alias ExNotifications.Helpers
  require Logger

  defp send_notification_url do
    "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id()}/send_notification"
  end

  @doc """
  Returns the queued notification object
  """
  @spec get_notification_id(binary()) :: map()
  def get_notification_id(notification_id) do
    GeeksHelpers.endpoint_get_callback(
      "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id()}/notification/#{notification_id}",
      Helpers.header()
    )
  end

  @doc """
  Checks your configuration to ExNotifications is correct.

  You can run this at your application start by adding the following to your children list in your `application.ex`:

  ```elixir
    {Task,
      fn ->
        # Check ExNotifications is correctly configured
        ExNotifications.check_channels()
    end}
  ```

  It will log results to the console and return the result of the verification

  - Returns an error if your `project_id` or `private_key` is incorrect
  - Returns `true` if your local channels configuration exist on your Notifications project
  - Returns `false` if at least one of your local channels configuration does not match any on your Notifications project
  """
  @spec check_channels() :: boolean() | {:error, any()}
  def check_channels do
    case GeeksHelpers.endpoint_get_callback(
           "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id()}/channels",
           Helpers.header()
         ) do
      %{} = data ->
        if Helpers.check_channels(data) do
          Logger.info("Your ExNotifications channels are correctly configured")
        else
          Logger.error("Fix your ExNotifications channels configuration")
        end

      {:error, resp} ->
        Logger.error("ExNotifications misconfiguration: #{resp}")
        {:error, resp}
    end
  end

  @doc """
  Builds a list of channels using a template based on a list of recipients to be used for sending a notification

  Use for `push_web`, `APNS` or `FCM` types.

  Returns a list of maps to use in the `channels` field of the `send/1` function
  """
  @spec build_channels(binary(), list(), integer(), map()) :: list()
  def build_channels(type, to, template_id, tokens)

  def build_channels("push_web", to, template_id, tokens) when is_list(to) do
    Enum.map(to, fn endpoint ->
      %{
        type: "push",
        name: Helpers.web_push_channel(),
        template: %{
          templateId: template_id,
          tokens: tokens
        },
        subscription: endpoint
      }
    end)
  end

  def build_channels("APNS", to, template_id, tokens) when is_list(to) do
    Enum.map(to, fn endpoint ->
      %{
        type: "apns",
        name: Helpers.apns_channel(),
        template: %{
          templateId: template_id,
          tokens: tokens
        },
        device_token: endpoint
      }
    end)
  end

  def build_channels("FCM", to, template_id, tokens) when is_list(to) do
    Enum.map(to, fn endpoint ->
      %{
        type: "fcm",
        name: Helpers.fcm_channel(),
        template: %{
          templateId: template_id,
          tokens: tokens
        },
        device_registration_id: endpoint
      }
    end)
  end

  @doc false
  def build_channels(_, _, _), do: %{}

  @doc """
  A variation of the `builds_channels/4` for `email` notifications

  This version does not rely on the template

  Needs the type (ie email), `subject`, `body`, `to` and an option `from`

  Returns a list of channels with one channel to use in the `send/1` function
  """
  @spec build_channels(binary(), binary(), map(), binary(), binary() | none()) :: list()
  def build_channels("email", subject, body, to, from \\ Helpers.sender_email_address()) do
    [
      %{
        type: "email",
        config: %{
          relays: [
            %{
              weight: 0,
              relay: Helpers.email_channel()
            }
          ],
          from: from
        },
        content: %{
          html_body: body.html,
          subject: subject
        },
        recipients: to
      }
    ]
  end

  @doc """
  Send a notification by specifying all parameters in the body map:
  ```elixir
  %{
    templates: [
      %{templateId: 1, templateContent: "Gm {{name}} {{lastname}}, Welcome!"}
    ],
    channels: [{
      "type": "email",
      "template": {
        "tokens": {
          "name": "Cristiano",
          "lastname: "Ronaldo"
        },
        "templateId": 1
      },
      "recipients": [
        "destination_email_here@gmail.com"
      ],
      "content": {
        "text_body": "Hello World",
        "subject": "welcome email"
      },
      "config": {
        "relays": [
          {
            "weight": 0,
            "relay": "mailgun"
          }
        ],
        "from": "your_email_here@gmail.com"
      }
    },
    {
      "type": "email",
      "recipients": [
        "destination_email_2@gmail.com"
      ],
      "content": {
        "text_body": "Hello World",
        "subject": "welcome email without template",
        "html_body": " Hello world!</h1>"
      },
      "config": {
        "relays": [
          {
            "weight": 0,
            "relay": "mailgun"
          }
        ],
        "from": "your_email_here@gmail.com"
      }
    }]
  }
  ```
  will return:
  - `valid_jobs` map in case all notifications were queued
  - `all_jobs` map, categorized by invalid ones and valid ones if at least one job failed to be queued

  `all_jobs` is the response from the notifications API as is.

  For more information refer to the [API docs](https://notifications.geeks.solutions/docs/frontend/index.html#2-sending-notifications)
  """
  @spec send(map()) :: {:ok, list()} | {:error, map()}
  def send(body) do
    case GeeksHelpers.endpoint_post_callback(send_notification_url(), body, Helpers.header()) do
      %{"invalid_notifications" => [], "valid_jobs" => valid_jobs} when is_list(valid_jobs) ->
        {:ok, valid_jobs}

      %{"invalid_notifications" => [_invalid_jobs]} = resp ->
        {:error, resp}
    end
  end

  @doc """
  Sends a `webhook` notification:

  Returns a tuple similar to `send/1`
  """
  @spec send(binary(), map()) :: {:ok, list()} | {:error, map()}
  def send("webhook", content) do
    build_body("webhook", content)
    |> send()
  end

  @doc """
  Sends a `push_web`, `APNS` or `FCM` notification:

  Provided a type, a content and a recipient

  for `push_web` the recipient should be a map or a list of maps, each map should be in the following format:
  ```elixir
  %{
    "endpoint" => "",
    "keys" => %{
      "auth" => "",
      "p256dh" => ""
    }
  }
  ```

  Returns a tuple similar to `send/1`
  """
  @spec send(binary(), map(), map() | binary()) :: {:ok, list()} | {:error, map()}
  def send(type, content, to) do
    build_body(type, content, to)
    |> send()
  end

  @doc """
  Sends an `email`

  The body is a map with at least the `html` key and optionally the `text` key

  Response is similar to `send/1`
  """
  @spec send(binary(), binary(), map(), binary(), binary()) :: {:ok, list()} | {:error, map()}
  def send("email", subject, %{html: _} = body, to, from \\ Helpers.sender_email_address()) do
    body = build_channels("email", subject, body, to, from)

    send(%{channels: body})
  end

  defp build_body("webhook", content) do
    %{
      channels: [
        %{
          type: "webhook",
          name: Helpers.webhook_channel(),
          payload: content
        }
      ]
    }
  end

  defp build_body("push_web", content, to) when is_list(to) do
    %{
      channels:
        Enum.map(to, fn endpoint ->
          %{
            type: "push",
            name: Helpers.web_push_channel(),
            content: content,
            subscription: endpoint
          }
        end)
    }
  end

  defp build_body("push_web", content, to) do
    %{
      channels: [
        %{
          type: "push",
          name: Helpers.web_push_channel(),
          content: content,
          subscription: to
        }
      ]
    }
  end

  defp build_body("APNS", content, to) do
    %{
      channels: [
        %{
          type: "apns",
          name: Helpers.apns_channel(),
          content: content,
          device_token: to
        }
      ]
    }
  end

  defp build_body("FCM", content, to) do
    %{
      channels: [
        %{
          type: "fcm",
          name: Helpers.fcm_channel(),
          content: content,
          device_registration_id: to
        }
      ]
    }
  end
end
