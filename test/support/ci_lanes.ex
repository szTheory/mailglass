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
  authoritative required-vs-advisory split lives in `MAINTAINING.md` (lines 152-191);
  the parity-contract intent is in `.planning/research/milestone-cicd/DX-MIX-CI.md`.

  ## Why the YAML/script copies are NOT hoisted away

  The required-lane list is *also* declared in three CI-side surfaces:
  `ci.yml` (`ci_green.needs`), `publish-hex.yml` (`REQUIRED_LANES`), and
  `scripts/setup_branch_protection.sh` (`REQUIRED_CHECKS`). Those are the CI-side
  DECLARATIONS the meta-tests VERIFY against — this module is the Elixir-side source
  the tests read, and GATE-03 is what proves the YAML/script copies have not drifted
  from it. Collapsing all four into one file is impossible across the YAML/shell/Elixir
  language boundary; the meta-test is the seam that keeps them coherent.

  ## Intentional exclusions from the parity claim

  `mix ci` deliberately does NOT reproduce the following CI lanes, so they are absent
  from `advisory_lanes/0` (rationale: DX-MIX-CI.md section E footgun #4 and #6):

    * `Demo Browser Evidence (Docker Compose / Chromium)` — Docker-compose demo
      evidence is slow and belongs to CI + `make demo-e2e`, not the default parity
      command (footgun #4: folding it in smuggles a Docker/Node requirement into the
      default path and muddies the zero-Node message).
    * `Preview Capture Advisory (...)` — Node/Playwright preview capture; same footgun #4.
    * `Core Full Suite Advisory`, `Provider Compatibility Advisory`,
      `Provider Live Advisory` — cron-only / live-provider canaries. "CI-parity for
      what a PR must pass," not "every canary" (DX-MIX-CI.md).
    * `Installer Golden Gate (...)`, `Branch Protection Advisory` — advisory CI-only
      lanes with no local-parity step in `mix ci`.
    * `Trust Lane Clean Baseline (...)` — the published-baseline trust journey (D-04);
      `mix ci` reproduces only the repo-head trust lane.

  The browser-tier advisory lane `Operator Browser Gate (...)` IS covered — by
  `mix ci.browser`, not `mix ci` (footgun #4 keeps it out of the default command).
  """

  @required_lanes [
    "Support Contract Core (Elixir 1.18 / OTP 27)",
    "Support Contract Admin (Elixir 1.18 / OTP 27)",
    "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
    "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
    "Installer Host Smoke"
  ]

  # Hygiene lanes `mix ci` reproduces (verbatim ci.yml name:).
  @advisory_lanes_ci [
    "Format Check (Elixir 1.18 / OTP 27)",
    "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Credo Strict (Elixir 1.18 / OTP 27)",
    "Dialyzer (Elixir 1.18 / OTP 27)",
    "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
    "Hex Audit (Elixir 1.18 / OTP 27)",
    "Mix Task Tests (Elixir 1.18 / OTP 27)",
    "Inbound Test (Elixir 1.18 / OTP 27)",
    "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  ]

  # Browser-tier advisory lane covered by `mix ci.browser` (verbatim ci.yml name:).
  @advisory_lanes_browser [
    "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)"
  ]

  @doc """
  The five required branch-protection leaf display names, VERBATIM as they appear as
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
end
