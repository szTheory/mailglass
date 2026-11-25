---
phase: 179-compatibility-policy-status-map-and-brand-pin
plan: 04
subsystem: brand-trademark-gate
tags: [trademark, name-search, fail-closed-gate, announcement-gate, mutation-proof, elixir-script]

requires: []
provides:
  - ".planning/research/brand-v2-adoption/trademark-search.json: honest search record (overall caution, register_checked false, owner_override null, 16 stamped sources)"
  - "Mailglass.BrandTrademarkGate (scripts/brand_trademark_gate.exs): load/1, validate/1, decision/2, announcement_allowed?/1 (Phase 183 entry point) and /2 (pure), cli/1"
  - "TRADEMARK-SEARCH.md: findings, decision rule and a 15-minute owner register-search runbook with checked full URLs"
  - "30-test shape and invariant suite with planted fail-closed states, override control and a trademark-symbol scan, none reading the clock"
affects: [183-announcement-gate]

actuals:
  tokens: 14040
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Pure fail-closed gate: validate then blocked then expired then allow paths, date injected, one private clock helper behind a one-line wrapper"
    - "Evidence invariants in the validator: a clear or register_checked claim without register evidence is an invalid record, not a soft deny"
    - "Override control by mirrored constant: owner_override must equal @acknowledged_override in the same commit, and agent-named by values fail even when acknowledged"
    - "Gate module loaded in setup_all and called through apply/3 so --warnings-as-errors does not flag compile-time remote calls"

key-files:
  created:
    - scripts/brand_trademark_gate.exs
    - test/scripts/brand_trademark_gate_test.exs
    - .planning/research/brand-v2-adoption/trademark-search.json
    - .planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md
  modified: []

key-decisions:
  - "Gate semantics (research assumption A4 adopted): allowed only if overall is not blocked, today is before expires, and (overall is clear with register_checked true, or a populated owner_override); expiry applies to the override path too"
  - "The record reports the two RDAP domain registrations as caution sources and keeps register_checked false, because domain registries are not trademark registers"
  - "rdap_other (.dev, .io, .email, .org, .net, .co: no domain object) is recorded clear; the plan did not fix its outcome"
  - "Dates must be extended ISO 8601 (YYYY-MM-DD); the basic form 20261113, which Date.from_iso8601/1 accepts, is rejected so a hand-edited record cannot drift into it"
  - "Who authors an owner_override is not observable by a test, so the control is the mirrored constant plus an agent-name rejection, and the authorship rule is stated as a review rule in the runbook"

patterns-established:
  - "Every planted fail-closed state asserts its specific deny reason or issue tag, never a bare falsy result"
  - "A record that overclaims is invalid (a validator issue), so the always-run test goes red on the file, not only on the decision"

requirements-completed: [BRPOL-05]

coverage:
  - id: D1
    description: "trademark-search.json is committed with date, searcher, mark, variants, classes [9, 38, 42], overall caution, register_checked false, owner_override null, expires and 16 sources (url, outcome, tier, retrieved, note), at a path a milestone archive does not move"
    requirement: BRPOL-05
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs#the committed record loads and validates"
        status: pass
      - kind: other
        ref: "jq acceptance: overall caution, register_checked false, owner_override null, classes 9,38,42, uspto/tmview/wipo not_checked"
        status: pass
    human_judgment: false
  - id: D2
    description: "The gate denies by default and fails closed: missing, empty, null, array, malformed, wrong-schema, empty-sources, missing-key and non-ISO-date records each deny with their named reason; clear without evidence, a register claim without evidence and a blocked source under caution are invalid"
    requirement: BRPOL-05
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs#evidence invariants and fail closed on an unreadable or malformed record"
        status: pass
      - kind: other
        ref: "Mutation run section below: G1, G2, G4 and M3 each red with the named issue, restored, green"
        status: pass
    human_judgment: false
  - id: D3
    description: "Allow and deny paths are exact: clear plus register search allows, today equal to expires is expired, blocked is never overridable, a populated owner_override on caution allows until expiry, and decision/2 and announcement_allowed?/2 never read the clock"
    requirement: BRPOL-05
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs#decision: the allow and deny paths and purity"
        status: pass
      - kind: other
        ref: "Mutation run section below: M1 (expiry boundary) and M2 (blocked precedence) each red, restored, green; grep gates: 0 clock reads in the test, 1 in the script (private today/0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "An owner_override must be mirrored by an identical @acknowledged_override, and agent-named by values (searcher, automated, agent, claude) are rejected even when acknowledged; only the owner writes owner_override is a runbook review rule"
    requirement: BRPOL-05
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs#committed owner_override is owner-acknowledged and override control"
        status: pass
      - kind: other
        ref: "Mutation run section below: G5 red with the acknowledgement message, restored, green"
        status: pass
    human_judgment: false
  - id: D5
    description: "No trademark or registered-mark symbol appears in README, CHANGELOG, docs, guides or brandbook markdown while the record does not allow an announcement; the scan is proven against a planted tree"
    requirement: BRPOL-05
    verification:
      - kind: unit
        ref: "test/scripts/brand_trademark_gate_test.exs#no trademark symbol appears in markdown while the record does not allow an announcement and trademark-symbol scan has teeth"
        status: pass
      - kind: other
        ref: "Mutation run section below: G3 red naming docs/migration-policy.md:99, restored, green"
        status: pass
    human_judgment: false
  - id: D6
    description: "TRADEMARK-SEARCH.md holds the queries, URLs, retrieval dates and findings plus a numbered owner runbook with each URL's HTTP status checked on the execution date; the register searches (USPTO, TMview, WIPO, image, counsel) remain an owner hand-off"
    requirement: BRPOL-05
    verification:
      - kind: other
        ref: "grep acceptance criteria on TRADEMARK-SEARCH.md (uspto url, icann .app url, not legal advice, Remaining for a human x1, METHODOLOGY.md, no carve-out citation, owner-only override rule)"
        status: pass
    human_judgment: true
    rationale: "The USPTO, TMview, WIPO, reverse-image and counsel steps are legal or otherwise unavailable checks an agent cannot run (METHODOLOGY.md line 9); the runbook is the hand-off and does not block the phase (D-23)"

duration: 17min
completed: 2026-11-14
status: complete
plan_head_before: 008e86ec51d9a9cfcc99f4e7bebe6ab9621861fb
plan_head_after: 7cec846aac65881e887eb6382e5e85210e993dcc
---

# Phase 179 Plan 04: Trademark Gate Summary

**Honest trademark and name search record (caution, registers not checked) behind a pure fail-closed announcement gate with evidence invariants, a clock-free 30-test suite proven by eight mutations, and a 15-minute owner runbook with checked URLs.**

## Performance

- **Duration:** 17 min wall clock (about 8 of those were the directory-scoped lane run under a load average of 15 to 26)
- **Started:** 2026-11-14T04:48:21Z
- **Completed:** 2026-11-14T05:05:42Z
- **Tasks:** 2
- **Files:** 4 created, 0 modified

## Accomplishments

- `trademark-search.json` records the search honestly: `overall: caution`, `register_checked: false`, `owner_override: null`, `expires` 2027-05-12, 16 sources. Hex, npm exact, PyPI, RubyGems, crates.io and six other TLD registries are clear; npm search, GitHub, Glama, the `.com` and `.app` registrations and the secondary aggregator are caution; USPTO, TMview, WIPO and image search are `not_checked`. No agent-written `clear` exists.
- Every agent-feasible check was re-run on the execution date with `curl`, not copied from the research: `mailglass-email-mcp` (0.0.1, published 2026-11-06), the two Glama connectors (`email.dygc/mailglass`, `email.dygc.mail/mail-glass`), `Mr-Anderson-403/MailGlass-v3.1`, `mailglass.com` (registered 2024-10-13, Cloudflare), `mailglass.app` (registered 2026-08-14, Namecheap, serves an "Email Data" sign-in page), and the dead GLASMAIL mark (serial 74299521, class 038, Dead/Cancelled 2000-12-23, found by a `glasmail` search on the secondary aggregator).
- `Mailglass.BrandTrademarkGate` is pure. `validate/1` makes overclaiming impossible to commit: a `clear` without a register search, a `register_checked` with a register still `not_checked`, and a `blocked` source under any other overall are each a named invalid-record issue. `decision/2` orders invalid, blocked, expired, then the allow paths; `announcement_allowed?/2` is true exactly when it allows; `announcement_allowed?/1` is the one-line Phase 183 entry point and the only caller of the module's single private clock helper.
- The test file has 30 tests, none reading the clock and none calling the arity that does; `function_exported?` proves the entry point exists.
- Override control: an `owner_override` must equal `@acknowledged_override` (nil now) in the same commit, and a `by` equal to the searcher or matching `automated|agent|claude` is rejected even when acknowledged.

## Task Commits

1. **Task 1 (tracer): honest record, gate, and CI test, end to end** - `6533be05` (docs(brand): the record) and `027d639c` (chore(brand): script and test)
2. **Task 2: planted fail-closed states, runbook, mutation proof** - `8788a74f` (chore(brand): planted states) and `7cec846a` (docs(brand): runbook)

**Plan metadata:** recorded in the final docs commit that carries this file.

Commit count is measured from the ledger (`git rev-list --count 008e86ec..HEAD` returned 4 at SUMMARY write), not narrated. The record was committed before the script and test so that every commit is green on its own (the plan listed them in the other order; the commit kinds are unchanged). `scripts/`, `test/` and `.planning/` are all outside the shippable paths, so no commit can trigger a release.

The tracer gate (`HUMAN_VERIFY_MODE` end-of-phase, automated-only verify) re-ran the Task 1 test and the CLI after the Task 1 commits; both passed (8 tests, 0 failures; the CLI printed `deny (not_clear)`, exit 1), so expansion proceeded.

## Files Created/Modified

- `scripts/brand_trademark_gate.exs` - `Mailglass.BrandTrademarkGate`: `load/1`, `validate/1`, `decision/2`, `announcement_allowed?/1`, `announcement_allowed?/2`, `cli/1`, `schema/0`, `required_source_ids/0`; private `today/0`; tail guard `Mix.env() != :test` runs the CLI otherwise
- `.planning/research/brand-v2-adoption/trademark-search.json` - the record, stable key order, 2-space JSON
- `.planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md` - Summary, Searches run, Findings, Decision rule, Remaining for a human, How to record the result
- `test/scripts/brand_trademark_gate_test.exs` - `Mailglass.Scripts.BrandTrademarkGateTest`, 30 tests, `async: true`, all writes under ExUnit `tmp_dir`

## Lane that proves BRPOL-05

The test lives in `test/scripts/`, which runs in two required lanes: `core_deterministic_suite` (root `mix test`) and `mix_task_tests` (`mix verify.ci_lane_contract`, directory-scoped `test test/scripts/`). Root `mix.exs`, its aliases and `ci.yml` were not edited. No advisory lane is cited as proof.

## Verification

| Check | Result |
|---|---|
| `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors` | 30 tests, 0 failures (at least 15 required) |
| `mix run --no-start scripts/brand_trademark_gate.exs check --today 2026-11-14` | `deny (not_clear): overall=caution register_checked=false expires=2027-05-12`, exit 1 |
| same command with a missing `--path` | `deny (no_record)`, exit 1; with `--today bad`, usage error, exit 2 |
| `mix verify.ci_lane_contract` (the `mix_task_tests` lane) | 594 tests, 1 failure, 31 excluded, exit 2; the one failure is the recorded phase 164 baseline failure below, not this plan |
| `mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/brand_pin_test.exs test/scripts/brand_trademark_gate_test.exs --warnings-as-errors` | 130 tests, 1 failure, the same phase 164 test |
| `mix format --check-formatted` at the root | exit 0; `scripts/brand_trademark_gate.exs` formatted explicitly (outside the formatter inputs) |
| `git diff --quiet -- .planning/research/brand-v2-adoption/trademark-search.json docs scripts` after the mutation run | exit 0 |
| `git status --short` after the mutation run | only the orchestrator's `.planning/state.json` edit |

Acceptance criteria re-run: `jq` shows `caution`, `false`, `not_checked` (USPTO, TMview, WIPO), `9,38,42` and `null`; clock reads in the test 0, in the script 1 (inside the private `today/0`); `def announcement_allowed?(` defined 2 times; lines in the test calling it without an explicit date 0; `@acknowledged_override` 8 occurrences; runbook greps: uspto url 3, icann `.app` url 2, "not legal advice" 1, "Remaining for a human" 1, `METHODOLOGY.md` 1, CLAUDE.md-carve-out citation 0, "only the owner writes owner_override" 1.

Not run: the bare root `mix test --warnings-as-errors`. The orchestrator scoped this run to the plan's targeted commands under a heavily loaded machine; the new test file is covered by the directory-scoped lane run above and by its own scoped runs. The `core_deterministic_suite` run itself is left to the phase gate.

## Phase 164 baseline

The single `mix verify.ci_lane_contract` failure is `git runtime rules do not conceal the retired finalize-phase extension paths` (`test/scripts/phase_164_repository_truth_test.exs:261`, `Expected false or nil, got true` for `ignored?(".gsd/extensions/finalize-phase/index.ts")`). It is the same failure recorded in `179-03-SUMMARY.md` and `179-01-SUMMARY.md` before any phase 179 change: an untracked local `.gsd/.gitignore` containing `*`, absent from a clean CI checkout. It is not this plan's to fix. The lane total (594 tests, 1 failure) is the plan 03 count of 564 plus this plan's 30 tests.

## Mutation run

Every mutation was applied to the committed tree, `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors` was run (red), the mutation was restored with `git checkout -- <file>`, and the tree was confirmed clean. A `mix test` run with failures exits 2. G1 to G5 are the plan's mutations; M1 to M3 are extra mutations of the gate logic itself, to prove the planted-state tests catch a broken gate and not only a bad record.

| # | Mutation | Red exit | Red excerpt (named cause) | Restore |
|---|---|---|---|---|
| G1 | `"overall": "caution"` to `"clear"` in the committed JSON | 2, 5 failures | `the committed record loads and validates`: `{:error, {:invalid_record, [:clear_without_evidence]}}` | `git checkout -- .planning/research/brand-v2-adoption/trademark-search.json` |
| G2 | `"register_checked": false` to `true` | 2, 6 failures | `the committed record loads and validates`: `{:error, {:invalid_record, [:register_claim_without_evidence]}}` | same |
| G3 | append the trademark character to `docs/migration-policy.md` | 2, 1 failure | `no trademark symbol appears in markdown ...`: "the trademark record denies announcement (not_clear) ... Found: docs/migration-policy.md:99" | `git checkout -- docs/migration-policy.md` |
| G4 | delete the `uspto` source | 2, 12 failures | `the committed record loads and validates`: `{:error, {:invalid_record, [missing_required_source: "uspto"]}}` | `git checkout -- .planning/research/brand-v2-adoption/trademark-search.json` |
| G5 | set `owner_override` to `{"by": "automated agent (Claude Code)", "date": "2026-11-13", "rationale": "planted"}` without touching the test | 2, 2 failures | `committed owner_override is owner-acknowledged`: "owner_override in .planning/research/brand-v2-adoption/trademark-search.json is not mirrored by @acknowledged_override in test/scripts/brand_trademark_gate_test.exs. An owner_override may be added only in a reviewed commit authored by the owner ..." | same |
| M1 | script: `Date.compare(today, expires) != :lt` to `== :gt` (equal to expires no longer expired) | 2, 3 failures | `today equal to expires counts as expired, and so does any later day`, plus the override-expiry and CLI expiry cases | `git checkout -- scripts/brand_trademark_gate.exs` |
| M2 | script: the `blocked` clause no longer applies when an override is present | 2, 1 failure | `blocked is never overridable by the file` | same |
| M3 | script: the `clear` invariant loses its not-checked, blocked and register conditions | 2, 3 failures | `clear without a register search is invalid and denies`, `clear with a blocked source is invalid`, `clear with a not_checked source is invalid ...` | same |

The green re-run after the restores is the final run of the verification table (30 tests, 0 failures), and `git diff --quiet` on the record, `docs/` and `scripts/` exits 0. The G3 mutation is a real file edit to a tracked doc; it was restored before any other command ran.

## URL status

Each runbook URL was fetched on 2026-11-13 with `curl -sS -o /dev/null -w '%{http_code}' -L` and a generic user agent.

| URL | HTTP status | Note |
|---|---|---|
| https://tmsearch.uspto.gov/search/search-information | 200 | JavaScript application shell |
| https://www.tmdn.org/tmview/#/tmview | 200 | JavaScript application shell |
| https://branddb.wipo.int/en/ | 200 | proof-of-work bot challenge for automated clients |
| https://branddb.wipo.int/en/similarname | 200 | same challenge |
| https://lookup.icann.org/en/lookup?name=mailglass.com | 200 | |
| https://lookup.icann.org/en/lookup?name=mailglass.app | 200 | |
| https://tineye.com/ | 200 | |
| https://lens.google.com/ | 200 | |
| https://glama.ai/mcp/servers?query=mailglass | 200 | |
| https://www.npmjs.com/package/mailglass-email-mcp | 403 | refused to automation; working alternative https://registry.npmjs.org/mailglass-email-mcp returned 200 and is in the runbook |
| https://github.com/search?q=mailglass&type=repositories | 200 | |

## Edge coverage

| Edge | Covering tests (all in `test/scripts/brand_trademark_gate_test.exs`) |
|---|---|
| empty | missing file gives `{:missing, path}` then `:no_record`; empty file gives `:malformed_json`; JSON `null`, `[]` and a string each give `[:not_a_map]`; an empty `sources` list gives `:sources_empty`; every top-level key deleted in turn gives `{:missing_key, key}`; each of these denies and `announcement_allowed?/2` is false |
| encoding | `"November 13, 2026"`, `"2026-13-01"`, `"20261113"`, a datetime string and an integer each give `{:invalid_date, field}` for both `date` and `expires`; a bad `retrieved` gives `{:invalid_source, id, :retrieved}`; a non-ISO override date gives `{:invalid_override, :date}`; `expires` not after `date` gives `:expires_not_after_date`; today equal to expires and the day after both deny `:expired`, the day before allows |
| idempotency | `load/1`, `validate/1`, `decision/2` and `announcement_allowed?/2` return identical results on a second call, for an allowed and a denied record; the directory listing, file bytes and mtime under `tmp_dir` are unchanged afterwards |
| concurrency | no process state; `validate/1`, `decision/2` and `announcement_allowed?/2` never read the clock (grep gates: 0 clock reads in the test, 1 in the script, inside private `today/0`); the file runs `async: true` and writes only under its own `tmp_dir` |

## Decisions Made

- Gate semantics follow research assumption A4: allowed only if overall is not blocked, today is before expires, and (clear with register_checked true, or a populated owner_override). `open` and `owner_reviewed` are not record fields.
- RDAP registrations are caution sources; `register_checked` stays false because domains are not trademark registers; whether the project owns either domain is an owner question in the runbook (step 4).
- `rdap_other` is recorded `clear` (no domain object in six registries); the plan left its outcome open.
- Authorship of an `owner_override` cannot be observed by a test, so the control is the mirrored `@acknowledged_override` plus the agent-name rejection; "only the owner writes owner_override" is stated as a review rule in the runbook.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test calls the gate through `apply/3`**
- **Found during:** Task 1 (first test run)
- **Issue:** The gate module is loaded in `setup_all`, so a compile-time remote call (`Mailglass.BrandTrademarkGate.announcement_allowed?(record, today)`) warned "is undefined (module ... is not available)", which fails the run under `--warnings-as-errors`.
- **Fix:** Every call goes through the `gate(function, args)` helper (`apply/3`), the dispatch style `release_policy_test.exs` uses. The grep gate (no line in the test calls `announcement_allowed?(` without an explicit date) holds trivially: it returns 0.
- **Files modified:** `test/scripts/brand_trademark_gate_test.exs`
- **Commit:** `027d639c`

**2. [Rule 2 - Hardening] Basic-format ISO dates are rejected**
- **Found during:** Task 1 (writing `parse_date/1`)
- **Issue:** `Date.from_iso8601/1` also accepts the basic form `20261113`, so a hand-edited record could drift into a non-extended format the runbook does not show.
- **Fix:** `parse_date/1` first requires `\A\d{4}-\d{2}-\d{2}\z`, then calls `Date.from_iso8601/1` and compares only `Date` structs. Tested with `"20261113"`.
- **Files modified:** `scripts/brand_trademark_gate.exs`
- **Commit:** `027d639c`

**3. [Rule 2 - Hardening] Unknown record keys and duplicate source ids are invalid**
- **Found during:** Task 1
- **Issue:** The plan required exact key sets; an extra key such as `"open": true` would otherwise look like a control the gate ignores, and a duplicate source id could hide a `not_checked` register.
- **Fix:** Unknown top-level and per-source keys give `{:unknown_key, k}` and `{:source_unknown_key, id, k}`; duplicate ids give `{:duplicate_source, id}`. Each is tested.
- **Files modified:** `scripts/brand_trademark_gate.exs`, `test/scripts/brand_trademark_gate_test.exs`
- **Commits:** `027d639c`, `8788a74f`

### Observations that differ from the research

- TMview: the research reported an automated request returning "Request Rejected". On 2026-11-13 a plain `GET` of `https://www.tmdn.org/tmview/#/tmview` returned HTTP 200 with an empty JavaScript application shell. The record states both: the shell as observed today, and the earlier rejection as carried from the research (not re-verified), and records `not_checked` either way.
- The record `date` is 2026-11-13 (the local calendar date at the time of the checks); the UTC date had already rolled to 2026-11-14.

### Process notes

- Task 2 is `tdd="true"`, but the gate was built in Task 1, so the planted-state tests were green on their first run (30 tests, 0 failures) and there was no red-before-green step. The teeth are proven instead by G1 to G5 and the extra M1 to M3 mutations above, each red and then restored.
- Commit order for Task 1 was record first, then script and test, so no commit is red.

**Total deviations:** 3 auto-fixed (1 blocking, 2 hardening), 0 architectural. **Impact:** none on scope; each is covered by tests.

## Issues Encountered

- `mix verify.ci_lane_contract` reports 1 failure, the pre-existing `git runtime rules do not conceal the retired finalize-phase extension paths` test caused by the untracked local `.gsd/.gitignore` (see "Phase 164 baseline"). It is identical before and after this plan and absent from a clean CI checkout.
- `mix test` output carries the unrelated pre-existing warning `OTLP exporter module opentelemetry_exporter not found`. It does not come from files in this plan.

## Authentication Gates

None. Every endpoint queried is public and needed no credentials.

## Known Stubs

None. No hardcoded empty values, placeholder text or unwired data in the files this plan created. The `not_checked` outcomes are deliberate, honest record states, not stubs: the owner register pass in the runbook resolves them, and the gate denies until then.

## Threat Flags

None. The script reads one local file and prints a decision; it opens no network endpoint, auth path or schema. The registry and RDAP queries sent only the public word "mailglass" and its variants, and the `searcher` field names the tool, not a person (T-179-14, accepted).

## Next Phase Readiness

- Phase 183 calls `Mailglass.BrandTrademarkGate.announcement_allowed?/1` before any announcement or trademark text. It denies today (`caution`, `register_checked: false`) and keeps denying until the owner records the USPTO, TMview and WIPO results, or deliberately adds an owner override.
- The owner register pass (about 15 minutes, runbook in `TRADEMARK-SEARCH.md`, "Remaining for a human") is the only owner hand-off in this plan. Per D-23 it does not block phase completion or the milestone, and no `clear` was manufactured.
- The record expires 2027-05-12; refresh it at 180 days, or at the next release or announcement, whichever comes first.

## Self-Check: PASSED

- All four created files exist (`scripts/brand_trademark_gate.exs`, `test/scripts/brand_trademark_gate_test.exs`, `trademark-search.json`, `TRADEMARK-SEARCH.md`).
- Commits `6533be05`, `027d639c`, `8788a74f`, `7cec846a` are ancestors of HEAD; the measured ledger count is 4.
- Acceptance criteria re-run (see Verification); the one lane failure is the recorded pre-existing phase 164 baseline.
- No `TODO`, `FIXME`, "coming soon" or "placeholder" in any created file.
