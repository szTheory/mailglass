---
phase: 32-replay-reconcile-hardening
verified: 2026-05-05T20:13:32Z
status: verified
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/6
  gaps_closed:
    - "Maintenance reconciliation works through one canonical function whether Oban is present or absent."
    - "Regression coverage exists for the most failure-prone replay/reconcile operator paths."
  gaps_remaining: []
  regressions: []
human_verification: []
---

# Phase 32: Replay & Reconcile Hardening Verification Report

**Phase Goal:** Operators can replay and reconcile webhook-driven delivery state safely, with explicit guardrails around authorization, ambiguity, and audit outcomes.
**Verified:** 2026-05-05T20:13:32Z
**Status:** verified
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Operators can request replay only after tenant-safe target resolution and action-time authorization. | ✓ VERIFIED | [mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:127) resolves the target before [DestructiveAction.authorize/4](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex:15), and [mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex:17) delegates through `Auth.authorize(..., :destructive_action, ...)`. |
| 2 | Stale-auth and unauthorized replay attempts stop before any replay audit rows are appended. | ✓ VERIFIED | [mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex:26) returns an auth error before execution, and [mailglass_admin/test/mailglass_admin/operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:340) asserts `"Recent authentication is required."` with no replay audit rows. |
| 3 | Ambiguous replayable webhook rows require an explicit operator choice instead of an implicit guess. | ✓ VERIFIED | [mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:437) returns `:target_required` for ambiguous sets without a chosen row, and [mailglass_admin/test/mailglass_admin/operator_live_test.exs](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/operator_live_test.exs:272) covers the `"choice required"` flow. |
| 4 | Operator-visible replay outcomes stay auditable and clearly distinguish new work, no-op outcomes, and failures. | ✓ VERIFIED | [mailglass_admin/lib/mailglass_admin/operator/repair_state.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:17) maps requested/completed/failed and [mailglass_admin/lib/mailglass_admin/operator/repair_state.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:28) maps replayed/noop to new work/no change; [mailglass_admin/lib/mailglass_admin/operator/timeline.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/timeline.ex:38) preserves the `Replay audit` distinction. |
| 5 | Maintenance reconciliation works through one canonical function whether Oban is present or absent. | ✓ VERIFIED | [lib/mailglass/webhook/reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:1) and [lib/mailglass/webhook/reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:233) define Oban-present and Oban-absent module variants that both export `available?/0` and `reconcile/2`; `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` now passes with 14 tests. |
| 6 | Regression coverage exists for the most failure-prone replay/reconcile operator paths. | ✓ VERIFIED | `mix test test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors` passes with 12 tests, `mix compile --no-optional-deps --warnings-as-errors` passes, and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` passes with 14 tests. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex` | Shared destructive-action authorization helper | ✓ VERIFIED | Exists, substantive, and is called from replay confirmation before execution. |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | Replay flow that resolves, authorizes, and executes | ✓ VERIFIED | Exists, substantive, and wires target resolution -> auth -> replay execution. |
| `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` | Shared presenter for replay availability/outcome/effect | ✓ VERIFIED | Exists, substantive, and is used across header, modal, timeline, and flash copy. |
| `lib/mailglass/webhook/reconciler.ex` | Canonical reconcile function for Oban and non-Oban installs | ✓ VERIFIED | Both compile branches export the same maintenance API; Oban-only worker entrypoint remains gated to the Oban branch. |
| `lib/mix/tasks/mailglass.reconcile.ex` | Manual reconcile entrypoint aligned with fallback contract | ✓ VERIFIED | Exists, substantive, and always invokes `reconciler.reconcile/2` while adapting the scheduler note to `available?/0`. |
| `test/mix/tasks/mailglass_reconcile_test.exs` | Regression coverage for Oban-present and Oban-absent task behavior | ✓ VERIFIED | Covers task output in both available and fallback modes; the real consumer/no-Oban compile path is additionally covered by the passing `mailglass_admin` suite. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `operator_live.ex` | `operator/destructive_action.ex` | `DestructiveAction.authorize/4` | ✓ WIRED | [mailglass_admin/lib/mailglass_admin/operator_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator_live.ex:135) calls the helper before `Replay.execute/1`. |
| `operator/destructive_action.ex` | `auth.ex` | `Auth.authorize(..., :destructive_action, ...)` | ✓ WIRED | [mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex:18) delegates through the existing auth seam. |
| `detail_header.ex` | `repair_state.ex` | Availability/latest replay summary mapping | ✓ WIRED | `RepairState` is used for availability and latest replay wording in the delivery detail header. |
| `timeline.ex` | `repair_state.ex` | Timeline label and metadata mapping | ✓ WIRED | `RepairState` produces replay labels and summaries while `timeline.ex` keeps replay audit rows visually distinct. |
| `mailglass.reconcile` task | `Mailglass.Webhook.Reconciler.reconcile/2` | Canonical reconcile invocation | ✓ WIRED | [lib/mix/tasks/mailglass.reconcile.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex:52) resolves the reconciler module and [lib/mix/tasks/mailglass.reconcile.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.reconcile.ex:54) calls `reconcile/2`. |
| `application.ex` | maintenance tasks | Runtime warning text describing fallback path | ✓ WIRED | [lib/mailglass/application.ex](/Users/jon/projects/mailglass/lib/mailglass/application.ex:100) points operators to `mix mailglass.reconcile` and `mix mailglass.webhooks.prune` when Oban is absent. |
| `guides/webhook-troubleshooting.md` | `test/mix/tasks/mailglass_reconcile_test.exs` | Documented fallback behavior mirrored by tests | ✓ WIRED | [guides/webhook-troubleshooting.md](/Users/jon/projects/mailglass/guides/webhook-troubleshooting.md:54) and [test/mix/tasks/mailglass_reconcile_test.exs](/Users/jon/projects/mailglass/test/mix/tasks/mailglass_reconcile_test.exs:53) describe the same Oban-less/system-cron fallback contract. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | `replay_targets`, `replay_history`, flash outcome | `ReplayTargets.list_delivery_targets/1`, `ReplayHistory.list_delivery_replay_history/1`, `Replay.execute/1` | Yes | ✓ FLOWING |
| `mailglass_admin/lib/mailglass_admin/operator/timeline.ex` | `@timeline_events` replay summaries | `Mailglass.Operator.Timeline.list_delivery_events/2` plus replay metadata | Yes | ✓ FLOWING |
| `lib/mailglass/webhook/reconciler.ex` | `orphans`, `linked`, telemetry metadata | `Mailglass.Events.Reconciler.find_orphans/1`, append-only `:reconciled` writes, projector updates | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Replay/reconcile root suites | `mix test test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors` | `12 tests, 0 failures` | ✓ PASS |
| Root no-optional-deps compile lane | `mix compile --no-optional-deps --warnings-as-errors` | Succeeded | ✓ PASS |
| Consumer operator suite without Oban in dependency graph | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | `14 tests, 0 failures` plus the expected runtime warning about manual webhook maintenance | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `MAT-01` | `32-01`, `32-02`, `32-03` | Operator can replay or reconcile webhook-driven delivery state with explicit tenant-safe authorization, auditable outcomes, and clear failure handling. | ✓ SATISFIED | Replay authorization, ambiguity handling, auditable wording, canonical reconcile fallback, and focused regression coverage all verify against code and passing behavioral checks. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No blocker stub/placeholder/optional-deps anti-patterns found in the phase-critical files scanned. | ℹ️ Info | The prior `use Oban.Worker` consumer-compile break is no longer present as a failing contract. |

### Human Verification Closure

The prior human-only checks were closed on 2026-05-05 with direct browser and
CLI evidence in a consumer-like `mailglass_admin` context:

1. Browser verification
   - Exact-target detail pages rendered `Replay is ready. One exact webhook target is available for confirmation.`
   - Ambiguous detail pages rendered `Replay is choice required.` and the confirmation button stayed absent until a target was selected (`before=0`, `after=1`).
   - Replay audit/history copy rendered both `completed · new work` and `completed · no change` in the operator header and timeline.

2. No-Oban fallback verification
   - App boot emitted the manual-maintenance warning directing operators to `mix mailglass.reconcile` and `mix mailglass.webhooks.prune`.
   - `mix mailglass.reconcile --tenant-id browser-tenant --batch-size 50` reported `scanned=5 linked=2 still_unmatched=3 tenant=browser-tenant Oban is not installed; run this task manually or from system cron for scheduled sweeps.`

### Gaps Summary

No gaps remain. The optional-Oban reconcile path now compiles and runs from a
consumer context, the highest-risk replay/reconcile seams are covered by
focused tests plus the no-optional-deps compile lane, and the prior human-only
wording/ergonomics checks now have direct evidence.

---

_Verified: 2026-05-05T20:13:32Z_
_Verifier: Claude (gsd-verifier)_
