# Phase 184: Close Admin and docs browser evidence gaps - Research

**Researched:** 2026-11-18
**Candidate base:** `a295e9a950e14d7ce3ec9456f31fbda864933580`
**Scope:** One authorized gap-closure plan and one exact-SHA candidate route.

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

## Not authorized

No new npm dependency, browser/package/image install, image pull, workflow retry/rerun, second candidate dispatch, third preview, favicon recapture, new product behavior, merge, release, deploy, tag, archive, or owner-worktree cleanup.

---

*Phase: 184-Close Admin and docs browser evidence gaps*
*Research base: a295e9a950e14d7ce3ec9456f31fbda864933580*
