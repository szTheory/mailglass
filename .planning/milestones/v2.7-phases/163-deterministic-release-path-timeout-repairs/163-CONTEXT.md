# Phase 163: Deterministic Release-Path Timeout Repairs - Context

**Gathered:** 2026-08-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair only the observed PostgreSQL SQLSTATE 57014 property-test failure and the admin gallery-matrix timeout at their narrow fixture, session, readiness, query, or per-test boundaries. Preserve the full 1,000-run property contract, every discovered gallery specimen, all viewport/theme/stress/overflow coverage, and the existing protected CI topology. Product schemas and APIs, admin UI behavior, dependency versions, global timeout policy, broad retries, seed pinning, skipped tests, reduced property counts, and reduced browser matrices remain out of scope.
</domain>

<decisions>
## Implementation Decisions

### Database Property Boundary
- **D-01:** Preserve both existing 1,000-run idempotency properties and the explicit non-transactional per-owner sandbox checkout as the baseline. Do not alter their invariant, run count, or established ownership-timeout repair.
- **D-02:** Reproduce and capture the actual SQLSTATE 57014 source before choosing a fix. Apply any repair only at the demonstrated fixture, session, isolation, or query seam; do not raise global database or job limits.

### Gallery Matrix Boundary
- **D-03:** Preserve live specimen discovery, its non-vacuity/stress-cell guards, and the full 320/390/768/1440 × light/dark/system sweep. Do not remove cells, axes, overflow checks, or clipping checks.
- **D-04:** Diagnose server boot/readiness separately from matrix execution using the existing readiness and boot-stage probes. Limit any timing repair to the demonstrated readiness or individual Playwright-test boundary while retaining the single-worker runner and bounded web-server lifecycle.

### Release-Path Proof
- **D-05:** Require repeated focused proof for each repaired path before accepting the existing canonical protected CI and operator-browser gates as the integration verdict.
- **D-06:** Keep protected workflow topology and job-level deadlines unchanged. An advisory label, a one-off local pass, a broad retry, or a longer global deadline cannot substitute for repeatable bounded evidence.

### the agent's Discretion
- Exact reproduction seeds and diagnostic instrumentation, provided they identify rather than conceal the failing boundary and are removed or retained only when they improve durable evidence.
- Exact local timeout value at a proven per-test or readiness seam, provided it is finite, justified by repeated measurements, and does not change the global database, Playwright, or CI job policy.
- Exact repetition count for focused stability proof, provided it is high enough to demonstrate recurrence is resolved and the canonical gates still run unchanged.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — DTRM-01 through DTRM-04 acceptance and prohibited shortcuts.
- `.planning/ROADMAP.md` — fixed Phase 163 goal, dependencies, and success criteria.
- `.planning/STATE.md` — current phase boundary and unresolved timeout concern.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-CONTEXT.md` — evidence-first, fail-closed release-path constraints inherited from Phase 162.
- `.planning/research/FEATURES.md` — milestone-level timeout repair analysis and scope exclusions.
- `.planning/research/STACK.md` — pinned toolchain and narrow configuration seams.
- `test/mailglass/properties/idempotency_convergence_test.exs` — primary 1,000-run property and prior ownership failure history.
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — sibling 1,000-run property and matching per-owner pattern.
- `.planning/milestones/v2.2-phases/143-test-harness-truth/143-gap-closure-ownership-timeout-SUMMARY.md` — prior narrow ownership-clock repair that must not regress.
- `mailglass_admin/e2e/gallery-matrix.spec.js` — protected live-discovery and viewport/theme/stress/overflow contract.
- `mailglass_admin/playwright.config.cjs` — bounded server lifecycle, readiness URL, and browser configuration.
- `mailglass_admin/test/support/operator_browser_server.ex` — boot-stage and readiness probes.
- `mailglass_admin/package.json` — single-worker operator-browser command.
- `.github/workflows/ci.yml` — canonical property and operator-browser integration gates.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The two property modules already share a 1,000-run, per-owner, non-transactional sandbox pattern with a finite module-local ownership bound.
- The historical Phase 143 summary preserves measured evidence for the prior DBConnection ownership-clock mismatch and its narrow repair.
- The browser harness already exposes `/ops/browser-ready` and boot-stage diagnostics, so readiness failures can be separated from slow matrix execution without adding another server path.
- The gallery spec already discovers live test IDs and enforces non-vacuity, required stress cells, all widths, all themes, overflow, and narrow-screen clipping.

### Established Patterns
- Reproduce first, then change the narrowest demonstrated boundary.
- Preserve invariant strength and coverage cardinality; a timeout fix may change timing plumbing but not what is proved.
- External or time-sensitive evidence stays bounded and fail-closed; absence of a reproduced failure is not proof of repair.
- Decisive-by-default and recommendation-first methodology applies: downstream research should synthesize one evidence-backed repair per path rather than reopen routine alternatives.

### Integration Points
- Database path: property setup/checkout and the specific fixture/session/query that emits SQLSTATE 57014, followed by the canonical property lane in `.github/workflows/ci.yml`.
- Browser path: `operator_browser_server.ex` readiness, `playwright.config.cjs`, and the individual `gallery-matrix.spec.js` test boundary, followed by `operator_browser_gate` unchanged.
</code_context>

<specifics>
## Specific Ideas

No additional user-specified mechanics. Use the confirmed narrow-boundary, full-coverage, repeated-proof approach.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within the fixed Phase 163 scope.
</deferred>
