defmodule ExNotifications.Helpers do
  @moduledoc false

  require Logger

  def env(key, opts \\ %{default: nil, raise: false}) do
    Application.get_env(:ex_notifications, key)
    |> case do
      nil ->
        if opts |> Map.get(:raise, false),
          do: raise("Please configure :#{key} to use ex_notifications as desired,
          i.e:
          config, :ex_notifications,
            #{key}: VALUE_HERE "),
          else: opts |> Map.get(:default)

      value ->
        value
    end
  end

  def private_key do
    env(:private_key, %{raise: true})
  end

  def project_id do
    env(:project_id, %{raise: true})
  end

  def endpoint do
    env(:endpoint, %{raise: false, default: "https://notifications.geeks.solutions"})
  end

  def sender_email_address do
    env(:sender_email_address, %{raise: false})
  end

  def email_channel do
    env(:email_channel, %{raise: false})
  end

  def fcm_channel do
    env(:fcm_channel, %{raise: false})
  end

  def apns_channel do
    env(:apns_channel, %{raise: false})
  end

  def web_push_channel do
    env(:web_push_channel, %{raise: false})
  end

  def webhook_channel do
    env(:webhook_channel, %{raise: false})
  end

  def header do
    [
      pkey: private_key(),
      "Content-Type": "application/json"
    ]
  end

  def check_channels(configured_channels) do
    Map.keys(configured_channels)
    |> Enum.all?(fn
      "apns" ->
        Map.get(configured_channels, "apns")
        |> check_channel(apns_channel())
      "email" ->
        Map.get(configured_channels, "email")
        |> check_channel(email_channel())
      "fcm" ->
        Map.get(configured_channels, "fcm")
        |> check_channel(fcm_channel())
      "push" ->
        Map.get(configured_channels, "push")
        |> check_channel(web_push_channel())
      "webhook" ->
        Map.get(configured_channels, "webhook")
        |> check_channel(webhook_channel())
      _any ->
        true
    end)
  end

  defp check_channel(configured_channel, local_config) when is_binary(local_config) and is_map(configured_channel) do
    if Map.has_key?(configured_channel, local_config) do
      true
    else
      Logger.error("ExNotifications: #{local_config} is not configured on your Notifications project")
      false
    end
  end

  defp check_channel(_, local_config) when is_nil(local_config), do: true
  defp check_channel(_, local_config) do
    Logger.error("ExNotifications: #{local_config} is not configured on your Notifications project")
    false
  end
end
