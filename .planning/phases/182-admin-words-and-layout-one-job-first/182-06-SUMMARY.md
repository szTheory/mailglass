---
phase: 182-admin-words-and-layout-one-job-first
plan: 06
subsystem: after-catalog-and-review
tags: [after-catalog, independent-review, rejection-gate, calibration, capture-driver, journey-seed, served-sha, advisory-journey, axe]

requires:
  - phase: 182-05
    provides: the advisory e2e specs and demo pins on the brand words, so the final catalog shows the words the pins expect
  - phase: 182-04
    provides: the word map and the Mailer row the catalog screens show
  - phase: 182-03
    provides: the zoned compact timestamps every screen shows
  - phase: 182-02
    provides: the class badge, the pane marks and the verdict block the reviewers judged
  - phase: 180
    provides: the capture pipeline, the before-catalog and the manifest validators this plan extends
provides:
  - MailglassDemo.JourneySeed, six password-reset rows on northstar read back from the stored rows
  - the capture driver's --mode after and --catalog-root, schema mailglass.after_catalog.v1, demo container PID and a server start later than the script start
  - phase182-journey.spec.js (14 scenario ids, 2 injected-defect shots, an advisory journey) and phase182-rubric.md
  - MailglassAdmin.TestSupport.CatalogValidators and ReviewGate (closed verdict schema, evidence-quote substring check, the one gate rule)
  - after_catalog_manifest_test.exs, 61 required-lane tests with mutation teeth on a synthetic catalog and on the committed one
  - the committed catalog after-1a0b741-20261116T004020Z with 44 verdict files and its review manifest
  - delivery help text and the Awaiting confirmation tile name an email, not a message (a reviewer finding, fixed with a test)
affects: [183 docs and the brand v2 release, any later bundle or root-layout change (needs a current superseded.json for this catalog)]

actuals:
  tokens: 100844
  tasks: 3
  commits: 10
plan_head_before: e13e4f21f48df36f77ff213bd9539da2d5d52a59
plan_head_after: c1ab617720c1596d018ff39ba6c5f4cd897ec072

tech-stack:
  added: []
  patterns:
    - "an evidence producer runs its advisory tests in a second Playwright invocation (--grep @advisory) so an advisory failure is reported and never withholds the evidence"
    - "calibration items carry neutral ids (calib-NN): a reviewer told 'known-good' or 'no-zone' would be biased"
    - "a gate that splits verdict failures into schema failures (red) and unverifiable quotes (a reject is dropped, a pass is red), and sorts judges by name so the outcome does not depend on list order"
    - "the A/B order of the first two judges of a paired scenario is a pure function of a recorded seed (:erlang.phash2), so a test can recompute it"

key-files:
  created:
    - reference/demo_app/lib/mailglass_demo/journey_seed.ex
    - reference/demo_app/assets/catalog/phase182-journey.spec.js
    - reference/demo_app/assets/catalog/phase182-rubric.md
    - mailglass_admin/test/support/catalog_validators.ex
    - mailglass_admin/test/support/review_gate.ex
    - mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs
    - mailglass_admin/test/mailglass_admin/phase182_review_words_test.exs
    - .planning/research/brand-v2-adoption/after-catalog/after-1a0b741-20261116T004020Z/
  modified:
    - reference/demo_app/assets/catalog/capture-before-catalog.cjs
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - .planning/phases/182-admin-words-and-layout-one-job-first/deferred-items.md

key-decisions:
  - "A judge verdict that breaks the closed schema is discarded and a fresh judge replaces it; it is never edited. Two stray-key verdicts (calib-02, judges a and c) were replaced by judge d, and the discarded files are named in this summary."
  - "When the first review rejected scenarios for the word 'message' (a real brand-word finding), the product text was fixed with a deterministic test. When it rejected 'Queued' and event names, which two locked decisions (D-02, D-10) already allow, the rubric was clarified, the catalog recaptured under a new id and judged again by fresh judges."
  - "Calibration ids are neutral (calib-NN) and the before-as-after PNGs are referenced in the immutable Phase 180 catalog, not copied."
  - "The injected defects must be plain: a status-word defect that left 'Failed:' in the sentence was passed by both judges, so the injection was fixed and verified against the running demo before the last recapture."
  - "The cold-build proof of the admin lane moved the admin _build/test aside instead of using MIX_BUILD_PATH, which cannot compile premailex on this machine."

requirements-completed: [BRADM-07, BRADM-01]

coverage:
  - id: D1
    description: "JourneySeed, the driver's after mode with the clean-tree exemption, the catalog journey spec and the rubric, proved by one smoke capture validated end to end"
    requirement: BRADM-07
    verification:
      - kind: other
        ref: "node --check on the driver and the spec; cd reference/demo_app && mix compile --warnings-as-errors (rc 0); smoke catalog after-47fadf2-20261116T001057Z promoted to the scratchpad with schema mailglass.after_catalog.v1 and server.started_at later than script_started_at"
        status: pass
    human_judgment: false
  - id: D2
    description: "ReviewGate and CatalogValidators are pure, exhaustively unit-tested, and the manifest test rejects every D-21 tamper case on a synthetic catalog"
    requirement: BRADM-07
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs (gate branches a-m, verdict schema, shared validators, seed text, 22 teeth); mix test with the before catalog test: 109 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "The committed catalog was captured last, on a clean tree, from served bytes equal to the committed bundle, and every scenario passed two independent judges whose power to reject was calibrated"
    requirement: BRADM-07
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/after_catalog_manifest_test.exs#the committed after-catalog (LIVE binding, ReviewGate.gate/1 == {:pass, []}, 5 before_as_after + 2 injected_defect + 1 known_good)"
        status: pass
      - kind: other
        ref: "five mutations on the committed catalog (flipped verdict, unlisted file, hallucinated quote, dropped calibration, passing known-bad) each turned that test red; restored, green"
        status: pass
    human_judgment: false
  - id: D4
    description: "The password-reset journey runs in a real browser at 375 and 1440, light and dark, in three time zones (advisory)"
    requirement: BRADM-01
    verification:
      - kind: e2e
        ref: "capture driver advisory pass on the final catalog run: 7 passed (4 journey cells, the suppressed next-step link at 44 px, America/New_York, Pacific/Auckland); advisory, never the required proof (the required proof is phase182_journey_test.exs from plan 02)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Delivery help text and the Awaiting confirmation tile name an email; a reviewer finding closed with a deterministic test"
    requirement: BRADM-07
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_review_words_test.exs (5 tests); reverting either string fails 2 tests"
        status: pass
    human_judgment: false
  - id: D6
    description: "The advisory axe run did not rise, and the baseline is unchanged"
    requirement: BRADM-01
    verification:
      - kind: e2e
        ref: "cd mailglass_admin && PERSIST_AXE_BASELINE=1 npm run test:operator-browser -- axe-baseline.spec.js: 9 passed; all nine cells equal the committed counts, so docs/axe-baseline.json was restored (advisory)"
        status: pass
    human_judgment: false

duration: 49min
completed: 2026-11-16
status: complete
---

# Phase 182 Plan 06: The after-catalog is captured last, judged by fresh reviewers behind a rejection gate, and bound in the required lane

**`MailglassDemo.JourneySeed`, the driver's after mode, a journey spec and a rubric produced the committed catalog `after-1a0b741-20261116T004020Z`: 14 scenarios and 2 injected defects captured on a clean tree from served bytes equal to the committed bundle, every scenario passed by two fresh independent judges, seven of seven known-bad calibration items rejected and the known-good passed, and `after_catalog_manifest_test.exs` proves the whole thing in the required lane with mutation teeth.**

## Performance

- **Duration:** 49 min (start 2026-11-15T23:58Z, end 2026-11-16T00:47Z)
- **Execute-start SHA (`<start>`):** `e13e4f21f48df36f77ff213bd9539da2d5d52a59`
- **Tasks:** 3 (1 tracer, 1 TDD auto, 1 auto)
- **Commits:** 10, measured by `git rev-list --count e13e4f21..HEAD` = 10 (the summary and state commits come after)
- **Tokens (chars/4 over the realized source diff, no PNG and no evidence text):** about 100,800 against the plan's 135,000 estimate (low confidence); the committed evidence text adds about 53,500 more on the same scale
- **Judging:** 46 `claude -p` runs on the final catalog (44 verdict files kept, 2 discarded as schema-invalid), 44 more on iteration 1 and 44 on iteration 2

## Accomplishments

- **JourneySeed (D-16).** Six password-reset rows on `northstar` (sent with no report, typo bounce with `reject_reason invalid`, bounce then open, nil-reason bounce, deferred, suppressed with a `hard_bounce` entry) go through the real changesets and `Projector.update_projections/2`; the case map is read back from the stored rows, and the file holds no retry phrase and no `"reason"`/`"cause"` key.
- **Capture driver.** `--mode before|after` and `--catalog-root`; after mode seeds both seeds, writes `mailglass.after_catalog.v1`, runs only `catalog/phase182-journey.spec.js`, records the demo container PID and `started_at`, refuses a server that did not start after the script began, and exempts exactly one path from the clean-tree check (`.planning/config.json`). Before mode still passes `catalog/before-catalog.spec.js` and otherwise behaves as at Phase 180.
- **Review pipeline.** Fresh judges are `claude -p --safe-mode --tools Read` processes in an empty temp directory holding only the candidate PNG, optionally the previous design as image A or B, `aria.yml` and `rubric.md`; the prompt adds the one-line goal and the identity values. The A/B order of paired scenarios comes from the recorded seed (`rng_seed 309608052`).
- **Gate and calibration.** `ReviewGate.gate/1` returns `{:pass, []}` for the committed catalog. Calibration: five Phase 180 captures shown as the new design, two injected defects (zone removed, status word removed), one known-good; all seven known-bad items were rejected by both valid judges and the known-good passed.
- **Required-lane proof.** `after_catalog_manifest_test.exs` validates the closed manifest, files, PNG headers, budget, privacy, the LIVE binding to the current `app.css` sha256 and root layout blob, the review manifest, every verdict's inputs, the seeded orders and the gate.

## Task Commits

1. **Task 1 (tracer):** `94b336cd` chore(demo): capture tooling for the brand v2 after-catalog; `47fadf26` fix(demo): journey spec waits on the real empty-state control and the mobile row button. Tracer gate: no `gate="blocking-human"`, auto mode off, `HUMAN_VERIFY_MODE` default with an automated-only `<verify>`; the verify commands were re-run on the committed content (node checks, demo compile rc 0, smoke manifest "ok") and logged "Tracer verified end-to-end, expanding".
2. **Task 2:** `4c6dd606` test(admin): review gate and after-catalog validators; `202dc871` test(admin): calibration items carry neutral ids.
3. **Task 3:** `432ebeb1` feat(admin): delivery help text names an email, not a message; `6aecbded` test(admin): delivery help text and summary tiles name an email; `f2e8eeeb` chore(demo): rubric states the queued qualifier and event names; the status-word defect is plain; `1a0b7419` fix(demo): the injected status-word defect strips the verdict sentence's leading class word; `52623d7b` docs: add the brand v2 after-catalog and its review; `c1ab6177` test(admin): bind the after-catalog review in the admin lane.

## Task 1 acceptance (recorded as the plan asks)

- **Clean-tree exemption (checker B2).** With only `.planning/config.json` modified, `assertCleanTree` returned without refusing. With `touch reference/demo_app/assets/catalog/.probe` (untracked) it refused: `probe-2: the working tree is dirty, so the recorded commit would not describe what was captured. | ?? reference/demo_app/assets/catalog/.probe | Commit or discard these changes, then run again.` (probe removed). `dirtyPathsBlocking(" M .planning/config.json\n")` is `[]`; the same text plus an untracked path, or a rename onto the file, is not. `grep -c "':!.planning/config.json'" capture-before-catalog.cjs` prints 1.
- `grep -c 'JOURNEY_CASES_JSON=' journey_seed.ex` prints 1. `grep -c mode` on the driver: 0 at HEAD, 33 now; the before-mode spec is `MODES.before.spec = "catalog/before-catalog.spec.js"`.
- The protected paths exist, and `git diff --name-only e13e4f21..HEAD -- catalog_seed.ex demo_data.ex personas.ex` prints nothing (also nothing for `before_catalog_manifest_test.exs`, `quick_view_scenarios.json` and `before-catalog.spec.js`).
- **Smoke capture:** `after-47fadf2-20261116T001057Z`, promoted outside the repo (scratchpad `--catalog-root`), never committed. Its advisory journey passed 7 of 7 (375 light, 375 dark, 1440 light, 1440 dark, the suppressed next-step link at 44 px, `America/New_York` and `Pacific/Auckland`). The first smoke run failed one capture (the empty-state wait used a hidden marker node) and was fixed in `47fadf26`.

## Task 3: the phase gate, axe, capture, review

**Phase gate (before every capture):** `mix format --check-formatted` (admin and root) clean; `mix mailglass_admin.assets.build --check` "matches a fresh build (138536 bytes)", bundle unchanged by this plan; the scoped contracts plus `phase182_*` and both catalog tests 371 tests, 0 failures; `check-conformance.sh` clean; `check_test_exceptions.sh` OK; root `mix compile --warnings-as-errors` rc 0; `mix credo --strict` no issues (570 files); core `mix test --seed 0`: 2399 tests, 23 properties, **1 failure, the known environmental one**; `mix verify.support_contract.admin`: 1749 tests, 0 failures (1754 after iteration 2's lib text change, 1756 on the final tree, cold).

**The one known environmental core failure (recorded, not hidden):** `Mailglass.Scripts.Phase164RepositoryTruthTest` "git runtime rules do not conceal the retired finalize-phase extension paths" fails here only because of the untracked local `.gsd/.gitignore` (`*`). Evidence: `git check-ignore -v .gsd/extensions/finalize-phase/index.ts` prints `.gsd/.gitignore:1:*`, and `git ls-files --error-unmatch .gsd/.gitignore` says it is not tracked; 182-01 showed all five assertions hold in a fresh `git clone --local`. Every other core test passed.

**Cold admin lane:** `MIX_BUILD_PATH="$(mktemp -d)/test" mix verify.support_contract.admin` cannot compile `premailex` on this machine (see Deviations). The equivalent cold proof, with `mailglass_admin/_build/test` moved aside and restored afterwards, ran 1756 tests, 0 failures, exit 0, on the final tree.

**Axe (advisory, D-23):** 9 passed. All nine cells equal the committed counts (`deliveries` and `inbound` 0 in light, dark and system; `preview` 1 `aria-allowed-attr` in each), so nothing was persisted and `docs/axe-baseline.json` was restored (only its `run_id` had moved).

**Final catalog:** `after-1a0b741-20261116T004020Z`, source `1a0b741980e6df05fa73b1fbe144a682ae0dc8e7`, `dirty: false`, recheck clean and head unchanged. Served `css-92945867e10190702a0dbe242ae69e27` sha256 `fc2df1a788e0089beb3c9778582917e0b5cbe10d231795ea05f23e757fadc1f0` equals the working tree and `git show 1a0b741:mailglass_admin/priv/static/app.css` (blob `f750815ac50ef6267dfb084203708f3a006c6872`); served js `js-63a077f9ed18947ef7f69ff45d5b5f7a` sha256 `3049edd1bc2ca1008a15bca3a1274d052d42b7707c26672573e13ba34e148698` carries the committed `hooks.js`. Container PID 94796, `server_started_at` 00:40:22.804Z later than `script_started_at` 00:40:20.688Z. 16 PNGs, 2,130,949 bytes (cap 15,000,000). Nothing under `mailglass_admin/lib`, `priv` or `lib` changed after this capture (`git diff --name-only 1a0b741..HEAD` over them is empty).

### Iterations (the plan allows three; all three were used)

| Iteration | Catalog id (never committed except the last) | Outcome |
|---|---|---|
| 1 | `after-202dc87-20261116T003123Z` | Gate red. Standing rejects: `deliveries__northstar__empty-search__375__light` (two judges, R-WORDS-1 "Messages are queued"), `deliveries__northstar__default__1440__light` (two judges: "Queued" as a status word, "Messages", a clipped row), `deliveries__northstar__reset-search__1440__light`, `delivery-detail__reset-typo-bounce__default__375__dark` and `delivery-detail__reset-sent-no-report__default__375__light` (one judge each, "This message was handed to the provider"). Calibration red: the injected status-word defect was passed by judge a; two judge-b outputs held a draft and a corrected object and were unparseable. |
| 2 | `after-f2e8eee-20261116T003731Z` | All 14 scenarios passed by two judges. Calibration red: both judges passed the status-word defect, because the injection missed the leading space of the sentence's text node and "Failed:" stayed on the page. Not a product reject. |
| 3 (committed) | `after-1a0b741-20261116T004020Z` | Gate `{:pass, []}`: 14 scenarios x 2 judges all pass, 7 known-bad rejected by both valid judges, known-good passed by both. |

What changed between iterations: product wording (`432ebeb1` plus its test `6aecbded`), a rubric clarification (`f2e8eeeb`), and the injection fix (`1a0b7419`, verified against the running demo with three fresh probe judges, all rejecting on R-STATUS-1, before the last capture). `prior_iterations` in the review manifest records iterations 1 and 2.

### Teeth (mutations, with failing test names)

On the gate (real source edited, watched red, restored): a lone valid reject made to pass failed `(b) one pass and one valid reject`, `(d2) a third judge's reject after two passes still blocks` and `a scenario reject that stands blocks the gate`; the substring check removed failed `(e)`, `(g)`, `an evidence quote that is not a substring ... hallucinated quote` and `a hallucinated quote on a pass is red`; a passed known-bad tolerated failed `(j)` and `a known-bad that a judge passed is red`.

On the committed catalog (each in `after_catalog_manifest_test.exs`, "the committed after-catalog every catalog directory validates, its review passes the gate, and the calibration is complete"): a verdict flipped to pass (`calib-01` judge a: `a pass must not cite a failed rule`), an unlisted `review/notes.md`, a hallucinated quote planted in a scenario verdict, `calibration: []` in the review manifest, and both `calib-01` verdicts made passes (`a known-bad passed (judge a, b)`) were each red; the restored catalog is green. The synthetic-catalog describe adds a PLAN.md verdict input, a mismatched screenshot sha256, a server start not later than the script start, a stale `manifest_sha256`, a seed-violating A/B order, a gutted rubric and an unreserved email.

### D-16 duplicate-fixture check

Inspected at the start SHA: `DemoData` and `CatalogSeed` reference six mailables: `AccountMailer.invite_admin` (8 references; the CatalogSeed `typo-bounce` and `unicode-recipient` rows), `AccountMailer.magic_link`, `BillingMailer.receipt_paid` (4; the CatalogSeed `sent-no-report` row) and `payment_failed`, `OperationsMailer.usage_alert` (5; the DemoData `nil-reason-bounce` and `deferred-no-retry` rows and the CatalogSeed `send-failed` row) and `incident_update` (`manual-suppressed`). `git grep password_reset` over `reference/demo_app/lib` and `reference/persona_spec` at the start SHA finds nothing, so no password-reset row existed and the six `reset-*` rows are new, not duplicates. The two pairable scenarios reuse the identically named Phase 180 ids.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The reviewers found real brand-word defects in delivery screens**
- **Found during:** Task 3, iteration 1
- **Issue:** the delivery timeline's outcome help and the Awaiting confirmation tile said "message" where the book says "email" (R-WORDS-1).
- **Fix:** `Components.outcome_help(:delivery, ...)`, a delivery fallback clause and the tile text now say email; `phase182_review_words_test.exs` enumerates every `Copy.statuses()` key and the three tiles. Inbound strings and the evidence-bound support-card strings are unchanged (logged in `deferred-items.md`). Text only; the bundle check still matches.
- **Files:** `components.ex`, `operator_live.ex`, `phase182_review_words_test.exs`. **Commits:** `432ebeb1`, `6aecbded`

**2. [Rule 2 - Missing] The rubric omitted two locked decisions**
- **Found during:** Task 3, iteration 1 (judges rejected a `Queued` badge and event names such as "Latest: Bounced")
- **Issue:** D-02/179 D-03 (a queued email reads Sent with the qualifier Queued) and D-10 (event atoms keep word badges) are locked, but the rubric said "exactly five status words". Judging by an incomplete rubric rejected correct screens.
- **Fix:** the rubric now states both, and that a list scrolling inside its own bordered area is not cut-off content; the catalog was recaptured under a new id and judged by fresh judges, not argued. A reader can see the change in `f2e8eeeb`; this is the judgement call a reviewer of this plan should look at first.
- **Files:** `phase182-rubric.md`. **Commit:** `f2e8eeeb`

**3. [Rule 1 - Bug] The injected status-word defect was not plain**
- **Found during:** iterations 1 and 2 (judge a, then both judges, passed the "known-bad")
- **Issue:** the defect removed the badge word and the heading, but the sentence still opened "Failed:", and the first fix left the text node's leading whitespace in front of its pattern.
- **Fix:** the injection strips the class word that opens the verdict sentence (allowing leading space); checked against the running demo and by three probe judges before the last capture.
- **Files:** `phase182-journey.spec.js`. **Commits:** `f2e8eeeb`, `1a0b7419`

**4. [Rule 3 - Blocking] Judge output the harness had to handle**
- **Found during:** iterations 1 and 3
- **Issue:** two iteration-1 outputs held a draft object and a corrected object (the parser now takes the judge's final object); two iteration-3 verdicts carried a stray key (`calib-02` judge a: `evidence_quote_note`, judge c: `reason`), which the closed schema rejects.
- **Fix:** nothing was edited. The two schema-invalid files were set aside (scratchpad `discarded3/calib-02.a.json.INVALID-extra-key` and `calib-02.c.json.INVALID-extra-key`), and a fresh judge d answered `calib-02` (valid, reject). `calib-02`'s committed verdicts are judges b and d. The prompt now lists the allowed keys.
- **Files:** none in the repository (harness lives in the scratchpad).

**5. [Rule 3 - Blocking] The cold-build form of the admin lane cannot run on this machine**
- **Issue:** `MIX_BUILD_PATH=<fresh temp>/test mix verify.support_contract.admin` stops compiling `premailex` (`priv/entities.txt` not found); pre-seeding the priv link by hand did not help.
- **Fix:** the same proof by moving `mailglass_admin/_build/test` aside, running the lane (1756 tests, 0 failures, exit 0) and restoring it. Logged in `deferred-items.md`.

**6. [Plan wording] Choices the plan left open**
- The advisory journey runs in a second Playwright invocation (`--grep @advisory`) so its result is printed, never required and never withholds evidence; capture tests use `--grep-invert @advisory`.
- Calibration ids are `calib-NN`; the `before_as_after` PNGs are referenced in the Phase 180 catalog by repo path and sha256, not copied (the plan said "contribute their PNG + aria").
- Judges are the `sonnet` model alias (the same model family as the executor), disclosed as a limit.

**Total deviations:** 6 (2 bugs found by the review, 1 missing rubric content, 1 injection bug, 2 blocking environment/tooling). **Impact on plan:** none on scope. The committed catalog is the third iteration; the plan's three-iteration limit is fully used.

## Issues Encountered

- **Known environmental core failure:** `Phase164RepositoryTruthTest` (see Task 3).
- **Docker lanes rewrite tracked PNGs under `.planning/milestones`:** this plan ran only the catalog driver, which does not; the tree was clean (`git status --porcelain --untracked-files=all -- . ':!.planning/config.json'` empty) before every capture and after the last commit. `reference/demo_app/mix.lock` was restored after the demo compile.
- **Primary seed branch fails, the in-harness fallback succeeds** (the demo endpoint is already listening); every run logged it and took the fallback, as in Phase 180.

## Known Stubs

None. Test files, tooling and evidence; nothing renders an empty or placeholder value.

## Threat Flags

None. The plan's threats are mitigated and tested: T-182-12 (hallucinated evidence) by `validate_verdict/2` and the calibration set; T-182-13 (tampering) by the sha256 bindings, the unlisted-file rule and the LIVE binding; T-182-14 (served build vs source) by the PID, the start-time ordering and the served-asset hashes; T-182-15 (disclosure) by the driver's reserved-domain check plus `unreserved_emails/1` in the required test over the manifest, cases, aria, rubric and verdict files. The reset token appears nowhere in the committed catalog.

## Disclosed limits

- Whether each judge was isolated is a property of how the verdicts were produced; the files show only the recorded inputs (`aria.yml`, `image-a.png`, optionally `image-b.png`, `rubric.md` in the temp directory, recorded in the harness run log) and the seeded orders.
- A pass by two Sonnet-class judges is evidence of brand fit, not proof; the deterministic contracts (text, zones, marks, nil-reason phrases, contrast, overflow) remain the required proof for those.
- The review harness is not committed (it lives in the executor scratchpad); the committed evidence is the verdicts, the review manifest and the rubric.

## User Setup Required

None.

## Next Phase Readiness

- BRADM-07 and BRADM-01 are copied above verbatim from the plan; this is the last plan declaring them. With this plan the phase has 6 of 6 summaries.
- A later change to `mailglass_admin/priv/static/app.css` or the root layout makes this catalog superseded: the same change must add `after-1a0b741-20261116T004020Z/superseded.json` (schema `mailglass.after_catalog.superseded.v1`, `superseded_by` equal to the new bundle sha256 and root layout blob), exactly as for the before catalog.
- Phase 183 (docs) can cite this catalog's manifest sha256 and review.

## Self-Check: PASSED

All ten task commits are ancestors of HEAD (`94b336cd`, `47fadf26`, `4c6dd606`, `202dc871`, `432ebeb1`, `6aecbded`, `f2e8eeeb`, `1a0b7419`, `52623d7b`, `c1ab6177`); the created files and the catalog directory exist; `after_catalog_manifest_test.exs` and `before_catalog_manifest_test.exs` pass together (109 tests, 0 failures); `git status --porcelain --untracked-files=all -- . ':!.planning/config.json'` is empty; the three plan-level verify commands exit 0 on the final tree (cold lane in place).

---
*Phase: 182-admin-words-and-layout-one-job-first*
*Completed: 2026-11-16*
