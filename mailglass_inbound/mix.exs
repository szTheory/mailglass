defmodule MailglassInbound.MixProject do
  use Mix.Project

  @version "0.3.2"
  @source_url "https://github.com/szTheory/mailglass"
  @description "Inbound routing contract package for mailglass"

  def project do
    [
      app: :mailglass_inbound,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "MailglassInbound",
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.13"},
      {:nimble_options, "~> 1.1"},
      {:uuidv7, "~> 1.0"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "mailglass_inbound",
      licenses: ["MIT"],
      description: @description,
      source_ref_pattern: "mailglass-sibling-group-v%{version}",
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/mailglass_inbound"
      },
      files: ~w(lib mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "MailglassInbound",
      source_url: @source_url,
      source_ref: "v" <> @version
    ]
  end
end
