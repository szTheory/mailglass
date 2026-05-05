# Webhook Troubleshooting

Use [operator-incident-support.md](./operator-incident-support.md) as the
canonical incident guide. This page is only the webhook-specific entry shim.

## Start from the real support symptom

- For "customer says the email never arrived", start at
  [Customer says the email never arrived](./operator-incident-support.md#customer-says-the-email-never-arrived).
- For "provider is retrying or timing out", start at
  [Provider is retrying or timing out](./operator-incident-support.md#provider-is-retrying-or-timing-out).
- For "orphan backlog is growing", start at
  [Orphan backlog is growing](./operator-incident-support.md#orphan-backlog-is-growing).
- For "replay completed but nothing changed", start at
  [Replay completed but nothing changed](./operator-incident-support.md#replay-completed-but-nothing-changed).

## Exact webhook reference sections

- Route wiring, provider setup, and supported providers:
  [webhooks.md](./webhooks.md)
- Current webhook event names and metadata keys:
  [telemetry.md](./telemetry.md)
- Manual backlog sweep fallback: `mix mailglass.reconcile`

## Fast boundary reminders

- provider lifecycle facts come from the provider send/accept/retry behavior
  plus normalized webhook events.
- replay facts come from one operator-triggered replay against one exact stored
  webhook row.
- reconcile facts come from the background-first orphan sweep and appended
  `:reconciled` audit events.

If you need the full "mailglass can tell you this / cannot tell you this"
checklists, use the canonical incident guide instead of this shim.
