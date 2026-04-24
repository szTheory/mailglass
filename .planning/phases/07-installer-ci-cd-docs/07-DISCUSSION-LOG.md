# Phase 7: Installer + CI/CD + Docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `07-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-04-24
**Phase:** 07-installer-ci-cd-docs
**Areas discussed:** Installer write strategy, installer golden-diff test design, CI/CD topology, docs contract enforcement

---

## Installer Write Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| AST/token-aware structural patcher | Semantic file rewrites via AST traversals for router/runtime/config | |
| Sentinel-managed block insertion | Installer-owned begin/end blocks with rerun replacement | |
| Hybrid operation engine | Owned-file create + anchored snippets + managed blocks + sidecars + manifest | ✓ |

**User's choice:** One-shot recommendation accepted; selected hybrid operation engine.
**Notes:** Deep-dive request emphasized least surprise, high DX, and idempotent reruns with sidecar conflicts rather than clobbering.

---

## Installer Golden-Diff Test Design

| Option | Description | Selected |
|--------|-------------|----------|
| Full-tree golden diff | Snapshot full generated host tree and compare with normalized diff | ✓ |
| Manifest-only snapshot | Snapshot normalized hashes/manifest with targeted assertions | |
| Action-plan snapshot + smoke | Snapshot operation plan plus minimal output smoke checks | |

**User's choice:** One-shot recommendation accepted; selected full-tree golden diff with constrained normalization.
**Notes:** Reviewability in PRs prioritized over minimal snapshot churn.

---

## CI/CD Topology and Required Gates

| Option | Description | Selected |
|--------|-------------|----------|
| Monolithic workflow | One large CI workflow containing all lanes and release logic | |
| Split-by-concern workflows | Separate workflows for CI, dependency review, actionlint, release, publish, advisory live tests | ✓ |
| Hybrid with reusable workflows | Shared `workflow_call` modules with thin wrappers | |

**User's choice:** One-shot recommendation accepted; selected split-by-concern topology.
**Notes:** Chosen for failure isolation, clear required checks, and secure publish separation.

---

## Docs Contract Enforcement Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Snippet-compile only | Compile README/guide snippets and validate task names | |
| Doctest-first only | Rely primarily on API doctests for contract confidence | |
| Hybrid trust pyramid | Doctests + snippet compile checks + host-app smoke docs checks | ✓ |

**User's choice:** One-shot recommendation accepted; selected hybrid docs trust pyramid.
**Notes:** Goal is trustworthy docs with pragmatic CI cost and strong onboarding guarantees.

---

## Additional Preference Decision

| Option | Description | Selected |
|--------|-------------|----------|
| Keep existing discuss flow | No config changes | |
| Shift-left recommendations | Enable research-before-questions while keeping high-impact override points | ✓ |

**User's choice:** Shift-left requested and applied.
**Notes:** Set `workflow.research_before_questions = true` in `.planning/config.json`.

---

## Claude's Discretion

- Exact installer marker naming and conflict sidecar formatting
- Exact normalization token conventions in golden harness
- Exact workflow file partitioning names, while preserving required-check semantics

## Deferred Ideas

- Full AST-first patcher as default installer strategy (deferred)
- Reusable `workflow_call` abstraction for CI workflows (deferred)
- Always-on heavy docs smoke for every PR (deferred pending runtime baseline)
