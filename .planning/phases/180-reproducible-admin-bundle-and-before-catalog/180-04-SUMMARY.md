---
phase: 180-reproducible-admin-bundle-and-before-catalog
plan: 04
subsystem: before-catalog-evidence
tags: [playwright, docker-demo, manifest, png, evidence, required-lane, exunit-contract-test, mutation-proof, brand-v2]

requires:
  - phase: 180-reproducible-admin-bundle-and-before-catalog
    provides: "180-01 byte-identical bundle gate (linux-amd64-cmp: identical), 180-02/03 root-only theme ownership (nested_theme_attr_count 0)"
provides:
  - "`MailglassDemo.CatalogSeed.seed!/0`: four missing delivery cases on Northstar plus a ten-case id map (`CATALOG_CASES_JSON=`)"
  - "`reference/demo_app/assets/catalog/{before-catalog.spec.js,capture-before-catalog.cjs}` and `playwright.catalog.config.cjs`: a re-runnable capture (clean-tree gate, restart, guarded reset, seed, 80-capture matrix, identity and budget gates, atomic promote)"
  - "Committed catalog `.planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/` (80 PNGs, 80 aria sidecars, `cases.json`, `manifest.json`)"
  - "`before_catalog_manifest_test.exs`: 48 tests in the required `support_contract_admin` lane, mutation-proven"
affects: [181-token-swap, 182-admin-words-and-layout, 183-docs-pass]

actuals:
  tokens: 155800
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Stage into the git-ignored `.cache/`, validate, re-check the tree, then `fs.renameSync` the whole directory (refuses an existing catalog_id)"
    - "Bind a committed artifact to the repository through working-tree bytes (sha256 plus git blob sha1) recomputed on every run, with a sidecar marker that must name the CURRENT bytes"
    - "Discarded warm-up screenshot before every real capture so the double capture is byte-identical"

key-files:
  created:
    - reference/demo_app/lib/mailglass_demo/catalog_seed.ex
    - reference/demo_app/assets/playwright.catalog.config.cjs
    - reference/demo_app/assets/catalog/before-catalog.spec.js
    - reference/demo_app/assets/catalog/capture-before-catalog.cjs
    - mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/
  modified:
    - .planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md

key-decisions:
  - "D-16 fallback driver NOT taken: the demo harness gave every D-19 guarantee (served identity, restart after the commit, clean tree); the driver stays at reference/demo_app/assets/catalog/"
  - "The seed runs on the pre-decided in-harness fallback branch (`docker compose run --rm --no-deps`) because `docker compose exec ... mix run` fails with eaddrinuse in 4 of 4 runs"
  - "`delivered-no-open` maps to the invite row (pm-demo-invite-001), not the receipt row, because the receipt row answers HTTP 400 on seeded data (deferred-items.md item 6)"
  - "A discarded warm-up screenshot precedes every real capture and both halves of the determinism self-test"
  - "Served JS identity is checked as 'the served bundle contains the committed hooks.js bytes', read with the XHR marker header Plug.CSRFProtection requires"

requirements-completed: [BRPIPE-03]

coverage:
  - id: D1
    description: "A committed before-catalog of 80 captures covers every router route and overlay on Northstar, Fjordline and Helios plus ten delivery cases, captured on a clean tree at the final source commit, 8,876,502 PNG bytes (cap 15,000,000), `nested_theme_attr_count` 0, double capture identical, served assets equal to disk and to the git blob"
    requirement: BRPIPE-03
    verification:
      - kind: integration
        ref: "DEMO_BASE_URL=http://127.0.0.1:4015/ node reference/demo_app/assets/catalog/capture-before-catalog.cjs (82 Playwright tests passed, 80 captures promoted as before-9eb9dee-20261115T022124Z)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs#the committed before-catalog every catalog directory validates, and each has at least one capture"
        status: pass
    human_judgment: false
  - id: D2
    description: "The required-lane validator rejects a flipped PNG byte, an unlisted file, dirty true, an over-cap budget, a traversal name, a stale server, an unknown or missing manifest key, a reset token, a non-reserved email, and each seeded-case rule violation; every rule has a mutation case"
    requirement: BRPIPE-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs (teeth: file and budget rules, privacy rules, seeded-case rules; 48 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mutations: weakened sha256 compare (1 red), unconditional binding pass (11 red), dropped nil-reason rule (1 red), dropped superseded_by-versus-checkout comparison (5 red), real catalog byte flip / unlisted PNG / dirty true / moved bundle (each red); all restored with git checkout and re-run green"
        status: pass
    human_judgment: false
  - id: D3
    description: "The catalog is bound to the repository in a depth-1 checkout with no git object: LIVE while the checkout's app.css sha256 and root layout blob equal the recorded values, otherwise a superseded.json naming the CURRENT bytes; a wrong or stale marker is red"
    requirement: BRPIPE-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs#teeth: source binding (i)-(xi)"
        status: pass
      - kind: integration
        ref: "cd mailglass_admin && mix verify.support_contract.admin (1389 tests, 0 failures; prints 'catalog before-9eb9dee-20261115T022124Z: LIVE')"
        status: pass
    human_judgment: false
  - id: D4
    description: "The seed and the committed cases.json follow the milestone stop line: no retry-timing or cause copy, the two nil-reason seeded cases carry no reject_reason and no last_error, `typo-bounce` carries reject_reason invalid, `send-failed` carries only the adapter's own last_error; stop_line_hits is 0 in all 80 captures"
    requirement: BRPIPE-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs#teeth: seeded-case rules (D-22)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The manifest test passes in the real `support_contract_admin` CI run on the phase PR (depth-1 checkout on ubuntu-latest)"
    requirement: BRPIPE-03
    verification: []
    human_judgment: true
    rationale: "Only the phase PR's first support_contract_admin run can supply it, and the PR is not open yet. The verifier reads the run ID and the catalog LIVE line from the lane itself."

duration: 30min
completed: 2026-11-15
status: complete
commits: 7
plan_head_before: 7fa05586eeb95253b78ac09f3e0dd8e4d1d100e4
plan_head_after: 185da0c4b23d54add78809b7d042d7260050efac
---

# Phase 180 Plan 04: Before-Catalog Summary

**An 80-capture "before" catalog (8.88 MB of PNG, aria sidecars, `manifest.json` carrying the source commit and content identities) of every current admin route and overlay on the Northstar, Fjordline and Helios fixtures plus ten delivery cases, produced by a re-runnable driver that refuses a dirty tree and a stale server, and validated in the required lane by a 48-test, mutation-proven manifest test that binds it to the repository through working-tree bytes only.**

## Performance

- **Duration:** 30 min (started 2026-11-15T01:59:43Z, last commit before this SUMMARY about 02:26Z)
- **Tasks:** 3 of 3 (Task 1 was the tracer)
- **Commits:** 7 (measured: `git rev-list --count 7fa05586..185da0c4`)
- **Files:** 5 created source files, 1 catalog directory (162 files), 1 planning file modified

## Accomplishments

- **Tracer (Task 1).** One capture flowed through restart, guarded reset, seed, capture, served-identity checks and manifest assembly into the ignored staging directory (the staged manifest passed the Task 1 node check). Tracer gate: Tracer verified end-to-end, expanding.
- **Full matrix (Task 2).** 80 captures in 40.9 s of Playwright time: Fjordline 22 (overview, deliveries, delivery quick view, delivery full detail, inbound at 375/1440 x light/dark, plus overview and deliveries at 768 light), Northstar inbound overlays 2, preview index / preview show (html tab) / gallery 12, Northstar and Helios lists 12, ten delivery cases on the full-detail screen 30, two-subjects list 2.
- **Final capture and promote (Task 3).** Run on a clean tree at `9eb9deed` after the W-2 precondition held (`linux-amd64-cmp: identical`); atomic rename to `before-9eb9dee-20261115T022124Z`, committed alone (162 files, none outside the catalog directory).
- **Required-lane validator.** `before_catalog_manifest_test.exs`: 48 tests, no `System.cmd`, no git object, no skip branch. The real catalog evaluates as LIVE; the teeth cover every rule on a synthetic catalog.

## Task Commits

1. **Task 1 (tracer)**
   - `90b63790` chore(demo): add the before-catalog seed for the four missing delivery cases
   - `b60c7dc3` chore(demo): add the before-catalog capture spec, config and driver
   - `02190677` chore(demo): warm up each catalog screenshot and read the js asset as XHR (tracer fix, see Deviations 1 and 2)
2. **Task 2**
   - `be82760e` chore(demo): capture the full before-catalog matrix with budget and identity gates
   - `9eb9deed` chore(demo): map the delivered-no-open case to the invite row (see Deviation 3)
3. **Task 3**
   - `a884b2bf` docs(brand): add the brand v2 before-catalog before-9eb9dee-20261115T022124Z
   - `185da0c4` test(admin): validate the committed before-catalog manifest in the admin lane

The catalog's own commit is `a884b2bf`. A manifest cannot contain the SHA of the commit that adds it (D-19), so the manifest records the SOURCE commit `9eb9deedfcdc435f2ac01bfd9dc2a441e8042662` and this SUMMARY records the commit that added the catalog.

## What the catalog says about its own sources

- **Before includes the BRPIPE-02 fix and the 180-01 gate (D-20).** `nested_theme_attr_count` is 0 in the manifest and in every capture, and the bundle is the reproducible 136,877-byte `app.css` (`sha256 173fdd6f...f6b2`, git blob `1d43e59c...`, root layout blob `132731a7...`). No token, font or logo change precedes it.
- **Identity.** `run_id mailglass-evidence-20261115022124-42567-10362`, `source_digest a37e6953...ebac` (computeSourceIdentity), commit time 02:19:24Z, server started 02:21:26Z (after the commit), seed anchor 02:21:35Z, Playwright 1.60.0, Chromium 148.0.7778.96, Node v26.10.0, darwin 25.6.0 arm64.
- **Served assets.** css `/dev/mail/css-bb2156de84d3550bfa21a10048441e91` and the js bundle both `matches_disk` and `matches_git_blob`; the served css sha256 equals `source.bundle.sha256`.
- **Seed command:** `docker compose run --rm --no-deps -T demo mix run -e CatalogSeed.seed!()` (the in-harness fallback). The primary `docker compose exec` command fails with `eaddrinuse` (deferred-items.md item 7), so the driver resets again and takes the fallback on every run. **D-16 fallback driver not taken.**

## Measured budget (replaces the estimated table in the plan)

| Tier | Shots | Bytes (promoted run) | Plan estimate (expected) |
|------|-------|----------------------|--------------------------|
| A Fjordline (lists, quick view, full detail, inbound, 768) | 22 | 1,684,000 B (1.684 MB) | 0.65 + 1.20 = 1.85 MB |
| B Northstar + Helios | 12 | 1,529,000 B (1.529 MB) | 1.11 MB |
| C ten cases x 3 + two-subjects list x 2 | 32 | 4,300,000 B (4.300 MB) | 4.50 + 0.30 = 4.80 MB |
| D preview index/show + gallery (viewport clip) | 12 | 1,050,000 B (1.050 MB) | 0.70 + 0.14 = 0.84 MB |
| E Northstar inbound overlays | 2 | 314,000 B (0.314 MB) | 0.30 MB |
| Total | 80 | 8,876,502 B (8.877 MB) | 8.9 MB |

(Tier figures are the driver's rounded decimal MB; the exact total is 8,876,502 B.) **No cut applied; the cut order was not needed, and the final count is 80.** The B tier is above its estimate because the Northstar 375 dark deliveries shot is 375 x 6065 px (487,232 B). Largest shots: that one, Northstar inbound 375 dark (201,111 B), Northstar deliveries 1440 light (181,094 B).

## Case-to-row mapping (cases.json of the committed catalog)

| Case | Source | Provider message id | Recipient | Scenario | Status | reject_reason | last_error | Metadata keys |
|------|--------|---------------------|-----------|----------|--------|---------------|------------|---------------|
| typo-bounce | catalog_seed | pm-cat-typo-bounce-001 | maya.okafor@northstr.example | catalog_typo_bounce | sent (last event bounced) | invalid | no | scenario, subject |
| send-failed | catalog_seed | none | dispatch@northstar.example | catalog_send_failed | failed | null | yes (adapter's own) | scenario, subject |
| sent-no-report | catalog_seed | pm-cat-sent-no-report-001 | finance@northstar.example | catalog_sent_no_report | sent | null | no | scenario, subject |
| unicode-recipient | catalog_seed | pm-cat-unicode-recipient-001 | zoë.müller@northstar.example | catalog_unicode_recipient | sent (delivered) | null | no | scenario, subject |
| nil-reason-bounce | demo_data | pm-demo-payment-failed-001 | billing@northstar.example | payment_failed | sent (bounced) | null | no | invoice_id, retry_window, scenario, subject |
| deferred-no-retry | demo_data | sg-demo-badge-deferred-001 | deferred@northstar.example | badge_deferred | sent (deferred) | null | no | scenario, subject |
| delivered-no-open | demo_data | pm-demo-invite-001 | mira.chen@northstar.example | invite_admin | sent (delivered) | null | no | journey, persona, scenario, subject |
| long-recipient | demo_data | pm-demo-truncation-stress-001 | operations.billing.notifications.enterprise.accounts@northstar-stress.example | truncation_stress | sent (delivered) | null | no | scenario, subject |
| complained | demo_data | sg-demo-badge-complained-001 | complained@northstar.example | badge_complained | sent (complained) | null | no | scenario, subject |
| manual-suppressed | demo_data | none | ops@northstar.example | incident_update | suppressed | null | no | incident, scenario, status, subject |

`manual-suppressed` is the DemoData row whose metadata scenario is `incident_update`, that is mailable `MailglassDemoWeb.Mailers.OperationsMailer.incident_update` (shown on screen as `OperationsMailer.incident_update`). The Tier A overlays opened Fjordline's single delivery, the long-module-name row `Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName` (recipient `bjorn.hansen@fjordline-aps.example`, subject "Welcome to Fjordline A/S", delivered). The Northstar inbound overlays opened the first inbound row ("Unrouted vendor notice", unrouted).

Both nil-reason seeded cases (`sent-no-report`, `unicode-recipient`) carry no reject_reason, no last_error and exactly the two metadata keys. `stop_line_hits` is 0 in all 80 captures and `relative_time_hits` is 0, so the screens, as captured, render no "next try at", no "will retry" and no relative time.

## Sampled visual check (agent, METHODOLOGY; Read tool on committed PNGs)

| Tier | Capture | Observed |
|------|---------|----------|
| A | `delivery-quick-view__fjordline-aps__open__1440__light` | Quick view overlay over the Fjordline deliveries list: "Welcome to Fjordline A/S", Delivered badge, "Replay is unavailable..." panel, Open full detail. Intended screen, theme and fixture. |
| B | `overview__helios-void__default__375__dark` | Helios Trial "Email health" empty state ("No mail activity in this period", 0 deliveries, 0 messages). Intended. |
| C | `delivery-detail__send-failed__default__375__dark` | Failed badge, provider UNKNOWN, timeline with one Failed event, no cause sentence (a gap the catalog records, not a seeded cause). Intended. |
| C | `delivery-detail__typo-bounce__default__1440__light` | Bounced badge, recipient at northstr.example, timeline Sent then Bounced with "Reason: Invalid". Intended. |
| C list | `deliveries__two-subjects-billing__default__1440__light` | Search "billing@northstar.example", two rows, different subjects, Bounced and Delivered. Intended. |
| D | `preview-show__any__html__375__dark` | Billing payment_failed, dark admin chrome, email iframe at 768 px clipped inside the 375 px pane. Intended; the clipping is today's behaviour. |
| D | `gallery__any__default__375__dark` | Component Gallery clipped to the viewport (icon, logo, flash). Intended. |
| E | `inbound-detail__northstar__first-message__375__dark` | Inbound full detail "Unrouted vendor notice". Intended. |

## Evidence (commands run from the repository root unless noted; all local)

| Check | Command | Result |
|-------|---------|--------|
| Task 1 verify | `cd reference/demo_app && mix compile --warnings-as-errors` and the staged-manifest node check | exit 0; `staged before-0219067-20261115T021054Z` |
| Task 2 verify | smoke set through the spec alone (`CATALOG_ONLY=smoke`) plus the records check | 8 passed; `smoke 6 6`; rc 0 |
| Phase gate: driver smoke | `DEMO_BASE_URL=http://127.0.0.1:4015/ node reference/demo_app/assets/catalog/capture-before-catalog.cjs --only smoke --no-promote` plus the manifest node check | 6 captures, 644,902 B; tiers A-E present; determinism, served identity, nested count, root attribute all pass |
| Full dry run | `... capture-before-catalog.cjs --no-promote` (before the case remap, then after) | first run: 79 passed, 3 failed (Deviation 3); second run: 82 passed, 80 captures, 8,877,993 B |
| Final capture | `... capture-before-catalog.cjs` | 82 passed, promoted `before-9eb9dee-20261115T022124Z`, 80 captures, 8,876,502 B |
| Task 3 verify | `cd mailglass_admin && mix test test/mailglass_admin/before_catalog_manifest_test.exs --warnings-as-errors --seed 0` | 48 tests, 0 failures; prints `catalog before-9eb9dee-20261115T022124Z: LIVE` |
| Ancestry (one-shot) | `git merge-base --is-ancestor 9eb9deedfcdc435f2ac01bfd9dc2a441e8042662 HEAD` | exit 0 |
| Render-input diff (one-shot) | `git diff --quiet 9eb9deed HEAD -- mailglass_admin/lib mailglass_admin/priv/static mailglass_admin/assets reference/demo_app/lib lib brandbook` | exit 0 |
| Required lane | `cd mailglass_admin && mix verify.support_contract.admin` | `Admin bundle matches a fresh build (136877 bytes).`, 1389 tests, 0 failures, 1 excluded; catalog LIVE |
| Format | `cd mailglass_admin && mix format --check-formatted` | exit 0 |
| Acceptance greps | tracked catalog: `manifests=1 pngs=80 cache=0 image_count=80`; no `System.cmd` in the test (0); `superseded.json` 21 mentions, `superseded_by` 18; no `superseded.json` in the catalog; demo_data.ex and personas.ex unchanged since 7a848162 | all hold |

### Mutation protocol (METHODOLOGY), each restored with `git checkout --` and re-run green (48 tests, 0 failures)

| Mutation | Result |
|----------|--------|
| (a) sha256 comparison weakened (`true or ...`) in the test source | 1 red: `a flipped PNG byte names the sha256 mismatch` |
| (b) binding decision replaced by an unconditional pass | 11 red: (ii), (iii), (v), (vi) x4, (x) x2, (xi) x2; (i) and (iv) stay green |
| (c) nil-reason `metadata_keys` rule dropped | 1 red: `reason added to the sent-no-report metadata_keys is red` |
| (d) `superseded_by` versus current checkout comparison dropped (any well-formed marker accepted) | 5 red: (vi) recorded values, (x) x2, (xi) x2; (iv) stays green |
| Real catalog: one PNG byte flipped | red: `gallery__any__default__1440__light.png: sha256 mismatch against the manifest` |
| Real catalog: an unlisted PNG added | red: `unlisted file extra__any__default__375__light.png` |
| Real catalog: `"dirty": true` | red: `source.dirty must be false` |
| Checkout `app.css` one line appended, no marker | red (the LIVE branch no longer holds and no `superseded.json` exists) |

### Lane table

| Proof | Lane |
|-------|------|
| `before_catalog_manifest_test.exs` (shape, files, budget, binding, seeded cases, privacy, teeth) | REQUIRED: `support_contract_admin` (whole test directory, no registration) |
| The capture run, the demo Playwright spec, the driver | NOT CI; never cited as proof |

## Phase 181 hand-off

The Phase 181 bundle regeneration commit must add `before-9eb9dee-20261115T022124Z/superseded.json` (schema `mailglass.before_catalog.superseded.v1`, keys `schema, catalog_id, superseded_by, superseded_in, reason`) whose `superseded_by` is `{"bundle_sha256": <new app.css sha256>, "root_layout_git_blob_sha": <new root layout blob sha1>}`; the required lane goes red until it does, and the red message prints both values. Every later bundle or root-layout change, in any phase, updates `superseded_by` (and `superseded_in` / `reason`) in its own PR: one marker update per change. The catalog PNGs, `cases.json` and `manifest.json` stay immutable. If any later commit touches a render input before merge (`mailglass_admin/lib`, `priv/static`, `assets`, `reference/demo_app/lib`, `lib`, `brandbook`), the catalog must be recaptured under a new catalog_id and the stale directory removed in the same PR (new PNGs are permanent history, D-21).

## Refinements of locked decisions

- D-24 (ancestry): durable "`git_sha` is an ancestor of HEAD" is replaced in the required lane by working-tree content identity (bundle sha256 + root layout blob sha1, LIVE or a current-bytes `superseded.json`), because main is squash-merged, so after merge the source commit object is not in main's history and a perpetual ancestry check would be red or skipped. The strict `git merge-base --is-ancestor <git_sha> HEAD` and the render-input diff run once, at PR open, and their outputs are recorded as evidence (backstop truth). The durable binding covers only the bundle bytes and the root layout; see "Disclosed limits" under OQ3.
- D-19 (fixed timestamps): the seed minute is recorded (`determinism.seed_anchor_utc`, `fixed_time: null`) instead of seeding at fixed absolute timestamps, because that would need an anchor seam in the guarded DemoData module, which D-22 forbids editing. Consequence: re-captures in different runs are not byte-identical; the double capture within one run is (the self-test enforces it), and relative-time text is still refused.
- D-07 (cross-platform proof ordering): recorded in 180-01-PLAN.md decisions_recorded (emulated linux/amd64 run first, real ubuntu-latest proof from the phase PR's first `support_contract_admin` run). Listed here so all phase refinements are findable in one place.

## Disclosed limits of the required-lane binding

- A PR that rewrites `source.bundle`, `served.assets` and `source.root_layout` in `manifest.json` in lockstep to new bytes passes the LIVE branch. That class is review-only (it would also change the manifest sha256 that Phases 182-183 cite, which a reviewer sees in the diff); nothing in `before_catalog_manifest_test.exs` catches it.
- The durable binding covers exactly the bundle bytes (`mailglass_admin/priv/static/app.css`) and the root layout (`mailglass_admin/lib/mailglass_admin/layouts/root.html.heex`). `lib/**`, `brandbook/tokens.css`, `reference/demo_app/lib` and `assets/` are verified only once, at PR open, by the recorded render-input diff (exit 0 above); after merge, a catalog made stale by those inputs is caught by Phase 182's reviewer, not by this lane. No render-input digest was added (scope).
- The marker is a sidecar, not a manifest edit, because Phases 182-183 cite the manifest sha256 (D-17). `fetch-depth: 0` was rejected: it adds a full-history fetch to every run of a required job and still cannot prove ancestry after squash-merge.

## ROADMAP criterion 4 deviation

The preview text, headers and raw-envelope tabs are not captured. This is a recorded budget cut at the 80-image cap (plan decisions_recorded "Capture map"): they follow the admin theme after 180-02 and share the preview-show chrome, and the text tab is the first to add if a later recapture has room (the measured total is 8.88 MB, so a recapture has byte room; the count cap of 80 is the binding limit). Criterion 4's "each current admin screen" is therefore met per router route and overlay (preview index, preview show html tab, gallery; operator overview, deliveries, delivery quick view, delivery full detail; inbound list, inbound quick view, inbound full detail), not per preview tab. Storybook is out of scope (OQ1).

## Late byte-proof (W-2)

`180-01-SUMMARY.md` carries `linux-amd64-cmp: identical` (the official linux-x64 4.1.12 binary, emulated, byte-identical to the committed bundle), so the `## Accepted risk: late ubuntu-latest byte proof` section is not needed. The real ubuntu-latest proof is the phase PR's first `support_contract_admin` run: run ID and its `--check` line are pending (no PR open yet). If that run shows a byte mismatch, the cost in the plan applies: a `ci:`/`chore:` commit pins the check to the CI platform and does not touch `mailglass_admin/priv/static` unless the committed bytes must change, in which case the catalog is recaptured under a new catalog_id in the same PR.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The double capture of the self-test screen differed on the first run**
- **Found during:** Task 1 tracer
- **Issue:** the first screenshot after a page load differed from the next two by one colour level in 3 anti-aliased pixels (max channel delta 1 on `/dev/mail`); the second and third were identical, so the determinism gate failed.
- **Fix:** a discarded warm-up screenshot precedes every real capture and both halves of the self-test (`shoot()` in the spec). Probed on `/dev/mail` and `/dev/mail/gallery`: three captures then byte-identical.
- **Files modified:** `reference/demo_app/assets/catalog/before-catalog.spec.js`
- **Commit:** `02190677`

**2. [Rule 3 - Blocking] The served js asset answered 403**
- **Found during:** Task 1 tracer
- **Issue:** `Plug.CSRFProtection` rejects a plain GET for a JavaScript body (cross-origin script guard), so the served-identity check could not read the bundle.
- **Fix:** the request sends `x-requested-with: XMLHttpRequest`.
- **Files modified:** same spec. **Commit:** `02190677`

**3. [Rule 3 - Blocking] The `delivered-no-open` case row answers HTTP 400**
- **Found during:** Task 2 full dry run (3 of 80 captures timed out)
- **Issue:** the plan mapped `delivered-no-open` to `pm-demo-receipt-001`. Its quick view and full detail return `400 Ecto.Query.CastError` (`lib/mailglass/operator/replay_targets.ex:101`) because DemoData seeds replay events on it with `webhook_event_id` values `demo-replay-wh-001` / `-002`, which are not UUIDs.
- **Fix:** mapped the case to `pm-demo-invite-001` (delivered, no open event, no replay events, renders HTTP 200) in `CatalogSeed`. DemoData, persona_spec and core `lib` untouched (D-22; a core fix would change the "before"). The defect is logged in `deferred-items.md` item 6 with the evidence and a suggested follow-up; it is not captured as a screenshot.
- **Files modified:** `reference/demo_app/lib/mailglass_demo/catalog_seed.ex`. **Commit:** `9eb9deed`

**4. [Process] A second clean-tree recheck immediately before the rename**
- The plan puts the recheck in step (h) and requires nothing between it and the rename. The driver also re-checks right before `fs.renameSync` (after the manifest write), which only tightens the guard.

**5. [Process] Commit subjects follow the plan's prescribed forms** (`chore(demo):`, `docs(brand):`, `test(admin):`), not `{type}({phase}-{plan})`, so Guard Release Trigger classifies by kind. The authoritative record is `plan_head_before..plan_head_after` (7 commits, measured).

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3), 2 process notes. **Impact on plan:** none on scope. The catalog has the full 80 captures and ten distinct cases; the receipt row's defect is recorded rather than shipped as evidence.

## Issues Encountered

- **The primary seed command cannot run beside the live server.** `docker compose exec -T demo mix run -e ...` fails with `eaddrinuse` (4 of 4 runs); the driver resets again and runs the fallback. Each driver run therefore resets twice. Logged as `deferred-items.md` item 7 (`make demo-reset` very likely has the same defect; not run).
- **`/dev/mail` redirects to the first scenario** (`AccountMailer.invite_admin`), so `preview-index` shows a Preview pane, not a list (`deferred-items.md` item 8).
- **Stale staged directories.** A failed tracer left a staged `before-*` directory whose sha7 sorts after later ones; the plan's `sort().pop()` node check reads by name, so I removed stale staged directories between runs. All staged directories are deleted (git-ignored, never committed).

## Known Stubs

None.

## Threat Flags

None. The driver talks only to the loopback demo container and reuses `resetDisposableEvidence` unchanged (T-180-15). Promote is atomic into a validated path (T-180-13, T-180-17); the catalog holds only RFC 2606/6761 addresses and no reset token or environment value, enforced by the driver and by the required-lane test (T-180-14); the budget is enforced in both (T-180-18). T-180-19 (lockstep manifest rewrite, post-merge staleness) is accepted and disclosed above. T-180-SC: no package added.

## Follow-ups

- **Phase 181:** add `superseded.json` in the same change as the bundle regeneration (hand-off above).
- **Phase PR:** append the first `support_contract_admin` run ID and its `--check` line here and to VERIFICATION.
- **Owner-visible, separate:** the receipt-row defect (`deferred-items.md` item 6), the `exec` seed failure (item 7), the earlier Preview axe-cell decision (180-03).

## Release effect

`chore(demo):` (`reference/demo_app`), `docs(brand):` (`.planning`) and `test(admin):` (`mailglass_admin/test`) are non-bump kinds (only `feat`, `fix` and `!` bump, per `scripts/guard_release_trigger.sh`). No `lib`, `priv/static` or release config changed; `.planning/release-target.json` is untouched. The catalog and the manifest test must ship in the same PR (a `.planning`-only change skips `support_contract_admin`).

## Next Phase Readiness

- Plan 180-04 is the last plan of phase 180; the phase is ready for verification and the phase PR.
- Phases 182-183 cite `catalog_id before-9eb9dee-20261115T022124Z` and the manifest sha256 (`sha256sum` of `manifest.json`).

---
*Phase: 180-reproducible-admin-bundle-and-before-catalog*
*Completed: 2026-11-15*

## Self-Check: PASSED

- Created files exist: `catalog_seed.ex`, `playwright.catalog.config.cjs`, `before-catalog.spec.js`, `capture-before-catalog.cjs`, `before_catalog_manifest_test.exs`, the catalog directory (80 PNG, 80 aria, `manifest.json`, `cases.json`).
- All seven commits are ancestors of HEAD: `90b63790`, `b60c7dc3`, `02190677`, `be82760e`, `9eb9deed`, `a884b2bf`, `185da0c4`.
- Acceptance greps and the one-shot ancestry and render-input checks hold; required lane 1389 tests, 0 failures; format clean.
