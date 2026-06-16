---
phase: 103-verification-idempotent-closeout
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - mailglass_admin/docs/ui-baseline-scores.json
  - mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 103: Code Review Report

**Reviewed:** 2026-06-16T00:00:00Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the v1.11 "only-forward score ratchet" (RATCHET-01): a schema-2
`ui-baseline-scores.json` with `{prior, current}` blocks and the ExUnit gate
`ratchet_baseline_test.exs` that enforces meet-or-beat semantics with an
anti-vacuity guard.

The gate is broadly well-constructed: coverage and range tests iterate both
blocks, and the anti-vacuity guard lives in its own test (not `setup_all`), so a
guard failure surfaces loudly. However, the central ratchet comparison contains
a **silent-pass defect**: the `|| 0` fallback in `compare_baselines/2` makes the
regression check structurally unable to detect missing cells, delegating that
responsibility entirely to a *separate* test. That coupling is unstated and
fragile. There are also gaps in the anti-vacuity guard (it proves run_ids
differ, not that the data is genuinely fresh) and missing type-strictness
assertions that let a float or string slip through the comparison in edge cases.

## Critical Issues

### CR-01: `|| 0` fallback in `compare_baselines/2` lets a missing/typo'd cell pass the ratchet vacuously

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:94-95`

**Issue:** The comparison coerces missing cells to `0`:

```elixir
prior_score = get_in(prior, ["surfaces", surface, pillar, theme]) || 0
current_score = get_in(current, ["surfaces", surface, pillar, theme]) || 0
```

This makes the ratchet check incapable of detecting absent data:

1. **Missing prior cell** → `prior_score = 0`. Any current value (even a
   regression relative to the *intended* prior) satisfies `current_score < 0 ==
   false`. The cell silently passes.
2. **Missing current cell** → `current_score = 0`. This would correctly fail
   *most* of the time (`0 < prior_score`), but if `prior_score` is also absent
   it becomes `0 < 0 == false` → silent pass.
3. **Both missing (e.g. a renamed pillar or a typo in `@pillars` shared by both
   blocks)** → `0 < 0 == false` → the cell is silently skipped from the ratchet
   entirely.

The only thing preventing this from being exploited today is that the
coverage test at lines 46-58 independently asserts all 36 cells exist in each
block. But that protection is **incidental and unstated**: the ratchet function
itself has no integrity guarantee, and the two tests share the same
`@surfaces/@pillars/@themes` module constants. A typo or rename in those
constants would corrupt *both* the coverage test and the ratchet in the same
direction — the coverage loop would check the wrong (matching, present) keys and
pass, and the ratchet would skip the real (now-orphaned) cells. The gate would
go green while silently comparing nothing.

This is the exact failure class the phase set out to prevent ("any way the gate
could silently pass when it should fail").

**Fix:** Make `compare_baselines/2` fail-closed on missing data instead of
coercing to `0`. Either assert presence inside the loop, or carry a distinct
sentinel that forces a failure:

```elixir
defp compare_baselines(prior, current) do
  problems =
    for surface <- @surfaces, pillar <- @pillars, theme <- @themes do
      prior_score = get_in(prior, ["surfaces", surface, pillar, theme])
      current_score = get_in(current, ["surfaces", surface, pillar, theme])

      cond do
        is_nil(prior_score) or is_nil(current_score) ->
          "#{surface}.#{pillar}.#{theme}: missing cell " <>
            "(prior=#{inspect(prior_score)}, current=#{inspect(current_score)})"

        current_score < prior_score ->
          "#{surface}.#{pillar}.#{theme}: #{prior_score} → #{current_score} (REGRESSION)"

        true ->
          nil
      end
    end
    |> Enum.reject(&is_nil/1)

  assert problems == [],
         "Ratchet violations (#{length(problems)}):\n" <> Enum.join(problems, "\n")
end
```

This removes the silent-skip path and makes the ratchet self-sufficient rather
than dependent on a sibling test's iteration constants.

## Warnings

### WR-01: Anti-vacuity guard only checks run_id inequality, not that current data is genuinely fresh

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:80-82`

**Issue:** The guard asserts `b["prior"]["run_id"] != b["current"]["run_id"]`.
This proves the *labels* differ, not that the `current.surfaces` block was
actually re-measured. A maintainer could copy `prior.surfaces` verbatim into
`current.surfaces`, bump only the `run_id` string, and the guard passes — every
cell trivially meets-or-beats itself. The guard's stated purpose ("the re-score
was not promoted; this would be a vacuous self-comparison") is only half
enforced: it catches a forgotten `run_id` bump but not a forgotten *re-score*
with a fresh `run_id`. The most likely human error (rename the run, forget to
re-run the scorer) defeats it.

**Fix:** This is partly inherent (you cannot prove an LLM re-scored from a JSON
file alone), but strengthen the guard so a pure copy is at least *visible*. For
example, assert that the surfaces blocks are not byte-identical, which forces an
intentional acknowledgement when prior and current legitimately match:

```elixir
refute b["prior"]["surfaces"] == b["current"]["surfaces"],
       "current.surfaces is identical to prior.surfaces — re-score appears to be " <>
         "a verbatim copy, not a fresh measurement (run_id differs but data does not)."
```

Note this is a real tradeoff: a legitimately unchanged re-score (no cell moved)
would trip it. If that is an expected steady state, document the override path
explicitly rather than leaving the guard weaker than its docstring claims.

### WR-02: Ratchet comparison does not assert integer type; a float or string could pass or crash

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:97`

**Issue:** `current_score < prior_score` relies on both being integers. The
coverage test guarantees presence and the range test guarantees membership in
`1..4` — but `score not in 1..4` (line 65) is the *only* type gate, and it runs
as a separate test. Term ordering in Elixir means `<` never raises, so a
malformed value (e.g. a JSON string `"4"` that slipped past a weakened range
test, or `nil` coerced to `0`) compares by type-order rules rather than numeric
value and could yield a misleading pass/fail. The ratchet function should not
assume the range test ran first; tests are independent and could be reordered or
selectively run (`mix test --only`).

**Fix:** Assert integer-ness at the point of comparison, or have
`compare_baselines/2` reject any non-integer cell the same way it rejects a
regression. Combined with the CR-01 fix, add an `is_integer/1` branch to the
`cond`.

### WR-03: Tests are interdependent but structured as independent — running a subset hides the gate

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:46-108`

**Issue:** The full gate's correctness depends on all four tests running
together: the ratchet test (line 78) only behaves correctly because the coverage
test (line 46) and range test (line 60) ran and would have failed first. But
ExUnit allows `mix test --only` / line-targeted runs, and `async: true` means
ordering is not guaranteed. Anyone running just `test "only-forward ratchet"` in
isolation gets a green result that does *not* actually validate coverage or
range — the `|| 0` fallback (CR-01) ensures it passes regardless. The "gate" is
only a gate when the whole file runs.

**Fix:** Make the ratchet test self-contained (see CR-01 and WR-02), so it
validates presence, range, and ordering on its own. Defense-in-depth: the gate
should hold even when run in isolation.

### WR-04: `setup_all` uses `Jason.decode!` and `File.read!` which raise outside the assertion machinery

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:37`

**Issue:** `Jason.decode!(File.read!(@scores_path))` raises a raw
`Jason.DecodeError` / `File.Error` on malformed or unreadable JSON. While this
*does* fail the suite (so the gate does not silently pass), it bypasses the
carefully-worded remediation messages the rest of the file invests in (the
`File.exists?` assert immediately above it, lines 32-35, gives a helpful
message, then line 37 throws an opaque decode error if the JSON is corrupt).
This is a robustness/DX gap, not a silent-pass — a truncated or invalid JSON
fails loudly but unhelpfully.

**Fix:** Wrap the decode and surface a guided message:

```elixir
baseline =
  case Jason.decode(File.read!(@scores_path)) do
    {:ok, data} -> data
    {:error, err} ->
      flunk("ui-baseline-scores.json is not valid JSON (#{Exception.message(err)}) — " <>
            "re-run the D-07 scoring step to regenerate it.")
  end

{:ok, baseline: baseline}
```

## Info

### IN-01: Comment about `if false` / Phase 95 hook point is now stale

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:87-90`

**Issue:** The comment block says "In Phase 95 this function exists but is never
called" and "Phase 103 only ADDS the call site." Now that Phase 103 has shipped
and the call site is live (line 84), this archaeological note describes a state
that no longer exists in the file. It risks confusing a future reader into
thinking the function is still dormant.

**Fix:** Trim to a present-tense description of what the function does, or move
the historical note to the phase SUMMARY where provenance belongs.

### IN-02: JSON `prior` block duplicates `deliveries` and `inbound` surfaces verbatim

**File:** `mailglass_admin/docs/ui-baseline-scores.json:8-23`

**Issue:** In the `prior` block, the `deliveries` (lines 8-15) and `inbound`
(lines 16-23) surfaces are byte-identical across all six pillars and both
themes. This is plausibly a real measurement coincidence (both scored
3/4/4/3/4/3), but exact duplication across two distinct surfaces is a mild smell
worth a sanity check — it can also indicate a copy-paste during seeding rather
than independent scoring. Not a defect in the gate logic.

**Fix:** No code change required. Confirm during the next re-score that the two
surfaces are genuinely scored independently; if they always co-move, consider
documenting why.

---

_Reviewed: 2026-06-16T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
