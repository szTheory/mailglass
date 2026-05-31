defmodule MailglassReferenceHost.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :mailglass_reference_host,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {MailglassReferenceHost.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:mailglass, "~> 1.3"},
      {:mailglass_admin, "~> 1.3"},
      {:mailglass_inbound, "~> 0.3"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"]
    ]
  end
end
