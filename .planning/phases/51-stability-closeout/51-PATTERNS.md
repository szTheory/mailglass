# Phase 51: Stability Closeout - Pattern Map

**Mapped:** 2026-05-26
**Files/work areas analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md` | config | batch | `.planning/milestones/v1.1-phases/43-execution-verification-recovery/43-VALIDATION.md` | exact |
| `.planning/milestones/v1.0-MILESTONE-AUDIT.md` | config | batch | `.planning/milestones/v0.1-MILESTONE-AUDIT.md` | exact |
| `scripts/setup_branch_protection.sh` | utility | request-response | `scripts/verify_support_contract.sh` + `.github/workflows/ci.yml` | role-match |
| `.github/workflows/branch-protection-drift.yml` | config | event-driven | existing workflow shell around `scripts/setup_branch_protection.sh` | exact |
| `MAINTAINING.md` | config | request-response | existing required-checks + release-runbook sections | exact |
| `test/support/citext_probe.ex` | utility | transform | existing root citext probe + `test/test_helper.exs` + `test/support/data_case.ex` | exact |
| `mailglass_admin/test/support/citext_probe.ex` | utility | transform | `test/support/citext_probe.ex` | exact |
| `test/mailglass/persistence_integration_test.exs` | test | transform | existing phase-2 UAT setup around `CitextProbe.run/1` | exact |
| `test/mailglass/migration_test.exs` | test | batch | existing migration round-trip harness | exact |
| `test/mailglass/boundary_test.exs` | test | transform | existing Boundary attribute assertions | exact |
| `lib/mailglass/operator/support_summary.ex` | service | request-response | existing tenant-scoped read-model/query shape | exact |

## Work Area Assignments

### 1. Phase 35 Nyquist Bookkeeping Closeout

**Primary files to read first**
- `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md`
- `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VERIFICATION.md`
- `.planning/milestones/v1.1-phases/43-execution-verification-recovery/43-VALIDATION.md`
- `.planning/milestones/v0.6-phases/34-verification-regression-closure/34-VALIDATION.md`

**Copy these patterns**
- Frontmatter truth shape from [43-VALIDATION.md](/Users/jon/projects/mailglass/.planning/milestones/v1.1-phases/43-execution-verification-recovery/43-VALIDATION.md:1): `status`, `nyquist_compliant`, and `wave_0_complete` are aligned in frontmatter, not left stale after verification exists.
- Validation sign-off shape from [34-VALIDATION.md](/Users/jon/projects/mailglass/.planning/milestones/v0.6-phases/34-verification-regression-closure/34-VALIDATION.md:66): completion evidence is explicit and the approval line is updated once the phase is genuinely closed.
- Verification-to-validation debt callout from [35-VERIFICATION.md](/Users/jon/projects/mailglass/.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VERIFICATION.md:69): preserve an audit trail, but remove the contradiction once the bookkeeping is repaired.

**Planner note**
- Treat this as artifact reconciliation only. Do not reopen Phase 35 implementation or rewrite its proof language.

### 2. v1.0 / v1.2 Audit Reconciliation

**Primary files to read first**
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md`
- `.planning/milestones/v0.1-MILESTONE-AUDIT.md`
- `.planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md`
- `.planning/REQUIREMENTS.md`

**Copy these patterns**
- Itemized debt ledger shape from [v0.1-MILESTONE-AUDIT.md](/Users/jon/projects/mailglass/.planning/milestones/v0.1-MILESTONE-AUDIT.md:108): each carry-forward item is individually named, localized, and given an action or rationale.
- “Pass with debt, not blocker” framing from [v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/mailglass/.planning/milestones/v1.0-MILESTONE-AUDIT.md:41): executive summary first, then specific debt bullets, then follow-up list.
- Carry-forward summary pattern from [50.7-01-SUMMARY.md](/Users/jon/projects/mailglass/.planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md:31): unresolved items are phrased as concrete next-phase inputs, not vague “cleanup later.”

**Planner note**
- CLOSE-05 should end with per-WR disposition lines, not one bulk “all addressed” sentence.

### 3. Branch-Protection Automation Drift

**Primary files to read first**
- [MAINTAINING.md](/Users/jon/projects/mailglass/MAINTAINING.md:94)
- [mix.exs](/Users/jon/projects/mailglass/mix.exs:263)
- [.github/workflows/ci.yml](/Users/jon/projects/mailglass/.github/workflows/ci.yml:85)
- [scripts/setup_branch_protection.sh](/Users/jon/projects/mailglass/scripts/setup_branch_protection.sh:1)
- [.github/workflows/branch-protection-drift.yml](/Users/jon/projects/mailglass/.github/workflows/branch-protection-drift.yml:1)

**Copy these patterns**
- Required-check truth source from [MAINTAINING.md](/Users/jon/projects/mailglass/MAINTAINING.md:96): repo-root semantic entrypoint plus the exact branch-protection buckets, including the inbound docs lane.
- Alias truth source from [mix.exs](/Users/jon/projects/mailglass/mix.exs:263): `verify.stability_contract` is the canonical sequence; branch protection should mirror that truth, not legacy CI job names.
- CI job-name truth source from [ci.yml](/Users/jon/projects/mailglass/.github/workflows/ci.yml:85) and [ci.yml](/Users/jon/projects/mailglass/.github/workflows/ci.yml:541): required check names must match workflow job names exactly.
- Script shape from [setup_branch_protection.sh](/Users/jon/projects/mailglass/scripts/setup_branch_protection.sh:35): keep the explicit `REQUIRED_CHECKS` array and one idempotent `gh api -X PUT`.
- Drift workflow wrapper from [branch-protection-drift.yml](/Users/jon/projects/mailglass/.github/workflows/branch-protection-drift.yml:25): scheduled + manual entrypoint, PAT presence guard, then shell script delegation.

**Planner note**
- The likely fix is to update the required contexts to the current support-contract buckets, not to invent a second source of truth or turn the workflow into a docs-only reminder.

### 4. Citext Race Structural Remediation

**Primary files to read first**
- [test/support/citext_probe.ex](/Users/jon/projects/mailglass/test/support/citext_probe.ex:1)
- [test/test_helper.exs](/Users/jon/projects/mailglass/test/test_helper.exs:55)
- [test/support/data_case.ex](/Users/jon/projects/mailglass/test/support/data_case.ex:38)
- [test/mailglass/migration_test.exs](/Users/jon/projects/mailglass/test/mailglass/migration_test.exs:125)
- [test/mailglass/persistence_integration_test.exs](/Users/jon/projects/mailglass/test/mailglass/persistence_integration_test.exs:50)
- [mailglass_admin/test/support/citext_probe.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/citext_probe.ex:1)
- [mailglass_admin/test/test_helper.exs](/Users/jon/projects/mailglass/mailglass_admin/test/test_helper.exs:17)

**Copy these patterns**
- Root probe contract from [citext_probe.ex](/Users/jon/projects/mailglass/test/support/citext_probe.ex:29): configurable `repo`, injectable `probe_fun`, computed `max_attempts`, and explicit exhaustion raise.
- Current recovery semantics from [test_helper.exs](/Users/jon/projects/mailglass/test/test_helper.exs:55) and [data_case.ex](/Users/jon/projects/mailglass/test/support/data_case.ex:52): warm once at suite boot, then probe every sandbox checkout after migrations.
- DDL failure-mode anchor from [migration_test.exs](/Users/jon/projects/mailglass/test/mailglass/migration_test.exs:125): the `down/0` round-trip drops and recreates `citext`; any structural fix must still preserve this proof.
- Integration-lane documentation of the race from [persistence_integration_test.exs](/Users/jon/projects/mailglass/test/mailglass/persistence_integration_test.exs:45): keep the comments truthful about why the race exists and what the harness is protecting against.
- Admin parity pattern from [mailglass_admin/test/test_helper.exs](/Users/jon/projects/mailglass/mailglass_admin/test/test_helper.exs:36): root/admin harnesses should not drift into different failure-handling behavior.

**Planner note**
- Default plan shape should be: fix the invalidation path first, then simplify probes if the structural fix makes them lighter. Do not start by adding more retries.

### 5. Boundary-Warning Closeout In Support/Admin Verification Lanes

**Primary files to read first**
- [test/mailglass/boundary_test.exs](/Users/jon/projects/mailglass/test/mailglass/boundary_test.exs:1)
- [test/support/admin_case.ex](/Users/jon/projects/mailglass/test/support/admin_case.ex:1)
- [mailglass_admin/test/support/live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:1)
- [mailglass_admin/test/support/inbound_fixtures.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/inbound_fixtures.ex:1)
- [mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex:1)
- [lib/mailglass/operator/support_summary.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/support_summary.ex:1)
- [test/mailglass/operator/support_summary_test.exs](/Users/jon/projects/mailglass/test/mailglass/operator/support_summary_test.exs:10)

**Copy these patterns**
- Boundary assertion style from [boundary_test.exs](/Users/jon/projects/mailglass/test/mailglass/boundary_test.exs:6): assert exact `deps`/`exports` invariants rather than muting warnings with broader allowlists.
- Helper placement rule from [admin_case.ex](/Users/jon/projects/mailglass/test/support/admin_case.ex:5): root package wrappers stay generic; admin endpoint/browser seams stay package-local.
- Admin test setup shape from [live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:33): package-local repo ownership + package-local probe call + tenant setup.
- Optional-dep gateway pattern from [optional_deps/mailglass_inbound.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex:10): keep cross-package access behind runtime gateways and `apply/3`, not new compile-time boundary edges.
- Query/read-model shape from [support_summary.ex](/Users/jon/projects/mailglass/lib/mailglass/operator/support_summary.ex:20): tenant-scoped pure query service with explicit helper functions and no UI/test-support leakage.

**Planner note**
- Prefer moving helpers or narrowing references over editing Boundary rules. Phase 51 should reduce warning noise without widening the runtime dependency graph.

### 6. WR-01..WR-06 Historical Closeout

**Primary files to read first**
- `.planning/milestones/v0.1-MILESTONE-AUDIT.md`
- [lib/mailglass/webhook/plug.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:296)
- [lib/mailglass/webhook/reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:97)
- [lib/mailglass/webhook/providers/postmark.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/postmark.ex:246)
- [lib/mailglass/migrations/postgres.ex](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres.ex:54)

**Copy these patterns**
- Audit-entry style from [v0.1-MILESTONE-AUDIT.md](/Users/jon/projects/mailglass/.planning/milestones/v0.1-MILESTONE-AUDIT.md:109): each WR item gets a concrete `where`, `problem`, and live-risk statement.
- Current live code for WR-05 from [webhook/plug.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:296): tenant resolution still receives `conn` and `raw_body`; Phase 51 must decide whether this is still acceptable or should be narrowed.
- Current live code for WR-02/03 from [webhook/reconciler.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:101): uses `Clock.utc_now/0` already and has a still-complex reconciliation transaction path; audit should distinguish fixed vs residual risk honestly.
- Current live code for WR-04 from [postmark.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/postmark.ex:246): synthetic event IDs now include record type + ID/message ID + timestamp; verify collision concern against the current shape before carrying it forward.
- Example of prior WR retirement in code comments from [migrations/postgres.ex](/Users/jon/projects/mailglass/lib/mailglass/migrations/postgres.ex:54): when a WR is fixed, the code now cites the risk directly and explains the mitigation.

**Planner note**
- There is no surviving `04-REVIEW.md` artifact in `.planning/`; use the v0.1 audit plus live code as the source of truth for CLOSE-05.

## Shared Patterns

### Single Truth Source First
- Use [MAINTAINING.md](/Users/jon/projects/mailglass/MAINTAINING.md:96), [mix.exs](/Users/jon/projects/mailglass/mix.exs:263), and [ci.yml](/Users/jon/projects/mailglass/.github/workflows/ci.yml:85) as the required-check truth chain, in that order.

### Artifact Reconciliation Over Reimplementation
- Use [35-VERIFICATION.md](/Users/jon/projects/mailglass/.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VERIFICATION.md:69) and [v1.0-MILESTONE-AUDIT.md](/Users/jon/projects/mailglass/.planning/milestones/v1.0-MILESTONE-AUDIT.md:45) as the model: fix stale status metadata and debt notes without rewriting historical proof unless it is false.

### Package-Local Test Support
- Use [test/support/admin_case.ex](/Users/jon/projects/mailglass/test/support/admin_case.ex:5) and [mailglass_admin/test/support/live_view_case.ex](/Users/jon/projects/mailglass/mailglass_admin/test/support/live_view_case.ex:33): keep admin-only harness code under `mailglass_admin/test/support`, not root test support.

### Boundary Fixes Through Seams, Not Exceptions
- Use [mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex:21) and [test/mailglass/boundary_test.exs](/Users/jon/projects/mailglass/test/mailglass/boundary_test.exs:18): runtime gateway + explicit boundary assertions is the preferred pattern.

## Phase 51 Anti-Patterns

- Do not “fix” CLOSE-02 by documenting a manual GitHub UI checklist again. The repo already has script + workflow seams; Phase 51 should repair drift in those seams.
- Do not treat `CitextProbe` retries as the primary fix. Probes are safety nets; the plan should target the shared type-cache invalidation path exposed by `migration_test.exs`.
- Do not widen `Boundary` deps or add blanket warning suppressions to silence support/admin verification noise.
- Do not rewrite archived Phase 35 or v1.0 proof artifacts wholesale. Change only the fields and rows that are stale or false.
- Do not close WR-01..WR-06 as a bundle. Each item needs its own “fixed in code” or “closed-no-action with rationale” disposition.
- Do not let branch-protection required checks drift away from `verify.stability_contract` / `scripts/verify_support_contract.sh` / current CI job names.

## No Exact Analog Found

| File / Work Area | Role | Data Flow | Reason |
|---|---|---|---|
| Historical `04-REVIEW.md` closeout source | config | batch | The original Phase 4 review artifact is not present in `.planning/`; use `.planning/milestones/v0.1-MILESTONE-AUDIT.md` plus live webhook code as the replacement source. |

## Metadata

**Analog search scope:** `.planning/`, `scripts/`, `.github/workflows/`, `lib/`, `test/`, `mailglass_admin/test/`
**Pattern extraction date:** 2026-05-26
