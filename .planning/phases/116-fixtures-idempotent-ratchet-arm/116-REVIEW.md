---
phase: 116-fixtures-idempotent-ratchet-arm
reviewed: 2026-06-20T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - mailglass_admin/docs/axe-baseline.json
  - mailglass_admin/docs/ui-baseline-scores.json
  - mailglass_admin/e2e/axe-baseline.spec.js
  - mailglass_admin/e2e/gallery-matrix.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
  - mailglass_admin/mix.exs
  - mailglass_admin/package-lock.json
  - mailglass_admin/package.json
  - mailglass_admin/priv/static/app.css
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/test/mailglass_admin/axe_baseline_test.exs
  - mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs
  - mailglass_admin/test/mailglass_admin/persona_cohort_test.exs
  - mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs
  - mailglass_admin/test/support/operator_fixtures.ex
  - reference/demo_app/assets/e2e/cohort.spec.js
  - reference/demo_app/lib/mailglass_demo/demo_data.ex
  - reference/demo_app/mix.exs
  - reference/persona_spec/personas.ex
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 116: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Phase 116 ("fixtures-idempotent-ratchet-arm") wires a single-source-of-truth
persona cohort spec into three materializers (demo seed, admin test-support,
gallery specimens), arms an axe-violation ratchet, and adds an executable
Bucket-A coverage manifest. The prior WR-01..WR-04 fixes hold: the axe producer
generates a per-invocation unique `run_id` (axe-baseline.spec.js:270), refuses to
write a `current.run_id` equal to the committed `prior.run_id` (lines 277-283),
the persona drift-guard fail-closed test now drives the real `materialized ==
spec_bearing` comparison through shared helpers (persona_drift_guard_test.exs:99-136),
and the axe producer throws on a required overlay that won't open
(openOverlay/openDeliveries/openInbound).

The defects below are concentrated where the phase's own thesis lives: artifact
**idempotency/determinism** and **ratchet honesty**. The most material finding
is that the committed `current` axe block in `docs/axe-baseline.json` could not
have been produced by the committed producer — its `run_id` format does not match
the producer's output — so the "current" half of the ratchet is a hand-authored
placeholder, not a measured scan. Several manifest/coverage citations also assert
properties their cited guards do not actually enforce, which weakens the
fail-closed contract the phase is built to provide.

No blocking security or data-loss defects were found. Generated bundles
(`package-lock.json`, `priv/static/app.css`) were noted as generated and not
style-reviewed.

## Warnings

### WR-01: Committed `current` axe baseline was not produced by the committed producer

**File:** `mailglass_admin/docs/axe-baseline.json:69`
**Issue:** The committed `current.run_id` is `"axe-2026-06-20-phase-116"`. The
producer that owns this block generates the run_id as:

```js
const runId = `axe-${new Date().toISOString().replace(/[:.]/g, "-")}`;
```

(axe-baseline.spec.js:270), which yields `axe-2026-06-20T14-32-07-123Z`-shaped
strings carrying a full ISO timestamp. The committed value embeds a hand-typed
milestone label (`-phase-116`) and no timestamp, so it cannot have come from a
real `PERSIST_AXE_BASELINE=1` run — it was authored by hand. The `current`
violations block is also byte-identical to `prior` (verified: every cell is
`total: 1` with the same rule-id). This means the "current" half of the ratchet
is a placeholder rather than a measured scan, defeating the point of a
prior→current ratchet for this commit: a regression introduced now would not be
caught because `current` was never actually measured against the live surfaces.
The anti-vacuity guard (`prior.run_id != current.run_id`,
axe_baseline_test.exs:93) passes only because the two were given different
hand-typed labels.
**Fix:** Regenerate the baseline from the live surfaces so `current` reflects a
real scan:

```bash
cd mailglass_admin && PERSIST_AXE_BASELINE=1 \
  npm run test:operator-browser -- axe-baseline.spec.js
```

Commit the resulting `current` block (whose `run_id` will carry a real
timestamp). If `prior` and `current` are legitimately equal, that is fine — but
`current` must still be a producer output, not a hand-edited clone, or the
ratchet is comparing nothing measured.

### WR-02: Bucket-A `A16-axe` cites a "system cell <= dark cell" property that no guard enforces

**File:** `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs:126`
**Issue:** The manifest row is
`%{id: "A16-axe", desc: "Axe WCAG 2.2 AA baseline (system cell <= dark cell)", guard_kind: :axe, locator: "axe-baseline.json", status: :live}`.
The `:axe` citation test (lines 246-263) only asserts that the literal string
`"axe-baseline.json"` appears in `axe_baseline_test.exs` and that three files
exist. It does **not** verify any system-vs-dark parity. Inspection of both
`axe_baseline_test.exs` and `axe-baseline.spec.js` confirms there is no
`system <= dark` assertion anywhere — `compare_axe/2` only ratchets each cell
against its own prior value. So Bucket-A defect A16 (system-parity variant) is
marked `:live` on a guard that proves a weaker property than the row describes.
This is the "STALE / vacuous CITATION" failure mode the manifest's own moduledoc
(lines 18-19) claims to prevent.
**Fix:** Either (a) add a real assertion to `axe_baseline_test.exs` that for each
surface `current.violations[surface]["system"].total <= ...["dark"].total` (and
per-rule), then keep the citation; or (b) correct the `A16-axe` `desc` to state
only what the guard checks (a fail-closed prior→current axe ratchet that includes
the system cell) so the ledger does not overclaim.

### WR-03: `compare_axe` per-rule diff tolerates a `nil`/missing rules map under a flat total

**File:** `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs:218`
**Issue:** `cc["rules"] || %{}` silently coerces a missing/`nil` current rules map
to empty. The shape test (lines 68-88) runs only over committed JSON, so it does
not guard a future producer regression. If a producer bug emitted a cell as
`{total: 2, rules: null}`, the comparator's rising-total branch (line 210) is the
only thing that could catch it — and only if the total actually rose. A cell that
went `{total: 2, rules: {color-contrast: 2}}` → `{total: 2, rules: null}` (same
total, lost rule detail) passes clean, masking a rule swap. The per-rule loop also
iterates `cc["rules"]` only, so a prior rule absent from current is never examined
(benign for a ratchet, but combined with the coercion it makes "rules became null"
indistinguishable from genuine improvement). Not a live failure today (committed
data is well-formed) but it weakens the fail-closed guarantee the moduledoc
advertises.
**Fix:** Fail closed when a present cell has a non-map `rules` under a non-zero
total:

```elixir
true ->
  cond do
    not is_map(cc["rules"]) ->
      "#{surface}.#{theme}: current rules map missing/non-map (cannot diff)"
    true ->
      # ... existing per-rule diff ...
  end
```

### WR-04: Demo fjordline materializer uses raw `utc_now`, bypassing the deterministic seed anchor

**File:** `reference/persona_spec/personas.ex:175`
**Issue:** The demo `reset!/0` establishes a process-stored seed anchor
(`Process.put(@anchor_key, DateTime.truncate(DateTime.utc_now(), :second))`,
demo_data.ex:25) so all northstar timestamps are anchor-relative via
`minutes_ago/1`. The moduledoc (demo_data.ex:14-18) states determinism "is carried
by IDs/counts/offsets ... never by absolute timestamps." But the fjordline persona
is materialized by `Personas.materialize!/2`, which computes its own
`occurred_at = DateTime.truncate(DateTime.utc_now(), :second)` (personas.ex:175)
instead of reading the demo anchor, and then folds `DateTime.to_unix(occurred_at)`
into the event `idempotency_key` (personas.ex:211). So the seeded fjordline event
key is tied to an absolute wall-clock second that diverges from the rest of the
seed's anchor-relative timestamps, and from the admin materializer (which uses
`hours_ago(1)`, operator_fixtures.ex:231-236). The cohort spec is the single source
of truth for *values* but not for *time origin* — the same persona lands at
unrelated instants across the two materializations, the inconsistency this phase's
"idempotent fixtures" thesis is meant to eliminate.
**Fix:** Thread the time origin through the materializer rather than re-reading the
clock inside `Personas`. Pass an `occurred_at`/anchor argument into
`seed!/1` → `materialize!/2` (demo passes its anchor; admin passes `hours_ago(1)`)
so all three materializations share one explicit origin.

### WR-05: Persona materializers use a positional catch-all clause that silently mis-materializes unknown payload kinds

**File:** `mailglass_admin/test/support/operator_fixtures.ex:215`
**Issue:** `materialize_persona!/1` dispatches on map shape: `%{payload: %{kind:
:no_deliveries}}`, `%{payload: %{kind: :lifecycle}}`, then a bare catch-all
`%{name: name, payload: payload}` (line 215) that assumes the fjordline
single-delivery shape. The catch-all is positional: any future persona added to
`spec/0` with a new `payload.kind` (or a typo'd kind) falls into the fjordline
branch and is materialized as a fjordline-style delivery — or crashes mid-insert on
a missing `payload.recipient`/`payload.long_delivery_id`. `Personas.materialize!/2`
(personas.ex:174) has the identical positional risk for its `:fjordline` clause.
The drift-guard checks tenant_id presence, not that each persona materialized via
its intended branch, so a mis-dispatch could pass the guard.
**Fix:** Match the kind explicitly and let an unknown kind raise:

```elixir
defp materialize_persona!(%{name: name, payload: %{kind: :single_delivery} = payload}) do
  # ... existing fjordline body ...
end
# no catch-all — an unknown payload.kind raises FunctionClauseError (fail-closed)
```

## Info

### IN-01: `bucket_a_coverage_test.exs` A24 `do: "—"` citation is brittle to gate reformatting

**File:** `mailglass_admin/test/mailglass_admin/bucket_a_coverage_test.exs:157`
**Issue:** The A24 `:grep_gate` locator is the literal `do: \"—\"`, matched verbatim
against `check-conformance.sh` (test line 218). The script contains `do: "—"` inside
STATCARD-GATE (check-conformance.sh:143), so it passes today — but the citation
depends on exact spacing surviving the shell pattern. A whitespace-only edit to that
gate (e.g. `do:"—"`) would break the citation and surface as a confusing
"STALE CITATION (A24)" failure unrelated to any real regression.
**Fix:** Cite the gate by its stable name (`STATCARD-GATE`) like the other rows, or
pin the `do: "—"` token with a comment in the shell script so an editor knows not to
reformat it.

### IN-02: `gallery_intends_literal?` state strings are duplicated, uncross-checked, in the matrix spec

**File:** `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs:274`
**Issue:** `@fjordline_specimen_states` keys on state strings (e.g.
`"fjordline-long-id"`) that are also hardcoded as testid suffixes in
`gallery-matrix.spec.js` STRESS_CELLS (lines 48-58). The two lists are maintained
independently with no cross-check. If the gallery drops a specimen state, the matrix
spec fails at runtime, but the drift-guard (reading only `gallery_live.ex`) silently
relaxes that literal's byte-consistency requirement — the same regression surfaces in
two unrelated places, or not at all in the guard.
**Fix:** Add a small assertion that every fjordline state in `@fjordline_specimen_states`
appears in the matrix STRESS_CELLS list (or derive one from the other) so a dropped
specimen fails one obvious place.

### IN-03: ICON-EXISTS-GATE cannot distinguish "zero icons used" from "scan found nothing"

**File:** `mailglass_admin/scripts/check-conformance.sh:156`
**Issue:** `grep -rhoE 'hero-[a-z0-9-]+' "$LIB" ... | sort -u > "$used_icons"` under
`set -euo pipefail`. `grep` exits non-zero on zero matches; the pipe masks that exit,
so an empty `used_icons` reads as "no missing icons" and the gate passes. The
BASH_SOURCE anchoring + dir-exists assert (lines 22-24) mitigates the wrong-cwd case,
but the gate still cannot tell a genuinely icon-free lib from a failed scan — the same
vacuity class the script's own comments flag elsewhere.
**Fix:** After building `used_icons`, assert it is non-empty:
`[[ -s "$used_icons" ]] || { echo "FAIL: ICON-EXISTS-GATE — zero hero-* usages scanned (path/scan error)" >&2; exit 2; }`.

### IN-04: `axe-baseline.json` `prior.run_id` is a hand-typed label, eroding run_id provenance

**File:** `mailglass_admin/docs/axe-baseline.json:4`
**Issue:** `prior.run_id` is `"2026-06-20-phase-116-axe"` — a hand-authored label, not
a producer timestamp. The producer preserves `existing.prior` verbatim
(axe-baseline.spec.js:300), so `prior` is human-managed during a re-baseline by
design — but pairing a hand-typed `prior` with a hand-typed `current` (WR-01) means
*neither* committed block traces to a producer run, removing the audit trail the
run_id exists to provide.
**Fix:** When promoting `current → prior` (the producer comment assigns this to plan
116-06), copy the previous real `current.run_id` (a producer timestamp) into
`prior.run_id` rather than typing a milestone string, so both blocks always trace to
a producer run.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
