defmodule Tempo.MixProject do
  use Mix.Project

  def project do
    [
      app: :tempo,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [
        summary: [threshold: 90],
        ignore_modules: [
          Tempo.MqClient,
          Tempo.MqWsClient,
          Tempo.Sources.Augment,
          TempoWeb,
          TempoWeb.Endpoint
        ]
      ],
      name: "Tempo",
      description: "Openclaw AI Tempo Agent - Multi-source AI tool analytics"
    ]
  end

  def application do
    [
      mod: {Tempo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.18"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.6"},
      {:cors_plug, "~> 3.0"},
      {:req, "~> 0.5"},
      {:websockex, "~> 0.5"},
      {:nimble_csv, "~> 1.2"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "assets.setup": [],
      "assets.build": [],
      "assets.deploy": []
    ]
  end
end
