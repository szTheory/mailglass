# Phase 93: HexDocs Wiring and Release Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-13
**Phase:** 93-hexdocs-wiring-and-release-hardening
**Mode:** assumptions
**Areas analyzed:** HexDocs logo/favicon wiring, Release-safety & verification, RELH-01 hardening mechanism, RELH-02 aftermath reconciliation

## Assumptions Presented

### Area A — Logo/favicon asset wiring (HEXD-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `logo-mark.svg` as `logo:`, `favicon.svg` as `favicon:` on all three packages | Confident | ADOPTION-MECHANICS §1; asset inventory; 48×48 legibility |
| Add width/height directly to canonical SVGs (164×156, 16×16), no ex_doc copies | Confident | Existing `<img>`/`<link rel=icon>` embeds override/ignore intrinsic size; brand-audit no-copies rule |
| Relative paths into canonical brandbook, no `:files` change | Confident | ex_doc auto-copies into doc output; ADOPTION-MECHANICS §1 |

### Area B — Release-safety & verification (HEXD-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| mix.exs edits land as `docs:`; no release cut; logo rides next release | Confident | release-please defaults; v1.10 scope lock; locked HexDocs-latency decision |
| Wire against locked ex_doc 0.40.1; ignore pending 0.40.3 (#77) | Likely | semantics unchanged 0.40.1→0.40.3; dependabot PR is orthogonal |
| Verify via local `mix docs` ×3 (logo+favicon present, no new warnings) | Confident | HEXD-02 success criterion |

### Area C — RELH-01 hardening mechanism
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| CI commit-type lint guarding brandbook/.planning/prompts paths | Likely | release-please root `"."` has no clean per-path exclusion; lint reliably enforceable |

### Area D — RELH-02 aftermath reconciliation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Investigate Hex live before reconciling; version truth contradictory | Unclear | in-repo 1.6.1/1.6.1/1.3.0 (manifest+mix.exs+pin) vs memory 1.6.2/1.6.2/1.3.1; no local 1.6.x package tags; no open release PR |

## Corrections Made

No corrections — both judgment calls confirmed at the recommended option:

### RELH-01 mechanism
- **Assumed:** CI commit-type lint (over config path-exclusion).
- **User chose:** CI commit-type lint (recommended). Confirmed.

### RELH-02 disposition
- **Assumed:** Investigate Hex live, then reconcile; record blocker if train unsettled.
- **User chose:** Investigate Hex live, then reconcile (recommended). Confirmed.

All other (Confident/Likely) assumptions were presented and accepted as-is.

## External Research

None performed in this session — `ADOPTION-MECHANICS.md` (2026-06-12) already
pre-settled the ex_doc and release-please mechanics at HIGH confidence; live
codebase verification (SVG attrs, docs configs, manifest, tags, open PRs)
supplied the rest. The researcher should confirm one open item flagged in
CONTEXT D-10: whether release-please offers a clean config-level path exclusion
for the root `"."` package (CI lint is committed regardless).
