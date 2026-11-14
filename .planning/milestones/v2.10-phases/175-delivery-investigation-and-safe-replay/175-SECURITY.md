---
phase: "175"
slug: "delivery-investigation-and-safe-replay"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 175 — Security

## Trust Boundaries

- Browser events to server-selected Account/Delivery/Inbound identity and frozen one-shot review.
- Fresh scoped evidence to current host authorization and existing replay commands.
- Retained or synthetic evidence to escaped bounded presentation and source-bound browser receipts.
- Run-owned test reset, environment-only credentials, advisory CI and locked dependency stack.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| T-175-01 | Elevation of privilege | Quick/full replay events | high | mitigate | operator_live.ex exact selection/scoped reread/authorization; operator_live_test.exs forged foreign identity | closed |
| T-175-02 | Tampering | Exact target identity | high | mitigate | operator_live.ex frozen snapshot/fresh comparison; operator_live_test.exs ambiguous and equal-looking targets | closed |
| T-175-03 | Repudiation | Success presentation | medium | mitigate | operator_live.ex command feedback + refreshed evidence; outbound-replay.spec.js durable audit/toast | closed |
| T-175-04 | Information disclosure | Technical/request presentation | medium | mitigate | ReplayTargets bounded projection and escaped ReplayModal HEEx; Unicode/script tests | closed |
| T-175-SC | Tampering | Package installs | high | accept | Accepted Risks Log AR-175-SC; exact constraints for existing locked versions, runtime `mix deps.get --check-locked`, and unchanged-lock probe/current-run evidence | closed |
| T-175-05 | Information disclosure | Suppression refresh | high | mitigate | OperatorLive selected Account/recipient/stream read; Suppressions query isolation and expiry tests | closed |
| T-175-06 | Tampering | Last-known suppression evidence | medium | mitigate | OperatorLive scope-matched retained evidence; SuppressionCard stale/unavailable; tagged transitions | closed |
| T-175-07 | Repudiation | Suppression policy/refresh | medium | mitigate | SuppressionCard recorded expiry/policy copy; real external-change/expiry tests | closed |
| T-175-08 | Elevation of privilege | Inbound confirmation | high | mitigate | InboundLive exact fresh record/Mailbox + authorization before replay; changed/foreign/denied tests | closed |
| T-175-09 | Tampering | One-shot review | high | mitigate | InboundLive pending/consumed review IDs and exact snapshots; duplicate run-count assertions | closed |
| T-175-10 | Information disclosure | Shell/summary | medium | mitigate | Components.replay_dialog presentation slots; escaped bounded domain wrappers; shell-contract tests | closed |
| T-175-11 | Repudiation | Recorded outcomes | medium | mitigate | InboundLive actual recorded outcome/toast/timeline; mounted failure and outcome-copy tests | closed |
| T-175-12 | Tampering | Stale/substituted target | high | mitigate | OperatorLive scope equality + frozen/fresh candidate comparison; replaced/deleted/changed request tests | closed |
| T-175-13 | Elevation of privilege | Revoked access | high | mitigate | OperatorLive scoped reread then host authorization then command; revoke-after-open zero-write test | closed |
| T-175-14 | Repudiation | Duplicate/error replay | high | mitigate | Consume before command; Webhook.Replay transaction/idempotency/success audit; duplicate/no-change/audit-failure tests | closed |
| T-175-15 | Information disclosure | Command error | medium | mitigate | RepairState fixed safe error mapping; persistence private-error absence test | closed |
| T-175-16 | Tampering | Scenario projection | medium | mitigate | quick_view_projection_test.exs persisted Northstar/Fjordline field-by-field comparison | closed |
| T-175-17 | Repudiation | Rendering/fidelity claims | medium | mitigate | check_phase175_evidence.cjs exact source/assets/URLs/execution/incomplete accounting; fresh receipt valid | closed |
| T-175-18 | Repudiation | Acceptance evidence | high | mitigate | Nonempty exact report-derived inventory; checker negative controls and auditor 14 invalid-input controls | closed |
| T-175-19 | Tampering | CI/gate claims | high | mitigate | CI advisory lane preserved; regression suites retained; manifest count + incomplete accounting tested | closed |
| T-175-20 | Information disclosure | Evidence/token | medium | mitigate | Run-owned reset identity/token guards; bounded synthetic captures; no token output | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
| --- | --- | --- | --- | --- |
| AR-175-SC | T-175-SC | The initial Phase 175 setup used the committed dependency graph and added no packages. WR-04 follow-up found that Compose's demo startup ran `mix deps.get` against the read/write workspace bind and resolved newer compatible minors (`boundary` 0.12.0 and `websock_adapter` 0.7.0) over the committed versions (0.11.0 and 0.6.0), mutating `reference/demo_app/mix.lock` before source validation. The Demo Mix manifest now adds exact `override: true` constraints for those already-locked packages, and `reference/demo_app/Dockerfile` runs startup resolution with `mix deps.get --check-locked`. The isolated `MIX_ENV=dev mix deps.get --check-locked` probe selected the committed versions and left lock SHA-256 `1472692952d9ddbd91df7a116a4b5cf28f717ca3369a7a04bf80cc94b39711d7` unchanged; the fresh combined run returned 0 with the same lock hash before and after. No new package, locked package version/checksum, or lock entry was introduced. The isolated evidence runtime still downloads the existing lock-matched Playwright browser. The probe also reported an advisory for existing locked `cowlib` 2.21.0 (CVE-2026-43966); its app-specific exploitability was not assessed in WR-04, no upgrade was included, and it requires separate follow-up ([OSV record](https://osv.dev/vulnerability/EEF-CVE-2026-43966)). Any future package/install or version change requires a separate legitimacy audit before use. | Already accepted in all six approved phase PLAN threat registers; orchestrator records that existing disposition. | 2026-10-27 |

## Audit Evidence

The read-only ASVS1 auditor verified all 20 planned implementation mitigations against current source and tests. The shared T-175-SC row appears in all six plans and is deduplicated once here. No implementation gap was identified. The auditor independently re-read AR-175-SC and returned SECURED: 21/21 closed, threats_open: 0.

Fresh checkEvidence with pilot true and writeSummary false validated run `mailglass-evidence-20261027200450-16960-29407`, source `8cd973774c293cc3d95b1e8f9be489b5e4ca5caa`, digest `77fdd45e830c44b07e1062af584414eb4d2c07f2747a7607aa47866cbf81153b`. Each condition has Demo 4, Admin 10, fidelity 10, Axe 26. Axe keeps 116 incomplete findings and 0 violations. Owned-project cleanup/volume removal is recorded. Fourteen additional in-memory invalid-evidence controls were rejected.

The final WR-04 combined run is `mailglass-evidence-20261027221513-96275-31939`, source `0deab1a14e28a8fb32d06a7d9e864d8d0fe508a0`, Phase 175 digest `d01817a07796768cbf874ba35715aa3945a3f59971104b362e82417244901fa7`, and Phase 174 digest `13694a3171535116a61d8ef3ed8c102cb5a664ef1d5c53fc9d401c58ba1d681c`. It exited 0. Each condition has Demo 4, Admin 10, fidelity 10, Axe 26, Delivery layout 6, and Inbound layout 6; the 116 Axe-incomplete findings remain incomplete. The monitored lock SHA-256 stayed unchanged before and after, and owned Compose volumes were removed.

Auditor explicitly reviewed task-suffixed commits `41addb1a`, `7e6c8578`, `32484ad8`, `5fd3e730`, `01216920` and their current source. Eight descriptor-less prohibitions remain flagged-unverified; this report invents no wired descriptors and does not silently close those flags.

### WR-04 runtime dependency resolution addendum

The prior audit's statement that no manifest changed described the earlier Phase 175 implementation and is historical. The current narrow change is in `reference/demo_app/mix.exs`: it constrains resolution of two already-present packages to the exact versions recorded in `reference/demo_app/mix.lock`, and `reference/demo_app/Dockerfile` runs startup resolution in locked-check mode. It adds no package or lock entry and does not alter application runtime surfaces. The dependency probe used isolated `/tmp` Mix/Hex/deps/build caches and reported boundary 0.11.0 and websock_adapter 0.6.0 with `--check-locked`; the lockfile stayed byte-identical. The fresh combined run `mailglass-evidence-20261027221513-96275-31939` exited 0 against the committed selected-source identity, with the same lock SHA-256 before and after. Earlier failed attempts and their lock diff remain under `artifacts/phase175/runner-failures/`; raw stdout for the 21:52 attempt was not retained after the temporary monitor log was reused. The successful run details are in [175-AUTOMATION.md](175-AUTOMATION.md).

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
| --- | --- | --- | --- | --- |
| 2026-10-27 | 21 | 21 | 0 | gsd-security-auditor (accepted-risk recheck complete) |

## Sign-Off

- [x] All threats have a disposition.
- [x] Planned accepted risk recorded.
- [x] Accepted-risk recheck and threats_open: 0 confirmed.
- [x] status: verified.
