---
phase: 177-readable-health-and-coherent-account-navigation
plan: "11"
subsystem: testing
tags: [prohibition-contract, mutation-proof, phase-gate, validation, playwright, d-52]
status: complete

requires:
  - phase: 177-01
    provides: ReturnContext, session whitelists
  - phase: 177-04
    provides: Health column markup
  - phase: 177-06
    provides: Account scope group
  - phase: 177-10
    provides: demo return seam
provides:
  - "phase177_prohibition_contract_test.exs: 16 mutation-proven rules (60 tests) in the merge-blocking admin lane"
  - "177-AUTOMATION.md: contract, mutation log, reduced motion, help tier, lane placement, gate run, demo outcomes"
  - "177-VALIDATION.md signed off (nyquist_compliant and wave_0_complete true)"
  - "Open todo for the deferred in-Operator push_patch Account switch authorization gap"
  - "Real-browser privacy canary (P2 backstop) in the operator browser lane"
affects: [phase-177-verification, security-hardening-slice]

plan_head_before: 22f5b6b12bbacb6d96e21a5ca56262bfa17055fe
plan_head_after: c2c0926da1f086e41ed6fd7a05c2094ce25fd64c

actuals:
  tokens: 19000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Prohibition = detector returning a violation list + teeth test + clean-state test on real output + recorded source mutation"
    - "P3 allow-list removes each static phrase only as a complete phrase, so a longer phrase cannot hide behind it"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs
    - .planning/todos/2026-10-28-operator-account-switch-skips-host-auth.md
  modified:
    - mailglass_admin/e2e/phase177-return-navigation.spec.js
    - .planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md
    - .planning/phases/177-readable-health-and-coherent-account-navigation/177-VALIDATION.md
    - .planning/phases/177-readable-health-and-coherent-account-navigation/deferred-items.md

key-decisions:
  - "The docs rule scans README, CHANGELOG, docs/*.md, lib moduledoc and doc heredocs and the repository guides, and ignores negated statements (does not re-run) so an honest sentence never trips it"
  - "Pre-existing core, format, credo and axe failures were recorded with evidence and not fixed (scope boundary); STATE.md is not hand-edited to satisfy a stale contract test"
  - "P2 real-browser backstop added to the operator lane because the demo spec 177-10 shipped carries no canary assertion"

requirements-completed: ["OUTUX-06", "UXF-09", "UXF-10"]

coverage:
  - id: D1
    description: "Every Phase 177 must-NOT is a detector with a teeth test and a clean-state test on real output, and each was proven red by a temporary source mutation"
    requirement: "UXF-09"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs (60 tests, 0 failures; 17 describes)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Admin suite, bundle-equals-fresh-build, conformance and the contract file are green; the coupled Playwright set passes apart from three pre-existing axe timeouts"
    requirement: "OUTUX-06"
    verification:
      - kind: unit
        ref: "mix verify.support_contract.admin --seed 0 (1082 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "npm --prefix mailglass_admin run test:operator-browser -- <13 specs> (242 passed, 3 pre-existing failed, 1 guarded skip)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reference demo suite including the D-07 logged-out Fjordline return"
    requirement: "UXF-10"
    verification:
      - kind: integration
        ref: "cd reference/demo_app && MIX_ENV=test mix test --seed 0 (37 tests, 0 failures; phase177_navigation_test.exs 9)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Deferred push_patch Account switch authorization gap captured as an open todo and guarded from being documented as fixed"
    verification:
      - kind: unit
        ref: "phase177_prohibition_contract_test.exs#docs do not claim patch-time re-authorization"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-10-28
---

# Phase 177 Plan 11: Prohibition Contract and Phase Gate Summary

**Sixteen Phase 177 prohibitions are now violation-list detectors with teeth tests, clean-state tests on real rendered output and a recorded red source mutation each, and the phase gate ran green apart from failures that predate the phase.**

## Performance

- **Duration:** 45 min (2026-10-28 21:11 to 21:56 local)
- **Tasks:** 3 (one tracer, two auto)
- **Files:** 6 changed or created

## Accomplishments

- `phase177_prohibition_contract_test.exs`: 60 tests, 17 describes (one teeth block, 16 rules), `--warnings-as-errors` clean, `credo --strict` clean on the file. It runs inside `mix verify.support_contract.admin`, so it is merge-blocking.
- Every rule was proven red by mutating its owning source, then reverted (log below). `git status --porcelain -- mailglass_admin/lib mailglass_admin/docs mailglass_admin/CHANGELOG.md` was empty after each.
- `177-AUTOMATION.md` gained the contract, comparison result, reduced-motion section, help-tier record, `## Lane placement`, the gate run and the demo outcomes. `177-VALIDATION.md` is signed off.
- `.planning/todos/2026-10-28-operator-account-switch-skips-host-auth.md` captures the deferred gap (status open) without claiming it is fixed, and a contract rule forbids any doc from claiming it is.

## Task Commits

1. **Task 1 (tracer): P1 end to end** - `3d48289f`
2. **Task 2: P2-P9, Health, Back link and docs rules** - `77cc7d71`
3. **Task 3: gate evidence, validation sign-off, todo, browser spec fix** - `c2c0926d`

## Mutation log

Each row: mutation, then the red tests (run at `--seed 0`), then the revert (path-specific `git checkout`). All reverts confirmed with an empty `git status --porcelain` on `lib/`, `docs/` and `CHANGELOG.md`; the file ran 60 tests, 0 failures afterwards.

| Rule | Mutation | Red tests and failure line |
|---|---|---|
| P1 | `preview_live.ex` sidebar `SurfaceNav` given `scope={:account}` and a `Shell.account_context` header | P1 direct entry and P1 valid return: `left: ["Account control \"operator-account-context\" rendered on Preview", ... "<details> rendered in Preview chrome"]` |
| P2 | `preview_live.ex` page header renders `@return_context.tenant_id` | P2 canary and width patch: `zz-canary-7f3 appears 1 time(s) outside href attribute values`; also P3 |
| P3 | `preview_live.ex` subtitle gains `Previews use sample data.` | P3 direct and tampered: `provenance claim "\b(sample|demo|fake)\b"`; also P6 |
| P3 | `preview_live.ex` subtitle gains `for this Account` | P3 direct and tampered: `Account wording "\bAccounts?('s)?\b" outside the allow-list`; also P6 (exact allow-list, not a blanket pass) |
| P4 | `return_context.ex` adds `{"tenant_id", id}` to the Preview href | P4: `/ops/mail?tenant_id=tenant-b` |
| P5 | `surface_nav.ex` adds Preview to the scoped items | P5 operator and Preview, P5 shared nav, plus P4 and P9 |
| P6 | `preview_live.ex` `Renders` to `Shows` | P6: `/dev/mail/.../welcome_default?width=768` |
| P7 | `shell.ex` `length(options) >= 2` to `>= 1` | P7: `<details> rendered without a real choice` |
| P8 | `router.ex` Preview session map gains `"return_surface"` | P8 session maps: `session carries return_surface` |
| P8 | `preview_live.ex` `assign(:tenant_id, "acme")` | P8 assigns: `PreviewLive assigns :tenant_id` |
| P9 | `surface_nav.ex` description hard-coded to name Inbound | P9: `sidebar: description mentions Inbound but no Inbound link is rendered` |
| Health order | `operator_live.ex` `Enum.sort_by(& &1.count, :desc)` | Health order: `issue order depends on count` |
| Health severity | `health_overview.ex` appends `" critical"` when count > 5 | Health severity (`:ascending` seed) |
| Health deep link | `health_overview.ex` Inbound issue link set to `:if={false}` | both deep-link tests: `issue row operator-health-inbound-failed has no deep link` |
| Health reordering | `health_overview.ex` `order-2` on the observation group | Health reordering: `visual reordering utility "order-2" in the Health region` |
| Health live region | `health_overview.ex` `role="status"` on the notice | both persistent-notice tests |
| Back link | `preview_live.ex` tenant id appended to `return_label` (both navs) | Back link test; also P2 (two) and P3 |
| Docs | `docs/operator-trust.md` sentence claiming the switch re-runs host authorization | docs: `docs/operator-trust.md: ... re-runs host authorization on every patch.` |

## Gate run (details and commands in 177-AUTOMATION.md)

| Gate | Result |
|---|---|
| `mix verify.support_contract.admin --seed 0` | exit 0, 1082 tests, 0 failures, 1 excluded |
| Core `mix test --seed 0` | 2239 tests, 23 properties, **3 failures (pre-existing, below)**, 27 excluded, 7 skipped |
| Inbound `mix test --seed 0` | 480 tests, 3 properties, 0 failures |
| Demo `MIX_ENV=test mix test --seed 0` | 37 tests, 0 failures (lock clean before, restored after) |
| `scripts/check-conformance.sh` | clean |
| `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` | no drift |
| `mix format --check-formatted` | **fails on 10 pre-existing files**; no file this phase touched |
| `mix credo --strict` | **6 pre-existing findings**; none in a file this plan authored |
| 13 coupled Playwright specs, one run | 242 passed, **3 failed (pre-existing axe timeouts)**, 1 guarded skip |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Intermittent failure of the plan 177-10 tracer spec**
- **Found during:** Task 3 (re-running `phase177-return-navigation.spec.js` alone after adding the canary test)
- **Issue:** "Phase 177 tracer: Preview returns to the originating Account" failed about 1 run in 3. It clicked the Preview link before the operator LiveView had connected. The synthetic test endpoint has no `Plug.Parsers`, so the disconnected render sees no query params and mints a bare `/dev/mail` href (debug render: `selected_tenant_id` nil, `tenant_state` `:none` disconnected; the context-bearing href appears after connect). The full 13-spec run had passed it by timing.
- **Fix:** the test now waits for `[data-phx-main].phx-connected` before reading the link; title unchanged. 8 consecutive standalone runs passed and the final full run passed.
- **Files modified:** `mailglass_admin/e2e/phase177-return-navigation.spec.js`
- **Commit:** `c2c0926d`

**2. [Rule 2 - Missing critical] Real-browser P2 canary**
- **Found during:** Task 3 (the plan says real-browser confirmation of P2 rides the 177-10 demo return journey)
- **Issue:** `reference/demo_app/assets/e2e/phase177-return.spec.js` carries no canary assertion, so the claimed backstop did not exist.
- **Fix:** added "Phase 177 privacy canary: Preview shows the return id only inside hrefs" to the operator browser spec (320 and 1280; Back link href carries the id, nothing else in the serialized DOM, `innerText` or title does). Recorded in 177-AUTOMATION.md.
- **Files modified:** `mailglass_admin/e2e/phase177-return-navigation.spec.js`
- **Commit:** `c2c0926d`

### Plan gate commands that exit non-zero, with evidence

The plan's task 3 verify commands include `mix format --check-formatted`, `mix credo --strict`, a browser run with no failed count, and (via the orchestrator gotchas) the full core suite. Each reports failures that exist at the pre-phase commit `03e2cc35`, so they were recorded, not fixed (scope boundary), and deferred in `deferred-items.md`:

- **3 Playwright failures:** `axe-baseline.spec.js` "scan deliveries / light|dark|system" time out at `operator-replay-open` (confirmed at `03e2cc35` by plan 177-07).
- **10 unformatted files and 6 credo findings:** all in files with an empty `git diff 03e2cc35 HEAD`, except `endpoint_case.ex` `reset/2` whose Phase 177 clause adds 1 to a complexity that was already over the limit.
- **3 core failures:** `state_md_contract_test.exs` (two; STATE.md at `03e2cc35` already lacks `gh issue list` and `f733fc22`) and `phase_164_repository_truth_test.exs` (an untracked local `.gsd/.gitignore` containing `*` makes git ignore a path the test asserts is visible).

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical), plus the documented pre-existing failures. **Impact:** none on product code; one spec made deterministic and one real-browser backstop added.

## Authentication Gates

None.

## Known Stubs

None. Stub scan of the files created or modified found no placeholder text or empty data flowing to UI.

## Threat Flags

None. No new network endpoint, auth path, file access or schema change; the todo documents the existing T-177-25 gap (transferred).

## Issues Encountered

The deferred in-Operator `push_patch` Account switch authorization gap (T-177-25) remains open by design and is captured in `.planning/todos/2026-10-28-operator-account-switch-skips-host-auth.md`. The pre-existing failures above need their own owners.

## Next Phase Readiness

Phase 177 has all 11 summaries. OUTUX-06, UXF-09 and UXF-10 are proven by merge-blocking ExUnit (including the mutation-proven contract) plus passing browser evidence, with zero owner UAT. Ready for phase verification.

## Self-Check: PASSED

- Files found: the contract test, the todo, `177-AUTOMATION.md`, `177-VALIDATION.md`.
- Commits found on HEAD: `3d48289f`, `77cc7d71`, `c2c0926d`.
- `lib/`, `docs/`, `CHANGELOG.md`, `priv/static` and `reference/demo_app/mix.lock` are clean.
