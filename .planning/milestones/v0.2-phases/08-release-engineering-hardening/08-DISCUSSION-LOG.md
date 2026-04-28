# Phase 8: Release-Engineering Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 08-release-engineering-hardening
**Areas discussed:** Dialyzer triage strategy (REL-12), Tests gate re-tightening (REL-10), Credo --strict scope (REL-11), Release Please extra-files + release-please-action v5 timing (REL-05)

**Discussion mode:** Research-driven (per user feedback memory `feedback_research_driven_recommendations.md`). 4 `gsd-advisor-researcher` subagents spawned in parallel — one per gray area. Each produced a comparison table + recommendation + ecosystem prior art + footguns. Claude synthesized into a coherent recommendation set; only the AsyncAdapter-vs-shared-mode fork was surfaced for explicit user confirmation (genuinely impactful — touches lib module surface right before Phase 9 API freeze).

---

## REL-12: Dialyzer Triage Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Pure fix-first (zero ignores) | Highest type-safety bar; matches Oban posture once already-clean; for retrofit at 230 findings, 3–5 days of work and many findings are structurally unfixable | |
| Pure ignore-first (catalog all 230, fix nothing) | Fast to ship; preserves history; but defeats `--halt-exit-status` and is the anti-pattern REL-12 explicitly forbids | |
| Hybrid: flag-tune + fix-cheap + ignore-structural + document-rest | Add `:no_opaque, :no_match` flags (kills Elixir 1.18 opaque cascade); minimal annotated ignore file ≤15 entries; CI shell-script enforces `# Reason:` per entry; `list_unused_filters: true` self-cleans | ✓ |
| Time-boxed triage (1-day budget, defer rest) | Hard cap on Phase 8 sprawl; layered on top of hybrid as a tripwire | ✓ (layered on top of hybrid) |

**User's choice:** Auto-resolved per feedback memory — research recommendation accepted.
**Notes:** Recommendation matches Oban's mix.exs posture (the closest analog to mailglass given the custom-Credo-as-real-contract DNA). The `:no_opaque` + `:no_match` flag pair is also Ash's solution to the same Elixir 14837 regression. Per-package ignore files (mailglass + mailglass_admin separately). 1-day tripwire — overflow becomes a v0.3 Dialyzer-deep-clean research phase rather than padding the ignore file.

---

## REL-10: Tests Gate Re-Tightening

### Sub-decision A: citext OID-cache fix

| Option | Description | Selected |
|--------|-------------|----------|
| Custom `Postgrex.Types` module with citext registered | Forces compile-time bootstrap; but citext is already built-in and this doesn't help with mid-run extension drop/recreate | |
| Skip citext in test envs, use plain text | Eliminates race; but introduces test/prod schema drift and hides case-insensitivity bugs | |
| Sequential bootstrap only (already in place) | Already what test_helper.exs does; insufficient alone — race is mid-suite, not at startup | |
| Extract `Mailglass.TestSupport.CitextProbe` helper, call from test_helper + every CaseTemplate | Belt-and-suspenders: cold start + per-checkout 5-iter retry; matches existing `probe_until_clean/5` idiom; retains `disconnect_on_error_codes` | ✓ |

### Sub-decision B: Async ownership pattern

| Option | Description | Selected |
|--------|-------------|----------|
| `Sandbox.allow/3` per spawned task | Surgical; but threads test concerns into prod code | |
| `$callers` chain auto-allowance | Silently fails — `Mailglass.TaskSupervisor` is top-level, NOT in test process's `$callers` chain | |
| Shared-mode-by-default in MailerCase | Zero lib changes; forces ~50–80 of 520 tests to `async: false`; smaller blast radius but slower suite | |
| Hybrid: shared-mode now, AsyncAdapter in Phase 9 | Defers behaviour to API-redesign window | |
| **AsyncAdapter behaviour** (`TaskSupervisor` prod / `Inline` test) | Mirrors `Mailglass.Clock` injection pattern + Oban `:inline` testing; keeps tests async; introduces new internal module right before Phase 9 freeze | ✓ |

### Sub-decision C: ExUnit ordering

| Option | Description | Selected |
|--------|-------------|----------|
| `--seed 0` deterministic | Reproducible but masks ordering bugs by always running same order | |
| `async: false` tagging on shared-state tests + CaseTemplate hardening + retain random seed | Surgical; flakes still surface via random seed; matches Oban/Phoenix/Ash | ✓ |

### Sub-decision D: Halt-on-failure rollout

| Option | Description | Selected |
|--------|-------------|----------|
| Flip first, fix as failures appear | Forcing function but bad signal-to-noise; demoralizing red main | |
| Fix isolation → unmute → flip continue-on-error | Conservative single-PR; risk of "good enough" stopping short | |
| **3-PR sequence: PR-A fix → PR-B advisory strict lane (parallel, ~1 week) → PR-C flip required + delete advisory** | Telemetry-first; gradual confidence build; matches Phoenix/Oban/Ecto pattern | ✓ |

**User's choice:** AsyncAdapter behaviour explicitly confirmed via AskUserQuestion. All other Tests-gate sub-decisions auto-resolved per feedback memory.
**Notes:** AsyncAdapter is `@moduledoc false` (internal) for Phase 8; Phase 9 evaluates whether to elevate to public-API surface in `api_stability.md` v2. `:inline` impl MUST honor `Mailglass.Tenancy.with_tenant/2` re-stamping (D-21) for prod-test parity. Branch-protection flip in PR-C is `szTheory`-admin-only — flagged.

---

## REL-11: Credo --strict Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Pure zero-suppression (fix all 171 strict findings in Phase 8) | Cleanest baseline; but ~half of fixes touch modules Phase 9 redesigns; massive PR; collides with API freeze | |
| Documented baseline only (suppress most, fix none) | Fastest to ship; defeats "aim for zero suppressions" spirit; sets bad norm | |
| Strict advisory + default mandatory | Lowest friction; but doesn't deliver REL-11 (`--strict` enabled hard) | |
| **Hybrid (Oban pattern): fix Warnings + Phase-9-stable Refactor hotspots; document the rest with `# Reason:` + `# Tracking:` comments enforced by CI shell script** | Aligns with engineering DNA ("Custom Credo checks at lint time" — those are the real signal); Phase-9-zone untouched; honest debt | ✓ |

**User's choice:** Auto-resolved per feedback memory.
**Notes:** Identical comment-convention shape as Dialyzer ignore list (`scripts/check_credo_suppressions.sh` paired with `scripts/check_dialyzer_ignore.sh`). Custom LINT-01..12 stay at default priority (already block). `is_error?/1` rename deferred to Phase 9 as part of API redesign — inline `# credo:disable-for-next-line` until then. `@moduledoc false` added to two test fixtures (don't disable the `Readability.ModuleDoc` check).

---

## REL-05: Release Please extra-files Resolution + v5 Upgrade Timing

### Sub-decision A: extra-files resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Build/find a release-please plugin for Elixir managed mix.exs | Cleanest abstraction; but TypeScript + Node violates "no Node toolchain anywhere" DNA (D-13); no maintained plugin exists | |
| Refactor siblings to load version from shared `version.exs` | Declarative `extra-files` works; but Hex tarball packaging + `Code.eval_file` load-order risk introduces more failure modes than sed currently has | |
| **Keep + harden the Path 2 sed step + document permanently** | Already proven in v0.1.1; recursion-safe; bash-loop generalization for N siblings; shellcheck + fixture test + zero-match guard + compile-time regex anchor (mix_config_test.exs) | ✓ |

### Sub-decision B: release-please-action v5 timing

| Option | Description | Selected |
|--------|-------------|----------|
| Upgrade in Phase 8 (evaluate on a branch) | Stays current; Node 20 EOL April 2026; but v5.0.0 has only 4 days of public soak (released 2026-04-22) | |
| **Defer to Phase 13 (release ceremony)** | Lets v5 soak ~2-3 months; bundles upgrade with other release-engineering work near a release moment | ✓ |

**User's choice:** Auto-resolved per feedback memory.
**Notes:** TS plugin authorship rejected outright on DNA grounds (D-13). version.exs refactor rejected on packaging-risk grounds — opt out unless a 3rd sibling pin lands AND the sed loop becomes unwieldy. SHA pin stays at `googleapis/release-please-action@5c625bfb…` (v4.4.1) for Phase 8. Compile-time regex anchor (mix_config_test.exs assertion or LINT-13 candidate) prevents silent sed-regex bit-rot if dep tuple form changes. CONTRIBUTING.md scaffolded if missing.

---

## Claude's Discretion

- Exact CI step ordering within `ci.yml` (where to place the new `tests-strict` lane, where the new shell-script gate steps slot in) — planner decision.
- Specific bash-loop syntax for the generalized sed step in REL-05 — implementation detail.
- Whether the `mix_config_test.exs` regex-anchor assertion (D-08-24) is one test or split across multiple — planner judgment.
- Audit pass to identify which of the ~11 currently-failing tests need `@tag async: false` vs which can run async with the `:inline` adapter — derive from a `mix test --seed <random>` 3x run during planning.

## Deferred Ideas

### To Phase 9 (Mailable API Redesign + Freeze)
- Rename `Mailglass.Error.is_error?/1` → `error?/1` — folded into API redesign breaking changes
- AsyncAdapter behaviour public-surface decision — Phase 9 evaluates whether to elevate from internal seam to documented extension point in `api_stability.md` v2

### To Phase 13 (Release Ceremony)
- release-please-action v5.0.0 upgrade — v4.4.1 SHA pin retained for Phase 8

### To v0.3 (or later)
- Dialyzer overflow phase if >15 ignore entries needed after 1-day triage
- Custom Credo check banning `@dialyzer {:nowarn_function, ...}` source-level pragmas — backlog item
- `:underspecs` Dialyzer flag opt-in (after ≤15-entry baseline hit)

### To v0.5+
- `mailglass_inbound` sibling pin folded into REL-05 bash-loop generalization (one-line config change when it lands)

---

## Process Notes

- Spawned 4 `gsd-advisor-researcher` subagents in parallel via the `Agent` tool with `run_in_background: true`. All 4 returned within ~4 minutes total wall-clock (parallelized).
- Each agent's brief: (1) compare options as a table, (2) recommend a single coherent option, (3) cite Elixir/Hex ecosystem prior art with concrete repo links, (4) call out footguns specific to mailglass's stack, (5) leave open questions for the planner only where genuinely undecided.
- Synthesis layered Phase-9-firewall awareness on top of the per-area recommendations (Phase 8 explicitly avoids touching modules the Phase 9 API redesign will rewrite).
- One AskUserQuestion call surfaced for the AsyncAdapter-vs-shared-mode fork — only this decision met the "VERY impactful, reasonable people might disagree" bar from the feedback memory.
