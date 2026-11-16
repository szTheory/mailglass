---
phase: 182-admin-words-and-layout-one-job-first
fixed_at: 2026-11-16T04:00:00Z
review_path: /Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 182: Code Review Fix Report

**Fixed at:** 2026-11-16T04:00:00Z
**Source review:** /Users/jon/projects/mailglass/.planning/phases/182-admin-words-and-layout-one-job-first/182-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 2 (WR-01, WR-02; `fix_scope: critical_warning`)
- Fixed: 2
- Skipped: 0
- Both fixes are logic changes (a copy claim and a link-destination condition), so both are marked `fixed: requires human verification`.

**Where verification ran:** the main checkout. `workflow.use_worktrees` is `false` in `.planning/config.json`, so no worktree, temp branch or recovery sentinel was created and there was no cleanup tail. The numbers below are reproducible from the tree as it stands.

**Verification (all in `/Users/jon/projects/mailglass/mailglass_admin`, toolchain exported as `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`):**
- `mix format --check-formatted`: clean
- `mix compile --warnings-as-errors --force`: clean (exit 0)
- `mix verify.support_contract.admin`: 1787 tests, 0 failures, 1 excluded (iteration 1 left 1778; this iteration adds 9: 4 for WR-01 and 5 for WR-02; the 1 excluded is the pre-existing `:skip`, none added)
- `mix mailglass_admin.assets.build --check`: "Admin bundle matches a fresh build (138536 bytes)". `priv/static/app.css` was not rebuilt and no Tailwind class was added.
- `after_catalog_manifest_test`, `before_catalog_manifest_test`: 109 tests, 0 failures (the committed after-catalog binding is intact). `root_theme_ownership_contract_test`: 22 tests, 0 failures.
- Scoped before the full lane: `phase182_cause_contract_test`, `phase182_review_words_test`, `copy_contract_test` (72 tests) and `phase182_journey_test`, `health_population_test`, `operator_live_test`, `phase177_*` (341 tests), all `--seed 0`, 0 failures.
- `scripts/check_test_exceptions.sh`: OK.
- No core `lib/` file was touched, so the core-only gates were not needed. No evidence-bound file was edited (`reference/persona_spec/quick_view_scenarios.json`, the demo catalog spec, `.planning/research/brand-v2-adoption/`, `.planning/release-target.json`). The pre-existing dirty `.planning/config.json` was never staged.

Every fix was proven red before it was made green: the new tests failed on the unfixed code for the stated reason (4 of 4 for WR-01, 4 of 5 for WR-02; the fifth WR-02 test is the baseline for "the other cards stay exact" and is meant to pass before and after), then passed after the fix.

## Fixed Issues

### WR-01: A provider-reported `:failed` event still gets the send-time cause in the Full detail timeline

**Files modified:** `mailglass_admin/lib/mailglass_admin/components.ex`, `mailglass_admin/test/mailglass_admin/phase182_cause_contract_test.exs`
**Commit:** 17b02830
**Status:** fixed: requires human verification (a wording claim changed; tests prove where each sentence appears, a human should confirm the wording)
**Applied fix:** `outcome_help(:delivery, :failed)` is keyed on the event type alone, so it cannot tell a send-time `:failed` event from a provider-reported one. It now reads "The email did not get through: sending failed, or the provider reported a failure." (the reviewer's suggested sentence, which matches the neutral wording iteration 1 gave the Health "Failed emails" help and the locked D-01/D-02 family "the email did not get through"). The send-time sentence "Sending failed before a successful handoff to the provider." now appears only in the verdict, where `send_failure_or_fallback/1` reads the row status. The comment above the clause was rewritten to say why the help must stay context-free.
**Reach:** the same clause feeds the Full detail timeline help and the `:failed` status tooltip (`outcome_badge`), so both are neutral now. No other file pinned the old sentence: the only other hit, `reference/persona_spec/quick_view_scenarios.json`, is a Health card projection that `outcome_help` does not feed, and it was not touched.
**Regression tests (all four fail on unfixed code):** the real `Timeline` rendered for a `:failed` event shows the neutral sentence and not the handoff sentence; the `:failed` status tooltip in the delivery context shows the neutral sentence; a real Full detail read of a `status: :sent` delivery with a provider `:failed` event (nil reason) shows the fallback in the verdict and the neutral sentence in the timeline, and the handoff sentence nowhere on the screen; a send-time failure (`status: :failed`) still reads the handoff sentence in the verdict and not in the timeline. The timeline and verdict are read through named selectors that fail loudly when the element is absent, so a screen that stops rendering them cannot pass.

### WR-02: Health "Delayed emails" count no longer matches the list its link opens

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs`
**Commit:** 4417b105
**Status:** fixed: requires human verification (a link-condition change; see "Limit of this fix" below)
**Applied fix:** in `health_issues/7`, a card's link carries the Activity event filter only when it opens exactly the emails the card counts. The old condition (every counted group has that latest event) is kept, and a second condition is added: no other group with that latest event is counted by another card or by none (`health_delivery_card(group) != event`). When either fails the link opens the unfiltered list. This is the reviewer's "widened?" form, applied to all four cards; for Failed, Bounced and Rejected it is a no-op by construction (every email whose latest event is `:failed`, `:bounced` or `:rejected` is class Failed and counts under the card of that same event), so their links are unchanged.
**Regression tests (journey file, `Health card links open the list the card counts (WR-02)`):**
- Each card's link opens exactly the emails the card counts: Failed 1, Bounced 2, Rejected 3, Delayed 4 (distinct counts so a link to another card's list cannot pass). Each link carries `event=<card>` and the Activity screen it opens lists exactly that many rows. This is the "other cards keep count-to-landing-list parity" proof; it passes before and after the fix.
- A confirmed delivery, a durable bounce, and a suppression, each followed by a later deferral, seeded next to one normal Delayed email: the card counts 1, the event filter alone would open 2 (asserted, so the widening is shown to be real), and the Delayed link now carries no `event=deferred`. On the screen it opens, the normal email reads "Delayed" and the other email is listed under its own word. These three fail on unfixed code.
- A widened Delayed card does not disturb another card: with two Failed emails, the Failed link still carries `event=failed` and opens exactly 2 rows. Fails on unfixed code through the Delayed assertion.
- Mutation: forcing the filter off for every card turns three tests red (the exact-parity test, the widened-neighbour test, and the pre-existing "provider-reported failure is a Failed email on Health" test); restored afterwards.

**Limit of this fix (flag for the owner):** the instruction asked for the Delayed link to return exactly the rows the card counts in the confirmed-then-deferred case. That is not reachable here. The Activity screen can filter only by latest recorded event, provider, search and window; none of them separates a confirmed-then-deferred email from a normal deferred one (their `status` is the same, `:sent`). Isolating the counted rows needs a filter by delivery class in core's `Mailglass.Operator.Deliveries`, which locked decision D-07 explicitly defers ("A server-side filter is a later core change (deferred)"), so it was not added. What the fix guarantees instead: when the event filter would open uncounted emails, the link no longer pretends to be the Delayed list (no `event=deferred` filter chip over a list that includes a Delivered email); every counted email is on the list it opens and reads its own class word; and in every case where the filter is exact, count equals the list total. The trade-off is that in the widened case the unfiltered list is much wider than the narrower event-filtered one, which is the same fallback the Bounced card already uses for a bounce followed by an open. If the owner prefers the narrower event-filtered list as the lesser mismatch, the change is one condition in `exact_filter?`, and the widened tests would then assert the filtered list instead.

## Skipped Issues

None.

---

_Fixed: 2026-11-16T04:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
