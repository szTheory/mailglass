---
phase: 50-inbound-documentation-pass
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - mailglass_inbound/docs/inbound-install.md
  - mailglass_inbound/docs/inbound-testing.md
  - mailglass_inbound/docs/inbound-operator.md
  - mailglass_inbound/docs/inbound-mailgun.md
  - mailglass_inbound/docs/inbound-ses.md
  - mailglass_inbound/docs/inbound-routing-debug.md
  - lib/mix/tasks/mailglass.docs.check.ex
  - mailglass_inbound/mix.exs
  - test/mailglass/docs_contract_test.exs
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 50: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Nine files reviewed: six inbound documentation guides, the docs-check mix task, the inbound `mix.exs`, and the docs contract test. The guides are well-structured and cover the installation, testing, and operations surface competently. Three blockers were found: one code example that crashes at runtime, one incorrect capability claim about SES subscription confirmation, and one fixture API called with wrong argument types that silently ignores all options. Four warnings cover a stale version pin, a false-positive in the contract check, contradictory config guidance, and a TODO comment in a shipped doc.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `message.metadata[:suppression_flagged]` Crashes at Runtime — Wrong Struct Field

**File:** `mailglass_inbound/docs/inbound-operator.md:365,391`

**Issue:** The guide documents two occurrences of the old `InboundMessage.metadata` accessor path for the suppression flag:

- Line 365 prose: "In the `InboundMessage.metadata` map under the `:suppression_flagged` key"
- Line 391 code: `if message.metadata[:suppression_flagged] do`

`MailglassInbound.InboundMessage` has **no `:metadata` field**. The `defstruct` enumerates: `tenant_id, provider, provider_message_id, message_id, envelope_recipient, subject, sent_at, received_at, text_body, html_body, from, to, cc, bcc, reply_to, headers, attachments, signals`. Accessing `message.metadata` on a struct that does not declare that key raises `** (KeyError) key :metadata not found`.

The design deviation D-49-21 (documented in `inbound_message.ex` lines 44–49) explicitly records that IOPS-05's original wording specified `metadata.suppression_flagged` but the implementation deliberately uses the typed `signals` nested struct instead. The operator guide was not updated to reflect this change.

**Fix:**
```elixir
# Prose correction: "In the InboundMessage.signals struct under the :suppression_flagged field"

# Code correction (operator guide line 391):
def process(message) do
  if message.signals.suppression_flagged do
    {:reject, "suppressed sender — flagged for manual review"}
  else
    :accept
  end
end

# Or use the shipped predicate:
def process(message) do
  if MailglassInbound.InboundMessage.suppression_flagged?(message) do
    {:reject, "suppressed sender — flagged for manual review"}
  else
    :accept
  end
end
```

---

### CR-02: SES "Subscription Confirmation Is Automatic" — Code Does Not Follow SubscribeURL

**File:** `mailglass_inbound/docs/inbound-ses.md:77-81`

**Issue:** The guide states:

> **Subscription confirmation is automatic.** When SNS delivers the `SubscriptionConfirmation` message to your endpoint, the ingress plug validates the `SubscribeURL` against the hardcoded AWS trust policy and responds with `200 OK`. SNS then marks the subscription as confirmed. No adopter action is required.

This is factually incorrect. AWS SNS requires that when your endpoint receives a `SubscriptionConfirmation`, it issues an HTTP GET to the `SubscribeURL` field to confirm the subscription. Returning `200 OK` to the POST from SNS does not confirm the subscription.

The actual inbound SES provider code (`mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex` lines 161–178) validates only that the `SubscribeURL` host matches the SNS trust-policy pattern and then returns `:ok` — it makes **no HTTP call** to the URL. The code comment at line 161 says "follow SubscribeURL; we validate it against the TrustPolicy host allowlist" — but validation is not following. The comment at line 163 confirms the design decision: "Topic activation (the actual ConfirmSubscription HTTP call) is core's outbound concern; for inbound the control-plane no-op is the deliverable."

The consequence for adopters who follow this guide: after pointing their SNS subscription at `/inbound/:tenant_id/ses` and creating the subscription, the SNS console will show the subscription status as **PendingConfirmation** indefinitely. SNS will not deliver `Notification` messages to an unconfirmed subscription. No inbound mail will be processed.

Contrast: the core `mailglass` SES webhook provider (`lib/mailglass/webhook/providers/ses.ex` lines 172–200) correctly constructs and calls the `ConfirmSubscription` URL — but that handles outbound event webhooks on a different SNS topic.

**Fix:** The guide must document that manual confirmation is required. Replace the "automatic" claim with the actual behavior and provide adopter instructions:

```markdown
3. **Confirm the subscription manually.** After SNS delivers a
   `SubscriptionConfirmation` POST to your endpoint, the ingress plug validates
   the `SubscribeURL` host against the hardcoded SNS trust policy (SSRF guard)
   and returns `200 OK`, but it does **not** follow the URL. SNS requires an
   HTTP GET to the `SubscribeURL` to complete confirmation.

   Visit the SNS console → your subscription → **Request confirmation** (or
   retrieve the `SubscribeURL` from the SNS delivery attempt logs and curl it):

   ```bash
   curl "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&..."
   ```

   The subscription status changes from `PendingConfirmation` to `Confirmed`
   once SNS receives your GET. Until confirmed, no `Notification` messages are
   delivered.
```

Alternatively, implement the HTTP follow in the inbound provider, consistent with how the core provider handles its SNS topic.

---

### CR-03: `build_ses_sns_payload` Called with Wrong Argument Type and Non-Existent Options

**File:** `mailglass_inbound/docs/inbound-ses.md:271-274`

**Issue:** The SES guide's testing section shows:

```elixir
payload = MailglassInbound.Fixtures.build_ses_sns_payload(%{
  bucket: "test-bucket",
  key: "inbound/test-message-id"
})
```

The actual function signature (`mailglass_inbound/lib/mailglass_inbound/fixtures.ex` line 371) is:

```elixir
@spec build_ses_sns_payload(keyword()) :: %{raw_body: binary(), headers: [...], config: map()}
def build_ses_sns_payload(opts \\ [])
```

Two problems:

1. **Wrong argument type.** The guide passes a `%{bucket: ..., key: ...}` map; the function expects a `keyword()`. In Elixir, passing a map where a keyword list is expected does not error at the call site (maps are enumerable), but the map atoms `:bucket` and `:key` are not keywords in the expected format, so `Keyword.get/2` calls will all return their defaults.

2. **Non-existent options.** Neither `:bucket` nor `:key` is a supported option. The builder ignores them silently and uses the hardcoded `@ses_bucket = "fixture-inbound-bucket"` and a generated SES message ID as the object key. Adopters following this example cannot override the bucket or object key.

The correct call (matching the inbound-testing.md guide at line 370) is:

**Fix:**
```elixir
# Correct: keyword list, supported options only
payload = Fixtures.build_ses_sns_payload(subject: "SES inbound test")

# The bucket and object key are fixture-internal; to test against a custom
# message body, use the :text_body option:
payload = Fixtures.build_ses_sns_payload(
  subject: "SES inbound test",
  text_body: "Custom body content"
)
```

---

## Warnings

### WR-01: Dependency Version Pin `~> 0.2` Contradicts Shipped `0.1.0`

**File:** `mailglass_inbound/docs/inbound-install.md:21`

**Issue:** The installation guide's dependency snippet shows:

```elixir
{:mailglass_inbound, "~> 0.2"},
```

The package version in `mailglass_inbound/mix.exs` is `@version "0.1.0"`, and `CLAUDE.md` confirms "mailglass_inbound 0.1.0" is the shipped version. The `mailglass_inbound/README.md` correctly shows `"~> 0.1"`. An adopter following the install guide would get a dependency resolution error because no `0.2.x` version exists on Hex.

**Fix:**
```elixir
{:mailglass_inbound, "~> 0.1"},
```

---

### WR-02: Docs Contract Check Token `"use MailglassInbound.Mailbox"` Is a False-Positive Substring Match

**File:** `lib/mix/tasks/mailglass.docs.check.ex:250` and `test/mailglass/docs_contract_test.exs:204`

**Issue:** Both the docs check task and the contract test require the token `"use MailglassInbound.Mailbox"` in `inbound-install.md`. The check uses `String.contains?/2` (substring match). The install guide never contains `use MailglassInbound.Mailbox` as a standalone directive — it correctly uses `@behaviour MailglassInbound.Mailbox` (line 106) because `MailglassInbound.Mailbox` is a pure `@behaviour` with no `__using__/1` macro. The check passes only because `"use MailglassInbound.MailboxCase"` (line 212) happens to contain `"use MailglassInbound.Mailbox"` as a substring.

This creates two risks:

1. If the MailboxCase example is ever removed from the install guide, the contract check will correctly fail — but for the wrong stated reason (it will report "missing `use MailglassInbound.Mailbox`" when the actual missing content is the mailbox behaviour wiring).
2. The required token implies a `use` macro exists, which could mislead a documentation author into writing incorrect code.

**Fix:** Replace the substring token with a more precise string that matches actual guide content:

```elixir
# In mailglass.docs.check.ex @tier1_surface_rules for "inbound-install.md":
required: [
  "body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}",
  "use MailglassInbound.Router",
  "@behaviour MailglassInbound.Mailbox",  # not "use MailglassInbound.Mailbox"
  "mix ecto.migrate",
  "async: false"
]

# In docs_contract_test.exs line 204:
assert doc =~ "@behaviour MailglassInbound.Mailbox"
```

---

### WR-03: Section 3 of Install Guide Shows Identical Config for `config.exs` and `test.exs`

**File:** `mailglass_inbound/docs/inbound-install.md:53-61`

**Issue:** Section 3 ("Configure the repository") tells adopters to "point it at the test repo in `config/test.exs`" but then shows the same `MyApp.Repo` value for both files:

```elixir
# config/config.exs
config :mailglass_inbound, :repo, MyApp.Repo

# config/test.exs (guide shows the same value)
config :mailglass_inbound, :repo, MyApp.Repo
```

The text then adds "If you use a separate test repo for isolation, use that module name instead." — which contradicts the example showing the same name. An adopter with a sandbox test repo (e.g. `MyApp.TestRepo`) will not know the test.exs entry is optional or what to put there, and Section 10 adds a third identical entry in the test setup block, compounding the confusion.

**Fix:** Show a meaningful difference or remove the redundancy. At minimum, add a comment distinguishing the two cases:

```elixir
# config/test.exs
# If you have a dedicated sandbox repo:
config :mailglass_inbound, :repo, MyApp.Repo
# Replace MyApp.Repo with MyApp.TestRepo if you use a separate test repo for isolation.
```

---

### WR-04: TODO Comment in Production-Facing Documentation

**File:** `mailglass_inbound/docs/inbound-mailgun.md:75`

**Issue:** The Mailgun configuration code block contains an inline TODO comment:

```elixir
config :mailglass_inbound, :mailgun,
  signing_key: System.get_env("MAILGUN_WEBHOOK_SIGNING_KEY")
  # TODO: set MAILGUN_WEBHOOK_SIGNING_KEY in your environment
```

This is a shipped, Tier-1 adopter-facing guide. TODO comments signal unfinished work. The intent is already covered in the surrounding prose ("Where to find the signing key"). The comment adds noise and contradicts the "thoughtful maintainer" brand voice.

**Fix:** Remove the TODO comment. The surrounding prose already tells adopters where to find the key. If the intent is to remind adopters to set the env var, use a `> **Note:**` callout block below the code fence instead.

---

## Info

### IN-01: `File.read!` in `docs.check.ex` Raises Unbranded Exception on Missing Files

**File:** `lib/mix/tasks/mailglass.docs.check.ex:346,358`

**Issue:** Both `leak_issues/1` (line 346) and `tier1_surface_issues/0` (line 358) call `File.read!` without rescue. If any file in `@tier1_paths` or `@tier1_surface_rules` is missing or unreadable, the task crashes with an `Elixir.File.Error` stack trace instead of the branded `Mix.raise("Delivery blocked: ...")` pattern used everywhere else in the task.

**Fix:**
```elixir
defp read_or_raise(path) do
  case File.read(path) do
    {:ok, content} -> content
    {:error, reason} ->
      Mix.raise("Delivery blocked: cannot read Tier 1 doc #{path}: #{:file.format_error(reason)}")
  end
end
```

Replace both `File.read!(path)` calls with `read_or_raise(path)`.

---

### IN-02: SES Guide Shows Minimal `Plug.Parsers` Config That Breaks Multi-Provider Setups

**File:** `mailglass_inbound/docs/inbound-ses.md:55-60`

**Issue:** The SES guide's "Plug.Parsers Wiring" section shows:

```elixir
plug Plug.Parsers,
  parsers: [:json],
  ...
```

The install guide (`inbound-install.md:70-76`) and the Mailgun guide (`inbound-mailgun.md:35`) both show `parsers: [:urlencoded, :multipart, :json]`. An adopter who configures their endpoint following only the SES guide and later adds Mailgun or SendGrid will silently break multipart parsing for those providers. SES notifications are JSON (so `:json` suffices for SES alone), but the endpoint-level parsers config is shared across all routes.

**Fix:** Align the SES guide's Plug.Parsers example with the install guide:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason,
  body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}
```

Add a note: "If you use SES exclusively and not other providers, `:json` suffices. For multi-provider endpoints, keep all three parsers."

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
