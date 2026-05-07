# Candidate 02 — Inbound Admin & Dev Observability

**Verdict:** **Build it.** Inbound shipped in v1.1 but is invisible in `mailglass_admin`. The data model already supports everything an operator UI needs (`InboundRecord`, `InboundEvidence`, `ExecutionRun`, `ReplayRun`), and `MailglassInbound.Internal.Replay.replay/2` already returns the same `{:ok, result}` shape outbound's `Webhook.Replay.execute/1` does. The hard, scary work (replay primitives, append-only execution lineage, mailbox routing semantics) is done. What's missing is the LiveView surface — a 4–6 week scope, not a quarter. **Defer the synthetic-inbound compose form to a v1.2.1 dev-only follow-up** behind a `mix.env() == :dev` gate; the security model deserves its own design pass.

## Concrete UI Surfaces

| Surface | What it shows | Tenant-scoped? | Dev / prod |
|---|---|---|---|
| `InboundLive` (`/inbound`) | Master/detail of `inbound_records` filtered by tenant, provider, mailbox, outcome, window. List card on left, detail on right. | **Yes — tenant_id required, blank tenant returns []** (mirror `OperatorLive.load_deliveries/1` line 338) | Both |
| Inbound detail header | Provider, `provider_message_id`, `message_id`, envelope_recipient, subject, received_at, latest execution outcome, mailbox class | Yes | Both |
| Execution timeline | All `ExecutionRun` rows (fresh + replay) for one record, ordered by `inserted_at`, badge for `:no_match \| :accept \| :ignore \| :reject \| :bounce \| :failed`, mailbox name, `outcome_reason`, replay-vs-fresh chip | Yes | Both |
| Routing trace card | "Why did this match `SupportMailbox`?" — show recipient/subject/header matchers from `__mailglass_inbound_routes__/0`, highlight the winning clause; for `:no_match` rows, show every route that was tried and which clause failed | Yes | Both |
| Evidence viewer | `InboundEvidence` raw payload + raw MIME; redact body by default, "Reveal raw" toggle gated by `DestructiveAction.authorize/4` with a fresh `:reveal_raw` capability | Yes | Both |
| Replay modal | Confirm modal + outcome-history list; reuses outbound's confirm-then-execute pattern, but the target is the record itself (replay payload re-resolves mailbox via `Internal.Replay.resolve_mailbox/2`) | Yes | Both |
| Inbound suppression card | If/when inbound bounce → outbound suppression linkage exists, show the cross-package link | Yes | Both |
| Synthetic compose (`/inbound/dev/new`) | ActionMailbox-style form (from/to/subject/body/headers + raw `.eml` paste) that calls `Ingress.Persist` + `Execution.Worker` directly | Yes | **Dev only** — `Mix.env() == :dev` AND adopter explicitly mounts `dev_routes/1` in their router |

## Reuse-Existing-Patterns Map

| New inbound surface | Copy from outbound |
|---|---|
| `MailglassAdmin.InboundLive` | `MailglassAdmin.OperatorLive` (master/detail, URL-param filters, push_patch on selection) |
| `Inbound.RecordsList` | `Operator.DeliveriesList` |
| `Inbound.FiltersForm` | `Operator.FiltersForm` (add `mailbox` and `outcome` enums; `outcome_values` from `ExecutionRun.__outcomes__/0`) |
| `Inbound.DetailHeader` | `Operator.DetailHeader` |
| `Inbound.ExecutionTimeline` | `Operator.Timeline` (event taxonomy is `ExecutionRun.outcome` instead of Anymail; same shape) |
| `Inbound.ReplayModal` | `Operator.ReplayModal` near-verbatim; selection becomes "fresh evidence" (single target — no ambiguous-multi case yet) so confirm-enabled is simpler |
| `Inbound.DestructiveAction` | `Operator.DestructiveAction` verbatim — same `MailglassAdmin.Auth.authorize/3` adapter seam, new capabilities `:replay_inbound` and `:reveal_raw` |
| `Inbound.RoutingTrace` | New component; thin — query `__mailglass_inbound_routes__/0` + render matcher diff against `InboundMessage` |

## Synthetic-Inbound Dev Tool — Should We?

**Yes, but as a v1.2.1 follow-up, dev-mounted only.** ActionMailbox's `Rails::Conductor::ActionMailbox::InboundEmailsController` is the canonical reference — `index/new/show/create` actions that build a `Mail` object and call `InboundEmail.create_and_extract_message_id!(mail.to_s)`. Mailglass's analog: a LiveView form that constructs an `InboundMessage`, hands it to `Ingress.Persist` with `provider: "synthetic"`, then dispatches `Execution.Worker`.

Shape:
- Mounted **only when adopter calls `MailglassAdmin.Router.dev_inbound_routes/1`** (separate macro from prod admin routes)
- LiveView checks `Application.get_env(:mailglass_admin, :allow_synthetic_inbound, false)` at runtime; refuses with 404 if false
- Tenant_id required field (no defaulting — adopter must pick)
- Stamps `metadata: %{synthetic: true, actor: <operator_id>}` on the resulting `ExecutionRun` so the execution timeline can badge it differently

## Anti-Patterns to Avoid

1. **Showing raw payload by default** — Postmark/Mailgun both gate raw `.eml` viewing. Default redacted; `:reveal_raw` capability check at the `DestructiveAction` seam, audit-logged.
2. **Unscoped tenant queries** — Operator's `load_deliveries(%{"tenant_id" => ""}) -> []` gate (line 338 of `operator_live.ex`) is the contract. Mirror it; don't show "all tenants".
3. **Replay without confirmation** — outbound replay modal is the precedent. No one-click replay. Capability check + confirmation modal + flash.
4. **PII in telemetry** — `[:mailglass, :inbound, :admin, :*]` events whitelist `tenant_id, provider, mailbox, outcome, latency_ms` only. Never `from`, `to`, `subject`, `headers`, body.
5. **Inventing a new admin auth path** — reuse `MailglassAdmin.Auth` adapter. New capabilities are configured by adopter, not invented by the package.
6. **Synthetic-inbound enabled in prod** — ActionMailbox's conductor is dev-only by convention; we make it dev-only by construction (separate router macro + runtime env flag + `Mix.env()` compile-time gate).
7. **Topic explosion** — one new topic: `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1` (per-tenant). Live updates to the list card on insert.

## References

- [rails/rails — `inbound_emails_controller.rb`](https://github.com/rails/rails/blob/main/actionmailbox/app/controllers/rails/conductor/action_mailbox/inbound_emails_controller.rb) — canonical conductor index/new/show/create flow
- [Action Mailbox Basics — Rails Guides](https://guides.rubyonrails.org/action_mailbox_basics.html) — conductor at `/rails/conductor/action_mailbox/inbound_emails`, "index of all the InboundEmails… and a form to create a new InboundEmail"
- [Mailgun Logs documentation](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/logs) — up-to-3 metrics, 10 filter dimensions, 24h default window — the bar for filter UX
- [Postmark Inbound Emails](https://postmarkapp.com/support/inbound-emails) — 45-day searchable activity feed; baseline expectation for inbound observability
- [SendGrid Inbound Parse](https://www.twilio.com/docs/sendgrid/ui/account-and-settings/inbound-parse) — counter-example: stats only, **no per-message log viewer**, "must monitor your own server logs"; this is exactly the gap mailglass should close
