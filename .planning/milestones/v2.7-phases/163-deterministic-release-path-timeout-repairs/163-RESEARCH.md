# Phase 163: Deterministic Release-Path Timeout Repairs - Research

**Researched:** 2026-08-26
**Domain:** Narrow, deterministic timeout diagnosis in the existing Ecto/PostgreSQL property harness and Playwright operator-browser harness
**Confidence:** HIGH (repository-local mechanisms and constraints); MEDIUM (upstream framework semantics, because Context7 is unavailable in this environment)

## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Database Property Boundary
- **D-01:** Preserve both existing 1,000-run idempotency properties and the explicit non-transactional per-owner sandbox checkout as the baseline. Do not alter their invariant, run count, or established ownership-timeout repair.
- **D-02:** Reproduce and capture the actual SQLSTATE 57014 source before choosing a fix. Apply any repair only at the demonstrated fixture, session, isolation, or query seam; do not raise global database or job limits.

#### Gallery Matrix Boundary
- **D-03:** Preserve live specimen discovery, its non-vacuity/stress-cell guards, and the full 320/390/768/1440 × light/dark/system sweep. Do not remove cells, axes, overflow checks, or clipping checks.
- **D-04:** Diagnose server boot/readiness separately from matrix execution using the existing readiness and boot-stage probes. Limit any timing repair to the demonstrated readiness or individual Playwright-test boundary while retaining the single-worker runner and bounded web-server lifecycle.

#### Release-Path Proof
- **D-05:** Require repeated focused proof for each repaired path before accepting the existing canonical protected CI and operator-browser gates as the integration verdict.
- **D-06:** Keep protected workflow topology and job-level deadlines unchanged. An advisory label, a one-off local pass, a broad retry, or a longer global deadline cannot substitute for repeatable bounded evidence.

### the agent's Discretion

- Exact reproduction seeds and diagnostic instrumentation, provided they identify rather than conceal the failing boundary and are removed or retained only when they improve durable evidence.
- Exact local timeout value at a proven per-test or readiness seam, provided it is finite, justified by repeated measurements, and does not change the global database, Playwright, or CI job policy.
- Exact repetition count for focused stability proof, provided it is high enough to demonstrate recurrence is resolved and the canonical gates still run unchanged.

### Deferred Ideas (OUT OF SCOPE)

None — analysis stayed within the fixed Phase 163 scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DTRM-01 | Reproduce/repair SQLSTATE 57014 at a narrow property seam while retaining 1,000 runs and invariant. | Separate the two property modules; capture `%Postgrex.Error{postgres: %{code: :query_canceled}}` plus SQL/step before changing timeout plumbing. |
| DTRM-02 | Repeated focused proof and canonical protected CI pass without prohibited shortcuts. | Repetition uses unseeded focused file invocations, then unchanged `mix test --warnings-as-errors` in the Deterministic Core Suite CI job. |
| DTRM-03 | Reproduce/repair gallery timeout at narrow readiness, test, or Playwright seam with full discovery/matrix coverage. | Split boot/readiness evidence from the matrix test's measured execution; retain all discovery guards and loops. |
| DTRM-04 | Repeated browser proof and operator-browser gate pass without retries/matrix/UI/global timeout changes. | Run the single gallery spec repeatedly with one worker and no added retry; use unchanged `npm run test:operator-browser` as integration proof. |

## Project Constraints (from CLAUDE.md)

- Do not alter product schemas/APIs, admin UI behavior, dependency versions, CI topology, global timeout policy, or release policy for this phase. [VERIFIED: CLAUDE.md and 163-CONTEXT.md]
- Keep errors as structured contracts; do not pattern-match error text. Telemetry must contain no PII. [VERIFIED: CLAUDE.md]
- The Ecto Sandbox helper is the sanctioned ownership/acquire-release door; preserve append-only event semantics and use `TRUNCATE ... CASCADE` for property cleanup. [VERIFIED: CLAUDE.md; test/support/sandbox_ownership.ex; property modules]
- The browser runner remains one worker because fixtures and server state are shared. [VERIFIED: mailglass_admin/package.json; 163-CONTEXT.md]
- Preserve unrelated dirty worktree state: `.planning/config.json` and `scheduled-control-sweep.json` were modified/untracked at research time. [VERIFIED: git status, 2026-08-26]

## Summary

Phase 163 has two independent timing paths, neither of which should be solved by reusing a broad timeout lever. The core property path has already closed the historical `DBConnection` ownership-clock failure: both 1,000-run modules use a ten-minute *per-owner* checkout bound, and the main idempotency property explicitly retains non-transactional committed-write semantics. [VERIFIED: test/mailglass/properties/idempotency_convergence_test.exs; test/mailglass/properties/webhook_idempotency_convergence_test.exs; 143-gap-closure-ownership-timeout-SUMMARY.md] SQLSTATE `57014` is a different failure class and must be attributed first; the repository's likely local candidate is webhook ingestion's intentionally bounded `SET LOCAL statement_timeout = '2s'`, not the already-proven owner timeout. [VERIFIED: lib/mailglass/webhook/ingest.ex; lib/mailglass/repo.ex] This is a hypothesis, not a repair decision.

The gallery path likewise has two clocks: Playwright's bounded `webServer.timeout` (300 seconds) governs boot/readiness, while the 30-second test timeout governs each matrix test. [VERIFIED: mailglass_admin/playwright.config.cjs] The server already prints boot stages, probes TCP, and probes `/ops/browser-ready`; the gallery spec then has two tests, one live-discovery resize loop and one stress-cell sweep. [VERIFIED: mailglass_admin/test/support/operator_browser_server.ex; mailglass_admin/e2e/gallery-matrix.spec.js] Planning must make diagnostic evidence choose exactly one seam before increasing any finite local bound.

**Primary recommendation:** Plan an evidence-first reproduction task, then one independently validated narrow repair task per path; do not pre-commit to a timeout value or edit until the emitted SQL statement / Playwright phase proves its owner.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 1,000-run database idempotency proof | Database / Storage | API / Backend test harness | SQL execution, transaction-local settings, Sandbox ownership, and `TRUNCATE` happen through `TestRepo`; production module behavior is observed, not redesigned. [VERIFIED: property modules; lib/mailglass/webhook/ingest.ex] |
| Property failure attribution | API / Backend test harness | Database / Storage | The test owns fixture/setup instrumentation; PostgreSQL error metadata identifies the exact statement/session boundary. [VERIFIED: property modules] |
| Browser-server boot/readiness | Frontend Server (SSR) | Database / Storage | `OperatorBrowserServer.run!/0` starts app, creates/owns sandbox state, seeds fixtures, binds endpoint, and exposes readiness. [VERIFIED: operator_browser_server.ex] |
| Gallery matrix proof | Browser / Client | Frontend Server (SSR) | Playwright drives rendered DOM at viewport/theme combinations while the LiveView server supplies specimens. [VERIFIED: gallery-matrix.spec.js] |
| Release-path integration verdict | CI / protected automation | Browser and database harnesses | Existing CI job deadlines/topology are the final integration surface and are explicitly frozen. [VERIFIED: .github/workflows/ci.yml; 163-CONTEXT.md] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Ecto SQL Sandbox + `Mailglass.TestSupport.SandboxOwnership` | Existing locked Mix dependency | Per-owner, release-registered database test ownership | It provides the established narrow owner seam and guards against restoring a global/shared-mode leak. [VERIFIED: test/support/sandbox_ownership.ex; 143-gap-closure-ownership-timeout-SUMMARY.md] |
| PostgreSQL 16 Alpine in CI | Digest pinned in `ci.yml` | Real persistence backing for the properties | The protected deterministic suite already uses it; no database version change is authorized. [VERIFIED: .github/workflows/ci.yml] |
| Playwright (`@playwright/test`) | `^1.59.1` in existing lockfile manifest | Browser test execution, server lifecycle, per-test deadlines | Existing test configuration owns the two relevant finite timing boundaries. [VERIFIED: mailglass_admin/package.json; mailglass_admin/playwright.config.cjs] |
| Node 22 | CI matrix | Operator-browser execution | The operator-browser CI job is explicitly Node 22 and already installs Chromium. [VERIFIED: .github/workflows/ci.yml] |

### Supporting

| Tool | Purpose | When to use |
|------|---------|-------------|
| `make toolchain CMD='…'` | Run a focused core command on the pinned Elixir 1.18 / OTP 27, 2-vCPU Docker harness. | Attribute/timing-proof runs when host Elixir 1.19 / OTP 28 would not represent CI. [VERIFIED: Makefile; 143-gap-closure-ownership-timeout-SUMMARY.md] |
| `/ops/browser-ready` and boot-stage logs | Distinguish server boot/readiness from test-body delay. | Before touching Playwright test timing. [VERIFIED: operator_browser_server.ex; playwright.config.cjs] |
| Existing Playwright trace-on-first-retry | Preserve failure diagnostics on its configured retry behavior. | Observe artifacts only; do not add retries or treat a retry pass as proof. [VERIFIED: playwright.config.cjs; 163-CONTEXT.md] |

**Installation:** none. [VERIFIED: .planning/research/STACK.md; 163-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Core property path
focused Mix invocation
  -> property setup: SandboxOwnership.checkout!
  -> fixture reset / tenant stamp
  -> 1,000 StreamData iterations
  -> TestRepo query or Webhook.Ingest transaction
  -> PostgreSQL response
  -> capture SQLSTATE + query/step attribution
  -> repeated focused proof
  -> unchanged Deterministic Core Suite CI job

Browser gallery path
single-worker Playwright invocation
  -> webServer: OperatorBrowserServer.run!
     -> app start -> AdminBootstrap -> sandbox owner -> fixtures
     -> TCP + /ops/browser-ready probes
  -> gallery-matrix test body
     -> live cell discovery/non-vacuity/stress guards
     -> widths × themes × overflow/clipping assertions
  -> capture boot versus test-body duration
  -> repeated focused proof
  -> unchanged Operator Browser Gate
```

### Component Responsibilities

| File | Ownership in Phase 163 | Planning guidance |
|------|------------------------|------------------|
| `test/mailglass/properties/idempotency_convergence_test.exs` | Main events property fixture and invariant | Do not change `max_runs: 1000`, generators, snapshots, or non-transactional checkout. Instrument only if it is the proven source. [VERIFIED: file] |
| `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | Webhook property fixture and invariant | First candidate for `57014` because each iteration calls `Ingest.ingest_multi/3`; do not change its owner bound or settle behavior until evidence says so. [VERIFIED: file; lib/mailglass/webhook/ingest.ex] |
| `lib/mailglass/webhook/ingest.ex` | Existing transaction-local 2s statement/500ms lock guards | Product code is normally out of scope; modify only if captured evidence proves this is the narrow session/query seam and no fixture-only repair exists. [VERIFIED: file; 163-CONTEXT.md] |
| `mailglass_admin/test/support/operator_browser_server.ex` | Boot/readiness evidence and server-owned fixture lifecycle | Add/retain only timing probes that separate boot stages from matrix execution. [VERIFIED: file] |
| `mailglass_admin/playwright.config.cjs` | `webServer` lifecycle / test-wide defaults | Leave 300s server lifecycle and CI retry/global defaults unchanged unless readiness evidence proves a bounded readiness seam requires a local change. [VERIFIED: file; 163-CONTEXT.md] |
| `mailglass_admin/e2e/gallery-matrix.spec.js` | Per-test matrix boundary and full coverage contract | Preserve discovery, `> 50` guard, stress list, four widths, three themes, all overflow/clipping checks. A finite test-local timeout is permissible only after measured body duration demonstrates it. [VERIFIED: file; 163-CONTEXT.md] |
| `.github/workflows/ci.yml` | Integration evidence only | Do not change job deadline/topology; run its existing deterministic core suite and browser gate as final proof. [VERIFIED: file; 163-CONTEXT.md] |

### Pattern 1: Capture before choosing the clock

**What:** Run the unaltered focused property and record the failing module, generated seed only as an observation, Postgrex SQLSTATE, query/step, current session timeout values, and elapsed time. [VERIFIED: 163-CONTEXT.md; property modules]

**When to use:** Before changing `ownership_timeout`, `statement_timeout`, `lock_timeout`, sandbox mode, a test timeout, or server lifecycle timeout. [VERIFIED: 163-CONTEXT.md]

**Implementation shape:** retain only diagnostic code that makes the chosen boundary observable; remove temporary logging after the regression proof can attribute future failure without it. [ASSUMED]

### Pattern 2: Split browser boot from matrix body

**What:** Treat successful `/ops/browser-ready` plus server stage output as boot evidence, then measure the gallery test separately. [VERIFIED: operator_browser_server.ex; playwright.config.cjs]

**When to use:** A gallery timeout can occur before a page exists, while live discovery runs, or during a specific viewport/theme/cell assertion; those are different repair seams. [VERIFIED: 163-CONTEXT.md; gallery-matrix.spec.js]

### Anti-Patterns to Avoid

- **Re-raising the ten-minute owner timeout:** it addresses the historical `DBConnection` owner-clock mismatch, not automatically SQLSTATE `57014`. [VERIFIED: 143-gap-closure-ownership-timeout-SUMMARY.md; 163-CONTEXT.md]
- **Changing `max_runs`, a property seed, an ExUnit exclusion, or gallery axes:** each manufactures a smaller proof and violates DTRM acceptance. [VERIFIED: REQUIREMENTS.md; 163-CONTEXT.md]
- **Increasing `ci.yml` `timeout-minutes`, Playwright global `timeout`, or adding retries before attribution:** those are explicitly prohibited global/broad mechanisms. [VERIFIED: REQUIREMENTS.md; 163-CONTEXT.md]
- **Conflating readiness with matrix work:** a server boot repair cannot be justified by a test-body observation, and vice versa. [VERIFIED: 163-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sandbox owner lifecycle | A second checkout/release helper | `SandboxOwnership.checkout!/1` | It registers release immediately and has harness-specific leak detection. [VERIFIED: test/support/sandbox_ownership.ex] |
| Database timeout policy | A new global config or generic retry wrapper | Existing per-owner checkout / transaction-local session seam after attribution | The phase permits only the demonstrated narrow boundary. [VERIFIED: 163-CONTEXT.md; webhook ingest] |
| Browser readiness endpoint | A second status route or ad hoc polling service | Existing `/ops/browser-ready`, TCP, HTTP, and step prints | The harness already exposes the required boot separation. [VERIFIED: operator_browser_server.ex; playwright.config.cjs] |
| Matrix enumeration | Hardcoded component lists or reduced cartesian test | Existing live discovery plus stress guards | Live discovery automatically includes new specimens and non-vacuity rejects empty selection. [VERIFIED: gallery-matrix.spec.js] |

## Common Pitfalls

### Pitfall 1: Mistaking `57014` for the historical ownership timeout

**What goes wrong:** A planner changes `ownership_timeout` because it is a familiar long-property setting, but the emitted failure comes from a PostgreSQL statement cancellation. [VERIFIED: 143-gap-closure-ownership-timeout-SUMMARY.md; lib/mailglass/webhook/ingest.ex]

**How to avoid:** Require captured exception metadata and query/step attribution; classify owner timeout, statement timeout, lock timeout, and readiness timeout separately. [ASSUMED]

### Pitfall 2: Treating a local fast machine as CI proof

**What goes wrong:** Host Elixir is 1.19.5/OTP 28, while protected CI is 1.18.4/OTP 27; local pass duration can under-report the protected clock. [VERIFIED: local environment probe, 2026-08-26; .tool-versions; .github/workflows/ci.yml]

**How to avoid:** Use the repository's capped gating-toolchain command for timing decisions, then let unchanged CI be the integration verdict. [VERIFIED: Makefile; 143-gap-closure-ownership-timeout-SUMMARY.md]

### Pitfall 3: Letting a Playwright retry conceal a slow first attempt

**What goes wrong:** CI enables one retry and trace-on-first-retry, so a retry pass can hide a first-attempt timeout if accepted as stability proof. [VERIFIED: playwright.config.cjs]

**How to avoid:** Focused stability proof must be repeated with no newly added retry and record first-attempt outcomes; the existing CI setting remains unchanged. [ASSUMED]

### Pitfall 4: Removing coverage to fit 30 seconds

**What goes wrong:** Reducing discovered cells, widths, themes, stress cells, or overflow assertions makes the run shorter but violates the proof contract. [VERIFIED: gallery-matrix.spec.js; REQUIREMENTS.md]

**How to avoid:** Preserve both tests and all loops; if the body is legitimately bounded too tightly, adjust only the individual proven test boundary to a finite measured value. [VERIFIED: 163-CONTEXT.md]

## Code Examples

### Focused property reproduction (unseeded)

```bash
# Run each independently; do not add --seed, --max-failures, --only, or exclusions.
MIX_ENV=test mix test test/mailglass/properties/idempotency_convergence_test.exs --warnings-as-errors
MIX_ENV=test mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors

# Repeat on the protected-toolchain analogue when deciding a timing bound.
make toolchain CMD='mix test test/mailglass/properties/webhook_idempotency_convergence_test.exs --warnings-as-errors'
```

Source: [VERIFIED: property module paths; Makefile; 163-CONTEXT.md]

### Focused gallery diagnosis/proof

```bash
cd mailglass_admin
mix mailglass_admin.assets.build
npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1

# Existing integration command; do not modify its retry/worker/topology.
npm run test:operator-browser
```

Source: [VERIFIED: mailglass_admin/package.json; playwright.config.cjs; gallery-matrix.spec.js]

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Pool-wide `:auto` with its default owner clock | Explicit shared, non-transactional per-owner checkout with a 10-minute owner bound | The idempotency property keeps committed-write semantics and full 1,000-run contract without global timeout change. [VERIFIED: 143-gap-closure-ownership-timeout-SUMMARY.md; idempotency property] |
| Opaque Playwright server boot | Step prints plus TCP and both HTTP readiness probes | A timeout can be attributed to boot/readiness before touching test execution. [VERIFIED: operator_browser_server.ex] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The likely SQLSTATE candidate is the webhook transaction's 2s `SET LOCAL statement_timeout`, because it is the repository-local path that intentionally sets that class of limit. | Summary / Pattern 1 | A wrong repair could alter product session policy instead of the actual fixture/query. |
| A2 | First-attempt outcomes must be recorded separately from CI's configured retry for meaningful focused stability proof. | Pitfall 3 | Repeated proof could accept flakiness hidden by a retry. |
| A3 | Temporary diagnostics should be removed unless they remain useful durable attribution evidence. | Pattern 1 | Retained noise or insufficient future failure attribution. |

## Open Questions

1. **Which exact property statement emits SQLSTATE `57014`?**
   - What we know: `WebhookIdempotencyConvergenceTest` calls `Ingest.ingest_multi/3`, and that transaction sets a local 2-second statement timeout. [VERIFIED: webhook property; lib/mailglass/webhook/ingest.ex]
   - What's unclear: the observed failing property/module, PostgreSQL message, query, and whether it is the 2-second statement bound, another test-session setting, lock contention, or fixture cleanup. [VERIFIED: 163-CONTEXT.md]
   - Recommendation: make actual reproduction/capture the first executable plan task and select no fix beforehand.

2. **Does the gallery timeout occur during web-server readiness or inside either test body?**
   - What we know: server readiness has a 300-second lifecycle bound; test default is 30 seconds; diagnostics already exist. [VERIFIED: playwright.config.cjs; operator_browser_server.ex]
   - What's unclear: the stage and elapsed duration of the observed failure. [VERIFIED: 163-CONTEXT.md]
   - Recommendation: preserve and collect stage evidence, then time the focused spec with all coverage intact.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Erlang host runtime | Quick local reproduction | ✓ | Elixir 1.19.5 / OTP 28 | `make toolchain` for CI parity. [VERIFIED: local probe, 2026-08-26] |
| Docker | Gating toolchain | ✓ | 29.5.2 | — [VERIFIED: local probe, 2026-08-26] |
| PostgreSQL CLI/readiness tool | Local test DB preflight | ✓ | psql 14.17; `pg_isready` present | Existing test DB / Docker service. [VERIFIED: local probe, 2026-08-26] |
| Node/npm | Browser proof | ✓ | Node 22.14.0 / npm 11.1.0 | — [VERIFIED: local probe, 2026-08-26] |
| Playwright dependencies | Browser proof | Present in `mailglass_admin/node_modules` | Manifest declares `@playwright/test ^1.59.1` | CI installs exact locked package/browser. [VERIFIED: mailglass_admin/package.json; repository files] |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Core framework | ExUnit + StreamData property tests, PostgreSQL-backed Ecto sandbox. [VERIFIED: property modules] |
| Browser framework | Playwright with `mailglass_admin/playwright.config.cjs`. [VERIFIED: config] |
| Quick property command | `MIX_ENV=test mix test test/mailglass/properties/<target>.exs --warnings-as-errors` |
| Quick browser command | `cd mailglass_admin && npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1` |
| Protected integration commands | Unchanged core `mix test --warnings-as-errors` CI step; unchanged `npm run test:operator-browser` operator-browser CI step. [VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DTRM-01 | Each 1,000-run property retains its invariant and the failure source is attributed before repair. | Property/regression | Focused file commands above, repeated unseeded; capture failure metadata when red. | ✅ |
| DTRM-02 | Focused property stability plus canonical deterministic core suite succeeds without shortcuts. | Repetition + integration | Repeated focused command on `make toolchain`, then unchanged CI deterministic suite. | ✅ |
| DTRM-03 | Gallery retains live discovery, non-vacuity/stress, four widths, three themes, overflow/clipping assertions. | Browser E2E/regression | Focused gallery spec, repeated under one worker. | ✅ |
| DTRM-04 | Browser path is repeatably bounded and existing operator-browser gate succeeds. | Repetition + integration | Repeated focused spec, then unchanged `npm run test:operator-browser` in CI. | ✅ |

### Sampling Rate

- **During diagnosis:** Run each affected focused command once unmodified to capture the error/stage; do not treat a pass as repair evidence. [VERIFIED: 163-CONTEXT.md]
- **After a narrow repair:** Run each affected focused command repeatedly at a planner-selected, documented finite count; execute against the gating-toolchain analogue for the property. [VERIFIED: 163-CONTEXT.md; Makefile]
- **Phase gate:** Existing canonical protected CI and operator-browser gates pass unchanged after focused proof. [VERIFIED: 163-CONTEXT.md; .github/workflows/ci.yml]

### Wave 0 Gaps

- [ ] Add no framework or package. [VERIFIED: .planning/research/STACK.md; 163-CONTEXT.md]
- [ ] Decide whether durable, narrow instrumentation is needed only after reproduction identifies a missing attribution field. [ASSUMED]
- [ ] Record a focused-proof evidence format (command, toolchain, repetition count, elapsed range, first-attempt result, and source boundary) in the execution plan; this is documentation/evidence, not a new test framework. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No authentication surface changes. [VERIFIED: 163-CONTEXT.md] |
| V3 Session Management | Yes, database-session scope only | Keep timeout/session changes transaction-local or fixture-local when evidence proves them; do not widen global policy. [VERIFIED: webhook ingest; 163-CONTEXT.md] |
| V4 Access Control | No | No authorization/UI behavior changes. [VERIFIED: 163-CONTEXT.md] |
| V5 Input Validation | No new input surface | Preserve existing property generators and browser fixture contract. [VERIFIED: property modules; gallery spec] |
| V6 Cryptography | No | No cryptographic change. [VERIFIED: 163-CONTEXT.md] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Timeout relaxation masks a real denial-of-service/lock condition | Denial of Service | Attribute the exact statement or readiness boundary and retain finite bounds; never change global/job limits. [VERIFIED: REQUIREMENTS.md; 163-CONTEXT.md] |
| Retry turns a deterministic failure into apparent success | Repudiation / Denial of Service | Keep focused proof first-attempt-visible and retain existing bounded retry configuration unchanged. [ASSUMED] |
| Diagnostics expose message/recipient content | Information Disclosure | Record only timing, test IDs, SQLSTATE/query shape, and non-PII metadata; follow project telemetry no-PII rule. [VERIFIED: CLAUDE.md] |

## Sources

### Primary (HIGH confidence)

- Repository code: property modules, SandboxOwnership helper, webhook ingest, Playwright config/spec, browser server, CI workflow, Makefile. [VERIFIED: codebase]
- Phase 163 context, requirements, roadmap, state, and Phase 143 ownership-timeout summary. [VERIFIED: planning artifacts]

### Secondary (MEDIUM confidence)

- Context7 research plan selected Ecto SQL Sandbox and Playwright documentation, but the local `ctx7` CLI and Context7 MCP access are unavailable; no external claim is relied on for the recommended repair. [CITED: local research-plan result]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing locked code and CI are the only permitted stack.
- Architecture: HIGH — all seams are visible in the affected source files.
- Failure mechanism: MEDIUM — historical ownership failure is confirmed, but current SQLSTATE and gallery stage must be reproduced before choosing a repair.

**Research date:** 2026-08-26
**Valid until:** execution begins or any affected failure evidence changes.
