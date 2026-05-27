# Architecture Research: v1.3 Adopter Trust Proof

**Project:** mailglass  
**Domain:** maintained Phoenix reference host app + clean-baseline CI trust lane  
**Researched:** 2026-05-27  
**Confidence:** HIGH

## Recommendation

Treat v1.3 as an **integration-proof architecture milestone**, not a core-runtime milestone.

The right architecture is:

1. Add one thin, maintained Phoenix reference host app that composes existing `mailglass` seams.
2. Add one deterministic trust-journey runner that proves install -> preview -> send -> webhook ingest -> operator troubleshooting.
3. Reuse that same runner in CI across two contexts: repo-head verification and published-version clean-baseline verification.
4. Keep API-contract truth in existing contract docs/tests (`docs/api_stability.md`, support-contract lanes), and label the reference app as usage proof only.

Everything below is **new work delta from shipped v1.2**; no core library behavior is re-implemented.

## Integration Model (Delta-Only)

| Layer | Existing architecture reused | New v1.3 integration role |
|---|---|---|
| Core mail runtime | `Mailglass.deliver*`, installer wiring, webhook ingest, append-only ledger | Consumed as-is by the reference host app |
| Admin/operator runtime | `MailglassAdmin.Router` mount + operator views/evidence/timelines | Used as troubleshooting proof endpoint in the journey |
| Inbound sibling package | Existing package remains available, but not required for the thin trust claim | Explicitly optional in v1.3 reference proof path |
| Host app surface | Existing `test/example` installer fixture proves installer snapshots only | New maintained reference host app proves operational journey end to end |
| CI surface | Existing `ci.yml` + `post-publish-smoke.yml` | New trust-proof lane and release-time published-version trust check |

## New vs Modified Components

### New Components

1. **Reference host app (maintained artifact)**  
   Suggested location: `reference/host_app/` (separate from `test/example` fixture seed).
2. **Reference integration boundary module(s)**  
   App-local boundary (for example `ReferenceHost.Mailing`) that calls stable public Mailglass APIs only.
3. **Deterministic trust fixtures**  
   Seed and webhook payload fixtures with stable IDs to make troubleshooting reproducible.
4. **Trust journey runner**  
   One script/task/test command that executes the whole proof journey and emits machine-checkable checkpoints.
5. **Trust-proof CI job**  
   Clean host-baseline lane that runs the journey non-interactively and fails hard on drift.

### Modified Components

1. **`.github/workflows/ci.yml`**  
   Add required trust-proof job for PR/push.
2. **`.github/workflows/post-publish-smoke.yml`**  
   Extend with published-version trust journey (beyond first-preview smoke).
3. **Docs positioning** (`README.md`, adoption guide, maintaining runbook)  
   Add explicit wording: reference app = usage/operations proof, contract truth = core stability docs/tests.
4. **Release checklist artifacts**  
   Include trust-proof lane result as release evidence so sibling-version skew cannot hide.

## Component Boundaries

### 1) Keep Library Boundaries Intact

The reference app must integrate only through existing public seams:

- `mix mailglass.install`
- `Mailglass.Mailable` + `Mailglass.deliver*`
- webhook router mount (`mailglass_webhook_routes`)
- admin mount (`mailglass_admin_routes`)

Do not copy provider verifiers, event projection logic, or operator internals into the app.

### 2) Separate Fixture Seed vs Maintained Reference App

- `test/example` remains a deterministic installer fixture for snapshot tests.
- The new reference app is a maintained adopter-facing artifact with realistic routes, seed data, and troubleshooting flow.
- This prevents two incompatible concerns (golden snapshots vs runnable operations demo) from colliding.

### 3) Proof Harness Boundary

Define one trust runner that both humans and CI call. The runner owns:

- journey setup order
- deterministic fixture loading
- checkpoint assertions
- machine-readable pass/fail output

This avoids docs saying one thing while CI tests another.

### 4) Dependency Boundary for Trust Claims

- Trust-proof default should resolve published Hex packages (no committed path deps).
- Local development overrides may exist, but they are explicitly non-proof paths.
- CI must fail if committed trust lane inputs contain path dependency coupling.

## Data Flow: End-to-End Trust Journey

1. **Bootstrap**: create or reset clean host app baseline; fetch deps; run `mix mailglass.install`; run migrations.
2. **Preview proof**: boot host app and assert preview mount responds (dev route path).
3. **Send proof**: execute one deterministic mailable send through `Mailglass.deliver/1` (or `deliver_later/1` if queued path is in scope).
4. **Ledger proof**: assert delivery/event records were persisted via existing append-only event pipeline.
5. **Webhook ingest proof**: POST signed provider fixture to mounted webhook route; run through endpoint parser + cached body + verify-first provider path.
6. **Normalization/projection proof**: assert normalized event and downstream projection side effects are visible through public/operator read models.
7. **Operator troubleshooting proof**: assert deterministic symptom -> evidence -> diagnosis path in admin/operator surface (at least one non-happy path, such as signature failure or bounce-driven incident context).
8. **Result emission**: persist checkpoint results for CI and release evidence.

## Data Flow: CI Journey (Clean Baseline)

1. **Trigger**: PR/push/release workflow starts trust-proof job.
2. **Environment**: provision Postgres and clean workspace (no pre-existing host app artifacts).
3. **Baseline creation**: generate clean Phoenix host baseline (same command family already used in post-publish smoke) or reset committed reference app to pristine state.
4. **Dependency resolution policy**:
   - repo-head lane: validates current branch integration behavior
   - published-version lane: validates real adopter install posture from Hex tags
5. **Journey execution**: run the single trust runner command.
6. **Assertions**: fail on missing checkpoints, path-dep leakage, nondeterministic IDs, or operator-flow ambiguity.
7. **Artifacts**: upload logs/checkpoint JSON for release/audit evidence.
8. **Gate behavior**: required on CI for drift prevention; required in release ceremony for published trust claim.

## Suggested Build Order

1. **Reference app baseline + scope lock**
   - Create `reference/host_app` and document strict non-goals.
   - Keep path-dep overrides out of committed proof defaults.
2. **Journey wiring (happy path)**
   - Install -> preview -> send checkpoints through existing public APIs.
3. **Webhook + operator proof wiring**
   - Add signed webhook fixtures and one deterministic troubleshooting path.
4. **Trust runner extraction**
   - Centralize journey execution in one command used by docs and CI.
5. **CI integration**
   - Add required trust job in `ci.yml`.
   - Add published-version trust proof in `post-publish-smoke.yml`.
6. **Docs/contract positioning**
   - Explicitly separate usage proof from API contract truth.
7. **Drift-prevention cadence**
   - Tie trust lane green status to release checklist and routine maintenance cadence.

## Architecture Decisions to Lock Early

1. **One reference app only** (not multiple provider permutations in v1.3).
2. **One deterministic troubleshooting scenario** (not broad operator matrix yet).
3. **One shared proof runner** (avoid duplicate scripts per workflow).
4. **Hex-first trust claim** with explicit non-proof local overrides.
5. **No new product surface** in reference app beyond trust journey support.

## Out of Scope for This Architecture Slice

- Transport-class expansion (`gen_smtp` listener).
- Broad provider matrix expansion.
- Ecosystem integration grab-bag (`SEED-003` auto-promotion).
- Core API redesign or contract redefinition.
- Treating reference-app internals as stable API surface.

## Sources

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/research/milestone-candidates/06-adopter-trust-proof.md`
- `.planning/research/milestone-candidates/SYNTHESIS.md`
- `.planning/research/FEATURES.md`
- `.planning/research/PITFALLS.md`
- `.github/workflows/ci.yml`
- `.github/workflows/post-publish-smoke.yml`
- `test/example/README.md`
- `test/mailglass/install/install_first_preview_smoke_test.exs`
