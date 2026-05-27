---
seed_id: SEED-003
title: Ecosystem Integrations (High-Value Wins)
status: archived
updated: 2026-05-27T12:28:03Z
note: Deferred after v1.3 trust-proof planning convergence; retained as future reference only.
---

# Ecosystem Integrations (High-Value Wins)

**Domain:** Interoperability with sztheory ecosystem libraries
**Status:** Archived seed (deferred)

Mailglass is the premier email rendering and delivery substrate. Its biggest ecosystem wins come from separating its concerns from orchestration, while providing standard rendering artifacts for other libraries.

## 1. Chimeway (Workflow Orchestration)
*The Win:* Mailglass handles the "What/How", Chimeway handles the "When/Why".
*Integration points:*
- **First-class Adapter:** Provide a `Chimeway.Adapter.Mailglass` implementation where Chimeway delegates rendering to Mailglass's MJML engine and dispatch to its Swoosh wrapper.
- **Signal Normalization:** `mailglass_inbound` webhooks should have a clean normalization path into Chimeway's Signal engine to drive feedback loops (e.g., escalating to SMS/push if a Mailglass delivery bounces).
- **Idempotency & Deduplication:** Leverage Chimeway's persistent signal engine to guarantee that a Mailglass email is only dispatched once, even if the upstream event fires multiple times.
- **Telemetry Consumption:** Chimeway can natively consume `[:mailglass, :delivery, :stop]` telemetry events as a secondary, decoupled feedback loop.

## 2. Rindle (Media Lifecycle)
*The Win:* Painless, secure email attachments and inline images.
*Integration points:*
- **Direct Attachment Pipeline:** A blueprint for attaching durable media from Rindle directly to Mailglass emails (e.g., fetching signed URLs or raw binary from Rindle and mapping it to Swoosh attachments).
- **Streamed/Chunked Loading:** When attaching large files, stream binary chunks from Rindle directly to Mailglass/Swoosh using `Enumerable` to maintain a low memory footprint.
- **CID Mapping:** Seamless integration for embedding Rindle assets as inline images (Content-ID mapping) within Mailglass templates.

## 3. Rendro (PDF Generation)
*The Win:* Sending physical artifacts with shared UI primitives.
*Integration points:*
- **Standardized Pipeline:** Provide a standard pattern for generating a PDF with Rendro (e.g., a monthly statement) and immediately piping that output into a Mailglass attachment struct.
- **Shared Component Ecosystem:** Share Tailwind configurations and component primitives between Mailglass and Rendro so invoices look identical in the email body as they do in the physical PDF.
- **Parallel Oban Rendering:** Define a synergistic background job pattern where heavy PDF generation in Rendro does not block email prep; instead, Chimeway/Oban defers Mailglass dispatch until the Rendro artifact is ready.

## 4. Threadline (Audit Platform)
*The Win:* Operator transparency & compliance for outbound communication.
*Integration points:*
- **Ledgering Outcomes:** Sink terminal delivery outcomes (delivered, bounced, blocked) from `mailglass_inbound` straight into Threadline, linked directly to the user's actor ID.
- **Support UI Synergy:** Deeply integrate Threadline's context into the Mailglass admin dashboard, allowing support operators to see the entire communication history and actor intent in a unified audit ledger.

## 5. Accrue (Billing / Multi-Tenancy)
*The Win:* Metered billing and plan limits for outbound emails.
*Integration points:*
- **Usage Metering:** Hook Mailglass delivery telemetry into Accrue to decrement email quotas on a per-tenant basis.
- **Delinquency Gating:** Enable a pattern where Mailglass checks Accrue tenant status to gate non-critical marketing emails while permitting transactional/password-reset emails to flow through.