# Phase 68: Realistic B2B SaaS Fixtures - Context

**Gathered:** 2026-06-01 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Build realistic deterministic B2B SaaS Ops fixtures for the existing
`reference/demo_app`. This phase covers resettable seeded data for outbound
deliveries, timeline events, suppressions, replayable webhook targets, inbound
records, inbound evidence, routing outcomes, replay lineage, no-match cases, and
realistic preview mailables.

This phase covers DATA-01, DATA-02, DATA-03, and DATA-04. It must not turn
`reference/host_app` into the rich demo, add new stable Mailglass public APIs,
build a hosted demo service, add production auth/account management, broaden the
provider matrix, or pull Phase 69 dashboard/docs or Phase 70 browser evidence
work into this fixture slice.
</domain>

<decisions>
## Implementation Decisions

### Fixture Scope
- **D-01:** Expand the existing `MailglassDemo.DemoData` seed/reset path rather
  than replacing it with a separate fixture framework. The phase should deepen
  the deterministic corpus already used by `mix demo.reset`.
- **D-02:** Keep the destructive fast reset command as the canonical maintainer
  reset path for this phase: `mix demo.reset`, backed by `priv/repo/seeds.exs`.
  Reset must truncate the demo Mailglass tables, restart identities, and reseed
  fixed data without rebuilding the schema.
- **D-03:** Keep fixture implementation under the demo app namespace. Demo-only
  data helpers belong under `MailglassDemo*`, not under `lib/mailglass*`,
  `mailglass_admin`, or `mailglass_inbound`.

### Scenario Corpus
- **D-04:** Deepen the existing Northstar Ops story instead of broadening into a
  provider matrix. The demo should feel like one coherent B2B SaaS operations
  workspace with believable invite/auth, billing, usage, support, bounce,
  suppression, webhook replay, inbound replay, and no-match stories.
- **D-05:** Seed outbound data with realistic delivery state variety: successful
  invite/auth and receipt cases, operational alert/bounce or failure cases,
  suppression-linked cases, and replayable webhook evidence that operator
  surfaces can inspect later.
- **D-06:** Seed inbound data with realistic stored truth: support replies,
  provider evidence, routing outcomes, fresh execution, replay execution, and at
  least one intentional no-match case. Include enough metadata for operator
  surfaces to explain why each record exists.
- **D-07:** Do not treat Phase 68 as provider breadth work. Representative
  provider labels are fine when they make scenarios concrete, but broad
  provider-matrix coverage remains deferred by v1.5 requirements.

### Mailables
- **D-08:** Keep demo mailables under `MailglassDemoWeb.Mailers.*` and use only
  public `Mailglass.Mailable` / `Mailglass.Message` APIs.
- **D-09:** Preserve and enrich the current preview scenario families:
  account invite/auth, billing receipt/payment, and operations usage/incident
  mail. Preview props should be deterministic and realistic enough for Phase 70
  browser evidence to assert rendered scenario identity without relying on
  private DOM shape.
- **D-10:** Mailer examples should read like B2B SaaS operational email, not
  marketing campaigns. Keep copy calm, concrete, and tied to the operator
  evidence story.

### Inbound And Replay Semantics
- **D-11:** Seed inbound truth directly through the package-owned inbound record,
  evidence, and execution-run insertion helpers already used by the demo app.
  Preserve stored-truth semantics: replay rows describe processing stored
  evidence, not a fresh provider receive.
- **D-12:** Preserve explicit fresh versus replay execution lineage. Inbound
  records that are replayed should have both original `:fresh` and subsequent
  `:replay` execution rows where appropriate.
- **D-13:** Keep no-match and rejection/bounce-style examples within existing
  inbound routing/mailbox semantics. Do not add new public router or mailbox
  API just to support fixtures.

### Verification
- **D-14:** Add focused deterministic seed/reset tests for Phase 68: row counts,
  stable provider/message IDs, stable event/outcome sets, suppression linkage,
  inbound evidence/run coverage, and mailer preview scenario coverage.
- **D-15:** Verification should prove the fixture corpus is deterministic and
  complete for DATA-01..DATA-04. Browser journey proof, screenshots, and
  checkpoint artifacts remain Phase 70 work.
- **D-16:** Keep assertions at the demo data contract level. Do not assert
  MailglassAdmin DOM shape, LiveView internals, or private package module
  details as stable public API.

### the agent's Discretion
- Exact scenario names, counts, provider labels, timestamps, and metadata keys,
  as long as they are deterministic, realistic, and cover DATA-01..DATA-04.
- Whether to keep all fixture helpers in `DemoData` or split small private
  helper modules under `MailglassDemo`, provided the public reset surface stays
  simple.
- Exact test module organization, provided tests make fixture completeness and
  reset determinism clear.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 68 goal and v1.5 phase sequencing.
- `.planning/REQUIREMENTS.md` - DATA-01, DATA-02, DATA-03, DATA-04 and
  out-of-scope boundaries.
- `.planning/PROJECT.md` - v1.5 milestone intent and Mailglass core value.
- `.planning/STATE.md` - current milestone position and prior decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface, and
  recommendation-first lenses.
- `.planning/phases/67-demo-app-foundation/67-CONTEXT.md` - locked demo app
  boundary, reset semantics, public-seam-only integration, and evidence handoff.

### Existing Demo Fixture Surface
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - current deterministic
  reset and seed implementation for outbound, inbound, suppression, webhook, and
  replay rows.
- `reference/demo_app/priv/repo/seeds.exs` - seed entrypoint used by
  `mix demo.reset`.
- `reference/demo_app/mix.exs` - `setup`, `ecto.setup`, `ecto.reset`,
  `demo.reset`, and dependency-mode aliases.
- `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` - existing
  deterministic reset proof.
- `reference/demo_app/README.md` - current quickstart/reset wording and
  demo-vs-contract boundary.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - preview, operator,
  demo reset, and inbound ingress route mounts.

### Demo Mailers And Inbound Routing
- `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` -
  account invite and magic-link preview scenarios.
- `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` -
  receipt and payment-failure preview scenarios.
- `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` -
  usage alert and incident preview scenarios.
- `reference/demo_app/lib/mailglass_demo_web/inbound_router.ex` - demo inbound
  route examples.
- `reference/demo_app/lib/mailglass_demo_web/inbound/support_mailbox.ex` - demo
  mailbox outcome behavior.

### Package Schemas And Contracts
- `lib/mailglass/outbound/delivery.ex` - delivery status, stream, event-type,
  provider message ID, metadata, and idempotency shape.
- `lib/mailglass/events/event.ex` - append-only event ledger atom sets,
  metadata, normalized payload, and idempotency shape.
- `lib/mailglass/webhook/webhook_event.ex` - raw webhook evidence schema and
  replay/idempotency fields.
- `lib/mailglass/suppression/entry.ex` - suppression entry shape.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex` - insertion
  helpers used by the demo seed path.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` -
  canonical inbound record fields and suppression flag.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex`
  - stored provider evidence fields.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` -
  fresh/replay source and outcome validation semantics.

No external specs are required for this phase beyond the project and package
contracts listed above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `reference/demo_app` already exists as a separate Phoenix app and is the only
  target for this phase.
- `MailglassDemo.DemoData.reset!/0` already truncates and reseeds demo rows with
  fixed tenant `northstar` and fixed time `2026-06-01 15:00:00Z`.
- Current demo data already seeds three outbound deliveries, six events, one
  webhook event, one suppression, two inbound records, two inbound evidence
  rows, and three inbound execution rows.
- Current mailers already expose the preview scenario families required by
  DATA-04: invite/auth, receipt/payment, and operational alert/incident.
- `DemoDataResetTest` already proves repeatable reset behavior and identity
  restart; it can be extended into a stronger fixture contract test.

### Established Patterns
- Demo app glue uses public Mailglass seams and keeps demo code under
  `MailglassDemo*`.
- Mailglass evidence should be deterministic and bounded in claim language.
  Fixture data proves adoption confidence, not stable DOM/API guarantees.
- Package schemas prefer explicit closed atom sets and clear event/outcome
  semantics. Seed data should use valid existing states rather than inventing
  new statuses.
- Inbound replay semantics are stored-truth-first: replay means reprocessing the
  stored normalized record and evidence, not pretending a provider sent a new
  message.

### Integration Points
- `mix demo.reset` and `priv/repo/seeds.exs` are the reset entrypoints Phase 69
  dashboard reset controls and Phase 70 evidence setup will rely on.
- Admin preview surfaces consume mailer `preview_props`; Phase 68 should make
  those scenarios realistic enough for later browser evidence.
- Outbound operator surfaces consume `mailglass_deliveries`,
  `mailglass_events`, `mailglass_webhook_events`, and `mailglass_suppressions`.
- Inbound operator surfaces consume `mailglass_inbound_records`,
  `mailglass_inbound_evidence`, and `mailglass_inbound_replay_runs`.
</code_context>

<specifics>
## Specific Ideas

- Keep the primary tenant as `northstar`.
- Preserve deterministic timestamps around `2026-06-01 15:00:00Z`.
- Consider scenario IDs and metadata that are easy to recognize in operator
  views, such as `team_invite`, `magic_link`, `receipt_paid`,
  `payment_failed`, `usage_alert`, `support_reply`, `inbound_no_match`, and
  `stored_truth_replay`.
- Make fixture tests assert named scenarios rather than only raw counts, so a
  later accidental simplification cannot still pass with the same row totals.
- Keep reset warnings destructive and plain.
</specifics>

<deferred>
## Deferred Ideas

- Provider-matrix demo breadth beyond representative seeded stories remains
  deferred by FUTR-02.
- Published-Hex-only demo gate after the live `mailglass_inbound` `1.0.0`
  release remains FUTR-01.
- Click-around dashboard/navigation/docs are Phase 69.
- Playwright browser evidence, screenshots, and checkpoints are Phase 70.

No reviewed todos were folded or deferred; `todo.match-phase 68` returned no
matches.
</deferred>
