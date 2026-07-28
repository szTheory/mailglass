---
id: SEED-004
status: dormant
planted: 2026-07-10
planted_during: v2.1 archived / awaiting next milestone
trigger_when: when planning outbound operator evidence, delivery audit, compliance, or message-retention work
scope: large
---

# SEED-004: Sent Email Snapshot Retention

## Why This Matters

Operators often need to answer: "What exact email did we send?" Provider event logs prove delivery flow, but they do not consistently preserve the rendered message body. Postmark and Resend expose sent-message viewing, SendGrid explicitly does not retain email content, Mailgun requires stored-message setup/storage URLs, and SES requires opt-in archiving. A Mailglass-owned snapshot could make this capability provider-independent and trustworthy.

This is high-value for support, compliance, QA, debugging template regressions, and product trust. It is also high-risk because rendered emails contain PII and sometimes sensitive business data, so it must be opt-in, retention-bound, access-controlled, and redaction-aware.

## When to Surface

**Trigger:** when planning outbound operator evidence, delivery audit, compliance retention, or provider-independent troubleshooting features.

## Scope Estimate

**Large** - likely a milestone-level feature spanning core schema, send pipeline capture, retention policy, authorization, admin UI, and threat modeling.

## Breadcrumbs

- `lib/mailglass/outbound.ex` - likely send-path capture seam.
- `lib/mailglass/outbound/delivery.ex` - delivery record schema to link snapshots.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` - operator detail surface where snapshots could appear.
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` - existing default-redacted raw evidence/reveal capability pattern.
- `mailglass_admin/lib/mailglass_admin/components.ex` - `mask_recipient/1` PII minimization primitive.
- Provider examples:
  - Postmark Messages API: https://postmarkapp.com/developer/api/messages-api
  - Postmark content retention: https://postmarkapp.com/support/article/can-i-hide-or-turn-off-saving-of-message-content-in-my-activity-page
  - SendGrid content policy: https://support.sendgrid.com/hc/en-us/articles/18961023703963-How-to-Find-the-Body-or-Contents-of-Emails
  - Mailgun stored messages: https://documentation.mailgun.com/docs/mailgun/user-manual/receive-forward-store/view-stored-messages
  - Resend sent email management: https://resend.com/docs/dashboard/emails/introduction
  - Amazon SES email archiving: https://docs.aws.amazon.com/ses/latest/dg/eb-archiving.html

## Notes

Recommended direction: Mailglass-owned, append-only, opt-in send-time snapshot rather than relying only on provider history. Store normalized render artifacts such as headers, subject, text body, HTML body, rendering metadata, and provider IDs with tenant-scoped retention and explicit reveal authorization.

Open questions for the milestone:

- Should raw MIME be stored, normalized parts, or both?
- How should attachments and inline images be referenced without bloating the database?
- Should snapshots be encrypted at rest through a configurable application callback?
- What redaction defaults should apply to subject, recipients, bodies, and custom headers?
- How long should default retention be, and should deletion be hard-delete or tombstone?
- Should provider-native retrieval be integrated as secondary evidence when available?
