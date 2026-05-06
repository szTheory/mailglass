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
      elixirc_options: elixirc_options(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "MailglassInbound",
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      mod: {MailglassInbound.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      test: [&configure_test_swoosh/1, "test"]
    ]
  end

  defp configure_test_swoosh(_args) do
    Application.put_env(:swoosh, :api_client, false, persistent: true)
  end

  defp elixirc_options do
    [no_warn_undefined: [Oban, Oban.Job, Oban.Worker]]
  end

  defp deps do
    [
      mailglass_dep(),
      {:ecto_sql, "~> 3.13"},
      {:nimble_options, "~> 1.1"},
      {:oban, "~> 2.21", optional: true},
      {:uuidv7, "~> 1.0"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "== 0.3.2"}
    else
      {:mailglass, path: "..", override: true}
    end
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
      files: ~w(lib docs priv .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "MailglassInbound",
      source_url: @source_url,
      source_ref: "v" <> @version,
      extras: [
        "README.md",
        "docs/api_stability.md",
        "docs/postmark_ingress.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Contract: ["docs/api_stability.md"],
        Guides: ["docs/postmark_ingress.md"]
      ],
      groups_for_modules: [
        Stable: [
          MailglassInbound,
          MailglassInbound.InboundMessage,
          MailglassInbound.Ingress.CachingBodyReader,
          MailglassInbound.Ingress.Plug,
          MailglassInbound.Router,
          MailglassInbound.Mailbox
        ],
        Internal: [MailglassInbound.OptionalDeps]
      ]
    ]
  end
end
