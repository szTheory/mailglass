# Phase 66: Release Position Decision - Pattern Map

**Mapped:** 2026-06-01  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/66-release-position-decision/66-RELEASE-POSITION.md` | config | transform | `.planning/v1.4-MILESTONE-AUDIT.md` | role-match |
| `.planning/phases/66-release-position-decision/66-VERIFICATION.md` | test | batch | `.planning/phases/65-compatibility-docs-and-dx-lock/65-VERIFICATION.md` | exact |
| `mailglass_inbound/CHANGELOG.md` | config | transform | `mailglass_inbound/CHANGELOG.md` | exact |
| `mailglass_inbound/mix.exs` | config | request-response | `mailglass_inbound/mix.exs` | exact |
| `.release-please-manifest.json` | config | transform | `.release-please-manifest.json` | exact |
| `mailglass_inbound/README.md` | config | request-response | `mailglass_inbound/README.md` | exact |
| `.planning/publish/mailglass_inbound-publish-summary.json` | config | file-I/O | `.planning/publish/mailglass_inbound-publish-summary.json` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/release-please.yml` | exact |

## Pattern Assignments

### `.planning/phases/66-release-position-decision/66-RELEASE-POSITION.md` (config, transform)

**Analog:** `.planning/v1.4-MILESTONE-AUDIT.md`

**Frontmatter + status rubric pattern** (lines 1-11):
```yaml
---
milestone: v1.4
audited: 2026-06-01T15:29:38Z
status: gaps_found
scores:
  requirements: 10/13
---
```

**Binary decision table pattern** (lines 81-96):
```markdown
| Requirement | ... | Final status | Evidence |
| REL-01 | ... | unsatisfied | ... |
| REL-02 | ... | unsatisfied | ... |
| REL-03 | ... | partial | ... |
```

### `.planning/phases/66-release-position-decision/66-VERIFICATION.md` (test, batch)

**Analog:** `.planning/phases/65-compatibility-docs-and-dx-lock/65-VERIFICATION.md`

**Verification report header pattern** (lines 1-15):
```markdown
---
phase: 65-compatibility-docs-and-dx-lock
verified: 2026-06-01T00:48:02Z
status: passed
score: 7/7 must-haves verified
---
```

**Observable truths + evidence pattern** (lines 17-39):
```markdown
## Goal Achievement
### Observable Truths
| # | Truth | Status | Evidence |
| 1 | ... | ✓ VERIFIED | ... |
```

**Behavioral command checks pattern** (lines 74-90):
```markdown
### Behavioral Spot-Checks
| Behavior | Command | Result | Status |
| ... | `mix verify.stability_contract` | ... | ✓ PASS |
```

### `mailglass_inbound/CHANGELOG.md` (config, transform)

**Analog:** `mailglass_inbound/CHANGELOG.md`

**Keep-a-Changelog + SemVer intro pattern** (lines 1-7):
```markdown
# Changelog
All notable changes ... this project adheres to Semantic Versioning.
```

**Release section formatting pattern** (lines 8-20, 92-100):
```markdown
## [0.3.0](compare-link) (YYYY-MM-DD)
### Features
...
## [Unreleased]
... current line posture text ...
```

### `mailglass_inbound/mix.exs` (config, request-response)

**Analog:** `mailglass_inbound/mix.exs`

**Version truth pattern** (lines 4-12):
```elixir
@version "0.3.0"
...
version: @version,
```

**Publish linked-pin pattern** (lines 110-116):
```elixir
if System.get_env("MIX_PUBLISH") == "true" do
  {:mailglass, "== 1.3.0"}
else
  {:mailglass, path: "..", override: true}
end
```

### `.release-please-manifest.json` (config, transform)

**Analog:** `.release-please-manifest.json`

**Multi-package manifest truth pattern** (lines 1-5):
```json
{
  ".": "1.3.0",
  "mailglass_admin": "1.3.0",
  "mailglass_inbound": "0.3.0"
}
```

### `mailglass_inbound/README.md` (config, request-response)

**Analog:** `mailglass_inbound/README.md`

**Canonical contract-routing wording pattern** (lines 20-24):
```markdown
Use docs/api_stability.md as the canonical inventory ...
Stable surfaces require deprecation bridge or major-version change ...
```

**Install pin snippet pattern** (lines 67-76):
```elixir
{:mailglass_inbound, "~> 0.3"},
{:mailglass, "~> 1.3"},
```

### `.planning/publish/mailglass_inbound-publish-summary.json` (config, file-I/O)

**Analog:** `.planning/publish/mailglass_inbound-publish-summary.json`

**Release-proof JSON schema pattern** (lines 1-14, 114-121, 193-198):
```json
{
  "expected_file": "...",
  "files": [...],
  "linked_versions": {...},
  "mailglass_inbound_publish_pin": "== 1.3.0",
  "manifest_version": "0.3.0",
  "source_ref": "v0.3.0",
  "version": "0.3.0"
}
```

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** `.github/workflows/release-please.yml`

**Manifest-driven sync pattern** (lines 142-154, 170-184):
```bash
CORE_VERSION=$(jq -r '.["."]' .release-please-manifest.json)
...
sed -i -E "s/\{:${dep}, \"== ...\"\}/{:${dep}, \"== ${CORE_VERSION}\"}/" "$path"
INBOUND_VERSION=$(jq -r '.["mailglass_inbound"]' .release-please-manifest.json)
...
sed -i -E "s/\{:mailglass_inbound, \"~> ...\"\}/{:mailglass_inbound, \"~> ${INBOUND_MM}\"}/" mailglass_inbound/README.md
```

## Shared Patterns

### Evidence-First Verification Artifact
**Source:** `.planning/phases/65-compatibility-docs-and-dx-lock/65-VERIFICATION.md`  
**Apply to:** `66-VERIFICATION.md`, `66-RELEASE-POSITION.md`
```markdown
Use frontmatter status/score + Observable Truths + Behavioral Spot-Checks tables with explicit command evidence.
```

### Version Truth Triad
**Source:** `mailglass_inbound/mix.exs` (lines 4-12), `.release-please-manifest.json` (lines 1-5), `.planning/publish/mailglass_inbound-publish-summary.json` (lines 114-121, 193-198)  
**Apply to:** inbound version bump/release-position execution files
```text
Keep package @version, manifest_version, and publish-summary version/source_ref aligned.
```

### Release Automation Sync
**Source:** `.github/workflows/release-please.yml` (lines 142-154, 170-184, 200-213)  
**Apply to:** version/pin/README updates during Phase 66 execution
```bash
Read manifest versions with jq, update dep pins + README pins, then commit synced release-please branch changes.
```

## No Analog Found

None. For governance artifacts (release-position decision), nearest planning/audit artifact patterns are mapped and should be reused.

## Metadata

**Analog search scope:** `.planning/phases/`, `.planning/`, `mailglass_inbound/`, repo root release files, `.github/workflows/`, `lib/mix/tasks/`  
**Files scanned:** 11  
**Pattern extraction date:** 2026-06-01
