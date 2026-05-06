# Phase 42: Async Execution And Adopter Proof - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** inbound execution seam, optional Oban gateways, prior inbound plans, docs-contract lanes, and root verification/release automation
**Analogs found:** strong matches for all three roadmap plans

Phase 42 should extend existing seams rather than introducing new architecture.
The repo already has the right boundaries: persist-first ingress, append-only
execution lineage, package-local optional dependency gateways, sibling-package
docs, and root verification automation.

## File Classification

| Likely Phase 42 File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` | service | side effects / classification | current `mailglass_inbound` execution seam | exact-boundary |
| `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` | gateway | runtime mode selection | current package-local optional Oban gateway | exact-gateway |
| `mailglass_inbound/lib/mailglass_inbound/application.ex` or supervisor additions | runtime | supervisor wiring | `lib/mailglass/application.ex` | strong-precedent |
| `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` | worker | queued execution | `lib/mailglass/outbound.ex` + `Mailglass.OptionalDeps.Oban` patterns | new-but-clear |
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | orchestrator | post-persist dispatch | current ingress plug | exact-flow |
| `mailglass_inbound/README.md` | docs | adopter lane | Phase 40/41 README updates | exact-doc-lane |
| `mailglass_inbound/docs/postmark_ingress.md` | docs | provider-specific setup | current doc style | exact-provider-doc |
| `mailglass_inbound/docs/sendgrid_ingress.md` | docs | provider-specific setup | current doc style | exact-provider-doc |
| `mailglass_inbound/docs/api_stability.md` | docs | contract inventory | current docs-contract source | exact-contract |
| `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | test | contract proof | current docs proof lane | exact-proof |
| repo-root verification alias/task files | verification | package-level proof | Phase 37/38/41 root verification posture | strong-precedent |
| `.github/workflows/release-please.yml` | automation | sibling-package release proof | existing linked-version automation | exact-automation |

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/execution.ex`

**Analog:** itself

**Copy these rules**

- keep semantic mailbox outcomes separate from execution failures
- centralize append-only lineage writes in one place
- treat `:duplicate` as a dispatch skip, not a mailbox outcome
- keep public mailbox callback surface unchanged

**Phase 42 adaptation**

- split the current "classify and insert execution run" flow from the trigger
  mechanism so both Oban and Task.Supervisor can call the same execution logic
- make enqueue/dispatch return a compact internal result without exposing
  `%Oban.Job{}`
- preserve replay compatibility by keeping one shared execution runner

---

### `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`

**Analog:** itself plus `lib/mailglass/optional_deps/oban.ex`

**Copy this gateway pattern**

- all direct `Oban.*` references stay behind a package-local gateway
- `available?/0` is the truth test for optional runtime support
- expose a small execution-mode API, not raw third-party structs

**Phase 42 adaptation**

- extend the gateway with enqueue helpers or worker visibility helpers as
  needed
- let the caller ask for `:oban` vs `:task_supervisor` without knowing how the
  decision is implemented

---

### `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`

**Analog:** itself

**Copy this orchestration pattern**

- verify first
- resolve tenant
- normalize
- persist
- respond with compact HTTP truth

**Phase 42 adaptation**

- replace direct inline `Execution.execute/1` with a post-persist dispatch step
- keep `200` acknowledgment semantics tied to persisted receive truth, not
  eventual mailbox result
- preserve duplicate short-circuit behavior

---

### `mailglass_inbound` runtime supervision

**Analog:** `lib/mailglass/application.ex`

**Copy this runtime posture**

- add optional children only when the compiled module exists
- emit one consolidated warning when Oban-backed durability is unavailable
- keep Task supervisor support explicit and visible in app start

**Phase 42 adaptation**

- if `mailglass_inbound` needs its own task supervisor or worker support,
  follow the same optional-child pattern instead of hard-requiring Oban
- reuse boot-warning style to explain bounded fallback semantics once per node

---

### `mailglass_inbound/docs/*.md` and docs contract proof

**Analog:** `40-03-PLAN`, `41-03-PLAN`, existing `docs_contract_test.exs`

**Copy this docs pattern**

- one canonical guide per provider/setup area
- README gives the overview and links to focused guides
- `docs/api_stability.md` guards the stable vs internal boundary
- docs-contract tests fail when claims widen beyond shipped behavior

**Phase 42 adaptation**

- README should become the one obvious inbound adoption lane
- provider guides should stay honest about parser wiring and replay semantics
- docs-contract tests should explicitly reject claims that fallback is durable,
  that replay is public API, or that installer support exists now

---

### Root verification and release proof

**Analog:** prior release/stability phases plus `.github/workflows/release-please.yml`

**Copy this proof pattern**

- root-level verification commands should cover sibling-package truth claims
- release automation should stay explicit about which sibling package files and
  versions participate
- proof artifacts should demonstrate honesty rather than breadth

**Phase 42 adaptation**

- add or extend a root verification lane that proves `mailglass_inbound`
  install/docs/test claims stay green
- ensure release-proof coverage includes `mailglass_inbound` docs/tests and any
  changed package metadata expectations

## Candidate File Sets By Plan

### 42-01: Oban-backed inbound execution plus bounded fallback

- `mailglass_inbound/lib/mailglass_inbound/execution.ex`
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex`
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` or equivalent
- `mailglass_inbound/lib/mailglass_inbound/application.ex` or related runtime
  wiring
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`
- `mailglass_inbound/test/mailglass_inbound/execution_test.exs`
- `mailglass_inbound/test/mailglass_inbound/replay_test.exs`

### 42-02: Canonical install, testing, and operator-trust docs

- `mailglass_inbound/README.md`
- `mailglass_inbound/docs/postmark_ingress.md`
- `mailglass_inbound/docs/sendgrid_ingress.md`
- `mailglass_inbound/docs/api_stability.md`
- `mailglass_admin/docs/operator-trust.md`
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
- targeted doc-oriented ingress/replay tests

### 42-03: Sibling-package release and root verification proof

- root verification aliases/tasks or supporting docs
- `.planning/ROADMAP.md` validation references if needed
- `.github/workflows/release-please.yml`
- `.planning/publish/*` expectations if release proof snapshots need updates
- package test/proof files that root verification commands exercise

## Recommendation

Keep the execution implementation split by trigger, not by semantics. The clean
pattern match is:

- `Ingress.Plug` persists and dispatches
- an internal dispatcher selects Oban or Task.Supervisor
- one shared runner executes mailbox logic and appends lineage
- docs/tests explain the exact durability difference

That yields a coherent three-plan phase with a narrow runtime change in `42-01`,
an honest adopter story in `42-02`, and repo-level proof in `42-03`.
