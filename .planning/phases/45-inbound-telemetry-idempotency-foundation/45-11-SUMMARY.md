---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 11
subsystem: credo-checks / inbound-telemetry
tags: [telemetry, credo, lint, inbound, WR-02, TELE-06]
requires:
  - "credo_checks/telemetry_event_convention.ex (existing :telemetry.execute/:telemetry.span clauses + shared validate/8)"
  - "mailglass_inbound/lib/mailglass_inbound/telemetry.ex (real inbound span wrapper + *_span/2 helpers)"
provides:
  - "TelemetryEventConvention span-wrapper call-site clause (real inbound + outbound + webhook coverage)"
  - "real-inbound proof test (unmodified -> clean, mutated -> flagged)"
affects:
  - "lint-time enforcement of inbound/webhook telemetry event names"
tech-stack:
  added: []
  patterns:
    - "AST walk clause matching a span-prefixed wrapper call site, reusing the shared validate/8 root/length helper"
    - "starts-with(\"span\") wrapper discriminator (covers span, span_with_enrichment) vs *_span suffix helpers"
key-files:
  created: []
  modified:
    - "credo_checks/telemetry_event_convention.ex"
    - "test/mailglass/credo/telemetry_event_convention_test.exs"
decisions:
  - "Anchor the new clause on a span-PREFIXED wrapper function name (span, span_with_enrichment), NOT the *_span suffix the plan's interface notes assumed — the *_span suffix does not carry a full literal prefix in this codebase and would false-positive."
metrics:
  duration_min: 5
  tasks_completed: 2
  files_modified: 2
  tests: 17
  completed: 2026-05-23
---

# Phase 45 Plan 11: TelemetryEventConvention — Real Inbound `:telemetry.span/3` Coverage Summary

The `TelemetryEventConvention` Credo check now validates the literal atom-list event prefixes at the package's own span-WRAPPER call sites (`span([...], ...)` / `span_with_enrichment([...], ...)`), which is where the inbound (and webhook) event names actually live — delivering the REAL inbound `:telemetry.span/3` coverage WR-02 charters, proven against the live `mailglass_inbound` telemetry module (correct → clean, mutated → flagged), with no false positives on variable-prefix forwards or partial-suffix `*_span` helpers, and a moduledoc that no longer overclaims.

## What Was Built

**Task 1 (TDD) — span-wrapper call-site clause + precise moduledoc.**
Added a `walk/5` clause (two heads: bare-atom local call `span([...], ...)` and qualified remote call `Mod.span([...], ...)`) that matches a span-WRAPPER call site and routes its literal first-arg prefix through the EXISTING shared `validate/8` helper at `threshold: min_segments - 1` (same span off-by-one — the runtime appends `:start`/`:stop`/`:exception`). Reuses `literal_atom_list/1` and `root_issue/5` unchanged. Rewrote the moduledoc to enumerate the three covered call-site forms (execute / span / span-wrapper) and to state explicitly that a variable prefix — including the private wrapper's own `:telemetry.span(event_prefix, ...)` forward — is intentionally NOT validated (the literal lives one level up at the wrapper call site, which IS covered).

**Task 2 — fixtures + real-inbound proof.**
Added fixtures proving the wrapper clause fires (under-segmented, wrong-root, qualified `Mod.span`), refutes (correct 3-segment inbound prefix, variable-prefix wrapper, partial-suffix `*_span` helper), and generalizes (webhook `span_with_enrichment`). Added the WR-02 real-inbound proof: it `File.read!`s `mailglass_inbound/lib/mailglass_inbound/telemetry.ex`, asserts the unmodified source yields ZERO issues (the real prefixes are correct AND now SEEN by the check), then asserts a mutated copy (`[:mailglass_inbound, :ingress, :request]` → `[:wrong_app, :ingress, :request]`) yields exactly ONE issue — proving the coverage is real, not vacuous.

## Verification

- `mix test test/mailglass/credo/telemetry_event_convention_test.exs` → 17 tests, 0 failures (8 pre-existing + 9 new, incl. the real-inbound proof).
- `mix test test/mailglass/credo/` → 89 tests, 0 failures (no regressions in sibling checks).
- `mix credo --strict` → exits 0, "found no issues" across 376 source files. This is the load-bearing proof: the new clause does NOT flag the real outbound `span([:mailglass, ...])`, the webhook `span_with_enrichment([:mailglass, :webhook, ...])`, the inbound `span([:mailglass_inbound, ...])`, the `++`-spliced `span([:mailglass, :persist] ++ suffix, ...)`, or the partial-suffix `persist_span([:delivery, ...])` call sites.
- `mix compile --warnings-as-errors` → no warnings in `telemetry_event_convention.ex`.

NOTE: the toolchain (Elixir/OTP 28, mix) IS available in this worktree, so the plan's "MISSING locally (toolchain caveat)" note was outdated — the RED→GREEN cycle and `credo --strict` were all run locally rather than deferred to CI.

## FIX-4 — Webhook `*_span` Generalization Confirmation (required by `<output>`)

The plan asked for a grep confirmation that the webhook package's `*_span` call sites are literal-correct under the generalized clause, with any variable-routed/non-literal site noted. Findings:

- **The webhook literals do NOT live at the public `*_span` call site.** The webhook public helpers (`ingest_span/2`, `verify_span/2`, `reconcile_span/2`) take `(metadata, fun)` and carry NO literal at their call site — exactly like the inbound `*_span/2` helpers.
- **The webhook wrapper is named `span_with_enrichment` (NOT `span`).** The literal prefixes live at its call sites inside the helpers:
  - `span_with_enrichment([:mailglass, :webhook, :ingest], ...)` — 3 segments, root `:mailglass` ✓
  - `span_with_enrichment([:mailglass, :webhook, :signature, :verify], ...)` — 4 segments, root `:mailglass` ✓
  - `span_with_enrichment([:mailglass, :webhook, :reconcile], ...)` — 3 segments, root `:mailglass` ✓
  All three are literal-correct (correct root + ≥ span threshold). `span_with_enrichment` itself forwards a VARIABLE `event_prefix` to `:telemetry.span/3` (intentionally not validated, like the inbound `defp span`).
- Because the webhook wrapper name is `span_with_enrichment`, the check now matches the wrapper by a **`span`-PREFIXED name** (`String.starts_with?(name, "span")`), which covers `span`, `span_with_enrichment`, and any future `span_*` wrapper — genuinely generalizing the FIX-4 coverage to the webhook package. No new webhook fixtures were added to the test file (a synthetic `span_with_enrichment` shape fixture is included to lock the generalization, but no real webhook source is parsed).

## Deviations from Plan

### [Rule 4 → goal-faithful correction] Anchored on a span-PREFIXED wrapper name, not the `*_span` suffix

- **Found during:** Task 1 read-first (grep of real call sites) — confirmed before any code was written.
- **Issue:** The plan's `<interfaces>`/`<action>` instructed matching a `*_span`-SUFFIXED helper call site whose first arg is a literal atom list. The codebase ground truth contradicts that premise:
  1. The real inbound `*_span/2` helpers (`ingress_span`/`route_span`/`persist_span`/`execution_span`) take `(metadata, fun)` — they do NOT carry a literal at their public call site. The literal full prefix lives at the INTERNAL `span([:mailglass_inbound, ...], ...)` call (function named exactly `span`, no `_span` suffix). So a `*_span`-suffix match would NEVER fire on real inbound code — failing the plan's core objective.
  2. The outbound core has `persist_span([:delivery, :update_projections], ...)` and `persist_span([:reconcile, :link], ...)` — `*_span`-suffixed call sites whose first arg IS a literal atom list, but it's a partial SUFFIX the wrapper prepends `[:mailglass, :persist]` onto, NOT a full prefix. A `*_span`-suffix match would FALSELY flag these (wrong root, too short), breaking `mix credo --strict` (a hard acceptance criterion).
- **Fix:** Anchored the clause on the span-WRAPPER function name (`span`-prefixed: `span`, `span_with_enrichment`) — the codebase-true location of every full literal event prefix across all three packages. This achieves the plan's actual OBJECTIVE and every `must_haves` truth (real inbound coverage; fires on under-segmented/wrong-root; passes on correct; no false positive on variable prefix; real inbound names validated; generalizes beyond the four inbound helpers to the webhook wrapper; precise moduledoc) while keeping `credo --strict` green.
- **Why not a checkpoint:** The literal `*_span`-suffix instruction was impossible-as-written (would miss all real inbound code AND break the build), the correct codebase-grounded shape was unambiguous, the plan is autonomous with `mode: yolo`, and the plan itself flags FIX-4 as the place to surface exactly this generalization concern. The OBJECTIVE and acceptance outcomes are fully met; only the AST anchor differs from the (factually mistaken) interface note.
- **Acceptance-criteria grep impact:** Two Task-1 acceptance greps assumed the `*_span`/`ends_with?` shape. They are superseded by the corrected anchor: `grep -c "starts_with?" credo_checks/telemetry_event_convention.ex` ≥ 1 and `grep -c "span_wrapper_name?" ...` ≥ 1 are the corrected equivalents. The substantive criteria (reuses `validate/8`, reuses `literal_atom_list/1` + `root_issue/5` unchanged, moduledoc no longer overclaims "enforced for BOTH", `credo --strict` exits 0, real-inbound proof present) are all met.
- **Files modified:** `credo_checks/telemetry_event_convention.ex`, `test/mailglass/credo/telemetry_event_convention_test.exs`
- **Commits:** `55f4d44` (initial `span`-name clause), `86f2bb5` (generalized to `span`-prefixed names for webhook FIX-4 coverage)

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| `a2fc8f7` | test | RED — failing tests for span-wrapper call-site validation |
| `55f4d44` | feat | GREEN — span-wrapper clause (real inbound coverage) + precise moduledoc |
| `86f2bb5` | feat | FIX-4 — generalize to `span`-prefixed names (webhook `span_with_enrichment` coverage) |

## Known Stubs

None — the clause is fully wired and proven against real source.

## Self-Check: PASSED

- `credo_checks/telemetry_event_convention.ex` — FOUND (modified, span-wrapper clause present)
- `test/mailglass/credo/telemetry_event_convention_test.exs` — FOUND (modified, 17 tests incl. real-inbound proof)
- Commit `a2fc8f7` — FOUND
- Commit `55f4d44` — FOUND
- Commit `86f2bb5` — FOUND
