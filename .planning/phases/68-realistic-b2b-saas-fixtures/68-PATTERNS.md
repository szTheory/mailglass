# Phase 68: realistic-b2b-saas-fixtures - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo/demo_data.ex` | service | batch | `reference/demo_app/lib/mailglass_demo/demo_data.ex` | exact |
| `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` | test | batch | `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` | exact |
| `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` | test | request-response | `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` | role-match |
| `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` | component | transform | `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` | exact |
| `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` | component | transform | `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` | exact |
| `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` | component | transform | `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` | exact |

## Pattern Assignments

### `reference/demo_app/lib/mailglass_demo/demo_data.ex` (service, batch)

**Analog:** `reference/demo_app/lib/mailglass_demo/demo_data.ex`

**Imports + constants pattern** (lines 4-13):
```elixir
alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias Mailglass.Suppression.Entry
alias Mailglass.Webhook.WebhookEvent
alias MailglassDemo.Repo
alias MailglassInbound.InboundRecords

@tenant "northstar"
@now ~U[2026-06-01 15:00:00Z]
```

**Reset orchestration pattern** (lines 16-21):
```elixir
def reset! do
  truncate!()
  seed_outbound!()
  seed_inbound!()
  :ok
end
```

**Scenario-first outbound seeding pattern** (lines 33-88):
```elixir
invite = delivery!(%{... provider_message_id: "pm-demo-invite-001", ...})
event!(invite, :sent, minutes_ago(25), %{"provider" => "postmark", "source" => "api"})
event!(invite, :delivered, minutes_ago(18), %{"provider" => "postmark", "source" => "webhook"})
...
suppression!(alert.recipient, :manual, "support-case:1842")
```

**Stored-truth inbound replay pattern** (lines 90-122):
```elixir
evidence = inbound_evidence!(support, %{"provider" => "mailgun", "signature" => "verified"})
inbound_run!(support, evidence, :fresh, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
inbound_run!(support, evidence, :replay, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
...
inbound_run!(no_match, no_match_evidence, :fresh, :no_match, nil)
```

**Insert helper + validation seam pattern** (lines 124-225):
```elixir
|> Delivery.changeset()
|> Repo.insert!()
...
{:ok, record} = InboundRecords.insert_inbound_record(...)
{:ok, evidence} = InboundRecords.insert_inbound_evidence(...)
{:ok, run} = InboundRecords.insert_execution_run(attrs)
```

**Truncate + identity reset pattern** (lines 237-248):
```elixir
Repo.query!("""
TRUNCATE TABLE
  mailglass_inbound_replay_runs,
  mailglass_inbound_evidence,
  mailglass_inbound_records,
  mailglass_webhook_events,
  mailglass_events,
  mailglass_suppressions,
  mailglass_deliveries
RESTART IDENTITY CASCADE
""")
```

---

### `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` (test, batch)

**Analog:** `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`

**DataCase + aliases pattern** (lines 1-8):
```elixir
use MailglassDemo.DataCase, async: false

alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias Mailglass.Suppression.Entry
alias MailglassDemo.DemoData
alias MailglassDemo.Repo
```

**Determinism contract test pattern** (lines 10-28):
```elixir
DemoData.reset!()
baseline = snapshot()
insert_noise()
refute snapshot() == baseline
DemoData.reset!()
rerun = snapshot()
assert Map.take(rerun, deterministic_keys()) == Map.take(baseline, deterministic_keys())
```

**Snapshot shape for named fixture assertions** (lines 30-43):
```elixir
%{
  deliveries: ...,
  events: ...,
  inbound: ...,
  suppressions: ...,
  inbound_evidence: ...,
  inbound_replay_runs: ...,
  delivery_message_ids: ...,
  event_types: ...,
  inbound_provider_message_ids: ...,
  suppression_addresses: ...,
  replay_sources: ...
}
```

---

### `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` (test, request-response)

**Analog:** `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs`

**ConnCase test module pattern** (lines 1-3 in analog):
```elixir
defmodule MailglassDemoWeb.PageControllerSecurityTest do
  use MailglassDemo.ConnCase, async: false
```

**Focused assertions pattern** (lines 19-47 in analog):
```elixir
test "...", %{conn: conn} do
  conn = get(conn, "...")
  assert ...
end
```

Use same single-behavior-per-test style to assert each mailer family’s `preview_props` scenario keys and deterministic values.

---

### `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` (component, transform)

**Analog:** `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`

**Mailable module pattern** (lines 1-5):
```elixir
defmodule MailglassDemoWeb.Mailers.AccountMailer do
  use Mailglass.Mailable, stream: :transactional
  alias Mailglass.Message
```

**Deterministic preview props pattern** (lines 6-20):
```elixir
def preview_props do
  [
    invite_admin: %{...},
    magic_link: %{...}
  ]
end
```

**Message composition pipeline pattern** (lines 22-51):
```elixir
new()
|> Message.from({...})
|> Message.to(assigns.recipient)
|> Message.subject(...)
|> Message.html_body(...)
|> Message.text_body(...)
|> Message.put_function(:invite_admin)
```

---

### `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` (component, transform)

**Analog:** `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex`

**Operational stream + preview families pattern** (lines 1-20):
```elixir
use Mailglass.Mailable, stream: :operational
...
def preview_props do
  [
    receipt_paid: %{...},
    payment_failed: %{...}
  ]
end
```

**Consistent function tagging pattern** (lines 22-48):
```elixir
|> Message.put_function(:receipt_paid)
...
|> Message.put_function(:payment_failed)
```

---

### `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` (component, transform)

**Analog:** `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex`

**Scenario family pattern** (lines 6-20):
```elixir
def preview_props do
  [
    usage_alert: %{...},
    incident_update: %{...}
  ]
end
```

**B2B operational copy + transform pipeline** (lines 22-48):
```elixir
new()
|> Message.from({...})
|> Message.to(assigns.recipient)
|> Message.subject(...)
|> Message.html_body(...)
|> Message.text_body(...)
|> Message.put_function(:incident_update)
```

## Shared Patterns

### Reset Entry Point
**Source:** `reference/demo_app/priv/repo/seeds.exs` (lines 1-3)  
**Apply to:** Keep `mix demo.reset` contract stable while deepening fixtures.
```elixir
Mix.Task.run("app.start")
MailglassDemo.DemoData.reset!()
IO.puts("Seeded Mailglass demo data for tenant #{MailglassDemo.DemoData.tenant_id()}")
```

### Mix Alias Contract
**Source:** `reference/demo_app/mix.exs` (lines 62-69)  
**Apply to:** Any reset workflow changes must preserve alias shape.
```elixir
"demo.reset": ["run priv/repo/seeds.exs"]
```

### Replay + No-Match Semantics
**Source:** `reference/demo_app/lib/mailglass_demo/demo_data.ex` (lines 103-122)  
**Apply to:** Inbound fixture expansions.
```elixir
inbound_run!(support, evidence, :fresh, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
inbound_run!(support, evidence, :replay, :accept, "MailglassDemoWeb.Inbound.SupportMailbox")
...
inbound_run!(no_match, no_match_evidence, :fresh, :no_match, nil)
```

### Inbound Routing/Mailbox Semantics
**Source:** `reference/demo_app/lib/mailglass_demo_web/inbound_router.ex` (lines 6-8), `reference/demo_app/lib/mailglass_demo_web/inbound/support_mailbox.ex` (lines 6-15)  
**Apply to:** Fixture metadata should align with existing route + outcome semantics.
```elixir
route(SupportMailbox, recipient: "support@demo.mailglass.local")
route(SupportMailbox, subject: ~r/\[(billing|support|refund)\]/i)
route(SupportMailbox, headers: [{"x-demo-priority", "high"}])
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `reference/demo_app/lib`, `reference/demo_app/test`, phase docs  
**Files scanned:** 10  
**Pattern extraction date:** 2026-06-01
