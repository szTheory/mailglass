---
slug: inbound-replay-flash-copy
status: awaiting_human_verify
trigger: "MailglassAdmin.InboundLiveTest replay flash copy fails on main at inbound_live_test.exs:913 and :1411"
created: 2026-09-16
updated: 2026-09-16
---

# Debug Session: inbound-replay-flash-copy

## Symptoms

**Expected behavior:**
After clicking `confirm_replay` on a matched InboundMessage in the operator detail
view, the rendered LiveView HTML contains the verbatim success flash copy:
`"Replay recorded. A new replay run was appended to this InboundMessage's timeline."`

**Actual behavior:**
The re-rendered HTML does not contain that string. The assertion `unescape(html) =~ <copy>`
fails; the returned `left:` value is the full operator-shell HTML (topbar, logo SVG,
theme fieldset, …) with no flash region carrying the replay copy.

**Error messages:**
```
1) test replay confirm flow (IADM-03) confirming replay on a matched record
   appends a :replay ExecutionRun (V2) (MailglassAdmin.InboundLiveTest)
   test/mailglass_admin/inbound_live_test.exs:913
   Assertion with =~ failed
   code:  assert unescape(html) =~
            "Replay recorded. A new replay run was appended to this InboundMessage's timeline."
   stacktrace: test/mailglass_admin/inbound_live_test.exs:933

2) test brand-voice + PII sweep (IADM-06, V10/V5) replay success, mailbox-missing
   block, and not-authorized block carry verbatim copy (V10)
   test/mailglass_admin/inbound_live_test.exs:1411
   Assertion with =~ failed  (same expected string)
   stacktrace: test/mailglass_admin/inbound_live_test.exs:1422
```

Both failures are the SAME assertion on the SAME flash copy string, reached via
two different call paths:
- :913 — `element("button[phx-click='open_replay']") |> render_click()` then
  `element("button[phx-click='confirm_replay']") |> render_click()`
- :1411 — `render_click(view1, "confirm_replay", %{})` directly (no `open_replay` first)

The fact that BOTH the open-then-confirm path and the direct-event path fail
identically suggests the flash is not rendering (or not surviving the re-render),
rather than a modal/open-state sequencing issue.

**Timeline:**
Pre-existing red on `main`. Recorded in project memory as "2 undiagnosed
InboundLiveTest replay-copy reds on main (likely PR #129)". PR #129 (operator
detail-view clarity) touched the replay button copy: "replay button de-reddened +
plain copy + honest replayable seeds". Strong prior that the copy string or the
flash mechanism drifted there.

**Reproduction (deterministic, confirmed by orchestrator):**
```
cd mailglass_admin
export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27
MIX_ENV=test mix test test/mailglass_admin/inbound_live_test.exs --seed 0
# => 68 tests, 2 failures  (reproduces every run, not a flake)
```

## Current Focus

reasoning_checkpoint:
  hypothesis: "`confirm_replay` never reaches its success branch. `MailglassInbound.Internal.Replay.replay/2` returns `{:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}` because the admin test fixture seeds evidence WITHOUT the durable route binding (`verification_facts[\"mailglass_execution_route\"]`) that commit 61e8c8e8 (#203, v2.6 ratchet) made the sole source of a replay mailbox. The handler therefore puts the ERROR flash `Replay blocked: mailbox module not found.` instead of the asserted success copy."
  confirming_evidence:
    - "Direct observation (scratch LiveView test, confirm_replay on a seed_matched! record): the ONLY role=\"alert\" region in the re-rendered HTML is `border-error` carrying `Replay blocked: mailbox module not found.` The flash region renders fine; the copy is the error branch."
    - "The asserted success string EXISTS verbatim in lib/mailglass_admin/inbound_live.ex:409 — so this is NOT copy drift from PR #129."
    - "`Internal.Replay.resolve_mailbox/4` routes through `Execution.route_from_evidence/1`; `Execution.route_binding/1` reads `verification_facts[\"mailglass_execution_route\"]` and returns `{:error, :missing_binding}` for `%{}`. The fallback `legacy_replay_mailbox_error/3` then DELIBERATELY refuses to resolve a persisted mailbox string (`# Pre-binding rows cannot safely resolve a persisted module name`) -> `:invalid_mailbox`."
    - "mailglass_admin/test/support/inbound_fixtures.ex seeds `verification_facts: %{}` by default and has not been touched since phase 48 (last commit f4dc7a74); the ratchet commit 61e8c8e8 that introduced route binding includes `test(inbound): seed durable replay route binding` — it updated mailglass_inbound's OWN fixtures (worker_test.exs / async_execution_test.exs `route_binding/0`) and missed the sibling admin fixture."
    - "`MyApp.Mailboxes.SupportMailbox` exists in test/support/inbound_test_router.ex with the comment `Replay resolves the stored mailbox string back to a loaded module` — an artifact of the pre-#203 contract, confirming the fixture was written against the legacy resolution path."
  falsification_test: "Seed `verification_facts` with `%{\"mailglass_execution_route\" => %{\"status\" => \"matched\", \"mailbox\" => \"Elixir.MyApp.Mailboxes.SupportMailbox\"}}` in seed_matched!. If the hypothesis is wrong, the success flash still will not appear."
  fix_rationale: "The production code is correct and intentionally hardened (#203 removed unsafe string->module resolution). The stale artifact is the admin test fixture, which models a pre-binding evidence row that can no longer exist for a freshly-matched message. Seeding the durable binding restores fixture fidelity with production evidence rows — it does not weaken any assertion or copy."
  blind_spots: "verification_facts render verbatim in EvidenceCard, so the new key becomes visible UI text — must re-run the whole file (brand-voice sweep + evidence-card assertions). `discover_bound_mailbox/1` scans `:code.all_loaded()`, so the mailbox module must be loaded at replay time."
  candidate_causes:
    - "code (mailglass_inbound): route-binding contract change in 61e8c8e8 removed legacy mailbox-string resolution"
    - "data (test fixture): admin InboundFixtures evidence rows carry no route binding"
    - "code (mailglass_admin copy): ruled out — string matches verbatim at inbound_live.ex:409"
  and_gate: "yes — BOTH conditions are required. The contract change alone is harmless for real evidence rows (ingress writes the binding); the fixture alone was fine pre-#203. The failure needs the new contract AND the un-migrated fixture simultaneously. This is a cross-package fixture-drift bug, not a single-cause defect."

next_action: fix applied and verified (68 tests, 0 failures at seeds 0 and 12345). Awaiting maintainer confirmation, then commit + archive + knowledge-base entry.

## Evidence

- timestamp: 2026-09-16
  observation: Failure reproduces deterministically at seed 0 on clean `main`
    (only `.planning/config.json` dirty). 68 tests, exactly 2 failures, both the
    same replay-success-copy assertion.

- timestamp: 2026-09-16
  checked: Scratch LiveView test firing `confirm_replay` on a `seed_matched!` record, scanning the re-rendered HTML for every `role="alert"` region.
  found: The single alert region is `border-error` carrying `Replay blocked: mailbox module not found.`
  implication: The flash MECHANISM works. The handler takes the `{:error, reason}` branch, not the success branch. Not a render/copy-drift bug.

- timestamp: 2026-09-16
  checked: `MailglassInbound.Internal.Replay.resolve_mailbox/4` -> `Execution.route_from_evidence/1` -> `Execution.route_binding/1`.
  found: The mailbox is resolved ONLY from `evidence.verification_facts["mailglass_execution_route"]`. With `%{}` it returns `{:error, :missing_binding}`, and `legacy_replay_mailbox_error/3` then deliberately refuses to resolve the persisted mailbox string ("Pre-binding rows cannot safely resolve a persisted module name") -> `{:replay_mailbox_missing, %{reason: :invalid_mailbox}}` -> `replay_error_copy/1` -> "Replay blocked: mailbox module not found."
  implication: The admin fixture models an evidence row that can no longer replay.

- timestamp: 2026-09-16
  checked: `git log -S "route_binding" -- mailglass_inbound/lib` and `git log -- mailglass_admin/test/support/inbound_fixtures.ex`.
  found: Route binding was introduced by 61e8c8e8 (#203, v2.6 engineering quality ratchet, 2026-08-19), whose changelog includes "test(inbound): seed durable replay route binding" — it migrated mailglass_inbound's OWN fixtures only. The admin fixture is untouched since f4dc7a74 (phase 48-03).
  implication: Culprit is #203, NOT PR #129. Cross-package fixture drift: a sibling-package test fixture was left behind by a same-commit contract change.

- timestamp: 2026-09-16
  observation: The `left:` HTML in both failures is the full operator shell and is
    truncated by ExUnit, so absence of the string is proven by the assertion itself,
    not by reading the truncated dump. Other verbatim-copy assertions in the same
    file (e.g. the not-loaded banner at :1391, the no-execution-runs copy at :1409)
    PASS — so `refute_banned/1` and the general copy-assertion machinery work.

## Eliminated

- hypothesis: "PR #129 drifted the success-flash copy string in the handler/template"
  evidence: "`grep` finds the asserted string verbatim at lib/mailglass_admin/inbound_live.ex:409; git log -S on the test file shows the copy is unchanged since 48-03 (decb6d55/96110d47)."
  timestamp: 2026-09-16

- hypothesis: "The flash container was removed from the operator shell during the detail redesign"
  evidence: "Operator.Shell renders `<.flash_region flash={@flash} />` (shell.ex:213) and InboundLive passes `flash={@flash}` (inbound_live.ex:494). The scratch diag proves an ERROR flash DOES render from this exact event."
  timestamp: 2026-09-16

- hypothesis: "Modal open-state sequencing (open_replay not fired on the :1411 path)"
  evidence: "Both paths reach the handler and produce the same error flash; confirm_replay does not gate on :replay_modal_open?."
  timestamp: 2026-09-16

## Resolution

root_cause: "Cross-package fixture drift (AND-gated, two contributing causes): (1) commit 61e8c8e8 (#203, v2.6 engineering ratchet) made `verification_facts[\"mailglass_execution_route\"]` the SOLE source of a replay mailbox and made the legacy path deliberately refuse to resolve a persisted mailbox string; (2) `MailglassAdmin.TestSupport.InboundFixtures` was never migrated and still seeds `verification_facts: %{}`. Together, `Internal.Replay.replay/2` returns `{:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}`, so `confirm_replay` takes its error branch and flashes \"Replay blocked: mailbox module not found.\" instead of the asserted success copy."
fix: "Seeded the durable route binding in `MailglassAdmin.TestSupport.InboundFixtures`. `insert_evidence!/3` gained a `:route_binding` option (`{:matched, module}` | `:no_match` | omitted = legacy pre-binding row) that merges `verification_facts[\"mailglass_execution_route\"]` in the exact shape `MailglassInbound.Execution.route_binding/1` reads back, and `Code.ensure_loaded!/1`s the mailbox so `discover_bound_mailbox/1`'s `:code.all_loaded()` scan can find it. `seed_matched!/2` now seeds `{:matched, MyApp.Mailboxes.SupportMailbox}`; `seed_no_match!/2` seeds `:no_match` (so V11 blocks for the RIGHT reason — `:no_prior_match` — rather than incidentally via the legacy fallback). The hardcoded mailbox strings collapsed onto a single `@fixture_mailbox` constant so the binding and the ExecutionRun.mailbox column can never drift apart again. NO production code and NO assertion or copy was changed."
oracle_type: specified (verbatim UI-SPEC copy contract, V10/IADM-03)
verification:
  - signal: original reproduction
    result: pass — 68 tests / 0 failures at `--seed 0` (was 68/2, deterministic)
  - signal: seed independence
    result: pass — 68/0 at `--seed 12345`
  - signal: mutation at the fix site
    result: pass — flipping `seed_matched!`'s binding to `:no_match` resurrects EXACTLY the two original failures (:913 and :1411). The regression assertions bite.
  - signal: revert test
    result: pass — the pre-fix tree reproduces both failures deterministically (baseline).
  - signal: regression scope
    result: pass — `InboundFixtures` has exactly one consumer (`inbound_live_test.exs`, plus `inbound_test_router.ex` referencing it in a comment); the whole file is green. `mix format --check-formatted` clean; `mix credo --strict` surfaces only the pre-existing `token_parity_test.exs:111` refactor note.
  - signal: diff shape
    result: pass — single test-support file, additive; no deletion-only "fix", no assertion weakened.
guardrail_verdict: accepted
why_not_caught: "No CI gate ran this file. `verify.support_contract.admin` (mailglass_admin/mix.exs) is an explicit ALLOW-LIST of admin test files and `inbound_live_test.exs` was not on it; no other ci.yml lane runs `mix test` inside mailglass_admin/. #203 could therefore land a cross-package contract change that broke an admin test with a fully green PR, and main stayed red undetected for ~4 weeks."
recurrence_guard: "Added `test/mailglass_admin/inbound_live_test.exs` to the `verify.support_contract.admin` allow-list (mailglass_admin/mix.exs) — the lane that gates every PR touching code. Verified green: 184 tests / 0 failures with `--warnings-as-errors`. The 68 tests in that file (incl. the two replay-copy assertions) are now merge-blocking, so the next durable-contract change cannot silently orphan the admin fixtures. Secondary guard: the fixture mailbox identity collapsed onto a single `@fixture_mailbox` constant so the route binding and the ExecutionRun.mailbox column cannot drift apart."
files_changed:
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/mix.exs
