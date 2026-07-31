defmodule Mailglass.CILanes do
  @moduledoc """
  The single Elixir-side source of truth for CI lane identity (MIXCI-03, D-LD-10).

  "One definition of green." Branch-protection truth (the required leaf gates) and
  the advisory hygiene lanes that `mix ci` / `mix ci.browser` reproduce are declared
  here ONCE. Two meta-tests read this module:

    * `test/scripts/required_checks_test.exs` — the GATE-03 set-equality test, which
      verifies `ci.yml`'s `ci_green.needs` display names set-equal `required_lanes/0`.
    * `test/scripts/ci_parity_drift_test.exs` — the MIXCI-03 parity-drift test, which
      verifies the `mix ci` ∪ `mix ci.browser` alias step-sets cover every required +
      advisory lane by identity, failing loudly on drift.

  All names here are VERBATIM the `name:` fields in `.github/workflows/ci.yml`. The
  authoritative required-vs-advisory split lives in `MAINTAINING.md` § "Required Checks";
  the parity-contract intent is in `.planning/research/milestone-cicd/DX-MIX-CI.md`.

  ## Why the YAML/script copies are NOT hoisted away

  The required-lane list is *also* declared in three CI-side surfaces:
  `ci.yml` (`ci_green.needs`), `publish-hex.yml` (`REQUIRED_LANES`), and
  `scripts/setup_branch_protection.sh` (`REQUIRED_CHECKS`). Those are the CI-side
  DECLARATIONS the meta-tests VERIFY against — this module is the Elixir-side source
  the tests read, and GATE-03 is what proves the YAML/script copies have not drifted
  from it. Collapsing all four into one file is impossible across the YAML/shell/Elixir
  language boundary; the meta-test is the seam that keeps them coherent.

  ## Three independent axes

  This module answers three different questions, and conflating them is the defect
  Phase 141 fixed:

    * **Parity** (`advisory_lanes/0`, `advisory_lanes_ci/0`, `advisory_lanes_browser/0`) —
      "does `mix ci` reproduce this lane locally?" Consumed by `ci_parity_drift_test.exs`
      (MIXCI-03).
    * **Classification** (`required_lanes/0`, `advisory_classified_lanes/0`,
      `publish_gating_lanes/0`, `structural_lanes/0`) — "what does this lane block?"
      Consumed by the drift meta-test (`test/scripts/lane_classification_drift_test.exs`)
      and mirrored in `publish-hex.yml`'s `gate-ci-green` and `MAINTAINING.md`.
    * **Advisory-matrix classification** (`advisory_matrix_gating_lanes/0`,
      `advisory_matrix_advisory_lanes/0`, Phase 143 / D-24) — "what does this
      `advisory-matrix.yml` lane block?" A *separate* question from the bucket above,
      because those four buckets classify `.github/workflows/ci.yml` jobs and these
      classify a different workflow's. See the "do not fold" note on the buckets.

  A lane is routinely in both of the first two (`Dialyzer` is locally reproduced *and*
  publish-gating). Do not partition one axis to build another.

  The name-space seam (RESEARCH F1): the strings in this module are YAML `name:`
  values; `gate-ci-green` sees runtime job names, which for a matrix lane carry an
  appended ` (<matrix values>)` suffix (e.g. `Dialyzer (Elixir 1.18 / OTP 27)` reports
  live as `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`). That is why classification
  matching downstream is prefix-based for every bucket except required.

  ## Intentional exclusions from the parity claim

  `mix ci` deliberately does NOT reproduce the following CI lanes, so they are absent
  from `advisory_lanes/0` (rationale: DX-MIX-CI.md section E footgun #4 and #6):

    * `Demo Browser Evidence (Docker Compose / Chromium)` — Docker-compose demo
      evidence is slow and belongs to CI + `make demo-e2e`, not the default parity
      command (footgun #4: folding it in smuggles a Docker/Node requirement into the
      default path and muddies the zero-Node message).
    * `Preview Capture Advisory (...)` — Node/Playwright preview capture; same footgun #4.
    * `Core Full Suite`, `Provider Compatibility Advisory` — the
      `advisory-matrix.yml` full-suite/toolchain matrix. *(Corrected per Plan 143-03's
      D-31 amendment: this is NOT a schedule-triggered-only canary — `advisory-matrix.yml`
      triggers on `push`, `pull_request`, `schedule`, and `workflow_dispatch`
      (`advisory-matrix.yml:3-10`), and Core Full Suite is about to become
      publish-gating on its two floor legs (HARNESS-04). It is excluded from the parity
      claim for a narrower reason: "CI-parity for what a PR must pass locally," not
      "every lane a PR's CI run executes" — `mix ci` does not reproduce the full
      four-leg toolchain/schema matrix locally, which is a wall-clock decision
      (SEED-006), not a claim about when the lane runs.)* `Provider Live Advisory` —
      genuinely triggered ONLY on a recurring schedule plus manual dispatch, a true
      live-provider canary: its own `provider-live.yml` workflow's `on:` block contains
      only `schedule` (`cron: "33 6 * * *"`) and `workflow_dispatch`, never `push` or
      `pull_request`.
    * `Installer Golden Gate (...)`, `Branch Protection Advisory` — advisory CI-only
      lanes with no local-parity step in `mix ci`.
    * `Trust Lane Clean Baseline (...)` — the published-baseline trust journey (D-04);
      `mix ci` reproduces only the repo-head trust lane.
    * `Design System Conformance (shell gates)` — `mix ci` and `mix ci.fast` run
      `mix credo --strict` but none of `scripts/check_motion_conformance.sh`,
      `mailglass_admin/scripts/check-conformance.sh`, or
      `mailglass_admin/scripts/check-conformance-advisory.sh`, so this lane has no
      local-parity step. It must NOT be added to `@advisory_lanes_ci` — doing so would
      make `ci_parity_drift_test.exs` (MIXCI-03) claim a local-parity guarantee `mix ci`
      does not provide.

  The browser-tier advisory lane `Operator Browser Gate (...)` IS covered — by
  `mix ci.browser`, not `mix ci` (footgun #4 keeps it out of the default command).
  """

  @required_lanes [
    "Support Contract Core (Elixir 1.18 / OTP 27)",
    "Support Contract Admin (Elixir 1.18 / OTP 27)",
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
    "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
    "Installer Host Smoke",
    "Hex Audit (Elixir 1.18 / OTP 27)",
    "Deps Audit (Elixir 1.18 / OTP 27)"
  ]

  # Hygiene lanes `mix ci` reproduces (verbatim ci.yml name:).
  @advisory_lanes_ci [
    "Format Check (Elixir 1.18 / OTP 27)",
    "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Credo Strict (Elixir 1.18 / OTP 27)",
    "Dialyzer (Elixir 1.18 / OTP 27)",
    "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Mix Task Tests (Elixir 1.18 / OTP 27)",
    "Inbound Test (Elixir 1.18 / OTP 27)",
    "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  ]

  # Browser-tier advisory lane covered by `mix ci.browser` (verbatim ci.yml name:).
  @advisory_lanes_browser [
    "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)"
  ]

  # Lanes that block NEITHER a merge NOR a publish. This is the *classification*
  # axis. Distinct from @advisory_lanes_ci / @advisory_lanes_browser, which answer
  # a different question: "what does `mix ci` reproduce locally?" (MIXCI-03). A
  # lane can be locally reproduced AND publish-gating (Dialyzer is).
  @advisory_classified_lanes [
    "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)",
    "Demo Browser Evidence (Docker Compose / Chromium)",
    "Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)"
  ]

  # Lanes that block a Hex publish when red but do NOT block a PR merge.
  # `gate-ci-green` (publish-hex.yml) enumerates these; `ci_green.needs` does not.
  @publish_gating_lanes [
    "Format Check (Elixir 1.18 / OTP 27)",
    "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Mix Task Tests (Elixir 1.18 / OTP 27)",
    "Inbound Test (Elixir 1.18 / OTP 27)",
    "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)",
    "Credo Strict (Elixir 1.18 / OTP 27)",
    "Design System Conformance (shell gates)",
    "Dialyzer (Elixir 1.18 / OTP 27)",
    "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Installer Golden Gate (Elixir 1.18 / OTP 27)",
    "Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)",
    "Branch Protection Advisory"
  ]

  # Structural jobs — not check lanes (a path filter and an aggregator).
  # Classified so no `ci.yml` job sits unrecorded (TRUTH-09); their blocking
  # behavior in `gate-ci-green` is identical to the publish-gating lanes above.
  # `CI Green` is itself one of the two branch-protection contexts and must
  # therefore NEVER appear in `REQUIRED_LANES` — that would be a self-referential
  # gate.
  @structural_lanes [
    "Detect Non-Doc Changes",
    "CI Green"
  ]

  # ---------------------------------------------------------------------------
  # THIRD AXIS (Phase 143 / D-24): `.github/workflows/advisory-matrix.yml`.
  #
  # These two buckets answer "what does this ADVISORY-MATRIX lane block?" — a
  # different question from the four buckets above, which answer it for `ci.yml`.
  # The strings are RUNTIME names: `advisory-matrix.yml`'s jobs interpolate every
  # matrix axis into their `name:`, so GitHub reports them fully substituted with no
  # appended suffix, one per `strategy.matrix.include:` row.
  # `Mailglass.CIYaml.expanded_matrix_job_names/1` reproduces exactly these seven.
  #
  # DO NOT fold either bucket into `all_classified_lanes/0`. That accessor is bound
  # by set equality to `ci.yml`'s 24 jobs, and three assertions in
  # `lane_classification_drift_test.exs` pin the count at 24 — folding breaks those,
  # both set-equality tests against `publish-hex.yml`, and the `MAINTAINING.md`
  # disposition-table comparison, all at once. This axis is additive: none of the
  # existing hardcoded counts changes because of it.
  # ---------------------------------------------------------------------------

  # The two `advisory-matrix.yml` legs HARNESS-04 gates a Hex publish on: the
  # Elixir 1.18 / OTP 27 floor pair, one per schema axis. They are the declared
  # `~> 1.18` floor `mix.exs` states, which keeps LD-13's floor-coincidence
  # invariant intact, and they are the ONLY advisory-matrix legs that gate —
  # `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:329` lists "use
  # one gigantic matrix as required status" under anti-patterns.
  #
  # Blast radius is wider than the lane name reads: gating these two also gates the
  # inbound `mix deps.get`, the inbound `mix ecto.create`, and `mix verify.schema_prefix`,
  # which are steps of the same job and which the next-toolchain legs do not run.
  #
  # LIVE as of Phase 143 plan 13: `gate-ci-green` (`publish-hex.yml`) reads
  # `advisory-matrix.yml` and blocks a Hex publish when either of these two legs is
  # red, cancelled, skipped, or absent. `MAINTAINING.md` records them as
  # `publish-gating` / `keep-with-reason` to match. The verdict, the evidence it
  # rests on, and its accepted costs are in
  # `.planning/phases/143-test-harness-truth/143-GATING-DECISION.md`.
  #
  # The gate reaches the run by DISPATCHING `advisory-matrix.yml` on the release
  # ref, not by looking a run up: a release-please bot-merged SHA has zero runs of
  # it (GitHub raises no workflow for a GITHUB_TOKEN event, and this workflow has
  # no `release:` trigger), so a lookup-only gate would deadlock every release.
  @advisory_matrix_gating_lanes [
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema public)",
    "Core Full Suite (Elixir 1.18 / OTP 27 / schema mailglass)"
  ]

  # Every other `advisory-matrix.yml` lane: classified, enumerated, warned on, never
  # blocking.
  #
  # `Core Full Suite Next Toolchain Advisory` is the forward-compatibility canary. It
  # carries `if: github.event_name != 'pull_request'`, so it is absent by design on
  # every PR run — absence there is a designed outcome, not a missing lane.
  #
  # `Inbound Full Suite Advisory` is deliberately NOT gated despite being green today
  # (D-20). It pins `--seed 0` specifically to dodge the known phase-45 property-test
  # pool flake, and a lane whose green depends on a hardcoded seed chosen to avoid a
  # known nondeterminism is not trustworthy enough to gate a publish: it would be
  # gating on the absence of a bug nobody fixed. Revisit when that pin is removed.
  @advisory_matrix_advisory_lanes [
    "Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema public)",
    "Core Full Suite Next Toolchain Advisory (Elixir 1.19 / OTP 28 / schema mailglass)",
    "Provider Compatibility Advisory (Elixir 1.18 / OTP 27)",
    "Inbound Full Suite Advisory (schema public)",
    "Inbound Full Suite Advisory (schema mailglass)"
  ]

  @doc """
  The seven required branch-protection leaf display names, VERBATIM as they appear as
  `name:` in `.github/workflows/ci.yml`.
  """
  @spec required_lanes() :: [String.t()]
  def required_lanes, do: @required_lanes

  @doc """
  The advisory lane display names the `mix ci` ∪ `mix ci.browser` parity claim covers,
  VERBATIM as they appear as `name:` in `.github/workflows/ci.yml`.

  Cron-only/live canaries and Docker demo-evidence lanes are intentionally excluded —
  see the module doc for the per-lane rationale.
  """
  @spec advisory_lanes() :: [String.t()]
  def advisory_lanes, do: @advisory_lanes_ci ++ @advisory_lanes_browser

  @doc """
  Advisory lanes reproduced by the `mix ci` alias (excludes the browser tier).
  """
  @spec advisory_lanes_ci() :: [String.t()]
  def advisory_lanes_ci, do: @advisory_lanes_ci

  @doc """
  Advisory lanes reproduced by the `mix ci.browser` alias (the browser tier only).
  """
  @spec advisory_lanes_browser() :: [String.t()]
  def advisory_lanes_browser, do: @advisory_lanes_browser

  @doc """
  The advisory *classification* lane display names — lanes that block NEITHER a
  merge NOR a publish. Distinct from the parity accessors above, which answer
  "does `mix ci` reproduce this lane locally?" A lane can appear in both this and
  `advisory_lanes/0` (e.g. `Operator Browser Gate`), or in only one (see the
  moduledoc's independent-axes section).
  """
  @spec advisory_classified_lanes() :: [String.t()]
  def advisory_classified_lanes, do: @advisory_classified_lanes

  @doc """
  Lane display names that block a Hex publish when red but do NOT block a PR
  merge. `gate-ci-green` (`publish-hex.yml`) enumerates these; `ci_green.needs`
  (`ci.yml`) does not.
  """
  @spec publish_gating_lanes() :: [String.t()]
  def publish_gating_lanes, do: @publish_gating_lanes

  @doc """
  Structural job display names — not check lanes (a path filter and an
  aggregator). Classified so no `ci.yml` job sits unrecorded (TRUTH-09); their
  blocking behavior in `gate-ci-green` is identical to `publish_gating_lanes/0`.
  """
  @spec structural_lanes() :: [String.t()]
  def structural_lanes, do: @structural_lanes

  @doc """
  Every `ci.yml` job display name, across all four classification buckets. The
  drift meta-test (`test/scripts/lane_classification_drift_test.exs`) asserts
  this set-equals the job names parsed from `ci.yml`, so no job can sit
  unclassified (TRUTH-09).
  """
  @spec all_classified_lanes() :: [String.t()]
  def all_classified_lanes,
    do:
      required_lanes() ++
        advisory_classified_lanes() ++ publish_gating_lanes() ++ structural_lanes()

  @doc """
  The `advisory-matrix.yml` RUNTIME lane names HARNESS-04 gates a Hex publish on —
  the two Elixir 1.18 / OTP 27 Core Full Suite legs, one per schema axis.

  Deliberately absent from `all_classified_lanes/0`: that accessor is bound by set
  equality to `ci.yml`'s 24 jobs (see the buckets' comment for what folding breaks).
  """
  @spec advisory_matrix_gating_lanes() :: [String.t()]
  def advisory_matrix_gating_lanes, do: @advisory_matrix_gating_lanes

  @doc """
  Every other `advisory-matrix.yml` RUNTIME lane name — classified, enumerated,
  warned on, never blocking. Disjoint from `advisory_matrix_gating_lanes/0` by
  construction, asserted in `lane_classification_drift_test.exs`.

  Deliberately absent from `all_classified_lanes/0`, same reason as above.
  """
  @spec advisory_matrix_advisory_lanes() :: [String.t()]
  def advisory_matrix_advisory_lanes, do: @advisory_matrix_advisory_lanes
end
