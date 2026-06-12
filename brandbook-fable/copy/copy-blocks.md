# mailglass copy blocks

Paste-ready copy for each launch surface, in the maintainer's voice: clear,
exact, confident without being cocky. Every package name, version pin, mix
task, and capability below is checked against the shipped code — if you
change a claim, re-check it the same way.

## GitHub About

> Batteries-included transactional email framework for Phoenix. Composes on Swoosh; adds HEEx components, a LiveView preview dashboard, normalized webhook events, suppression lists, RFC 8058 one-click unsubscribe, and an append-only event ledger.

## Hex.pm description

Transactional email framework for Phoenix. Composes on Swoosh

This is the `description` string shipped in `mix.exs` — short on purpose,
because Hex search results truncate aggressively. The longer pitch belongs
in the README and the HexDocs intro.

## HexDocs intro

mailglass is a batteries-included transactional email framework for Phoenix.
It composes on top of Swoosh — you keep your Swoosh adapter — and ships the
framework layer above the transport: HEEx-native mailables with Outlook
fallbacks, a LiveView preview dashboard, provider-normalized webhook events,
suppression lists, RFC 8058 List-Unsubscribe with signed tokens,
multi-tenant routing, and an append-only event ledger. Start with
`mix mailglass.install`, then preview your first Mailable before you send it.

## Landing hero

**Headline:** Transactional email for Phoenix, made visible.

**Subhead:** mailglass composes on Swoosh and ships the framework layer teams rebuild by hand: HEEx-native components, a LiveView preview dashboard, normalized webhook events, suppression lists, and an append-only event ledger.

## Feature blurbs

**Preview before you send** — Every Mailable renders in a dev dashboard: device widths, dark mode, HTML, text, raw source, and headers, with live-editable assigns.

**One event vocabulary** — Provider webhooks normalize into a single stream — queued, sent, bounced, deferred, delivered, complained — the same names whichever provider reported them.

**Suppressions that hold** — Hard bounces and complaints project Suppression records automatically. A suppressed recipient is blocked before dispatch, and the error names the cause.

**One-click unsubscribe** — RFC 8058 List-Unsubscribe headers with signed tokens — the unsubscribe mechanics inbox providers now expect, generated for you.

**An audit trail you can trust** — Deliveries and Events land in an append-only Postgres ledger. A trigger raises on UPDATE or DELETE — history is evidence, not state.

**Deliverability, diagnosed** — `mix mail.doctor` checks SPF, DKIM, DMARC, MX, and BIMI against DNS, and answers cannot_verify when DNS alone cannot prove a claim.

## Calls to action

**Primary:** Install mailglass

**Secondary:** Read the guides

Use the primary verb-first and unadorned. Never "Get started today",
never "Try it free" — there is nothing to try; it is a library, and it is MIT.

## Launch post

mailglass is on Hex: a transactional email framework for Phoenix that
composes on Swoosh instead of replacing it. Define a Mailable, preview it in
dev, send it, and watch the Delivery's Events arrive — bounces project
Suppressions automatically.

Docs and source: [link]

## Release notes template

Structure every release note as three parts, in this order:

1. **What changed** — declarative present tense, the feature first, no
   adjectives doing the work facts should do.
2. **Why it matters** — one or two sentences naming the job it serves.
3. **Upgrade note** — second person, imperative, only if action is needed.
   If nothing is needed, say "No changes required."

One filled example, from a real release:

> **`mix mail.doctor` gains `--format json`.** The doctor now emits a
> machine-readable result with `schema_version: 1`, so CI and dashboards can
> consume the same SPF, DKIM, DMARC, MX, and BIMI checks you run by hand.
> No changes required — the human-readable output is unchanged by default.
