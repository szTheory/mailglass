---
phase: 116-fixtures-idempotent-ratchet-arm
reviewed: 2026-06-20T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - reference/persona_spec/personas.ex
  - reference/demo_app/lib/mailglass_demo/demo_data.ex
  - reference/demo_app/mix.exs
  - reference/demo_app/assets/e2e/cohort.spec.js
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/test/support/operator_fixtures.ex
  - mailglass_admin/test/mailglass_admin/persona_cohort_test.exs
  - mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs
  - mailglass_admin/test/mailglass_admin/axe_baseline_test.exs
  - mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs
  - mailglass_admin/e2e/axe-baseline.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/gallery-matrix.spec.js
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 116: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Phase 116 is test-infrastructure, fixtures, and dev-only UI: a multi-tenant persona
stress cohort with a fail-closed drift-guard, a WCAG 2.2 AA axe baseline + comparator,
Playwright structural/interaction gates, a widened gallery, a 24-defect Bucket-A
coverage manifest, and promoted aesthetic+axe baselines. The work is careful and
well-documented, with most gates correctly designed to fail closed.

No BLOCKER/Critical defects: there are no security holes, data-loss paths, or
crashes. The append-only / no-PII / structured-error conventions are respected, and
the FROZEN baselines (`reference/demo_app`, `host_app`) were not destabilized in any
committed lockfile.

The findings that matter are all about *gate honesty* — places where a ratchet or
drift-guard can pass vacuously, silently flip a comparator test red on a benign
re-run, or assert a tautology instead of the property it claims to prove. For a phase
whose entire deliverable is "idempotent, fail-closed gates," these are real Warnings:
a gate that lies is worse than no gate. The Info items are minor consistency notes on
dev-only surfaces.

## Warnings

### WR-01: Axe producer's hardcoded run_id collides with the committed `prior.run_id` on a same-day re-run

**File:** `mailglass_admin/e2e/axe-baseline.spec.js:233`
**Issue:** The producer derives the fresh `current` run_id as a date-stamped literal:

```js
const runId = `${new Date().toISOString().slice(0, 10)}-phase-116-axe`;
```

The committed baseline (`docs/axe-baseline.json`) now has
`prior.run_id = "2026-06-20-phase-116-axe"` (plan 116-06 promoted the producer's
output into `prior`) and `current.run_id = "axe-2026-06-20-phase-116"` (hand-assigned
a *different* shape in 116-06 to dodge the collision). If anyone re-runs the producer
with `PERSIST_AXE_BASELINE=1` on 2026-06-20, it writes `current.run_id =
"2026-06-20-phase-116-axe"` — byte-identical to the committed `prior.run_id`. The
ExUnit anti-vacuity guard (`axe_baseline_test.exs:93`,
`b["prior"]["run_id"] != b["current"]["run_id"]`) then fails the suite. The producer's
output format and the committed shape have already diverged (`-phase-116-axe` vs
`axe-...-phase-116`), so the "regenerate the baseline" command documented in the spec
header and in `axe_baseline_test.exs:13` is no longer round-trippable without a manual
edit. This is exactly the kind of silent, dated, milestone-pinned literal a future
re-baseline will trip over.
**Fix:** Make the run_id unique per invocation and decoupled from the milestone date,
e.g. append a timestamp/uuid suffix and drop the hardcoded `phase-116`:

```js
const runId = `axe-${new Date().toISOString().replace(/[:.]/g, "-")}`;
```

and have the producer *never* emit a run_id that can equal the existing `prior.run_id`
(read `existing.prior.run_id` and assert inequality before writing).

### WR-02: Persona drift-guard "fails closed" test is a tautology — it never exercises the guard

**File:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs:110-132`
**Issue:** The test named "adding a persona to spec() without materializing it fails
closed" does not add a persona to `spec()` or run the real guard. It builds a
throwaway list by appending `"phantom-persona"` to the spec-derived names *in the test
body*, then asserts:

```elixir
refute Enum.sort(drifted_spec_bearing) == Enum.sort(materialized)
```

`drifted_spec_bearing` always contains `"phantom-persona"` and `materialized` never
will, so this `refute` is true by construction regardless of how (or whether) the
production drift-guard behaves. It proves the local `==` operator works, not that
`OperatorFixtures.seed_persona_cohort!/0` plus the real assertion in the sibling test
("deliveries-bearing personas in the spec are exactly the ones materialized") actually
fail closed when `spec/0` gains an unmaterialized persona. A reviewer reading the test
name would believe the fail-closed property is covered; it is not.
**Fix:** Drive the real guard with a genuinely-drifted spec. Either inject a stub spec
provider, or assert that the production comparison
(`materialized == spec_bearing`) would raise — e.g. capture the comparison the guard
uses and prove that a spec with an extra bearing persona but unchanged DB makes it
unequal. At minimum, rename the test so it does not overstate what it verifies.

### WR-03: Gallery drift-guard intent heuristic ignores its `label` argument — all four literals share one coarse trigger

**File:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs:202-209,229-231`
**Issue:** `gallery_intends_literal?(gallery_src, _label)` discards the per-literal
`label` and returns `String.contains?(gallery_src, "fjordline-aps")` for *every*
literal. The caller then also gates on `String.contains?(gallery_src, "fjordline")`.
Net effect: the moment the gallery mentions `"fjordline-aps"` anywhere (it does, in
several captions), the byte-consistency assertion activates for all four literals
simultaneously and stays active. That means the guard cannot distinguish "the gallery
mirrors the long-id specimen" from "the gallery mirrors the CJK name specimen" — if a
future edit drops one specimen's value but keeps the `"fjordline-aps"` caption token,
the guard still demands *all four* values be byte-present and will fail on the wrong
one, or (if the dropped value was never required) pass for the wrong reason. The
heuristic is advertised in the docstring as per-label ("if the gallery references the
persona-namespaced value") but is implemented as a single global trigger.
**Fix:** Tie the intent signal to a per-literal namespaced testid/state rather than the
shared caption token, e.g. check for the specific `gallery-fjordline_stress-fjordline-long-id`
testid when `label == :long_delivery_id`, so each literal's presence is governed
independently and a dropped specimen is detected precisely.

### WR-04: Axe producer best-effort overlay open can silently under-count violations and still promote the baseline

**File:** `mailglass_admin/e2e/axe-baseline.spec.js:154-160,98-114`
**Issue:** `openOverlay` swallows *all* errors from the opener
(`catch (_err) { /* scan the surface alone */ }`). The opener does the row click,
detail-column wait, replay-open click, and `[role=dialog]` assertions. If any of those
break (a renamed testid, a fixture with no replayable row, a timing regression), the
producer silently scans the surface *without* the overlay, measures fewer failing
nodes, and — under `PERSIST_AXE_BASELINE=1` — happily writes that lower count as the
new `current`. Because the ratchet is "meet-or-beat," a silently-lowered baseline then
*tightens* the floor: a later legitimate run that does open the overlay reads as a
regression, OR (worse) a genuine new overlay violation is masked because the baseline
was captured overlay-free. The fold of overlay violations into the surface (D-03) is
the whole point of the producer, and it is exactly the part that can vanish without a
trace. This is a non-deterministic gate input.
**Fix:** Distinguish "this surface legitimately has no overlay" (preview) from "the
overlay open failed unexpectedly." For deliveries/inbound, let the opener failure throw
(fail the producer test) rather than catching unconditionally, or record a per-cell
`overlay_opened: true|false` flag in the JSON and assert it stays `true` for the two
scrim-backed surfaces so an overlay-free scan cannot be promoted unnoticed.

## Info

### IN-01: `fjordline` persona event uses wall-clock `utc_now`, diverging from the demo's seed-anchor determinism convention

**File:** `reference/persona_spec/personas.ex:175,205,209`
**Issue:** `materialize!/2` for fjordline-aps stamps `occurred_at` /
`last_event_at` with `DateTime.utc_now()` truncated, not the demo's
`@anchor_key`-based `minutes_ago/1`. `demo_data.ex:14-18` explicitly documents that the
northstar seed ages out of the operator recency windows by an anchored offset, and that
"Determinism is carried by IDs/counts/offsets ... never by absolute timestamps." The
fjordline delivery therefore always renders as "now," inconsistent with the rest of the
cohort. This is harmless for the cohort assertions (they key off IDs/values, not
recency) but is a determinism-convention drift worth a comment or alignment.
**Fix:** Either thread the demo seed anchor into `seed!/1`, or add a short comment in
`personas.ex` noting the intentional always-fresh stamping and why it does not need the
anchor (the cohort tests never assert on fjordline recency).

### IN-02: Demo landing-page summary count now silently includes the fjordline-aps delivery while labeled with the northstar tenant

**File:** `reference/demo_app/lib/mailglass_demo/demo_data.ex:39-47`
**Issue:** `summary/0` returns `tenant_id: @tenant` ("northstar") next to
`deliveries: Repo.aggregate(Delivery, :count)`, which is a *global* count across all
tenants. Phase 116 adds the fjordline-aps delivery, so the dev landing page's
"northstar … N deliveries" stat is now off by one (counts a non-northstar row). It is a
dev-only cosmetic page and the aggregate was already global pre-116, so this is minor —
but the new cohort makes the tenant label visibly inconsistent with the number.
**Fix:** Scope the aggregate to `@tenant` (`where: d.tenant_id == @tenant`) if the card
is meant to describe northstar, or relabel the card as a global total.

### IN-03: `mailglass_admin/mix.exs` inbound-dep comment vs. constraint drift (≥ doc accuracy)

**File:** `mailglass_admin/mix.exs:102-106,164-184`
**Issue:** The dep comment at lines 102-106 describes the inbound sibling as "FLOATING
(`~> 0.2`, never `==`)", but the actual constraint (line 180) and the surrounding block
(lines 164-172) are `~> 1.1`. The two comments disagree about the floating line. The
116-02 SUMMARY also restates the stale `~> 0.2`. Not a functional defect (the live
constraint is `~> 1.1`), but the contradictory inline doc is a future-maintainer trap
in a file whose entire purpose is hand-maintained version pins.
**Fix:** Update the line 102-106 comment to `~> 1.1` to match the live constraint and
the line 164-172 block.

### IN-04: `bucket_a_coverage_test.exs` declares a `:playwright_testid` guard kind that no manifest row uses

**File:** `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs:14,236-244`
**Issue:** The module documents and tests a `:playwright_testid` guard kind, but no row
in `@manifest` carries `guard_kind: :playwright_testid`. The corresponding test
("every :playwright_testid citation literal physically exists") iterates an empty
comprehension and passes vacuously. Harmless dead branch today, but it is precisely the
"vacuous pass" shape this manifest is built to prevent, and it can mask a future typo
(someone adds a `:playwright_testid` row with a stale testid and the dedicated test
still appears to cover it).
**Fix:** Either drop the unused guard kind + its test, or add an assertion that at least
one row exercises it (or that the kind is intentionally reserved), so the empty
iteration cannot silently certify a future stale citation.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
