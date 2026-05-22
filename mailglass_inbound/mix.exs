defmodule MailglassInbound.MixProject do
  use Mix.Project

  @version "0.1.0"
  # First Hex publish — see Phase 044.5 release ceremony record
  @source_url "https://github.com/szTheory/mailglass"
  @description "Inbound routing contract package for mailglass"

  def project do
    [
      app: :mailglass_inbound,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  # `test/support` carries MailglassInbound.TestRepo (the Postgres-backed test
  # repo) so it must compile in the :test env. Mirror core mix.exs.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      mailglass_dep(),
      {:ecto_sql, "~> 3.13"},
      {:nimble_options, "~> 1.1"},
      {:oban, "~> 2.21", optional: true},
      {:uuidv7, "~> 1.0"},
      # `:mimemail` (from gen_smtp) is exercised by the real MIME parser in Plan 03.
      # All access goes through the core Mailglass.OptionalDeps.GenSmtp gateway, so
      # it is NOT added to elixirc_options no_warn_undefined here (no bare references
      # in inbound code). Pinned to the vetted 1.3.0 core lockfile resolution.
      {:gen_smtp, "~> 1.3", optional: true},
      # StreamData backs the TELE-08 1000-run inbound convergence property
      # (test/mailglass_inbound/properties/). Test-only; mirrors core's 1.3 pin.
      {:stream_data, "~> 1.3", only: [:test]},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "== 1.0.0"}
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
        "docs/postmark_ingress.md",
        "docs/sendgrid_ingress.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Contract: ["docs/api_stability.md"],
        Guides: ["docs/postmark_ingress.md", "docs/sendgrid_ingress.md"]
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
