---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 12
subsystem: credo-checks / optional-deps
tags: [egress-pii, credo, gen_smtp, gap-closure, TELE-06, IN-01]
requires:
  - "NoPiiInResponseBody check + path-gating (pre-existing from 45-09 family)"
provides:
  - "NoPiiInResponseBody catches WR-02 (differently-named error var) + WR-03 (two-step payload) egress leaks via the mandated bare-variable body-arg rule"
  - "gen_smtp available?/0 IN-01 doc note (proxy probe + :mimemail-via-decode/2-rescue)"
affects:
  - "lint-time enforcement of the 'No PII on egress' invariant on webhook + ingress surfaces"
tech-stack:
  added: []
  patterns:
    - "Credo body-arg dataflow heuristic: last-positional-arg bare-variable rule with a Jason-encoded carve-out set + def-head exclusion"
key-files:
  created: []
  modified:
    - credo_checks/no_pii_in_response_body.ex
    - test/mailglass/credo/no_pii_in_response_body_test.exs
    - lib/mailglass/optional_deps/gen_smtp.ex
decisions:
  - "Applied the MANDATED bare-variable body-arg rule (Option B) — it alone closes WR-03's two-step payload var"
  - "Layered Option A fragment broadening on top with the substring fragment \"err\" (matches err/error), correcting the plan's \"error\" suggestion which would not substring-match the var name `err`"
  - "Excluded def/defp heads sharing a sink name (e.g. `def send_json/3`) to avoid a function-definition false positive surfaced during GREEN"
metrics:
  duration: ~25m
  completed: 2026-05-23
  tasks: 2
  files: 3
  commits: 3
---

# Phase 45 Plan 12: Egress PII Guard Hardening (WR-02/WR-03) + IN-01 Summary

Broadened `NoPiiInResponseBody` to catch a changeset/error term bound to a differently-named variable (WR-02) and a payload assembled in a prior assignment then passed as a bare body variable (WR-03) on the gated egress surfaces — via the mandated bare-variable body-arg rule plus an `"err"` fragment — while preserving the static-map and Jason-encoded-body carve-outs and documenting the remaining multi-hop dataflow boundary; folded in the IN-01 `gen_smtp` `available?/0` doc note.

## What Was Built

### Task 1 — Mandated bare-variable body-arg rule (Option B) + docs

`credo_checks/no_pii_in_response_body.ex`:

- **Option B (mandated, the load-bearing change):** the LAST positional arg of a gated egress sink (`send_resp`/`send_json`/`put_resp_body`) is now treated as suspicious when it is a bare local variable — *unless* that variable name is in a per-file carve-out set of names bound to `Jason.encode!/encode`. A static map/binary literal is not a bare variable, so the legitimate closed-code body stays clean. This is what catches WR-03's two-step `payload = %{...}; send_json(conn, 500, payload)` shape, which no fragment-name list can reach.
- **Jason carve-out set:** `collect_jason_encoded_vars/1` prewalks the AST once collecting `var = Jason.encode!(...)` / `var = Jason.encode(...)` (qualified and bare) bindings; a body-position bare var whose name is in this set is the documented-safe encoded-binary shape and is not flagged.
- **Def-head exclusion:** `collect_def_head_sigs/2` records `{name, line}` for any `def`/`defp` whose name collides with a response sink (e.g. `def send_json(conn, status, payload)`), and the bare-variable rule skips those. Without this, the helper *definition* head (call-shaped AST) was a false positive — surfaced and fixed during GREEN.
- **Option A layered on top:** added `"err"` to `suspicious_fragments` (now `["reason", "changeset", "err"]`). Matched as a substring of the variable name, `"err"` catches both `err` and `error` used as an inline body FIELD (`%{detail: err}`, WR-02). Generic transport names `body`/`resp`/`payload` are still deliberately excluded.
- **Docs:** `@explanations` `check:` text and the top-of-file design-note comment now describe the bare-variable body-arg rule and explicitly state the remaining boundary — true multi-hop intra-function dataflow (a body arg that is neither a bare error-named var nor a directly-passed error/inspect/changeset term, assembled across several hops) is still out of scope.

### Task 2 — Regression tests + IN-01 gen_smtp doc note

`test/mailglass/credo/no_pii_in_response_body_test.exs`:

- **WR-02 regression:** `send_json(conn, 500, %{status: "error", detail: err})` (err = changeset) → exactly one issue.
- **WR-03 regression:** `payload = %{status: "error", detail: inspect(changeset)}` then `send_json(conn, 500, payload)` → exactly one issue (the mandated bare-variable rule catches the bare `payload` body var).
- The Jason-encoded `body` helper negative case is preserved and asserts `== []` (carve-out regression guard); the three existing positive cases and the out-of-path case are unchanged.

`lib/mailglass/optional_deps/gen_smtp.ex` (IN-01): `available?/0` `@doc` now notes it probes `:gen_smtp_client` as a PROXY for the `:gen_smtp` package, and that `:mimemail` absence is a distinct concern handled by `decode/2`'s `:undef` rescue, not this predicate. `available?/0` behavior unchanged.

## Plan Note (per <output>)

The MANDATED bare-variable body-arg rule (Option B) was applied. Fragment-name broadening (Option A) WAS layered on top, using the substring fragment `"err"`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Function-definition head false positive in the bare-variable rule**
- **Found during:** Task 1 GREEN (first run)
- **Issue:** A `def send_json(conn, status, payload)` head is structurally identical to a `send_json(...)` call, so the new bare-variable rule flagged the JSON-helper *definition* head (last arg `payload` is a bare var). This broke the existing "does NOT flag the JSON helper's generic send_resp(status, body)" negative test.
- **Fix:** Added `collect_def_head_sigs/2` + `def_head?/3` to record and exclude `def`/`defp` heads whose name collides with a sink (matched by `{name, line}`). The rule now fires only on real call sites.
- **Files modified:** credo_checks/no_pii_in_response_body.ex
- **Commit:** 11f2a58

**2. [Rule 1 - Bug] Corrected the Option A fragment from "error" to "err"**
- **Found during:** Task 1 GREEN
- **Issue:** The plan's interfaces suggested adding `"error"` to catch `err`/`error`. But the check matches `String.contains?(var_name, fragment)` — `"err"` does not *contain* `"error"`, so the WR-02 `err` var was not caught. The fragment must be a substring OF the variable name.
- **Fix:** Used `"err"` (substring-matches both `err` and `error`); documented the matching direction in the comment. Did NOT add `"e"` (would match nearly every identifier).
- **Files modified:** credo_checks/no_pii_in_response_body.ex
- **Commit:** 11f2a58

### Out-of-scope artifact (not committed)

`mix deps.get` (run locally to enable real test/credo verification) resolved several deps to newer in-range versions, churning `mix.lock`. This is unrelated to the plan (which does not touch dependencies); `mix.lock` was restored to its committed base before each commit and is NOT part of any commit in this plan.

## Toolchain Note

The plan flagged automated verification as "MISSING locally (toolchain caveat)", but Elixir 1.19.5 / OTP 28 + deps were available in the worktree, so RED/GREEN were verified for real rather than by source-proof alone:
- **RED:** the two new tests failed (`left: 0, right: 1`) before the check change; the 6 existing tests stayed green.
- **GREEN:** `mix test test/mailglass/credo/no_pii_in_response_body_test.exs` → 8 tests, 0 failures.
- **No new false positives on real code:** `mix credo --strict` → 376 files, 2788 mods/funs, found no issues, exit 0 (current `lib/mailglass/webhook/plug.ex` is clean).

## Verification Evidence

- `mix test test/mailglass/credo/no_pii_in_response_body_test.exs`: 8 tests, 0 failures.
- `mix credo --strict`: found no issues, exit 0.
- Doc terms grep (`bare variable|body-position|intra-function|multi-hop|dataflow`, excluding `#` lines): 8 matches.
- `suspicious_fragments: ["reason", "changeset", "err"]` — no `"body"`/`"resp"`/`"payload"`.
- IN-01: `grep -c "proxy\|:mimemail" gen_smtp.ex` = 9; `available?/0` still `Code.ensure_loaded?(:gen_smtp_client)`.

## No PII / API-stability check

- No PII introduced; the change tightens (not loosens) the egress PII guard.
- No public-API change: `available?/0` and `decode/2` behavior unchanged; the Credo check is dev/test-only tooling.
- No `.credo.exs` edit, no `included_path_prefixes`/`response_sinks` change, no GitHub-Action edits.

## Known Stubs

None. No placeholder values, no unwired data sources.
