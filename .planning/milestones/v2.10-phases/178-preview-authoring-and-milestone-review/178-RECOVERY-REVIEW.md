# Phase 178 Recovery Review

**Status:** Pass; `unresolved_high: 0`.
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

**Disposition:** Pass. **ASVS L1 high-severity findings:** 0.

The Compose change gives `demo_e2e` the same named Mix/Hex, dependency/build, npm, and Playwright caches as `demo`. The runner sets a unique `mailglass-evidence-$RUN_SUFFIX` Compose project name for each evidence run; the retained demo remains under the separate `mailglass-demo` project. The cleanup trap calls `down --volumes --remove-orphans` only for that run-specific project and only after this wrapper has started its services. No host port exposure or new network endpoint was introduced.

The Phase 175 container command now runs `MIX_ENV=test mix deps.get --check-locked` before building Admin assets, using the already locked dependency graph. The exit trap returns ownership for the Phase 174 condition directory and the Phase 175 directory. Both paths are derived from the validated run evidence root, which the existing `resolveEvidenceOutputPath` check confines beneath the evidence root and rejects if a path component is a symlink. The container uses `chown -Rh`; it changes ownership without changing permission bits and does not dereference symlinks. The saved private Axe receipts remain mode `0600`; no `chmod` was introduced, and retained evidence copies use `cp -a`.

The wrapper contract test checks the dependency ordering and ownership loop but does not execute the container command or prove mounts by itself. The saved cold/warm local pilot exercised the real Compose path and both evidence checkers: Phase 174 reports 169/169 expected cases in each condition; Phase 175 reports 10/10 Admin operator cases and 26/26 Axe cases in each condition, with zero Axe violations. The actual `admin_operator_exit_code` is 0 for both conditions, and run-owned volumes were removed. These are local results only.

The current selected-source digests match the saved pilot bytes: Phase 174 `3d663eb790db0894f36ce8de9df0bc10a16e92e6a4133ffe370dc42363a62794`; Phase 175 cold and warm `b0fab6e1575713038c0b743d8b76b5e10796a55441e3e24fb8b12374ebe05cad`. The saved pilot records dirty source revision `afc308405b36da7f4d86bb795129d0acc680517c`; the digest match establishes the reviewed selected bytes but does not turn that local pilot into clean-commit or hosted evidence. `178-VERIFICATION.md` summarizes the passing local Hex audit, three locked-dependency checks, wrapper contract, shell syntax, Compose config, and pilot; raw logs for the three dependency checks were not retained.

| Reviewed source | SHA-256 |
|---|---|
| `compose.demo.yml` | `35c152ffccdc1371a425a39dfbb186346a2afd8ff61018b5f5e256931bf2f33a` |
| `scripts/run_demo_browser_evidence.sh` | `6e4555428db9f797368cf715ff0fd8cbd726ca95f8442ff397a7eb58fbae2473` |
| `scripts/test_run_demo_browser_evidence.sh` | `8e63f6f7d6f5d7e375b75310adf4e53242e3be8db5293587f6ec8996107ccb8c` |

| Saved evidence | SHA-256 |
|---|---|
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase174/cost.json` | `f8f99487604e0ab3f5a411fbf13995eb5e5e037ce75e26dcc14954a166094279` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase174/execution.json` | `627373873100f3c1058458630e98f8b3223c7dac3a4cb0a30af0a57d0b5ffb06` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase174/cold/axe.json` | `4f8792cdf1dcf6306dabc6b5adaa7217e86247a33bcdeef7c2d0fec6330810b6` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase174/warm/axe.json` | `44160e726d9ec1cd6b0619fbde7d01062db7682891ddce9b07e004b708f061de` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/run.json` | `d6bf3064f96e525a144eb26578690416daf0741670a8b9a2e830cb27f2755e9a` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/execution.json` | `835f2c64f77d9cdff13da656865c7ca55770823d78292cee32bae6a8c4c08e3e` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/cold/runtime.json` | `e569d3bd9a0ff0bff3a898d3d6eefd43e6ea0db186aa982467695e192a4276ff` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/warm/runtime.json` | `7dfccc5f4e4c52fb347d17dbc8dd54f3cbfa617c19cc677a12e8d29990235961` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/cold/axe.json` | `4f8792cdf1dcf6306dabc6b5adaa7217e86247a33bcdeef7c2d0fec6330810b6` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/warm/axe.json` | `44160e726d9ec1cd6b0619fbde7d01062db7682891ddce9b07e004b708f061de` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/cold/admin-playwright-report.json` | `fbef2696de85cd0f649b3ead88f06f7e7eebfd1f13093da0aa26ba64057a4702` |
| `reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101232222-19011-19944/phase175/warm/admin-playwright-report.json` | `d9b9ef013c8139345463f74696d56affb32936eb822307e23289616335175617` |

No high-severity issue was found in the reviewed source scope. The only test-scope limitation is that the wrapper contract alone cannot demonstrate real Compose ownership; the saved dirty-tree pilot supplies local runtime evidence for the exact selected source bytes. Hosted behavior, hosted cost, candidate approval, and preview status remain unverified.
