# Phase 169 Review Fix Evidence

## Fixed Issues

### CR-01: Exact support IDs can be presented as the wrong evidence population

Exact Account webhook and Event lookups continue to retain the requested same-Account row. Exact sections and URL focus copy now use neutral labels. They show the row's current stored webhook status and its actual direct linkage. When a source Event was later reconciled, the projection retains the requested source Event ID and exposes both the reconciliation Event ID and linked Delivery. Aggregate examples retain their population-specific labels, and foreign-scope exact IDs remain nondisclosing.

Regression coverage includes a processed webhook reached from the failed-ingest URL, an ordinary linked Event reached from the unmatched Event URL, an unresolved orphan, an orphan subsequently reconciled, and foreign-scope exact IDs.

### WR-01: A changed replay target cannot be refreshed from the rejection flow

Opening a new replay review now refreshes the current candidate list. A changed or removed target remains rejected by the existing action-time target revalidation and host authorization checks. Rejection leaves the current review consumed; closing and explicitly reopening creates a fresh private LiveView review correlation value. A queued confirmation carrying the prior review value cannot act on a replacement target. A transient refresh read failure produces a safe unavailable view and a later explicit reopen retries the read.

Behavioral coverage exercises replacement refresh followed by authorized confirmation of the newly reviewed target, removed-target refresh to zero candidates, unavailable-read retry, and duplicate queued confirmations. The correlation value is confined to dialog event correlation; it does not change the public replay command or authorization contract.

## Verification

Commands were run with `ASDF_ELIXIR_VERSION=1.18.4-otp-27` and `ASDF_ERLANG_VERSION=27.3.4.15` unless otherwise shown.

- `mix test test/mailglass/operator/replay_targets_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/replay_test.exs --seed 1` — 25 passed, 0 failed.
- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator/replay_modal_test.exs --seed 1` — 108 passed, 0 failed.
- `cd mailglass_admin && mix test --seed 1` — 542 passed, 0 failed, 1 excluded.
- `BROWSER_SERVER_PORT=4102 ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 npm run test:operator-browser` from `mailglass_admin` — 197 passed, 1 skipped. The successful run used the approved elevated browser launch required by the sandbox; Phase 169 journey and replay browser tests passed.
- `git diff --check` — passed before commit.

## Commits

- `35ca96ce` — `fix(169): preserve exact support and replay review state`

## Scope Notes

The browser suite rewrote tracked after-state screenshots; those generated changes were restored so the existing Phase 168/169 baseline photos remain unchanged. The pre-existing dirty `.planning/.continue-here.md` deletion, `.planning/HANDOFF.json` deletion, and `.planning/config.json` modification were preserved and not staged.
