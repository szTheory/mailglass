---
phase: 93
slug: hexdocs-wiring-and-release-hardening
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-13
---

# Phase 93 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Verdict: **SECURED** — 13/13 threats closed (8 `mitigate` verified in code/config, 5 `accept` rationale verified). Register authored at plan time; this audit verified each mitigation exists in the implementation rather than scanning for new threats. Implementation files read-only; no patches applied.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| ex_doc build → doc output | ex_doc reads logo/favicon source paths and copies them into `doc/assets/`. Only untrusted-input analog is a relative path resolving outside the package dir (`../brandbook/`). | SVG asset paths (no user data) |
| package source → Hex tarball | The `:files` allowlist controls what ships to Hex; logo/favicon are auto-copied at doc-build time and are NOT in the tarball. | Published package contents |
| PR author → release pipeline | A PR title + changed-file set crosses into release-please's bump decision on squash-merge. The guard workflow sits at this boundary. | PR title (conventional-commit type), changed-file paths |
| GITHUB_TOKEN → guard workflow | The guard reads PR title + files; needs no write, no secrets. `pull_request` (not `pull_request_target`) keeps fork PRs in the low-privilege context. | Read-only PR metadata |
| in-repo pins → Hex dependency resolution | admin/inbound core-dep pins resolve at publish/CI time against Hex; a pin to an unpublished core reds main. | Version constraint literals |
| live Hex → in-repo version truth | Hex is authoritative; the D-13 guard establishes it before any version edit so reconciliation never runs against an unsettled train. | Published version numbers |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-93-01 | Tampering | docs/0 relative path resolves outside package dir | accept | `../brandbook/` is an intentional committed monorepo path (admin `mix.exs:219-220`, inbound `mix.exs:152-153`); no external input controls path; docs build only from monorepo checkout | closed |
| T-93-02 | Information Disclosure | `:files` allowlist accidentally widened to ship brandbook into Hex tarball | mitigate | No `:files` line changed by any phase-93 commit (7f8f3044/73b5d0ce/b92e79e3/57192111 show no `files:`/`~w(` diff); no `brandbook` token in any of the three allowlists (`mix.exs:350-351`, admin `:210`, inbound `:143`); ex_doc auto-copies at build time | closed |
| T-93-03 | Denial of Service | new `mix docs` warning silently degrades published docs | mitigate | SVG explicit sizing at source (logo `width="164" height="156"`, favicon `width="16" height="16"`) removes the ex_doc 0.40.x missing-attr warning condition; 93-01-SUMMARY records clean `mix docs` x3, no new warnings | closed |
| T-93-04 | Tampering | bump-triggering PR slips past guard via non-conventional title | mitigate | `guard-release-trigger.yml:31-37` exits 0 on non-conventional titles (defers to `pr-title.yml`); the two checks compose; fixture case 5 green | closed |
| T-93-05 | Tampering | path-prefix evasion (e.g. `brandbook-evil/` matching `brandbook/`) | mitigate | Trailing-slash `GUARDED` array (`:26`), dir-boundary subset test (`:68-74`), FAIL only when ALL files guarded (`:77`); fixture cases 1 + 6 green | closed |
| T-93-06 | Elevation of Privilege | workflow token over-scoped, secrets exposed to fork PRs | mitigate | Plain `pull_request:` (zero `pull_request_target`); permissions exactly `pull-requests: read` + `contents: read` (`:8-10`); no marketplace actions (only preinstalled `gh`) | closed |
| T-93-07 | Repudiation | exclude-paths silently misbehaves, no release cut when intended | accept | exclude-paths is secondary/silent; loud required guard workflow is primary; belt-and-suspenders, both present | closed |
| T-93-08 | Denial of Service | core-dep pin set to unpublished core version, reds main | mitigate | Pin `{:mailglass, "== 1.6.2"}` (admin `:142`, inbound `:127`); no stale `== 1.6.1`; D-13 gate confirmed core 1.6.2 published before pin set | closed |
| T-93-09 | Tampering | reconciliation against unsettled/mid-flight train, wrong version | mitigate | D-13 Task-1 gate confirmed live Hex 1.6.2/1.6.2/1.3.1 (inbound 1.3.1 deps `== 1.6.2`) before edits; manifest + @version match | closed |
| T-93-10 | Repudiation | hand-edit to manifest/@version that release-please later fights | accept | release-please rewrites manifest/@version only on a cut release PR; manifest already at released versions, nothing pending to cut; edit is stable | closed |
| T-93-11 | Tampering | accidental deletion of real published 1.6.x tags, orphaning HexDocs source links | mitigate | `git tag --list` shows both `mailglass-v1.6.1` and `mailglass-v1.6.2` (+ admin pair) present — fetch+KEEP, no deletion | closed |
| T-93-SC | Tampering (supply chain) | npm/pip/cargo installs (plans 01/02/03) | accept | No package-manager installs in any plan; only SVG attribute edits, mix.exs keyword/literal edits, a JSON config edit, a YAML workflow using preinstalled `gh`, a bash fixture test, and `git fetch --tags`. No new dependency (`tech_stack.added: []` x3) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-93-01 | T-93-01 | docs/0 relative path resolves outside package dir — intentional committed monorepo path, no external input control | gsd-security-auditor (plan-time disposition) | 2026-06-13 |
| AR-93-07 | T-93-07 | exclude-paths silent misbehavior — secondary/belt-and-suspenders; loud guard is primary | gsd-security-auditor (plan-time disposition) | 2026-06-13 |
| AR-93-10 | T-93-10 | manifest hand-edit vs release-please — nothing pending to cut; edit is stable | gsd-security-auditor (plan-time disposition) | 2026-06-13 |
| AR-93-SC | T-93-SC | package-manager supply chain — no installs, no new dependency in any plan | gsd-security-auditor (plan-time disposition) | 2026-06-13 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-13 | 13 | 13 | 0 | gsd-security-auditor (verify-mitigations mode) |

---

## Open Caveat (NOT a security gap — operational follow-up)

Plan 02 Task 3 — registering `guard-release-trigger` as a **required** branch-protection check — is a documented manual follow-up (93-02-SUMMARY), not completed. The guard workflow runs and reports status on every PR but does NOT block merges until added to main branch protection:

```bash
gh api -X PATCH repos/szTheory/mailglass/branches/main/protection/required_status_checks \
  --field 'contexts[]=guard-release-trigger'   # after the check has run on ≥1 PR
```

This does not change any threat disposition above — T-93-04/05/06 verify the guard's logic and least-privilege posture (present and correct), and the exclude-paths defense-in-depth (T-93-07) is already active. It is the activation step only, surfaced so it isn't lost.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-13
