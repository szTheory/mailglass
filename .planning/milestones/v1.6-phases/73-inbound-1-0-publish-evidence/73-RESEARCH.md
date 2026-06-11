# Phase 73: Inbound 1.0 Publish Evidence - Research

**Researched:** 2026-06-02
**Domain:** Hex package release evidence / publish-path rehearsal (Elixir sibling-package monorepo)
**Confidence:** HIGH

## Summary

Phase 73 is a **prepare-and-stage** documentation-and-evidence phase, not a publish phase
(CONTEXT D-01). Everything the planner needs already exists in the repo: the inbound-only
publish path is fully wired in `.github/workflows/publish-hex.yml`, the deterministic
preflight lane (`mix mailglass.publish.check --package mailglass_inbound`) already writes a
committed summary, the inbound docs-contract and root stability-contract tests already assert
release truth, and the Phase 38 release forms already encode the exact REL-03 field set with a
"not run" pending-marker convention. The phase's real work is: (a) author a new inbound-scoped
RELEASE-RECORD (+ optional checklist) in the Phase 73 dir that clones the Phase 38 shape, drops
the obsolete approver fields, and marks post-publish-only fields explicit `pending`; (b)
dry-run-rehearse the inbound-only dispatch and record its evidence; (c) refine `MAINTAINING.md`
inbound-only publish/fallback wording and fix the stale Phase 38 path at lines 256-257 (D-10);
(d) optionally extend an existing docs/release-contract test to assert the new record EXISTS
and carries the required field headers — never a gate asserting live external Hex/HexDocs state.

I verified every load-bearing claim against the live tree: line ranges in `publish-hex.yml`,
the stale `MAINTAINING.md:256-257` path (the cited `.planning/phases/38-...` dir does NOT exist;
it was archived to `.planning/milestones/v1.0-phases/38-...`), the current
`mailglass_inbound/mix.exs` `@version "1.0.0"` and `MIX_PUBLISH=true` pin `{:mailglass, "== 1.3.0"}`,
the reference-app pins (`~> 0.3` host / `~> 0.3.0` demo — correctly NOT flipped to `~> 1.0`),
the committed publish-summary, the inbound CHANGELOG `## [1.0.0]` section, and the absence of any
`mailglass_inbound-v1.0.0` git tag (only `-v0.1.0/-v0.2.0/-v0.3.0` exist — staging is genuinely pending).

**Primary recommendation:** Plan three task clusters — (1) author the inbound RELEASE-RECORD +
CHECKLIST in the Phase 73 dir cloning Phase 38's shape with pending markers; (2) run the
deterministic verification lanes (`publish.check`, `verify.stability_contract`) and a
`gh workflow run publish-hex.yml -f package=mailglass_inbound -f dry_run=true -f tag=<ref>`
rehearsal, capturing run URLs/exit status into the record; (3) refine `MAINTAINING.md`
inbound-only wording and fix the D-10 stale path. Add at most a light field-presence test
extension for evidence-completeness (D-08). Do NOT create any live-Hex/HexDocs gate, do NOT
cut the publish-triggering tag, do NOT flip reference pins, do NOT force a core/admin release.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Inbound-only publish dispatch | CI / GitHub Actions (`publish-hex.yml`) | — | Already wired; phase documents + rehearses, does not rebuild (D-06) |
| Deterministic pre-publish proof | Mix task (`mailglass.publish.check`) | Root test (`stability_contract_test`) | Package-local tarball/metadata truth lives in the task; aggregate wiring in root test |
| Release evidence artifact | Planning docs (`73-xx-RELEASE-RECORD.md`) | Light test extension (D-08) | REL-03 is an evidence record; completeness asserted by documented artifact + optional field-presence test |
| Runbook truth (inbound publish/fallback) | Docs (`MAINTAINING.md`) | — | Maintainer-facing operational doc; SC-3 |
| Live Hex/HexDocs/smoke capture | OUT OF SCOPE this phase | — | Deferred to maintainer's post-phase publish trigger (D-01, Deferred Ideas) |

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 73 **prepares and stages** the inbound-only publish path; it does NOT run the
  real `mix hex.publish` of `mailglass_inbound 1.0.0`. Publishing is irreversible after the
  60-minute / zero-download window, so the actual publish trigger stays a deliberate maintainer
  action after this phase.
- **D-02:** "Prepare" = (a) confirm `mailglass_inbound-v1.0.0` tag/ref readiness from the
  reviewed source ref WITHOUT creating the live publish-triggering tag; (b) dry-run rehearse the
  inbound-only dispatch (`package=mailglass_inbound`, `dry_run=true`); (c) author an
  evidence-ready release record. No step causes an irreversible external publish.
- **D-03:** Create a NEW inbound-scoped release record in the Phase 73 dir
  (`73-xx-RELEASE-RECORD.md`, optional matching `73-xx-RELEASE-CHECKLIST.md`), structurally
  modeled on Phase 38 forms but scoped to the single inbound package and `mailglass_inbound-v1.0.0`.
  Do NOT edit archived Phase 38 forms in place.
- **D-04:** Record carries the full REL-03 field set (tag/ref, release-vs-dispatch path, publish
  workflow run URL, fallback usage, Hex index URL, HexDocs URL, install/smoke proof, 60-minute
  revert/retire decision). DROP the obsolete GitHub-Environment approver fields from the Phase 38
  shape (publish is hands-free; `hex-publish` environment has no required reviewers).
- **D-05:** Post-publish-only fields (Hex index URL, HexDocs URL, install/smoke proof, 60-minute
  outcome) recorded as explicit `pending` / `not run` markers under the prepare posture. Pending
  evidence must read as pending, never as captured (Honest Surface Area).
- **D-06:** REL-02 requires NO workflow changes. Inbound-only dispatch is already wired in
  `publish-hex.yml`. The phase documents, dry-run-rehearses, and records — does not reinvent.
- **D-07:** The dry-run rehearsal is load-bearing: confirm a single-package inbound dispatch
  behaves correctly within the ordered fan-out (admin waits on inbound) without forcing a
  core/admin release.
- **D-08:** Completeness asserted by documented artifact PLUS at most a light extension of an
  existing docs/release-contract check — NOT a brand-new executable gate that asserts live
  Hex/HexDocs URLs (would fail deterministically and block closeout).
- **D-09:** Reference-app pins (`reference/host_app/mix.exs`, `reference/demo_app/mix.exs`) stay
  below `~> 1.0` in this phase. The flip is post-publish pin-truth, deferred.
- **D-10:** Fix the stale runbook path at `MAINTAINING.md:256-257` (cites archived
  `.planning/phases/38-...`, now at `.planning/milestones/v1.0-phases/38-...`).

### Claude's Discretion

- One file vs. record + checklist pair, and exact filename, as long as the full REL-03 field set
  is present and pending fields read as pending.
- Whether to extend an existing docs/release-contract test for evidence-completeness or rely on
  the documented artifact alone, provided no new gate asserts live external state.
- Prefer existing repo-native lanes (`mix mailglass.publish.check --package mailglass_inbound`,
  `publish-hex.yml` `dry_run`, `mix verify.stability_contract`) over inventing new mechanics.

### Deferred Ideas (OUT OF SCOPE)

- Actual `mailglass_inbound 1.0.0` Hex publish + live evidence capture (maintainer trigger after
  this phase). When it runs: flip reference pins to `~> 1.0`, capture live Hex/HexDocs/smoke
  evidence, fill the 60-minute decision.
- Matcher expansion, lifecycle callbacks, public replay API, provider extension API, synthetic
  inbound UI, `gen_smtp` listener, Cloudflare recipe docs, ecosystem integrations, demo app
  enhancements, screenshot workflow expansion, planning-directory cleanup, broad source hygiene,
  any forced core/admin release line.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-02 | Maintainer can execute or prepare the inbound-only publish path from the reviewed tag/ref without forcing a `mailglass`/`mailglass_admin` release | `publish-hex.yml` already implements `package=mailglass_inbound` dispatch with tag-pinned checkout, independent inbound-slice gating, `dry_run` input, ordered fan-out core→inbound→admin, idempotent `hex.info` skip (lines quoted below). REL-02 is satisfied by documenting + dry-run-rehearsing this path and refining `MAINTAINING.md` inbound-only wording. NO workflow change. |
| REL-03 | Maintainer can record inbound release evidence (tag/ref, release-vs-dispatch path, workflow URL, fallback usage, Hex index URL, HexDocs URL, smoke/install proof, 60-minute revert/retire decision) | New inbound RELEASE-RECORD in Phase 73 dir cloning the Phase 38 field set; post-publish fields marked `pending`/`not run`; optional light field-presence test extension (D-08). |

## Standard Stack

No new packages. This phase touches CI workflow docs, Mix task invocation, planning artifacts,
and one runbook. The relevant repo-native tooling (all already present and verified):

| Tool | Purpose | Invocation |
|------|---------|------------|
| `mix mailglass.publish.check --package mailglass_inbound` | Deterministic pre-publish tarball + metadata + linked-version preflight; writes `.planning/publish/mailglass_inbound-publish-summary.json` | `mix mailglass.publish.check --package mailglass_inbound` (root) |
| `mix verify.stability_contract` | Root semantic proof: core+admin+inbound support contracts + docs.check + `--no-optional-deps` compile | `mix verify.stability_contract` (root) |
| `mailglass_inbound/test/.../docs_contract_test.exs` | Inbound stale-wording / over-claim / pin-truth guards (D-08 extension candidate) | `cd mailglass_inbound && mix verify.docs.contract.inbound` |
| `test/mailglass/stability_contract_test.exs` | Root release-automation + inbound publish-truth internal-consistency assertions | part of `verify.support_contract.core` |
| `gh` CLI 2.93.0 (verified installed) | Trigger `dry_run=true` inbound-only dispatch rehearsal without a real publish | `gh workflow run publish-hex.yml ...` (see Code Examples) |

**Installation:** none. `gh` is present at `/opt/homebrew/bin/gh` [VERIFIED: `command -v gh`].

## Package Legitimacy Audit

Not applicable — this phase installs no external packages. (No `## Package Legitimacy Audit`
table required; nothing added to any registry.)

## Architecture Patterns

### Publish-path data flow (already wired; phase documents/rehearses this)

```
maintainer
  │  (deferred trigger — NOT this phase)
  ▼
release: published  ──OR──  workflow_dispatch (fallback/rehearsal)
  │                           │ inputs: tag, dry_run, package
  ▼                           ▼
checkout ref = inputs.tag || release.tag_name   ← NEVER `main`
  │
  ▼
prepublish-summary  (runs publish.check per selected package → STEP_SUMMARY)
  │
  ▼
gate-ci-green  (resolve tagged SHA, require ci.yml green; advisory lanes excepted)
  │
  ▼   ordered fan-out, each step: hex.info idempotency skip → publish/dry-run
publish-core ──▶ publish-inbound ──▶ publish-admin
(skipped for           (this phase's          (waits on inbound to
 inbound-only           rehearsal target)       avoid Hex index race)
 dispatch)
```

For an **inbound-only** dispatch (`package=mailglass_inbound`):
`publish-core` is skipped, `publish-inbound` runs (gated on `publish-core.result == 'skipped'`),
`publish-admin` does NOT run (its condition requires `package == 'mailglass_admin'` OR a
non-inbound-non-mailglass package). This is exactly REL-02's "publish inbound without forcing
core/admin."

### Verified `publish-hex.yml` line map (quote these in the plan)

[VERIFIED: read `.github/workflows/publish-hex.yml` 2026-06-02]

| Concern | Lines | Detail |
|---------|-------|--------|
| Trigger contract (release canonical, dispatch fallback-only, never `main`) | 3-12 | Header comment locks the contract |
| `tag` / `dry_run` / `package` dispatch inputs | 13-32 | `package` choice includes `mailglass_inbound` (line 30); `dry_run` default false (18-22); options core/admin/inbound/all |
| Tag-pinned checkout (`inputs.tag \|\| release.tag_name`) | 63-69 (summary), 203-206 (core), 284-287 (admin), 369-372 (inbound) | All four jobs pin to the tag, never `main` |
| Inbound prepublish check gating | 108-113 | Runs `mailglass.publish.check --package mailglass_inbound` only when package ≠ mailglass AND ≠ mailglass_admin |
| `gate-ci-green` (advisory-lane aware) | 115-191 | Resolves tagged SHA, requires `ci.yml` green; Operator Browser Gate advisory |
| `publish-inbound` job + condition | 345-425 | `needs: [publish-core]`; `if` allows inbound-only (`package == 'mailglass_inbound'` AND `publish-core.result == 'skipped'`), lines 354-366 |
| Inbound `MIX_PUBLISH=true` deps + dry-run skip note | 383-399 | Dry-run skips the MIX_PUBLISH deps.get (linked core not yet on Hex at a v1.x.0 cut) |
| Inbound idempotent `hex.info` skip | 406-413 | Skips publish if version already live |
| Inbound publish step (dry-run vs `--yes`) | 414-425 | `if: dry_run != 'true' && skip != 'true'` → `mix hex.publish --yes` |
| `publish-admin` waits on inbound | 257-281 | `needs: [..., publish-inbound]`; admin gated on `publish-inbound.result == 'success'` for release/`all` paths — so inbound-only dispatch does NOT trigger admin |

**Key fan-out insight:** in `dry_run=true` mode the per-sibling `mix hex.publish --dry-run` and
the `MIX_PUBLISH=true mix deps.get` are intentionally SKIPPED (lines 313, 338, 395, 420);
tarball integrity is validated upstream by `prepublish-summary`'s `mailglass.publish.check`.
A dry-run inbound dispatch therefore proves: input wiring, tag-pinned checkout, prepublish
summary for inbound, gate-ci-green resolution, and the fan-out gating — without resolving the
not-yet-published `== 1.3.0` core pin. That is exactly the load-bearing rehearsal D-07 wants.

### Phase 38 RELEASE-RECORD shape to clone (verified field set)

[VERIFIED: read `.../38-03-RELEASE-RECORD.md` and `38-03-RELEASE-CHECKLIST.md`]

Phase 38 RELEASE-RECORD top block fields:
`Release type` · `Tag` · `Publish workflow run URL` · `Post-publish smoke run URL` ·
`Proof bundle path` · `Install/upgrade rehearsal path` · `Hex index confirmation` ·
`HexDocs URLs` · `Fallback path used` · `60-minute outcome`.
Then a `## Manual approvals and external checks` block with:
`GitHub Environment approver` · `Approval timestamp` · `Branch-protection verification result`.
Then `## Proof links` and `## Notes`.

The Phase 38 CHECKLIST separates **Repo-proved before publish** (CI green, required buckets,
proof exports) from **Manual/external proof** (GitHub Environment approval, fallback dispatch,
branch-protection, live Hex/HexDocs, 60-minute window).

**For the inbound record, DROP these obsolete fields (D-04):** `GitHub Environment approver`,
`Approval timestamp`, and the checklist's "GitHub Environment approval for `hex-publish`" gate —
publish is hands-free; the `hex-publish` environment has no required reviewers (CLAUDE.md
"Commit & Branch Conventions": "the publish fan-out runs with no human approval gate"). Keep
fallback, Hex/HexDocs, smoke, and 60-minute fields but mark them `pending` / `not run`.
Branch-protection field is optional for an inbound-only slice; if dropped, note why.

### Anti-Patterns to Avoid

- **Editing the archived Phase 38 forms in place** — they are the linked core/admin v1.0 record (D-03).
- **Recording pending fields as captured** — Honest Surface Area; pending must read pending (D-05).
- **Adding a gate that asserts live Hex/HexDocs URLs** — fails deterministically under prepare
  posture; blocks milestone closeout (D-08).
- **Cutting `mailglass_inbound-v1.0.0` as a real tag** — that tag publishes on push via the
  `release: published` event chain. Stage readiness, do not create the live trigger (D-01/D-02).
- **Flipping reference-app pins to `~> 1.0`** — makes reference apps resolve an unavailable
  version before publish (D-09). They are currently `~> 0.3` (host) / `~> 0.3.0` (demo) [VERIFIED].
- **Dispatching from `main`** — version resolution is tag-based; always pass the reviewed tag.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pre-publish tarball/metadata/linked-version proof | A new validation script | `mix mailglass.publish.check --package mailglass_inbound` | Already does 14 ordered checks + writes the committed summary JSON |
| Inbound source/publish internal-consistency proof | New assertions | `test/mailglass/stability_contract_test.exs` "inbound release preflight truth is internally consistent" test (lines 116-179) | Already derives version/pin/changelog/readme/summary agreement without hardcoding literals |
| Triggering a non-destructive publish rehearsal | A bespoke local mix shim | `publish-hex.yml` `dry_run=true` dispatch via `gh` | The real workflow path; proves actual gating + fan-out |
| Release record field set | Inventing fields | Phase 38 RELEASE-RECORD/CHECKLIST shape | Encodes the exact REL-03 fields + "not run" convention |

**Key insight:** REL-02/REL-03 are evidence-and-documentation requirements over already-built
infrastructure. The cheapest honest path is to invoke existing deterministic lanes and record
their output, not to add new mechanics.

## Runtime State Inventory

This is a docs/evidence phase with one CI-doc fix; it renames/migrates no runtime state, but it
DOES stage a release. Explicit inventory:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore keys touched. (Verified: phase scope is docs + record + runbook.) | none |
| Live service config (publish trigger state) | No `mailglass_inbound-v1.0.0` git tag exists yet (only `-v0.1.0/-v0.2.0/-v0.3.0`) [VERIFIED: `git tag --list`]. Manifest already at `mailglass_inbound: 1.0.0` [VERIFIED]. The live publish-triggering tag must NOT be created this phase (D-01). | Stage readiness only; record `Tag: mailglass_inbound-v1.0.0 (staged, not cut)` |
| OS-registered state | None | none |
| Secrets/env vars | `HEX_API_KEY` already configured in repo Actions secrets (MEMORY); `MIX_PUBLISH=true` is the publish-time env selector for the inbound `== 1.3.0` pin — code rename only, not touched | none |
| Build artifacts | `mailglass_inbound/_publish_check/` is generated by `publish.check` and cleaned unless `--keep`; the committed `mailglass_inbound-publish-summary.json` is the durable artifact | Re-run `publish.check` to refresh summary if any inbound source/metadata changed (it has not this milestone since Phase 71/72) |

## Common Pitfalls

### Pitfall 1: Treating the dry-run rehearsal as a full publish proof
**What goes wrong:** Expecting the dry-run to validate the `== 1.3.0` core-pin resolution or run
`mix hex.publish --dry-run` per sibling.
**Why it happens:** The workflow intentionally SKIPS `MIX_PUBLISH=true deps.get` and the
per-sibling dry-run publish in `dry_run=true` mode (lines 313/338/395/420) because the linked
core version is not on Hex at a v1.x.0 cut.
**How to avoid:** Record the dry-run as proving input wiring + tag-pinned checkout + inbound
prepublish summary + gate + fan-out gating. Resolution proof is owned by `publish.check`'s
isolated-tarball compile, not the dry-run. State this explicitly in the record so the evidence
is not over-claimed.
**Warning signs:** A record that says "dry-run validated dependency resolution" — it did not.

### Pitfall 2: Creating the live publish-triggering tag
**What goes wrong:** Pushing `mailglass_inbound-v1.0.0` to stage readiness inadvertently arms the
release path.
**Why it happens:** The repo's release flow ties tags to publishing; the canonical path is
`release: published`. A tag plus a GitHub Release would trigger the hands-free fan-out.
**How to avoid:** "Confirm tag/ref readiness from the reviewed source ref WITHOUT creating the
live publish-triggering tag" (D-02). Reference the reviewed SHA/ref in the record; do not create
the tag or release.

### Pitfall 3: Stale runbook path silently surviving
**What goes wrong:** `MAINTAINING.md:256-257` points at `.planning/phases/38-...` which does NOT
exist [VERIFIED: `ls` returns "No such file or directory"]; the archived location is
`.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/`.
**Why it happens:** The Phase 38 dir was archived; the runbook reference was not updated.
**How to avoid:** Fix both lines (D-10). Note: the inbound record could ALSO be cited here as the
inbound-specific companion to the (still-archived) core/admin Phase 38 forms.
**Warning signs:** `docs_contract_test.exs` line 414-416 only asserts `maintaining =~ "mailglass_inbound"`
and `=~ "mix verify.stability_contract"` — it does NOT currently catch the broken path, so the
fix needs manual verification (or a new field-presence assertion if extended per D-08).

### Pitfall 4: Adding a live-state gate that reds the milestone
**What goes wrong:** A test asserting `https://hex.pm/packages/mailglass_inbound/1.0.0` resolves
fails deterministically because 1.0.0 is not published under the prepare posture.
**How to avoid:** Any D-08 extension asserts only that the RECORD FILE EXISTS and contains the
required field HEADERS (string presence), never external HTTP/Hex state.

## Code Examples

### Deterministic inbound preflight (writes the committed summary)
```bash
# Source: lib/mix/tasks/mailglass.publish.check.ex (verified)
# Runs 14 ordered checks; writes .planning/publish/mailglass_inbound-publish-summary.json
mix mailglass.publish.check --package mailglass_inbound
# Inspect the unpacked tarball without auto-clean:
mix mailglass.publish.check --package mailglass_inbound --keep
```

### Root semantic proof (core + admin + inbound + docs + no-optional-deps compile)
```bash
# Source: mix.exs verify.stability_contract alias (verified lines 293-298)
mix verify.stability_contract
```

### Non-destructive inbound-only dispatch rehearsal (D-02b / D-07)
```bash
# Source: publish-hex.yml workflow_dispatch inputs (verified lines 13-32)
# gh 2.93.0 verified installed at /opt/homebrew/bin/gh
# NOTE: dispatch from the reviewed tag/ref, NEVER from `main`.
# Under prepare posture the tag is not yet cut — rehearse against the reviewed
# release SHA/ref the maintainer will eventually tag, OR document the exact
# command for the maintainer to run post-tag. Either is honest as long as the
# record states which was done.
gh workflow run publish-hex.yml \
  -f package=mailglass_inbound \
  -f dry_run=true \
  -f tag=<reviewed-tag-or-ref>

# Capture the run for the record:
gh run list --workflow=publish-hex.yml --limit 1
gh run view <run-id> --json url,conclusion,jobs
```
The dry-run proves: `package=mailglass_inbound` routes correctly, checkout pins the tag,
`prepublish-summary` runs the inbound check, `gate-ci-green` resolves, `publish-core` is skipped,
`publish-inbound` is gated-in, and `publish-admin` does NOT run (no forced core/admin release).

### Optional D-08 field-presence assertion (lightest honest option)
```elixir
# Extend mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
# (or test/mailglass/stability_contract_test.exs). String-presence only — NO live HTTP.
test "inbound release record exists and carries the REL-03 field headers" do
  record = File.read!(Path.expand(
    "../../../.planning/phases/73-inbound-1-0-publish-evidence/73-xx-RELEASE-RECORD.md", __DIR__))
  for header <- ["Tag", "Publish workflow run URL", "Fallback", "Hex index",
                 "HexDocs", "smoke", "60-minute"] do
    assert record =~ header
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GitHub Environment manual approver gate on publish | Hands-free fan-out, no required reviewers | v1.3 era (CLAUDE.md) | Drop approver/approval-timestamp fields from the inbound record (D-04) |
| Phase 38 forms in `.planning/phases/38-...` | Archived to `.planning/milestones/v1.0-phases/38-...` | v1.0 milestone archival | `MAINTAINING.md:256-257` is now stale (D-10) |
| Inbound folded into core/admin `1.x` sibling line | Inbound is its own stable `1.0` line | v1.4/v1.6 | Record is inbound-scoped, single package; no forced core/admin cut |

**Deprecated/outdated:**
- `MAINTAINING.md:256-257` path — broken; fix to the archived location (D-10).
- GitHub Environment approver fields in the Phase 38 record shape — obsolete under hands-free publish.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The maintainer will run the actual `gh workflow run ... dry_run=true` rehearsal against the reviewed ref, OR the planner documents it as a maintainer step | Code Examples / Validation | If the phase cannot dispatch (no tag yet, no CI run on the ref), the rehearsal evidence reads as "documented command, not executed" — still honest under D-05 but the planner must decide whether the phase body runs it or stages it |
| A2 | Reference pins `~> 0.3`/`~> 0.3.0` are the intended pre-publish state (CONTEXT says `~> 0.3.0`) | User Constraints D-09 | Low — both are below `~> 1.0`; the constraint is "do not flip to `~> 1.0`", which holds either way |

**Note:** All other claims are `[VERIFIED]` against the live tree on 2026-06-02. The only genuine
open question is A1 (whether the dry-run is executed in-phase or staged as a maintainer command),
which is a planner/discretion call, not a fact gap.

## Open Questions

1. **Execute the dry-run dispatch in-phase, or stage the command for the maintainer?**
   - What we know: `gh` is installed; the workflow accepts `package=mailglass_inbound dry_run=true`.
     A dispatch requires a tag/ref with a green `ci.yml` run (gate-ci-green resolves the tagged SHA).
   - What's unclear: whether the reviewed ref already has a green `ci.yml` run that
     `gate-ci-green` can resolve, and whether the maintainer wants the phase to actually fire a
     dispatch vs. record the exact command.
   - Recommendation: Plan it as "attempt the dry-run dispatch against the reviewed ref; if a
     green `ci.yml` run exists, capture the run URL + conclusion into the record; otherwise record
     the exact `gh workflow run` command + the resolved ref and mark the run URL `pending`." Both
     satisfy D-07 honestly under the prepare posture.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI | dry-run dispatch rehearsal (D-07) | ✓ | 2.93.0 | Record the `gh workflow run` command for the maintainer |
| `git` | tag/ref readiness check | ✓ | (system) | — |
| `mix` (Elixir 1.18 / OTP 27) | `publish.check`, `verify.stability_contract` | ✓ (project baseline) | 1.18 / 27 | — |
| Postgres (test DB) | `verify.support_contract.*` lanes that boot repos | ✓ (project baseline) | 16 in CI | scope to file-level docs tests if DB unavailable |
| Live Hex.pm / HexDocs | OUT OF SCOPE (advisory only) | n/a | — | record `pending` (D-05) |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** live Hex/HexDocs intentionally not exercised (prepare posture).

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true`). Every REL-02/REL-03
must-have is provably validated through deterministic repo-native means — explicitly NOT through
live Hex/HexDocs assertions.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18 / OTP 27) |
| Config file | umbrella-style sibling configs; root `mix.exs` aliases drive lanes |
| Quick run command | `cd mailglass_inbound && mix verify.docs.contract.inbound` |
| Full suite command | `mix verify.stability_contract` (root) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-02 | Inbound-only dispatch path exists, tag-pinned, no forced core/admin | structural (workflow grep) + manual dry-run | `mix test test/mailglass/stability_contract_test.exs` (asserts `publish-hex` wiring indirectly via release-automation test) + `gh workflow run ... dry_run=true` exit status | ✅ (stability_contract_test exists) |
| REL-02 | Runbook documents inbound-only publish/fallback path | docs-contract | `cd mailglass_inbound && mix verify.docs.contract.inbound` (line 415-416 asserts MAINTAINING mentions inbound + stability_contract) | ✅ |
| REL-02 | Stale Phase 38 path fixed (D-10) | manual verify + optional new assertion | `grep -n "phases/38" MAINTAINING.md` returns nothing; archived path present | ✅ (grep is the check) |
| REL-03 | Inbound publish preflight summary is internally consistent | unit | `mix test test/mailglass/stability_contract_test.exs:116` ("inbound release preflight truth is internally consistent") | ✅ |
| REL-03 | Pre-publish tarball/metadata proof | task exit status | `mix mailglass.publish.check --package mailglass_inbound` (exit 0) | ✅ |
| REL-03 | Release record exists with required field headers + pending markers | field-presence (D-08, optional) | new test asserting record file `=~` each REL-03 header + `pending`/`not run` for post-publish fields | ❌ Wave 0 (if D-08 extension chosen) |

### Sampling Rate
- **Per task commit:** `cd mailglass_inbound && mix verify.docs.contract.inbound` (fast docs guard)
- **Per wave merge:** `mix verify.stability_contract` (full root proof) + `mix mailglass.publish.check --package mailglass_inbound`
- **Phase gate:** Full `mix verify.stability_contract` green + dry-run rehearsal evidence recorded (run URL or staged command) + record field-presence test green (if added) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] (If D-08 extension chosen) Add a field-presence test for the inbound RELEASE-RECORD to
  `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` OR
  `test/mailglass/stability_contract_test.exs` — string-presence of REL-03 headers + pending
  markers, NO live HTTP. Lightest honest option per D-08.
- [ ] (If D-10 hardening desired) Add an assertion that `MAINTAINING.md` does NOT contain
  `.planning/phases/38-` (catches regression of the stale path). Optional.

*Existing infrastructure (`stability_contract_test`, `docs_contract_test`, `publish.check`,
`verify.stability_contract`) already covers REL-02 wiring and REL-03 source-truth consistency.
The only new test is the optional record field-presence guard.*

## Security Domain

`security_enforcement` is not set to `false` (absent = enabled), but this phase's surface is
docs/evidence/CI-doc only — no auth, session, access-control, input-validation, or crypto code is
added or modified.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | no | no user input added |
| V6 Cryptography | no | n/a |

### Release-security note (informational, not a phase change)
| Concern | Mitigation (already in place) |
|---------|-------------------------------|
| `HEX_API_KEY` exposure on a failed/inbound-only dispatch | `publish-inbound`/`publish-admin` gating requires upstream success/skipped-by-design, never skipped-by-failure (workflow comments lines 348-353, 262-266). Preserve this — do NOT loosen the gating when documenting. |
| Publishing from the wrong commit | Tag-pinned checkout (`inputs.tag \|\| release.tag_name`), never `main`. Record must capture the exact ref. |
| Hands-free publish with no reviewer gate | Intentional policy (CLAUDE.md); the record drops approver fields accordingly. Do not reintroduce an approval claim that does not exist. |

## Sources

### Primary (HIGH confidence — all read from the live tree 2026-06-02)
- `.github/workflows/publish-hex.yml` — full file; line map verified
- `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` + `38-03-RELEASE-CHECKLIST.md` — field set + "not run" convention
- `lib/mix/tasks/mailglass.publish.check.ex` — 14-check pipeline + summary writer
- `mailglass_inbound/mix.exs` — `@version "1.0.0"`, `{:mailglass, "== 1.3.0"}` under MIX_PUBLISH, package allowlist, docs extras
- `.planning/publish/mailglass_inbound-publish-summary.json` + `-files.expected` — committed truth
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` — inbound docs guards (D-08 candidate)
- `test/mailglass/stability_contract_test.exs` — root release-automation + inbound preflight consistency
- `MAINTAINING.md` (220-339) — Release Runbook, Retract Decision Tree, inbound fallback wording, stale 256-257 path
- `mix.exs` (290-312) — `verify.stability_contract` alias body
- `.release-please-manifest.json` — `mailglass_inbound: 1.0.0`
- `reference/host_app/mix.exs` + `reference/demo_app/mix.exs` — pins at `~> 0.3` / `~> 0.3.0` (correctly not flipped)
- `git tag --list` — no `mailglass_inbound-v1.0.0` yet; `command -v gh` → 2.93.0
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` (REL-02/REL-03), `73-CONTEXT.md`

### Secondary / Tertiary
- None — no web sources needed; entire phase is repo-internal and verified by direct read.

## Metadata

**Confidence breakdown:**
- Publish-path state: HIGH — read the full workflow + verified every line range
- Phase 38 record shape: HIGH — read both forms
- REL-03 field set + pending convention: HIGH — verified against Phase 38 + D-04/D-05
- Deterministic verification lanes: HIGH — read the task, both contract tests, and the alias body
- Stale path defect (D-10): HIGH — confirmed cited dir does NOT exist; archived dir does
- Dry-run rehearsal mechanics: HIGH — `gh` verified installed; dry-run skip logic read in workflow

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (stable; repo-internal — only invalidated by edits to publish-hex.yml,
the contract tests, the publish.check task, or the Phase 38 forms)
