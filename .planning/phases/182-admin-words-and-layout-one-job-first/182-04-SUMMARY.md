---
phase: 182-admin-words-and-layout-one-job-first
plan: 04
subsystem: admin-words-rollout
tags: [activity-admin-account, vocabulary-wired, orphan-sentence, mailer-plain-name, field-help-tooltip, words-contract, screen-registry, mutation-proof]

requires:
  - phase: 182-03
    provides: MailglassAdmin.TestSupport.ScreenRegistry (states/1, visible_text/1), the zone-and-mark contract this plan's words scan sits beside
  - phase: 182-02
    provides: the class badge and verdict the rows already read, Copy.vocabulary/0 and class_labels/0
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: the gloss table (Operator/Admin, Tenant/Account, Deliveries/Activity, orphan/provider reports) and the stability tests that must pass unedited
provides:
  - the Deliveries screen named Activity in nav, h1, document title, orientation heading, empty states, pagination landmark, result counts, back and return links, Preview return label and Preview subtitle, with the gloss "Every email your app sent, one row per delivery." under the h1
  - Admin and Account where the screens said operator (document title, no-Account and denial sentences)
  - Copy.vocabulary/0 :admin, :activity and :unmatched_reports wired (every wired entry is now bound to a screen string)
  - MailglassAdmin.Operator.OrphanCount.label/1 and the heading "Provider reports that match no email"
  - MailglassAdmin.Operator.MailerName.plain_name/1 and identity/1, the Mailer row on Full detail (help trigger + visible identity) and the plain name on list rows
  - ScenarioLabel.humanize/1 binary clause (still one String.capitalize call)
  - phase182_words_contract_test.exs (26 tests) and operator/mailer_name_test.exs (15 tests)
affects: [182-05 advisory e2e and demo pins, 182-06 after-catalog and review]

actuals:
  tokens: 22500
  tasks: 3
  commits: 5
plan_head_before: 3564297816c70e6d17339d9481888f8164bc9a3a
plan_head_after: f99a69637e54b4529f8e20b71f6306dd7131df65

tech-stack:
  added: []
  patterns:
    - "a words contract scans the same ScreenRegistry the time and status contract scans, reading page text (hover and screen-reader text kept), word-bearing attributes and the document <title>, so one new screen is caught by both"
    - "an identifier is data, not a word: the detectors refuse a match touching a word character or a hyphen (tenant_id, deliveries_path, browser-tenant)"
    - "a retired-phrase source scan covers sentences a render cannot reach (a denial only shows when auth denies)"
    - "a pure detector for one component row (Mailer) with a planted mutant per way it can fail the reader"
    - "plain-name derivation on binaries only, with a VM atom-count check and a control that proves the instrument sees atom creation"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/operator/orphan_count.ex
    - mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex
    - mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs
    - mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/copy.ex
    - mailglass_admin/lib/mailglass_admin/surface_nav.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
    - mailglass_admin/lib/mailglass_admin/operator/quick_view.ex
    - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
    - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator/detail_header.ex
    - mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex
    - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
    - mailglass_admin/lib/mailglass_admin/preview/return_context.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex
    - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/support/operator_fixtures.ex
    - "17 ExUnit files whose pins moved (listed under Changed pins)"

key-decisions:
  - "The gloss replaces the old Activity subtitle ('Trace each delivery through its event history.') instead of adding a second paragraph under the h1: one line under the h1 keeps the verdict above the fold at 375px, and the old subtitle was pinned only in the before-catalog evidence."
  - "The document <title> follows the screen: 'mailglass — Activity' on the Activity screen, 'mailglass — Admin' on the overview and as the mount default. The plan's truth says the screen reads Activity in its <title>, and a tab named 'Admin' for every Operator view says nothing."
  - "The words detectors refuse a match that touches a word character or a hyphen. A plain \\b flagged 418 hits that were the fixture Account id 'browser-tenant'; an Account id is adopter data, and tenant_id and deliveries_path are code. The cost is that a hyphenated word such as 'tenant-scoped' would escape, accepted and recorded."
  - "Tooltip and screen-reader text count as page text in the words scan (unlike ScreenRegistry.visible_text/1): a help sentence is still a sentence, and the plan rewords help strings (FiltersForm, tiles, orphan help) that only a hover scan reaches."
  - "The retry control reads 'Retry loading activity' (testid operator-retry-deliveries unchanged): 'Retry deliveries' would now be banned by the contract and, worse, reads as retrying a send."
  - "The field_help label of the Mailer trigger is the plain name, not 'Mailer' as the plan text said: the accessible name must contain the visible text (WCAG 2.5.3), the defect 182-03 fixed for timestamps. The <dt> 'Mailer' supplies the context."
  - "The Mailer row replaces the old 'Mailable' row of the collapsed Technical details and sits first in the visible field grid."
  - "Fixture data may not use the retired words: the default fixture mailable 'Mailglass.Example.OperatorMailer' (it would read 'Operator mailer') became 'BrowserMailer', the neighbouring fixtures' name."
  - "The orphan support card now shows the sentence in place of a lone display number, because the number plus a count-aware tail cannot be built from label/1 alone and the sentence carries its own count."
  - "A name with no letter or digit (for example '_' or '...') has no plain name: nothing is invented from punctuation."
  - "Adopter-supplied denial messages are outside mailglass's copy (the real product shows what the adopter's auth returns); the test adapter's fixture message was reworded so the scan needs no allow-list entry."

requirements-completed: [BRADM-03, BRADM-04, BRADM-05]

coverage:
  - id: D1
    description: "The Activity screen reads Activity in its nav (both layouts), document title, h1 and orientation heading, with the gloss under the h1; routes, deliveries_path, data-testids, surface_nav keys and modules keep their names"
    requirement: BRADM-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#Activity identity (BRADM-03, D-11)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/stability_contract_test.exs (unedited)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No registered screen state (89 states: Preview, Gallery, the status grid, the journey histories, the replay modal, the 101-event timeline, the Inbound list and records) shows Deliveries, operator or tenant as a word in page text, aria-label, title, alt, placeholder, aria-description or <title>"
    requirement: BRADM-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#words scan over every registered state (D-11, D-18)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Activity list with no rows, with filters matching nothing and beyond the last page, and the unresolved delivery links, say Activity; no Account selected reads with Account and no operator word"
    requirement: BRADM-04
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#states the registry does not carry (BRADM-03, BRADM-04, D-11)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Preview return link from Activity reads 'Back to Activity'; the retired phrases (old labels, operator sentences, old tiles, old orphan wording) are absent from lib strings"
    requirement: BRADM-03
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#Preview return link and #retired words stay out of the source"
        status: pass
    human_judgment: false
  - id: D5
    description: "Copy.vocabulary/0 :admin, :activity and :unmatched_reports are wired and every wired on_screen word is bound to a screen string literal"
    requirement: BRADM-03
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/copy_contract_test.exs#vocabulary binding"
        status: pass
    human_judgment: false
  - id: D6
    description: "OrphanCount.label/1 is exact for 0, 1, 2, 11 and 1000 and raises for negative, fractional and non-integer counts; the support cards read the sentence for one, many, none and unknown counts"
    requirement: BRADM-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#the provider-report sentence (BRADM-05, D-12)"
        status: pass
    human_judgment: false
  - id: D7
    description: "MailerName.plain_name/1 derives Password reset from Module.function and Account mailer from a module alone, returns nil for nil, blank and nameless values, never raises, and creates no atom"
    requirement: BRADM-05
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs (15 tests, atom count checked over 1000 random inputs with a control)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Full detail shows the Mailer as a help trigger holding the plain name, a tooltip and hidden description holding the stored identity, the identity printed in full (mono, break-words, visible), no title in the row, outside the collapsed Technical details; list rows show the plain name; a nil or blank mailable draws nothing; a hostile stored value stays text"
    requirement: BRADM-05
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs#the mailer on Full detail and in the list (BRADM-05, D-13) and #detectors have teeth"
        status: pass
    human_judgment: false
  - id: D9
    description: "The route and API contract tests and the docs contracts pass unedited"
    requirement: BRADM-03
    verification:
      - kind: other
        ref: "git diff 35642978..HEAD over stability_contract_test, operator_trust_doc_test, test/mailglass/docs_contract_test.exs, mailglass_inbound/test and router.ex is empty; mix verify.support_contract.admin exit 0"
        status: pass
    human_judgment: false

duration: 29min
completed: 2026-11-15
status: complete
---

# Phase 182 Plan 04: Activity, Admin and Account on every screen, the provider-report sentence and a mailer with a plain name

**The Deliveries screen is now called Activity everywhere a reader meets it (nav, tab title, h1, empty states, back links, counts), "Operator" is gone from screen text, an orphan count reads "5 provider reports match no email", and a mailer shows as "Password reset" or "Account mailer" with its stored identity printed beside it; a 26-test words contract scans 89 states with thirteen recorded mutations that turn it red.**

## Performance

- **Duration:** about 29 min (start 2026-11-15T23:03:22Z, end 23:32Z)
- **Execute-start SHA:** `3564297816c70e6d17339d9481888f8164bc9a3a`
- **Tasks:** 3 (1 tracer, 1 auto, 1 TDD-flagged auto)
- **Commits:** 5, measured by `git rev-list --count 35642978..HEAD` = 5 (the summary and state commit come after)
- **Files changed:** 41 outside `.planning`, 1634 insertions and 241 deletions
- **Tokens (chars/4 over the realized diff, bundle excluded):** about 22,500 against the plan's 128,000 estimate (low confidence; about 5.7x high, the third plan in a row more than 4x high)

## Accomplishments

- **Activity.** `surface_nav.ex` labels the `:deliveries` item Activity (key unchanged). The h1, the orientation heading and the tab title read Activity; the gloss "Every email your app sent, one row per delivery." sits under the h1 where the old subtitle was. The document `<title>` follows the screen (`sync_page_title/1`): "mailglass — Activity" there, "mailglass — Admin" on the overview.
- **Everywhere else.** Empty states (`No activity in this time window`, `No activity matches the current filters`, `No activity on this page`), `Activity pagination`, result counts (`N emails`), the status region (`N emails match`), `Back to Activity`, `Go to Activity`, `Return to Activity`, the Preview return label and subtitle, the Gallery specimens, the health tiles (`Failed emails`, `Bounced emails`, `Rejected emails`, `Delayed emails`) and their help.
- **Admin and Account.** The no-Account sentence is `Select an Account to see its activity.` (Inbound list: `... its inbound messages.`); the four Inbound denial sentences and `DestructiveAction`'s default end `for this admin account.`; the tab title says Admin.
- **Vocabulary.** `:admin`, `:activity` and `:unmatched_reports` are `wired: true`; `copy_contract`'s binding test now requires each on-screen word in a screen string. `OrphanCount.label/1` lives outside `copy.ex` so the binding sees its literal.
- **Orphan sentence.** `0 provider reports match no email`, `1 provider report matches no email`, `N provider reports match no email`; the group heading is `Provider reports that match no email` (health row, focus title, notices, the reconciliation fact label). The Tier-1 support card shows the sentence, the zero row reads `0 provider reports match no email in this window`, an unknown count reads `Provider reports that match no email are unavailable`.
- **Mailer.** `MailerName.plain_name/1` and `identity/1` (binaries only, no atom). Full detail gets a Mailer row first in the field grid: the plain name is a `field_help` trigger, the tooltip and hidden description hold the identity, the identity is also printed in a `mono block break-words` span, and the row has no `title`. List rows (table and cards) show the plain name; a nil or blank mailable draws nothing.
- **Contract.** `phase182_words_contract_test.exs` scans every `ScreenRegistry` state plus the empty, filtered, beyond-last-page, unresolved-link, no-Account and Preview-return states, and a retired-phrase source scan.

## Task Commits

1. **Task 1 (tracer):** `2c38e690` feat(admin): label the deliveries screen Activity. Tracer gate: no `gate="blocking-human"`, auto mode off, `HUMAN_VERIFY_MODE` end-of-phase with an automated-only `<verify>`; the verify command was re-run on the committed tree (370 tests, 0 failures, bundle and conformance clean) and logged "Tracer verified end-to-end, expanding".
2. **Task 2 lib:** `145b7089` feat(admin): use Activity, Admin and Account across admin screens.
3. **Task 2 tests:** `abefd911` test(admin): move pinned screen words to Activity and Admin. The plan prescribed two commits (lib, then tests), so the required lane is red between them by design; it is green at both ends.
4. **Task 3:** `87435e49` feat(admin): plain mailer names and the provider-report sentence (tests and lib in one commit, as the plan prescribed; see TDD notes).
5. `f99a6963` test(admin): prove a hostile stored mailer name is escaped (T-182-10, added after the threat model was re-read).

## Task 1 scan inventory (what Task 2 had to clear)

The first full scan read 89 states and reported 734 hits. 418 of them were the fixture Account id `browser-tenant` matching `\btenant\b` (data, not words); once the detectors refused identifier fragments, 316 hits remained, all of the `deliveries` rule (zero `operator`, zero `tenant`), in these families:

- `Back to deliveries` on every Full detail state, `Deliveries pagination` on every Activity page, the list heading and `N deliveries` counts, `Deliveries (0)` Gallery headings
- the four health tiles and their `Help for ... deliveries` triggers, `Delayed deliveries` help
- the filter help `Show deliveries with activity during this period.` on every Activity page and Quick view (the most repeated hit)
- the Gallery: nav specimens, the empty specimen `No deliveries`, `orientation_strip — deliveries`
- the Overview tooltip `Deliveries with a recorded event ...` and `N deliveries updated`
- the Preview subtitle (index and show) and the replay modal sentence `update Deliveries` (a site the plan did not list)

The `operator` rule found nothing in the registry because the sites that carry the word (the no-Account card, the denial sentences) are not registry states; they are covered by the extra-states describe and the retired-phrase scan.

## Mutation proofs

Each runs on real source with the named required-lane tests going red, then the source restored from a backup copy (`git diff --stat -- lib` shows only the committed work afterwards). "Words" is `phase182_words_contract_test.exs`.

| # | Mutation | Result |
|---|---|---|
| M1 | nav label back to `Deliveries` | 6 red in Words: Activity identity, the 89-state scan, the empty states, the unresolved links, no Account selected, the Preview return link |
| M2 | `page_title(:deliveries)` back to `mailglass — Deliveries` | 4 red: Activity identity, the scan, empty states, unresolved links |
| M3 | `aria-label="Deliveries pagination"` | 3 red: the scan (attribute), the empty states, the retired-phrase scan |
| M4 | `Back to Deliveries` in `return_context.ex` | 2 red: Preview return link, retired phrases |
| M5 | `mailglass — Operator` as the default title | 3 red: overview title, the scan, no Account selected |
| M6 | one Inbound denial sentence back to `the current operator` | 1 red: retired phrases (a sentence no render reaches) |
| M7 | `scoped operator data` in the tenant selector | 2 red: no Account selected, retired phrases |
| M8 | orphan heading back to `Unmatched events` | 2 red: retired phrases, and the existing Health pin in `operator_live_test.exs` |
| M9a | `hidden` on the visible mailer identity | 2 red: the Full detail mailer test and the detector's teeth |
| M9b | the visible mailer identity not printed (the plan's "identity only inside the tooltip") | 3 red: Full detail mailer, the title-and-wrap test, detector teeth |
| M10 | `title={@text}` on the field_help trigger | 3 red: Full detail mailer, the title-and-wrap test, detector teeth |
| M11 | `String.to_atom/1` round trip in `humanize/1` | 3 red in `mailer_name_test.exs`: the never-raises sweep, the source check, the VM atom count |
| M12 | `label(1)` returns the plural | 2 red: the exact-label test and the support cards |
| M13 | the Tier-1 orphan card condition back to `count > 0` with a nil count | 1 red: the support cards test (a `FunctionClauseError`) |
| M14 | `Phoenix.HTML.raw/1` on the mailer identity | 1 red: the hostile-mailable test (T-182-10) |

M13 is a real defect, not a plan mutation; see Deviation 1.

## Changed pins (D-14)

Only assertions on the retired words moved; assertions on routes, ids and `data-*` values stay exact.

- `operator/shell_test.exs`: nav labels `Health, Activity, Inbound, Preview`, the aria-current checks and every `title="Activity"` input. The two `refute ... Deliveries` checks were moved to `Activity` too: left alone they would pass forever on a word that never renders.
- `operator_live_test.exs`: list heading, the gloss (replaces the subtitle test), empty states and bodies, `7 emails`, `21 emails`, `1 email`, status-region sentences (`2 emails match`, `1 email matches`, `No emails match the current filters`), `Couldn't load activity for these filters`, `Retry loading activity`, `Back to Activity`, `Select an Account to see its activity.`, `they are not failed emails.`, the orphan support card (`~r/\d+ provider reports? matche?s? no email/`), the health row `Provider reports that match no email`, `Oldest provider report: orphan-open`. `refute ... "2 deliveries"` became `"2 emails"` so it still bites.
- `phase177_prohibition_contract_test.exs` (24), `phase177_return_navigation_test.exs` (8), `phase177_account_scope_test.exs` (8): every whole-word `Deliveries` label and `Back to Deliveries` is `Activity`.
- `phase176_prohibition_contract_test.exs`: the P7 empty-copy guard now matches `No activity`, `No emails` and `No messages` (the old `No deliveries` regex would have matched nothing); the error title.
- `voice_test.exs`, `preview_live_test.exs`: the Preview subtitle, the Activity heading and the no-Account sentence.
- `inbound_live_test.exs`: two no-Account sentences (they come from the shared selector, `... its activity.`) and three denial sentences.
- `components_test.exs`: the replay modal sentence. `copy_contract_test.exs`: the four `@status_phrases` entries and their prose (the count stays 22).
- `operator/results_status_test.exs`, `operator/health_overview_test.exs` (`0 emails updated`, the two orphan notices), `preview/return_context_test.exs`, `persona_cohort_test.exs` (not in the plan's list, two pins), `quick_view_projection_test.exs` (`Applies to Health, Activity and Inbound.`).
- `test/support/endpoint_case.ex`: the test adapter's denial message; `test/support/operator_fixtures.ex`: the default fixture mailable.
- Unchanged on purpose: `quick_view_projection_test.exs` keeps `Back to Deliveries` for the retained manifest scenario, because that label is data in `reference/persona_spec/quick_view_scenarios.json`, which the Phase 174 and 175 evidence digests bind (see Deviation 5). `operator_account_authorization_test.exs` (listed by the plan) has only test names and paths with the word, no assertion on screen text.
- Not edited: `brand_v2_compat_policy_test.exs`, `before_catalog_manifest_test.exs`, `stability_contract_test.exs`, `operator_trust_doc_test.exs`, the core and inbound `docs_contract_test.exs`.

## Left for 182-05 (advisory e2e and demo pins)

Word map the e2e specs must follow, exactly as rendered now: nav, h1 and tab `Activity`; gloss `Every email your app sent, one row per delivery.`; `Activity pagination`; counts `N emails`; `No activity in this time window`, `No activity matches the current filters`, `Change or clear a filter to see more.`, `No activity on this page`; `Couldn't load activity for these filters`; button `Retry loading activity`; `Back to Activity`, `Go to Activity`, `Return to Activity ...`; Preview `Back to Activity`; tab titles `mailglass — Activity` and `mailglass — Admin`; tiles `Failed emails` and the other three, `N emails updated`; `Select an Account to see its activity.`; denial `... not authorized for this admin account.`; orphan heading `Provider reports that match no email`, card `N provider reports match no email` with `In the selected Account window.`, `Oldest provider report:`; Mailer row `[data-testid=operator-detail-mailer]` with `<dt>` Mailer (the old `Mailable` row in Technical details is gone) and `[data-testid=operator-delivery-mailer]` on rows; the Gallery specimen `orientation_strip — activity`.

Files that still read the old words (grep at plan end):
- `mailglass_admin/e2e/`: `admin-assets`, `axe-baseline`, `flows`, `judgment`, `operator`, `phase168-plan03-acceptance`, `phase169-journey`, `phase170-journey`, `phase176-filters`, `phase177-account`, `phase177-health`, `phase178-real-zoom`, `structural`, `theme-ownership` (all `.spec.js`) and `support/real-zoom.cjs`.
- `reference/demo_app/assets/e2e/`: `cohort`, `delivery-investigation`, `demo`, `persona-screenshots`, `phase173-evidence`, `phase176-filters`, `quick-views` (all `.spec.js`), and `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs:132` (`Back to Deliveries`, now `Back to Activity`).
- Leave `reference/demo_app/assets/catalog/before-catalog.spec.js` alone: it is the immutable Phase 180 before-catalog capture, not a pin.
- Leave `reference/persona_spec/quick_view_scenarios.json` alone (evidence-digest bound); it still says `Back to Deliveries` and `Unmatched events` as retained data.

## Verification

Plan-end order (D-24), all with the ASDF exports:

| Step | Result |
|---|---|
| admin `mix format --check-formatted` | clean (the package was clean before; `mix format` touched only files this plan owns) |
| admin `mix mailglass_admin.assets.build --check` | "Admin bundle matches a fresh build (138536 bytes)": no Tailwind class changed, so no rebuild and no `superseded.json` rebind (sha256 `fc2df1a7...c1f0` still current) |
| Task 1 verify (contract, copy_contract, shell, components, operator_live, stability, `--warnings-as-errors --seed 0`) | 370 tests, 0 failures |
| Task 2 verify (words, Phase 176 and 177 prohibitions, voice, inbound_live, stability, operator_trust_doc) | 266 tests, 0 failures, 1 excluded |
| Task 3 verify (mailer_name, words, Phase 178 prohibition, copy_contract, scenario_label, operator_live, health_overview) | 309 tests, 0 failures |
| seeds 1 to 6 over `mailer_name_test` and the words contract (atom-count and detector checks) | 40 tests, 0 failures each |
| `bash scripts/check-conformance.sh` | "OK: design-system conformance clean." |
| admin `mix credo --strict` | no finding in a file this plan created; the 7 findings are in files and functions it did not change (for example `assign_delivery_state/5`) |
| root `bash scripts/check_test_exceptions.sh`, root `mix format --check-formatted` | "OK: test exception registry is complete and unexpired."; clean |
| plan-scope diff gate (`git diff 35642978..HEAD` over the stability test, `operator_trust_doc_test`, the core `docs_contract_test`, `mailglass_inbound/test`, `router.ex`, core `lib` and `mailglass_inbound`) | empty |
| admin `mix verify.support_contract.admin` | 1689 tests, 0 failures, 1 excluded, exit 0 |

Core and inbound are untouched, so their suites were not run. No `mix` ran in `reference/demo_app`, so its `mix.lock` is untouched.

## TDD notes

The plan is `type: execute`, so no plan-level gate sequence applies; Task 3 is `tdd="true"` and the plan prescribed one commit, so the RED run was observed and recorded here rather than committed separately.

- **RED:** `mix test test/mailglass_admin/operator/mailer_name_test.exs --seed 0` before any implementation: 15 tests, 14 failures, each `UndefinedFunctionError: function MailglassAdmin.Operator.MailerName.plain_name/1 is undefined (module MailglassAdmin.Operator.MailerName is not available)` (or `identity/1`). The fifteenth test, the control that proves the atom-count instrument sees `String.to_atom/1`, passes by design. Semantic assessment: the targets executed and failed on the planned call to a function that does not exist yet; no syntax, fixture or zero-test fault.
- **GREEN:** `orphan_count.ex`, `mailer_name.ex` and the `ScenarioLabel.humanize/1` binary clause; the same command then ran 15 tests, 0 failures (39 with `scenario_label_test.exs`).
- **REFACTOR:** none needed. The control test's `for` was bound to `_atoms` after `--warnings-as-errors` aborted the first full run on an ignored-result warning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A nil orphan count drew the Tier-1 card and would have crashed**
- **Found during:** Task 3 (the words test planted a nil count)
- **Issue:** the card was gated by `orphan_backlog.count > 0`, and in Elixir `nil > 0` is `true` (an atom sorts above any number). `count: nil` is the real "read failed" value (`operator_live.ex` builds it when the orphan read fails), so the card drew with an empty number before; with `OrphanCount.label(nil)` it raised `FunctionClauseError` inside the LiveView.
- **Fix:** the card is gated by `(summary_count(@support_summary, :orphan_backlog) || 0) > 0`; the unavailable row already says so. Mutation M13 proves it.
- **Files:** `support_cards.ex`. **Commit:** `87435e49`
- **Not fixed (out of scope):** the Failed webhook attempts card has the same `count > 0` gate (`support_cards.ex:149`) and draws an empty card on a nil count; logged in `deferred-items.md`.

**2. [Rule 3 - Blocking] The test endpoint has no body parser, so a dead render sees no params**
- **Found during:** Task 1 (the `<title>` check read the overview title for the Activity URL)
- **Fix:** the contract reads dead renders with `get(conn, path, params)`; a real adopter endpoint (with `Plug.Parsers`) carries the query string. Documented where `dead_get/2` is defined.
- **Files:** the words contract. **Commit:** `2c38e690`

**3. [Rule 2 - Missing critical] Sites the plan did not list, found by the scan**
- **Found during:** Task 1 inventory and Task 2
- **Issue:** the replay modal sentence `update Deliveries` (now `update delivery records`), the `Retry deliveries` control (now `Retry loading activity`), the Gallery specimen state `orientation_strip — deliveries` (now `activity`), the Inbound moduledoc `current operator context` (the plan's acceptance grep counts it), `persona_cohort_test.exs` (two pins).
- **Files:** `replay_modal.ex`, `deliveries_list.ex`, `gallery_live.ex`, `inbound_live.ex`, `persona_cohort_test.exs`. **Commits:** `145b7089`, `abefd911`

**4. [Rule 1 - Bug in plan] The Mailer trigger label**
- **Issue:** the plan text gave `field_help` the label "Mailer" while the visible text is the plain name, which breaks WCAG 2.5.3 (the accessible name must contain the visible text).
- **Fix:** the label is the plain name; the `<dt>` supplies "Mailer". **Commit:** `87435e49`

**5. [Rule 1 - Bug in plan] One pin could not move**
- **Issue:** the plan listed `quick_view_projection_test.exs` ~593 as a `Back to Deliveries` pin to move. It asserts a label read from `reference/persona_spec/quick_view_scenarios.json`, which `scripts/check_phase174_evidence.cjs` and `check_phase175_evidence.cjs` bind by digest. Editing the JSON would break those evidence checks.
- **Fix:** the pin stays, with a comment saying where the production label is pinned. **Commit:** `abefd911`

**6. [Rule 3 - Blocking] A fixture used a retired word**
- **Issue:** the default fixture mailable `Mailglass.Example.OperatorMailer` read "Operator mailer" in the new list rows, which the words scan correctly flagged as a screen word.
- **Fix:** it is `BrowserMailer`, like the neighbouring fixtures. Fixture data may not use the retired words (written into the contract's moduledoc). **Commit:** `87435e49`

Smaller adjustments: `ScreenRegistry.states/1` returns maps, not `{label, path}` (as 182-03 built it), so the contract reads `state.path`, `state.mount`, `state.hooks` and `state.expect`; `endpoint_case.ex` and `app.css` handling follow the plan (the bundle needed no rebuild, so `app.css` and `superseded.json` are untouched although the plan listed them); the filtered empty state's body is `Change or clear a filter to see more.` (the title carries the sentence, so a repeated body would be noise); the support card says `Oldest provider report:` where it said `Oldest unmatched Event example:`; the reconciliation fact label is `Provider reports still matching no email`.

**Total deviations:** 6 (3 bugs including one in the plan text and one in a pre-existing gate, 2 missing-critical or blocking sites, 1 blocking fixture). **Impact on plan:** none on scope; every plan truth holds.

## Issues Encountered

- `Phase164RepositoryTruthTest` ("git runtime rules do not conceal the retired finalize-phase extension paths") still fails in a root core run because of the untracked `.gsd/.gitignore` (logged by 182-01). This plan did not touch or run core.
- The first full admin run aborted on an ignored-result compile warning in `mailer_name_test.exs` (`for ... do: String.to_atom(value)`), fixed by binding the result.

## Known Stubs

None. `OrphanCount` and `MailerName` are real derivations over real data; the words contract's `report_inventory/1` only prints when `PHASE182_REPORT` is set.

## Threat Flags

None beyond the plan's threat model. T-182-09: `MailerName` works on binaries (`String.split/2`, `Macro.underscore/1`, one regex), and the contract asserts the VM atom count moves by no more than 8 across 1000 random inputs while a control that does create atoms moves it by at least 150 (M11 turns it red). T-182-10: the identity is rendered by HEEx autoescape only; a planted `<img onerror>` and `<script>` stay text (M14 turns it red). T-182-11: no route, `deliveries_path`, `data-testid`, `surface_nav` key or module was renamed; `stability_contract_test.exs` and the other three contract files are unedited and pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 182-05 has the exact word map and the file lists above; it should run the specs it edits (and `axe-baseline.spec.js` once, in 182-06).
- 182-06 captures the after-catalog last; the bundle and root layout are unchanged by this plan (sha256 `fc2df1a788e0089beb3c9778582917e0b5cbe10d231795ea05f23e757fadc1f0`).
- BRADM-03, BRADM-04 and BRADM-05 are copied above verbatim from the plan; whether the shared-ID gate lets them be marked complete depends on the 182-05 plan (see the state update).

## Self-Check: PASSED

All created files exist (`orphan_count.ex`, `mailer_name.ex`, `phase182_words_contract_test.exs`, `mailer_name_test.exs`); `def label` is in `orphan_count.ex` and `def plain_name` in `mailer_name.ex`; all five commits (`2c38e690`, `145b7089`, `abefd911`, `87435e49`, `f99a6963`) are ancestors of HEAD; no uncommitted `lib` or `priv` change; `mix format --check-formatted` is clean in the admin package and at the root.

---
*Phase: 182-admin-words-and-layout-one-job-first*
*Completed: 2026-11-15*
