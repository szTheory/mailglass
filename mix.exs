defmodule Mailglass.MixProject do
  use Mix.Project

  @version "2.6.0"
  @source_url "https://github.com/szTheory/mailglass"
  # Release-As path anchor (137-02, D-01): this root mix.exs touch attributes the
  # companion commit's `Release-As: 2.0.0` footer to the linked mailglass +
  # mailglass_admin group (core `exclude-paths` keeps admin/inbound out of `.`).
  # The linked-versions plugin may still override a per-commit trailer (v1.0 Pitfall 5);
  # the D-02 dry-run PR inspection is the gate that confirms 2.0.0 before merge.

  def project do
    [
      app: :mailglass,
      version: @version,
      # LD-13: when the required pin advances past 1.18, add a 1.18 floor row to the
      # required lane or raise this floor — never let the tested version outrun it.
      # See .planning/research/milestone-cicd/SYNTHESIS.md LD-13 and the 1.19/OTP28
      # advisory row in .github/workflows/advisory-matrix.yml.
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
      # :inets/:ssl back the SES SNS SigningCertURL fetch (`:httpc` GET over
      # HTTPS in webhook/providers/ses.ex). Declared explicitly rather than
      # relying on a transitive load — Igniter is now an optional dep, so it no
      # longer drags :inets into a consumer's app tree.
      extra_applications: [:logger, :crypto, :public_key, :inets, :ssl],
      mod: {Mailglass.Application, []}
    ]
  end

  # Elixir 1.18+ no longer auto-promotes :test for `mix test` invocations
  # nested inside aliases. Every composite alias that nests `mix test` (or an
  # env-sensitive compile) must declare its preferred env here, otherwise it
  # raises the `set MIX_ENV explicitly` error before any sub-task runs. This is
  # the #1 "alias looks broken on first run" footgun for the ci.* family below.
  def cli do
    [
      preferred_envs: [
        # Local↔CI parity aliases (CICD milestone)
        ci: :test,
        "ci.fast": :test,
        "ci.full": :test,
        "ci.setup": :test,
        "ci.browser": :test,
        # Semantic verify aliases (REL-03)
        "verify.foundation": :test,
        "verify.persistence": :test,
        "verify.send_pipeline": :test,
        "verify.webhooks": :test,
        "verify.installer": :test,
        "verify.mix_tasks": :test,
        "verify.ci_lane_contract": :test,
        "verify.reference_host.journey": :test,
        "verify.demo_browser_evidence": :test,
        "verify.phase69": :test,
        "verify.phase67": :test,
        "verify.cold_start": :test,
        "verify.installer.golden": :test,
        "verify.installer.idempotency": :test,
        "verify.installer.smoke": :test,
        "verify.support_contract.core": :test,
        "verify.stability_contract": :test,
        "verify.provider_compatibility": :test,
        "verify.docs.contract": :test,
        "verify.docs.contract.inbound": :test,
        "verify.docs.migration": :test,
        "verify.schema_prefix": :test
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

  # "dev/" holds maintainer-only tooling (reference-host trust journey modules,
  # mix mailglass.trust.run / mailglass.repo.hygiene). Compiled in :dev and :test
  # for CI/local use, but kept out of "lib" so it never ships in the Hex package
  # (mix.exs :package :files lists "lib", not "dev").
  defp elixirc_paths(:dev), do: ["lib", "credo_checks", "dev"]
  defp elixirc_paths(:test), do: ["lib", "credo_checks", "test/support", "dev"]
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
      {:premailex, "~> 1.0"},
      {:floki, "~> 0.38"},
      {:boundary, "~> 0.10"},
      {:jason, "~> 1.4"},
      # Optional (gated by Code.ensure_loaded?/1 in Mailglass.OptionalDeps.*)
      {:oban, "~> 2.21", optional: true},
      {:opentelemetry, "~> 1.7", optional: true},
      {:mjml, "~> 6.0", optional: true},
      {:gen_smtp, "~> 1.3", optional: true},
      {:sigra, "~> 1.0", optional: true},
      # Test only
      {:stream_data, "~> 1.3", only: [:test]},
      {:mox, "~> 1.2", only: [:test]},
      {:excoveralls, "~> 0.18", only: [:test]},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_reload, "~> 1.6", optional: true, only: [:dev, :test]},
      # Dev/test
      # Optional: the public `mix mailglass.upgrade.v0_2` codemod is built on
      # Igniter, but the module is compile-guarded with
      # `Code.ensure_loaded?(Igniter.Mix.Task)`, so consumers who don't run it
      # don't carry Igniter (and its `req`/`finch`/`mint` chain) in their lock —
      # keeping a fresh install HTTP-client-agnostic (OPS-01). Adopters running
      # the codemod add Igniter themselves (`mix igniter.install` / deps entry).
      {:igniter, "~> 0.7", optional: true, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
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
      # Phase 57: canonical deterministic trust-runner entrypoint for
      # reference-host journey verification across local and CI surfaces.
      "verify.reference_host.journey": [
        "mailglass.trust.run"
      ],
      "verify.demo_browser_evidence": [
        "cmd sh scripts/run_demo_browser_evidence.sh"
      ],
      "verify.phase69": [
        "test test/mailglass/docs_contract_test.exs --warnings-as-errors",
        "cmd --cd reference/demo_app sh -c \"MIX_ENV=test mix test test/mailglass_demo_web/page_controller_dashboard_test.exs test/mailglass_demo/docs_contract_test.exs --warnings-as-errors\"",
        "verify.demo_browser_evidence"
      ],
      "verify.phase67": [
        "test test/reference_host/scope_lock_contract_test.exs --warnings-as-errors",
        "cmd --cd reference/demo_app sh -c \"MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate && mix test --warnings-as-errors\"",
        "cmd sh -c \"DEMO_EVIDENCE_RESET_TOKEN=phase67-verify docker compose -f compose.demo.yml config\"",
        "cmd rg -n 'MAILGLASS_DEMO_DEPS|service_healthy|npm ci|playwright install --with-deps chromium|cache' compose.demo.yml"
      ],

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
      # Mix-task / generator CLI surface (`mix mailglass.gen.*`, doctor, reconcile,
      # suppressions.resync). Directory-scoped ON PURPOSE: a file-enumerated list
      # (as used by the contract aliases below) silently drops newly-added task
      # tests from CI — the exact drift footgun that left the Phase-47 inbound
      # generators advisory-only. A directory glob auto-includes every
      # test/mix/tasks/*_test.exs, is non-vacuous (the dir exists + has tests, so
      # it can't pass by matching zero tests), and keeps one focused concern per
      # alias per engineering-DNA. The Igniter generator tests are in-memory
      # (Igniter.Test) but the core test_helper boots Mailglass.TestRepo, so the
      # CI job that runs this still needs the test DB created.
      "verify.mix_tasks": [
        "test test/mix/tasks/ --warnings-as-errors"
      ],
      # CI lane-contract truth seam (TRUTH-07, Phase 141). Directory-scoped ON
      # PURPOSE: the glob auto-includes every future test/scripts/*_test.exs, and
      # until this phase no `ci.yml` lane executed this directory at all
      # (RESEARCH.md F2) — a meta-test dropped in test/scripts/ without this alias
      # (and the ci.yml step that runs it) would satisfy the letter of a drift-proof
      # test while enforcing nothing.
      "verify.ci_lane_contract": [
        "test test/scripts/ --warnings-as-errors"
      ],
      "verify.support_contract.core": [
        "test test/mailglass/docs_contract_test.exs test/mailglass/docs/testing_guide_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compatibility_contract_test.exs test/mailglass/docs_migration_smoke_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors"
      ],
      "verify.stability_contract": [
        "verify.support_contract.core",
        "cmd --cd mailglass_admin mix verify.support_contract.admin",
        "cmd --cd mailglass_inbound mix verify.support_contract.inbound",
        "mailglass.docs.check",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      "verify.provider_compatibility": [
        "test test/mailglass/adapter_test.exs test/mailglass/adapters/swoosh_test.exs test/mailglass/webhook/providers/postmark_test.exs test/mailglass/webhook/providers/sendgrid_test.exs test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/providers/resend_test.exs test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/plug_ses_test.exs test/mailglass/webhook/providers/resend_webhook_plug_test.exs --warnings-as-errors"
      ],
      "verify.docs.contract.inbound": [
        "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"
      ],
      "verify.docs.contract": [
        "test test/mailglass/docs_contract_test.exs test/mailglass/compatibility_contract_test.exs --warnings-as-errors",
        "verify.docs.contract.inbound",
        "mailglass.docs.check"
      ],
      "verify.docs.migration": [
        "test test/mailglass/docs_migration_smoke_test.exs test/mailglass/compatibility_contract_test.exs --warnings-as-errors"
      ],
      "verify.schema_prefix": [
        "test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix --warnings-as-errors",
        "cmd mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs --warnings-as-errors",
        "credo --strict",
        "cmd --cd mailglass_inbound mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors"
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
      ],

      # --- Local↔CI parity (CICD milestone) ---
      #
      # `mix ci` is the ONE command a contributor runs before opening a PR: it
      # mirrors the 5 required branch-protection gates plus the standard hygiene
      # lanes, across all three sibling packages. Three tiers:
      #
      #   mix ci.fast    — seconds, no DB/network. Pre-commit loop.
      #   mix ci         — full local parity. Needs Postgres + network (phx.new).
      #   mix ci.browser — opt-in Node/Playwright admin browser gate (advisory).
      #
      # CI keeps its per-job step split for legible, parallel status; the SUM of
      # `mix ci` + `mix ci.browser` equals the mergeable surface, so "green
      # locally" means "green in CI". Ordering inside each alias is cheap →
      # expensive, fail-fast.

      # Create every test DB the parity run needs. Preflight-probes Postgres
      # first so absence fails with a brand-voice line, not a DB stacktrace.
      "ci.setup": [
        "cmd bash scripts/preflight_postgres.sh",
        "cmd env MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet",
        "cmd --cd mailglass_inbound mix deps.get --check-locked",
        "cmd --cd mailglass_inbound mix ecto.create -r MailglassInbound.TestRepo --quiet"
      ],

      # Fast tier — no Postgres, no network. The pre-commit / inner-loop gate.
      # (deps.unlock --check-unused is intentionally omitted: the lock carries
      # orphaned transitive entries; cleaning them is a deferred follow-up.)
      "ci.fast": [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "compile --no-optional-deps --warnings-as-errors",
        "credo --strict"
      ],

      # Full local parity — run from repo ROOT. Requires Postgres (+ network for
      # the installer smoke step at the end). Mirrors the 5 required gates +
      # hygiene. Preflight guards fail closed before any DB/network task.
      ci: [
        "cmd bash scripts/preflight_postgres.sh",
        # Package-isolation tasks can leave local dev artifacts behind the
        # unchanged lock. Rehydrate them before the parity run starts.
        "cmd mix deps.get --check-locked",
        # Keep the no-optional-deps compile in an isolated child build. Running
        # `ci.fast` inline unloads Hex from this parent Mix VM; sharing _build
        # would also delete optional dependency artifacts needed by later lanes.
        "cmd env MIX_ENV=test MIX_BUILD_PATH=_build/ci_fast mix ci.fast",
        # Run the remaining parity surface in a fresh Mix VM. The no-optional-deps
        # compile above intentionally changes compiler/dependency state; keeping
        # the full suite in the parent VM makes Mix inspect stale dependency
        # metadata and report false lock mismatches.
        "cmd mix deps.get --check-locked",
        "cmd env MIX_ENV=test mix ci.full"
      ],

      # The full parity surface is separate so `mix ci` can execute it in a
      # clean Mix VM after the isolated fast gate. Keep this alias declarative:
      # ci_parity_drift_test expands externally invoked aliases and proves the
      # union still covers every protected and advisory CI lane.
      "ci.full": [
        "cmd env MIX_ENV=test mix ci.setup",
        "cmd env MIX_ENV=test mix verify.support_contract.core",
        "cmd env MIX_ENV=test mix test --warnings-as-errors",
        "cmd --cd mailglass_admin mix deps.get --check-locked",
        "cmd --cd mailglass_admin mix verify.support_contract.admin",
        "cmd --cd mailglass_inbound mix deps.get --check-locked",
        "cmd --cd mailglass_inbound mix compile --no-optional-deps --warnings-as-errors",
        "cmd --cd mailglass_inbound mix test --exclude property",
        "cmd --cd mailglass_inbound mix test --only property",
        # ExDoc is intentionally a dev-only dependency; invoke the docs gates in
        # their native environment instead of inheriting ci.full's test env.
        "cmd env MIX_ENV=dev mix docs --warnings-as-errors",
        "cmd env MIX_ENV=dev mix mailglass.docs.check",
        # F1: widened from the two bare hex-audit/deps-audit mix tasks so
        # `mix ci` reproduces the same shared-allowlist, three-directory scan
        # both ci.yml audit lanes now run (Phase 142/VULN-05). Leaving this
        # unwidened would keep ci_parity_drift_test.exs green while the
        # local<->CI parity claim silently narrowed to a root-only,
        # allowlist-unaware scan. Costs `mix ci` two extra deps.get/audit
        # passes (mailglass_admin, mailglass_inbound); noted as a SEED-006
        # input, not optimized here.
        "cmd env MIX_ENV=test mix mailglass.audit --kind hex",
        "cmd env MIX_ENV=test mix mailglass.audit --kind deps",
        "cmd env MIX_ENV=test mix dialyzer",
        "cmd --cd mailglass_inbound mix dialyzer",
        "cmd --cd reference/host_app mix deps.get",
        "cmd --cd reference/host_app env MIX_ENV=dev mix compile",
        "cmd env MIX_ENV=test MAILGLASS_REFERENCE_HOST_PACKAGE_MODE=prepublication MAILGLASS_CORE_WORKSPACE_EBIN=#{File.cwd!()}/_build/test/lib/mailglass/ebin MAILGLASS_INBOUND_WORKSPACE_EBIN=#{File.cwd!()}/mailglass_inbound/_build/test/lib/mailglass_inbound/ebin mix verify.reference_host.journey",
        "cmd bash scripts/check_trust_runner_checkpoint.sh",
        "cmd bash scripts/preflight_network.sh",
        "cmd env DEP_MODE=path MAILGLASS_PATH=#{File.cwd!()} bash scripts/consumer_install_smoke.sh",
        "cmd env MAILGLASS_PATH=#{File.cwd!()} bash scripts/generated_ecto_host_proof.sh"
      ],

      # Opt-in browser gate (Node + Playwright). Advisory in CI; zero-Node is an
      # ADOPTER guarantee, so requiring Node HERE (dev/CI tooling) is fine.
      "ci.browser": [
        "cmd env MIX_ENV=test mix ci.setup",
        "cmd --cd mailglass_admin npm ci",
        "cmd --cd mailglass_admin npx playwright install --with-deps chromium",
        "cmd --cd mailglass_admin npm run test:operator-browser"
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
      logo: "brandbook/assets/logo-mark.svg",
      favicon: "brandbook/assets/favicon.svg",
      skip_undefined_reference_warnings_on: [
        "README.md",
        "CONTRIBUTING.md",
        "guides/webhooks.md",
        "guides/jobs.md"
      ],
      # Disable auto-linking (and the matching warnings) for cross-refs to
      # external Swoosh/Ecto internals and to intentionally @moduledoc-false
      # Mailglass modules — moduledoc prose still mentions them by name.
      skip_code_autolink_to: [
        "Swoosh.Adapter.deliver/2",
        "Swoosh.ApiClient.init/0",
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
        "docs/api_stability.md",
        "guides/compatibility-and-deprecations.md",
        "guides/upgrading-to-v1_0.md",
        "guides/upgrading-to-v2_0.md",
        "guides/getting-started.md",
        "guides/b2c-first-adopter.md",
        "guides/learning-path.md",
        "guides/jobs.md",
        "guides/authoring-mailables.md",
        "guides/components.md",
        "guides/preview.md",
        "guides/webhooks.md",
        "guides/unsubscribe.md",
        "guides/dkim-setup.md",
        "guides/multi-tenancy.md",
        "guides/telemetry.md",
        "guides/testing.md",
        "guides/upgrading-from-v0_1.md",
        "guides/migration-from-swoosh.md",
        "guides/production-go-live-checklist.md",
        "guides/errors-and-troubleshooting.md",
        "docs/upgrade-from-0.x.md",
        "MAINTAINING.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "CODE_OF_CONDUCT.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Contract: [
          "docs/api_stability.md",
          "guides/compatibility-and-deprecations.md"
        ],
        Guides: [
          "guides/upgrading-to-v1_0.md",
          "guides/upgrading-to-v2_0.md",
          "guides/getting-started.md",
          "guides/b2c-first-adopter.md",
          "guides/learning-path.md",
          "guides/jobs.md",
          "guides/authoring-mailables.md",
          "guides/components.md",
          "guides/preview.md",
          "guides/webhooks.md",
          "guides/unsubscribe.md",
          "guides/dkim-setup.md",
          "guides/multi-tenancy.md",
          "guides/telemetry.md",
          "guides/testing.md",
          "guides/upgrading-from-v0_1.md",
          "guides/migration-from-swoosh.md",
          "guides/production-go-live-checklist.md",
          "guides/errors-and-troubleshooting.md",
          "docs/upgrade-from-0.x.md"
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
