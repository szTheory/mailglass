---
phase: 143
slug: test-harness-truth
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 143 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test runtime → PostgreSQL | Test helpers inspect and temporarily alter shared database and sandbox state. | SQL identifiers, schema names, pool ownership state |
| Test module → process-global state | Case helpers temporarily modify application environment and sandbox modes used by later modules. | Schema configuration and pool mode |
| Formatter → CI logs and committed evidence | Suite truth records and counts are retained in logs and phase artifacts. | Module/schema/relation names, counts, signature atoms |
| Workflow dispatch inputs → shell and gate verdict | Maintainer inputs influence probes and the release-gate exception path. | Booleans, deadlines, free-text reason |
| GitHub Actions API → publish decision | Runtime job names and conclusions determine whether publishing proceeds. | Workflow/job metadata and commit SHA |
| Throwaway refs → remote workflows | Temporary tags and branches exercise real gating paths. | Git refs and deliberately failing test changes |
| CI output → enforcement constants | Observed suite counts become committed minimum thresholds. | Aggregate test counts and run provenance |
| Lint configuration → ownership guarantee | Credo reachability and allowlists enforce the supported sandbox API boundary. | AST call sites and allowlist entries |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-143-01 | Information Disclosure | Suite truth ledger output | medium | mitigate | Whitelisted metadata only; formatter contract tests | closed |
| T-143-02 | Repudiation | Unreachable/erroring baseline probe | high | mitigate | `:cannot_verify` violation in `sandbox_ownership.ex` and formatter | closed |
| T-143-03 | Tampering | Ownership healing call | medium | mitigate | Healing restricted to synchronous module completion | closed |
| T-143-04 | Information Disclosure | Test support in Hex package | low | accept | Package allowlist restricts output to `lib`; accepted as R-143-01 | closed |
| T-143-05 | Tampering | Dispatch inputs reaching shell | high | mitigate | Inputs bound through `env:` in `gate-self-test.yml` | closed |
| T-143-06 | Repudiation | Probe deadline path | high | mitigate | Never-appeared and timeout paths fail closed | closed |
| T-143-07 | Denial of Service | Scheduled probe opening PRs | medium | mitigate | Probe remains `workflow_dispatch` only | closed |
| T-143-08 | Elevation of Privilege | Self-test workflow permissions | medium | accept | Existing permissions are necessary and unchanged; accepted as R-143-02 | closed |
| T-143-09 | Information Disclosure | Committed ledgers and excerpts | high | mitigate | Artifacts exclude addresses, subjects, recipients, and bound values | closed |
| T-143-10 | Repudiation | Mechanism account evidence | medium | mitigate | Required-lane contract test with anti-vacuity guard | closed |
| T-143-11 | Tampering | CI lane registry edit | high | mitigate | Lane cardinality and set-equality drift tests | closed |
| T-143-12 | Denial of Service | Deliberate sandbox leak | high | mitigate | Pre-registered cleanup and repeated regression coverage | closed |
| T-143-13 | Repudiation | Message-string assertions | high | mitigate | Failure identity asserted structurally | closed |
| T-143-14 | Information Disclosure | Test support in Hex package | low | accept | Package allowlist restricts output to `lib`; accepted as R-143-03 | closed |
| T-143-15 | Tampering | Raw shared-mode call deletion | high | mitigate | Behaviour-preserving wrapper and effect-level regression tests | closed |
| T-143-16 | Repudiation | Async-value alteration | high | mitigate | Async shape preserved and guarded by tests | closed |
| T-143-17 | Denial of Service | Ownership-timeout retuning | medium | mitigate | Bounded-healing timeout behavior retained and tested | closed |
| T-143-18 | Tampering | Teardown reordering | high | mitigate | Reverse callback ordering documented and covered | closed |
| T-143-19 | Denial of Service | Loss of healing behavior | medium | mitigate | Mode switch preserved through `unsandboxed_module/1` | closed |
| T-143-20 | Repudiation | Mixed restoration fix | high | mitigate | Mode and app-environment responsibilities remain separate | closed |
| T-143-21 | Repudiation | Conditional baseline restoration | high | mitigate | Unconditional restore followed by verified baseline assertion | closed |
| T-143-22 | Tampering | Direct config-cache restoration | high | mitigate | `with_schema!/2` uses supported env and invalidation path | closed |
| T-143-23 | Denial of Service | Schema/search-path drift | high | mitigate | Restore-first ordering and per-module drift detection | closed |
| T-143-24 | Repudiation | Unproven lint reachability | high | mitigate | Positive and negative Credo integration fixtures | closed |
| T-143-25 | Repudiation | Vacuous AST matching | high | mitigate | Anti-vacuity fixture counts and negative cases | closed |
| T-143-26 | Elevation of Privilege | Growing ownership allowlist | medium | mitigate | Allowlist cardinality and integration sentinel | closed |
| T-143-27 | Tampering | Widening Credo file scope | medium | mitigate | Narrow configuration and integration coverage | closed |
| T-143-28 | Repudiation | Inert signature classifier | high | mitigate | Exact nested-term classifier regression | closed |
| T-143-29 | Repudiation | Signature laundering | high | mitigate | Raw and composed `:already_shared` clauses and fixtures | closed |
| T-143-30 | Repudiation | Count-key shape mismatch | high | mitigate | Required keys read with `Map.fetch!/2` | closed |
| T-143-31 | Tampering | Machine-rewritten threshold | medium | mitigate | Hardcoded, provenance-bearing constants and drift tests | closed |
| T-143-32 | Information Disclosure | CI count/tally output | low | accept | Output restricted to aggregate counts and safe names; accepted as R-143-04 | closed |
| T-143-33 | Repudiation | Floor measured from invalid run | high | mitigate | Green-run IDs, job IDs, and dates pinned in source | closed |
| T-143-34 | Tampering | Floor enforcement removal | high | mitigate | Workflow env occurrences and enforcement are drift-tested | closed |
| T-143-35 | Tampering | Lowering pinned floor | high | mitigate | Deliberate-repin instructions and review-visible constants | closed |
| T-143-36 | Denial of Service | Floor after legitimate test removal | medium | accept | Minimum comparison supports deliberate retuning; accepted as R-143-05 | closed |
| T-143-37 | Spoofing | Gating/advisory name collision | high | mitigate | Bidirectional runtime-name collision assertions | closed |
| T-143-38 | Repudiation | Declared-name vacuity | high | mitigate | Runtime matrix expansion and exact cardinality assertions | closed |
| T-143-39 | Tampering | Split classification change | high | mitigate | Four classification artifacts landed atomically in `f1371927` | closed |
| T-143-40 | Denial of Service | Workflow concurrency change | high | mitigate | Load-bearing concurrency shape retained and documented | closed |
| T-143-41 | Elevation of Privilege | Branch-protection modification | high | mitigate | Required-check contract retained; protection script unchanged | closed |
| T-143-42 | Repudiation | Inconclusive probe outcome | high | mitigate | Timeout and never-appeared outcomes fail closed | closed |
| T-143-43 | Elevation of Privilege | Gate wired on partial evidence | high | mitigate | Blocking checkpoint preceded gate implementation | closed |
| T-143-44 | Denial of Service | Orphaned probe refs | medium | mitigate | Cleanup paths and recorded remote-ref deletion | closed |
| T-143-45 | Spoofing | Registry/runtime name mismatch | high | mitigate | Exact runtime-name match and live evidence | closed |
| T-143-46 | Elevation of Privilege | Automated-path gate bypass | high | mitigate | Override is dispatch-only and inert for releases | closed |
| T-143-47 | Tampering | Skip-reason script injection | high | mitigate | Free text passed through environment, not interpolated into shell | closed |
| T-143-48 | Repudiation | Missing lane read as green | high | mitigate | Missing, cancelled, and skipped conclusions block | closed |
| T-143-49 | Denial of Service | Concurrent gate cancellation | high | mitigate | SHA queries, randomized settle, and shared deadline | closed |
| T-143-50 | Denial of Service | Release-pipeline deadlock | high | mitigate | Dual self-heal, bounded deadline, and recovery instructions | closed |
| T-143-51 | Access Control | Publish-gate permissions | medium | accept | Existing action permissions unchanged and Hex isolated; accepted as R-143-06 | closed |
| T-143-52 | Tampering | Rehearsal publishing to Hex | high | mitigate | Dry-run rehearsals used released versions and did not publish | closed |
| T-143-53 | Tampering | Rehearsal against old ref | high | mitigate | Tagged SHA relationship recorded in gating evidence | closed |
| T-143-54 | Denial of Service | Orphaned rehearsal refs | medium | mitigate | Local/remote deletion and remaining-ref search recorded | closed |
| T-143-55 | Repudiation | Evidence-free verdict | high | mitigate | Seven-run evidence table and contract coverage | closed |
| T-143-56 | Elevation of Privilege | Override becoming routine | medium | mitigate | Release inertness enforced; exception discipline documented | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-143-01 | T-143-04 | `mix.exs` explicitly packages `lib` and excludes test support. Residual risk is a future allowlist change; Phase 142's tarball protocol governs such changes. | Project owner | 2026-07-31 |
| R-143-02 | T-143-08 | The self-test needs `contents: write`, `pull-requests: write`, and `checks: read` to create and inspect throwaway probes. Permissions were not widened in this phase. | Project owner | 2026-07-31 |
| R-143-03 | T-143-14 | Duplicate plan-level exposure record retained for traceability. Test support remains excluded by the explicit package allowlist. | Project owner | 2026-07-31 |
| R-143-04 | T-143-32 | CI output contains aggregate counts, schema names, and signature atoms only; no test data or bound query values are emitted. | Project owner | 2026-07-31 |
| R-143-05 | T-143-36 | A legitimate test removal can require deliberate floor retuning. The `>=` comparison and advisory growth nudge limit accidental disruption. | Project owner | 2026-07-31 |
| R-143-06 | T-143-51 | The publish gate's existing contents-read/actions-write permissions support self-healing dispatch. Publishing credentials remain isolated behind the `hex-publish` environment. | Project owner | 2026-07-31 |

Accepted risks do not resurface in future audit runs unless their assumptions or controls change.

---

## Security Audit 2026-07-31

| Metric | Count |
|--------|-------|
| Threats found | 56 |
| Closed by verified mitigation | 50 |
| Closed by accepted-risk record | 6 |
| Open | 0 |

The ASVS Level 1 audit verified all 50 mitigation dispositions against implementation or evidence artifacts. The six accepted dispositions were approved by the project owner and documented above. No open threat meets or exceeds the configured `high` blocking threshold.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 56 | 56 | 0 | `gsd-security-auditor` + project owner |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-31
