# Phase 162: Protected Release and Scheduled-Control Recovery - Research

**Researched:** 2026-08-22
**Domain:** GitHub Actions protected-release recovery, immutable publication evidence, and truthful repository controls
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Treat the current v2.5.0 candidate state as a blocked reconciliation, not as release authorization. Produce an append-only narrative that joins PR #222 head/base/check facts, candidate and published tags, exact Hex versions/checksums, `.planning/release-target.json`, retained WT-03 publish-summary deltas, and the relevant release/recovery refs.
- **D-02:** The tracked target's current `authorized` / `publication: not_started` state does not authorize merge, tag creation, or publication by itself. Refresh all time-sensitive GitHub, Git, Actions, and Hex facts immediately before any disposition and record `cannot-check` rather than infer when a source is unavailable.
- **D-03:** Give PR #222 and every retained stale release/recovery branch or check exactly one explicit outcome: merge only through the existing protected exact-candidate path, retire with a recorded evidence-backed reason, or retain with a named recovery condition. Nothing may remain auto-merge-armed or unexplained in limbo, and no retained Phase 161 evidence may be deleted merely because the release is blocked.
- **D-04:** Preserve the existing authority boundary: push, hourly schedule, and digest-free manual release-please runs remain proposal-only. Only the protected exact candidate-digest dispatch may validate and merge the reviewed proposal and cross into tag/release creation; Phase 162 must not add merge, tag, publish, or protected-dispatch authority to ordinary control or scheduled entry points.
- **D-05:** Record control-run and applicable observed scheduled-run evidence separately. A manual dispatch may prove the control path but never substitutes for scheduled execution; pending elapsed-time evidence remains pending, and unavailable evidence reports `cannot-check`.
- **D-06:** Release-please and repository-hygiene must expose bounded, inspectable outcomes through agreeing logs and machine-readable evidence. Preserve the existing `pass`, policy `blocked`, and `cannot-check` semantics, make the narrowest changes needed for truthful results, and do not redesign workflow topology or weaken the already-green protected `CI Green` path.
- **D-07:** Post-publish recovery is valid only for an exact immutable target whose tracked release state and public package facts prove publication. The existing recovery path must resolve all expected package tags to the same target SHA and verify the authorized content digest.
- **D-08 resolution:** While the target remains authorized but unpublished, record post-publish as top-level `blocked`. Do not substitute `main`, reinterpret a release-event no-op as consumer proof, or force a new release solely to satisfy this phase.

### the agent's Discretion
- Exact filename and schema for the append-only Phase 162 reconciliation artifact, provided every claim cites its source, capture time, immutable identity, and outcome.
- Exact ordering of read-only GitHub, Git, Actions, Hex, and local-ledger queries.
- Exact narrow implementation seam for truthful scheduled/control reporting, provided the authority and evidence contracts above remain unchanged.

### Deferred Ideas (OUT OF SCOPE)
- PostgreSQL property-test and admin gallery-matrix timeout repairs — Phase 163.
- Final maintainer/version/release documentation reconciliation, generated/tracked artifact classification, ignore-rule cleanup, and quiet repository closeout — Phase 164.
- CI efficiency/topology overhaul (SEED-006) — outside v2.7.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTO-01 | Reconcile PR #222, commits/checks, tags, Hex versions, and ledger. | Append-only evidence record with per-source capture timestamps, immutable IDs, and one disposition. |
| AUTO-02 | Dispose every stale release branch/check with no auto-merge limbo. | Branch/PR/check disposition rows and explicit recovery-condition vocabulary. |
| AUTO-03 | Truthful proposal-only release-please control and schedule. | Preserve existing trigger/authority split; repair failed candidate-capture reporting only. |
| AUTO-04 | Inspectable pass/blocked/cannot-check hygiene outcomes with agreeing JSON/logs. | Make aggregate status three-valued and have workflow summary render the JSON report. |
| AUTO-05 | Exact immutable post-publish recovery or evidence-backed blocked state. | Keep all-tags-to-one-SHA/content-digest guard; make unpublished scheduled resolution non-successful but explicit. |
</phase_requirements>

## Summary

The phase is a reconciliation and truthful-reporting repair, not a release. The current ledger authorizes candidate `2.5.0/2.5.0/2.2.0` at proposal SHA `d0369ba...` with `publication: not_started`; live public facts instead show all three corresponding tags/releases at `0f0b068...` and those versions as latest on Hex. PR #222 is an independently open, clean, fully checked release proposal at `7253bc...` over `6c4b28...`, with ordinary auto-merge absent. These identities must be recorded as a blocked mismatch, never merged or reinterpreted as one release. [VERIFIED: GitHub API and Hex API]

The existing controls already encode the required safety boundaries. `release-please.yml` makes push, hourly schedule, and digest-free dispatch proposal-only, while the candidate-digest dispatch performs exact policy, PR, required-check, content-digest, and protected-main validation. `post-publish-smoke.yml` already resolves schedule only from a completed target and verifies all three tags against one SHA and the content digest. The failure is that ordinary expected blocked/unpublished states currently exit as generic failing workflow steps, and hygiene collapses `:unknown` into aggregate `:blocked`. [VERIFIED: repository workflows, scripts, and live Actions logs]

**Primary recommendation:** Add one tracked append-only Phase 162 reconciliation record, then make the smallest workflow/task changes that emit explicit `pass`, `blocked`, or `cannot-check` JSON and matching summaries while retaining nonzero policy-block exit behavior and all immutable/protected authority gates.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release-state reconciliation | Repository/planning evidence | GitHub API + Hex API | Durable narrative joins time-sensitive remote facts with retained local evidence. |
| Proposal-only release control | GitHub Actions | ReleasePolicy | Workflow trigger guards invoke policy; only protected digest dispatch may cross authority boundary. |
| Hygiene result classification | Mix task | GitHub Actions artifact/summary | Task owns structured outcome; workflow preserves and displays exactly that result. |
| Immutable post-publish proof | GitHub Actions | Git/Hex + ReleasePolicy | Workflow must bind public packages/tags to one authorized immutable target. |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Existing `Mailglass.ReleasePolicy` | repository-local | Validates lifecycle, expected tags, candidate/content identities. | Single policy owner already consumed by release and smoke workflows. [VERIFIED: `scripts/release_policy.exs`] |
| GitHub Actions + pinned actions | existing pins | Scheduled/control execution, artifact retention, summaries. | Existing protected workflow topology is the contract. [VERIFIED: `.github/workflows/*.yml`] |
| GitHub CLI/API | `gh 2.95.0` locally | Read-only PR, ref, release, run/job, artifact evidence capture. | Provides authenticated live facts without adding a dependency. [VERIFIED: local environment] |
| `jq`, Git, Mix | `jq 1.7.1`, Git `2.41.0`, OTP 28 | Exact JSON/Git/policy processing. | Already installed and used by current controls. [VERIFIED: local environment] |

### Supporting

| Library / Tool | Purpose | When to Use |
|----------------|---------|-------------|
| Hex public API | Published version/checksum observation. | Reconciliation only; treat unavailability as `cannot-check`. [VERIFIED: `.planning/release-target.json`] |
| ExUnit existing contract tests | Protect workflow text/policy behavior. | Every narrow reporting/guard change. [VERIFIED: `test/scripts/*`, `test/mix/tasks/*`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Append-only Markdown/JSON reconciliation record | New release database/service | Violates maintenance-only scope and duplicates the existing ledger. [VERIFIED: CONTEXT.md] |
| Extend `ReleasePolicy` and hygiene task | New release-state subsystem | Splits authority and creates conflicting ledgers. [VERIFIED: existing control contracts] |

**Installation:** No external package installation is justified or allowed for this phase. [VERIFIED: REQUIREMENTS.md out-of-scope]

## Architecture Patterns

### System Architecture Diagram

```text
GitHub PR/ref/check API ─┐
Git tags/releases API ───┼─> capture commands ─> append-only reconciliation record
Hex package/release API ─┤                              │
Phase 161 preserved refs ┘                              └─> disposition: protected merge | retire | retain(condition)

push / schedule / digest-free dispatch ─> release-please proposal-only ─> proposal evidence
candidate-digest protected dispatch ─────> exact policy + CI validation ─> merge/tag/release authority

control or scheduled hygiene ─> Mix task JSON ─> workflow summary + uploaded identical JSON
schedule post-publish ─> completed immutable ledger target ─> all tags same SHA + digest + Hex proof
```

### Recommended Project Structure

```text
.planning/phases/162-protected-release-and-scheduled-control-recovery/
└── 162-RELEASE-RECONCILIATION.md   # append-only evidence and dispositions

dev/mix/tasks/mailglass.repo.hygiene.ex # three-state report classification
.github/workflows/                    # bounded control/schedule rendering only
test/mix/tasks/ and test/scripts/      # executable reporting/authority contracts
```

### Pattern 1: Append-only evidence ledger
**What:** One human-readable tracked record containing a capture header and one row per claim: source/command or URL, capture time, immutable identity, observation, and disposition/recovery condition.

**When to use:** Before changing a live branch, PR, tag, workflow, or release ledger; append a new capture rather than editing earlier facts. [VERIFIED: CONTEXT.md D-01/D-02 and Phase 161 handoff]

**Example:**
```markdown
| Captured UTC | Source | Immutable identity | Observation | Outcome |
|---|---|---|---|---|
| 2026-08-22T…Z | GitHub PR API | PR 222; head SHA; base SHA | open/clean/checks pass/auto-merge null | retain only pending named exact-digest recovery |
```

### Pattern 2: Three-state operational result
**What:** Preserve `pass`, `blocked`, and `cannot-check` as first-class result statuses in the aggregate JSON, text output, job summary, and exit policy.

**When to use:** Any remote observation can distinguish confirmed policy noncompliance from lack of evidence/access. `blocked` means the check ran and policy is unsatisfied; `cannot-check` means evidence could not be acquired. [VERIFIED: CONTEXT.md D-02/D-06; `mailglass.repo.hygiene`]

**Implementation detail:** Rename internal `:unknown` to external `:cannot_check` (encoded `cannot-check`) or map it at the report boundary; aggregate precedence should be `cannot-check` if any check cannot be established, otherwise `blocked` if any established check blocks, otherwise `pass`. Preserve nonzero exit for both non-pass statuses. [HIGH: derived from locked three-state contract and existing task tests]

### Pattern 3: Immutable-target fail-closed post-publish resolution
**What:** Scheduled smoke accepts only `completed-versions`; protected dispatch compares all identity fields between the protected control checkout and target checkout, then verifies expected tags resolve to the supplied SHA and its authorized digest.

**When to use:** Every post-publish retry/recovery. Do not derive a target from `main`, latest package release, or release event. [VERIFIED: `post-publish-smoke.yml`; `scripts/check_post_publish_target.sh`]

### Anti-Patterns to Avoid

- **Using a control dispatch as scheduled proof:** Store separate run IDs/event names; do not label dispatch evidence as scheduled evidence. [VERIFIED: CONTEXT.md D-05]
- **Generic workflow failure for an expected unpublished target:** It obscures policy block versus failed observation. Produce a bounded report/summary first, then retain non-success exit for policy block. [VERIFIED: live run `32572135200`]
- **Changing permissions/topology to fix reporting:** The release authority boundary is already correct; only reporting/classification is in scope. [VERIFIED: CONTEXT.md D-04/D-06]
- **Rewriting WT-03 or release history:** Add correction/disposition records only. [VERIFIED: CONTEXT.md D-01/D-03]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release lifecycle validation | Another JSON schema/state machine | `scripts/release_policy.exs` and wrappers | It already validates lifecycle, tags, versions, proposal identity, and digest. [VERIFIED: repository scripts] |
| Tag/SHA/content binding | Ad hoc shell comparison in a new workflow | `check_post_publish_target.sh` | It fetches each expected tag and validates all resolve to one exact SHA and digest. [VERIFIED: script] |
| Published release provenance | New package polling or “latest” lookup | `verify_published_release.sh` + policy Hex helper | Existing verifier binds run/artifact/Hex facts to a published target. [VERIFIED: script] |
| Workflow-control testing | New framework | Existing ExUnit workflow contract tests | Tests already parse/execute relevant snippets and protect exact strings. [VERIFIED: test files] |

**Key insight:** Truthful outcome reporting belongs around existing authoritative controls; duplicating their policy logic would create a second, contradictory release truth.

## Common Pitfalls

### Pitfall 1: Conflating candidate identities
**What goes wrong:** PR #222’s current `7253bc...` head is treated as the ledger candidate `d0369b...` or as the published `0f0b...` tag train.
**Why it happens:** They share a release topic/version family but are distinct immutable SHA identities. [VERIFIED: GitHub API, release-target.json]
**How to avoid:** Put SHA, version set, source, and capture time in every reconciliation row; no row may rely on branch name alone.
**Warning signs:** Any claim says “v2.5.0” without its package set and SHA.

### Pitfall 2: Collapsing unknown evidence into a policy block
**What goes wrong:** The hygiene aggregate is currently `blocked` for any non-pass, including internal `:unknown`.
**Why it happens:** `status/1` only checks whether all checks pass. [VERIFIED: `dev/mix/tasks/mailglass.repo.hygiene.ex`]
**How to avoid:** Implement explicit aggregate precedence and assert both text and JSON output.
**Warning signs:** A missing GH token, API failure, or unavailable branch-protection verifier produces only `blocked`.

### Pitfall 3: Treating scheduled unpublished smoke as a generic crash
**What goes wrong:** The scheduled smoke resolver fails on `completed-versions` when the ledger remains authorized/not-started, skipping all downstream jobs without a bounded outcome record.
**Why it happens:** The current workflow uses a hard shell assertion before outputs/summary. [VERIFIED: live run `32572135200`; `post-publish-smoke.yml`]
**How to avoid:** Keep the exact completed-target requirement, but emit an explicit `blocked` result with source identities before ending non-success according to a tested contract.
**Warning signs:** Resolver’s only visible conclusion is exit code 1 and downstream skipped.

### Pitfall 4: Trying to solve release-please failure by granting ordinary triggers authority
**What goes wrong:** A schedule/control run is allowed to merge/tag/publish to escape candidate-capture mismatch.
**Why it happens:** The failed scheduled run makes the safe proposal path look broken. [VERIFIED: live run `32587776542`]
**How to avoid:** Fix capture/reporting or record a blocked disposition; preserve protected digest dispatch as the sole crossing.
**Warning signs:** New permissions or calls to merge/tag APIs appear outside `protected-dispatch`.

## Code Examples

### Aggregate three-state hygiene status
```elixir
# Source: project-local contract; add focused tests before refactoring.
defp status(checks) do
  cond do
    Enum.any?(checks, &(&1.status == :cannot_check)) -> :cannot_check
    Enum.any?(checks, &(&1.status == :blocked)) -> :blocked
    true -> :pass
  end
end
```

### Bounded scheduled target resolution
```bash
# Source: existing post-publish policy contract.
if completed=$(policy completed-versions "$target" 2>"$reason"); then
  emit_result pass "$completed"
else
  emit_result blocked "authorized target is unpublished" "$(cat "$reason")"
  exit 1
fi
```
The implementation must make its machine-readable result the source used by the summary, not create two independently computed verdicts. [HIGH: derived from AUTO-04]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Ordinary release PR auto-merge after green checks | Ordinary auto-merge step is explicitly disarmed; exact candidate-digest dispatch is sole merge/tag boundary. | Planning must retain the current protected path rather than restore auto-merge. [VERIFIED: `release-please.yml`] |
| Release-event post-publish execution as proof | Release events are intentional no-ops; schedule uses completed target and dispatch requires exact target inputs. | A release event cannot satisfy AUTO-05. [VERIFIED: `post-publish-smoke.yml`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The minimal repair will be able to emit a structured scheduled post-publish `blocked` result without introducing a new workflow or external service. | Architecture Patterns | Planner may need to choose the exact existing workflow artifact/summary seam after implementation inspection. |

## Open Questions (RESOLVED)

1. **PR #222 disposition rule:** Execution performs a fresh exact capture. If the PR head SHA, base SHA, content digest, and required checks satisfy the named protected recovery condition, retain PR #222 for the existing exact candidate-digest protected dispatch. If any immutable identity or policy prerequisite mismatches, retire it with the exact mismatch reason. Evidence capture never merges it, and no push, schedule, digest-free dispatch, or other ordinary trigger gains release authority.
2. **Scheduled authorized/not-started vocabulary:** Use top-level `blocked` consistently in result JSON, logs, summary, reconciliation, and plans. This is a non-success policy outcome because no completed immutable target exists; no alternate top-level term is permitted for this state.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| GitHub CLI/API | live PR/run/tag evidence | ✓ | 2.95.0 | record `cannot-check` when unavailable/access denied |
| Mix / OTP | policy and task tests | ✓ | OTP 28 | existing CI pinned runtime |
| Git | ref/tag identity verification | ✓ | 2.41.0 | none |
| jq | report/ledger inspection | ✓ | 1.7.1 | none in current shell contracts |
| Hex API | public package/release facts | ✓ | public HTTPS | record `cannot-check`; do not infer |

**Missing dependencies with no fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (project Mix test suite) |
| Config file | `mix.exs` |
| Quick run command | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs test/scripts/release_trigger_recovery_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTO-01 | Ledger format has immutable identity/capture/outcome rows; release-policy validates existing target facts. | contract + manual live capture | `mix test test/scripts/release_policy_test.exs test/scripts/release_policy_contract_test.exs` | ✅; reconciliation-specific test ❌ Wave 0 |
| AUTO-02 | Proposal-only triggers cannot arm ordinary auto-merge or cross release authority. | workflow contract | `mix test test/scripts/release_trigger_recovery_test.exs` | ✅ |
| AUTO-03 | All proposal triggers remain and protected dispatch remains uniquely gated. | workflow contract | `mix test test/scripts/release_trigger_recovery_test.exs test/scripts/release_policy_contract_test.exs` | ✅ |
| AUTO-04 | Aggregate, JSON, text, and workflow artifact distinguish pass/blocked/cannot-check. | unit + workflow contract | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` | ✅; explicit three-state cases ❌ Wave 0 |
| AUTO-05 | Schedule requires completed target; dispatch is exact immutable target; guard requires three tags + digest. | workflow/script contract | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/verify_published_release_test.exs` | ✅; bounded scheduled-report case ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** run the focused ExUnit command for changed control/task.
- **Per wave merge:** `mix test`.
- **Phase gate:** focused tests green plus fresh read-only GitHub/Hex evidence; observe an actual scheduled run where applicable.

### Wave 0 Gaps

- [ ] Add reconciliation-artifact schema/required-field contract test or deterministic checker for source, capture time, immutable identity, and outcome.
- [ ] Add hygiene tests asserting aggregate `cannot-check`, JSON string, text line, and nonzero exit separately from policy `blocked`.
- [ ] Add post-publish workflow contract test for scheduled authorized/not-started explicit report and no `main` substitution.
- [ ] Add release-please workflow contract test proving a capture mismatch is reported/recorded without authority expansion.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | GitHub token permissions remain least-privilege and existing secrets only. [VERIFIED: workflows] |
| V3 Session Management | no | No user session surface. |
| V4 Access Control | yes | Protected candidate digest, protected-main checkout, exact PR/check validation, no ordinary trigger authority. [VERIFIED: `release-please.yml`] |
| V5 Input Validation | yes | SHA/SemVer/digest validation in policy and shell guards. [VERIFIED: scripts] |
| V6 Cryptography | yes | SHA-256 content digest is verified; do not implement a new digest scheme. [VERIFIED: policy and post-publish guard] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller selects self-authorizing ref | Elevation of privilege | Read control policy from protected `main`/workflow SHA and compare immutable target identities. [VERIFIED: workflows] |
| Partial/mixed release tags | Tampering | Require all expected tags and resolve each to one target SHA. [VERIFIED: `check_post_publish_target.sh`] |
| Remote API unavailable treated as absence | Tampering / repudiation | Only confirmed absence is absence; otherwise return `cannot-check`. [VERIFIED: release preflight and CONTEXT.md] |
| “Latest” package release substituted for target | Tampering | Resolve policy-owned exact versions and target SHA; never use latest. [VERIFIED: post-publish workflow tests] |

## Sources

### Primary (HIGH confidence)
- Repository controls: `.github/workflows/release-please.yml`, `.github/workflows/repo-hygiene.yml`, `.github/workflows/post-publish-smoke.yml`, `scripts/release_policy.exs`, `scripts/check_post_publish_target.sh`, and `scripts/verify_published_release.sh`.
- Live GitHub API/Actions capture (2026-08-22): PR `#222`, branch `release-please--branches--main`, tags/releases, and runs `32587776542`, `32573781732`, `32572135200`.
- Live Hex package endpoints listed in `.planning/release-target.json` (2026-08-22).
- Phase inputs: `162-CONTEXT.md`, `161-WORKSPACE-INVENTORY.md` Phase 162 handoff, `REQUIREMENTS.md`, `STATE.md`.

### Secondary (MEDIUM confidence)
- [GitHub Actions events documentation](https://docs.github.com/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows) — schedule and workflow-dispatch event semantics. [CITED: docs.github.com]
- [GitHub REST Actions documentation](https://docs.github.com/rest/actions/workflow-runs) — workflow-run/job/artifact query boundaries. [CITED: docs.github.com]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommended tools are repository-local or observed installed/live.
- Architecture: HIGH — locked phase decisions and existing protected controls define the boundary.
- Pitfalls: HIGH — confirmed in live failing runs and implementation code.

**Research date:** 2026-08-22
**Valid until:** execution-time remote capture required; code findings stable for 30 days.
