defmodule ExNotifications.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_notifications,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "ExNotifications",
      source_url: "https://github.com/Geeks-Solutions/ex_notifications",
      homepage_url: "https://notifications.geeks.solutions",
      docs: [
        main: "ExNotifications",
        logo: "notifications_logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_geeks,
       git: "https://github.com/Geeks-Solutions/ex_geeks",
       ref: "a591f05fb7b37618590bf76bf45057d9780fa2c4"}
    ]
  end
end
