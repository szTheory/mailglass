---
phase: 182-admin-words-and-layout-one-job-first
fixed_at: 2026-11-16T03:10:00Z
review_path: /Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 5
skipped: 1
status: partial
---

# Phase 182: Code Review Fix Report

**Fixed at:** 2026-11-16T03:10:00Z
**Source review:** /Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (CR-01, WR-01..WR-05; `fix_scope: critical_warning`)
- Fixed: 5
- Skipped: 1 (WR-05, conflicts with a plan-mandated guard)
- Out of scope, untouched: WR-06 (necessity finding, excluded by `critical_warning`) and IN-01..IN-09

**Where verification ran:** the main checkout. `workflow.use_worktrees` is `false` in `.planning/config.json`, so no worktree, temp branch or recovery sentinel was created and there was no cleanup tail. The numbers below are reproducible from the tree as it stands.

**Verification (all in `/Users/jon/projects/mailglass/mailglass_admin`, toolchain exported as `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`):**
- `mix format --check-formatted`: clean
- `mix compile --warnings-as-errors`: clean
- `mix verify.support_contract.admin`: 1778 tests, 0 failures, 1 excluded (baseline was 1756; this run adds 22 tests; the 1 excluded is a pre-existing `:skip`, none added here)
- `mix mailglass_admin.assets.build --check`: "Admin bundle matches a fresh build (138536 bytes)". `priv/static/app.css` was not rebuilt or touched, and no new Tailwind class was introduced.
- `after_catalog_manifest_test`, `before_catalog_manifest_test`, `root_theme_ownership_test`: 109 tests, 0 failures. The committed after-catalog binding is intact.
- `scripts/check_test_exceptions.sh`: OK.
- No core `lib/` file was touched, so the core-only gates (`mix credo --strict`, `mix test test/mailglass/operator`) were not needed.

Every fix was proven red before it was made green: the new test failed on the unfixed code for the stated reason, then passed after the fix.

## Fixed Issues

### CR-01: Provider-reported `:failed` events are given the invented cause "Sending failed before a successful handoff to the provider."

**Files modified:** `mailglass_admin/lib/mailglass_admin/copy.ex`, `mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs`
**Commit:** a7f843a2
**Status:** fixed: requires human verification (a wrong-condition logic fix; tests prove it, a human should confirm the intent)
**Applied fix:** `event_cause/1` became `event_cause/2` and takes the row. A `:failed` event with a nil `reject_reason` now reads the handoff sentence only when the row's `status` is `:failed` (the send-time path, via the existing `send_failure_or_fallback/1`); any other row reads "No reason was recorded for this email." A provider reason is unchanged.
**Regression test (fails on unfixed code):** a `:sent` row with a provider-sourced `:failed` event and no reason must read the fallback, and its Full detail must not contain the handoff sentence. Companion tests pin the send-time row (still the handoff sentence, with and without a `:failed` event), a provider reason on a `:sent` row, and an empty loaded timeline. The existing matrix cell `{:event, :failed, nil}` (a `status: :failed` row) still passes unchanged.

### WR-01: Health overview delivery counts still use the pre-phase atom rule

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs`
**Commit:** 8eeae107
**Status:** fixed: requires human verification (bucketing rule; tests prove parity, a human should confirm the card mapping)
**Applied fix:** `health_issues/7` now decides membership with `StatusMap.delivery_class/1`, the rule the Activity summary and row marks use (D-05, D-07). The class decides whether a group is a problem; the card only names how it failed: the latest failure event (`:bounced`, `:rejected`, `:failed`), else a durable `bounced_at` reads Bounced, else Failed; the `:delayed` class is the Delayed card. A bounce followed by an open now counts under Bounced, a provider-reported `:failed` on a handed-off row counts under Failed (before, it counted nowhere), and a confirmed delivery followed by a deferral no longer counts as Delayed. Card testids, the card set, and the "event filter only when every matching group's latest event is that event" fallback are unchanged, so `health_population_test`, `phase177_prohibition_contract_test` and the pinned `operator_live_test` Health tests pass unedited.
**One consequential copy change (flag for review):** the Failed card help no longer reads "Sending failed before a successful handoff to the provider." (false for the provider-reported failures it now includes, the same shape as CR-01). It now reads "These emails did not get through: sending failed, or the provider reported a failure." No test or e2e pinned the old help text.
**Regression tests (journey file):** a per-row parity check over every `@bucket_rows` entry (Health card total equals the Activity Needs attention count minus the Not sent rows, since Health has no Not sent card), plus three tests for the disagreeing shapes. Three of them fail on the unfixed code. Mutation: removing the durable-bounce branch from `health_failure_card/1` turns the bounce-then-open test red (restored afterwards).

### WR-02: "Not sent" verdict treats "no matching suppression entry" as "an entry that recorded no reason"

**Files modified:** `mailglass_admin/lib/mailglass_admin/copy.ex`, `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`, `mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs`
**Commit:** 03222998
**Status:** fixed: requires human verification (state handling and copy; a human should confirm the wording)
**Applied fix:** `DetailHeader.suppression_evidence/2` returns a distinct `:no_entry` for "read ok, nothing matches". `Copy` gives that evidence its own Not sent verdict: the recorded fact in the past tense ("This address was on your suppression list when this was recorded."), the note "No current suppression entry matches this address.", a next step with no removal ("Trigger the email from your app again if it should be sent."), and no card link. It never shows the no-reason fallback.
**Locked decisions respected:** D-02 and D-19 are about a nil *reason*. An entry that exists with a nil reason still reads the fixed fallback and the removal next step, exactly as before (the D-19 matrix cell `{:suppression, nil}` is unchanged and a test pins it). Only the absent-entry case, which D-02 does not describe, takes the new wording.
**Regression tests (fail on unfixed code, 4 of 5):** the verdict and rendered Full detail for no entry and for an empty map; agreement with the suppression card's "No current Mailglass match"; the nil-reason entry still reading the fallback; and a real LiveView read of a suppressed delivery with no entry (confirmed on the unfixed code: "No reason was recorded for this email." above "No current Mailglass match"). `%{suppression: :no_entry}` was added to the verdict-string enumeration so the new copy is tone and retry scanned.

### WR-03: A persisted `"nil"` mailable is shown as the mailer name "Nil"

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/mailer_name.ex`, `mailglass_admin/test/mailglass_admin/operator/mailer_name_test.exs`, `mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs`
**Commit:** 7276280e
**Applied fix:** `MailerName.identity/1` returns nil for the exact text `inspect(nil)` produces (`"nil"`, after trimming), so `plain_name/1` and both renderers (Activity row, Full detail Mailer cell) drop the line together. A module really called `Nil` inspects as "Nil" and still reads as a name; the match is exact and lower-case only.
**Regression tests (3 fail on unfixed code):** the unit test (`"nil"`, padded `"nil"`, plus the legitimate `Nil`, `MyApp.Nil`, `MyApp.NilMailer`), the Full detail test and the Activity list test, each now carrying a persisted-nil mailable.

### WR-04: Retired word "unmatched" is still on screen in the support drilldown banner

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`, `mailglass_admin/test/mailglass_admin/phase182_words_contract_test.exs`
**Commit:** 2bf8f496
**Applied fix:** the `%{focus: :orphan_backlog}` banner with no event id now reads "Showing provider reports that match no email" (the locked D-12 / 182-04 `OrphanCount` wording family), and the moduledoc line was reworded to match.
**Why the existing scan missed it:** the retired-phrase list was case-sensitive and held only "Unmatched webhook evidence". It now also lists "unmatched webhook".
**Regression tests (both fail on unfixed code):** the source scan (now flags the banner string and the moduledoc line) and a render test that draws the banner for every focus state and refuses "unmatched" or "orphan" in any of them, with a floor that every state draws a banner, plus an exact-text pin for the orphan focus.

## Skipped Issues

### WR-05: Compile-time `raise` over a core enum can break an adopter's build

**File:** `mailglass_admin/lib/mailglass_admin/copy.ex:255-263`
**Reason:** skipped: conflicts with a locked, plan-mandated decision. Plan 182-02 requires "A compile-time check in Copy raises if the sentence maps' keys differ from the enum accessors (adding an enum value breaks the build, not the screen)" (182-02-PLAN.md truths, line 332). It implements CONTEXT D-04 (cause text is structural, generated over the core enums), and mutation M11 in 182-02-SUMMARY.md records the delete-an-entry mutation going red as a compile error. Replacing the raise would change a recorded, mutation-proven guarantee, which is a decision for the owner, not a review fix.
**Original issue:** the module-body check raises `ArgumentError` in an adopter's compile if a newer core (still allowed by admin's `{:mailglass, "~> 2.0"}`) adds a reject reason. The runtime `@unrecognized_reason` fallback already covers the screen.
**Option for the owner (not applied):** keep the guard but make it `IO.warn/2` instead of `raise`. The admin lane compiles with `--warnings-as-errors`, so this repo's CI would still go red on a new reason (preserving the "breaks the build, not the screen" intent), while an adopter resolving a newer core gets a warning rather than a failed compile. That also needs M11 re-recorded as a warning-as-error. A related release-side option, already in CONTEXT's deferred list, is tightening admin's published core pin to `~> 2.8`.

## Not Attempted (out of scope)

### WR-06: Fixed "no reason" text for a suppression entry that cannot exist without a reason

**File:** `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:135-141`
**Reason:** necessity finding; `critical_warning` excludes necessity findings (removing code is a scope decision for the human, #4100), so no edit was applied. It also did not fall out of WR-02: the nil-reason branch in `reason_value/1` is still exercised by the D-19 matrix cell `{:suppression, nil}` (an entry with a nil reason shows the fixed fallback on the card), so removing it would break a locked contract test. WR-02 removed the only real path that reached the verdict's no-reason wording for an absent entry, which weakens the case for the dead branch but does not delete it. Left in REVIEW.md for the owner.

---

_Fixed: 2026-11-16T03:10:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
