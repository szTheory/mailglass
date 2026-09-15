defmodule MailglassAdmin.MixProject do
  use Mix.Project

  @version "2.6.0"
  @source_url "https://github.com/szTheory/mailglass"
  @description "Mountable LiveView dashboard for mailglass — dev preview + admin"

  def project do
    [
      app: :mailglass_admin,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      compilers: [:boundary | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      name: "MailglassAdmin",
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

  def cli do
    [
      preferred_envs: [
        ci: :test,
        "ci.fast": :test,
        "mailglass_admin.preview.capture": :test,
        "verify.preview": :test,
        "verify.phase_05": :test,
        "verify.support_contract.admin": :test
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

  # "dev/" holds internal CI-only preview-capture tooling (Chromium screenshot
  # driver + mix mailglass_admin.preview.capture). Compiled in :dev and :test for
  # CI/local use, but kept out of "lib" so it never ships in the Hex package
  # (mix.exs :package :files lists "lib", not "dev").
  defp elixirc_paths(:dev), do: ["lib", "dev"]

  # RATCHET-01 / CONTEXT D-06 mechanism 2 (A1 fallback — Pitfall 3): the
  # canonical persona cohort spec lives in the demo app, but a `path:` dep on
  # the whole `mailglass_demo` app is structurally impossible — the demo
  # depends on `mailglass_admin`, so a back-dep is a circular path dep ("another
  # project with the same name was already defined"). Instead we compile the
  # single canonical spec directory directly into the admin TEST build.
  # `reference/persona_spec/personas.ex` is a pure module — it references only
  # core schemas (`Mailglass.Outbound.Delivery`, `Mailglass.Events.Event`), no
  # demo-app or Phoenix deps — so it compiles cleanly here. This keeps the spec
  # a single source of truth (admin test-support reads
  # `MailglassDemo.Personas.spec/0`) without crossing into prod or the
  # `--no-optional-deps` lane (it is `:test`-only, just like `test/support`).
  @persona_spec_dir Path.expand("../reference/persona_spec", __DIR__)
  defp elixirc_paths(:test), do: ["lib", "test/support", "dev", @persona_spec_dir]
  defp elixirc_paths(_), do: ["lib"]

  # CONTEXT D-24: phoenix_live_reload is dev-only optional; declare here so
  # bare references compile cleanly on the no-optional-deps CI lane.
  defp elixirc_options do
    [no_warn_undefined: [Phoenix.LiveReloader]]
  end

  defp deps do
    [
      # Local-dev: path dep so changes in ../lib/mailglass/ are picked up
      # immediately. Published Hex tarball: pinned version match (linked
      # versions per CONTEXT D-02 / DIST-01 / PREV-01).
      mailglass_dep(),
      # Optional sibling: the admin LiveView reads inbound rows through the
      # `MailglassAdmin.OptionalDeps.MailglassInbound` runtime gateway. The dep
      # is FLOATING (`~> 0.2`, never `==`) and `optional: true` so the
      # `mix compile --no-optional-deps --warnings-as-errors` lane compiles with
      # inbound stripped (CONTEXT D-48-01, Pitfall 4). It is INTENTIONALLY OUT of
      # the release-please PINS array — a `==` cross-line pin into a 0.2.x package
      # is unsatisfiable; the gateway, not a version pin, is the integration seam.
      mailglass_inbound_dep(),
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:plug, "~> 1.18"},
      {:nimble_options, "~> 1.1"},
      # Build tooling (CONTEXT D-18). No :esbuild at v0.1 (pure LiveView, no custom JS).
      {:tailwind, "~> 0.4", only: [:dev, :test], runtime: false},
      # Optional dev dep (CONTEXT D-24). Adopter-owned LiveReload subscription.
      # `:only [:dev, :test]` so preview_live_test.exs can exercise the
      # LiveReload subscribe + broadcast path; the dep remains `optional: true`
      # so adopters can omit it entirely in prod-admin (v0.5) configurations.
      {:phoenix_live_reload, "~> 1.6", optional: true, only: [:dev, :test]},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:boundary, "~> 0.10", runtime: false},
      # floki + jason: unrestricted :only scope because the mailglass core
      # path dep uses them at runtime. Mix rejects divergent :only options
      # on shared transitive deps (Rule 3 blocker resolution).
      {:floki, "~> 0.38"},
      {:jason, "~> 1.4"},
      # Dev/test
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      # Phoenix.LiveViewTest 1.1+ requires lazy_html for DOM traversal
      # (replaces the previous floki-based implementation).
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  # CONTEXT D-02 linked-versions switch (the ONE pattern with no analog in
  # mailglass core's mix.exs): local-dev uses a path dep so the sibling
  # packages evolve together; publishing to Hex uses a pessimistic `~>` constraint
  # (v1.15 Phase 125, LD-2). Admin is in the linked-versions group
  # [mailglass, mailglass_admin] — the Release Please plugin release-time-locks
  # admin's minor to core, so `~> 2.0` is safe: admin never resolves against a
  # core minor it was not shipped with. A new core minor requires a linked admin
  # release, which updates this line.
  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "~> 2.0"}
    else
      {:mailglass, path: "..", override: true}
    end
  end

  # CONTEXT D-48-01: the optional inbound sibling. Mirrors `mailglass_dep/0`'s
  # MIX_PUBLISH branch STRUCTURE (path dep for local-dev, version constraint when
  # publishing) but is FLOATING (`~> 2.0`, NEVER `== X.Y.Z`) and `optional: true`.
  #
  # Why floating, not pinned: `mailglass_inbound` tracks its own version line and
  # is NOT part of the release-please linked-versions group. The v2.0 milestone
  # advanced inbound to its own 2.0.0 (breaking schema-isolation contract), so the
  # floating constraint is `~> 2.0` — it must resolve against the inbound MAJOR
  # that ships alongside this admin release. A `==` pin (the shape release-please's
  # sed step writes for the linked siblings) could write an unsatisfiable
  # cross-line version, so this dep is deliberately ABSENT from the release-please
  # PINS array in `.github/workflows/release-please.yml`. Bump the floating line by
  # hand when inbound's major advances past core's (0.2 -> 1.x -> 2.0).
  #
  # The admin reads inbound rows exclusively through the
  # `MailglassAdmin.OptionalDeps.MailglassInbound` runtime gateway
  # (`Code.ensure_loaded?(MailglassInbound)` + `apply/3`), so `optional: true`
  # keeps the `--no-optional-deps` compile lane green with inbound stripped.
  defp mailglass_inbound_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass_inbound, "~> 2.0", optional: true}
    else
      {:mailglass_inbound, path: "../mailglass_inbound", optional: true}
    end
  end

  # REL-03: Semantic names are canonical. The `verify.phase_05` key below is a
  # deprecated one-cycle pass-through that delegates to the semantic alias.
  # Remove it in the next release cycle.
  #
  # Phase 5 verification gate. Intentionally RED at Plan 02 completion:
  #   - step 2 (test --warnings-as-errors) fails because Plans 03-06 tests are RED
  #   - step 3 (mailglass_admin.assets.build) fails because Plan 05 ships that task
  # Step 4 is the PREV-06 / CONTEXT D-04 merge gate — bundle drift CI check.
  defp aliases do
    [
      # Sibling-local ci verb (uniform "is this green?" across packages). The
      # root `mix ci` already fans out; these serve the inner-loop-in-a-subdir
      # case for a contributor working inside mailglass_admin/.
      "ci.fast": [
        "format --check-formatted",
        "compile --no-optional-deps --warnings-as-errors",
        "credo --strict"
      ],
      ci: [
        "ci.fast",
        "verify.support_contract.admin"
      ],
      # Semantic alias (REL-03)
      "verify.preview": [
        "compile --no-optional-deps --warnings-as-errors",
        "test --warnings-as-errors --exclude flaky",
        "mailglass_admin.assets.build",
        "cmd git diff --exit-code priv/static/"
      ],
      "verify.support_contract.admin": [
        "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors"
      ],
      # Deprecated pass-through (REL-03, one cycle) — use verify.preview instead
      "verify.phase_05": ["verify.preview"]
    ]
  end

  # CONTEXT D-04: strict files whitelist. `assets/` source is EXCLUDED from
  # the Hex tarball (vendored daisyUI + Tailwind input); `priv/static/` is
  # INCLUDED (compiled CSS, fonts, logo). LiveDashboard / Oban Web precedent.
  defp package do
    [
      name: "mailglass_admin",
      licenses: ["MIT"],
      description: @description,
      source_ref_pattern: "mailglass-sibling-group-v%{version}",
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/mailglass_admin"
      },
      files: ~w(lib priv/static docs .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "MailglassAdmin",
      source_url: @source_url,
      source_ref: "v" <> @version,
      logo: "../brandbook/assets/logo-mark.svg",
      favicon: "../brandbook/assets/favicon.svg",
      extras: [
        "README.md",
        "docs/design-system.md",
        "docs/operator-trust.md",
        "docs/api_stability.md",
        "docs/compatibility-and-deprecations.md"
      ],
      groups_for_extras: [
        Overview: ["README.md"],
        Design: ["docs/design-system.md"],
        Contract: [
          "docs/operator-trust.md",
          "docs/api_stability.md",
          "docs/compatibility-and-deprecations.md"
        ]
      ],
      groups_for_modules: [
        Stable: [MailglassAdmin, MailglassAdmin.Router, MailglassAdmin.Auth],
        Internal: [MailglassAdmin.Operator.Mount]
      ]
    ]
  end
end
