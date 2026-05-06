# Operator Incident Support

This is the canonical incident guide for production mailglass support. Start
from the customer symptom, then use the stage drilldowns below to separate
provider lifecycle facts, replay facts, and reconcile facts.

`mailglass_admin/docs/operator-trust.md` is the canonical admin trust doc for
the stable router/auth/session/replay semantics referenced by this guide.

## Symptom-first entrypoints

### customer says the email never arrived

1. Check the selected delivery in the operator surface.
2. Review outbound spans and delivery timeline facts.
3. If a provider webhook is missing or unmatched, continue to the webhook and
   orphan sections below.

### provider is retrying or timing out

1. Check `[:mailglass, :outbound, :dispatch, :stop]` for dispatch latency and
   status.
2. Check `[:mailglass, :webhook, :ingest, :stop]` for ingest failures or slow
   webhook processing.
3. Confirm whether the provider is retrying externally or mailglass is only
   recording duplicate inbound attempts.

### orphan backlog is growing

1. Check `[:mailglass, :webhook, :orphan, :stop]` for orphan age and volume.
2. Check `[:mailglass, :webhook, :reconcile, :stop]` for scanned, linked, and
   remaining counts.
3. Run `mix mailglass.reconcile` if you need an on-demand background sweep.

### replay completed but nothing changed

1. Read the replay audit facts on the selected delivery.
2. Confirm whether the replay outcome was `new work` or `no change`.
3. If the event is still unmatched, move to the reconcile stage instead of
   retrying vague "repair" steps.

## Delivery send and provider lifecycle facts

### Provider lifecycle facts

- `[:mailglass, :render, :message, :stop]` proves the message rendered in your
  app.
- `[:mailglass, :outbound, :send, :stop]` proves the send pipeline ran.
- `[:mailglass, :outbound, :dispatch, :stop]` proves mailglass handed work to
  the provider; dispatch is not the same thing as downstream delivery.
- Normalized provider webhook events, once matched to a delivery, are the local
  record of later provider lifecycle facts such as `:sent`, `:delivered`,
  `:bounced`, `:deferred`, or `:complained`.

### Replay facts

- Replay does not create provider lifecycle truth by itself.
- Replay is an operator action against one exact stored webhook event from the
  selected delivery detail.
- Replay outcomes stay auditable as requested, completed, or failed, plus the
  effect wording `new work` or `no change`.

### Reconcile facts

- Reconcile is not a provider resend and not a delivery-detail replay.
- Reconcile scans orphan webhook rows that are still unmatched after the grace
  window and appends `:reconciled` when a safe link becomes possible.
- A reconcile run can leave rows `still unmatched` without that being a bug.

### Mailglass can tell you this

- Whether mailglass rendered and dispatched the message
- Whether a matched provider webhook later arrived in the local ledger
- Whether a replay was attempted and what local effect it had
- Whether reconcile linked or left orphan rows unmatched

### Mailglass cannot tell you this

- Whether a mailbox provider placed the message in inbox, spam, or quarantine
- Why a remote provider retried unless that reason is surfaced in the provider
  webhook you actually received
- Whether a provider dashboard would show additional account-side policy errors

## Webhook signature and ingest facts

### Provider lifecycle facts

- `[:mailglass, :webhook, :signature, :verify, :stop]` tells you whether the
  request passed signature verification.
- `[:mailglass, :webhook, :ingest, :stop]` tells you whether mailglass accepted
  and processed the webhook request.
- `[:mailglass, :webhook, :normalize, :stop]` tells you whether a provider
  event mapped into the shipped event taxonomy.

### Replay facts

- Replaying a stored webhook row reruns mailglass's normalization and ingest
  path for that exact stored input.
- A replay that converges to duplicate or `no change` means the row was already
  accounted for locally; it does not prove the original provider retry stopped.

### Reconcile facts

- Reconcile only matters here if ingest produced an orphan row because the
  matching delivery was not yet linkable.
- Reconcile does not re-verify signatures or refetch provider payloads.

### Mailglass can tell you this

- Whether signature verification succeeded or failed
- Whether ingest completed, duplicated, or failed locally
- Whether normalization mapped the provider event type

### Mailglass cannot tell you this

- The contents of provider payload fields that mailglass intentionally does not
  expose in telemetry examples
- Any remote retry schedule that the provider never sent to your app

## Orphan backlog and reconcile facts

### Provider lifecycle facts

- An orphan means mailglass received a webhook fact before it could safely link
  that fact to a delivery.
- Orphans often reflect timing or identifier availability, not necessarily a
  broken provider.

### Replay facts

- Replaying an orphan row may still produce `no change` if the row remains
  unmatched or already converged.
- Replay is not the canonical way to drain a growing orphan backlog.

### Reconcile facts

- `Mailglass.Webhook.Reconciler.reconcile/2` is the canonical sweep.
- `mix mailglass.reconcile` calls the same code path and reports `linked` and
  `still unmatched`.
- `[:mailglass, :webhook, :reconcile, :stop]` gives you the shipped aggregate
  fact set for each sweep: `scanned_count`, `linked_count`,
  `remaining_orphan_count`, and `status`.

### Mailglass can tell you this

- How many orphans were scanned in a sweep
- How many were linked
- How many remain unmatched after the sweep
- The age of orphan events seen by the orphan emit

### Mailglass cannot tell you this

- That an unmatched orphan will definitely reconcile on the next run
- That a reconcile sweep changed downstream provider state

## Replay and reconcile repair actions

### Provider lifecycle facts

- Provider retries and downstream delivery behavior remain external lifecycle
  facts.
- Use provider dashboards for account-side delivery policy or suppression
  questions that never reach mailglass.

### Replay facts

- Replay is exact-target and delivery-entrypoint only.
- Use replay when you have one stored webhook row and need to rerun local
  ingest after fixing local configuration or transient ingest conditions.
- `new work` means replay appended new durable local facts.
- `no change` means replay converged without adding new local work.

### Reconcile facts

- Reconcile is background-first backlog maintenance, not a substitute for
  replay.
- Use reconcile when the issue is unmatched orphan accumulation, especially if
  the provider facts already reached your app.
- If Oban is absent, schedule `mix mailglass.reconcile` yourself; mailglass
  does not require a separate dashboard or backend to do this.

### Mailglass can tell you this

- Which exact delivery and webhook row a replay targeted
- Whether replay changed local durable state
- Whether reconcile linked backlog rows in this run

### Mailglass cannot tell you this

- That replay fixed the customer's inbox placement
- That reconcile means the provider retried, resent, or accepted a message

## Exact references

- Telemetry contract: [telemetry.md](./telemetry.md)
- Webhook setup and provider notes: [webhooks.md](./webhooks.md)
- Webhook shim: [webhook-troubleshooting.md](./webhook-troubleshooting.md)
- Manual reconcile fallback: `mix mailglass.reconcile`
