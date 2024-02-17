# Overview

This library helps you connect to the [Notifications SaaS application](https://notifications/geeks.solutions) to offload your application from 
handling queues for all your notifications needs.
By sending your messages through notification you benefit from:
- A retry on failure
- Multiple preconfigured relays that will be tried one after the other to deliver your messages
- A full logs of all the notifications sent

The SaaS Application can support various notification types:
- Email
- Webhook
- Mobile Push (iOs and Android)
- Web Push
- SMS

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_notifications` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_notifications, "~> 0.1.0"}
  ]
end
```

If you want to benefit from a verification routine on your application start, you can add the following children to your start/2 callback of your Application.ex

```elixir
  {Task,
    fn ->
      # Check ExNotifications is correctly configured
      ExNotifications.check_channels()
  end}
```

## Configuration

You need to provide a set of configurations for ex_notifications to run correctly, in your config.exs (or {env}.exs)
add the following
```elixir
config, :ex_notifications,
  project_id: {your_project_id},
  private_key: {your_private_key},
  sender_email_address: "test@geeks.solutions",
  email_channel: "mailgun"
```

### Required configs
To properly run this deps you need to provide the following configurations:
- `project_id`: Your Notifications project id that you collect after opening a new project on https://notifications.geeks.solutions
- `private_key`: The private key associated to your notifications project

### App dependent configs
The following configs are optional, but may be required by your own application (ie email related config are required to properly send emails):
- `sender_email_address`: The sender email address to use when using notifications as an email relay
- `email_channel`: The name of the channel you configured on your Notifications project to relay emails
- `fcm_channel`: The name of the channel you configured on your Notifications project to relay FCM push notifications
- `apns_channel`: The name of the channel you configured on your Notifications project to relay APNS push notifications
- `web_push_channel`: The name of the channel you configured on your Notifications project to relay Web push notifications
- `webhook_channel`: The name of the channel you configured on your Notifications project to relay webhooks

### Dev config
For development purpose you can also use the following config:
- `endpoint`: By default this points to the production url of notifications, you can change this URL to point to another environment
