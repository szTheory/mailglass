defmodule MailglassAdmin.MixProject do
  use Mix.Project

  @version "0.3.2"
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
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
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:plug, "~> 1.18"},
      {:nimble_options, "~> 1.1"},
      # Build tooling (CONTEXT D-18). No :esbuild at v0.1 (pure LiveView, no custom JS).
      {:tailwind, "~> 0.4", only: :dev, runtime: false},
      # Optional dev dep (CONTEXT D-24). Adopter-owned LiveReload subscription.
      # `:only [:dev, :test]` so preview_live_test.exs can exercise the
      # LiveReload subscribe + broadcast path; the dep remains `optional: true`
      # so adopters can omit it entirely in prod-admin (v0.5) configurations.
      {:phoenix_live_reload, "~> 1.6", optional: true, only: [:dev, :test]},
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
  # packages evolve together; publishing to Hex pins the exact sibling
  # version via Release Please linked-versions plugin (Phase 7 D-03).
  #
  # The pinned-version string ("== 0.1.0") is a LITERAL, not an @version
  # interpolation. mix_config_test.exs evaluates this function's body in
  # isolation (via Code.string_to_quoted + Code.eval_quoted) where module
  # attributes are unreachable — `@version` would raise
  # `cannot invoke @/1 outside module`.
  #
  # Release Please's linked-versions plugin bumps the `@version` attribute
  # above automatically. The `==` literal below is rewritten by a sed step
  # in `.github/workflows/release-please.yml` that runs after the
  # release-please action and pushes a sync commit onto the
  # `release-please--branches--main` PR branch. (release-please's own
  # `extra-files` generic updater silently no-ops on a mix.exs already
  # managed by the elixir release-type, so we cannot rely on it — verified
  # empirically during the v0.1.1 cycle.)
  defp mailglass_dep do
    if System.get_env("MIX_PUBLISH") == "true" do
      {:mailglass, "== 0.3.1"}
    else
      {:mailglass, path: "..", override: true}
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
      # Semantic alias (REL-03)
      "verify.preview": [
        "compile --no-optional-deps --warnings-as-errors",
        "test --warnings-as-errors --exclude flaky",
        "mailglass_admin.assets.build",
        "cmd git diff --exit-code priv/static/"
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
      files: ~w(lib priv/static .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "MailglassAdmin",
      source_url: @source_url,
      source_ref: "v" <> @version
    ]
  end
end
