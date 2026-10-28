---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "08"
subsystem: ui
tags: [storybook, scenario-manifest, inbound, evidence-card, detail-header, gallery, fixtures]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 02 DetailHeader contact display, plan 03 EvidenceCard disclosure, plan 05 EvidenceCard truthful facts list"
provides:
  - Eleven manifest scenarios inbound-evidence-* with synthetic reserved-domain worst-case data
  - MailglassDemo.QuickViewScenarios.inbound_evidence/1 builder (production assigns only)
  - Storybook.InboundEvidence at /dev/storybook/inbound_evidence composing the production DetailHeader and EvidenceCard
  - Merge-blocking ExUnit table asserting every scenario's defining fact through the production components
  - Advisory demo e2e inventory spec inbound-evidence.spec.js
  - Gallery fixtures with no masked-looking Inbound addresses
affects: [176-10]

plan_head_before: 88c90d5b180411d5bea720b987138ffdf740cae1
plan_head_after: e01e62890106b604d3bbde7d657b7abed43c4a20

actuals:
  tokens: 12500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Story scenarios are manifest-first: JSON facts -> pure builder -> production component assigns, with no invented props"
    - "A story page states its proof boundary (story-render-only) in its header and manifest, and leaves authorization to connected routes"

key-files:
  created:
    - reference/demo_app/storybook/inbound_evidence.story.exs
    - reference/demo_app/assets/e2e/inbound-evidence.spec.js
  modified:
    - reference/persona_spec/quick_view_scenarios.json
    - reference/persona_spec/quick_view_scenarios.ex
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex

key-decisions:
  - "Scenarios are not added to axe_selection (it stays at 20 entries); accessibility of revealed, denied and invalid states is proven on connected routes in plan 176-10"
  - "The denied scenario carries a sentinel in both raw_payload and raw_mime so the absence assertion covers every byte path the card can render"
  - "The ExUnit table reads fact values out of the evidence card's dl by label, so 'Unavailable' for size cannot be satisfied by the Provider authentication fact"
  - "INUX-05 and INUX-06 are also declared by plan 176-10, so requirements are not marked complete here"

patterns-established:
  - "inbound-evidence-* scenario ids map 1:1 to variation ids (dashes to underscores), asserted by the ExUnit table"

requirements-completed: []
# INUX-05 and INUX-06 are also declared by plan 176-10, so they are not marked here.

coverage:
  - id: D1
    description: "Eleven retained inbound-evidence-* scenarios render through the production DetailHeader and EvidenceCard; each defining fact (long local part, Unicode, spoof cue, Show 2 more, missing-header copy, Unparseable address, Unavailable not 0 bytes, empty payload, thousands-separated size with focusable pre, denied copy with no payload bytes) is asserted"
    requirement: INUX-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs#Phase 176 retained Inbound evidence scenarios render through production components"
        status: pass
    human_judgment: false
  - id: D2
    description: "Storybook page /dev/storybook/inbound_evidence serves all eleven variations with the story testids and scenario ids from the manifest (advisory demo lane, D-29)"
    requirement: INUX-06
    verification:
      - kind: e2e
        ref: "reference/demo_app/assets/e2e/inbound-evidence.spec.js#Phase 176 retained Inbound evidence inventory and production composition"
        status: pass
    human_judgment: false
  - id: D3
    description: "No gallery envelope_recipient fixture is masked-looking; the Inbound detail specimen carries from, to and cc; specimen ids and states unchanged"
    requirement: INUX-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/gallery-matrix.spec.js and structural.spec.js --grep gallery (18 passed)"
        status: pass
    human_judgment: false
  - id: D4
    description: "axe_selection is unchanged at 20 entries and the Phase 174/175 evidence checkers still pass"
    requirement: INUX-06
    verification:
      - kind: unit
        ref: "scripts/check_phase174_evidence.test.cjs and scripts/check_phase175_evidence.test.cjs (16 pass, 0 fail)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-10-28
status: complete
---

# Phase 176 Plan 08: Retained Inbound evidence stories Summary

**Eleven manifest-driven Storybook scenarios now render the production Inbound DetailHeader and EvidenceCard with synthetic worst-case contacts and raw-source states, a merge-blocking ExUnit table proves each defining fact, and the gallery no longer shows masked-looking addresses.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-10-28
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files:** 6 modified or created (2 new)

## Accomplishments

- `inbound-evidence-*` scenarios (normal contacts, long local part, Unicode, spoofed display name, 7 recipients, missing headers, unparseable, unknown size/count, empty payload revealed, multi-KB revealed, denied) in `quick_view_scenarios.json`, all `proof_boundary: story-render-only`, reserved example domains only.
- `QuickViewScenarios.inbound_evidence/1` returns only the assigns the production components accept (`detail`, `evidence`, `reveal_state`, `received_at`, `account_labels`) and raises `ArgumentError` for unknown ids.
- `Storybook.InboundEvidence` (`/dev/storybook/inbound_evidence`, theme owner `inbound-evidence-story`, picker `inbound-evidence-review-theme`, root `inbound-evidence-story`) states "Static rendering only. Reveal is not connected to authorization."
- The ExUnit table asserts per scenario: long address untruncated; Unicode address and name exact; spoof cue present only on the spoof scenario; "Show 2 more"; "No From header" / "No To header" / "Not recorded by provider"; "Unparseable address"; Payload size and Header count read `Unavailable` and never "0 bytes"; empty payload shows "0 bytes" and its own copy; large payload has a focusable `<pre>` and a thousands-separated size; denied renders the denied status and none of the sentinel bytes.
- Gallery: `composed_detail_timeline` carries synthetic `from`/`to`/`cc` and an unmasked envelope recipient; the three `records_list` Inbound specimens use reserved-domain addresses with the long-value stress specimen kept long.

## Task Commits

1. **Task 1: One retained Inbound evidence scenario rendered by production components (tracer)** - `e842fd19` (feat)
2. **Task 2: Worst-case Inbound contact and evidence scenarios** - `7f0be424` (feat; the table test was written first and seen RED with "unknown retained Inbound evidence scenario long_local_part", then green)
3. **Task 3: Replace masked gallery fixtures with synthetic worst-case data** - `e01e6289` (feat)

**Plan metadata:** committed separately (docs: complete plan).

## Verification

Story URL: `/dev/storybook/inbound_evidence` (demo app, e.g. `http://127.0.0.1:4716/dev/storybook/inbound_evidence`; variation iframes are `normal_contacts` ... `evidence_denied`).

| Command | Result |
|---|---|
| `mix test test/mailglass_admin/quick_view_projection_test.exs --seed 0` (mailglass_admin) | 6 tests, 0 failures |
| `mix test test/mailglass_admin/quick_view_projection_test.exs --only phase176 --trace --seed 0` | 6 tests, 0 failures, 5 excluded; the Phase 176 test is present in the trace |
| `mix test test/mailglass_admin/persona_drift_guard_test.exs test/mailglass_admin/group_nesting_test.exs test/mailglass_admin/bucket_a_coverage_test.exs --seed 0` | 21 tests, 0 failures |
| `mix test --seed 0` (full mailglass_admin) | 811 tests, 0 failures, 1 excluded |
| `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs` | 16 pass, 0 fail |
| `npm --prefix mailglass_admin run test:operator-browser -- structural.spec.js gallery-matrix.spec.js --grep "gallery"` | 18 passed, 0 failed, 0 skipped; `app.css` stayed clean |
| `grep -c 'envelope_recipient: "[^"]*\*' gallery_live.ex` | 0 (baseline 4) |
| `axe_selection` length | 20 (unchanged) |
| `bash mailglass_admin/scripts/check-conformance.sh` | OK: design-system conformance clean |
| `mix format --check-formatted` on every touched file (admin and demo_app) | clean |
| `git diff --quiet -- reference/demo_app/mix.lock` | clean after every demo run (reverted with `git checkout -- reference/demo_app/mix.lock`; the lockfile did not actually drift in these runs) |

### Advisory demo e2e (D-29)

- Task 1 spec (1 retained id): **1 passed, 0 failed, 0 skipped**.
- Task 2 spec (11 retained ids, all variations): **1 passed, 0 failed, 0 skipped**.
- The Playwright-managed `webServer` mode (`mix ecto.setup && mix phx.server`) could not drive these runs on this machine, for two reasons recorded for the lane owner. (a) The local `mailglass_demo_dev` database is stale (migration `AnchorMailglassInboundV01` fails with schema "mailglass" does not exist), so a throwaway database `mailglass_demo_176_08_tmp` was used and dropped afterward. (b) Port 4015 is held by a Docker listener on this host, so requests to `127.0.0.1:4015` never reach Phoenix; and `mix ecto.setup` boots a transient endpoint that answers `GET /` 200 before `mix phx.server` binds, so Playwright's readiness probe fires early and the first navigation is refused. Passing runs used `PORT=4716`, a separately started `mix phx.server`, and `DEMO_BASE_URL=http://127.0.0.1:4716` (external-server mode).

## Deviations from Plan

None - plan executed exactly as written. Two test-local adjustments inside Task 2 are noted for transparency and did not change shipped code: the denied-copy assertion matches "permission to reveal raw source." (the apostrophe renders literally, not as `&#39;`), and the table asserts fact values by `dt`/`dd` label so the shared "Unavailable" word on the Provider authentication fact cannot satisfy the size and count checks.

## Issues Encountered

- The demo e2e web-server lane could not start on this host (stale local database, Docker holding port 4015, ecto.setup readiness race); worked around with external-server mode as described above. Not a plan defect.
- Observation for the browser reds already logged in `deferred-items.md` (`phase169-journey.spec.js:459`, `flows.spec.js`, `operator.spec.js`): this plan's gallery and structural cases (18) were green, so those reds are confined to the Deliveries replay and Inbound evidence spec surfaces and are not affected by fixture changes here.

## Known Stubs

None. All fixture values are intentional synthetic data with reserved example domains.

## Threat Flags

None. Dev-only fixtures and a story page; T-176-17 (reserved example domains, no real addresses) and T-176-18 (story header states no authorization is exercised; `proof_boundary: story-render-only`) are mitigated and covered by the ExUnit table.

## Next Phase Readiness

- Plan 176-10 can prove axe and authorization for revealed, denied and invalid states on connected routes; the new scenarios are deliberately outside `axe_selection`.
- INUX-05 and INUX-06 stay open until plan 176-10 (it declares them too).

## Self-Check: PASSED

- Created files exist: `reference/demo_app/storybook/inbound_evidence.story.exs`, `reference/demo_app/assets/e2e/inbound-evidence.spec.js`.
- Commits `e842fd19`, `7f0be424`, `e01e6289` are ancestors of HEAD.

---
*Phase: 176-direct-filters-and-useful-inbound-evidence*
*Completed: 2026-10-28*
