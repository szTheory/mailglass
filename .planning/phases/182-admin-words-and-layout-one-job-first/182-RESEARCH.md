# Phase 182: Admin Words and Layout, One Job First - Research

**Researched:** 2026-11-15
**Domain:** Phoenix LiveView admin UI (words, status marks, time zones, layout) over an existing Ecto read model, with mutation-proven ExUnit contract tests and a Playwright capture pipeline. No new packages.
**Confidence:** HIGH on codebase facts (every cited line was opened this session); MEDIUM on three product-truth risks (R1-R3 below) that need a planner decision, not more research.

<user_constraints>
## User Constraints (from 182-CONTEXT.md)

The 25 locked decisions are reproduced here as their **verbatim bold headline sentences**. Each decision's sub-bullets (draft strings, test lists, mutation lists, file:line refs) are equally binding and live in `/Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-CONTEXT.md` lines 17-95. Do not re-litigate any of them; section "CONTEXT corrections" below lists only places where the live tree makes a decision unimplementable *as written*, each with a recommended resolution that preserves the decision's intent.

### Locked Decisions
- **D-01:** **Five verdicts, one per `StatusMap.delivery_class/1` class** (Sent, Delivered, Delayed, Failed, Not sent).
- **D-02:** **"Sent is not delivered" lives in every Sent-class verdict, unconditionally.** (fixed fallback sentence: "No reason was recorded for this email."; banned: "successfully", "Oops", "unfortunately", "will", "should arrive"; never render `last_error`.)
- **D-03:** **The brand book's own example sentences conflict with the stop line and lose.**
- **D-04:** **Cause text is structural, not just filtered.** (`Copy.cause_sentence/1` by comprehension over the enums, no `nil` clause; `Copy.cause_or_fallback/1`.)
- **D-05:** **Do the additive core change; do not settle for showing the limitation.** (`bounced_at`, `terminal`, `delivered_at`, `complained_at`, `suppressed_at` on `delivery_projection/1`; `outcome_groups` agrees; new core test file; isolated `feat(core):` commit; api_stability wording.)
- **D-06:** **Admin degrades honestly when keys are absent.**
- **D-07:** **"Needs attention" stays a summary count plus row marks, not a filter (owner-vetoable default).**
- **D-08:** **Server renders "H:MM AM/PM UTC"-style absolute time with its zone; the browser upgrade keeps the zone.**
- **D-09:** **Every time is a `Components.timestamp`.**
- **D-10:** **Status = pane mark + word, only through `status_badge`.**
- **D-11:** **Screen text only; flip `Copy.vocabulary/0` entries to `wired: true` and bind them.**
- **D-12:** **Orphan wording:** "N provider reports match no email", with singular "1 provider report matches no email".
- **D-13:** **Mailer plain name + accessible tooltip by reusing existing pieces.**
- **D-14:** **Pinned tests are updated in the same plan as each word.**
- **D-15:** **List screen order:** h1 "Activity" with the gloss line, a full-width labelled search ("Email address", `type=search`), the Needs attention summary, then all activity. **Detail screen order, verdict above the fold at 375px.**
- **D-16:** **A real password-reset scenario is needed.**
- **D-17:** **New test files only** (`phase182_time_status_contract_test.exs`, `phase182_cause_contract_test.exs`, `phase182_journey_test.exs`, `after_catalog_manifest_test.exs`).
- **D-18:** **Time/status contract (BRADM-02), three layers in one file.**
- **D-19:** **Cause contract (BRADM-06).**
- **D-20:** **BRADM-01 proof lanes.** (required `phase182_journey_test.exs`; advisory Playwright.)
- **D-21:** **BRADM-07 reviewer protocol (automated; the owner only vetoes).**
- **D-22:** Plan order (1 core projection, 2 the one job, 3 time/status everywhere, 4 words, 5 after-catalog and review).
- **D-23:** **Bundle and before-catalog rules carry over.**
- **D-24:** **Cheap pre-flight order before any long suite.**
- **D-25:** Commit kinds: admin `lib`/`priv/static` = `feat(admin):`; the core projection = `feat(core):`; `.planning`, brand files = `docs:`/`chore(brand):`; CI wiring = `ci:`.

### Claude's Discretion
- Exact copy tightening within D-02 claims for width, test file internals, the `status-marks.json` layout, the plain-name derivation module location, which seeded scenario ids already exist, and the `feat(core)` scope token the PR-title check accepts.

### Deferred Ideas (OUT OF SCOPE)
- Server-side "Needs attention" bucket filter (new core query parameter and compat-policy row); next-retry time, provider reason text and per-mailer rollups (INSIGHT-01..03).
- Tighten admin's published core pin to `~> 2.8` (separate `chore`/`build` commit); verify whether the linked-versions plugin really rewrites admin's `~> 2.0`.
- Feed the "will retry" / "Next try at" conflict back to the brand book repo (szTheory/mailglass-brand).
- A "sent too long, probably lost" state (needs an honest age rule and data we do not capture).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRADM-01 | Search by email, find the delivery under Needs attention, read verdict + "sent is not delivered" + next step, in light, dark, 375px | Search already filters recipient/subject via `ilike` (`lib/mailglass/operator/deliveries.ex:137-150`); it is hidden below `md` today (see C-6). Verdict data flow and Quick view limit: C-3. Projection fields: C-4. Journey test pattern: Validation Architecture. |
| BRADM-02 | Every time states its zone; every status is a pane mark + word | Real mark geometry extracted from the pinned book (C-1, Code Examples). Localizer fix and SSR format verified by running Elixir and Node (C-14). Offender list verified (C-13). Screen-registry approach verified by running it (Architecture, Pattern 4). |
| BRADM-03 | "Activity" label in screen text only, `deliveries_path` unchanged | Word inventory by plan (Blast Radius). Vocabulary binding semantics (C-8). |
| BRADM-04 | "Admin" replaces "Operator", "Account" replaces "Tenant" in on-screen copy | "Tenant" is already fully gone from on-screen text; "operator" still appears in 8 more on-screen lib sites than CONTEXT lists (C-12). |
| BRADM-05 | Orphan count reads "N provider reports match no email"; mailer plain name with accessible tooltip | Orphan site list with corrected lines (Blast Radius). Production `Delivery.mailable` holds the module only, not module + function (C-9). `field_help`/`module_identity` reuse verified. |
| BRADM-06 | Cause sentences only where reason exists; fixed fallback otherwise; contract-tested | Enum accessors for source-enumerated matrices verified (Pattern 3). Quick view has no reason data (C-3). Honest-fallback risk R1. |
| BRADM-07 | Separate agent reviews each scenario against the book, rejection gate, unique evidence paths, served SHA | Capture driver structure verified; validators in the before-catalog test are private (C-11); environment is capable (Environment Availability). |
</phase_requirements>

## Summary

CONTEXT is accurate on the large majority of its file:line claims (all of D-05's core refs, the localizer, the summary bucketing, `outcome_help`, the brand-book sentence lines, `catalogId` hard-coding, `release-please` state) and is wrong, stale or unimplementable-as-written in 18 places (C-1 to C-18 in "CONTEXT corrections"; C-1, C-3, C-4, C-6, C-8, C-11 and C-18 change plan content, the rest are inventory or wording fixes). The three that change plan content most: **(C-1)** the five pane marks are *not* check/triangle/cross/slash-circle/arrow; the pinned book draws a half-filled frame, a filled pane with a check, a frame with a clock hand, a filled pane with a crack, and a struck-through frame, and I extracted exact path data (below); **(C-3)** Quick view renders from the list-row projection only, so it cannot know a cause and must not print the "No reason was recorded" fallback; **(C-4)** `StatusMap` treats any non-nil value as "present", so a `false` boolean named `bounced_at` in `outcome_groups` would mis-classify every group as Failed (proved by running it).

The work is almost entirely reuse: `Copy` (add verdict data), `StatusMap.delivery_class/1`, `Components.status_badge`/`timestamp`/`field_help`, the Phase 175-178 contract-test template, and the Phase 180 capture driver. Nothing is installed. The only core change is the additive projection (D-05). The expensive hazards are not technical risk but pinned tests: `copy_contract_test.exs` has a rule (Part B) that, as soon as a class label is `wired: true`, requires **every** atom of that class to render the plain class word on its badge, which contradicts D-01 ("events stay in the timeline as evidence") and the golden table; it needs a deliberate, strength-preserving rewrite in Plan 2.

**Primary recommendation:** Build the verdict as pure data in `Copy` + one `Components` function, render it only where the data is real (Full detail: class + cause from timeline events; Quick view and list rows: class mark + word + one sentence with no cause claim), extract the real mark geometry from the pinned book into `brandbook/v2/status-marks.json`, return `true`/`nil` (never `false`) for the projection flags in `outcome_groups`, and rewrite copy_contract Part B to bind the *row-level class badge* instead of every atom.

## Project Constraints (from CLAUDE.md)

- Zero human UAT (D-52): Claude runs all evidence; judgment prohibitions become mutation-proven contract tests (template `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`). Owner hand-off only for ship/no-ship, brand/visual identity, secrets, `hex-publish`, physical devices.
- Research-first, decide, escalate rarely. No punting to the user.
- Conventional Commits (squash-merge; PR title checked); never hand-edit `.planning/release-target.json`; never edit `.planning/STATE.md` by hand.
- Things Not To Do that touch this phase: no PII in telemetry metadata (the verdict must not add telemetry); no pattern-matching errors by message string; do not write `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI `git diff --exit-code`); no marketing features; do not use `Application.compile_env*` outside `Mailglass.Config`.
- Brand voice: specific and composed, never "Oops!"; prefer the direct word.
- Domain language: Message/Delivery/Event; `dispatch` is not `delivered`.
- Toolchain (memory): export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; verified working this session.
- Project skills dirs: `.claude/skills` and `.agents/skills` do not exist. [VERIFIED: ls]

## CONTEXT corrections (verified against the live tree)

Verified-correct (no action): D-05 refs `deliveries.ex:119-134` (`delivery_projection`), `:70-83` (`outcome_groups`), `:137-150` (search); `projector.ex:48` (`@terminal_event_types ~w[delivered bounced complained rejected failed suppressed]a`) and `:126-134` (`maybe_flip_terminal`); `status_map.ex:43-48` (limitation comment), `:151-155` (`durable_failure?`); `copy.ex:89-93` (`:account ... wired: true`); `operator_live.ex:134,729,780,838,859,997-1026,2738-2773,2835`; `components.ex:1433-1442` (`outcome_help`), `:656-673` (`module_identity`); `assets.ex:105-135` (localizer); `operator.spec.js:713-728`; `capture-before-catalog.cjs:474` (`const catalogId = \`before-${source.git_sha.slice(0, 7)}-${utcStamp(now)}\``); `brand.json:256,263,649,720,725` (the "will retry" / "will not be retried" / "Next try at 2:12 PM UTC" lines); PR #325 open as `chore: release main` carrying only `feat(admin)` #317; ledger `status` is `inactive`; `config/test_exceptions.exs` and `scripts/check_test_exceptions.sh:19` scan only `test/mailglass` and `mailglass_inbound/test`; `superseded.json` exists and names the current bundle sha256 `8c57857f...b89b` and layout blob `c89fca34...7b519`.

| # | CONTEXT says | Live tree | Resolution |
|---|---|---|---|
| C-1 | D-10: the five book silhouettes are "check, triangle, cross, slash-circle, outbound arrow" | **Wrong.** `brandbook/v2/brand.json:900` verbatim: "Sent is a frame half full. Delivered is filled with a check. Delayed is a frame with a clock hand. Failed is filled with a crack. Not sent is a frame struck through." Marks are portrait panes (`viewBox="0 0 100 120"`), 20 px tall in rows, 44 px in detail, never under 14 px. Exact paths extracted from the pinned book (Code Examples). | Use the extracted geometry. Brand colour roles map to existing tokens (see C-1 mapping below). |
| C-2 | D-10: marks "exist only as inline `<svg class="stm">` fragments in `mailglass-brand-book.html`" | **Confirmed**, and the file is *not in the repo*: `brandbook/brand.pin.json` ships only brand.json, the OFLs, lockups, favicon and fonts. The book HTML is a member of the pinned zip (sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`, matches the pin; member `mailglass-brand/mailglass-brand-book.html` sha256 `1699d693c4ebd9d2548b58ce702468e37e7c8345687f956f8c5bcb3459104db8`). It has 51 `svg.stm` occurrences, 23 distinct strings = 5 canonical shapes x 5 sizes (13x16, 27x32, 12x14, 17x20, 37x44). | The extractor script must download the pinned zip (`scripts/brand_pin.exs` already supports a local zip, line ~118) and slice that member. Local cached zips exist only in other sessions' scratchpads; do not depend on them. |
| C-3 | D-01/D-19: verdict "fed by timeline events for the cause", cause matrix "through Quick view, full detail, timeline..." | `quick_view.ex:8-13` moduledoc: Quick view "Renders entirely from the list-row projection already loaded in `@deliveries`, so flipping records ... fires no new queries." It has **no events, so no `reject_reason`**. Rendering "No reason was recorded for this email." there would be *false* whenever the timeline holds a reason. | Quick view one-line form = mark + class word + one sentence **without** any cause or fallback, plus the existing "Open full detail" link. Cause and fallback render only on Full detail (timeline loaded). D-19 matrix: for Quick view assert *neither* a cause word nor the fallback appears. |
| C-4 | D-05: add `bounced_at`, `complained_at`, `suppressed_at` to `outcome_groups` "boolean forms" | `status_map.ex:157`: `defp present?(row, key), do: Map.get(row, key) != nil`. **Proved by running:** `delivery_class(%{status: :sent, last_event_type: :sent, bounced_at: false})` returns `:failed`; `suppressed_at: false` returns `:not_sent`; `delivered_at: false` returns `:delivered`. A `terminal: true` row with `complained_at` set returns `:sent`. | In `outcome_groups` select values that are `true` or `nil`, never `false` (for example `fragment("CASE WHEN ? IS NOT NULL THEN true END", d.bounced_at)`), or give them distinct boolean keys and teach `delivery_class` those keys. Add the `false` case to the mutation set. `delivery_projection/1` (row path) selects real timestamps, which is fine. |
| C-5 | D-18: hand-written `class="badge` allowed only in `components.ex`, `copy.ex` and the named allow-list (`results_status.ex`, `support_cards.ex`, `preview_live.ex:1184`) | That allow-list is the **time-formatting** list. Hand-written `badge` outside components/copy: `operator/suppression_card.ex:36`, `inbound/timeline.ex:84`, `inbound/routing_trace.ex:58` (non-status chips: "Current Mailglass match", provider/source label). "every `.badge` has exactly one aria-hidden mark and a status word" would fail on those. | Mark genuine status badges with `data-mg-status`; render-scan `[data-mg-status]`; source-scan allow-lists those 3 chips by file. |
| C-6 | D-15: full-width labelled `type=search`, "Email address" | The search is inside `#operator-filter-panel` (`class="hidden md:block"`, `operator_live.ex:944`; toggle button at `:929-933`), invisible below `md` until "Filters" is toggled. `FiltersForm` is guarded by **FORM-DRIFT-GATE** (`mailglass_admin/scripts/check-conformance.sh`, block "FILTER_WRAPPERS"; required lane `conformance_gates`): the wrapper must call `Components.filter_field`/`filter_section` and contain no `<label|input|select|textarea`. `Components.filter_field` has no `:search` type (`components.ex:890`: `values: [:text, :number, :select, :textarea, :checkbox]`). | Add `:search` to `filter_field` (render `type="search"`), split `FiltersForm` into `search_field/1` + `other_fields/1`, both thin wrappers, and lift the search above the collapsible panel inside the same `<form id="operator-filters">`. Keep id `filters_search` and form id `operator-filters` (pinned: 18 e2e uses in `phase176-filters.spec.js`/`phase178-real-zoom.spec.js`, `operator_live_test.exs:3518,4235`). `components_test.exs:1524,1567-1573` pin label "Search" and field order; update with the change. The same search also matches subjects; keep help text honest ("Also matches subjects"). |
| C-7 | D-14: "Deliveries" in "about 10 admin test files, 8 admin e2e files and 4 demo e2e files"; "Needs attention" pinned in 4+4 | Actual on-screen "Deliveries" pins: **15** admin test files (24 hits in `phase177_prohibition_contract_test.exs`, 15 `components_test.exs`, 12 `operator/shell_test.exs`, 11 `phase176_prohibition...`, 9 `operator_live_test.exs`, 8+8 `phase177_return_navigation`/`phase177_account_scope`, 4 `voice_test.exs`, 2 `quick_view_projection_test.exs`, 2 `preview_live_test.exs`, 1 each in `preview/return_context_test`, `operator_account_authorization_test`, `operator/results_status_test`; `brand_v2_compat_policy_test` and `before_catalog_manifest_test` only *mention* the word and need no edit), **11** admin e2e files (14 hits `operator.spec.js`), **5** demo e2e files + `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs`. "Needs attention" is **not renamed** (D-07 keeps it; `components.ex:1133`, `operator_live.ex:1013,2768`, `health_overview.ex:23` stay), so its 4+4 pins need no edit unless summary markup changes. "Dispatched"/"Deferred" pins (`components_test.exs:59,87`, `copy_contract_test.exs`) only need edits if atom labels in `Copy.statuses/0` change; D-01 keeps events as evidence, so they should not. | Use the per-plan inventory below. |
| C-8 | D-14: "`copy_contract_test.exs:627-693` carries 23 per-file literal baselines" | The **23** is `@status_phrases` (layer 3b closed phrase set; asserted by "the recorded set is the 23 planned entries"). The per-file baselines are `@literal_baseline` (8 files) and `@capitalize_baseline` (12 files). Three binding hazards: (a) `wired_class_violations/1` (Part B): for every `wired: true` class label, **every atom** with `StatusMap.classify(atom) == class` must render the plain class word on `status_badge` and none of `["Accepted", "Deferred", "Suppressed"]`. Flipping `class_labels` to wired makes `:bounced`/`:rejected`/`:deferred`/`:dispatched`/`:suppressed` badges read Failed/Delayed/Sent/Not sent, contradicting layer 1's golden table and D-01. (b) "entries that are not wired yet are present as data" asserts `Enum.all?(Copy.class_labels(), &(&1.wired == false))`. (c) Layer 3b collects any status-word phrase (`Sent`, `Delivered`, `Failed`, `Delayed`, `Not sent`, ...) in any `lib` string outside `copy.ex` and `gallery_live.ex`. | (a)/(b): in Plan 2 rewrite Part B to bind the **row-level class badge** (render the new class badge for an exemplar row per class and assert word == class label, no retired word) while atom-level badges keep event words; update the "all false" assertion to "wired iff the row badge reads it". Keep detector teeth. (c): all verdict sentences live in `copy.ex` (already D-01), so layer 3b stays closed; changing the summary help text (`operator_live.ex:2768`) or the four overview-tile phrases requires editing the matching `@status_phrases` entry and the count assertion. Any new `String.capitalize` in `lib` changes `@capitalize_baseline`. |
| C-9 | D-13: plain name "Password reset" from `AccountMailer.password_reset` | Production persistence writes `mailable: inspect(rendered.mailable)` (`lib/mailglass/outbound/persistence.ex:15,222,236`): the **module only**. `Message.mailable_function` exists (`message.ex`) but is not persisted. Only seeded data (`demo_data.ex:77,97,...`) has `Module.function`. `ScenarioLabel.humanize/1` is `when is_atom(atom)` only (`preview/scenario_label.ex`). In real adopter data the plain name will be the humanized module leaf ("Account mailer"), not "Password reset". | Implement both shapes; test both; never `String.to_atom`. Do not promise "Password reset" outside seeded data. Not fixable without new capture (stop line). |
| C-10 | D-16: check whether `nil-reason-bounce`, `typo-bounce`, `sent-no-report` exist | **All exist.** `catalog_seed.ex` seeds `typo-bounce`, `send-failed`, `sent-no-report`, `unicode-recipient`; it looks up `nil-reason-bounce` (`pm-demo-payment-failed-001`), `deferred-no-retry` (`sg-demo-badge-deferred-001`), `delivered-no-open`, `long-recipient`, `complained`, `manual-suppressed` (scenario `incident_update`) from `DemoData` (`catalog_seed.ex` `@demo_cases`, ~lines 41-48). **Missing:** a password-reset scenario and a bounce-then-open row. `before_catalog_manifest_test.exs` reads `catalog_seed.ex` text (no retry phrase, no `"reason"`/`"cause"` key) and requires `cases.json` to list exactly ten slugs (`@case_slugs`, `cases_semantic_failures`). | Do not edit `catalog_seed.ex`. Add a new module (suggest `MailglassDemo.JourneySeed`, `reference/demo_app/lib/mailglass_demo/journey_seed.ex`) invoked by the after-catalog driver after `CatalogSeed.seed!/0`. Note `DemoData.reset!/0` (what the advisory e2e lane's `POST /demo/evidence/reset` runs, `demo_data.ex:34-56`) never calls it, so see C-18. |
| C-11 | D-17/D-21: `after_catalog_manifest_test.exs` "reuses the validators of `before_catalog_manifest_test.exs`" | Every validator is `defp` inside that 1,600-line test module (`validate_catalog/2` at line 492, `shape_failures`, `binding_failures`, `cases_failures`, ...). Not callable. | Either extract the shape/file/budget/binding validators into `mailglass_admin/test/support/catalog_validators.ex` (compiled via `elixirc_paths(:test)`, `mix.exs:87`) and have both tests call it (touches the Phase 180 test, keep its teeth green), or write a thinner after-catalog validator. Recommended: extract only the pure helpers (`sha256`, `git_blob_sha`, `png_header_failures`, `binding_state`, `exact_keys`), leave the before test's rules untouched. |
| C-12 | D-11: "Admin" replaces "Operator" at `operator_live.ex:134` and gallery `:728` | Also on-screen: `inbound_live.ex:389,416,486,1220` and `inbound/destructive_action.ex:18` ("...not authorized for the current operator."), `operator/shell.ex:511`, `inbound/records_list.ex:135,474` ("Select an Account to see scoped operator data."). Pinned by `operator_live_test.exs:2567`, `voice_test.exs:305`, `inbound_live_test.exs:107,151,1655,1677,2252`, `e2e/phase170-journey.spec.js:202`, `test/support/endpoint_case.ex:445` (adopter-supplied message in the test auth). `e2e/structural.spec.js:2887,2893` assert `getByText("Operator", {exact:true})` count 0 in the Preview topbar: vacuous after the rename. "Tenant" is already gone from on-screen text (grep clean). | Include these 8 sites in Plan 4; update the pins in the same plan; replace the two negative e2e assertions with a check that "Admin" is the shell word. |
| C-13 | D-09 offenders | Verified: `timeline.ex:170` (`Provider occurrence time: {Map.get(event, :provider_occurred_at)}`) and `:222` (`provider_time(...)`, defined ~`:300-302`), `support_cards.ex:385,388` (`DateTime.to_iso8601(at) <> " UTC"` yields `...Z UTC`), `results_status.ex:38` (`Calendar.strftime(loaded_at, "%H:%M")` + `" UTC"`), `preview_live.ex:1184` (`"%a, %d %b %Y %H:%M:%S +0000"` RFC 2822 Date header). `components.ex:1552` (non-copyable `<time>`) also carries `title` and `aria-label` ("Recorded at ..."); `components.ex:1576` `copy_value` carries `title="Click to copy"`. These are the only `strftime`/`to_iso8601` hits outside `components.ex`. | Per D-09. Keep the tooltip text `"... UTC • Click to copy"` (pinned `components_test.exs:636`). |
| C-14 | D-08: server text "H:MM AM/PM UTC"-style | Today the server text is `"%Y-%m-%d %H:%M:%S"` plus microsecond digits plus `" UTC"` (`components.ex:1606-1617`), e.g. `2026-06-14 14:32:05.000000 UTC`, pinned in ~14 test places (`components_test.exs` 8, `operator/health_overview_test.exs` 4, `inbound/evidence_card_test.exs` 1, `operator_live_test.exs` 1, e2e `phase168-plan03-acceptance.spec.js` 3). **Verified by running:** `Calendar.strftime(at, "%b %-d, %Y, %-I:%M %p") <> " UTC"` gives `Nov 15, 2026, 2:05 PM UTC`, identical to `toLocaleString("en-US", {year:"numeric",month:"short",day:"numeric",hour:"numeric",minute:"2-digit",timeZoneName:"short",timeZone:"UTC"})`. For other zones Node prints `EST` (America/New_York) and `GMT+13` (Pacific/Auckland), so the zone-token regex needs `GMT[+-]\d`. `root.html.heex:13-23`: while JS is present, a not-yet-localized `<time>` is `color: transparent` (placeholder bar), so SSR text is the no-JS fallback. | Visible SSR text = compact form + ` UTC`; keep `data-utc`, the tooltip, and the copy value at full precision. Add `timeZoneName: "short"` and fixed `"en-US"` to `FMT`; stop overwriting `aria-label`. Only `operator.spec.js:723-728` computes the expected local string from the same options and must be updated. |
| C-15 | D-15: "raw events in a native `<details>`, collapsed" | There is no raw-events element today. Detail stack (`operator_live.ex:862-925`): `DetailHeader`, `Timeline`, `SuppressionCard`, `ReplayAction`, `<details>` "Account diagnostics". `DetailHeader` holds `Components.technical_details collapsible={false}` (ids, provider message id). | Interpret as: Technical details becomes the collapsed `<details>`; the timeline stays expanded as evidence. Do not add any new raw-payload rendering (new surface, PII risk). |
| C-16 | D-07: summary count | No admin test pins `delivery_summary` / `operator-delivery-summary` / `delivery-summary-*` (grep across `mailglass_admin/test`, `e2e`, demo e2e: none; only core tests touch `outcome_groups`). The re-bucket has **zero existing coverage**. | Plan 1 must add tests: all five classes into Needs attention / Delivered / Awaiting, queued reads Awaiting, complained/unsubscribed leave Needs attention, and the bounce-then-open row counts under Needs attention. |
| C-17 | D-22 "feat(core): isolated commit" | Repo squash-merges (CLAUDE.md), so on `main` the PR is one commit; the "isolated commit" is review isolation only. `release-please` attributes by path (`release-please-config.json`: core `exclude-paths` omits `lib`), so the scope token is cosmetic. | Keep two commits inside the PR for review; PR title `feat(core): ...` if the PR contains the core change. |
| C-18 | D-20: advisory spec at `reference/demo_app/assets/e2e/phase182-journey.spec.js` "on the demo fixtures" | `./e2e` is the advisory lane's `testDir`, whose reset (`DemoData.reset!`) never seeds password-reset rows. `playwright.catalog.config.cjs` comment explains why seeded capture specs live in `./catalog`. | Put the journey spec in `reference/demo_app/assets/catalog/` (run by the capture driver, which seeds first), or have the `./e2e` spec use only existing DemoData rows (nil-reason bounce `payment_failed`, deferred, complained, suppressed). Recommended: `catalog/` placement; it also yields the BRADM-07 screenshots. |

**Colour mapping for marks (C-1), verified:** `contrast_contract_test.exs:76-92` binds the book's status pairs as `"status-sent" => {"text", "surface"}`, `"status-delivered" => {"success-text", "surface"}`, `"status-delayed" => {"warning-text", "surface"}`, `"status-failed" => {"error-text", "surface"}`, `"status-notsent" => {"text-muted", "surface"}`. The book's `--mk-ink/ok/warn/bad/mute/surf` equal those roles' values. Every one of `--mg-color-success-text`, `warning-text`, `error-text`, `text-muted`, `surface` exists in the committed `app.css` (light surface `#fff`, dark `#2a211b`). Marks therefore need **no new CSS class**: use `fill="var(--mg-color-...)"` attributes and `width`/`height` attributes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Delivery class and verdict data | Admin (pure `Copy` + `StatusMap`) | Core read model (projection fields) | Words are admin-owned; core only exposes columns that already exist (D-05). |
| Cause (`reject_reason`) | Core `Operator.Timeline` (already delivers it) | Admin Full detail | Only Full detail has events (C-3). |
| Search by email | Core `Deliveries.maybe_filter_search` (exists) | Admin LiveView + `FiltersForm` | No new query parameter (D-07 defers a filter). |
| Time zone display | Browser localizer (`assets.ex`) over server-rendered `<time>` | Server `Components.timestamp` | SSR is the no-JS fallback; JS keeps the zone (D-08). |
| Status mark | Admin `Components` (inline SVG, token-coloured) | `brandbook/v2/status-marks.json` (provenance) | Geometry pinned to the book bytes; test compares component to JSON. |
| Screen registry | Test (`Phoenix.Router.routes/1` over `MailglassAdmin.TestAdopter.Router`) | `__live__/0` reverse check | Cannot drift from the router. |
| After-catalog / review | Demo capture driver + Playwright (advisory) | Required-lane ExUnit manifest test | Evidence is advisory, its integrity is required (180 D-04/D-13). |

## Standard Stack

No package is added, removed or upgraded in this phase.

### Core (all existing) [VERIFIED: `mailglass_admin/mix.lock`, `node -e` in demo assets]
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| phoenix_live_view | 1.2.13 | Screens and `Phoenix.LiveViewTest` | Existing stack |
| phoenix | 1.8.16 | `Phoenix.Router.routes/1` for the registry | Existing |
| floki | 0.38.5 | Render scans (script-stripped visible text) | Used by `copy_contract_test`, `voice_test` |
| ecto_sql | 3.14.0 | Projection query | Existing |
| @playwright/test | 1.60.0 installed (`^1.59.1` declared) | Advisory capture/journey | Existing; Chromium 1200-1223 cached in `~/Library/Caches/ms-playwright` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline SVG with token attributes | `hero-*` icons / new icon sheet | Heroicons cannot draw the book's panes, and a new `hero-*` needs a vendored plugin entry (`ICON-EXISTS-GATE`). Inline SVG adds no CSS class and no bundle rebuild. |
| Thin new after-catalog validator | Extracted shared validators | Extraction touches a 1,600-line Phase 180 test; a thin validator duplicates ~150 lines. Recommended: extract the pure helpers only. |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed or recommended in this phase. **Packages removed due to [SLOP] verdict:** none. **Packages flagged as suspicious [SUS]:** none. (The `package-legitimacy` seam was not run: there are no names to check.)

## Architecture Patterns

### System Architecture Diagram

```
 delivery row (Postgres)
   status, last_event_type, delivered_at, bounced_at, terminal,
   complained_at, suppressed_at, provider, mailable, recipient
        |  Mailglass.Operator.Deliveries.delivery_projection/1  (D-05: +5 fields)
        |  list_recent_deliveries_page/2 -> entries + outcome_groups (true|nil flags, C-4)
        v
 OperatorLive (list)                      OperatorLive (detail, ?delivery_id=..&full=1)
   |  search form -> ?search= patch          |  get_delivery/2 + Timeline events + suppression_state
   |  delivery_summary: StatusMap            |            |
   |   .delivery_class per group             v            v
   |   -> Needs attention / Delivered /   Verdict (pure data in Copy)
   |      Awaiting                          class  = StatusMap.delivery_class(row)
   v                                         cause  = last failure-class event's reject_reason
 row: class badge (mark + word)              guard  = Map.has_key?(row, :bounced_at) else
 Quick view: mark + word + 1 sentence               "Status cannot be fully determined ..."
   (NO cause, NO fallback: no events)               |
                                                    v
                                      Components.verdict  (mark, word, sentence, rule, next step)
                                        mark  <- brandbook/v2/status-marks.json (test-equal)
                                        times <- Components.timestamp (zone always)
                                      then evidence: Timeline, SuppressionCard; Technical details <details>
 Browser: localizer FMT (+timeZoneName, en-US) re-renders <time> keeping the zone
```

### Recommended Project Structure
```
mailglass_admin/lib/mailglass_admin/
├── copy.ex                      # + verdict/1, cause_sentence/1 (no nil clause), cause_or_fallback/1,
│                                #   orphan_count_label/1, class labels
├── components.ex                # + status_mark/1, delivery_badge/1, verdict/1; filter_field :search; timestamp format
├── operator/mailer_name.ex      # NEW pure, total, no atom creation (plain name; both mailable shapes)
├── operator/quick_view.ex       # one-line verdict
├── operator/filters_form.ex     # split: search_field/1 + other_fields/1 (thin wrappers)
brandbook/v2/status-marks.json   # NEW pinned geometry + provenance
scripts/brand_status_marks.exs   # NEW extractor/verifier (downloads pinned zip, slices the book HTML)
mailglass_admin/test/mailglass_admin/
├── phase182_time_status_contract_test.exs
├── phase182_cause_contract_test.exs
├── phase182_journey_test.exs
├── phase182_words_contract_test.exs   # recommended 5th file (BRADM-03/04/05 teeth, see Validation)
└── after_catalog_manifest_test.exs
mailglass_admin/test/support/catalog_validators.ex   # extracted pure helpers (C-11)
reference/demo_app/lib/mailglass_demo/journey_seed.ex        # NEW (C-10)
reference/demo_app/assets/catalog/phase182-journey.spec.js   # NEW (C-18)
test/mailglass/operator/deliveries_projection_test.exs       # NEW core file (no @tag :skip / Process.sleep)
```

### Pattern 1: Verdict as pure data, rendered once
**What:** `Copy.verdict(class, facts)` returns `%{word, sentence, rule, next_step}` from templates keyed by the five classes; `Components.verdict/1` renders it; Quick view calls the one-line variant (no cause). Gate on `Map.has_key?(row, :bounced_at)` (D-06).
**When:** Quick view, Full detail, list row badge all go through the same class computation so they cannot drift.
**Honest-copy rules found in the tree (apply to every string):** `phase175_prohibition_contract_test.exs` bans, on the replay/suppression surfaces it scans, `~r/send (it )?again/i`, `~r/retry delivery/i`, `~r/(?<!not )\b(resent|sent|delivered)\b/i` (replay outcome corpus only) and `~r/permanent/i`; `voice_test.exs` bans "oops", "whoops", "uh oh", "something went wrong". The D-02 Failed next step contains "send again": keep that sentence **out of `SuppressionCard`, `ReplayAction`, `ReplayModal`, `RepairState`** (the scanned modules) or reword to "trigger the email from your app again" (already the Not-sent wording).

### Pattern 2: Real mark component, token-coloured, no CSS class
```heex
<%# Source geometry: brandbook/v2/status-marks.json (this value set is asserted equal by a test) %>
<svg width="17" height="20" viewBox="0 0 100 120" aria-hidden="true" focusable="false">
  <rect width="100" height="120" fill="var(--mg-color-success-text)"/>
  <path d="M24 62L43 82L77 38" fill="none" stroke="var(--mg-color-surface)" stroke-width="13"/>
</svg>
```
Wrap in the existing `badge badge-outline` (present in the bundle; `badge-ghost` is **not**) with `data-mg-status={class}`; word colour via `style="color: var(--mg-color-success-text)"` so the word keeps the book 4.5:1 pair (a solid `badge-success` pill would put white on green instead of the book pair). New spacing/utility classes may still change the bundle: run `mix mailglass_admin.assets.build --check` after every UI edit (D-23).

### Pattern 3: Source-enumerated matrices (BRADM-06)
Accessors, all read this session: `Mailglass.Events.Event.__reject_reasons__/0` (`event.ex:137`, 7 values: `[:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]`, `event.ex:73`), `Mailglass.Suppression.Entry.__reasons__/0` (`entry.ex:138`, `[:hard_bounce, :complaint, :unsubscribe, :manual, :policy, :invalid_recipient]`), `Mailglass.Outbound.Delivery.__event_types__/0` (`delivery.ex:176`), status values `[:queued, :sent, :dispatched, :failed, :suppressed]` (`delivery.ex:56`; no accessor: use `Ecto.Enum.values(Delivery, :status)`). The existing `status_map_test.exs` asserts `length(grid()) == 5 * 21 * 2` (210 cells).

### Pattern 4: Screen registry (D-18), verified by running
In `MIX_ENV=test mix run --no-start`, `Phoenix.Router.routes(MailglassAdmin.TestAdopter.Router)` returned 40 routes, of which exactly these 10 are LiveView routes (via `route.metadata.phoenix_live_view = {mod, action, opts, extra}`): `/dev/mail` (`PreviewLive :index`), `/dev/mail/:mailable/:scenario` (`PreviewLive :show`), `/dev/mail/gallery` (`GalleryLive :index`), the same three under `/alt/dev/console`, `/ops/mail` (`OperatorLive :index`), `/ops/mail/inbound` (`InboundLive :index`), `/secure/console` and `/secure/console/inbound`. So 5 distinct `{module, action}` pairs. Modules exporting `__live__/0`: `GalleryLive, InboundLive, OperatorLive, PreviewLive` (4). Modules exporting `__components__/0`: 31, including `GalleryLive`. **Pitfall:** call `Code.ensure_loaded?(m)` before `function_exported?(m, :__live__, 0)`; app modules are not all loaded at test start. `OperatorLive` is one route serving overview, list, Quick view and detail through query params (`view`, `delivery_id`, `full`), so the registry must enumerate *states per route*, not routes.

### Anti-Patterns to Avoid
- Computing the verdict in HEEx per screen (D-01).
- A `false` flag named like a timestamp in any map passed to `delivery_class/1` (C-4).
- Rendering the fallback sentence anywhere events are not loaded (C-3).
- Editing `catalog_seed.ex` or the before-catalog directory (immutable evidence; D-23).
- `String.to_atom/1` on `Delivery.mailable` (atom exhaustion; value is DB data).
- `String.capitalize` in a new `lib` file without updating `@capitalize_baseline` (use `ScenarioLabel`'s logic via an added binary clause instead).
- `title=` attributes for status/time meaning (D-09/D-10); `aria-label` that omits its visible text (WCAG 2.5.3).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contrast ratios | New WCAG math | `mailglass_admin/test/support/contrast.ex` (`ratio/2`, `resolve_tokens/1`) + `contrast_contract_test.exs` `@book_binding` | Already binds the five status pairs; add the 3:1 mark-vs-surface check beside them |
| Font-subset check for new copy | Manual char review | `GlyphScan` (`test/support/glyph_scan.ex`) via `glyph_contract_test.exs` | Scans every `lib` string; subset is 170 code points: Basic Latin, NBSP, degree, Latin-1 letters, U+2013, U+2014, U+2018, U+2019, U+201C, U+201D, U+2022, U+2026, U+2212 (`glyph_contract_test.exs`, `@subset`) |
| Accessible tooltip | New popover | `Components.field_help` via `module_identity` (`components.ex:656-673`) | Hover/focus/tap, Esc, `role=tooltip`, 44 px target already built and tested |
| HTML assertions | Regex over HTML | `Floki.parse_fragment!` + `Floki.filter_out("script")` (pattern in `copy_contract_test.exs` `visible_text/1`) | Scripts carry words like "noops" and zone tokens |
| Manifest/PNG/binding checks | Re-implement | Extract from `before_catalog_manifest_test.exs` (C-11) | 1,600 lines of proven teeth |
| Date formatting | New formatter libs | `Calendar.strftime/2` (SSR) and `toLocaleString("en-US", {...timeZoneName:"short"})` (browser) | Verified identical for UTC viewers (C-14) |
| Route enumeration | A hand list | `Phoenix.Router.routes/1` (Pattern 4) | Cannot drift |

**Key insight:** every hard part here already has a pinned, mutation-tested owner (`Copy`, `StatusMap`, `GlyphScan`, `Contrast`, the manifest validators). The risk is *breaking a pin while adding a word*, not missing a tool.

## Blast Radius by Plan (D-22 ordering)

Counts are line hits from grep this session; "pins" = tests/e2e that must change in the same plan (D-14).

**Plan 1 — core projection + admin re-bucket/fallback**
- Core: `lib/mailglass/operator/deliveries.ex` (projection `:119-134`, `outcome_groups` `:70-83`); new `test/mailglass/operator/deliveries_projection_test.exs` (scanned by `check_test_exceptions.sh`: no `@tag :skip|:flaky`, `Process.sleep(`, `pg_sleep(`); existing `deliveries_test.exs` needs no edit (asserts counts and `last_event_type` set only, lines 40-42, 63).
- Docs: `docs/api_stability.md` (read-model bullets at ~82-85 and ~126-141) and `mailglass_admin/docs/api_stability.md` (~36-39, ~148-161). Tests reading these: `test/mailglass/docs_contract_test.exs:1068-1100` (pins the Mailable import/defoverridable lists only), `stability_contract_test.exs`, `auth_actions_contract_test.exs`, `brand_v2_compat_policy_test.exs`: adding one sentence is safe; add no heading/table row.
- Admin: `status_map.ex:43-48` comment deletion; `status_map_test.exs` "operator row limitation" test (~L326-335) replaced; `operator_live.ex` `delivery_summary` (`:2738-2773`) incl. help strings `:2764-2772`; copy_contract `@status_phrases` entry for the help phrase "Failed, bounced, rejected, deferred, suppressed, complained, or unsubscribed deliveries. ..." (it is one of the 23) must change with the string.

**Plan 2 — the one job**
- `copy.ex`, `components.ex` (mark, class badge, verdict, `filter_field :search`, `outcome_help` conditional `:1433-1442`, timestamp), `operator/{quick_view,detail_header,suppression_card,timeline,filters_form}.ex`, `operator_live.ex` (search placement, detail order `:862-925`), `controllers/assets.ex` FMT (`:105-135`), `gallery_live.ex:683,728` ("retry window").
- Pins: `copy_contract_test.exs` (Part B rewrite, "all false" assertion, possibly `@literal_baseline`), `components_test.exs:1524,1567-1573` (field order/label), `phase176_prohibition_contract_test.exs` P11/P12 (toolbar and filter panel structure), `operator_live_test.exs:3518,4235` and 18 e2e `#filters_search` uses (ids unchanged, so only layout assertions move), `e2e/operator.spec.js:713-728` (FMT).
- New: verdict/cause/journey tests, `JourneySeed`, `OperatorFixtures` rows (`test/support/operator_fixtures.ex`: helpers `insert_delivery!/1`, `insert_event!/2`, `insert_suppression!/1`; fixtures use module-only `mailable: "Mailglass.Example.BrowserMailer"`, which matches production).

**Plan 3 — time and status everywhere**
- D-09 offenders (C-13), `components.ex:1512-1513` docstring, `utc_string` SSR format (C-14), `title` removal `:1552,:1576`.
- Pins: ~14 on the long timestamp form (list in C-14), `components_test.exs:632,636-642`, `health_overview_test.exs:350,359`.
- Registry + `phase182_time_status_contract_test.exs`.

**Plan 4 — words (D-11..D-14)**
- On-screen "Deliveries" in lib: `operator_live.ex:729` (title), `:780` ("Go to Deliveries"), `:838` ("Back to deliveries"), `:1603,1607,1614` (error copy), `deliveries_list.ex:28` (`attr :heading, default: "Deliveries"`), `:76-134` (empty/error titles and bodies), `:354` (`aria-label="Deliveries pagination"`), `:424` ("0 deliveries"), `results_status.ex:20,33,42` (nouns), `quick_view.ex:238,242,248`, `health_overview.ex:163,179`, `filters_form.ex:27,41` (help), `shell.ex:582` (`heading: "Deliveries"`), `surface_nav.ex:15` (`label: "Deliveries"`), `preview_live.ex:358`, `gallery_live.ex:666,668,1184`, `copy.ex` (`vocabulary` flags). Keep `deliveries_path`, `data-testid`s, `surface_nav` keys, module names.
- "Operator": `operator_live.ex:134`, `gallery_live.ex:728`, plus C-12's 8 sites.
- Orphan wording (D-12), actual sites: `operator_live.ex:2835` ("Unmatched events"), `:2951` ("Unmatched webhook evidence"), `:2959`, `:2976`; `support_cards.ex:202,257,329,335`; `health_overview.ex:269,278`. Pins: `operator_live_test.exs:933,4689`, `health_overview_test.exs:350,359`.
- Pins for "Deliveries": see C-7 (largest: `phase177_prohibition_contract_test.exs` 24, `components_test.exs` 15, `shell_test.exs` 12, `phase176_prohibition...` 11, `operator_live_test.exs` 9). `voice_test.exs` and `phase177_prohibition` P6 pin the exact Preview subtitle "It doesn't read Deliveries or Inbound messages from any Account." (`preview_live.ex:358`).
- Mailer plain name (`detail_header.ex:68-76` uses `module_identity` with `segments={2}`).

**Plan 5 — after-catalog and review:** driver `after-` id mode, new spec cases, `JourneySeed` call, review directory, `after_catalog_manifest_test.exs`. Run last, clean tree. Bundle or root-layout bytes must be final: `before_catalog_manifest_test.exs` marks every catalog SUPERSEDED/LIVE against the current `app.css` sha256 and root-layout blob (`binding_state/2`), and any bundle change after this phase's `superseded.json` update requires another `superseded_by` update in that same change.

## Common Pitfalls

### Pitfall 1: Part B of copy_contract (C-8a)
**What goes wrong:** flipping `Copy.class_labels` to `wired: true` turns the suite red (every atom badge must read the class word).
**How to avoid:** rewrite the rule to the row-level class badge in the same plan; keep `retired_leaks` (Part A) as is; keep the teeth block (`wired_class_violations` known-bad planted input).
**Warning signs:** failures naming `{:failed, :bounced, "Bounced"}` style tuples.

### Pitfall 2: `false` reads as present (C-4)
**How to avoid:** `true`/`nil` flags; add a unit test `delivery_class(%{... bounced_at: false})` is **not** the contract (it is `:failed` by design); instead test the *producer* (`outcome_groups`) never emits `false` for those keys.

### Pitfall 3: Quick view honesty (C-3)
Fallback only on Full detail. Contract: Quick view HTML contains none of the 7 cause words and not "No reason was recorded".

### Pitfall 4: `test_exceptions.exs` line keying
Scans `test/mailglass` and `mailglass_inbound/test` only (`check_test_exceptions.sh:19`). New core file must contain no `@tag :skip`, `@tag :flaky`, `Process.sleep(`, `pg_sleep(`. Admin edits are unaffected. Verified OK: `bash scripts/check_test_exceptions.sh` prints "OK: test exception registry is complete and unexpired."

### Pitfall 5: bundle and `superseded.json` (D-23)
Any new Tailwind class in `lib/` changes `priv/static/app.css`. Run `mix mailglass_admin.assets.build` (writes) then `--check`, commit the bundle, and update `before-9eb9dee-20261115T022124Z/superseded.json` `superseded_by.bundle_sha256` and `root_layout_git_blob_sha` **in the same change** (current values above). Avoid new classes where possible: inline `style` colours, SVG attributes, existing `badge-outline`, `text-label`, `min-h-11`. The memory note "token-parity bundle landmine" (a blind rebuild can break `TokenParityTest`) is superseded by Phase 180's reproducible `--check`; baseline today: "Admin bundle matches a fresh build (138509 bytes)".

### Pitfall 6: glyph subset (170 code points)
All `lib` strings (not `@doc`/`@moduledoc`) are scanned. Use `•` (U+2022), `’`, `—`, `…`, `−`; never `·`, arrows, `✓`, `≥`, `≈`. D-02's draft strings are ASCII-only. Do not add the glyphs to the fonts (BRTOK-03).

### Pitfall 7: Phase 175-178 prohibition pins on new copy
See Pattern 1 ("send again", "permanent", "sent/delivered" on replay surfaces). Phase 176 P11/P12 pin the Deliveries toolbar and filter panel (`hidden md:block` must not become an inline `display`); Phase 177 P6 pins the Preview subtitle exactly.

### Pitfall 8: persona drift guard
`persona_drift_guard_test.exs` compares `MailglassDemo.Personas.spec/0` (three personas: `fjordline-aps`, `helios-void`, `northstar`) with `OperatorFixtures.seed_persona_cohort!/0` and gallery literals. New password-reset rows must be a separate seed on an existing tenant (`northstar`) and must not add a persona or edit `personas.ex`/`DemoData`.

### Pitfall 9: axe baseline
`docs/axe-baseline.json` has a 9-cell ratchet (`axe_baseline_test.exs`, surfaces `deliveries`, `inbound`, `preview` x light/dark/system). New markup (marks, verdict, search) can add `color-contrast`/`label` violations. Fix tokens/markup first; regenerate once, last, only if the phase changes it: `cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js` (advisory lane; `operator_browser_gate` is not in the required `ci_green` needs list, `ci.yml:1440-1475`).

### Pitfall 10: honest-copy edges (need a planner call, see Open Questions)
R1: a send-time failure has `last_error` (never rendered) but `reject_reason` nil, so "No reason was recorded for this email" is not literally true there. R2: `last_event_type: :complained` with no delivery classifies `:sent` (shown above), so the Sent rule line "the receiving server has not reported accepting it" overstates for a complaint row. R3: `Delivery.status :suppressed` is dormant and a suppressed send leaves no Delivery row (`status_map.ex:29-34`), so "Not sent" rows are rare outside seeded data; an operator searching a suppressed address finds nothing. Do not invent a suppression lookup (new feature).

## Code Examples

### Pane-mark geometry, extracted from the pinned book
Source: `mailglass-brand/mailglass-brand-book.html` inside the pinned zip (sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b`; member sha256 `1699d693c4ebd9d2548b58ce702468e37e7c8345687f956f8c5bcb3459104db8`), `svg.stm` fragments, quoted verbatim (canonical shapes; all other sizes differ only in `width`/`height`). [VERIFIED: unzip + regex scan this session]
```html
<!-- Sent -->      <rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-ink)" stroke-width="12"/><path d="M6 60H94V114H6Z" fill="var(--mk-ink)"/>
<!-- Delivered --> <rect width="100" height="120" fill="var(--mk-ok)"/><path d="M24 62L43 82L77 38" fill="none" stroke="var(--mk-surf)" stroke-width="13"/>
<!-- Delayed -->   <rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-warn)" stroke-width="12"/><path d="M50 24V62L72 78" fill="none" stroke="var(--mk-warn)" stroke-width="12"/>
<!-- Failed -->    <rect width="100" height="120" fill="var(--mk-bad)"/><path d="M60 0L40 48L62 68L44 120" fill="none" stroke="var(--mk-surf)" stroke-width="12"/>
<!-- Not sent -->  <rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-mute)" stroke-width="12"/><path d="M0 120L100 0" stroke="var(--mk-mute)" stroke-width="12"/>
```
Light values: ink `#2A1D17`, ok `#1D6B3C`, warn `#855300`, bad `#B3261E`, mute `#665850`, surf `#FFFFFF`. Dark: ink `#F3EEEA`, ok `#7FCB9A`, warn `#E3B25C`, bad `#F09A93`, mute `#B9ADA3`, surf `#2A211B`. Aspect 100:120, so 20 px tall = width 17, 44 px tall = width 37; never under 14 px tall.

### Suggested `brandbook/v2/status-marks.json` layout
```json
{
  "schema": "mailglass.status_marks.v1",
  "source": {
    "pin": "brandbook/brand.pin.json",
    "zip_sha256": "ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b",
    "zip_member": "mailglass-brand/mailglass-brand-book.html",
    "member_sha256": "1699d693c4ebd9d2548b58ce702468e37e7c8345687f956f8c5bcb3459104db8",
    "extracted_by": "scripts/brand_status_marks.exs"
  },
  "view_box": "0 0 100 120",
  "heights_px": { "row": 20, "detail": 44, "minimum": 14 },
  "roles": { "ink": "text", "ok": "success-text", "warn": "warning-text", "bad": "error-text", "mute": "text-muted", "surf": "surface" },
  "marks": {
    "sent": { "word": "Sent", "shapes": [ {"tag":"rect","x":6,"y":6,"width":88,"height":108,"fill":"none","stroke":"ink","stroke_width":12}, {"tag":"path","d":"M6 60H94V114H6Z","fill":"ink"} ] }
  }
}
```
(other four marks follow the table above). Required-lane test: parse the JSON, render each mark through the component, and assert the `d`/`x`/`width` values and role-to-`--mg-color-*` mapping are equal; a second assertion binds `roles` to `contrast_contract_test.exs` `@book_binding`. The zip byte-check is advisory (online), like Phase 179 D-19. The extractor is the only code that needs the zip; the JSON is the committed truth.

### Projection flags that `delivery_class/1` reads correctly (C-4)
```elixir
# outcome_groups select (Ecto): true|nil, never false. delivery_confirmed already follows
# the existing pattern at lib/mailglass/operator/deliveries.ex:80
#   delivery_confirmed: not is_nil(delivery.delivered_at)
bounced_at:    fragment("CASE WHEN ? IS NOT NULL THEN true END", delivery.bounced_at),
terminal:      delivery.terminal,
complained_at: fragment("CASE WHEN ? IS NOT NULL THEN true END", delivery.complained_at),
suppressed_at: fragment("CASE WHEN ? IS NOT NULL THEN true END", delivery.suppressed_at)
```
(Grouping by the same expressions, as lines 72-76 already do for `not is_nil(delivery.delivered_at)`.) [ASSUMED: exact Ecto fragment form compiles in `group_by`; the existing `not is_nil(...)` group_by is the verified precedent. The planner should prove it with the DB-backed test in D-05.]

### Localizer and SSR format pair (verified)
```elixir
Calendar.strftime(at, "%b %-d, %Y, %-I:%M %p") <> " UTC"   # "Nov 15, 2026, 2:05 PM UTC"
```
```js
const FMT = { year: "numeric", month: "short", day: "numeric",
              hour: "numeric", minute: "2-digit", timeZoneName: "short" }
d.toLocaleString("en-US", FMT)   // UTC: "Nov 15, 2026, 2:05 PM UTC"; New_York: "... 9:05 AM EST"; Auckland: "Nov 16, 2026, 3:05 AM GMT+13"
```

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| Atom-level badge in rows (`delivery_display_status` returns `:opened` after a bounce) | Row class badge from `StatusMap.delivery_class/1` over the extended projection | A bounce followed by an open reads Failed, not Delivered |
| Bare local time after JS (`toLocaleString(undefined, ...)`) | Fixed `en-US` + `timeZoneName: "short"` | Zone survives localization |
| Heroicon per status | Book pane mark + word on delivery-class badges only | Events keep heroicons |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `CASE WHEN ... THEN true END` fragment is accepted inside `group_by`/`select` exactly as written | Code Examples | Plan 1 adjusts the fragment; the DB test catches it immediately |
| A2 | Real adopter data stores the module only in `Delivery.mailable` (read from `persistence.ex:15,222,236`; I did not run an adopter app) | C-9 | If some path writes `Module.function`, the happy-path plain name appears more often; the both-shapes implementation is correct either way |
| A3 | Splitting a CamelCase module leaf into "Account mailer" is an acceptable "never invent a name" derivation | C-9 | Owner may prefer showing the raw leaf; trivial to change |
| A4 | Placing the journey spec under `assets/catalog/` is acceptable instead of `assets/e2e/` (C-18) | C-18 | If the owner wants it in the advisory e2e lane, it must use existing DemoData rows only |
| A5 | Keeping `badge badge-outline` with inline `style` word colour passes axe `color-contrast` in both themes (contrast pairs are the book's, but a rendered axe run was not performed) | Pattern 2 | Pitfall 9 regeneration discipline applies |

## Open Questions

1. **R1 honest fallback for send-time failures**
   - Known: `status: :failed` rows carry `last_error` (adapter error) and nil `reject_reason`; `last_error` must never render; the fallback says "No reason was recorded for this email."
   - Unclear: whether that is true when an adapter error *was* recorded.
   - Recommendation: for the `status == :failed` send-time case use the existing, already-true `outcome_help` claim ("Sending failed before a successful handoff to the provider.", `components.ex` `outcome_help(:delivery, :failed)`) as the cause line, and reserve the fixed fallback for provider-reported bounces/rejections with nil `reject_reason`. This narrows, never widens, the claim.
2. **R2 complaint rows read Sent**
   - Recommendation: when `complained_at` is present add "A complaint was recorded for this email." and omit the "has not reported accepting it" half of the rule line; classes stay as 179 D-03 locks them.
3. **R3 suppressed address finds no row** — Recommendation: leave the empty state truthful ("No activity matches this email address in this time window"), add no suppression lookup (stop line).
4. **Where does the journey spec live (C-18)?** Recommendation: `assets/catalog/`.
5. **Mark colour on solid pills** — Recommendation: outline badge + token-coloured word (Pattern 2); confirm with the axe producer.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP via asdf | all tests | yes | Elixir 1.18.4 / OTP 27 with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` | none needed |
| PostgreSQL | DB-backed core/admin tests | yes | accepting connections at `/tmp:5432` | none |
| Node | Playwright, capture driver | yes | v26.10.0 | none |
| Playwright + Chromium | advisory journey, capture | yes | 1.60.0; chromium-1200..1223 cached | none |
| Docker daemon + `compose.demo.yml` | capture driver (restarts demo, seeds via `docker compose exec`) | yes | client 29.5.2, daemon answering `docker ps` | driver has an in-harness fallback seed branch |
| `gh` CLI | PR state | yes | authenticated as szTheory | none |
| fontTools (python3) | not needed (fonts are not re-subset) | yes (4.62.1) | n/a | n/a |
| Pinned brand zip | status-marks extractor | not durable locally | pin URL in `brandbook/brand.pin.json` | download via `scripts/brand_pin.exs` (supports local zip, `:118`) |

**Missing dependencies:** none blocking. (An unrelated Postgres container for another project is also running; do not touch it.)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18.4), `Phoenix.LiveViewTest`, Floki 0.38.5; Playwright 1.60.0 for advisory |
| Config file | `mailglass_admin/mix.exs` aliases (`verify.support_contract.admin`); `config/test_exceptions.exs` (core only) |
| Quick run command | `cd /Users/jon/projects/mailglass/mailglass_admin && export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && mix test test/mailglass_admin/<file>.exs --seed 0` |
| Full suite command | `mix verify.support_contract.admin` (bundle `--check` then the whole admin test dir with `--warnings-as-errors`); core: `cd /Users/jon/projects/mailglass && mix test` |

Measured baselines this session (all green): `mix format --check-formatted` 0.7 s; `mix mailglass_admin.assets.build --check` 0.8 s ("Admin bundle matches a fresh build (138509 bytes)"); scoped contract set (`copy_contract`, `status_map`, `glyph_contract`, `before_catalog_manifest`, `root_theme_ownership_contract`, `font_assets_contract`, `persona_drift_guard`) 180 tests, 0 failures, 1.5 s; `operator_live_test` + `components_test` + `quick_view_projection_test` 319 tests, 0 failures, 5.5 s; core `deliveries_test` + `timeline_test` 16 tests, 0 failures; `check_test_exceptions.sh` OK. All under 30 s, so per-task quick runs are viable.

### Phase Requirements -> Test Map
| Req | Required-lane test | Command | Mutation that must turn it red (recorded in plan summary) |
|-----|--------------------|---------|-----------------------------------------------------------|
| BRADM-01 | `phase182_journey_test.exs` (LiveViewTest: `render_change` on `#operator-filters` asserts `?search=` patch, summary counts the row under Needs attention, row mark+word, detail verdict + "Sent is not delivered" + next step + zone on every `<time>`; plus `get(conn, path)` with cookie `mailglass_admin_theme_v2` = light/dark/absent asserting exactly one `data-theme` on `<html>`) and the D-05 core contract (bounce->open, bounce->click, rejected->open, delivered->bounce) | `mix test test/mailglass_admin/phase182_journey_test.exs --seed 0`; core `mix test test/mailglass/operator/deliveries_projection_test.exs` | delete the Sent rule line; drop `bounced_at` then `terminal` from the projection select (each must fail); reorder detail so timeline precedes verdict (assert DOM order); omit the search patch; emit `bounced_at: false` in `outcome_groups` |
| BRADM-02 | `phase182_time_status_contract_test.exs` (render scan over the registry x `OperatorFixtures` grid incl. 210-cell status x event x confirmed; source scan; static `FMT` check; floor on scanned `<time>`/badge counts) | `mix test test/mailglass_admin/phase182_time_status_contract_test.exs --seed 0` | D-18's list: drop " UTC" in `utc_string`; bare `<time>` in a new component; icon-only badge; hand-coded `<span class="badge">` in a LiveView; remove `timeZoneName`; LiveView module missing from the registry; set a mark `aria-label`; `false` flag |
| BRADM-03 | `phase182_words_contract_test.exs` (recommended) render-scan: no visible/aria "Deliveries" noun on registered screens except the gloss; `copy_contract_test` vocabulary binding for `:activity` | `mix test test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/copy_contract_test.exs --seed 0` | reintroduce "Deliveries" in nav label / `<title>` / `aria-label`; set `:activity` `wired: true` with no screen literal (existing binding test) |
| BRADM-04 | same words file: no visible "Operator" and no "scoped operator data"/"current operator"; "Admin" present in the page title and shell | same | revert `operator_live.ex:134`; revert one of the 8 C-12 sites |
| BRADM-05 | words file + unit tests: `Copy.orphan_count_label/1` (0, 1, n), `MailerName.plain_name/1` (module+function, module-only, nil, blank, trailing dots, odd casing, never creates atoms), tooltip a11y render (`role="tooltip"`, `aria-describedby` target present, no `title`, full identity also visible, `break-words`) | `mix test test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0` | revert to "Unmatched events"; use `title=` for the identity; hide the full module on detail |
| BRADM-06 | `phase182_cause_contract_test.exs` (structural: `Copy.cause_sentence/1` has no `nil` clause; forbidden-phrase scan over visible text with allow-list; matrix = `Event.__reject_reasons__/0` + nil x {bounced, rejected, failed, deferred, delivered} plus `Entry.__reasons__/0` + nil; cell count equals product; Quick view asserts no cause and no fallback) | `mix test test/mailglass_admin/phase182_cause_contract_test.exs --seed 0` | interpolate a nil reason; add "will retry" to Delayed copy; delete an enum clause; skip a reason; render the fallback on Quick view |
| BRADM-07 | `after_catalog_manifest_test.exs` (extracted validators + verdict schema + pure `gate/1` outcomes + calibration presence + substring check + LIVE/SUPERSEDED binding) | `mix test test/mailglass_admin/after_catalog_manifest_test.exs test/mailglass_admin/before_catalog_manifest_test.exs --seed 0` | flip a verdict to pass; add an unlisted file; plant a hallucinated quote; drop the calibration set; make a known-bad calibration pass |

Advisory only (never cited as required proof): Playwright journey at 375/1440 x light/dark with `timezoneId` `UTC`, `America/New_York`, `Pacific/Auckland` (assert a zone token after `data-localized`), `scrollWidth <= innerWidth`, 44 px controls, `document.fonts.check`, `.phx-connected`.

### Sampling Rate
- **Per task commit:** the one scoped file for that task (`mix test <file> --seed 0`, seconds).
- **Per plan:** D-24 order in `mailglass_admin`: `mix format --check-formatted`; `mix mailglass_admin.assets.build --check`; scoped existing contracts (`root_theme_ownership`, `copy_contract`, `status_map`, `glyph_contract`, `font_assets_contract`, `before_catalog_manifest`, `persona_drift_guard`); new Phase 182 files; `bash scripts/check_test_exceptions.sh` (repo root); if core changed: `mix compile --warnings-as-errors` and `mix credo --strict` at root; then `mix verify.support_contract.admin` and core `mix test`.
- **Phase gate:** full admin + core suites green (baseline is zero failures, memory `project_full_suite_baseline_is_zero`), then capture/review last on a clean tree.

### Wave 0 Gaps
- [ ] `mailglass_admin/test/support/catalog_validators.ex` (C-11).
- [ ] `OperatorFixtures` rows: password-reset Sent-no-report, bounce, bounce-then-open, nil-reason bounce, deferred, suppressed, complained (module-only `mailable`, reserved `.example` recipients).
- [ ] `JourneySeed`, `brandbook/v2/status-marks.json`, `scripts/brand_status_marks.exs`.
- [ ] Framework install: none.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2/V3 Auth/Session | no change | existing `:operator_access` seam untouched |
| V4 Access Control | yes (read model) | `tenant_id` scoping stays in `Deliveries` (`fetch_tenant_id!`, `Tenancy.scope/2`); new fields are same-row columns, no cross-tenant path |
| V5 Input Validation | yes | `escape_like/1` (`deliveries.ex:156-161`) already guards `%`/`_`/`\`; the search input stays server-validated; plain-name derivation treats `mailable` as untrusted DB text: HEEx autoescape, no `raw`, no `String.to_atom` |
| V6 Cryptography | no | none |
| V8/V9 Data protection | yes | recipient emails appear on screen; capture validates reserved example domains (`unreservedEmails` in the driver) and the manifest test rejects non-reserved addresses; no new telemetry (CLAUDE.md: no PII in metadata) |
| V12 Files / V14 Config | yes (small) | extractor verifies the zip sha256 before reading any byte (as `brand_pin.exs` does) |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Reflected/stored XSS via `mailable` or recipient | Tampering | HEEx escaping; contract scan bans `Phoenix.HTML.raw` in new components |
| Atom exhaustion from DB strings | DoS | no `String.to_atom`; test asserts atom count unchanged across plain-name calls |
| Leaking exception text | Info disclosure | never render `last_error` (D-02); cause contract scans for module/exception shapes |
| PII in evidence artifacts | Info disclosure | reserved-domain seeds, driver and manifest email checks, reset-token check |

## Sources

### Primary (HIGH confidence, opened or executed this session)
- `/Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-CONTEXT.md`, `.planning/REQUIREMENTS.md` (BRADM-01..07), `.planning/STATE.md`, `CLAUDE.md`, `.planning/METHODOLOGY.md`
- Code: `lib/mailglass/operator/deliveries.ex`, `lib/mailglass/outbound/{projector,delivery,persistence}.ex`, `lib/mailglass/events/event.ex`, `lib/mailglass/suppression/entry.ex`, `mailglass_admin/lib/mailglass_admin/{copy,status_map,components,operator_live,gallery_live,surface_nav,preview_live,layouts}.ex`, `controllers/assets.ex`, `layouts/root.html.heex`, `operator/{quick_view,detail_header,timeline,suppression_card,support_cards,results_status,filters_form,deliveries_list,health_overview}.ex`, `preview/scenario_label.ex`
- Tests: `copy_contract_test`, `status_map_test`, `before_catalog_manifest_test`, `phase175_prohibition_contract_test`, `persona_drift_guard_test`, `glyph_contract_test`, `contrast_contract_test`, `voice_test`, `axe_baseline_test`, `brand_v2_compat_policy_test`, `test/support/{endpoint_case,live_view_case,operator_fixtures}.ex`; scripts `check-conformance.sh`, `check_test_exceptions.sh`, `guard_release_trigger.sh`, `gsd-regression-gate.sh`; `.github/workflows/{pr-title,ci}.yml`; `release-please-config.json`; `reference/demo_app/{lib/mailglass_demo/{catalog_seed,demo_data}.ex,assets/catalog/*,playwright.catalog.config.cjs}`
- Executed: route/`__live__`/`__components__` probe; `StatusMap` boolean probe; scoped test and pre-flight runs; Node `toLocaleString` and Elixir `Calendar.strftime` probes; zip sha256 and member extraction (`unzip`, `python3 -I`) of the pinned brand zip; `gh pr view 325`.
- `brandbook/v2/brand.json` (lines 256, 263, 649, 720, 725, 900), `brandbook/brand.pin.json`, `brandbook/tokens.css`.

### Secondary / Tertiary
- None. External prior art was covered by the CONTEXT fan-out and is intentionally not re-researched.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (nothing new; versions read from lockfiles).
- Architecture: HIGH (flows read and probed); MEDIUM for Pattern 2 colour/axe (A5).
- Pitfalls: HIGH (each reproduced or read in source); R1-R3 are product-truth calls, not unknowns.

**Research date:** 2026-11-15
**Valid until:** 2026-11-22 (line numbers drift on every merge; re-grep before editing; PR #325 and the Hex lines change on release)
