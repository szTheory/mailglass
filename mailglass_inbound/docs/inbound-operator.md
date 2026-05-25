# mailglass_inbound Operator Guide

This guide covers the production operations surface for `mailglass_inbound`:
three mix tasks for config verification, replay, and data retention; the
retention and rate-limit configuration schema; and how suppression flagging
works.

## mix mailglass.inbound.doctor

`mix mailglass.inbound.doctor` runs DNS-free pre-deploy validation of your
inbound configuration. It is the inbound analog of `mix mail.doctor` — entirely
offline, exit-coded for CI, designed to catch configuration errors before you
deploy.

### Usage

```bash
mix mailglass.inbound.doctor
mix mailglass.inbound.doctor --strict
mix mailglass.inbound.doctor --format json
mix mailglass.inbound.doctor --verbose
```

The task reads `config :mailglass_inbound, router: MyApp.InboundRouter` to
locate your compiled router.

### What it checks

- Routes compile and do not conflict
- Referenced mailbox modules exist and implement `process/1`
- Provider signing keys are **present** in config (presence only — it never
  verifies a signature, so no live HTTP call is made)
- MIME backend availability

### Exit codes

| Code | Meaning |
| ---- | ------- |
| `0` | All checks pass (including warnings, unless `--strict`) |
| `1` | At least one check failed, or any warning under `--strict` |
| `2` | Cannot diagnose — no router configured, or router does not compile |

Exit code `2` is the "cannot even run the checks" signal. Exit code `1` is the
CI failure signal. Exit code `0` is the green path.

### Flags

| Flag | Effect |
| ---- | ------ |
| `--strict` | Treat warnings as failures (exit `1` on any warning) |
| `--format json` | Machine-readable JSON output (default: human) |
| `--verbose` | Show the resolved route list alongside check results |

### CI usage

Add to your pre-deploy gate:

```bash
mix mailglass.inbound.doctor --strict --format json
```

Exit code `1` fails the gate. Exit code `2` typically indicates a missing
router config and should also fail.

### Output (human format)

```
check: routes compile ... ok
check: no route conflicts ... ok
check: SupportMailbox implements process/1 ... ok
check: postmark signing key present ... ok
check: MIME backend available ... ok

All checks passed.
```

## mix mailglass.inbound.replay

`mix mailglass.inbound.replay` replays previously received inbound records
through their mailboxes. It drives the shipped replay engine, appending an
`ExecutionRun` with `source: :replay` to the append-only lineage table without
modifying any existing rows.

### Usage

```bash
# Replay a single record
mix mailglass.inbound.replay --tenant acme --record-id <uuid>

# Replay all records since a timestamp for a tenant
mix mailglass.inbound.replay --tenant acme --since 2026-05-01T00:00:00Z

# Report scope without replaying
mix mailglass.inbound.replay --tenant acme --dry-run

# Skip confirmation
mix mailglass.inbound.replay --tenant acme --record-id <uuid> --yes
```

### --tenant is required

`--tenant <id>` is required for every replay operation. It is the cross-tenant
replay guard: every record is loaded scoped to that tenant, so a
foreign-tenant `--record-id` resolves to nothing rather than replaying across
the boundary.

In single-tenant deployments, pass your resolver's tenant ID:

```bash
mix mailglass.inbound.replay --tenant default --dry-run
```

Omitting `--tenant` is a CLI error:

```
Inbound replay blocked: --tenant <id> is required (cross-tenant replay guard).
Use --tenant default under the SingleTenant resolver.
```

### Flags

| Flag | Effect |
| ---- | ------ |
| `--tenant <id>` | **Required.** Scope all record loads to this tenant |
| `--record-id <uuid>` | Replay a specific record (AND-combined with --since) |
| `--since <iso8601>` | Replay all records received at or after this timestamp |
| `--yes` / `-y` | Skip the confirmation prompt |
| `--dry-run` | Report the count and scope without replaying |

`--record-id` and `--since` are AND-combinable: both must match for a record to
be replayed.

### Confirmation

Replay is non-destructive — it only appends `ExecutionRun` rows. The
confirmation tier is a simple `[y/N]` defaulting to **No**:

```
Replay 12 inbound record(s)? [y/N]
```

`--yes`/`-y` skips the prompt for automation. `--dry-run` reports scope without
prompting or replaying.

### Zero matches

When no records match the selectors, the task exits `0` with:

```
Inbound replay: nothing to replay (0 records matched the selectors).
```

## mix mailglass.inbound.prune

`mix mailglass.inbound.prune` enforces the configured inbound retention policy.
It runs the batched sweep synchronously (with or without Oban) and deletes
over-retention rows in batches of 1000 under a `pg_try_advisory_lock`
single-run guard.

### Usage

```bash
# Interactive typed confirmation
mix mailglass.inbound.prune

# Report scope without deleting
mix mailglass.inbound.prune --dry-run

# Skip confirmation (for cron or CI)
mix mailglass.inbound.prune --yes
```

### Typed "yes" confirmation

Because the sweep **permanently deletes rows**, the confirmation tier is
stronger than replay's `[y/N]`. You must type the full word `yes` at the
prompt:

```
This permanently deletes over-retention inbound rows. Type 'yes' to continue:
```

Typing anything other than `yes` (including `y`, `Y`, or `YES`) aborts without
deleting:

```
Inbound prune: aborted (no rows deleted).
```

`--yes`/`-y` skips the prompt for automated use (cron, CI):

```bash
mix mailglass.inbound.prune --yes
```

### Flags

| Flag | Effect |
| ---- | ------ |
| `--yes` / `-y` | Skip typed confirmation (cron/CI) |
| `--dry-run` | Report scope without deleting |

### Delete order

Rows are deleted child-first to respect the FK-lineage invariant:

1. `replay_runs` (oldest window: 30 days default)
2. `execution_runs` (90 days default)
3. `evidence` (90 days default)
4. `records` (90 days default)

### Advisory lock

A `pg_try_advisory_lock` guards the sweep so only one prune can run at a time.
If another sweep is already in progress, the task exits cleanly:

```
Inbound prune: another sweep is already running (advisory lock held); nothing deleted.
```

### Scheduled pruning with Oban

`MailglassInbound.Prune.Worker` exists as an Oban cron worker but is **not
auto-registered**. Wire it yourself in your Oban config:

```elixir
# config/config.exs
config :my_app, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {MailglassInbound.Prune.Worker, "0 3 * * *"}  # daily at 03:00 UTC
     ]}
  ]
```

If you do not use Oban, run the prune task from system cron:

```cron
0 3 * * * /path/to/app mix mailglass.inbound.prune --yes
```

`mix mailglass.inbound.prune` runs the sweep synchronously regardless of
whether Oban is installed — only *scheduling* needs Oban.

## Retention policy configuration

Retention windows control how long each table class is kept before the prune
sweep deletes it. Configure them in `config/runtime.exs`:

```elixir
config :mailglass_inbound,
  retention: [
    records_days:        90,   # how long to keep InboundRecord rows
    evidence_days:       90,   # how long to keep raw evidence (payloads, MIME)
    execution_runs_days: 90,   # how long to keep fresh ExecutionRun rows
    replay_runs_days:    30    # how long to keep ReplayRun rows
  ]
```

These are the defaults. You only need to configure keys you want to override.

### FK-lineage invariant

The four windows must respect the foreign-key lineage so the child-first sweep
never trips a constraint:

```
records_days >= evidence_days >= max(execution_runs_days, replay_runs_days)
```

If you configure a shorter parent window than a child, the config accessor
silently clamps the parent up to the minimum safe value rather than letting the
sweep crash on a foreign key violation.

### Disabling a window

Set any class to `:infinity` to disable pruning for that class:

```elixir
config :mailglass_inbound,
  retention: [
    records_days:        :infinity,  # never prune records
    evidence_days:       :infinity,  # never prune evidence
    execution_runs_days: :infinity,
    replay_runs_days:    30
  ]
```

When a child class is `:infinity`, its parent classes are also treated as
`:infinity` (the FK-lineage invariant applies).

### Inspecting effective windows at boot

Call `MailglassInbound.Config.validate_at_boot!/0` from your application start
to validate the configured shape and raise early on invalid values:

```elixir
# lib/my_app/application.ex
def start(_type, _args) do
  MailglassInbound.Config.validate_at_boot!()
  # ... supervisor children
end
```

## Rate-limit configuration

`mailglass_inbound` rate-limits inbound requests post-verify in three buckets
evaluated fail-fast in order:

```
tenant -> recipient -> sender_domain
```

On bucket trip, the plug returns HTTP 429 with a `Retry-After` header. There
is no `:transactional` stream bypass.

Configure in `config/runtime.exs`:

```elixir
config :mailglass_inbound,
  rate_limit: [
    tenant:        [capacity: 1000, per_minute: 1000],  # per tenant_id
    recipient:     [capacity: 500,  per_minute: 500],   # per envelope_recipient
    sender_domain: [capacity: 200,  per_minute: 200]    # per sender domain
  ]
```

These are the defaults. `capacity` is the token-bucket burst size;
`per_minute` is the sustained refill rate. The defaults set them equal, so
"N/min" is the sustained throughput.

### Evaluation order

1. **Tenant bucket** trips first. If a tenant exceeds 1000 inbound requests per
   minute across all recipients, subsequent requests from that tenant are
   rejected with 429 before further processing.
2. **Recipient bucket** trips second — per `envelope_recipient` address,
   regardless of sender.
3. **Sender domain bucket** trips last — per extracted sender domain.

Fail-fast means a tenant trip never reaches the recipient or sender_domain
checks.

### Tuning recommendations

- Raise `tenant` capacity for high-volume tenants (e.g. SaaS platforms
  receiving forwarded helpdesk email at scale).
- Keep `sender_domain` low to protect against individual senders flooding a
  single recipient.
- All values are runtime-configurable — no restart required if you update
  `config/runtime.exs` and restart the application.

## Suppression flag interpretation

`mailglass_inbound` checks the outbound suppression list when an inbound message
arrives. Suppressed senders are **flagged, not auto-bounced**.

### What the flag means

When an inbound sender's address appears on the suppression list, the
`InboundRecord` is inserted with `suppression_flagged: true`. The message still
flows through routing and mailbox execution. The flag is visible:

- In the `InboundMessage.metadata` map under the `:suppression_flagged` key
- In the inbound admin LiveView record list and detail panel

### Why flag-only, not auto-bounce

Several common inbound patterns involve suppressed addresses:

- **Forwarders and aliasing services.** A forwarding address may be on the
  suppression list (e.g. a bounce from `alias@forwarder.example` that
  suppressed that address), but the human behind it is legitimate.
- **Complaint replies.** A recipient who marked a delivery as spam may then
  write in with a genuine support request. Auto-bouncing that reply discards
  diagnostic signal.
- **False-positive recovery.** Suppression lists can have false positives.
  Auto-bouncing closes the recovery window before a human can inspect the
  situation.

The flag preserves the diagnostic signal. Your mailbox callback decides what to
do with it:

```elixir
defmodule MyApp.Mailboxes.SupportMailbox do
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(message) do
    if message.metadata[:suppression_flagged] do
      # Route to a human review queue rather than auto-processing
      {:reject, "suppressed sender — flagged for manual review"}
    else
      :accept
    end
  end
end
```

Or accept and handle in application logic:

```elixir
def process(message) do
  MyApp.SupportTickets.create(message)
  :accept
end
```

The choice of outcome is yours. The inbound package only flags; it does not
decide.

## References

- [inbound-install.md](inbound-install.md) — initial router config and provider
  setup, which `mix mailglass.inbound.doctor` validates
- [inbound-testing.md](inbound-testing.md) — how to write tests that verify
  mailbox behavior
- [inbound-mailgun.md](inbound-mailgun.md) — Mailgun provider setup
- [inbound-ses.md](inbound-ses.md) — SES provider setup
