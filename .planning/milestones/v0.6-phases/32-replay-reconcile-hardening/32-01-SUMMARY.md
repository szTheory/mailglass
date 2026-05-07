# Phase 32 Plan 32-01 Summary

## Outcome

Replay confirmation now follows the required server-side sequence:
resolve the tenant-safe replay target in `OperatorLive`, authorize the
destructive action through `MailglassAdmin.Operator.DestructiveAction`,
then execute `Mailglass.Webhook.Replay`.

## Changes

- Added `MailglassAdmin.Operator.DestructiveAction.authorize/4` as the
  shared action-time auth helper for replay and future destructive
  operator flows.
- Updated `MailglassAdmin.Auth` docs with an adopter-owned 15-minute
  recent-auth example, explicitly documented as example policy rather
  than library-owned behavior.
- Routed `confirm_replay` in `MailglassAdmin.OperatorLive` through
  `DestructiveAction.authorize/4` before `Replay.execute/1`.
- Strengthened `MailglassAdmin.OperatorLiveTest` assertions for:
  stale-auth denial with no replay audit rows,
  exact-target auto-selection,
  ambiguity keeping confirm disabled until explicit target choice.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors`
- `rg -n "DestructiveAction\\.authorize|:destructive_action|15-minute|900" mailglass_admin/lib/mailglass_admin/auth.ex mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex mailglass_admin/lib/mailglass_admin/operator_live.ex mailglass_admin/test/support/endpoint_case.ex`

## Deviations

- No code changes were made in `mailglass_admin/test/support/endpoint_case.ex`.
  That file already had unrelated in-progress edits in the working tree,
  so the public recent-auth example was documented in
  `mailglass_admin/lib/mailglass_admin/auth.ex` instead.

## Commits

No task commits were created. Atomic commits were not safe because the
plan-required surface already contained unrelated uncommitted work,
including a fully untracked `mailglass_admin/lib/mailglass_admin/auth.ex`
and pre-existing edits in `mailglass_admin/test/support/endpoint_case.ex`.
