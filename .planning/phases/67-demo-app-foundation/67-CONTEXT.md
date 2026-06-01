# Phase 67: Demo App Foundation - Context

**Gathered:** 2026-06-01 (assumptions mode + subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Create and harden the foundation for a separate realistic B2B SaaS Ops demo app
at `reference/demo_app`, with dual dependency mode and one-command Docker Compose
DX.

This phase covers DEMO-01, DEMO-02, DX-01, and DX-02. It must not turn
`reference/host_app` into the rich demo, add new stable Mailglass public APIs,
build a hosted demo service, add production auth/account management, broaden the
provider matrix, or absorb Phase 68-70 work beyond the foundation needed for
those later phases.
</domain>

<decisions>
## Implementation Decisions

### Demo App Boundary
- **D-01:** Keep `reference/demo_app` as the rich click-around demo app and keep
  `reference/host_app` as the narrow v1.3 trust-proof host. The demo proves
  adoption confidence; it is not a new product surface and not contract truth.
- **D-02:** The demo app should be an ordinary Phoenix app with its own
  `mix.exs`, config, Repo, Endpoint, Router, migrations, seeds, assets, and
  Dockerfile. Do not move it into an umbrella or package internals for Phase 67.
- **D-03:** Demo integration must use public seams only: Mailglass delivery,
  MailglassAdmin router/auth mounts, and MailglassInbound ingress/router/mailbox
  seams. Demo-only glue belongs under `MailglassDemo*`, not under package source.

### Dependency Mode
- **D-04:** Preserve dual dependency mode: local path dependencies by default
  for maintainer iteration, and `MAILGLASS_DEMO_DEPS=hex` for published-package
  smoke/adopter-proof checks.
- **D-05:** Published-Hex mode must be explicit, documented, and verified
  against the actual release line. Phase 67 planning should check whether the
  current `mailglass_inbound` Hex constraint still intentionally targets `~> 0.3`
  or should move after the inbound `1.0.0` release ceremony.
- **D-06:** Do not introduce new public configuration APIs for this mode. The
  dependency switch is demo-app wiring, not a Mailglass feature.

### Docker Compose DX
- **D-07:** Treat `compose.demo.yml` as the canonical local click-around entry:
  `docker compose -f compose.demo.yml up --build demo`.
- **D-08:** Keep the Compose shape as three concerns: Postgres, Phoenix demo app,
  and separate browser evidence runner. This mirrors real adopter usage and keeps
  browser automation independent of Phoenix process ownership.
- **D-09:** Preserve cache-aware named volumes for Postgres, Mix, Hex, npm,
  Playwright browsers, package `deps`, and package `_build` directories. This is
  a feature of the DX, not incidental Compose clutter.
- **D-10:** Planning should add a Phoenix readiness/healthcheck path and make the
  evidence runner wait for `service_healthy`, not only `service_started`.
- **D-11:** Planning should switch demo browser dependency installation to
  lockfile-respecting `npm ci` and ensure browser system dependencies are
  deterministic, either by installing Playwright deps in the image or by using a
  Playwright-ready evidence image.
- **D-12:** Planning should keep a future clean/no-cache evidence lane in view so
  cache volumes do not mask clean-checkout failures. The interactive DX can be
  cached; release/evidence proof should still have a clean path.

### Setup And Reset Semantics
- **D-13:** Keep idiomatic Phoenix/Ecto aliases: `setup`, `ecto.setup`, and
  `ecto.reset`.
- **D-14:** Keep a demo-specific deterministic reset command (`mix demo.reset`)
  that truncates demo Mailglass tables, restarts identities, and reseeds fixed
  data without rebuilding the schema. This is the fast click-around reset path.
- **D-15:** Make reset wording unmistakably destructive in docs and any UI copy.
  It should be friendly, but never imply that seeded demo data is preserved.
- **D-16:** Browser evidence should reset deterministically before it asserts
  journeys. Prefer a demo/test-only reset endpoint modeled after existing admin
  browser support, or run `mix demo.reset` from the evidence container against
  the same database.

### Router, Auth, And Surface Shape
- **D-17:** Keep the current three-surface model: dashboard/login/reset in the
  browser scope, preview under `/dev/mail`, and operator workflows under
  `/ops/mail`.
- **D-18:** Demo operator login/session glue should stay intentionally simple and
  demo-only. Do not build production auth/account management in this milestone.
- **D-19:** Keep inbound provider examples as seeded evidence and public ingress
  configuration, not as public provider-module contracts.

### Evidence Handoff
- **D-20:** Phase 67 should prepare, but not fully implement, Phase 70 browser
  evidence. The foundation should define reliable startup/reset/artifact paths.
- **D-21:** Browser artifacts should use bounded claim language and deterministic
  schema/versioning, for example `demo_browser_evidence.v1`, parallel in spirit
  to the existing preview capture/checkpoint contract.
- **D-22:** Future screenshots/checkpoints prove demo journeys and adoption
  confidence; they do not make DOM shape, demo routes, selectors, or demo copy
  stable public API.

### UI And Copy Direction
- **D-23:** The demo should feel like a mail console/operator lab bench: calm,
  inspectable, and evidence-first. Avoid marketing-page gloss, analytics-casino
  dashboards, and feature hype.
- **D-24:** Use Mailglass language consistently: preview, delivery, event,
  suppression, inbound record, evidence, routing trace, replay, and tenant.
  Prefer clear recovery-oriented copy over clever labels.

### the agent's Discretion
- Exact healthcheck route name, reset endpoint shape, and evidence artifact
  schema fields, as long as they remain demo-only and deterministic.
- Whether browser system dependencies live in the demo Dockerfile or a dedicated
  evidence image, as long as the path is reproducible and easy to run.
- Exact phase-67 verification command shape, but prefer a focused
  `verify.phase67`-style proof over a kitchen-sink verifier.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 67 goal and v1.5 phase sequencing.
- `.planning/REQUIREMENTS.md` - DEMO-01, DEMO-02, DX-01, DX-02 and out-of-scope
  boundaries.
- `.planning/PROJECT.md` - v1.5 milestone intent and Mailglass core value.
- `.planning/STATE.md` - current milestone position and convergence posture.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface, and
  recommendation-first lenses.

### Existing Demo Foundation
- `reference/demo_app/mix.exs` - demo dependency-mode switch and setup/reset
  aliases.
- `reference/demo_app/README.md` - quickstart, URLs, dependency mode, persona,
  and demo-vs-contract boundary.
- `compose.demo.yml` - canonical Compose stack and cache volume topology.
- `reference/demo_app/Dockerfile` - demo container base and setup command.
- `reference/demo_app/config/config.exs` - Mailglass/MailglassAdmin/
  MailglassInbound demo configuration.
- `reference/demo_app/config/dev.exs` - container-friendly endpoint and database
  config.
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - preview/operator/
  inbound route mounts.
- `reference/demo_app/lib/mailglass_demo_web/admin_auth.ex` - demo-only admin
  auth behaviour.
- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` -
  dashboard/login/reset surface.
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - deterministic seed/reset
  implementation.
- `reference/demo_app/assets/playwright.config.cjs` and
  `reference/demo_app/assets/e2e/demo.spec.js` - current browser evidence seed.

### Boundary And Evidence Precedents
- `reference/host_app/SCOPE.md` - narrow trust-host boundary that must not be
  collapsed into the demo.
- `.planning/milestones/v1.3-phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md`
  - public-seam-only maintained host precedent.
- `.planning/milestones/v1.3-phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md`
  - deterministic runner/checkpoint precedent.
- `.planning/milestones/v1.3-phases/59-ci-trust-lanes-checkpoint-evidence/59-CONTEXT.md`
  - required evidence-lane and artifact-contract precedent.
- `.planning/phases/999.2-shift-left-email-screenshot-responsive-preview-workflow-backlog/999.2-CONTEXT.md`
  - bounded screenshot/preview evidence precedent.
- `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex` - existing
  deterministic manifest/checkpoint style to learn from without coupling demo
  code to maintainer-only internals.
- `scripts/check_preview_capture_checkpoint.sh` - executable checkpoint
  validation precedent.
- `mailglass_admin/playwright.config.cjs` and
  `mailglass_admin/test/support/endpoint_case.ex` - existing browser readiness
  and reset patterns.

### Prompt Corpus Applied
- `prompts/Phoenix needs an email framework not another mailer.md` - Mailglass
  thesis, preview/admin dashboard advantage, DX targets, and scope warnings.
- `prompts/mailglass-engineering-dna-from-prior-libs.md` - prior-library DNA:
  example host apps, Playwright proof, doc contracts, and phase verification.
- `prompts/mailglass-brand-book.md` - calm, inspectable UI/copy guidance.
- `prompts/phoenix-best-practices-deep-research.md` - generated Phoenix shape,
  contexts, thin web layer, and component guidance.
- `prompts/elixir-best-practices-deep-research.md` - explicit API/return-shape,
  boundary validation, and process-use rules.
- `prompts/ecto-best-practices-deep-research.md` - Repo/schema/query/changeset
  separation and transaction/database-truth posture.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
  - container/runtime config, Postgres truth, and Plug/Phoenix edge guidance.
- `prompts/mailer-domain-language-deep-research.md` - preview, mailable,
  delivery, evidence, and aggregate language.

### External Ecosystem Research
- Phoenix Mix task docs - generated Phoenix apps commonly expose application
  aliases such as `ecto.setup` and `ecto.reset`.
- Rails engine docs - mountable engines are tested through a cut-down dummy host
  app, validating the host-app proof pattern.
- Rails Action Mailbox docs - local conductor/inbound development UI is a strong
  precedent for inspectable inbound evidence.
- Django reusable app docs - reusable apps need clear quickstart and packaging
  boundaries.
- Docker Compose volume docs - named volumes are the right mechanism for
  managed persistent caches/data.
- Playwright CI docs - browser automation should install dependencies
  deterministically, use the official image or CLI install path, and prefer
  stable workers in CI.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `reference/demo_app` already exists and already satisfies much of the intended
  foundation: separate Phoenix app, Mailglass config, admin/preview/operator
  mounts, demo-only auth, deterministic data, Dockerfile, README, and browser
  test seed.
- `compose.demo.yml` already provides the right high-level shape and most cache
  volumes needed for fast local iteration.
- `MailglassDemo.DemoData.reset!/0` already gives deterministic reset over
  outbound deliveries/events/webhook events/suppressions and inbound records/
  evidence/execution runs.
- Existing admin preview capture and trust-runner artifacts provide the schema,
  bounded-claim, and validator pattern for later demo evidence.

### Established Patterns
- Public guarantee truth lives in `api_stability.md` inventories and executable
  stability checks, not in examples, screenshots, or demo DOM.
- Phoenix code should preserve generated app shape: app/domain modules under the
  app namespace, web concerns under `*_web`, thin controllers/LiveViews, and
  context/domain functions for behavior.
- Mailglass evidence should be deterministic, machine-readable where possible,
  and honest about what it proves.
- The repo has a strong phase-verification culture; Phase 67 should get focused
  proof rather than a broad verifier.

### Integration Points
- Demo Compose startup should integrate with Postgres health and a new Phoenix
  readiness check.
- Browser evidence should integrate with deterministic reset and artifact output
  paths that Phase 70 can harden.
- Hex dependency mode should integrate with release-line truth after the inbound
  `1.0.0` ceremony.
- Dashboard links should continue routing into real MailglassAdmin preview and
  operator surfaces rather than duplicate those surfaces in demo code.
</code_context>

<specifics>
## Specific Ideas

- Recommended interactive command:
  `docker compose -f compose.demo.yml up --build demo`
- Recommended evidence command:
  `docker compose -f compose.demo.yml up --build --abort-on-container-exit --exit-code-from demo_e2e demo_e2e`
- Recommended Phase 67 planning checks:
  - Demo app boots through Compose.
  - `/` readiness/dashboard path returns after database setup.
  - `/dev/mail` preview path is reachable.
  - `/ops/mail` and `/ops/mail/inbound` are reachable through demo login.
  - `mix demo.reset` is deterministic and documented as destructive.
  - Hex dependency mode resolves to intended release-line packages.
  - Browser dependency install is lockfile-based and reproducible.
- Recommended Phase 70 handoff:
  `reference/demo_app/tmp/browser_evidence/manifest.json`,
  `checkpoint.json`, screenshots, and Playwright report/test-results paths with
  bounded claim text.

The user asked for a one-shot recommendation set, not a menu of choices. The
coherent recommendation is: keep the current architecture, harden the DX
contract, fix readiness/reset/reproducibility footguns, and explicitly prevent
demo evidence from becoming public API contract.
</specifics>

<deferred>
## Deferred Ideas

- Rich seeded B2B SaaS scenarios are Phase 68.
- Dashboard polish, persona/JTBD docs, quickstart expansion, and click-around
  UX depth are Phase 69.
- Full Playwright screenshot/checkpoint gate and responsive browser evidence are
  Phase 70.
- Published-Hex-only demo gate remains FUTR-01 until the live
  `mailglass_inbound` `1.0.0` release exists.
- Provider-matrix broadening remains FUTR-02.
- Ecosystem integrations remain FUTR-03 and should not be pulled into Phase 67.

### Reviewed Todos

None - no pending todos matched Phase 67.
</deferred>

---

*Phase: 67-demo-app-foundation*
*Context gathered: 2026-06-01*
