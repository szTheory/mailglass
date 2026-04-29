defmodule Mailglass.MixProject do
  use Mix.Project

  @version "0.3.2"
  @source_url "https://github.com/szTheory/mailglass"

  def project do
    [
      app: :mailglass,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      compilers: [:boundary | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      name: "Mailglass",
      description: "Transactional email framework for Phoenix. Composes on Swoosh",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :public_key],
      mod: {Mailglass.Application, []}
    ]
  end

  # Elixir 1.18+ no longer auto-promotes :test for `mix test` invocations
  # nested inside aliases. Every composite verify.* alias must declare its
  # preferred env here, otherwise `mix verify.phase_07` (and friends) raise
  # the `set MIX_ENV explicitly` error before any sub-task runs.
  #
  # REL-03: Both semantic names (verify.foundation etc.) and deprecated
  # pass-throughs (verify.phase_NN) are listed for one cycle.
  def cli do
    [
      preferred_envs: [
        # Semantic aliases (REL-03)
        "verify.foundation": :test,
        "verify.persistence": :test,
        "verify.send_pipeline": :test,
        "verify.webhooks": :test,
        "verify.installer": :test,
        # Deprecated pass-throughs — remove after one release cycle
        "verify.phase01": :test,
        "verify.phase_01": :test,
        "verify.phase_02": :test,
        "verify.phase_03": :test,
        "verify.phase_04": :test,
        "verify.phase_07": :test,
        "verify.cold_start": :test,
        "verify.installer.golden": :test,
        "verify.installer.idempotency": :test,
        "verify.installer.smoke": :test,
        "verify.docs.contract": :test,
        "verify.docs.migration": :test
      ]
    ]
  end

  defp dialyzer do
    [
      # D-08-01: :no_opaque + :no_match kill the Elixir 1.18 opaque-type
      # cascade (elixir-lang/elixir#14837). :error_handling, :missing_return,
      # :underspecs improve coverage; revisit removing :underspecs after the
      # <=15-entry baseline is hit (D-08-07).
      flags: [:error_handling, :missing_return, :no_opaque, :no_match, :underspecs],
      # D-08-03: ignore_file_strict pins to {file, short_description} tuples
      # (stable across line-number drift). D-08-04: list_unused_filters fails
      # CI loudly when a future fix invalidates an existing ignore (prevents
      # silent drift).
      ignore_file_strict: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      # Add :credo and :mix to PLT so dev-only modules don't produce
      # callback_info_missing + unknown_function warnings. credo is a :dev/:test
      # dep; without :credo in the PLT, the 13 custom check files each generate
      # ~11 dialyzer warnings. Mix.Task behaviour is similarly dev-only.
      plt_add_apps: [:credo, :mix, :ex_unit]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "credo_checks"]
  defp elixirc_paths(:test), do: ["lib", "credo_checks", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # CORE-06: suppress optional-dep compile warnings so `mix compile --no-optional-deps`
  # passes cleanly. Each gateway module in Mailglass.OptionalDeps.* declares its own
  # @compile {:no_warn_undefined, ...} for module-level granularity; this list covers
  # the project-wide surface so bare references (e.g. in type specs) don't warn.
  defp elixirc_options do
    [
      no_warn_undefined: [
        Oban,
        Oban.Worker,
        Oban.Job,
        Oban.Migrations,
        Mailglass.Oban.TenancyMiddleware,
        Mailglass.Outbound.Worker,
        # :otel_tracer and :otel_span are erlang-atom modules, not Elixir
        :otel_tracer,
        :otel_span,
        Mjml,
        :gen_smtp_client,
        Sigra,
        # Premailex transitively references Meeseeks.Error in an optional
        # HTML-parser integration. Meeseeks isn't a mailglass dep; suppress
        # the bare-reference warning to keep test --warnings-as-errors clean.
        Meeseeks,
        Meeseeks.Error,
        Meeseeks.Document,
        # :asn1ct surfaces in OTP 27 SendGrid ECDSA shim; not in our deps.
        :asn1ct
      ]
    ]
  end

  defp deps do
    [
      # Required
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:plug, "~> 1.18"},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:swoosh, "~> 1.25"},
      {:uuidv7, "~> 1.0"},
      {:nimble_options, "~> 1.1"},
      {:telemetry, "~> 1.4"},
      {:gettext, "~> 1.0"},
      {:premailex, "~> 0.3"},
      {:floki, "~> 0.38"},
      {:boundary, "~> 0.10"},
      {:jason, "~> 1.4"},
      # Optional (gated by Code.ensure_loaded?/1 in Mailglass.OptionalDeps.*)
      {:oban, "~> 2.21", optional: true},
      {:opentelemetry, "~> 1.7", optional: true},
      {:mjml, "~> 5.3", optional: true},
      {:gen_smtp, "~> 1.3", optional: true},
      {:sigra, "~> 0.2", optional: true},
      # Test only
      {:stream_data, "~> 1.3", only: [:test]},
      {:mox, "~> 1.2", only: [:test]},
      {:excoveralls, "~> 0.18", only: [:test]},
      # Dev/test
      # Public upgrade codemod task ships in the package, so Igniter must be
      # available when consumer apps compile mailglass as a dependency.
      {:igniter, "~> 0.7", runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  # INST-04: `mix verify.phaseNN` is the single-command gate CI runs per phase.
  # Phase 6 expands this with custom Credo checks; the alias names stay stable.
  #
  # REL-03: Semantic names are canonical. The `verify.phase_NN` keys below are
  # deprecated one-cycle pass-throughs that delegate to the semantic aliases.
  # Remove them in the next release cycle.
  defp aliases do
    [
      # --- Semantic verify aliases (REL-03) ---

      # Phase 1: foundation — no-optional-deps compile + full test suite + Credo strict.
      "verify.foundation": [
        "compile --no-optional-deps --warnings-as-errors",
        "test --warnings-as-errors",
        "credo --strict"
      ],
      # Phase 2: persistence — drops/rebuilds the test DB, runs phase_02_uat tests,
      # then the no-optional-deps compile lane (Oban middleware conditional compile).
      # Mailglass.TestRepo lives in test/support (not in project ecto_repos),
      # so ecto tasks need `-r` to target it explicitly.
      "verify.persistence": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_02_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      # Phase 3: send pipeline UAT gate per INST-04.
      "verify.send_pipeline": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_03_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      # Phase 4: webhooks UAT gate per INST-04. Wave 0 wires the alias; Wave 4 (Plan 09)
      # ships the first `@tag :phase_04_uat` tests. Zero-test runs are a valid
      # pass — the alias verifies the DB can be dropped/created and the
      # no-optional-deps compile lane stays green.
      "verify.webhooks": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_04_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      # Phase 7: installer — runs the installer and docs test suites in a
      # single `mix test` invocation. Chaining individual aliases would trip
      # Mix's task-deduplication (each `verify.installer.*` calls `mix test`,
      # but `mix test` only runs once per invocation, so a chain would execute
      # only the first file).
      "verify.installer": [
        "test test/mailglass/install test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors --exclude flaky"
      ],

      # --- Deprecated pass-throughs (REL-03, one cycle) ---
      # These delegate to the canonical semantic aliases above.

      # verify.phase01 (legacy spelling without underscore) — deprecated; use verify.foundation
      "verify.phase01": ["verify.foundation"],
      # verify.phase_01 — deprecated; use verify.foundation
      "verify.phase_01": ["verify.foundation"],
      # verify.phase_02 — deprecated; use verify.persistence
      "verify.phase_02": ["verify.persistence"],
      # verify.phase_03 — deprecated; use verify.send_pipeline
      "verify.phase_03": ["verify.send_pipeline"],
      # verify.phase_04 — deprecated; use verify.webhooks
      "verify.phase_04": ["verify.webhooks"],
      # verify.phase_07 — deprecated; use verify.installer
      "verify.phase_07": ["verify.installer"],

      # --- Non-phase aliases (unchanged) ---

      "verify.installer.golden": [
        "test test/mailglass/install/install_golden_test.exs --warnings-as-errors"
      ],
      "verify.installer.idempotency": [
        "test test/mailglass/install/install_idempotency_test.exs --warnings-as-errors"
      ],
      "verify.installer.smoke": [
        "test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors"
      ],
      "verify.docs.contract": [
        "test test/mailglass/docs_contract_test.exs --warnings-as-errors"
      ],
      "verify.docs.migration": [
        "test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors"
      ],
      # Cold-start smoke — full suite from a fresh DB. Catches startup-order,
      # seed, and missing-migration issues that warm-state runs can mask.
      #
      # Excludes:
      #   - `:flaky` — tracked in deferred-items.md
      #   - `:migration_roundtrip` — the down/0 test in migration_test.exs
      #     drops and recreates the citext extension mid-suite. Postgres's
      #     syscache raises `XX000 cache lookup failed for type NNN` on
      #     prepared plans that referenced the pre-drop pg_type entry, and
      #     Postgrex's pool-wide TypeServer cache has no clean invalidation
      #     API. Phase 02 UAT lane runs the round-trip in isolation (via
      #     `--only phase_02_uat`), so coverage is preserved without
      #     poisoning the cold-start pool.
      "verify.cold_start": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --exclude flaky --exclude migration_roundtrip"
      ]
    ]
  end

  # CI-05: files whitelist excludes priv/static (Admin dashboard bundle — built
  # from source in the mailglass_admin package, never committed here).
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      source_ref_pattern: "mailglass-sibling-group-v%{version}",
      files:
        ~w(lib priv/gettext guides mix.exs LICENSE README.md CHANGELOG.md MAINTAINING.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md)
    ]
  end

  defp docs do
    [
      main: "getting-started",
      homepage_url: @source_url,
      source_url: @source_url,
      source_ref: "v#{@version}",
      skip_undefined_reference_warnings_on: [
        "README.md",
        "CONTRIBUTING.md",
        "guides/webhooks.md"
      ],
      # Disable auto-linking (and the matching warnings) for cross-refs to
      # external Swoosh/Ecto internals and to intentionally @moduledoc-false
      # Mailglass modules — moduledoc prose still mentions them by name.
      skip_code_autolink_to: [
        "Swoosh.Adapter.deliver/2",
        "Swoosh.Mailer.deliver/1",
        "Swoosh.Adapters.Sandbox.Storage",
        "Ecto.Repo.rollback/1",
        "Mailglass.Application.start/2",
        "Mailglass.Outbound.Worker.perform/1",
        "Mailglass.TemplateEngine.HEEx.render/3",
        "Mailglass.SuppressionStore.check/2"
      ],
      extras: [
        "README.md",
        "guides/getting-started.md",
        "guides/authoring-mailables.md",
        "guides/components.md",
        "guides/preview.md",
        "guides/webhooks.md",
        "guides/unsubscribe.md",
        "guides/dkim-setup.md",
        "guides/multi-tenancy.md",
        "guides/telemetry.md",
        "guides/testing.md",
        "guides/migration-from-swoosh.md",
        "MAINTAINING.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "CODE_OF_CONDUCT.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Guides: [
          "guides/getting-started.md",
          "guides/authoring-mailables.md",
          "guides/components.md",
          "guides/preview.md",
          "guides/webhooks.md",
          "guides/unsubscribe.md",
          "guides/dkim-setup.md",
          "guides/multi-tenancy.md",
          "guides/telemetry.md",
          "guides/testing.md",
          "guides/migration-from-swoosh.md"
        ],
        Maintainers: [
          "MAINTAINING.md",
          "CONTRIBUTING.md",
          "SECURITY.md",
          "CODE_OF_CONDUCT.md"
        ]
      ],
      groups_for_modules: [
        Core: [Mailglass, Mailglass.Config, Mailglass.Message, Mailglass.Outbound, Mailglass.Events],
        Authoring: [Mailglass.Mailable, Mailglass.Components, Mailglass.Renderer],
        Transport: [Mailglass.Adapter, Mailglass.Adapters.Fake, Mailglass.Adapters.Swoosh],
        Webhooks: [Mailglass.Webhook, Mailglass.Webhook.Router, Mailglass.Webhook.Plug],
        Operations: [Mailglass.Tenancy, Mailglass.TestAssertions],
        Internal: [
          Mailglass.Application,
          Mailglass.Outbound.Worker,
          Mailglass.Outbound.Projector,
          Mailglass.Webhook.Provider,
          Mailglass.Webhook.Reconciler,
          Mailglass.Webhook.Pruner,
          Mailglass.TemplateEngine.HEEx,
          Mailglass.Suppression,
          Mailglass.Migration,
          Mailglass.Migrations.Postgres,
          Mailglass.SuppressionStore.Ecto,
          Mailglass.SuppressionStore.ETS.Supervisor,
          Mailglass.Adapters.Fake.Supervisor,
          Mailglass.Adapters.Fake.Storage,
          Mailglass.PubSub,
          Mailglass.OptionalDeps.Oban
        ]
      ]
    ]
  end
end
