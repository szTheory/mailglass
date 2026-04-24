defmodule Mailglass.MixProject do
  use Mix.Project

  @version "0.1.0"
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
      name: "Mailglass",
      description: "Transactional email framework for Phoenix. Composes on Swoosh.",
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
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
        # :otel_tracer and :otel_span are erlang-atom modules, not Elixir
        :otel_tracer,
        :otel_span,
        Mjml,
        :gen_smtp_client,
        Sigra
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  # INST-04: `mix verify.phaseNN` is the single-command gate CI runs per phase.
  # Phase 6 expands this with custom Credo checks; the alias names stay stable.
  defp aliases do
    [
      "verify.phase01": [
        "compile --no-optional-deps --warnings-as-errors",
        "test --warnings-as-errors",
        "credo --strict"
      ],
      # Phase 2 UAT gate — drops and rebuilds the test DB so migration/seed
      # regressions surface named, runs the 6 success-criteria test files
      # explicitly (equivalent to `mix test --only phase_02_uat`), then the
      # no-optional-deps compile lane (Oban middleware conditional compile).
      # Mailglass.TestRepo lives in test/support (not in project ecto_repos),
      # so ecto tasks need `-r` to target it explicitly.
      "verify.phase_02": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_02_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      # Phase 3 UAT gate per INST-04.
      "verify.phase_03": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_03_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
      ],
      # Phase 4 UAT gate per INST-04. Wave 0 wires the alias; Wave 4 (Plan 09)
      # ships the first `@tag :phase_04_uat` tests. Zero-test runs are a valid
      # pass — the alias verifies the DB can be dropped/created and the
      # no-optional-deps compile lane stays green.
      "verify.phase_04": [
        "ecto.drop -r Mailglass.TestRepo --quiet",
        "ecto.create -r Mailglass.TestRepo --quiet",
        "test --warnings-as-errors --only phase_04_uat --exclude flaky",
        "compile --no-optional-deps --warnings-as-errors"
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
      files: ~w(lib priv/gettext mix.exs LICENSE README.md CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "getting-started",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end
end
