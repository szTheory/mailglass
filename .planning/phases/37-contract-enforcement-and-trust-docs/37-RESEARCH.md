# Phase 37: Contract Enforcement and Trust Docs - Research

**Researched:** 2026-05-05
**Domain:** Elixir library contract enforcement, testing-contract docs, and admin trust semantics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-37-01..05:** Ship one semantic repo-root stability proof built from existing lightweight checks rather than a manifest snapshot, export diff, or ABI-style system.
- **D-37-06..11:** Make `guides/testing.md` the canonical adopter-facing testing contract and keep it exactly aligned with shipped helper behavior, async/process ownership semantics, and Oban lanes.
- **D-37-12..15:** Publish stable admin trust semantics around router macros, auth, session, mount, destructive-action, and replay behavior without freezing DOM, component, or LiveView internals.
- **D-37-16..18:** Prefer recommendation-first planning and lightweight enforcement that points at promised seams instead of widening the contract through raw reachability.

### the agent's Discretion
- Exact proof alias/task names and how the repo-root command composes existing checks.
- Exact file names and section ordering for trust docs and contract tests.
- Exact split between docs assertions, docs drift checks, and targeted semantic tests, as long as the failures stay humane and seam-specific.

### Deferred Ideas (OUT OF SCOPE)
- Heavy manifest/snapshot proof artifacts.
- Broadening the `v1.x` contract beyond the surfaces already declared in Phase 35 and Phase 36.
- Freezing admin DOM, CSS, component, or LiveView internals.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Maintainer can run one stability verification workflow that detects drift in the documented public surface for both `mailglass` and `mailglass_admin`. | Compose the existing root/admin support-contract aliases, docs-contract checks, narrow leak check, and no-optional-deps compile lane behind one semantic repo-root entrypoint. |
| PROOF-02 | Maintainer can detect leaked internal modules, docs, types, tasks, or sibling-package contract violations before a release is cut. | Extend the current stability/docs checks with targeted contract assertions against the exact documented inventories and trust docs. |
| PROOF-03 | Adopter can rely on a documented testing contract for inline, async, Oban, and cross-process delivery workflows without guessing which helpers or modes are stable. | Rewrite `guides/testing.md` into the canonical story and prove the documented helper semantics against shipped code/tests. |
| PROOF-04 | Adopter can rely on stable admin mount, auth, and operator-action docs without depending on DOM, component, or LiveView implementation details. | Publish one canonical admin trust doc tied to the stable router/auth/session/replay seams and prove it with targeted admin contract tests. |
</phase_requirements>

## Summary

Phase 37 is not a new runtime-feature phase. The repo already has the primitives it needs: a narrow core leak checker in `lib/mix/tasks/mailglass.stability.check.ex`, Tier 1 docs drift checks in `lib/mix/tasks/mailglass.docs.check.ex`, root/admin support-contract aliases in `mix.exs` and `mailglass_admin/mix.exs`, and a repo-root orchestration script in `scripts/verify_support_contract.sh`. The right move is to strengthen those into one semantic proof workflow and connect them to the canonical testing and admin trust docs rather than inventing a second enforcement system.

The current testing guide is materially too thin for the promised contract. `guides/testing.md` only covers Fake + `assert_mail_sent`, while the shipped surface in `Mailglass.TestAssertions`, `Mailglass.MailerCase`, and `Mailglass.ObanHelpers` already defines much richer semantics: `last_mail/0` reads Fake storage instead of consuming the mailbox, `wait_for_mail/1` is timeout-based, cross-process cases should prefer `Fake.allow/2` or sandbox ownership transfer before shared mode, and Oban `:inline` / `:manual` lanes both require `async: false` plus the `oban_jobs` table. Phase 37 should turn those behaviors into the canonical adopter story and keep the docs contract-tested.

The admin trust story is also already present in code and partial docs. `MailglassAdmin.Router` documents the stable mount macros and option schema, `MailglassAdmin.Auth` is the stable adopter-owned authorization seam, `mailglass_admin/README.md` already explains operator replay/action-time auth semantics, and `guides/operator-incident-support.md` already distinguishes replay from reconcile. The missing piece is one canonical trust doc that states the stable promises cleanly and one proof bundle that fails when those semantics drift.

**Primary recommendation:** plan this phase as three execution slices:
1. one repo-root semantic proof workflow for PROOF-01 and PROOF-02,
2. one canonical testing-contract docs-and-proof slice for PROOF-03,
3. one canonical admin trust-doc docs-and-proof slice for PROOF-04.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Repo-root semantic proof workflow | root `mix.exs` / `scripts/verify_support_contract.sh` | root/admin package aliases | The maintainer entrypoint should stay at repo root, but it should delegate to existing package-local authorities instead of replacing them. |
| Public-surface leak and docs drift enforcement | Mix tasks + ExUnit contract tests | canonical docs | Existing Mix tasks already encode the "lightweight, actionable" posture; tests can add seam-specific guarantees without noisy scanning. |
| Testing trust contract | `guides/testing.md` | `Mailglass.TestAssertions`, `Mailglass.MailerCase`, docs contract tests | The guide should teach adopters the supported path, but its truth comes from the shipped helper behavior and tests. |
| Admin trust contract | canonical admin trust doc | `MailglassAdmin.Router`, `MailglassAdmin.Auth`, operator tests, incident guide | The stable promises are docs-level, but they must stay tied to the router/auth/session/replay semantics already in code. |

## Project Constraints

- The project explicitly prefers honest-surface, recommendation-first, lightweight enforcement over heavy compatibility infrastructure.
- `mix compile --no-optional-deps --warnings-as-errors` remains part of the support contract and must stay inside the proof workflow.
- `mailglass_admin` is a matched sibling package with its own support-contract lane; the repo-root proof should compose it rather than flatten it.
- The stable contract was intentionally narrowed in Phases 35 and 36; Phase 37 should prove that inventory, not widen it by implication.

## Recommended Plan Shape

### Slice 1: Semantic repo-root proof workflow

**Goal:** make one top-level command prove the documented surface across core and admin with humane failures.

**What to build**
- Add one semantic repo-root verification alias or task such as `mix verify.stability_contract` that composes:
  - core support-contract verification
  - admin support-contract verification
  - `mix compile --no-optional-deps --warnings-as-errors`
- Extend contract tests so they assert the promised docs and inventories exist and are wired into the proof path.
- Keep failures seam-specific: "testing contract drifted", "admin trust contract drifted", "public-surface leak detected", not raw export dumps.

**Likely files**
- `mix.exs`
- `scripts/verify_support_contract.sh`
- `lib/mix/tasks/mailglass.stability.check.ex`
- `lib/mix/tasks/mailglass.docs.check.ex`
- `test/mailglass/docs_contract_test.exs`
- new root contract tests for stability/trust-doc coverage

### Slice 2: Canonical testing contract

**Goal:** make `guides/testing.md` the single truthful adopter story for mail testing.

**What to publish**
- `deliver/2` baseline
- `deliver_later/2` baseline
- optional Oban lanes (`:inline`, `:manual`) with `async: false` and `oban_jobs` caveats
- cross-process/browser/LiveView ownership transfer guidance (`Fake.allow/2`, sandbox allowance first; shared/global only as fallback)
- PubSub/webhook assertion lane
- footguns and strict-CI posture

**What must stay exact**
- `last_mail/0` reads Fake storage, not the process mailbox
- `wait_for_mail/1` blocks on timeout
- `MailerCase` default inline/test setup semantics
- shared/global mode is exceptional, not the default

**Likely files**
- `guides/testing.md`
- `lib/mailglass/test_assertions.ex`
- `test/support/mailer_case.ex`
- `test/support/oban_helpers.ex`
- `test/mailglass/test_assertions_test.exs`
- `test/mailglass/mailer_case_test.exs`
- `test/mailglass/test_assertions_pubsub_test.exs`
- targeted docs tests for the testing guide

### Slice 3: Canonical admin trust doc

**Goal:** document the stable operator/admin semantics without freezing internal UI implementation.

**What to publish**
- stable router macros and documented options
- `MailglassAdmin.Auth.authorize/2` as the adopter-owned auth seam
- session-key semantics for `subject_id`, optional `tenant_id`, optional `auth_method`, optional `recent_auth_at`
- mount-time `:operator_access`
- action-time `:destructive_action`
- exact-target, tenant-scoped, ledger-audited replay semantics
- explicit replay-vs-reconcile distinction

**What must stay intentionally internal**
- LiveView modules
- component modules
- DOM/CSS shape
- event names
- modal layout/details
- internal assign names and mount plumbing

**Likely files**
- new canonical admin trust doc under `guides/` or `mailglass_admin/docs/`
- `mailglass_admin/README.md`
- `mailglass_admin/docs/api_stability.md`
- `guides/operator-incident-support.md`
- `mailglass_admin/test/mailglass_admin/router_test.exs`
- `mailglass_admin/test/mailglass_admin/auth_test.exs`
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs`
- targeted docs tests for the admin trust doc

## Architecture Patterns

### Pattern 1: Compose existing proof lanes instead of replacing them

The repo already uses:
- `mix verify.support_contract.core`
- `mix verify.support_contract.admin`
- `mix compile --no-optional-deps --warnings-as-errors`
- `scripts/verify_support_contract.sh`

Phase 37 should wrap these into one semantically named maintainer entrypoint and add the missing trust-doc assertions around them.

### Pattern 2: Canonical doc plus executable proof

The strongest repo pattern from Phases 35 and 36 is "publish one canonical doc, then add deterministic tests and docs checks that assert its exact promises." Phase 37 should reuse that pattern for:
- `guides/testing.md`
- the canonical admin trust doc
- any new proof-workflow naming/docs

### Pattern 3: Stable seam docs, internal implementation freedom

Admin docs should promise:
- mount seam
- auth seam
- session semantics
- authorization timing
- replay semantics

They should explicitly refuse to promise:
- DOM selectors
- component APIs
- LiveView modules
- internal hooks/wiring

### Anti-Patterns to Avoid

- Export-diff or xref-heavy enforcement that freezes internals accidentally.
- Rewriting `guides/testing.md` as a broad brainstorm instead of a recommendation-first contract.
- Documenting shared/global test mode as the default path.
- Treating replay and reconcile as interchangeable repair tools.
- Letting admin README prose and the canonical trust doc drift into competing authorities.

## Common Pitfalls

### Pitfall 1: Docs describe older helper behavior

`guides/testing.md` currently says `last_mail()` returns from the current process mailbox, but the shipped implementation reads Fake-backed delivery storage. Any plan must include proof that docs match the helper semantics exactly.

### Pitfall 2: One "stability" command without semantic coverage

A renamed root alias is not enough if it only shells existing commands without proving the new testing/admin trust docs. The proof workflow must fail when the promised seams drift, not just when generic compile/tests fail.

### Pitfall 3: Admin docs freeze UI internals accidentally

Examples that lean on selectors, component names, or modal wording would silently widen the contract. Keep examples semantic and seam-centered.

### Pitfall 4: Cross-process testing guidance defaults to global/shared mode

The shipped posture in `MailerCase` prefers explicit ownership transfer and keeps shared/global mode as the escape hatch. The docs must preserve that order.

## Key Insight

Phase 37 should inherit the same pattern that made Phases 35 and 36 coherent: one canonical contract doc per concern, plus repo-native deterministic proof that the docs are still true. The new work is mostly wiring and trust-proof, not new runtime capability.
