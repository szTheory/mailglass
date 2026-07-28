# Learning Path

This guide sequences the first week with mailglass. Work through the steps in order — each one
builds on the previous. The guides linked here are the same ones you will keep returning to as
your integration matures.

## Week 1 arc

- **[Getting started](getting-started.md)** — Install the library, configure your adapter, mount
  the preview and webhook routes, and send your first message.

- **[What you can do with mailglass](jobs.md)** — A job-by-job map of the ten things mailglass
  is built to handle, from auth sends to suppression management. Read this once to see the full
  scope, then return when a specific job comes up.

- **[How mailglass works](architecture.md)** — Build the system-level mental model: follow an
  outbound message and its provider evidence through rendering, persistence, webhooks,
  projections, and suppressions, then learn where to start reading the code.

- **[Mailglass code walkthrough](code-walkthrough.md)** — Put real functions behind that
  architecture: trace a Message through rendering, durable dispatch, Swoosh transport,
  projection, webhook ingest, and the tests that expose the design.

- **[Authoring mailables](authoring-mailables.md)** — Define message builders using
  `Mailglass.Mailable`. Covers the builder API, HTML and text bodies, subject lines, from/to
  setters, and how to attach metadata for event correlation.

- **[Preview](preview.md)** — Use the dev dashboard to render and inspect your mailables before
  they reach a provider. The preview runs your production render pipeline, so what you see
  matches what gets sent.

- **[Webhooks](webhooks.md)** — Mount webhook ingest, verify provider signatures, and handle
  the normalized event taxonomy. Covers Postmark, SendGrid, and Mailgun first-party verifiers.

- **[Testing](testing.md)** — Test your mailables with the Fake adapter. Covers
  `Mailglass.Adapters.Fake`, `Mailglass.TestAssertions`, and the cross-process, Oban, and PubSub
  test lanes.

- **[Telemetry and operating](telemetry.md)** — Attach handlers to the structured telemetry
  events mailglass emits for rendering, dispatch, and webhook ingest. Understand what each event
  carries so you can build dashboards and alerts.

## Going deeper

Once the week-1 arc is solid, these guides cover the next layer:

- **[Multi-tenancy](multi-tenancy.md)** — Route mail through per-tenant adapters using the
  `Mailglass.Tenancy` behaviour and `adapter_ref` configuration.

- **[DKIM setup](dkim-setup.md)** — Configure DKIM signing through your ESP for improved
  deliverability.

- **[List-Unsubscribe](unsubscribe.md)** — Add RFC 8058 `List-Unsubscribe` headers and wire
  suppression callbacks.

- **[Migrating from Swoosh](migration-from-swoosh.md)** — Adopt mailglass alongside an existing
  raw-Swoosh integration using the incremental-adoption mechanics.
