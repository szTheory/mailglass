---
phase: 50-inbound-documentation-pass
fixed_at: 2026-05-25T16:47:00Z
review_path: .planning/phases/50-inbound-documentation-pass/50-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 50: Code Review Fix Report

**Fixed at:** 2026-05-25T16:47:00Z
**Source review:** `.planning/phases/50-inbound-documentation-pass/50-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (CR-01, CR-02, CR-03, WR-01, WR-02, WR-03, WR-04)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: `message.metadata[:suppression_flagged]` crashes — wrong struct field

**Files modified:** `mailglass_inbound/docs/inbound-operator.md`
**Commit:** b6e0a24
**Applied fix:**
- Changed prose at ~line 365: "In the `InboundMessage.metadata` map under the `:suppression_flagged` key" → "In the `InboundMessage.signals` struct under the `:suppression_flagged` field"
- Changed code at ~line 391: `message.metadata[:suppression_flagged]` → `message.signals.suppression_flagged`

### CR-02: SES subscription confirmation is NOT automatic

**Files modified:** `mailglass_inbound/docs/inbound-ses.md`
**Commit:** dc4fd6b
**Applied fix:** Replaced the "Subscription confirmation is automatic" paragraph (~lines 77-81) with accurate instructions. The new text explains that the ingress plug validates the `SubscribeURL` host for SSRF protection but does NOT follow it, that the subscription stays `PendingConfirmation` until SNS receives an HTTP GET, and provides a curl example and SNS console instructions for manual confirmation.

### CR-03: `build_ses_sns_payload` wrong argument type and non-existent options

**Files modified:** `mailglass_inbound/docs/inbound-ses.md`
**Commit:** dc4fd6b (combined with CR-02 — same file)
**Applied fix:** Replaced the example passing a map `%{bucket: ..., key: ...}` with correct keyword list examples using supported options (`:subject`, `:text_body`). Added a `> **Note:**` block explaining that `:bucket` and `:key` are fixture-internal constants that cannot be overridden.

### WR-01: Version pin `~> 0.2` should be `~> 0.1`

**Files modified:** `mailglass_inbound/docs/inbound-install.md`
**Commit:** 9576ad4
**Applied fix:** Changed `{:mailglass_inbound, "~> 0.2"}` to `{:mailglass_inbound, "~> 0.1"}` in the dependency snippet to match the shipped `0.1.0` package version.

### WR-02: Docs contract token is a false-positive substring match

**Files modified:** `lib/mix/tasks/mailglass.docs.check.ex`, `test/mailglass/docs_contract_test.exs`
**Commit:** 118416a
**Applied fix:**
- In `mailglass.docs.check.ex` `@tier1_surface_rules` for `inbound-install.md`: changed required token from `"use MailglassInbound.Mailbox"` to `"@behaviour MailglassInbound.Mailbox"`
- In `docs_contract_test.exs`: changed `assert doc =~ "use MailglassInbound.Mailbox"` to `assert doc =~ "@behaviour MailglassInbound.Mailbox"`

Both files updated atomically in one commit. Verified: `mix test test/mailglass/docs_contract_test.exs` passes (22 tests, 0 failures) and `mix credo --strict lib/mix/tasks/mailglass.docs.check.ex` reports no issues.

### WR-03: Install guide shows identical config for `config.exs` and `test.exs`

**Files modified:** `mailglass_inbound/docs/inbound-install.md`
**Commit:** 6b03247
**Applied fix:** Added a `# config/test.exs` comment inside the code fence and replaced the trailing "If you use a separate test repo..." sentence with clearer prose: entry is optional if only one repo is used, and instructs adopters to replace `MyApp.Repo` with their test repo module name (e.g. `MyApp.TestRepo`) when applicable.

### WR-04: TODO comment in shipped documentation

**Files modified:** `mailglass_inbound/docs/inbound-mailgun.md`
**Commit:** a45ed49
**Applied fix:** Removed the `# TODO: set MAILGUN_WEBHOOK_SIGNING_KEY in your environment` comment from the configuration code block. The surrounding prose ("Where to find the signing key") already provides complete instructions. No replacement callout was needed.

## Skipped Issues

None — all 7 in-scope findings were fixed successfully.

---

_Fixed: 2026-05-25T16:47:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
