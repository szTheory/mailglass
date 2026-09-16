---
slug: inbound-replay-flash-copy
status: resolved
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

root_cause: |
  AND-gated cross-package fixture drift. (1) Commit 61e8c8e8 (#203, v2.6 ratchet)
  made verification_facts["mailglass_execution_route"] the sole source of a replay
  mailbox and deliberately closed legacy mailbox-string resolution. (2) mailglass_admin's
  InboundFixtures still seeded verification_facts: %{}, because #203 migrated
  mailglass_inbound's own fixtures and missed the admin sibling. confirm_replay
  therefore took the error branch. NOT copy drift and NOT PR #129 -- the asserted
  success string is verbatim at inbound_live.ex:409, and no production code is at fault.

fix: |
  Test-support only. insert_evidence!/3 gained a :route_binding option merging the
  binding in the exact shape Execution.route_binding/1 reads back -- mirroring what
  Ingress.Persist writes on every real evidence row. seed_matched!/2 seeds {:matched, _};
  seed_no_match!/2 seeds :no_match so the V11 block fires for the right reason
  (:no_prior_match). Mailbox collapsed onto one constant. No copy changed, no assertion
  weakened, refute_banned/1 sweep intact.

verification: |
  inbound_live_test.exs 68/0 at seeds 0 and 12345 (was 68/2 deterministic).
  verify.support_contract.admin 184/0. mix format clean; credo --strict shows only the
  pre-existing token_parity_test.exs:111 note. Mutation check: flipping seed_matched!
  to :no_match resurrects exactly the two original failures at :913 and :1411.
  Independently re-run by the orchestrator, not just self-reported.

prevention: |
  No CI lane ran this file -- verify.support_contract.admin is an explicit allow-list
  that omitted inbound_live_test.exs, and nothing else runs mix test inside
  mailglass_admin/. That is how #203 landed green over a red file and main stayed red
  ~4 weeks. The file is now on the allow-list, making its 68 tests merge-blocking.

follow_up: |
  Post-#203, real pre-binding (legacy) evidence rows can never replay -- they fail
  {:replay_mailbox_missing, :invalid_mailbox} and surface as "Replay blocked: mailbox
  module not found." Intentional per the code comment, but a silent behavioural break
  for anyone who ingested mail before v2.6, with no upgrade note found. NOT addressed
  here; candidate for /gsd-capture.

files_changed:
  - mailglass_admin/test/support/inbound_fixtures.ex
  - mailglass_admin/mix.exs

landed: branch fix/admin-inbound-fixture-route-binding, commit df7faadc, PR #262
