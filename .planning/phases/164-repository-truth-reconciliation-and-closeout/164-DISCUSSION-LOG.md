# Phase 164: Repository Truth Reconciliation and Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 164-repository-truth-reconciliation-and-closeout
**Areas discussed:** Truth surface, Artifact disposition, Closeout proof

---

## Truth Surface

### Operational authority

| Option | Description | Selected |
|--------|-------------|----------|
| Layered authority | Executable controls and immutable/live facts win; `MAINTAINING.md` explains them; planning records remain history. | ✓ |
| Single runbook authority | Make `MAINTAINING.md` the definitive operational source. | |
| Executable files first | Treat workflows and scripts as authority and keep prose as a summary. | |
| You decide | Defer the hierarchy to research and planning. | |

**User's choice:** Layered authority.
**Notes:** Recommended because upstream Release Please defaults differ from Mailglass's protected exact-digest authority and public Hex facts are stronger than duplicated prose claims.

### Obsolete instructions

| Option | Description | Selected |
|--------|-------------|----------|
| Label and bound them | Keep useful historical procedures in place with exact version or milestone applicability. | ✓ |
| Move them to planning history | Relocate obsolete procedures and keep active docs current-only. | |
| Add an applicability matrix | Map every retained procedure to versions and recovery states. | |
| You decide | Defer treatment to research and planning. | |

**User's choice:** Label and bound them.
**Notes:** The user then instructed the workflow to auto-follow all remaining recommendations.

### Version claims

| Option | Description | Selected |
|--------|-------------|----------|
| Derived and contract-checked current truth | Check current claims against manifests and public Hex; preserve old constraints only in historical guides. | ✓ |
| Manual exact-version sweep | Update duplicated exact strings during this phase. | |
| Remove version examples | Avoid current version claims in prose. | |
| You decide | Defer treatment to research and planning. | |

**User's choice:** Recommended option selected under the user's auto-follow instruction.
**Notes:** Current repository versions are core/admin `2.5.0` and inbound `2.2.0`.

### Recovery guidance

| Option | Description | Selected |
|--------|-------------|----------|
| Current decision path plus historical links | Keep one supported state-based recovery path and link evidence for provenance. | ✓ |
| Independent recovery sections | Keep separate procedures for each release era. | |
| Evidence-only recovery guidance | Remove operational steps and point only to evidence. | |
| You decide | Defer treatment to research and planning. | |

**User's choice:** Recommended option selected under the user's auto-follow instruction.
**Notes:** Current guidance must state exact identities, supported commands, and protected authorization conditions.

---

## Artifact Disposition

### Classification record

| Option | Description | Selected |
|--------|-------------|----------|
| Tracked evidence-backed disposition ledger | Record producer, state, authority, reproducibility, currentness, evidence, and outcome for every item. | ✓ |
| Commit-diff review only | Limit classification to the eventual implementation diff. | |
| Separate artifact and ignore audits | Maintain independent records for files and patterns. | |
| You decide | Defer the record shape to research and planning. | |

### Generated-output boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Authority-and-consumer classification | Track contractual/forensic proof; leave reproducible diagnostics and machine-local noise untracked. | ✓ |
| Track all generated JSON | Commit every structured generated output. | |
| Ignore all generated output | Treat generated files as disposable. | |
| You decide | Defer treatment to research and planning. | |

### Ignore-rule threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Producer-backed narrow rules | Commit only shared project patterns with the narrowest safe scope. | ✓ |
| Repository-wide tool patterns | Add broad patterns for local and generated tools. | |
| No ignore changes | Preserve all current rules unchanged. | |
| You decide | Defer treatment to research and planning. | |

### Root scheduled sweep

| Option | Description | Selected |
|--------|-------------|----------|
| Record then remove stale output | Preserve its digest and stale reason in the ledger, then remove it from the root. | ✓ |
| Move into tracked phase evidence | Promote it into Phase 164 proof. | |
| Ignore future sweep files | Add a repository ignore pattern. | |
| You decide | Defer treatment to research and planning. | |

**User's choice:** Recommended options selected under the user's auto-follow instruction.
**Notes:** Git's documented ignore-source boundaries and GitHub artifact retention informed the policy. The root file's SHA-256 is `331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e`; its observations predate the completed current-main sweep.

---

## Closeout Proof

### Evidence form

| Option | Description | Selected |
|--------|-------------|----------|
| Tracked ledger plus rerunnable exact-main report | Preserve durable facts in Git and prove volatile exact-main state on demand. | ✓ |
| Committed final snapshot only | Store a point-in-time closeout capture in the repository. | |
| Workflow artifact only | Keep final proof only in CI storage. | |
| You decide | Defer the evidence form to research and planning. | |

### Canonical cleanliness

| Option | Description | Selected |
|--------|-------------|----------|
| Identity-bound porcelain-clean contract | Require canonical path, `main`, `HEAD == origin/main`, empty tracked/untracked porcelain, and safe ignore semantics. | ✓ |
| Git status clean only | Accept an ordinary clean status without identity checks. | |
| No files under ignored paths | Require ignored caches and local files to be absent. | |
| You decide | Defer the cleanliness boundary to research and planning. | |

### Protected and scheduled verdicts

| Option | Description | Selected |
|--------|-------------|----------|
| Exact-SHA checks plus explained evidence-valid controls | Require exact-main checks and provenance-valid pass or expected policy-blocked scheduled outcomes. | ✓ |
| Required checks only | Ignore scheduled and recovery evidence at closeout. | |
| Latest run by branch name | Accept the latest branch-associated run without exact identity binding. | |
| You decide | Defer the remote-proof boundary to research and planning. | |

### Inventory completeness

| Option | Description | Selected |
|--------|-------------|----------|
| Exactly-one evidence-backed disposition | Fail closeout on any unclassified, duplicate, stale-without-outcome, or unsupported row. | ✓ |
| Best-effort inventory | Permit incomplete classifications with notes. | |
| Only changed tracked files | Exclude generated and ignore-rule items. | |
| You decide | Defer completeness to research and planning. | |

**User's choice:** Recommended options selected under the user's auto-follow instruction.
**Notes:** Stable Git porcelain and exact workflow `head_sha` filtering informed the identity-bound, rerunnable proof contract.

---

## the agent's Discretion

- Exact ledger filename and machine-readable schema.
- Exact current-document section layout and link placement.
- Exact reuse or extension seam across the existing workspace, hygiene, scheduled-control, and CI-monitoring assets.
- Exact evidence command ordering, timestamps, and workflow artifact filenames.

## Deferred Ideas

None.
