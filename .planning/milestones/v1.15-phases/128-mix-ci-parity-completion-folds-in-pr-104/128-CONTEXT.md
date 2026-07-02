# Phase 128: `mix ci` parity completion (folds in PR #104) - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Synthesized from locked milestone research (no discuss-phase needed — the design is decision-ready in `DX-MIX-CI.md` and SYNTHESIS LD-10/LD-12; maintainer-approved milestone decisions already lock the shape).

<domain>
## Phase Boundary

Complete `mix ci` so a single local command **equals the mergeable surface**, closing the
local↔CI parity gap. Deliver:

1. `mix ci` = all 5 REQUIRED branch-protection gates (currently missing Installer Host Smoke +
   the reference-host trust lane + its checkpoint contract).
2. Tiered aliases: `mix ci.fast` (seconds, no DB) / `mix ci` (full parity, Postgres+network) /
   `mix ci.browser` (opt-in Node/Playwright), plus **sibling-local** `ci`/`ci.fast` in
   `mailglass_admin` + `mailglass_inbound`, plus a discoverable `make ci`/`make help`.
3. A **manifest-membership parity-drift test** asserting `ci ∪ ci.browser` covers every
   required+advisory CI lane by identity + flag-set — sharing ONE `ci_lanes` source with GATE-03.
4. Brand-voice **preflight guards**: `mix ci`/`ci.setup` probe Postgres, the installer step probes
   network; absence prints an actionable message, never a raw connection crash.
5. Designate `verify.*` as internal composition targets, **remove the deprecated `verify.phase_NN`
   pass-throughs**, and repoint CONTRIBUTING at `mix ci`/`mix ci.fast` (no `verify.phase_07` 404).

**Out of scope:** any product/provider/transport/route change (D-23); ripping out the per-job
`ci.yml` split (the two-surface split is intentional — aliases for humans, matrix for CI legibility;
the parity-drift test is what keeps them from drifting); cache-key/PLT/Dialyzer-promotion work
(that's Phase 129).
</domain>

<decisions>
## Implementation Decisions (LOCKED — from `DX-MIX-CI.md` §B, decision-ready)

### Form & tiering
- **Plain Mix alias lists** — NOT a Mix.Task, NOT `ex_check`, NOT a `bin/ci` script. Zero new deps;
  fail-fast native chaining; honors minimal-tooling DNA. (`ex_check` can't model the bespoke gates —
  trust lane builds `reference/host_app`, installer smoke shells out, siblings need `cmd --cd`.)
- **Three tiers.** `ci.fast` (format + unused-deps hygiene + `compile --warnings-as-errors` + `compile
  --no-optional-deps --warnings-as-errors` + `credo --strict`); `ci` (full parity); `ci.browser`
  (Node/Playwright, advisory). `ci.fast` is a strict SUBSET of `ci`.
- **Ordering inside each alias = cheap → expensive, fail-fast.** format/credo/compile → contract+tests
  → docs/hex.audit → dialyzer → trust lane → installer smoke (network, SLOWEST) **last**.
- **3-package fan-out** via `cmd --cd mailglass_admin …` / `cmd --cd mailglass_inbound …`, mirroring the
  existing `verify.stability_contract`. One command from repo root.
- **Postgres-needing steps stay IN `mix ci`** (with `mix ci.setup` creating the sibling test DBs).
  Installer Host Smoke stays IN `mix ci` (required gate) but runs last behind a network prereq.
- **`preferred_envs`**: every new alias (`ci`, `ci.fast`, `ci.setup`, `ci.browser`) MUST be pinned to
  `:test` in `cli/0` — Elixir 1.18 no longer auto-promotes; omitting it is the #1 "alias looks broken"
  footgun. Same for the sibling aliases.
- **`make ci`/`ci-fast`/`ci-browser`** = thin pass-throughs only (Rails "CI YAML calls the command"),
  added to `.PHONY` so they appear in `make help`. `make ci` exports `MAILGLASS_PATH=$(pwd)`.

### Parity-drift test (MIXCI-03) — the "one definition of green" backstop
- Must assert `ci ∪ ci.browser` ⊇ the required + advisory CI lanes **by identity + flag-set**, failing
  LOUDLY on drift — NOT a vacuous substring superset. Include anti-vacuity guards (Phase 126 precedent).
- **Shares ONE `ci_lanes` source with GATE-03.** Phase 126 deliberately left the 5-name required-lane
  set duplicated across `ci.yml` (`ci-green.needs`), `publish-hex.yml` (`REQUIRED_LANES`), and
  `setup_branch_protection.sh` (`REQUIRED_CHECKS`), with a comment "Phase 128 MIXCI-03 will hoist to one
  source." **Hoist those to a single shared source** and have both the GATE-03 meta-test
  (`test/scripts/required_checks_test.exs`) and the new MIXCI-03 parity-drift test read from it.

### Brand-voice preflight guards (MIXCI-04)
- `mix ci`/`ci.setup` preflight-probe Postgres; the installer step probes network. On absence, print a
  specific, actionable, brand-voice message (voice: clear/exact/warm — "Postgres isn't reachable at
  localhost:5432. Start it, or set POSTGRES_HOST." NOT "Oops"/raw `DBConnection` crash).

### CONTRIBUTING + verify.* cleanup (MIXCI-05)
- Replace CONTRIBUTING Local Setup + Development Workflow (`CONTRIBUTING.md:5–21`) with the `ci.fast → ci`
  workflow + prerequisite-honest text (exact replacement in `DX-MIX-CI.md` §C). Removes the deprecated
  `mix verify.phase_07` pointer at `CONTRIBUTING.md:20`.
- **Remove the 6 pure deprecated pass-throughs** at `mix.exs:261–272` (`verify.phase01`, `.phase_01`,
  `.phase_02`, `.phase_03`, `.phase_04`, `.phase_07`) AND their `preferred_envs` entries. These are the
  "REL-03, one cycle" pass-throughs; this is that next cycle.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The decision-ready design (execute with minimal further thinking)
- `.planning/research/milestone-cicd/DX-MIX-CI.md` — §B has the EXACT alias bodies, `preferred_envs`
  list, sibling aliases, Makefile, `preferred_envs`; §C has the exact CONTRIBUTING replacement; §E is the
  footgun list. This is the primary spec.
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-10 (`mix ci` must equal the mergeable surface
  before the CONTRIBUTING claim lands; shared `ci_lanes`), LD-12 (least-surprise DX guards).

### The GATE-03 seam this phase completes
- `.planning/phases/126-.../126-01-PLAN.md` + `126-01-SUMMARY.md` — GATE-03 set-equality meta-test.
- `test/scripts/required_checks_test.exs` — the existing meta-test; MIXCI-03 shares its `ci_lanes` source.
- `.github/workflows/ci.yml` (`ci-green.needs`) + `.github/workflows/publish-hex.yml` (`REQUIRED_LANES`)
  + `scripts/setup_branch_protection.sh` (`REQUIRED_CHECKS`) — the 3 duplicated lane-set copies to hoist.

### Existing shapes to mirror
- `mix.exs` — `aliases/0` (`verify.stability_contract` fan-out pattern at ~301–307; deprecated
  pass-throughs at 261–272), `cli/0 preferred_envs`.
- `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs` — sibling `aliases/0` + `cli/0`.
- `CONTRIBUTING.md`, `MAINTAINING.md:153–158` (the 5 required gates), `Makefile` (demo-only today).
- `scripts/consumer_install_smoke.sh`, `scripts/check_trust_runner_checkpoint.sh`.
</canonical_refs>

<specifics>
## Specific Ideas / Reconciliations the planner MUST honor

1. **Fold in PR #104 (OPEN, not merged).** PR #104 already added a FIRST-DRAFT `ci.fast`/`ci`/`ci.browser`
   + `preferred_envs` + the CONTRIBUTING edit to root `mix.exs` (2-file diff: `mix.exs` +50, `CONTRIBUTING.md`
   +10). Its `mix ci` is INCOMPLETE — it is missing Installer Host Smoke, the trust-lane journey +
   checkpoint script, sibling aliases, `make ci`, the parity-drift test, the preflight guards, and the
   `verify.phase_NN` removal. Cleanest path: supersede PR #104 with the phase branch and close #104 (its
   diff is small). Do NOT double-add the aliases.

2. **CONSUME the Phase 127 `--seed 0` deletion (the whole 127→128 dependency).** `DX-MIX-CI.md` §B.1
   line 173 and §B.3 line 251 write the inbound step as `mix test --exclude property --seed 0`. Phase 127
   (DET-02) DELETED `--seed 0` everywhere and made the inbound suite deterministic via `MailboxCase`
   serial + dropping `shared:`. The `mix ci` inbound step MUST use `mix test --exclude property` with **NO
   `--seed 0`** — reintroducing it is a regression against Phase 127.

3. **`deps.unlock --check-unused` nuance.** `DX-MIX-CI.md` §B.1 puts it in `ci.fast`. PR #104
   deliberately EXCLUDED it because the lock carries orphaned transitive entries (`castore`,
   `unicode_util_compat`) that would red the check; cleaning those is a separate follow-up. **Recommendation:
   keep it excluded from `ci.fast`** (match PR #104's informed decision) OR clean the orphans first if
   trivial — planner's discretion, but do not ship a `ci.fast` that fails on first run.

4. **`verify.phase67` / `verify.phase69` are NOT pass-throughs** — they have real bodies (mix.exs:246–256)
   and are not marked deprecated. MIXCI-05 targets only the 6 pure pass-throughs (261–272). Leave
   phase67/69 functional (or note them as a separate rename candidate — not required for the "no
   `verify.phase_07` 404" success criterion, which only needs the pass-throughs gone + CONTRIBUTING
   repointed).

5. **Success criterion #4 is testable end-to-end:** `mix ci` with no Postgres must print the brand-voice
   message, not crash. The parity-drift test (crit #3) must fail when a required lane is dropped from the
   alias — write it fail-closed with anti-vacuity guards.
</specifics>

<deferred>
## Deferred Ideas
- Cache-key single-source + PLT self-healing eviction + Dialyzer→required promotion → **Phase 129**.
- Cleaning orphaned transitive lock entries (`castore`, `unicode_util_compat`) so `deps.unlock
  --check-unused` can rejoin `ci.fast` — separate follow-up, not blocking.
- `DET-A1` honest-async inbound suite — deferred post-v1.15.
</deferred>

---

*Phase: 128-mix-ci-parity-completion-folds-in-pr-104*
*Context synthesized 2026-07-01 from locked milestone-cicd research (research-first-decide; no strategic forks left to escalate).*
