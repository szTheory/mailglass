# Phase 69: Click - Context

**Gathered:** 2026-06-01 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the demo app click-around UX and short documentation for the existing
`reference/demo_app`. This phase covers a dashboard that links to Mailglass
preview, outbound operator, and inbound operator surfaces, plus quickstart docs
that explain the Northstar Ops persona, job-to-be-done, seeded data, and what to
click.

This phase covers DEMO-03 and DX-03. It must not turn `reference/host_app` into
the rich demo, add new stable Mailglass public APIs, build a hosted demo
service, add production auth/account management, broaden the provider matrix, or
pull Phase 70 browser evidence/screenshot/checkpoint work into this UX/docs
slice.
</domain>

<decisions>
## Implementation Decisions

### Dashboard Scope
- **D-01:** Refine the existing `MailglassDemoWeb.PageController.home/2`
  dashboard into the click-around hub instead of introducing a new LiveView or
  duplicating MailglassAdmin screens.
- **D-02:** Keep the dashboard as demo-app glue under `MailglassDemoWeb`; do not
  move dashboard behavior into `mailglass`, `mailglass_admin`, or
  `mailglass_inbound`.
- **D-03:** The dashboard should summarize the deterministic Northstar corpus
  and guide users into real preview/operator surfaces. It is a hub, not a second
  admin implementation.

### Navigation And Auth
- **D-04:** Keep dashboard links pointed at real mounted Mailglass surfaces:
  `/dev/mail`, `/demo/login?return_to=/ops/mail?tenant_id=northstar`, and
  `/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar`.
- **D-05:** Preserve the simple demo-only login/session glue and safe
  `return_to` filtering. Do not add production auth/account management.
- **D-06:** Keep reset controls explicitly destructive and demo-only. The reset
  path may stay on the dashboard, but copy must make clear that it truncates and
  reseeds deterministic demo evidence tables.

### Docs Shape
- **D-07:** Use `reference/demo_app/README.md` as the canonical short
  quickstart and "what to click" guide.
- **D-08:** Keep root README references brief and directional if they need
  cleanup. Avoid scattering canonical demo truth across root, admin, and demo
  docs.
- **D-09:** Docs must explain the persona/JTBD, seeded outbound and inbound data,
  preview scenarios, reset behavior, Compose quickstart, dependency mode, and
  the demo-vs-contract boundary.

### UX Copy And Visual Polish
- **D-10:** Make the dashboard more guided and inspectable while keeping it
  calm, operator-focused, and evidence-first.
- **D-11:** Use Mailglass domain language consistently: preview, mailable,
  delivery, event, suppression, inbound record, evidence, routing trace, replay,
  tenant.
- **D-12:** Avoid marketing-page gloss, production-app account UI, analytics
  dashboards, and claims that demo routes, selectors, copy, screenshots, or DOM
  shape are stable public API.

### Verification Boundary
- **D-13:** Add focused Phase 69 verification around controller output, safe
  links, docs content, reset wording, and dashboard route coverage.
- **D-14:** Full Playwright journey expansion, screenshots, deterministic
  browser checkpoints, and `demo_browser_evidence.v1` artifact hardening remain
  Phase 70 work.
- **D-15:** Browser tests may remain as smoke seeds if already present, but Phase
  69 should not depend on private MailglassAdmin DOM shape as the stable proof
  of DEMO-03/DX-03.

### the agent's Discretion
- Exact dashboard layout and copy, provided it stays responsive, readable, and
  operator-focused.
- Whether dashboard verification is implemented as controller tests, static
  source assertions, or a small phase verifier, provided DEMO-03 and DX-03 are
  directly covered.
- Whether root README gets a minor pointer refresh, provided the demo README
  remains canonical.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 69 goal and v1.5 phase sequencing.
- `.planning/REQUIREMENTS.md` - DEMO-03, DX-03, evidence requirements deferred
  to Phase 70, and out-of-scope boundaries.
- `.planning/PROJECT.md` - v1.5 milestone intent and Mailglass core value.
- `.planning/STATE.md` - current milestone position and prior decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface, and
  recommendation-first lenses.
- `.planning/phases/67-demo-app-foundation/67-CONTEXT.md` - locked dashboard,
  route, auth, reset, Compose, evidence-boundary, and UI/copy direction.
- `.planning/phases/68-realistic-b2b-saas-fixtures/68-CONTEXT.md` - locked
  Northstar fixture corpus, preview scenarios, inbound/outbound story, and
  Phase 69 handoff.

### Demo App UX And Docs
- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` -
  current dashboard, login, reset, healthcheck, and evidence reset controller.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - dashboard, preview,
  operator, inbound ingress, and demo reset route mounts.
- `reference/demo_app/README.md` - canonical demo quickstart, persona/JTBD,
  seeded data, reset, dependency mode, and demo-vs-contract boundary.
- `README.md` - root-level demo pointer that may need drift cleanup.
- `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs`
  - existing safe redirect and evidence reset token coverage.
- `reference/demo_app/assets/e2e/demo.spec.js` - current browser smoke seed and
  Phase 70 handoff context.

### Demo Data And Scenarios
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - deterministic Northstar
  summary/reset data used by the dashboard.
- `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` - fixture
  determinism and named scenario coverage.
- `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` -
  account invite and magic-link preview scenarios.
- `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` -
  receipt and payment-failure preview scenarios.
- `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` -
  usage alert and incident preview scenarios.

No external specs are required for this phase beyond the project and package
contracts listed above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `reference/demo_app` already has a dashboard implemented in
  `PageController.home/2`, with dynamic counts from `DemoData.summary/0`.
- The demo already mounts `/dev/mail`, `/ops/mail`, and `/ops/mail/inbound`
  through public MailglassAdmin router seams.
- Demo-only login, safe operator redirect filtering, destructive reset, and
  token-gated evidence reset already exist.
- `reference/demo_app/README.md` already contains a short quickstart,
  persona/JTBD, reset command, dependency mode, and evidence boundary wording.
- Phase 68 completed a realistic Northstar corpus that Phase 69 can describe
  and route users through.

### Established Patterns
- Demo code stays under `MailglassDemo*` and uses package public seams only.
- `reference/host_app` remains the narrow trust-proof artifact; rich click-around
  proof belongs in `reference/demo_app`.
- Mailglass examples and docs should be honest adoption evidence, not expanded
  compatibility or public API guarantees.
- Browser evidence and screenshots should be deterministic and bounded in claim
  language, but Phase 70 owns the full evidence gate.

### Integration Points
- Dashboard cards should continue linking into actual mounted preview and
  operator surfaces rather than wrapping or reimplementing them.
- Dashboard counts and story labels should derive from or stay aligned with the
  deterministic `DemoData` corpus.
- Docs should align with Compose startup in `compose.demo.yml`, reset semantics
  in `mix demo.reset`, and current package dependency mode in
  `reference/demo_app/mix.exs`.
- Any Phase 69 route/link changes should preserve the Phase 70 browser smoke
  seed and its future expansion path.
</code_context>

<specifics>
## Specific Ideas

- Keep the primary click path:
  1. Start demo stack with `docker compose -f compose.demo.yml up demo`.
  2. Open `http://localhost:4015`.
  3. Inspect preview mailables at `/dev/mail`.
  4. Open outbound operator for tenant `northstar`.
  5. Open inbound operator for tenant `northstar`.
  6. Reset deterministic data when needed.
- Consider showing named scenarios on the dashboard, such as invite/auth,
  receipt/payment failure, usage alert, support reply, bounce/reject/no-match,
  suppression, and replay.
- Keep route labels understandable to a fresh adopter: "Preview mailables",
  "Outbound operator", "Inbound operator", and "Reset seed data" are clearer
  than internal feature names.
- If docs mention browser evidence, frame it as Phase 70/future artifact
  boundary unless the implementation already provides a verified smoke command.
</specifics>

<deferred>
## Deferred Ideas

- Full Playwright coverage for preview, outbound operator, inbound operator,
  replay, screenshots, and checkpoints remains Phase 70.
- Published-Hex-only demo gate after the live `mailglass_inbound` `1.0.0`
  release remains FUTR-01.
- Provider-matrix demo breadth beyond representative seeded stories remains
  FUTR-02.
- Ecosystem integrations from `SEED-003` remain FUTR-03.

No reviewed todos were folded or deferred; `todo.match-phase 69` returned no
matches.
</deferred>
