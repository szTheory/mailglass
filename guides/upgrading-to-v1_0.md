# Upgrading to v1.0

This is the canonical latest-`0.x` to `1.0` upgrade guide for Mailglass.

Use this guide as the single upgrade authority when moving an existing
`mailglass` deployment onto the `1.x` contract. The older guides
[`upgrading-from-v0_1.md`](upgrading-from-v0_1.md) and
[`migration-from-swoosh.md`](migration-from-swoosh.md) remain useful, but they
are subordinate references now. They cover focused migration slices; this guide
defines the full compatibility story.

Before you start, read the canonical
[`compatibility-and-deprecations.md`](compatibility-and-deprecations.md) policy.
That guide defines the `stable lane`, the `compatibility lane`, the support
matrix, and the warning posture this upgrade assumes.

## Who this guide is for

Use this guide if you are on the latest supported `0.x` line and any of these
statements are true:

- your mailables still call `Swoosh.Email.*` directly
- you still build messages through `Mailglass.Message.new/2`
- you still call `Mailglass.Outbound.send/2`
- you still deliver raw `%Swoosh.Email{}` values for parity during migration
- you rely on `mix mailglass.upgrade.v0_2` to rewrite legacy authoring code

If you are starting a brand-new integration, skip the compatibility lane and
build directly on the stable lane.

## Stable lane target

Your `1.0` target state is:

- delivery through `Mailglass.deliver/2`, `deliver!/2`, `deliver_later/2`, or
  `deliver_many/2`
- message authoring through native `Mailglass.Message` setters
- advanced Swoosh-only adjustments isolated behind
  `Mailglass.Message.update_swoosh/2`
- matched `mailglass` and `mailglass_admin` release lines when both packages are
  present
- a clean strict-CI story for any retained deprecated paths you still carry

## Recommended sequence

1. Upgrade dependencies to the latest supported `0.x` line and fetch deps.
2. Read the compatibility guide so you know which bridges are only temporary.
3. Run the codemod if your mailables still pipe directly into
   `Swoosh.Email.*`.
4. Move new code onto the native setter path.
5. Replace `Mailglass.Outbound.send/2` calls with `Mailglass.deliver/2`.
6. Decide which remaining compatibility bridges you must keep temporarily.
7. Run docs/tests/compile with your normal strict settings before shipping.

## Dependency and package expectations

The `1.x` contract stays intentionally narrow:

- `mailglass`: current `0.3.x` line as the pre-`1.0` source state
- `mailglass_admin`: matched release line when installed
- Elixir: `~> 1.18`
- OTP: `27+`
- Phoenix: `~> 1.8`
- Phoenix LiveView: `~> 1.1`

Those expectations come from the same repo-truth support matrix documented in
[`compatibility-and-deprecations.md`](compatibility-and-deprecations.md).

## Codemod-first authoring migration

If your code still looks like this:

```elixir
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> Swoosh.Email.to(user.email)
    |> Swoosh.Email.from("hello@myapp.com")
    |> Swoosh.Email.subject("Welcome!")
    |> Swoosh.Email.html_body("<h1>Welcome</h1>")
    |> Swoosh.Email.attachment("path/to/guide.pdf")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

run the transitional codemod first:

```bash
mix mailglass.upgrade.v0_2
mix mailglass.upgrade.v0_2 --apply
```

The codemod exists to get you onto the stable setter lane faster. It is not the
long-term contract by itself.

## Preferred `1.0` authoring shape

After the codemod and any manual cleanup, the same mailable should look like
this:

```elixir
defmodule MyApp.WelcomeEmail do
  use Mailglass.Mailable, stream: :transactional

  def welcome(user) do
    new()
    |> to(user.email)
    |> from("hello@myapp.com")
    |> subject("Welcome!")
    |> html_body("<h1>Welcome</h1>")
    |> attach("path/to/guide.pdf")
    |> Mailglass.Message.put_function(:welcome)
  end
end
```

When a native setter does not cover your case, use the supported escape hatch:

```elixir
new()
|> to("user@example.com")
|> Mailglass.Message.update_swoosh(fn email ->
  Swoosh.Email.put_provider_option(email, :template_id, "welcome-template")
end)
|> Mailglass.Message.put_function(:welcome)
```

## Deprecation DX inventory

Every retained compatibility bridge below names its replacement, warning
channel, strict-CI impact, support horizon, and proof artifact.

| surface | replacement | warning channel | `--warnings-as-errors` impact | support-until version | proof artifact |
| --- | --- | --- | --- | --- | --- |
| `Mailglass.Message.new/2` | native `Mailglass.Message` setters or `new_from_use/2` | compiler deprecation via `@deprecated` | unsafe to keep in new strict-CI code because the deprecation warning is real | no earlier than `v2.0` | `lib/mailglass/message.ex`, this guide, compatibility guide |
| `Mailglass.Outbound.send/2` | `Mailglass.deliver/2` | docs-only compatibility warning today | compiles cleanly, but treat as non-canonical in new code | no earlier than `v2.0` | `lib/mailglass/outbound.ex`, this guide, compatibility guide |
| raw `%Swoosh.Email{}` with `Mailglass.deliver/2` | `Mailglass.Message`/`Mailglass.Mailable` | docs-only compatibility warning today | compiles cleanly, but not preferred for new integrations | no earlier than `v2.0` | `guides/migration-from-swoosh.md`, migration smoke test |
| `mix mailglass.upgrade.v0_2` | stable setter lane after rewrite | task warnings for ambiguous unsupported calls | neutral by itself; the resulting code must compile cleanly | no earlier than `v2.0` while documented | `lib/mix/tasks/mailglass.upgrade.v0_2.ex`, this guide |
| deprecated `verify.phase_*` aliases | semantic `verify.*` aliases | docs-only maintainer deprecation | not relevant to adopter code; keep out of Tier 1 docs | one release cycle as documented in repo comments | `mix.exs`, docs-check rules |

## Strict-CI guidance

If you compile or test with `--warnings-as-errors`, separate retained bridges
into two buckets:

- warning-emitting deprecated paths:
  `Mailglass.Message.new/2` should be migrated before you treat the codebase as
  fully `1.x` clean
- silent compatibility bridges:
  raw `%Swoosh.Email{}` delivery and `Mailglass.Outbound.send/2` still compile,
  but they remain transitional paths and should not be the default for new code

The goal is not "remove everything old immediately." The goal is "know exactly
which old path is safe to keep temporarily and which one will break strict CI."

`Mailglass.Message.new/2` stays release-blocking for strict adopters because it
still emits a real compiler deprecation warning under `--warnings-as-errors`.
Do not call an upgrade clean while that warning-producing path remains on the
canonical `1.0` lane.

## Focused migration recipes

### Replace `Mailglass.Outbound.send/2`

Preferred `1.0` form:

```elixir
assert {:ok, _delivery} = Mailglass.deliver(message)
```

If your code still imports or aliases `Mailglass.Outbound`, migrate those
callers to `Mailglass.deliver/2` unless a local transition constraint forces
you to keep the compatibility bridge briefly.

### Replace `Mailglass.Message.new/2`

If you manually wrapped a `%Swoosh.Email{}`:

```elixir
email = Swoosh.Email.new(subject: "Welcome")
message = Mailglass.Message.new(email, mailable: MyApp.UserMailer)
```

prefer authoring through `use Mailglass.Mailable` and native setters, or use
`new_from_use/2` when you are inside a mailable-driven build path.

### Keep a raw `%Swoosh.Email{}` only when parity matters

The raw-email path still exists so adopters can land on mailglass gradually:

```elixir
email =
  Swoosh.Email.new()
  |> Swoosh.Email.to("migrated@example.com")
  |> Swoosh.Email.from("system@example.com")
  |> Swoosh.Email.subject("Migration test")

assert {:ok, _delivery} = Mailglass.deliver(email)
```

Treat that as a compatibility bridge, not as the preferred long-term authoring
model.

## Subordinate references

Use the older guides for focused slices only:

- [`upgrading-from-v0_1.md`](upgrading-from-v0_1.md): codemod-first conversion
  from direct `Swoosh.Email` setter calls
- [`migration-from-swoosh.md`](migration-from-swoosh.md): incremental adoption
  when you are moving from a raw Swoosh setup

If those guides ever appear to disagree with this one, treat this guide as the
canonical authority and update the subordinate guide.

## Verification before shipping

After you migrate, run the checks that match the repo's own support posture:

```bash
mix verify.docs.migration
mix verify.stability_contract
mix docs --warnings-as-errors
```

If you ship `mailglass_admin`, keep it on the matched sibling release line and
verify its docs build too:

```bash
cd mailglass_admin
mix docs --warnings-as-errors
```

## Upgrade outcome

You are `1.0`-ready when:

- new code uses the stable lane by default
- deprecated paths that emit warnings are either removed or consciously tracked
- any retained silent bridges are documented as temporary compatibility choices
- subordinate migration guides no longer act like competing authorities
