# Phase 43: Execution Verification Recovery - Research

**Researched:** 2026-05-06
**Domain:** Phase-level execution verification recovery for inbound milestone requirements and audit bookkeeping. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints

No `43-CONTEXT.md` exists, so the planner should treat the explicit user prompt and roadmap entry as the controlling scope. [VERIFIED: codebase grep]

### Locked Decisions

- Research Phase 43, `Execution Verification Recovery`, as a gap-closure/recovery phase. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md]
- The phase restores execution-level verification evidence for the inbound implementation phases rather than adding new product functionality. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md]
- The phase must address `MODEL-01`, `ROUTE-01`, `MAILBOX-01`, `INGRESS-01`, `STORE-01`, `INGRESS-02`, and `STORE-02`. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Research must identify the concrete verification/reporting shape this repo expects, which prior phase artifacts must be repaired or created, the likely command/test evidence sources for phases 39-41, and planning pitfalls around stale bookkeeping versus real execution proof. [VERIFIED: user prompt]

### Claude's Discretion

- Choose the narrowest artifact-recovery plan that satisfies the milestone audit's three-source check without reopening inbound feature design. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- Define a per-plan verification matrix if it helps the planner create `VALIDATION.md` for the repaired phase chain. [VERIFIED: user prompt] [VERIFIED: .planning/config.json]

### Deferred Ideas (OUT OF SCOPE)

- New inbound providers, UI, or broader product functionality are out of scope for Phase 43. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md]
- Phase 42 async/adopter requirement closure (`EXEC-01`, `EXEC-02`, `ADOPT-01`) belongs to Phase 44, not this phase. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MODEL-01 | Adopter can depend on one canonical `%InboundMessage{}` struct. [VERIFIED: .planning/REQUIREMENTS.md] | Recover Phase 39 execution proof from `39-01-SUMMARY.md`, `inbound_message_test.exs`, `router_test.exs`, `mailbox_test.exs`, and `docs_contract_test.exs`. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| ROUTE-01 | Adopter can route inbound mail through one DSL. [VERIFIED: .planning/REQUIREMENTS.md] | Same Phase 39 proof bundle as `MODEL-01`, plus the ordered-route semantics already described in `39-01-SUMMARY.md`. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] |
| MAILBOX-01 | Adopter can implement mailbox handlers with explicit outcomes. [VERIFIED: .planning/REQUIREMENTS.md] | Same Phase 39 proof bundle, especially `mailbox_test.exs` and the execution-lineage context in `39-02-SUMMARY.md`. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-02-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] |
| INGRESS-01 | Maintainer can verify and normalize Postmark inbound payloads. [VERIFIED: .planning/REQUIREMENTS.md] | Recover Phase 40 execution proof from `40-01/02/03-SUMMARY.md`, Postmark provider/plug/persist/docs-contract tests, and the existing `40-VALIDATION.md`. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-01-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-02-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-03-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] |
| STORE-01 | Operator can persist canonical plus raw provider source material. [VERIFIED: .planning/REQUIREMENTS.md] | Same Phase 40 proof bundle, centered on `persist_test.exs`, `plug_test.exs`, and the storage claims in `40-02-SUMMARY.md`. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-02-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| INGRESS-02 | Maintainer can verify and normalize SendGrid inbound payloads. [VERIFIED: .planning/REQUIREMENTS.md] | Replace Phase 41's plan-check `VERIFICATION.md` with execution proof from `41-01/02/03-SUMMARY.md`, `sendgrid_provider_test.exs`, `plug_test.exs`, `mailbox_execution_test.exs`, `replay_test.exs`, and `docs_contract_test.exs`. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-01-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| STORE-02 | Operator can replay stored inbound truth without pretending it is a fresh receive. [VERIFIED: .planning/REQUIREMENTS.md] | Same Phase 41 execution bundle, with `replay_test.exs` and `mailbox_execution_test.exs` as the primary behavior proof and `REQUIREMENTS.md` status reconciliation as bookkeeping follow-through. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- `mailglass_inbound` is a sibling package and must keep its package-local boundaries rather than reaching across to unrelated package internals. [VERIFIED: CLAUDE.md]
- Optional dependencies must stay behind `Mailglass.OptionalDeps.*`-style gateways; for inbound this already exists as `MailglassInbound.OptionalDeps.Oban`, so recovery work should verify that seam rather than bypass it. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-03-SUMMARY.md] [VERIFIED: mailglass_inbound/lib/mailglass_inbound/optional_deps.ex]
- Verification and docs claims must stay honest, narrow, and recommendation-first; this repo already enforces that through docs-contract tests and verification reports. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs]
- `STATE.md` is workflow-managed and should not be the primary recovery target for this phase; the audit blockers are missing or wrong phase verification artifacts plus stale requirement traceability. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- No Node toolchain should be introduced for this work; the existing stack is Mix, ExUnit, markdown artifacts, and `actionlint`. [VERIFIED: CLAUDE.md] [VERIFIED: mix --version] [VERIFIED: actionlint -version]

## Summary

Phase 43 should be planned as an artifact-recovery phase with three deliverables: create `39-VERIFICATION.md`, create `40-VERIFICATION.md`, and replace `41-VERIFICATION.md` with an execution-focused report that cites real code, real tests, and fresh command evidence instead of plan-check output. That is the direct blocker named by the v1.1 milestone audit. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

The repo's accepted verification shape is already visible in recovered Phases 34-38: a phase-level verification report states 3-5 observable truths, inventories required artifacts, proves key links, records behavioral spot-check commands with results, maps requirements to evidence, and calls out any residual manual or bookkeeping debt explicitly. Phase 43 should reuse that shape exactly rather than inventing a new proof format. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md] [VERIFIED: .planning/phases/36-deprecation-and-compatibility-contract/36-VERIFICATION.md] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md] [VERIFIED: .planning/phases/38-release-rehearsal-and-proof-artifacts/38-VERIFICATION.md]

The main planning risk is confusing existing summaries and docs-contract tests with sufficient milestone proof. The audit shows that summaries can mark requirements complete while the milestone still fails because `VERIFICATION.md` is missing, wrong in kind, or contradicted by `REQUIREMENTS.md`. Phase 43 therefore has to repair both execution proof and requirement bookkeeping for the seven Phase 39-41 requirement IDs, but it should not spill into Phase 42's async/adoption closure. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

**Primary recommendation:** Plan Phase 43 as three narrow execution-proof plans plus one bookkeeping closeout step inside the final plan: recover Phase 39 proof, recover Phase 40 proof, then repair Phase 41 proof and `REQUIREMENTS.md` traceability for the seven in-scope IDs. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical inbound contract proof (`MODEL-01`, `ROUTE-01`, `MAILBOX-01`) | API / Backend | Repository / Planning Artifacts | The behaviors are implemented and tested in `mailglass_inbound` modules and ExUnit files, while the recovered proof lives in phase markdown artifacts. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] |
| Postmark ingress and storage proof (`INGRESS-01`, `STORE-01`) | API / Backend | Database / Storage | The verify-first plug and provider normalization live in code/tests, and the storage truth depends on persistence semantics and duplicate indexes. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-01-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-02-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] |
| SendGrid ingress, mailbox execution, and replay proof (`INGRESS-02`, `STORE-02`) | API / Backend | Database / Storage | The behavior spans ingress parsing, post-commit execution, and replay lineage over stored record/evidence truth. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-01-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] |
| Phase verification and audit reconciliation artifacts | Repository / Planning Artifacts | API / Backend | The missing deliverables are markdown verification/validation documents that summarize already-shipped backend behavior and fresh test evidence. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md] |
| Requirement traceability reconciliation for seven inbound IDs | Repository / Planning Artifacts | — | The audit explicitly names stale `REQUIREMENTS.md` status as a blocker for milestone closeout. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` | Runs Mix tasks and ExUnit proof lanes. | Present locally and already used by all phase summaries and verification artifacts. [VERIFIED: mix --version] |
| Erlang/OTP | `28` | Runtime for Elixir test and compile commands. | Present locally and part of the verified toolchain used for the repo. [VERIFIED: mix --version] |
| ExUnit | bundled with Elixir `1.19.5` | Primary execution evidence source for inbound behavior. | Every inbound requirement named by the audit already maps to package-local ExUnit files. [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] |
| Mix aliases + markdown verification reports | repo-local | Canonical proof orchestration and human-auditable evidence output. | Recovered phases 34-38 use phase `VERIFICATION.md` plus command results as the accepted audit format. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mailglass_inbound/docs_contract_test.exs` lane | repo-local | Guards truthfulness of package docs and root proof linkage. | Use whenever a recovered verification report cites docs surface or root semantic verification. [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] [VERIFIED: mix.exs] |
| `actionlint` | `1.7.12` | Workflow syntax proof for release/verification lanes. | Not required for Phase 43's in-scope requirements, but already available for any repo-root proof references. [VERIFIED: actionlint -version] [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-03-SUMMARY.md] |
| Existing `39-VALIDATION.md`, `40-VALIDATION.md` | repo-local | Nyquist evidence matrix to reuse when writing matching verification reports. | Use as the command inventory for Phases 39 and 40 rather than rebuilding the matrix from scratch. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] |
| New `41-VALIDATION.md` | repo-local artifact to create | Missing Nyquist matrix for Phase 41. | Create during Phase 43 because the milestone audit marks Phase 41 validation as missing. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-phase execution `VERIFICATION.md` reports | One milestone-level catch-up report | Rejected because the audit fails on missing phase-level proof and requirement-local three-source evidence, not on absence of a milestone narrative. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |
| Fresh execution reruns | Summary-only reconstruction from existing `*-SUMMARY.md` files | Rejected because recovered phases 34-38 all record behavioral spot-check commands and results, and the audit explicitly asks for execution-level verification. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |
| Reusing Phase 41's current `VERIFICATION.md` | Minor edits to the plan-check report | Rejected because the current file is a planning-check artifact and marks the requirements as `PLANNED`, not satisfied. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |

**Verification prerequisites:**

```bash
mix --version
actionlint -version
test -d mailglass_inbound/deps || (cd mailglass_inbound && mix deps.get)
```

**Version verification:** Use the local toolchain already present in this workspace before rerunning proof commands. `mix --version` reports Elixir `1.19.5` on Erlang/OTP `28`, and `actionlint -version` reports `1.7.12`. [VERIFIED: mix --version] [VERIFIED: actionlint -version]

## Architecture Patterns

### System Architecture Diagram

```text
Roadmap + REQUIREMENTS + milestone audit
        |
        v
Prior phase summaries (39-41) -----> Existing validation files (39, 40; 41 missing)
        |                                      |
        v                                      v
Concrete ExUnit / Mix evidence reruns ------> command results with fresh pass/fail truth
        |                                      |
        +-------------------+------------------+
                            v
          Phase-specific execution VERIFICATION.md artifacts
          - 39-VERIFICATION.md
          - 40-VERIFICATION.md
          - repaired 41-VERIFICATION.md
                            |
                            v
     REQUIREMENTS.md traceability updated for 7 in-scope IDs
                            |
                            v
              Re-run v1.1 milestone audit / downstream closeout
```

The key rule is that markdown artifacts summarize proof; they do not replace proof. Command reruns and existing test lanes are the evidence source, while `VERIFICATION.md` is the audit-facing synthesis layer. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md]

### Recommended Project Structure

```text
.planning/
├── phases/
│   ├── 39-inbound-package-foundation/
│   │   ├── 39-VALIDATION.md
│   │   └── 39-VERIFICATION.md        # create
│   ├── 40-postmark-ingress-and-replayable-persistence/
│   │   ├── 40-VALIDATION.md
│   │   └── 40-VERIFICATION.md        # create
│   ├── 41-sendgrid-ingress-and-mailbox-routing/
│   │   ├── 41-VALIDATION.md          # create
│   │   └── 41-VERIFICATION.md        # replace with execution proof
│   └── 43-execution-verification-recovery/
│       └── 43-RESEARCH.md
└── REQUIREMENTS.md                   # reconcile 7 in-scope IDs after proof is written
```

This structure matches the audit gap list exactly and keeps the recovery outputs attached to the original implementation phases, which is how prior recovered verification phases are organized. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md]

### Pattern 1: Three-Source Requirement Closure

**What:** Treat each requirement as satisfied only when the roadmap/requirements mapping, summary frontmatter, and phase-level execution verification all agree. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

**When to use:** Use for every recovered Phase 39-41 requirement and for the final `REQUIREMENTS.md` reconciliation step. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

**Example:**

```markdown
| Requirement | SUMMARY frontmatter | VERIFICATION.md | Final |
| --- | --- | --- | --- |
| MODEL-01 | listed complete | execution proof present | satisfied |
```

Source pattern: recovered audit and verification reports. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md]

### Pattern 2: Evidence-First Verification Report

**What:** Write 3-5 observable truths, required artifacts, key links, behavioral spot-checks, and requirements coverage from existing code/tests/commands. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md]

**When to use:** Use for `39-VERIFICATION.md`, `40-VERIFICATION.md`, and the replacement `41-VERIFICATION.md`. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

**Example:**

```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| SendGrid + replay bundle | `cd mailglass_inbound && mix test ... --warnings-as-errors` | green | ✓ PASS |
```

Source pattern: recovered verification reports and inbound summaries that already list the exact commands. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md]

### Pattern 3: Validation Matrix Reuse Before Proof Synthesis

**What:** Use existing `VALIDATION.md` command matrices as the baseline evidence plan, then rerun or confirm those commands and synthesize them into `VERIFICATION.md`. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md]

**When to use:** Use for Phases 39 and 40 directly, and create the missing `41-VALIDATION.md` before finishing the repaired Phase 41 verification report. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

**Example:**

```markdown
| Task ID | Requirement | Automated Command |
|---------|-------------|-------------------|
| 41-02-01 | STORE-02 | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` |
```

Source pattern: existing Nyquist validation files plus Phase 41 summaries. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md]

### Anti-Patterns to Avoid

- **Plan-check masquerading as execution proof:** The current Phase 41 `VERIFICATION.md` passed planning checks but still failed the milestone audit because it did not verify executed behavior. Replace it rather than extending it. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- **Summary-only closure:** `*-SUMMARY.md` frontmatter alone is insufficient for the three-source audit. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- **Cross-phase sprawl into Phase 42:** Phase 43 should stop at Phase 39-41 requirement proof and bookkeeping, because Phase 42's missing verification belongs to Phase 44 by roadmap scope. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- **Bookkeeping before proof:** Do not mark `REQUIREMENTS.md` satisfied before the corresponding execution report exists and cites actual command evidence. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Missing execution evidence | New bespoke audit parser or proof harness | Existing ExUnit lanes plus phase `VERIFICATION.md` synthesis | The repo already treats tests and phase reports as the accepted audit contract. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md] |
| Phase 39 and 40 command inventory | New validation matrix from scratch | Existing `39-VALIDATION.md` and `40-VALIDATION.md` | Those files already enumerate the correct requirement-to-command mapping. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] |
| Root verification story | Separate verification alias for recovery only | Existing `mix verify.stability_contract` and package-local test bundles | The root alias already includes inbound docs-contract proof and no-optional-deps compile truth. [VERIFIED: mix.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| Requirement reconciliation | Ad hoc narrative in summaries | Direct `REQUIREMENTS.md` traceability updates after proof creation | The audit explicitly checks `REQUIREMENTS.md` against summaries and verification artifacts. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] |

**Key insight:** Phase 43 is a proof-recovery problem, not a feature-gap problem, so leverage the code and test lanes that already exist and spend effort on auditable synthesis plus traceability cleanup. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-03-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md]

## Common Pitfalls

### Pitfall 1: Treating `VERIFICATION.md` as optional when tests already exist

**What goes wrong:** The phase looks implemented, but the milestone still fails because the workflow requires a phase verification artifact in addition to tests and summaries. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Why it happens:** Executors closed plans with summaries and targeted test notes, but never produced the audit-facing phase report for Phases 39, 40, and 42. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**How to avoid:** Make the recovery plan create the missing phase reports as first-class deliverables, not as optional wrap-up. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Warning signs:** Requirements stay `partial` in milestone audit tables even though the related tests exist. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

### Pitfall 2: Confusing plan validation with execution validation

**What goes wrong:** A plan-check report is preserved as `VERIFICATION.md`, but it cannot satisfy requirement proof. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Why it happens:** Phase 41's current report uses planning language such as `PLANNED` and validates artifact wiring instead of runtime behavior. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md]
**How to avoid:** Replace the file wholesale with the recovered execution template used by Phases 34-38. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/36-deprecation-and-compatibility-contract/36-VERIFICATION.md]
**Warning signs:** The report contains plan-check results, checker references, or no behavioral spot-check section. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md]

### Pitfall 3: Updating `REQUIREMENTS.md` before the evidence bundle is fresh

**What goes wrong:** Bookkeeping looks fixed temporarily, but the next audit still sees unsupported claims or stale timestamps. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Why it happens:** `REQUIREMENTS.md` is easier to edit than rerunning the package-local suite and writing proof. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**How to avoid:** Make requirement-status edits the tail of the final Phase 43 plan, after all phase reports are written. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Warning signs:** Traceability rows change from `Pending` to satisfied while the related phase report is still missing or still plan-check-only. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

### Pitfall 4: Losing time to environment drift instead of proof work

**What goes wrong:** The planner assumes the inbound package suite can be rerun immediately, but local dependencies are missing and no fallback exists for execution-grade proof. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: shell probe `INBOUND_DEPS_MISSING`]
**Why it happens:** The root repo has dependencies, but `mailglass_inbound/deps` is currently absent in this workspace. [VERIFIED: shell probe `ROOT_DEPS_PRESENT`] [VERIFIED: shell probe `INBOUND_DEPS_MISSING`]
**How to avoid:** Put dependency restoration at the top of the first Phase 43 plan and treat it as a prerequisite for all Phase 39-41 reruns. [ASSUMED]
**Warning signs:** `mix test` in `mailglass_inbound` fails before executing the relevant proof lanes. [ASSUMED]

## Code Examples

Verified patterns from repo sources:

### Phase 39 Recovery Bundle

```bash
cd mailglass_inbound && mix test \
  test/mailglass_inbound/inbound_message_test.exs \
  test/mailglass_inbound/router_test.exs \
  test/mailglass_inbound/mailbox_test.exs \
  test/mailglass_inbound/persistence_test.exs \
  test/mailglass_inbound/replay_test.exs \
  test/mailglass_inbound/docs_contract_test.exs \
  --warnings-as-errors
```

Source: existing validation matrix and summaries. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-02-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-03-SUMMARY.md]

### Phase 40 Recovery Bundle

```bash
cd mailglass_inbound && mix test \
  test/mailglass_inbound/ingress/caching_body_reader_test.exs \
  test/mailglass_inbound/ingress/postmark_provider_test.exs \
  test/mailglass_inbound/ingress/plug_test.exs \
  test/mailglass_inbound/ingress/persist_test.exs \
  test/mailglass_inbound/docs_contract_test.exs \
  --warnings-as-errors
```

Source: existing validation matrix and summaries. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-01-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-02-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-03-SUMMARY.md]

### Phase 41 Recovery Bundle

```bash
cd mailglass_inbound && mix test \
  test/mailglass_inbound/ingress/sendgrid_provider_test.exs \
  test/mailglass_inbound/ingress/plug_test.exs \
  test/mailglass_inbound/mailbox_execution_test.exs \
  test/mailglass_inbound/replay_test.exs \
  test/mailglass_inbound/docs_contract_test.exs \
  --warnings-as-errors
```

Source: executed-plan summaries and current test files. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-01-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summary files mark requirements complete. | Summary files plus execution `VERIFICATION.md` plus reconciled `REQUIREMENTS.md` are required for audit satisfaction. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] | Explicit in milestone audit dated 2026-05-06. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] | Planning must allocate time for proof synthesis, not only implementation closeout. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |
| Phase 41 stored a planning-check report in `VERIFICATION.md`. | Phase 41 now needs an execution report matching the recovered Phase 34-38 pattern. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md] [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] | Gap discovered on 2026-05-06 audit. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] | The existing file is not reusable as-is for milestone closure. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |
| Validation existed for 39, 40, and 42 only. | Phase 41 also needs a Nyquist-style validation matrix so the inbound chain is internally consistent. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] | Gap documented on 2026-05-06 audit. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] | Planner should include `41-VALIDATION.md` creation instead of limiting work to reports alone. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |

**Deprecated/outdated:**

- The current `41-VERIFICATION.md` is outdated for milestone-closeout purposes because it verifies planning artifacts rather than executed behavior. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this
> section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `cd mailglass_inbound && mix deps.get` will be the viable way to restore the missing package-local dependency tree before reruns. | Common Pitfalls / Environment Availability | Phase 43 may need an extra environment-repair step or a different dependency bootstrap path before any execution evidence can be refreshed. |
| A2 | `mix test` failures in `mailglass_inbound` would currently occur before the relevant proof lanes if dependencies are not restored. | Common Pitfalls | The planner could underestimate the amount of environment setup needed before writing reports. |

## Open Questions

1. **Should fresh proof be mandatory, or is historical reconstruction acceptable?**
   - What we know: recovered Phases 34-38 all record fresh command evidence and dates inside `VERIFICATION.md`, and the milestone audit asks for execution-level verification. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
   - What's unclear: whether the user would accept reconstruction from summaries alone if an environment issue blocks reruns. [ASSUMED]
   - Recommendation: plan for fresh reruns first and treat summary-only reconstruction as a fallback that still may not satisfy the audit. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

2. **Should Phase 43 create `41-VALIDATION.md` or leave Nyquist repair to Phase 44?**
   - What we know: the audit marks Phase 41 validation as missing while Phase 43 is the execution-recovery phase for 39-41. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: whether the planner wants that matrix bundled into the Phase 41 repair plan or as a separate final bookkeeping action. [ASSUMED]
   - Recommendation: include `41-VALIDATION.md` in Phase 43 because it belongs to the same broken proof chain and avoids leaving 39-41 internally inconsistent. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Mix and ExUnit proof commands | ✓ | `1.19.5` | — [VERIFIED: mix --version] |
| Erlang/OTP | Elixir runtime | ✓ | `28` | — [VERIFIED: mix --version] |
| Mix | All proof commands and aliases | ✓ | `1.19.5` | — [VERIFIED: mix --version] |
| `actionlint` | Optional workflow-proof references | ✓ | `1.7.12` | Skip workflow lint if a given plan does not touch workflow evidence. [VERIFIED: actionlint -version] |
| Root deps tree | Root semantic proof lanes | ✓ | present | — [VERIFIED: shell probe `ROOT_DEPS_PRESENT`] |
| `mailglass_inbound` deps tree | All Phase 39-41 package-local reruns | ✗ | — | `cd mailglass_inbound && mix deps.get` is the likely remediation. [VERIFIED: shell probe `INBOUND_DEPS_MISSING`] [ASSUMED] |

**Missing dependencies with no fallback:**

- Fresh package-local execution proof for Phases 39-41 is blocked until the `mailglass_inbound` dependency tree is restored, because the evidence source is package-local ExUnit lanes. [VERIFIED: shell probe `INBOUND_DEPS_MISSING`] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

**Missing dependencies with fallback:**

- None for execution-grade proof; summaries and existing markdown can help reconstruction, but they do not substitute for the audit's requested execution layer. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix aliases + markdown verification artifacts. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] |
| Config file | `mix.exs`, `mailglass_inbound/mix.exs`, existing phase validation files, and new `41-VALIDATION.md`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md] |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/plug_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` for shared ingress/replay surfaces, plus phase-specific bundles below. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] |
| Full suite command | `cd mailglass_inbound && mix test --warnings-as-errors && cd .. && mix test test/mailglass/stability_contract_test.exs --warnings-as-errors`. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-VALIDATION.md] [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODEL-01 | `%InboundMessage{}` stays canonical and narrow. [VERIFIED: .planning/REQUIREMENTS.md] | unit / docs contract | `cd mailglass_inbound && mix test test/mailglass_inbound/inbound_message_test.exs test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| ROUTE-01 | Router DSL compiles ordered recipient/subject/header matches. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/router_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] |
| MAILBOX-01 | Mailbox outcomes stay inside the locked contract. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] |
| INGRESS-01 | Postmark verify-first plug and normalization path stay honest. [VERIFIED: .planning/REQUIREMENTS.md] | provider / request / integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/caching_body_reader_test.exs test/mailglass_inbound/ingress/postmark_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/caching_body_reader_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| STORE-01 | Canonical row plus raw evidence persist atomically with duplicate collapse. [VERIFIED: .planning/REQUIREMENTS.md] | persistence / integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/persist_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| INGRESS-02 | SendGrid auth/raw-MIME normalization works through shared ingress. [VERIFIED: .planning/REQUIREMENTS.md] | provider / request / integration | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/sendgrid_provider_test.exs test/mailglass_inbound/ingress/plug_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| STORE-02 | Replay and mailbox execution run over stored truth without faking a fresh receive. [VERIFIED: .planning/REQUIREMENTS.md] | integration / regression | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_execution_test.exs test/mailglass_inbound/replay_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] |

### Sampling Rate

- **Per task commit:** run the smallest phase-specific bundle that matches the artifact being written. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md]
- **Per wave merge:** rerun the full bundle for the repaired phase before writing or updating that phase's `VERIFICATION.md`. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md]
- **Phase gate:** `cd mailglass_inbound && mix test --warnings-as-errors` plus any direct root proof lane cited by the recovered reports must be green before `/gsd-verify-work`. [VERIFIED: .planning/phases/42-async-execution-and-adopter-proof/42-VALIDATION.md] [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VALIDATION.md` — missing Nyquist matrix for `INGRESS-02` and `STORE-02`. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- [ ] `mailglass_inbound` dependency restore — required before any fresh reruns in this workspace. [VERIFIED: shell probe `INBOUND_DEPS_MISSING`] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Verify ingress auth behavior through provider and plug tests for Postmark and SendGrid. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| V3 Session Management | no | Not a user-session phase; the recovered work is webhook/auth and replay proof, not browser-session logic. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Tenant resolution and replay-over-stored-truth boundaries are part of the proof chain. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] |
| V5 Input Validation | yes | Canonical message, router, provider, and replay tests enforce accepted shapes and failure paths. [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] |
| V6 Cryptography | no | Phase 43 recovers proof for existing auth and persistence behavior; it does not introduce new crypto controls. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Ingress auth bypass or tenant resolution before verification | Spoofing / Elevation of Privilege | Use `postmark_provider_test.exs`, `sendgrid_provider_test.exs`, and `plug_test.exs` as the execution evidence source because they cover verify-first behavior and explicit failure paths. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| Duplicate receives re-trigger mailbox work | Repudiation / Tampering | Cite `persist_test.exs` and `plug_test.exs` for Postmark and SendGrid duplicate collapse without second execution. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| Replay treated as fresh provider receipt | Tampering / Repudiation | Cite `replay_test.exs` and docs-contract proof that explicitly reject replay-as-fresh wording. [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] |
| Proof documents overstate shipped behavior | Repudiation | Reuse docs-contract tests and phase verification format so claims are anchored to code and command results. [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/v1.1-MILESTONE-AUDIT.md` - exact gap list, three-source requirement standard, and missing-artifact diagnosis. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - Phase 43 scope, in-scope requirement IDs, and Phase 44 boundary. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/phases/39-inbound-package-foundation/*-SUMMARY.md` and `39-VALIDATION.md` - existing execution notes and command matrix for Phase 39. [VERIFIED: .planning/phases/39-inbound-package-foundation/39-01-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-02-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-03-SUMMARY.md] [VERIFIED: .planning/phases/39-inbound-package-foundation/39-VALIDATION.md]
- `.planning/phases/40-postmark-ingress-and-replayable-persistence/*-SUMMARY.md` and `40-VALIDATION.md` - existing execution notes and command matrix for Phase 40. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-01-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-02-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-03-SUMMARY.md] [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-VALIDATION.md]
- `.planning/phases/41-sendgrid-ingress-and-mailbox-routing/*-SUMMARY.md` and current `41-VERIFICATION.md` - execution notes for replacement plus proof that the current report is the wrong kind. [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-01-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-02-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-03-SUMMARY.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md]
- `mailglass_inbound/test/mailglass_inbound/*` and `mix.exs` - concrete execution-evidence lanes and root verification wiring. [VERIFIED: mailglass_inbound/test/mailglass_inbound/inbound_message_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/router_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/sendgrid_provider_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/replay_test.exs] [VERIFIED: mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs] [VERIFIED: mix.exs]

### Secondary (MEDIUM confidence)

- `CLAUDE.md` - project-level constraints that affect how proof and docs should be repaired. [VERIFIED: CLAUDE.md]
- Recovered verification reports for Phases 34-38 - canonical report shape to reuse. [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md] [VERIFIED: .planning/phases/35-stability-contract-audit/35-VERIFICATION.md] [VERIFIED: .planning/phases/36-deprecation-and-compatibility-contract/36-VERIFICATION.md] [VERIFIED: .planning/phases/37-contract-enforcement-and-trust-docs/37-VERIFICATION.md] [VERIFIED: .planning/phases/38-release-rehearsal-and-proof-artifacts/38-VERIFICATION.md]

### Tertiary (LOW confidence)

- None. All material planning claims above were derived from local repo artifacts or direct environment probes. [VERIFIED: local repo audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools and proof sources were verified from local commands or checked-in files. [VERIFIED: mix --version] [VERIFIED: actionlint -version] [VERIFIED: mix.exs]
- Architecture: HIGH - the required recovery outputs and proof chain are explicitly documented in the milestone audit and prior recovered verification reports. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/34-verification-regression-closure/34-VERIFICATION.md]
- Pitfalls: HIGH - each major pitfall is evidenced directly by the current v1.1 audit failure state or the wrong-kind Phase 41 verification artifact. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-VERIFICATION.md]

**Research date:** 2026-05-06
**Valid until:** 2026-05-13 for workflow-state details; this phase is highly sensitive to new verification artifacts landing. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
