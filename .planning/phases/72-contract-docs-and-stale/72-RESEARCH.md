# Phase 72: Contract Docs and Stale-Claim Guards — Research

**Researched:** 2026-06-02
**Domain:** Elixir docs-contract editing, stale-claim guards, ExUnit string assertions, Mix task token rules
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Contract Wording**
- D-01: Public wording should say one thing everywhere: `mailglass_inbound` has its own independent stable `1.0` contract documented in `mailglass_inbound/docs/api_stability.md`.
- D-02: Preserve the matched `mailglass` / `mailglass_admin` `1.x` sibling line as a separate compatibility story. Do not imply that core, admin, and inbound are one matched three-package `1.x` release line.
- D-03: Replace stale wording that says inbound is excluded from the `1.x` compatibility promise, remains outside the `v1.x` stability promise, or is supported only through `mailglass_inbound` `0.x`. Correct replacements should distinguish "not part of the linked core/admin version group" from "not stable."
- D-04: Keep `mailglass_inbound/docs/api_stability.md` inventory-shaped. README, jobs, maintainer, and compatibility docs may summarize and route readers there, but should not become competing contract inventories.

**Stale-Claim Guard Shape**
- D-05: Extend existing proof seams rather than creating a new verifier.
- D-06: Prefer exact stale-phrase guards for known bad claims; dynamic parsing only where it materially improves durability.
- D-07: Do not ban every mention of `1.x` around inbound. The correct posture: inbound is not part of the matched core/admin `1.x` group, but it does have its own stable `1.0` contract.

**Release Topology And Source Refs**
- D-08: Treat release topology truth as part of Phase 72's stale-claim surface. `release-please-config.json` has three packages, but the linked-versions group includes only core/admin; `.release-please-manifest.json` records core/admin `1.3.0` and inbound `1.0.0`.
- D-09: Planning should consider correcting inbound package docs/source metadata from generic `mailglass-sibling-group-v%{version}` pattern to package-tag refs such as `mailglass_inbound-v1.0.0`, and should refresh the inbound publish summary if source/package metadata truth changes.
- D-10: Keep Phase 73 separate: live Hex index, HexDocs URLs, workflow run URLs, post-publish smoke/install proof, fallback usage, and 60-minute revert/retire decision.

**Public Surface Targets**
- D-11: Primary Phase 72 surfaces: `guides/compatibility-and-deprecations.md`, `guides/jobs.md`, root `README.md`, `MAINTAINING.md`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/docs/inbound-install.md`, relevant package tables/status sections, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, `test/mailglass/docs_contract_test.exs`, `test/mailglass/stability_contract_test.exs`, and `lib/mix/tasks/mailglass.docs.check.ex`.
- D-12: Known stale surfaces: compatibility guide support matrix and deprecation-DX horizons, `guides/jobs.md` and its current contract test, a `MAINTAINING.md` JTBD refresh note that still says inbound is outside the `v1.x` promise, and inbound package source-ref metadata.
- D-13: Reference/demo app published-Hex pins (`~> 0.3`) remain Phase 73.

**Ecosystem Lessons And DX**
- D-14 through D-16: Keep docs calm, exact, maintainer-like. Do not blur framework semantics with provider implementation details.

### Claude's Discretion
- Planner may choose exact assertion names and exact string tokens, provided the checks fail on stale inbound `0.x`/outside-`v1.x` claims in current public docs while allowing historical changelog or archived context.
- Planner may choose whether topology guards live in root docs-contract tests, root stability-contract tests, or both, provided they remain deterministic.
- Planner should use existing repo-native commands and avoid creating another release truth engine.

### Deferred Ideas (OUT OF SCOPE)
- Phase 73: Reference/demo app published-Hex pins, Hex index URL, HexDocs URL, workflow run URL, smoke/install proof, fallback usage, 60-minute revert/retire decision.
- Out of v1.6 scope: matcher expansion, lifecycle callbacks, public replay API, provider extension API, synthetic inbound UI, `gen_smtp` listener, Cloudflare recipe docs, ecosystem integrations, demo app enhancements, screenshot workflow expansion, planning-directory cleanup, broad source hygiene, forced core/admin release work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Adopter-facing docs describe `mailglass_inbound` as its own stable `1.0` package contract routed through `mailglass_inbound/docs/api_stability.md`, not as `v0.5+`, `0.3`, or outside stability truth. | Five stale claim sites identified below with exact replacement wording. |
| DOC-02 | Compatibility docs preserve the matched `mailglass` / `mailglass_admin` `1.x` sibling line while explaining that inbound has a separate `1.0` contract and does not widen core/admin compatibility promises. | Exact stale support matrix row and DX inventory horizons identified below. |
| PROOF-02 | Executable docs-contract or release-contract checks pin the highest-risk stale claims: inbound install version, package table status, maintainer runbook smoke dependencies, and inbound-only release wording. | Exact test changes and new token rules identified for each proof seam. |
</phase_requirements>

---

## Summary

Phase 72 is a narrow docs-truth and stale-claim guard phase. All `mailglass_inbound` source/package truth was validated clean by Phase 71 (`mix mailglass.publish.check --package mailglass_inbound` passes, `stability_contract_test.exs` 6/6, `docs_contract_test.exs` 24/24). What remains is the public prose layer: five stale-claim sites across four files that still describe inbound as outside or excluded from stability, plus three executable guard gaps where those stale phrases are either required (and should become forbidden) or not yet guarded.

There are no new packages to install, no schema changes, no new modules to write. The work is: (1) correct stale wording in four doc files, (2) fix two corresponding proof seams in existing test/task files, (3) decide whether to fix the `source_ref_pattern` in `mailglass_inbound/mix.exs` and regenerate the publish summary if so. The hardest judgment call is the `source_ref_pattern`: the current value `mailglass-sibling-group-v%{version}` implies inbound ships under the sibling-group tag, but the manifest and publish-summary already record `source_ref: "v1.0.0"` and the `stability_contract_test.exs` asserts `source_ref == "v#{expected_version}"`. D-09 directs planning to consider a package-specific tag pattern (`mailglass_inbound-v%{version}`); research confirms this is a pre-publish correctness fix since no `1.0.0` tag exists yet.

**Primary recommendation:** Edit the five stale sites, update the three proof seams, fix the `source_ref_pattern`, regenerate the publish summary, and run the existing verification lane to confirm clean.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public prose accuracy (stale claims) | Documentation layer | — | Markdown edits in guides/, README, MAINTAINING.md |
| Executable stale-claim guards | ExUnit tests + Mix task token rules | — | Existing `docs_contract_test.exs`, `stability_contract_test.exs`, and `mailglass.docs.check.ex` seams |
| Package source metadata | `mailglass_inbound/mix.exs` | `.planning/publish/mailglass_inbound-publish-summary.json` | `source_ref_pattern` in the `:package` key of mix.exs controls Hex publish metadata |
| Publish summary refresh | `mix mailglass.publish.check --package mailglass_inbound` | — | The existing lane regenerates the snapshot from the current mix.exs state |

---

## Standard Stack

No new packages. This phase operates entirely within existing repo infrastructure.

| Tool | Version | Purpose |
|------|---------|---------|
| ExUnit | bundled with Elixir 1.18 | Test assertions in existing test files |
| `mix mailglass.docs.check` | repo-native | Tier 1 token required/forbidden rules |
| `mix mailglass.publish.check --package mailglass_inbound` | repo-native | Regenerates publish summary after mix.exs changes |
| `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | repo-native | Root docs/JTBD contract assertions |
| `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` | repo-native | Root release topology assertions |
| `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | repo-native | Package-local inbound docs-contract assertions |

---

## Package Legitimacy Audit

No external packages are installed in this phase. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Public docs layer (Markdown)
    guides/compatibility-and-deprecations.md  ←— stale claim sites: support matrix row + DX inventory horizons
    guides/jobs.md                            ←— stale claim sites: intro header + "One more thing" footer
    MAINTAINING.md                            ←— stale claim site: JTBD refresh protocol step 5

Executable proof seams (ExUnit + Mix task)
    test/mailglass/docs_contract_test.exs     ←— currently asserts stale wording; must be flipped
    test/mailglass/stability_contract_test.exs ←— already guards root README; may need topology guard
    lib/mix/tasks/mailglass.docs.check.ex     ←— currently requires stale token; must flip to forbidden

Package metadata
    mailglass_inbound/mix.exs                 ←— source_ref_pattern; may need correction
    .planning/publish/mailglass_inbound-publish-summary.json ←— regenerated by publish.check lane
```

Data flow for correctness verification:
1. Edit stale doc sites → prose truth corrected
2. Flip required/forbidden tokens in docs.check.ex → `mix mailglass.docs.check` fails on stale, passes on corrected
3. Flip assert/refute in docs_contract_test.exs → `mix test` fails on stale, passes on corrected
4. If source_ref_pattern changed → run `mix mailglass.publish.check --package mailglass_inbound` → publish summary regenerated → stability_contract_test.exs passes

### Recommended Project Structure

No new directories needed. All edits are in-place.

### Anti-Patterns to Avoid

- **Adding a new verifier:** D-05 says extend existing proof seams. Do not create a new Mix task or separate test file.
- **Banning `1.x` around inbound entirely:** D-07 is explicit: inbound has its own `1.0` contract; docs may correctly distinguish "not in the linked core/admin `1.x` group" from "not stable."
- **Competing contract inventories:** D-04 says README/guides may summarize and route, not enumerate stable surfaces. Do not turn compatibility guide into a second stable-module list.
- **Hardcoding the version number in new test assertions:** Existing pattern in `stability_contract_test.exs` uses `expected_version = "1.0.0"` where semantically appropriate, and regex patterns (`~r/@version "\d+\.\d+\.\d+"`) for ceremony-agnostic truth. Follow the established pattern.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting stale phrases in docs | Custom file scanner | Extend `@tier1_surface_rules` in `mailglass.docs.check.ex` | The existing task already reads files and checks required/forbidden tokens; adding entries is two lines |
| Proving topology between config/manifest/summary | New verifier task | Extend `test/mailglass/stability_contract_test.exs` | The test already reads and JSON-parses all three files; add assertions to the existing describe block |
| Proving stale jobs.md wording | New test file | Extend `test/mailglass/docs_contract_test.exs` | The `"freshness stamp and inbound stability boundary are present"` test already exists for this exact purpose |
| Refreshing publish summary after mix.exs change | Hand-edit the JSON | `mix mailglass.publish.check --package mailglass_inbound` | The task reads mix.exs state and writes canonical output; hand-editing breaks checksum integrity |

---

## Stale-Claim Inventory (the complete list of things to change)

This is the factual core of Phase 72 research. Every item below was identified by reading actual file content.

### Stale Claim 1 — `guides/jobs.md` intro header (DOC-01)

**File:** `guides/jobs.md`, lines 3-7
**Current text (exact):**
```
> **Current as of 2026-05-23.** This guide covers the shipped, `v1.x`-stable
> jobs in `mailglass` and `mailglass_admin`. Inbound mail
> (`mailglass_inbound`) is summarized near the end, but it remains **outside the
> `v1.x` stability promise** for now.
```
**Why stale:** Says inbound is outside the `v1.x` stability promise. Inbound now has its own stable `1.0` contract. The correct posture (per D-03) is: inbound is not part of the linked core/admin `v1.x` group, but it has a separate stable `1.0` contract.
**Replacement direction:** Update date. Change the inbound stability note from "outside the `v1.x` stability promise" to something like "has its own independent stable `1.0` contract documented in `mailglass_inbound/docs/api_stability.md`."

### Stale Claim 2 — `guides/jobs.md` "One more thing: receiving mail" footer (DOC-01)

**File:** `guides/jobs.md`, lines 416-419
**Current text (exact):**
```
Today it ships verified ingress for Postmark and SendGrid, and the repo's v1.2
work is expanding that surface with more provider, operator, testing, and docs
maturity. It is real, useful, and shipping, but it is still **outside the
`v1.x` stability promise**. Treat it as production-capable and still hardening.
```
**Why stale:** "v1.2 work is expanding" is historical; the package shipped 1.0.0 through v1.4. "still outside the `v1.x` stability promise" contradicts Phase 66 release-position decision.
**Replacement direction:** Replace with a two-sentence description noting `mailglass_inbound` `1.0.0` has its own independent stable `1.0` contract and routes adopters to `mailglass_inbound/docs/api_stability.md`.

### Stale Claim 3 — `guides/compatibility-and-deprecations.md` support matrix row (DOC-02)

**File:** `guides/compatibility-and-deprecations.md`, line 166
**Current text (exact):**
```
| `mailglass_inbound` | excluded from the `1.x` compatibility promise in this milestone | `README.md`, `docs/api_stability.md` |
```
**Why stale:** Says inbound is "excluded from the `1.x` compatibility promise in this milestone." Inbound now has a separate `1.0` contract. The prose must distinguish "not part of the linked core/admin `1.x` group" from "not stable."
**Replacement direction:** Change the supported posture cell to something like "independent `1.0` contract; see `mailglass_inbound/docs/api_stability.md`" and update the proof artifact column to `mailglass_inbound/docs/api_stability.md`.

### Stale Claim 4 — `guides/compatibility-and-deprecations.md` deprecation-DX inventory support-until horizons (DOC-02)

**File:** `guides/compatibility-and-deprecations.md`, lines 217-219 (three table rows)
**Current "Support-until horizon" cell text (exact, repeated three times):**
```
Through `mailglass_inbound` `0.x`; semantic break requires a major release position decision
```
**Why stale:** Says the stable surfaces were only supported through the `0.x` line and a major release-position decision was still pending. That decision was made (Phase 66): `1.0.0`. The horizons must now reflect the `1.0` contract, i.e., semantic breaks require a deprecation bridge or a major-version change (inbound `2.0`).
**Replacement direction:** Replace the three "Support-until horizon" cells. New text: "Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change" (or equivalent). This is the inbound equivalent of the core/admin `v2.0` horizon language in the major-releases section.

### Stale Claim 5 — `MAINTAINING.md` JTBD refresh protocol step 5 (DOC-01)

**File:** `MAINTAINING.md`, lines 117-118
**Current text (exact):**
```
   - keep inbound summarized separately while it remains outside the `v1.x`
     promise
```
**Why stale:** The conditional "while it remains outside" is no longer true. Inbound has its own `1.0` contract.
**Replacement direction:** Replace with something like "keep inbound summarized separately, noting its own independent `1.0` contract and routing readers to `mailglass_inbound/docs/api_stability.md`."

---

## Proof Seam Changes (the complete list of executable guard changes)

### Proof Seam 1 — `lib/mix/tasks/mailglass.docs.check.ex` README.md rules (PROOF-02)

**Current state:** `README.md` has this required token:
```elixir
"mailglass_inbound` is outside the `v1.x` stability promise"
```
**Why stale:** Phase 71 already removed this phrase from `README.md` and replaced it with correct stable `1.0` wording. The root docs_contract_test.exs at line 51 already has `refute readme =~ "`mailglass_inbound` is outside the `v1.x` stability promise"`. But `mailglass.docs.check.ex` still **requires** this now-absent phrase, meaning `mix mailglass.docs.check` currently fails on the corrected README.

Wait — this requires verification. If Phase 71 removed the phrase from README.md, the docs.check task's `required:` entry would fail. Let me clarify: the docs_contract_test.exs line 51 refutes the phrase (meaning the README must NOT have it), which conflicts with the docs.check task that REQUIRES it. [VERIFIED by reading both files]

**Action:** In `@tier1_surface_rules` for `"README.md"`:
- Remove `"mailglass_inbound` is outside the `v1.x` stability promise"` from `required:`
- Add appropriate stable-`1.0` required token(s) matching what Phase 71 already put in the README (e.g., `"**`mailglass_inbound`** (inbound routing; stable 1.0)"` or `"`mailglass_inbound` has its own stable `1.0` contract inventory"` — both of which are already in README.md per `docs_contract_test.exs` line 44-45)

**Note:** The `refute readme =~ "`mailglass_inbound` is outside the `v1.x` stability promise"` in docs_contract_test.exs (line 51) is already correct and passes. The problem is only in `mailglass.docs.check.ex`.

### Proof Seam 2 — `test/mailglass/docs_contract_test.exs` jobs.md freshness test (PROOF-02)

**Current state:** The `"freshness stamp and inbound stability boundary are present"` test (lines 356-363) has:
```elixir
assert jobs =~ "Current as of 2026-05-23"
assert jobs =~ "outside the"
assert jobs =~ "`v1.x` stability promise"
```
**Why stale:** After Stale Claims 1 and 2 are corrected, "outside the" and "`v1.x` stability promise" will no longer appear in `guides/jobs.md`, and the date will change.
**Action:** Update the three assertions:
- Change `"Current as of 2026-05-23"` to the new date (e.g., `"Current as of 2026-06-02"`)
- Replace `assert jobs =~ "outside the"` with an assert on the new stable-`1.0` wording
- Replace `assert jobs =~ "\`v1.x\` stability promise"` with a refute on the stale phrase, plus an assert on the stable `1.0` routing phrase

**Concrete new assertion pattern (approximate):**
```elixir
assert jobs =~ "Current as of 2026-06-02"
assert jobs =~ "independent stable `1.0` contract"
assert jobs =~ "mailglass_inbound/docs/api_stability.md"
refute jobs =~ "outside the `v1.x` stability promise"
```

### Proof Seam 3 — `guides/compatibility-and-deprecations.md` token rules in docs.check (PROOF-02)

**Current state:** `@tier1_surface_rules` for `"guides/compatibility-and-deprecations.md"` does not have a forbidden token for the stale exclusion phrase.

**Action:** Add to `forbidden:` in the compatibility guide rules:
```elixir
"excluded from the `1.x` compatibility promise"
```
And optionally add a required token asserting the new stable posture of inbound in the support matrix, such as:
```elixir
"independent `1.0` contract"
```
This ensures `mix mailglass.docs.check` catches any future regression to the stale wording.

---

## Source Ref Metadata Decision (D-09)

**Current state in `mailglass_inbound/mix.exs`:**
```elixir
source_ref_pattern: "mailglass-sibling-group-v%{version}"
# and in docs():
source_ref: "v" <> @version
```

**Current state in `.planning/publish/mailglass_inbound-publish-summary.json`:**
```json
"source_ref": "v1.0.0",
"source_ref_pattern": "mailglass-sibling-group-v%{version}"
```

**Current test assertion in `stability_contract_test.exs` line 140:**
```elixir
assert summary["source_ref"] == "v#{expected_version}"
```
This passes because the summary has `"source_ref": "v1.0.0"`. The `source_ref` in `docs()` is `"v1.0.0"`, which is correct for linking source to the release tag.

**The issue with `source_ref_pattern`:** This field controls which tag HexDocs uses to link source files. `"mailglass-sibling-group-v%{version}"` would resolve to the tag `mailglass-sibling-group-v1.0.0`, which does not exist (the sibling-group tag exists for core/admin, not for inbound's independent release). Per D-09, the correct pattern is `"mailglass_inbound-v%{version}"` which resolves to `mailglass_inbound-v1.0.0`.

**Confirmed by:** Release-please config shows inbound is not in the linked-versions group (`components: ["mailglass", "mailglass_admin"]`). The inbound-only publish path uses `package=mailglass_inbound` dispatched from the `mailglass_inbound-v1.0.0` tag (per MAINTAINING.md). [VERIFIED: release-please-config.json line 24-26, MAINTAINING.md line 298]

**Action:** In `mailglass_inbound/mix.exs`, change:
```elixir
source_ref_pattern: "mailglass-sibling-group-v%{version}"
```
to:
```elixir
source_ref_pattern: "mailglass_inbound-v%{version}"
```
Then run `mix mailglass.publish.check --package mailglass_inbound` to regenerate `.planning/publish/mailglass_inbound-publish-summary.json`.

**Test impact:** `stability_contract_test.exs` currently does not assert the `source_ref_pattern` value. The test that runs after the summary regeneration (`assert summary["source_ref"] == "v#{expected_version}"`) continues to pass (unchanged). Add an assertion for the corrected `source_ref_pattern` value to guard against future regression.

---

## Common Pitfalls

### Pitfall 1: Forgetting the `mix mailglass.docs.check` required-token conflict
**What goes wrong:** The `README.md` required-token list in `mailglass.docs.check.ex` still requires `"mailglass_inbound\` is outside the \`v1.x\` stability promise"`. Phase 71 removed this phrase from the README. So `mix mailglass.docs.check` currently fails on the README. If a planner only edits the prose and tests without fixing the task, the docs-check CI lane stays broken.
**How to avoid:** Fix the `@tier1_surface_rules` for `"README.md"` before running `mix mailglass.docs.check` as a verification step.

### Pitfall 2: Forgetting to update the jobs.md date
**What goes wrong:** The `docs_contract_test.exs` freshness test asserts `"Current as of 2026-05-23"`. If the jobs.md wording is updated but the date is not changed, the test still passes but the date claim is stale.
**How to avoid:** Update the date to `2026-06-02` (research date) when updating jobs.md. The test assertion must be updated to match.

### Pitfall 3: Over-claiming in the compatibility guide replacement
**What goes wrong:** The replacement wording for the support matrix row might accidentally say "mailglass_inbound is part of the `1.x` contract" rather than "inbound has its own independent `1.0` contract."
**How to avoid:** The new wording must be precise: inbound is NOT part of the linked core/admin `1.x` group. It has its own separate `1.0` contract. The compatibility guide's intro already says to route inbound claims through `mailglass_inbound/docs/api_stability.md`.

### Pitfall 4: Treating the `source_ref_pattern` change as requiring a new stability_contract_test assertion in the same test block as the exact-version test
**What goes wrong:** The `"inbound 1.0 release preflight truth is exact"` test block in `stability_contract_test.exs` asserts exact values. Adding `source_ref_pattern` to the publish-summary JSON requires that test to be updated or the publish summary to be regenerated first.
**How to avoid:** Run `mix mailglass.publish.check --package mailglass_inbound` to regenerate the summary after changing `mix.exs`. Add the `source_ref_pattern` assertion to the stability test afterward.

### Pitfall 5: Not running the inbound docs-contract lane after compatibility guide edits
**What goes wrong:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` has a test (`"adoption path and compatibility routing stay canonical"`) that reads `guides/compatibility-and-deprecations.md` and asserts several exact tokens. If the compatibility guide changes break any of those tokens, the inbound lane fails.
**How to avoid:** Run `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` as a verification step after any compatibility guide edits. The existing tokens that must remain: `"mailglass_inbound/docs/api_stability.md"`, `"stable/internal/deferred source"`, `"Reachability is not a compatibility promise."`, `"## mailglass_inbound compatibility"`, `"## Inbound deprecation-DX inventory"`, and the DX inventory header row.

---

## Code Examples

### Example 1: Correct support matrix row for `mailglass_inbound` (DOC-02)

Current stale row:
```markdown
| `mailglass_inbound` | excluded from the `1.x` compatibility promise in this milestone | `README.md`, `docs/api_stability.md` |
```

Corrected row (semantics-first, routes to inbound's own inventory):
```markdown
| `mailglass_inbound` | independent `1.0` contract; see `mailglass_inbound/docs/api_stability.md` | `mailglass_inbound/docs/api_stability.md` |
```

### Example 2: Correct DX inventory support-until horizon (DOC-02)

Current stale cell (three occurrences):
```markdown
Through `mailglass_inbound` `0.x`; semantic break requires a major release position decision
```

Corrected cell (parallel with core/admin major-release language):
```markdown
Through `mailglass_inbound` `1.x`; semantic break requires a deprecation bridge or a `mailglass_inbound` major-version change
```

### Example 3: Correct `@tier1_surface_rules` entry for `README.md` in docs.check (PROOF-02)

Current stale required token:
```elixir
"mailglass_inbound` is outside the `v1.x` stability promise"
```

Replacement in `required:` (pick tokens already present in corrected README.md):
```elixir
"**`mailglass_inbound`** (inbound routing; stable 1.0)",
"`mailglass_inbound` has its own stable `1.0` contract inventory"
```

The first token already exists in the README (confirmed `docs_contract_test.exs` line 47). The second also exists (line 44).

### Example 4: Updated jobs.md freshness test assertions (PROOF-02)

Current stale:
```elixir
assert jobs =~ "Current as of 2026-05-23"
assert jobs =~ "outside the"
assert jobs =~ "`v1.x` stability promise"
```

Corrected:
```elixir
assert jobs =~ "Current as of 2026-06-02"
assert jobs =~ "independent stable `1.0` contract"
assert jobs =~ "mailglass_inbound/docs/api_stability.md"
refute jobs =~ "outside the `v1.x` stability promise"
```

### Example 5: Corrected `source_ref_pattern` in `mailglass_inbound/mix.exs` (D-09)

Current:
```elixir
source_ref_pattern: "mailglass-sibling-group-v%{version}",
```

Corrected:
```elixir
source_ref_pattern: "mailglass_inbound-v%{version}",
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| inbound described as outside `v1.x` stability | inbound has independent `1.0` contract, not part of linked core/admin group | Phase 66 release-position decision (2026-06-01) | Requires correcting five stale-claim sites in four doc files |
| `source_ref_pattern` uses sibling-group tag | should use inbound-specific package tag | Phase 72 (pre-publish correction) | Resolves to correct `mailglass_inbound-v1.0.0` tag on HexDocs |
| `support-until horizon` in DX inventory says "through 0.x" | should say "through 1.x" with major-version change trigger | Phase 72 (post Phase 66) | Three table cells in compatibility guide |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix mailglass.docs.check` currently fails because it requires the stale `"mailglass_inbound\` is outside..."` token that Phase 71 already removed from README.md | Proof Seam 1 | If the check passes, the required token may still be present in README.md, meaning Phase 71 did not fully remove it — in that case the README still needs editing |
| A2 | `guides/jobs.md` does not contain `"independent stable \`1.0\` contract"` or similar new wording yet (it was not touched by Phase 71) | Stale Claims 1 & 2 | If jobs.md already has the new wording, some prose edits can be skipped |

Both A1 and A2 can be verified in under 60 seconds at execution time with `grep`:
- A1: `grep "outside the.*v1.x" README.md` should return nothing (Phase 71 removed it); `mix mailglass.docs.check` should show the missing token failure.
- A2: `grep "independent stable" guides/jobs.md` should return nothing.

---

## Open Questions

1. **Exact replacement wording for jobs.md "One more thing" paragraph**
   - What we know: the current paragraph describes inbound as "still outside the `v1.x` stability promise" and references "repo's v1.2 work is expanding."
   - What's unclear: whether to keep "production-capable" framing or replace entirely with the canonical routing to `mailglass_inbound/docs/api_stability.md`.
   - Recommendation: Keep the paragraph's spirit (brief summary of what inbound does, routing to full docs), update the stability claim to match the corrected intro header. Two sentences max per D-16 ("small honest surfaces beat broad claims").

2. **Whether `guides/compatibility-and-deprecations.md` "What this guide does not promise" section needs updating**
   - Current text (line 225): `"support for \`mailglass_inbound\` within the \`1.x\` contract covered here"`
   - What's unclear: this is technically accurate — the guide covers core/admin `1.x`, not inbound's contract. But it may read as "inbound is not stable," which conflicts with D-03.
   - Recommendation: Rephrase to make the boundary clearer: this guide covers the matched `mailglass` / `mailglass_admin` `1.x` line; `mailglass_inbound` has its own independent contract documented in `mailglass_inbound/docs/api_stability.md`. This distinguishes "not covered by THIS guide" from "not stable."

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | All test commands | Yes (project requirement) | 1.18+ | — |
| PostgreSQL | `mix test` for inbound suite | Yes (dev environment proven in Phase 71) | 14+ | — |
| `mix mailglass.publish.check` | Publish summary regeneration | Yes (repo-native task) | repo-native | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir 1.18) |
| Config file | `test/test_helper.exs` (root), `mailglass_inbound/test/test_helper.exs` |
| Quick run command (root docs) | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` |
| Quick run command (root stability) | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` |
| Quick run command (inbound docs) | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` |
| Docs check command | `mix mailglass.docs.check` |
| Full lane | `mix verify.stability_contract` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-01 | inbound described as stable `1.0` in jobs.md header | unit (string assert) | `mix test test/mailglass/docs_contract_test.exs -k "freshness stamp" --warnings-as-errors` | Yes (line 356) — assertion needs update |
| DOC-01 | inbound described as stable `1.0` in jobs.md footer | unit (string assert) | `mix test test/mailglass/docs_contract_test.exs -k "freshness stamp" --warnings-as-errors` | Yes — assertion needs update |
| DOC-01 | MAINTAINING.md JTBD step no longer says "outside v1.x" | unit (string assert) | `mix test test/mailglass/docs_contract_test.exs -k "MAINTAINING" --warnings-as-errors` | Partial — existing MAINTAINING test may not cover step 5 wording |
| DOC-02 | compatibility guide support matrix row corrected | unit (token rule) | `mix mailglass.docs.check` | Yes — add forbidden token |
| DOC-02 | DX inventory support-until horizons corrected | unit (string assert) | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs -k "adoption path" --warnings-as-errors` | Partial — existing test checks routing tokens, not horizon wording |
| PROOF-02 | docs.check does not require stale outside-v1.x token | integration (Mix task) | `mix mailglass.docs.check` | Yes — requires modifying @tier1_surface_rules |
| PROOF-02 | source_ref_pattern corrected in publish summary | unit (JSON assert) | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` | Partial — summary is read; `source_ref_pattern` not yet asserted |

### Sampling Rate
- **Per task commit:** `mix mailglass.docs.check && mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors`
- **Per wave merge:** `mix verify.stability_contract` (runs all three lanes)
- **Phase gate:** Full lane green before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. No new test files or framework installs needed.

---

## Security Domain

No security-sensitive changes. This phase edits Markdown documentation and token rules in an existing Mix task. No authentication, cryptography, input validation, or access-control surfaces are modified.

---

## Sources

### Primary (HIGH confidence)

- Direct file reads of all six primary doc surfaces (`guides/compatibility-and-deprecations.md`, `guides/jobs.md`, `MAINTAINING.md`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/api_stability.md`) — current stale claim locations verified by reading actual content.
- Direct file reads of all three executable proof seams (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, `test/mailglass/docs_contract_test.exs`, `test/mailglass/stability_contract_test.exs`) — exact assertion names, line numbers, and current assert/refute posture verified.
- Direct file read of `lib/mix/tasks/mailglass.docs.check.ex` — `@tier1_surface_rules` for `README.md` confirms stale required token.
- Direct file reads of `mailglass_inbound/mix.exs`, `release-please-config.json`, `.release-please-manifest.json`, `.planning/publish/mailglass_inbound-publish-summary.json` — source_ref_pattern and topology truth verified.
- `.planning/phases/71-inbound-release-truth-preflight/71-VERIFICATION.md` — exact list of Phase 71 deferred items confirmed.

### Secondary (MEDIUM confidence)

- `.planning/phases/72-contract-docs-and-stale/72-CONTEXT.md` — decisions D-01 through D-16 used to constrain research scope.
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, PROOF-02 requirements confirmed against findings.

---

## Metadata

**Confidence breakdown:**
- Stale claim locations: HIGH — verified by reading each file, exact line numbers known
- Proof seam changes: HIGH — verified by reading each test and the Mix task, exact assertion names known
- source_ref_pattern correction: HIGH — topology confirmed via release-please-config.json and MAINTAINING.md
- Replacement wording: MEDIUM — direction is clear from decisions, exact phrasing is planner discretion

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (docs phase; content stable)
