# Phase 178 Recovery Review

**Status:** In progress; lock-graph review complete, Demo environment/ownership review pending.
**Checkout branch:** `main` (unchanged). The intended remote target ref recorded for the future Plan 21 approval is `gsd/v2.10-ui-repairs-storybook`.
**Stopped predecessor:** `255422cbe6e16c570ccb465246c2394fa3190866`.

## Review scope and authority boundary

This review covers only the six already-completed local recovery source files:

- `mix.lock`
- `mailglass_admin/mix.lock`
- `mailglass_inbound/mix.lock`
- `compose.demo.yml`
- `scripts/run_demo_browser_evidence.sh`
- `scripts/test_run_demo_browser_evidence.sh`

The reviewed files will be committed in two task commits. The source candidate will be the second task commit on the unchanged local `main` checkout. The target-ref field above is metadata for a separately approved future push; this plan does not create a branch, push, update a PR, dispatch a workflow, run hosted CI, or launch a preview. The local pilot is not hosted evidence, does not authorize remote work, and its 2.205-minute added time is not hosted runner cost.

## Preexisting workspace inventory

Captured before plan edits on 2026-11-02 UTC. The index was clean. These unrelated dirty paths were preserved and excluded from all task staging:

| Status | Path |
|---|---|
| deleted | `.planning/HANDOFF.json` |
| modified | `.planning/config.json` |
| modified | `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts/review-fix/account-chooser-320.png` |
| modified | `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts/review-fix/account-options-1440.png` |
| modified | `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts/review-fix/account-options-320.png` |
| modified | `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts/review-fix/selected-account-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/deliveries-1440.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/deliveries-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/deliveries-390.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/deliveries-768.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/detail-1440.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/detail-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/detail-390.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/detail-768.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/health-1440.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/health-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/health-390.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/health-768.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/quick-view-1440.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/quick-view-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/quick-view-390.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/quick-view-768.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/replay-review-1440.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/replay-review-320.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/replay-review-390.png` |
| modified | `.planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts/after/replay-review-768.png` |
| modified | `.planning/phases/178-preview-authoring-and-milestone-review/178-VERIFICATION.md` |
| modified | `.planning/research/JTBD-COVERAGE.md` |
| modified | `.planning/research/storybook-fractal/RECOMMENDATIONS.md` |
| modified | `.planning/seeds/SEED-009-fractal-storybook.md` |
| modified | `.planning/seeds/SEED-261010-gad-operator-date-range-and-live-filters.md` |
| modified | `.planning/seeds/SEED-261010-hjp-inbound-filters-auto-apply-and-live-search.md` |
| modified | `.planning/state.json` |
| untracked | `.planning/milestones/v2.9-phases/173.1-address-tech-debt-demo-auth-browser-evidence/.gitkeep` |
| untracked | `.planning/research/phase178-hosted-stop-recovery.md` |
| untracked | `AGENTS.md` |
| untracked | `prompt.txt` |

The six recovery files listed in the review scope were also modified before execution; they are included only in the two explicit task commits. The refreshed verification report remains outside those commits.

## Task 178-20-01 — Hex-audited lock graphs

**Disposition:** Pass. **ASVS L1 high-severity findings:** 0.

All three diffs change only the `phoenix_html` lock entry from 4.3.0 to 4.4.0, with the 4.4.0 Hex package and registry checksums. No other package entry changes. The refreshed local verification report records passing results for `mix mailglass.audit --kind hex` and `mix deps.get --check-locked` in the root, Admin, and Inbound projects at `.planning/phases/178-preview-authoring-and-milestone-review/178-VERIFICATION.md#current-local-recovery-evidence`. No package was installed or resolved during this review.

The recorded checks are summary evidence in that report; separate raw command logs were not saved. The recovery pilot itself ran from dirty source revision `afc308405b36da7f4d86bb795129d0acc680517c`, so it is not a frozen candidate. The selected-source digests were recomputed from the current workspace and match the saved Phase 174 and both Phase 175 pilot receipts, which supports reusing those local pilot results for the reviewed bytes. This does not establish hosted success, approval, or runner cost.

| Reviewed source | SHA-256 |
|---|---|
| `mix.lock` | `8cd8ecc6b5ed71e796918da4d1484cb8be20fbc3347d5c9b58cd317c839ee429` |
| `mailglass_admin/mix.lock` | `28c99a59e14ba54a2d2c25caf497ab0739b1a3dc422e5a426b3ba0ff15ce5c42` |
| `mailglass_inbound/mix.lock` | `00fbc7902afaa6b1dbfbb7665b34ad8b4a0e96f4f7da4ca66d523c248bc7841c` |

| Saved evidence | SHA-256 |
|---|---|
| `.planning/phases/178-preview-authoring-and-milestone-review/178-VERIFICATION.md` | `c6f7cb00c4c32b8cb512d60ffca6a63eee7fc5d95c91730163bb01dd3f34b8d1` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase174/cost.json` | `f8f99487604e0ab3f5a411fbf13995eb5e5e037ce75e26dcc14954a166094279` |

The lock changes introduce no endpoint, authentication path, schema, or additional trust boundary. Their security effect is limited to replacing the previously rejected vulnerable package version in the three audited dependency graphs.

## Task 178-20-02 — Demo environment and evidence ownership

**Status:** Pending review and commit.
