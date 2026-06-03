defmodule MailglassInbound.MixProject do
  use Mix.Project

  @version "1.1.1"
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

  def cli do
    [
      preferred_envs: [
        "verify.support_contract.inbound": :test,
        "verify.stability_contract": :test
      ]
    ]
  end

  defp aliases do
    [
      test: [&configure_test_swoosh/1, "test"],
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
    # `Mailglass.Oban.TenancyMiddleware` is a cross-package reference from
    # execution/worker.ex. It is runtime-safe — both the call site and the whole
    # worker module sit inside `Code.ensure_loaded?/1` gates — but static xref
    # cannot resolve it under `mix compile --no-optional-deps`, where Oban is
    # stripped from both inbound's dep and the path-dep core (eliding the core
    # module). Suppressing it here (project-level, so it takes effect even while
    # the gated module body is elided) mirrors core mix.exs's own no_warn_undefined
    # entry for the same module and keeps the inbound `--no-optional-deps
    # --warnings-as-errors` lane green. List kept tight: only modules actually
    # referenced from inbound code (do NOT add Mailglass.Outbound.Worker — no
    # inbound reference exists).
    [no_warn_undefined: [Oban, Oban.Job, Oban.Worker, Mailglass.Oban.TenancyMiddleware]]
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
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "== 1.4.2"}
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
