# Upgrading from v0.x to v1.0 (bundle: v0.5 → v1.1)

This guide is the bundle-context companion to
[`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md). Use this guide
to understand WHAT changed across the four-milestone bundle (v0.5 + v0.6 +
v1.0 + v1.1) and HOW to verify the upgrade against your sandbox app. Use
[`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md) for the strict-CI
canonical migration steps.

For the focused `v0.1 → v0.2` setter rewrite specifically, see
[`upgrading-from-v0_1.md`](../guides/upgrading-from-v0_1.md).

## Who this guide is for

Adopters on any `~> 0.3` version of `mailglass` and `mailglass_admin` who:

- shipped before the v1.0 cut date
- want to migrate to the `~> 1.0` line
- are willing to verify against a sandbox app before upgrading production

If you have never published a Mailglass-backed app to production, the
canonical [`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md) is
sufficient — this companion exists for adopters who skipped one or more
intermediate releases and want the bundle-shape view.

## What 1.0.0 bundles

Four shipped milestones land in this single 1.0.0 cut. Sibling package
versions are pinned per the
[`compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md)
contract.

| Milestone | Phases | Adopter-facing change |
|-----------|--------|------------------------|
| v0.5 Adoption Hardening | 28-31 | `Mailglass.TestAssertions`, idempotent `mix mailglass.install`, dev-preview hardening |
| v0.6 Production Maturity | 32-34 | Per-domain `RateLimiter`, Mailgun and SES providers, SES SNS verification |
| v1.0 Stability Lock | 35-38 | Compatibility guide, `upgrading-to-v1_0.md`, deprecation contract, release-rehearsal proof |
| v1.1 Inbound Core Slice | 39-44 | `mailglass_inbound` first Hex appearance (separate 0.x line), Postmark + SendGrid inbound ingress |

Cross-references to the per-milestone audits (in-repo, GitHub) if you
want the deep-dive:

- [`v0.5-MILESTONE-AUDIT.md`](https://github.com/szTheory/mailglass/blob/main/.planning/milestones/v0.5-MILESTONE-AUDIT.md)
- [`v0.6-MILESTONE-AUDIT.md`](https://github.com/szTheory/mailglass/blob/main/.planning/milestones/v0.6-MILESTONE-AUDIT.md)
- [`v1.0-MILESTONE-AUDIT.md`](https://github.com/szTheory/mailglass/blob/main/.planning/milestones/v1.0-MILESTONE-AUDIT.md)
- [`v1.1-MILESTONE-AUDIT.md`](https://github.com/szTheory/mailglass/blob/main/.planning/milestones/v1.1-MILESTONE-AUDIT.md)

## Before/After Examples

The highest-impact diffs across the bundle. Each example pairs a `0.x`
shape with the equivalent `1.0` shape.

### Dependency declaration

```elixir
# Before (0.x)
def deps do
  [
    {:mailglass, "~> 0.3"},
    {:mailglass_admin, "~> 0.3"}
  ]
end

# After (1.0)
def deps do
  [
    {:mailglass, "~> 1.0"},
    {:mailglass_admin, "~> 1.0"},
    # OPTIONAL — add only if you handle inbound mail:
    {:mailglass_inbound, "~> 0.1"}
  ]
end
```

### Mailable authoring (v0.1 setter rewrite, retained from v0.2)

```elixir
# Before (v0.1 piping into Swoosh.Email)
new()
|> Swoosh.Email.to(user.email)
|> Swoosh.Email.from("hello@myapp.com")
|> Swoosh.Email.subject("Welcome!")
|> Swoosh.Email.html_body("<h1>Welcome</h1>")

# After (v0.2+, supported native setters; same shape on 1.0)
new()
|> to(user.email)
|> from("hello@myapp.com")
|> subject("Welcome!")
|> html_body("<h1>Welcome</h1>")
```

If you are still on the v0.1 setter shape, run the codemod first; see
[`upgrading-from-v0_1.md`](../guides/upgrading-from-v0_1.md).

### Test assertions (v0.5 hardening)

```elixir
# Before (manual mailbox inspection)
import Swoosh.TestAssertions
assert_email_sent(subject: "Welcome!")

# After (Mailglass.TestAssertions, integrated with Mailglass.Adapters.Fake)
import Mailglass.TestAssertions
assert_mail_sent(subject: "Welcome!")
```

### Per-domain rate limiting (v0.6)

```elixir
# Before (no rate limit, or DIY enforcement)

# After (built-in multi-bucket rate limiter; opt-in overrides via runtime config)
config :mailglass, Mailglass.RateLimiter,
  tenant_recipient: 100,
  global_recipient: 1000,
  sender_domain: 500
```

Rate-limited messages return `{:error, %Mailglass.RateLimitError{}}` —
match the struct, never the message string.

## Bundle Migration Walkthrough

1. **Update your dependencies** in `mix.exs`:

   ```elixir
   def deps do
     [
       {:mailglass, "~> 1.0"},
       {:mailglass_admin, "~> 1.0"},
       # OPTIONAL — add only if you want inbound message routing:
       {:mailglass_inbound, "~> 0.1"}
     ]
   end
   ```

2. **Fetch dependencies:**

   ```bash
   mix deps.get
   ```

3. **(If still on `~> 0.1` setter API)** Run the codemod first:

   ```bash
   mix mailglass.upgrade.v0_2 --apply
   ```

4. **Compile with strict warnings.** `Mailglass.Message.new/2` will warn
   on the deprecation bridge; migrate per
   [`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md):

   ```bash
   mix compile --warnings-as-errors
   ```

5. **Verify your usage matches the canonical guide:**

   ```bash
   mix verify.docs.migration
   ```

6. **Run your test suite.**

For the strict-CI canonical step list (preserved from the 1.0 release
contract), follow [`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md)
in lockstep with this walkthrough.

## Sibling Packages

- `mailglass_admin` 1.0.0 — linked release. Bump together with core.
- `mailglass_inbound` 0.1.0 — first Hex appearance. Opt-in if you handle
  inbound mail. Ships on a separate 0.x version line per
  [`compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md).
  Adding or omitting `mailglass_inbound` does not affect the core 1.x
  contract.

## Sandbox Verification Recipe

Verify end-to-end against a fresh Phoenix app before upgrading production.
This recipe matches the maintainer-side verification documented in the
release runbook.

```bash
mix archive.install hex phx_new --force
mix phx.new sandbox --no-ecto --no-mailer --install
cd sandbox
# Edit mix.exs deps to add:
#   {:mailglass, "== 1.0.0"},
#   {:mailglass_admin, "== 1.0.0"},
#   {:mailglass_inbound, "== 0.1.0"}
mix deps.get
mix mailglass.install
mix compile --warnings-as-errors
mix phx.server &
curl -fs http://localhost:4000/dev/mail/    # expect HTTP 200
```

If the sandbox passes, your upgrade should be safe. If `mix
mailglass.install` reports any warnings, address them before applying the
bump to production.

## Dependency Matrix

- `mailglass`: `~> 1.0`
- `mailglass_admin`: `~> 1.0`
- `mailglass_inbound`: `~> 0.1` (optional)
- `phoenix`: `~> 1.8`
- `phoenix_live_view`: `~> 1.1`
- `ecto` / `ecto_sql`: `~> 3.13`
- Elixir `~> 1.18`
- OTP 27+
- PostgreSQL 14+ (CI proves Postgres 16)

Optional supported integrations: `oban`, `opentelemetry`, `mjml`,
`gen_smtp`, `sigra`. None are required to remain inside the 1.x contract.

## Rollback

Treat the upgrade as a git-clean operation. Run from a disposable branch
or clean working tree so `git diff` shows exactly what changed. Discard
with `git restore .` if the diff is wrong.

Hex publishes are irreversible after the 60-minute revert window. The
public rollback contract is git-based review/revert of the upgrade diff,
not cleanup of arbitrary dirty repositories.

## Troubleshooting

### Linked siblings drift between releases

`mailglass` and `mailglass_admin` share a version line. If `mix deps.get`
complains about mismatched versions, you likely have one declared at a
different constraint than the other. Align both at `~> 1.0`.

### `mailglass_inbound` not on the 1.x line

Inbound is intentionally on `~> 0.1` because the inbound API is still
stabilizing. Add or omit it independently of `mailglass` core; it does
not lock-step with the 1.x line. See
[`compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md)
for the explicit exclusion text.

### `Mailglass.Message.new/2` warning

This is the deprecation bridge, retained from v0.2. See
[`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md) for the
migration path. The warning is informational, not blocking.

### `Mailglass.RateLimitError` after upgrading

Per-domain rate limiting was introduced in v0.6 and remains enabled by
default for `:bulk` and `:operational` streams. If your existing volume
exceeds the defaults, configure overrides in `config/runtime.exs` or move
time-sensitive alerts to the `:transactional` stream.

### Tests fail with "no mail sent"

Confirm you have switched to `Mailglass.Adapters.Fake` in
`config/test.exs`, and that you import `Mailglass.TestAssertions` rather
than relying on internal mailbox structure.

## What this guide does NOT cover

- API-level migration of specific code paths — see
  [`upgrading-to-v1_0.md`](../guides/upgrading-to-v1_0.md).
- The detailed deprecation contract — see
  [`compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md).
- Inbound integration — see `mailglass_inbound/README.md` (separate
  package).
- The focused `v0.1 → v0.2` setter codemod — see
  [`upgrading-from-v0_1.md`](../guides/upgrading-from-v0_1.md).

---

*Last updated: 2026-05-07 (Phase 44.5 v1.0/1.1 release ceremony).*
