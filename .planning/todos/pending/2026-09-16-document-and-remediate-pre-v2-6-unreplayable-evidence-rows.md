---
created: 2026-09-16T16:43:11.774Z
title: Document and remediate pre-v2.6 unreplayable evidence rows
area: inbound
severity: major
files:
  - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex:285-286
  - mailglass_inbound/lib/mailglass_inbound/execution.ex:119-137
  - mailglass_inbound/lib/mailglass_inbound/execution.ex:346-348
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex:846
---

## Problem

Commit `61e8c8e8` ("feat: complete v2.6 engineering quality ratchet (#203)") made
`verification_facts["mailglass_execution_route"]` the **sole** source of a replay
mailbox and deliberately closed the legacy path that resolved a mailbox from the
persisted `ExecutionRun.mailbox` string:

```elixir
%ExecutionRun{mailbox: mailbox} when is_binary(mailbox) and mailbox != "" ->
  # Pre-binding rows cannot safely resolve a persisted module name.
  {:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}
```

Consequence: **any InboundMessage evidence row ingested before v2.6 can never be
replayed again.** `Execution.route_binding/1` returns `{:error, :missing_binding}`
on those rows, `Internal.Replay` maps that to
`{:error, {:replay_mailbox_missing, %{reason: :invalid_mailbox}}}`, and the admin
UI surfaces it to operators as `"Replay blocked: mailbox module not found."`
(`inbound_live.ex:846`) — a message that reads like a misconfiguration the
operator could fix, when in fact nothing they can do will make the row replayable.

The closure itself is intentional and defensible (resolving an arbitrary persisted
module name is an unsafe atom/code-loading operation). What is missing is the
adopter-facing half of the change:

- No CHANGELOG entry marking it as a behavioural break.
- No upgrade note in `mailglass_inbound/docs/` (checked: install, testing,
  operator, mailgun, ses, routing-debug — none mention it).
- No backfill path or `mix` task to populate the route binding on historical rows.
- No detection: nothing tells an operator up front which of their rows are
  replay-capable, so they discover it one failed replay at a time.
- Not reflected in `mailglass_inbound/docs/api_stability.md`, even though the
  package is on a stable `1.0` contract.

Found during the `/gsd-debug` session that produced PR #262. That PR fixed the
*test-fixture* half of the same contract drift (`mailglass_admin`'s
`InboundFixtures` still seeded `verification_facts: %{}`); this todo is the
remaining *production/adopter* half, which was deliberately left out of scope
there.

Real rows are unaffected going forward — `Ingress.Persist` writes the binding on
every evidence row it creates (`ingress/persist.ex:38`), so this is strictly a
historical-data problem whose blast radius is "everything ingested before v2.6".

## Solution

Needs a decision before implementation — at minimum the documentation arm, and a
call on whether to offer remediation:

1. **Document it (non-optional).** CHANGELOG entry + an upgrade note stating that
   pre-v2.6 rows are not replayable and why. Consider whether this belongs in
   `api_stability.md` as a recorded behavioural break against the `1.0` contract.
2. **Improve the operator message.** `"Replay blocked: mailbox module not found."`
   misattributes the cause. Something closer to "this message predates durable
   route binding and cannot be replayed" tells the truth and stops operators
   hunting a config bug. Must stay within the brand voice constraints in
   `brandbook/brand-book.md` and pass the `refute_banned/1` sweep.
3. **Decide on remediation.** Options, roughly in increasing cost:
   - Do nothing beyond docs — acceptable if the adopter base is small.
   - Surface replayability up front (disable/annotate the replay control for
     pre-binding rows) so the dead end is visible before it's hit.
   - Offer a `mix mailglass.inbound.backfill_route_binding` task that reconstructs
     the binding by re-running the router against stored evidence, rather than
     trusting the persisted module string. This keeps the safety property that
     motivated closing the legacy path, since the mailbox comes from live routing
     config, not from persisted data.

Open question worth answering first: how many adopters actually have pre-v2.6
rows? That determines whether this is docs-only or warrants the backfill task.
