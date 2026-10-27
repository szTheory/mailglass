---
phase: "174"
slug: "faithful-storybook-and-quiet-quick-views"
status: verified
threats_open: 0
threats_total: 19
threats_closed: 19
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 174 — Security

ASVS L1 verification of the six planned threat registers. The repeated supply-chain threat is deduplicated. All 19 planned mitigations are present; no risk acceptance or new authorization was inferred. L1 closed-register short-circuit applies; no deeper auditor dispatch is required.

## Trust Boundaries

- Browser to guarded development router and authenticated Account-scoped records.
- Synthetic facts to isolated persisted fixtures and production presentation.
- Hook definitions to each host's existing socket/lifecycle owner.
- Rendered assets/theme state to source-identified receipts.
- Fresh Axe output to independent approval/triage inputs.
- Run-owned Docker reset/database/cleanup to safe retained CI artifacts.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-174-01 | Elevation of privilege | StorybookRoutes | high | mitigate | reference/demo_app/lib/mailglass_demo_web/router.ex:4,34,68: availability guards wrap both macros; live mount uses browser session/CSRF pipeline. reference/demo_app/mix.exs:50 keeps PhoenixStorybook only: :dev. Demo security tests cover production exclusion. | closed |
| T-174-02 | Tampering | Quick-view paths | high | mitigate | mailglass_admin/lib/mailglass_admin/operator_live.ex and inbound_live.ex retain scoped path generation. Connected quick-views.spec.js checks Account/filter/selection/Close; existing operator_live_test.exs/inbound_live_test.exs retain foreign-tenant rejection. | closed |
| T-174-03 | Information disclosure | Scenario metadata/captures | medium | mitigate | reference/persona_spec/quick_view_scenarios.ex and .json use synthetic cohorts/example.test. Browser receipts identify scenarios and safe projection facts. | closed |
| T-174-SC | Tampering | Package supply chain | high | mitigate | No dependency/lockfile change against verified pre-phase candidate; package.json adds only a script. Both existing Playwright versions and PhoenixStorybook1.2 remain. Existing actions retain SHA pins and lockfile-only restores. Baseline diff confirms identical mix/npm locks/toolchain/Dockerfile/compose pins. | closed |
| T-174-04 | Information disclosure | Inbound selected projection | high | mitigate | mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs:157 tests exact Unicode and excludes independently inserted foreign Account row; scoped production reads remain intact. | closed |
| T-174-05 | Tampering | Shared fixture facts | medium | mitigate | quick_view_projection_test.exs independently materializes Delivery and Inbound fixtures and compares meaningful fields; generated IDs/timestamps have explicit narrow treatment, not whole-object normalization. | closed |
| T-174-06 | Denial of service | Test materialization/history | low | mitigate | QuickViewProjectionTest uses existing LiveViewCase/Sandbox and bounded fixture cohorts. No new global fixture/history service. | closed |
| T-174-07 | Spoofing | Browser socket ownership | high | mitigate | mailglass_admin/priv/static/hooks.js contains hook definitions with no socket construction; reference/demo_app/dev/mailglass_demo_web/storybook.ex registers those definitions into the existing Storybook owner. storybook-hooks.spec.js verifies actual joins/frames and no Admin bootstrap. | closed |
| T-174-08 | Denial of service | Focus hook listeners | medium | mitigate | hooks.js destroyed callbacks remove focus/keyboard listeners; storybook-hooks.spec.js and flows.spec.js exercise repeated patch/removal/reconnect and focus-return lifecycles on both locked clients. | closed |
| T-174-09 | Elevation of privilege | Demo hook endpoint | high | mitigate | Demo hook endpoint is inside Code.ensure_loaded?(PhoenixStorybook.Router) guard and secure-browser-header pipeline in router.ex; no adopter Admin router macro change. | closed |
| T-174-10 | Tampering | Fidelity receipt | medium | mitigate | storybook-fidelity.spec.js checks actual successful response bytes/digests, loaded font faces and computed roles, distinct source/build identities, and fresh scenario/theme/width receipts. | closed |
| T-174-11 | Information disclosure | Captures/receipt | medium | mitigate | Fidelity producers retain synthetic case IDs, safe routes, asset/font hashes and computed values. No customer/session data source is used. | closed |
| T-174-12 | Tampering | Theme owner | low | mitigate | storybook.ex template-local owner uses matchMedia and root dataset, no host cookie write; theme cases exercise explicit modes, both initial OS modes/live changes, and stable host preference. | closed |
| T-174-13 | Tampering | Execution report | high | mitigate | storybook-axe.cjs validateReport independently checks caller run/revision/digest, nonempty exact expected/executed sets and per-case success; negative fixtures cover stale/missing/partial/duplicate/self-comparison. | closed |
| T-174-14 | Repudiation | Approved fingerprints | medium | mitigate | storybook-axe-approved.json is independent read-only input. Comparator requires exact rule/target/scenario/state/theme plus provenance; producer never rewrites it. Approved violation list remains empty. | closed |
| T-174-15 | Information disclosure | Axe nodes | medium | mitigate | storybook-axe.spec.js safeFindings serializes rule/selector/scenario/state/theme/count only, excluding node HTML; report files are private0600 and synthetic. | closed |
| T-174-16 | Tampering | Reset/teardown wrapper | high | mitigate | run_demo_browser_evidence.sh owns unique Compose project, isolated non-retained loopback ports, fresh reset token, serial workers, health-marker guard, and trap cleanup. check-persona-reset-target.cjs rejects mismatched project/origin/token. Container evidence chown is scoped to owned condition, uses -h and preserves file modes/status; disposable Linux probe verified outside symlink target unchanged. | closed |
| T-174-17 | Repudiation | Review/cost receipts | medium | mitigate | check_phase174_evidence.cjs validates source manifest hashes, counts, cold/warm setup, independently completed GitHub run/job/runner identity and timestamps. It rejects local labels/absent metadata/red workflow. Original downloaded cost is retained before enrichment; live required contexts remain CI Green and Guard Release Trigger. Final candidate CI40491221303 completed/success; strict --require-ci passed against independent job122145432926 metadata, sourcefbf7d791 and both148-case conditions. | closed |
| T-174-18 | Information disclosure | Uploaded evidence | medium | mitigate | Selected receipts use synthetic safe metadata and axe safeFindings; workflow uploads only run-owned directory with 14-day retention. Fresh reset token is not included in receipt schema; private report modes are retained through scoped ownership handoff. | closed |

## Accepted Risks Log

No accepted risks. All listed dispositions are implemented mitigations.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-27 | 19 | 19 | 0 | Codex orchestrator, ASVS L1 source/receipt verification |

## Evidence and Limits

The strict hosted checker passed during this audit for run40491221303, exact implementation candidatefbf7d791, both148/148 conditions and independent completed job122145432926 metadata. Existing Account/security suites and all26 candidate CI jobs passed. Reset origin/project/token negative controls and receipt forgery/missing/partial controls remain active. The default operator suite retains233 cases; all18 selected Axe cases remain in the isolated dedicated producer. No lockfile/client/action upgrade or protected-context change occurred.

This verifies the planned L1 controls; it does not grant merge/release/deployment approval or certify every possible new threat. The UI descriptorless transparency prohibition remains flagged-unverified in its own evidence contract and is not converted into a security acceptance.

## Fresh exact-candidate evidence — 2026-10-27

The post-review candidate `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5` completed run [40498413906](https://github.com/szTheory/mailglass/actions/runs/40498413906) successfully with all 26 jobs green. The strict hosted checker passed against the independent Demo job [122170444350](https://github.com/szTheory/mailglass/actions/runs/40498413906/job/122170444350), matching the source digest `21542c6a5e3a10a8d6334b902c9cbfbecde06e210aca8ae9c333cbe3054ed1c2`, run and attempt, runner, timestamps, and complete cold/warm receipts. This supersedes the earlier `40491221303` receipt as current-source evidence.

The first post-review run `40496672358` is retained as an unsuccessful readiness attempt: Preview Capture Advisory expired its startup readiness window while compilation and fixture seeding were active, so it is not claimed as proof. Its failed job log and actual run/job metadata were preserved; the unchanged-candidate retry passed without relaxing timeout, checker, isolation, artifact, or branch-protection policy. No new trust boundary or accepted risk was introduced.

## Sign-Off

- [x] Every planned threat has implemented evidence.
- [x] No accepted risk was silently introduced.
- [x] `threats_open: 0`.
- [x] `status: verified`.


## Post-Review Reconciliation

The independent source review identified three concrete gaps that the initial audit had missed. Commit `18c6cf32` adds symlink-component rejection, no-follow checkpoint writes and preservation of prior retained evidence (CR-01/T-174-16/18); full-detail focus ownership and a connected regression (WR-01); and omitted route/story inputs plus dirty-byte digest controls (WR-02/T-174-17). All 24 focused Node checks and 3 browser cases passed, with an independent clean re-review in `174-REVIEW-FIX.md`. The initial report is retained and all three dispositions are fixed. Current exact-candidate CI proof is tracked separately from these focused checks; no risk acceptance or gate reduction occurred.
