defmodule MailglassInbound.MixProject do
  use Mix.Project

  @version "2.3.0"
  @source_url "https://github.com/szTheory/mailglass"
  @description "Inbound routing contract package for mailglass"
  # Release-As path anchor (137-02, D-04): this mailglass_inbound/ subtree touch
  # attributes the companion commit's SEPARATE `Release-As: 2.0.0` footer to the
  # standalone mailglass_inbound package (its own breaking changes from Phase 135),
  # so RP cuts inbound 2.0.0 rather than the 1.7.0 minor it would otherwise score.

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
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
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
      # :inets/:ssl back the SES SigningCertURL fetch (`:httpc` GET over HTTPS in
      # ingress/providers/ses.ex). Declared explicitly rather than relying on a
      # transitive load (core's Igniter chain provided :inets before it became
      # an optional dep).
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  def cli do
    [
      preferred_envs: [
        ci: :test,
        "ci.fast": :test,
        "verify.support_contract.inbound": :test,
        "verify.stability_contract": :test
      ]
    ]
  end

  defp aliases do
    [
      test: [&configure_test_swoosh/1, "test"],
      # Sibling-local ci verb (uniform across packages). The inbound test step
      # is `test --exclude property` with NO seed pin — Phase 127 (DET-02) made
      # the suite deterministic via serial MailboxCase; a seed pin regresses it.
      "ci.fast": [
        "format --check-formatted",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      ci: [
        "ci.fast",
        "verify.support_contract.inbound",
        "test --exclude property"
      ],
      "verify.docs.contract.inbound": [
        "test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"
      ],
      "verify.support_contract.inbound": [
        "test test/mailglass_inbound/docs_contract_test.exs test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors"
      ],
      "verify.stability_contract": ["verify.support_contract.inbound"]
    ]
  end

  defp configure_test_swoosh(_args) do
    Application.put_env(:swoosh, :api_client, false, persistent: true)
  end

  defp elixirc_options do
    [no_warn_undefined: [Oban, Oban.Job, Oban.Worker]]
  end

  defp dialyzer do
    [
      flags: [:error_handling, :missing_return, :no_opaque, :no_match, :underspecs],
      ignore_file_strict: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      plt_add_apps: [:ex_unit, :mix],
      plt_file: {:no_warn, "_build/dialyxir/mailglass_inbound.plt"}
    ]
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
      # All access goes through the inbound MailglassInbound.OptionalDeps.GenSmtp gateway, so
      # it is NOT added to elixirc_options no_warn_undefined here (no bare references
      # in inbound code). Pinned to the vetted 1.3.0 core lockfile resolution.
      {:gen_smtp, "~> 1.3", optional: true},
      # `ex_aws`/`ex_aws_s3` (D-46-15, D-46-20): the FIRST new optional runtime
      # deps since the v1.0 STACK lock. Used only by the SES inbound provider's
      # real S3 fetcher (`MailglassInbound.S3Fetcher.ExAwsS3`); the fake-first
      # test default (`S3Fetcher.Fake`) needs neither. All `ExAws`/`ExAws.S3`
      # access flows through the `MailglassInbound.OptionalDeps.ExAwsS3` gateway,
      # whose own `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` covers the
      # references — so (like gen_smtp above) they are NOT added to the
      # project-level `no_warn_undefined` list. Adopters also wire `:sweet_xml`,
      # an HTTP client, and AWS creds themselves (Phase 50 setup guide).
      {:ex_aws, "~> 2.7", optional: true},
      {:ex_aws_s3, "~> 2.5", optional: true},
      # StreamData backs the TELE-08 1000-run inbound convergence property
      # (test/mailglass_inbound/properties/). Test-only; mirrors core's 1.3 pin.
      {:stream_data, "~> 1.3", only: [:test]},
      {:excoveralls, "~> 0.18", only: [:test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  # Published builds constrain to the core 2.0 release line. The v1.15 loosened-`~>`
  # keystone stays: this is a pessimistic `~> 2.0` pin, NOT an `== X.Y.Z` re-pin.
  # The old `and >= 1.10.2` floor only ever excluded the broken 1.10.0/1.10.1 core
  # builds; there is no analog on the fresh 2.0 line, so it is dropped (D-05).
  #
  # A new core MINOR (2.1.0) is where internal contracts (Mailglass.Outbound.*,
  # events table, Error hierarchy) may shift. Inbound adopters can upgrade patch
  # releases freely; each minor line requires a deliberate `fix(inbound):`
  # floor-bump asserting "verified against core 2.1." Do NOT speculatively widen
  # to `~> 2.0 or ~> 2.1` — the minor boundary is a meaningful contract gate.
  #
  # Dev/test resolves the sibling via the local path dep (else-branch, untouched).
  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "~> 2.0"}
    else
      {:mailglass, path: "..", override: true}
    end
  end

  defp package do
    [
      name: "mailglass_inbound",
      licenses: ["MIT"],
      description: @description,
      source_ref_pattern: "mailglass_inbound-v%{version}",
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/mailglass_inbound"
      },
      files: ~w(lib docs .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "MailglassInbound",
      source_url: @source_url,
      source_ref: "v" <> @version,
      logo: "../brandbook/assets/logo-mark.svg",
      favicon: "../brandbook/assets/favicon.svg",
      extras: [
        "README.md",
        "docs/api_stability.md",
        "docs/postmark_ingress.md",
        "docs/sendgrid_ingress.md",
        "docs/inbound-install.md",
        "docs/inbound-testing.md",
        "docs/inbound-operator.md",
        "docs/inbound-mailgun.md",
        "docs/inbound-ses.md",
        "docs/inbound-routing-debug.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Contract: ["docs/api_stability.md"],
        Guides: ["docs/postmark_ingress.md", "docs/sendgrid_ingress.md"],
        "Inbound Guides": [
          "docs/inbound-install.md",
          "docs/inbound-testing.md",
          "docs/inbound-operator.md",
          "docs/inbound-mailgun.md",
          "docs/inbound-ses.md",
          "docs/inbound-routing-debug.md"
        ]
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
        Testing: [
          MailglassInbound.TestAssertions,
          MailglassInbound.MailboxCase,
          MailglassInbound.Test.Ingress,
          MailglassInbound.Fixtures
        ],
        Internal: [MailglassInbound.OptionalDeps]
      ]
    ]
  end
end
