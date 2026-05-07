# Phase 34: Verification & Regression Closure - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining production-maturity verification gaps so maintainers can trust the support-critical release contract before `v1.0`.

This phase is about making the verification story honest, stable, and enforceable for the seams that matter most to operator support and regression prevention. It is not a general test-suite beautification pass, not a broad observability expansion, not a provider-live productization effort, and not a replay/reconcile redesign phase.

</domain>

<decisions>
## Implementation Decisions

### Verification gate shape
- **D-34-01:** Do not define Phase 34 success around one monolithic repo-root `mix test` claiming to verify the whole repo. That is the wrong abstraction for a sibling-package codebase.
- **D-34-02:** Keep package-local suites authoritative:
  - root `mix test` remains authoritative for `mailglass` core
  - `mailglass_admin` keeps its own authoritative suite(s)
  - any top-level verification entrypoint introduced in Phase 34 should be an honest orchestrator over those package-local authorities
- **D-34-03:** The `MAT-03` gate should be a dedicated required support-contract gate, not “every available test in both packages must pass.”
- **D-34-04:** The required Phase 34 verification contract should cover three buckets:
  - core support-contract regression bundle
  - admin/operator support-contract regression bundle
  - consumer-shape contract such as compile without optional deps
- **D-34-05:** Required support-contract jobs must be explicit, always-run, and non-vacuous. Avoid conditional/skipped required jobs and avoid tag-only gates that can pass with zero matching tests.

### Bootstrap reliability and trust semantics
- **D-34-06:** Workflow/test bootstrap reliability is the highest-risk seam in this phase because it determines whether maintainers can trust automation at all.
- **D-34-07:** Phase 34 should harden the verification entrypoints it declares authoritative. Broad repo-wide reruns that are still noisy or structurally broader than `MAT-03` may remain advisory, but they must not be mislabeled as the release gate.
- **D-34-08:** Do not centralize `mailglass` and `mailglass_admin` bootstrap lifecycle into one opaque global helper just to manufacture a fake root gate. Keep ownership local to each package’s `test_helper` / case-template structure.
- **D-34-09:** Do not paper over bootstrap instability with broad retry/rescue behavior that can hide real failures. Retry-based probes such as `CitextProbe` are acceptable only with clear honesty boundaries and package-local ownership.

### Advisory vs required lanes
- **D-34-10:** Keep real-provider / live-provider workflows advisory. Do not promote networked third-party provider lanes to required PR gates.
- **D-34-11:** Split the current advisory space into two clearer contracts:
  - deterministic provider-smoke / compatibility coverage that can be required if it does not depend on external network, secrets, or timing-sensitive provider behavior
  - true provider-live canary coverage that stays advisory on cron and `workflow_dispatch`
- **D-34-12:** If an advisory workflow duplicates required CI without adding meaningful signal, repurpose it into deterministic smoke/compatibility coverage or remove it. Avoid placebo advisory jobs.
- **D-34-13:** Advisory failures should remain triaged and visible, but advisory semantics must stay explicit: they are canaries and release evidence, not branch-protection truth.

### Support-truth contract priorities
- **D-34-14:** After verification-entrypoint trust, the next highest priority is the truthfulness contract around telemetry, support summaries, support docs, and support cards.
- **D-34-15:** Phase 34 should preserve and expand automated contract coverage that proves support surfaces say only what mailglass can actually know about delivery, replay, reconcile, and backlog state.
- **D-34-16:** Replay/reconcile should stay on a focused regression-retention track in this phase. Preserve the Phase 32 semantics and keep targeted regression coverage; do not broaden Phase 34 into new replay/reconcile product design.
- **D-34-17:** Provider/advisory workflow coverage belongs in this phase only as an explicit documented gate and signal posture, not as a new required merge blocker.

### Recommendation-first workflow posture
- **D-34-18:** Downstream Phase 34 research, planning, and implementation should be recommendation-first and one-shot by default:
  - research broadly
  - compare tradeoffs internally
  - return one cohesive recommendation set
  - avoid option sprawl
- **D-34-19:** Shift this posture left within GSD for this project: escalate only for very impactful choices the user is likely to care about directly.
- **D-34-20:** For this phase, “very impactful” means choices that materially change:
  - public verification/release contract
  - user trust semantics or overclaim/underclaim risk
  - branch-protection or CI required-check posture
  - tenant/privacy/security boundaries
  - long-term maintainer burden in a significant way

### the agent's Discretion
- Exact workflow/job names, mix aliases, and script locations for the support-contract gate.
- Exact composition of the core/admin targeted regression bundles, as long as they remain support-critical, explicit, and non-vacuous.
- Exact docs wording that clarifies required vs advisory verification posture.
- Exact file/module placement for any verification orchestrator or helper introduced in this phase.

</decisions>

<specifics>
## Specific Ideas

- The Phase 34 recommendation set should feel like one coherent verification philosophy, not a pile of unrelated test fixes.
- The desired maintainer experience is:
  - one honest top-level verification entrypoint
  - package-local truth underneath it
  - explicit required vs advisory semantics
  - no false green from skipped or vacuous jobs
  - no flaky required dependence on external provider health
- The desired user/project-owner experience is:
  - fewer questions
  - more one-shot recommendations
  - escalation only for truly high-impact decisions
- Strong ecosystem priors to borrow from:
  - Elixir/Phoenix/Ecto package-local test ownership and explicit CI job separation
  - deterministic fake/sandbox/provider-contract tests as required gates
  - live-provider or service-backed lanes as canaries, not merge blockers
  - webhook/operator tooling that prioritizes truthfulness and recoverability over broad UI surface area

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project posture
- `.planning/ROADMAP.md` — Phase 34 goal, success criteria, and milestone position.
- `.planning/PROJECT.md` — production-maturity framing, fake-adapter gate philosophy, advisory live-provider posture, and maintainer constraints.
- `.planning/REQUIREMENTS.md` — `MAT-03` requirement definition.
- `.planning/STATE.md` — current phase position and deferred root-bootstrap note.
- `.planning/METHODOLOGY.md` — decisive-by-default and recommendation-first project posture, including the stronger “shift this left” guidance.

### Prior locked context constraining this phase
- `.planning/phases/32-replay-reconcile-hardening/32-CONTEXT.md` — replay/reconcile semantics already locked; Phase 34 should retain, not redesign, them.
- `.planning/phases/32-replay-reconcile-hardening/32-VERIFICATION.md` — existing replay/reconcile verification evidence and remaining regression-retention posture.
- `.planning/phases/33-observability-incident-support/33-CONTEXT.md` — support-surface truthfulness, privacy, and operator wording constraints.
- `.planning/phases/33-observability-incident-support/33-VERIFICATION.md` — explicit deferral of root-level verification rerun stability into Phase 34.
- `.planning/phases/33-observability-incident-support/33-VALIDATION.md` — current support-contract test shape and verification map.

### Current verification and CI seams
- `.github/workflows/ci.yml` — required CI jobs, existing `admin_smoke_gate`, and the current required-vs-broader-suite landscape.
- `.github/workflows/advisory-matrix.yml` — current advisory matrix shape that may need repurposing or removal if redundant.
- `.github/workflows/provider-live.yml` — current live-provider advisory canary workflow and failure-tracking posture.
- `test/test_helper.exs` — root/core test bootstrap lifecycle.
- `mailglass_admin/test/test_helper.exs` — admin package test bootstrap lifecycle.
- `test/support/citext_probe.ex` — current citext bootstrap probe behavior in `mailglass`.
- `mailglass_admin/test/support/citext_probe.ex` — current citext bootstrap probe behavior in `mailglass_admin`.
- `test/support/data_case.ex` — canonical core DB test ownership pattern.
- `test/support/mailer_case.ex` — canonical outbound/support-heavy core test ownership pattern.
- `mailglass_admin/test/support/live_view_case.ex` — canonical admin LiveView support-surface test ownership pattern.

### Current support-contract artifacts that should inform the gate
- `test/mailglass/docs_contract_test.exs` — docs contract assertions for shipped support/docs surfaces.
- `test/mailglass/docs/operator_incident_support_guide_test.exs` — operator incident guide contract.
- `test/mailglass/operator/support_summary_test.exs` — support-summary truth/read-model contract.
- `test/mailglass/webhook/telemetry_test.exs` — shipped webhook telemetry contract.
- `test/mailglass/telemetry_test.exs` — broader telemetry contract.
- `test/mailglass/webhook/replay_test.exs` — replay semantics regression coverage.
- `test/mailglass/webhook/reconciler_test.exs` — reconcile semantics regression coverage.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — operator support-card/drilldown/admin support contract.
- `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs` — non-vacuous admin smoke gate precedent.
- `lib/mailglass/operator/support_summary.ex` — support-summary truth source.
- `guides/telemetry.md` — telemetry truth boundary.
- `guides/operator-incident-support.md` — canonical operator support story.

### External precedents and ecosystem priors
- `https://hexdocs.pm/mix/Mix.Tasks.Test.html` — explicit test selection and package-local test execution norms in Mix.
- `https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html` — Ecto sandbox ownership and spawned-process testing posture.
- `https://hexdocs.pm/phoenix_live_view/security-model.html` — action-time and mounted support-surface trust posture.
- `https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html` — deterministic mail testing over real-provider dependence in a neighboring library.
- `https://guides.rubyonrails.org/testing.html` — Action Mailer test-delivery posture in Rails.
- `https://github.com/stripe/stripe-mock` — deterministic provider-contract testing precedent.
- `https://github.com/beam-community/stripity-stripe` — Elixir SDK precedent for mock-backed required tests plus real integration outside the main gate.
- `https://github.com/ex-aws/ex_aws` — external-service library precedent for local/deterministic test preference.
- `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks` — skipped-job and status-check semantics relevant to non-vacuous required gates.
- `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches` — required-check naming/branch-protection semantics.
- `https://docs.stripe.com/webhooks/process-undelivered-events?locale=en-GB` — exactness and manual recovery posture for webhook repair.
- `https://docs.github.com/en/webhooks/using-webhooks/handling-failed-webhook-deliveries` — failed-delivery recovery posture.
- `https://shopify.dev/docs/apps/build/webhooks/troubleshooting-webhooks` — honest webhook troubleshooting and support-signal posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ci.yml` already contains a required-core lane and a separate `admin_smoke_gate`, so Phase 34 can evolve an existing split-gate posture rather than inventing one from scratch.
- `provider-live.yml` already models advisory live-provider failure tracking correctly enough to refine rather than replace.
- Phase 33 already shipped a meaningful support-contract regression bundle across docs, telemetry, support summary, and operator LiveView behavior.
- `post_installer_smoke_test.exs` already gives the repo one precedent for fixing a vacuous tag-based smoke gate.
- Package-local `test_helper` and case-template files already show the natural ownership boundaries Phase 34 should preserve.

### Established Patterns
- The project prefers honest surfaces over broad but misleading promises.
- Fake-adapter coverage is the required trust base; real providers are advisory evidence.
- `mailglass` and `mailglass_admin` are sibling packages with distinct adopter-facing contracts, not an umbrella pretending to be one app.
- Support/operator UX already emphasizes truthfulness, exactness, and low-claim wording. Verification should mirror that same posture.

### Integration Points
- Phase 34 should connect the roadmap requirement (`MAT-03`), CI workflow semantics, mix/test entrypoints, support-contract tests, and verification docs into one explicit contract.
- Any new verification gate should likely live at the repo level as a thin orchestrator while delegating real work to package-local commands/jobs.
- If deterministic provider-smoke coverage is introduced or repurposed, it should sit between required core/admin support bundles and advisory provider-live canaries.

</code_context>

<deferred>
## Deferred Ideas

- Turning live-provider or networked third-party checks into required PR gates.
- Broadening Phase 34 into new support-console or observability-product features.
- Reworking replay/reconcile product semantics beyond retaining regression coverage.
- Treating broad full-suite reruns as the `MAT-03` release contract before they are stable and honestly scoped.

</deferred>

---

*Phase: 34-verification-regression-closure*
*Context gathered: 2026-05-05*
