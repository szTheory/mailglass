# Phase 184: Close Admin and docs browser evidence gaps - Research

**Researched:** 2026-11-18
**Candidate base:** `a295e9a950e14d7ce3ec9456f31fbda864933580`
**Scope:** Original 184-01 route plus the owner-authorized 184-02 recovery addendum below.

## Findings

### Candidate CI failures

- The whole-repository formatter job found two pre-existing unformatted test files: `test/mailglass/publish/brand_asset_allowlist_test.exs` and `test/mailglass/docs_migration_smoke_test.exs`. Run the whole-checkout format check before lengthy suites and format only those files if needed.
- `test/scripts/brand_docs_contract_test.exs` creates `README.html`, while `scripts/brand_docs_check.exs` currently checks `readme.html`. The browser contract `mailglass_admin/e2e/docs-theme-contract.cjs` checks `README.html`; retained Phase 183 reports say package output contracts passed. Resolve the case from the exact generated output before changing the checker/fixture, and make every contract agree with that observed path.
- The docs fixture's inline CSS string triggers Credo's quote-count readability rule. Use a delimiter-appropriate raw sigil or equivalent that preserves the fixture's CSS bytes exactly.
- The Phase 177 browser spec's expected navigation name differs only in case from the rendered accessible name (`Mailglass sections` vs `mailglass sections`). Update the assertion to the observed accessible name and wait for the LiveView page content to be visible before asserting it; do not introduce a vacuous selector fallback.

### Playwright runtime

`reference/demo_app/Dockerfile` installs Debian's Node 18 runtime. The evidence runner executes the Demo Playwright 1.60 suite and then the Admin Playwright 1.65.1 suite inside the same `demo_e2e` container. The Admin lockfile declares Node `>=20`, while Playwright's official v1.65 release notes say Node 20 is no longer tested and recommend Node 22, 24, or 26. Select Node 22. Keep Phase 174 on its existing Node 18 / Playwright 1.60 path and scope Node 22 to the Admin 1.65.1 commands. The CI workflow already uses a commit-pinned `actions/setup-node` Node 22 step in other jobs; carrying its tool-cache runtime into the existing Demo job/container avoids a project dependency or replacement browser image. Add an explicit major-version preflight before the Admin `npm ci` and record the active Node version with existing evidence.

Primary source: [Playwright v1.65 release notes](https://playwright.dev/docs/release-notes) and [Playwright installation requirements](https://playwright.dev/docs/intro).

### Browser failure diagnosis

- Phase 177 browser coverage is in `mailglass_admin/e2e/phase177-account.spec.js`; the server-side nav test already uses the rendered lowercase accessible name.
- Preview Axe cells already run with zero retries. The reported `Target.createTarget` failure occurs at page creation before the assertions execute. Run one focused preview/theme cell in the existing pinned Playwright Docker path, one worker, zero retries, and the current timeout. Preserve the Axe tags, baseline equality and selectors. Capture enough browser/runner logs to classify a server readiness, browser process, or CDP target failure.
- Do not rerun the full operator suite merely to diagnose the target-creation seam. The repository's `scripts/gsd-regression-gate.sh` already has a pinned-image, resource-bounded, zero-retry browser path with a readiness relay.

### Docs browser on generated output

`scripts/verify_brand_docs.sh` owns one temporary output root, builds all three package docs there, checks the generated outputs, and passes that exact root to `docs-theme-contract.cjs`. The current browser command runs on the host; the browser contract accepts `--all --output-root`. Reuse the already available Playwright 1.65.1 image and keep the output root alive through the browser check. The container should see the checkout and output root read-only, run with bounded resources and no network, and fail closed if the exact image is absent; do not pull an image, install a browser, or fall back to stale checkout docs. Ensure `git show` can read the pinned source commit in the container, or provide the verified pinned blobs without changing their identity.

### Route and cost guard

- Before the single `workflow_dispatch`, complete cheap formatting, fixture/Credo, Node 22 runtime, selector/readiness, docs-browser image, and bounded Axe preflights.
- Keep the hosted run on the exact pushed candidate SHA and the existing CI workflow. Verify the Demo artifact contains `phase174/cost.json`, `phase175` evidence and source identity; verify expected/executed counts match; compare against the approved same-profile baseline. Both measured deltas must be within +5 minutes wall and +10 minutes runner. Failed checks, missing artifacts/receipt, count mismatch or over-budget results stop before preview.
- The previous candidate used +7.30 runner minutes of the +10-minute allowance, leaving 2.70 minutes of headroom. The Admin Node fix should reuse the already pinned Node 22 setup action and mounted tool cache; avoid a second large browser image pull or another Playwright install path.
- Only after hosted and cost gates pass is the one isolated candidate-owned Admin preview and independent review authorized. Preserve the old Phase 182-07 stop, owner worktree, and favicon source/capture stop.

## Recommended implementation shape

1. Repair formatting and deterministic docs fixture/Credo issues, resolving README filename casing against an actual temporary package build.
2. Add a Node 22 runtime preflight and provide Node 22 only to the Admin Playwright 1.65.1 leg inside the existing cost-recording evidence container; keep the Demo Playwright 1.60 leg on Node 18.
3. Fix the Phase 177 accessible-name selector/readiness assertion. Diagnose one preview Axe target-creation case with the existing Docker browser runner, unchanged timeout/assertions and zero retries.
4. Extend the docs verification script to run the browser contract in the already installed Playwright image against the exact generated output root, then clean the owned output.
5. Run only one exact-SHA hosted dispatch after local preflight. Enforce all CI, count, cost and resource gates before any preview.

## Original plan 184-01 boundary

Plan 184-01 allowed one candidate route and is now blocked before Mix. It did not authorize an alternate boundary or retry. No npm/browser/image installation, image pull, favicon recapture, new product behavior, merge, release, deploy, tag, archive, or owner-worktree cleanup was authorized by that plan.

## Recovery addendum for plan 184-02 — 2026-11-18

### Evidence verifier and baselines

- The retained 184-01 directory contains only source identity plus the docs-build log, PID, and exit receipts. Those three receipt hashes recheck, but the per-path owner/protected manifests and `184-01-route.cjs` helper do not exist. Do not claim a full 184-01 `verify-all` pass or reconstruct missing preimages from aggregate hashes.
- Before any Mix/source/browser action, create a Node-built-in-only route helper with deterministic `node:test` fixtures. It must verify a complete retained route manifest and authenticated candidate source; its verify modes must be read-only and fail closed on missing/tampered inputs, ambiguous attempt markers, or absent cleanup receipts.
- Capture sorted path/type/mode/symlink-target/content-hash manifests for owner WIP, dependencies/modules/browser roots, catalogs, favicon inputs, seeds, protected Phase 182-07 files, and all allowed report targets. Keep owner file contents and secrets out of evidence; retain only the path metadata and hashes necessary for deterministic comparison. Record report-target preimages separately. Capture source commit/tree identity and an authenticated source bundle or equivalent before candidate cleanup.

### Candidate-owned dependency snapshot

- The four owner dependency trees total approximately 133 MiB / 9,260 files, reside on the same APFS data volume as `/private/tmp`, and the read-only inventory found no symlinks or multiply linked files. About 309 GiB was free during this read-only check. No snapshot was created or tested.
- The host has the required Elixir `1.18.4-otp-27` / Erlang OTP `27.3.4.13` runtime when explicitly selected. The exact pinned Elixir/OTP Docker image is absent locally; the standard toolchain Compose target uses shared resources and is unsuitable as-is.
- A candidate-owned `cp -c` snapshot of each dependency tree is plausible and may fall back to a regular copy. It is not proven until the plan's disposable clone preflight and hash/path checks pass. Never use hard links or symlinks into owner caches. Before Mix, compare lockfiles, full inventories, modes and hashes; enforce candidate dependency snapshots read-only and write all build output under candidate-owned `_build` paths. No `mix deps.get`, package install, image build/pull, permission escalation, or fallback to shared owner deps. Any boundary failure stops before Mix and source repair.

### Hosted and preview gates

- CI policy classifies Demo Browser Evidence and Operator Browser Gate as advisory relative to the `CI Green` aggregate. Plan 184-02 must require those two lanes separately as phase gates rather than describe them as constituents of `CI Green`.
- Freeze the Operator inventory at 356 cases across 19 files: 355 pass, one named guarded skip, zero failed/flaky. Demo expects 169 cases in each cold and warm condition: 111 demo + 6 hooks + 26 fidelity + 26 Axe. Do not reuse the obsolete 310-pass Operator count.
- Require the `phase178-cost-disposition.v1` receipt bound to the full SHA and hashes of its seven inputs (baseline run/jobs, dispatch run/jobs, Operator log, Demo cost, and candidate `expected.json`). Baseline run: `40414024714`; absolute limits: 1,541 seconds wall time and 110.68333333333334 runner minutes. Both budget flags must pass; count-mismatch flags must be false. Missing/failed jobs, mismatched counts, missing receipt, or overage stops before preview.
- A preview remains conditional on the one exact-SHA push/dispatch and all separate phase gates plus the formal cost receipt. Preserve zero retries, unchanged +5/+10 ceilings, one isolated preview, two independent reviews, owner-demo resources, favicon stop, and Phase 182-07 stop.

## Updated recommended implementation order

1. Build and fixture-test the verifier; retain complete owner/protected/report-target baselines and authenticated candidate source before any effect.
2. Prove a disposable candidate-owned dependency snapshot is independent, hash-equal, read-only and within candidate roots; confirm explicit runtime and candidate build paths. Stop before Mix if any check fails.
3. Repair only the identified candidate seams, run cheap formatter/fixture/Credo/runtime/count preflights first, then one zero-retry docs/browser diagnostic route.
4. Push one exact candidate and dispatch once. Require CI Green plus the separate Demo and Operator gates, exact counts, formal cost receipt and existing timing ceilings.
5. Run one isolated preview and two independent reviews only after all gates pass; clean only task-owned resources and verify retained evidence without rerunning tests or CI.

---

*Phase: 184-Close Admin and docs browser evidence gaps*
*Research base: a295e9a950e14d7ce3ec9456f31fbda864933580*
