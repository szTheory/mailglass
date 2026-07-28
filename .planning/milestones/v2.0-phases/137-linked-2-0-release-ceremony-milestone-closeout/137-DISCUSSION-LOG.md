# Phase 137: Linked 2.0 release ceremony + milestone closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-03
**Phase:** 137-linked-2-0-release-ceremony-milestone-closeout
**Mode:** assumptions
**Areas analyzed:** version-trigger mechanism, sibling dep-pins, inbound version target,
reference-baseline posture, smoke readiness, milestone closeout

## Assumptions Presented

### Version-trigger mechanism (2.0.0 major)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Force major via `Release-As: 2.0.0` empty commit (linked core+admin) + separate `Release-As: 2.0.0` for inbound; not a `BREAKING CHANGE:` footer | Likely | No breaking marker in 132–136 (full-body grep); release-please-config.json has no bump-minor-pre-major/versioning override → defaults cut 1.12.0/1.12.0/1.7.0 |

### Sibling dep-pin edits
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| admin `~> 1.10` + inbound `~> 1.10 and >= 1.10.2` are manual pre-release edits to `~> 2.0`; RP sed only touches README/display pins | Confident | release-please.yml L115–120 sed scope; mailglass_admin/mix.exs L147, mailglass_inbound/mix.exs L143 |

### Inbound version target + floor
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inbound → 2.0.0 (not 1.7.0); core pin → `~> 2.0`, drop `>= 1.10.2` floor, keep `~>` (no `==`) | Confident | Phase 135 feat(135-01/02): loose migrations → dispatcher, default schema moved (semver-major); v1.15 keystone loosened off `==`; dossier §3.7/§3.9/Phase F `==` language is stale |

### Reference baseline
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `~> 1.0` → `~> 2.0` is a real mix.exs+lock edit (major crosses tilde); clean-baseline guard is version-agnostic so no script edit | Confident | reference/host_app/mix.exs L35–37; check_clean_baseline_hex_only.sh version-agnostic |
| (Originally assumed) Route A: pin `:schema, "public"` to stay frozen-deterministic | Likely | host_app has no `:schema` config; frozen-baseline logic favors public — **CORRECTED by user, see below** |

### Smoke readiness
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| post-publish-smoke 2.0-ready (checkout fix 67f4b33d, `~>`-aware compat); consumer smoke `== 2.0.0` pins self-consistent; no script edit | Confident | post-publish-smoke.yml L180–181 checkout, L363 `(==|~>|>=)` grep; consumer_install_smoke.sh |

### Milestone closeout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| audit → complete → cleanup; manually correct MILESTONES.md/STATE.md to true 132–137 span (gsd-sdk over-counts); RP auto-tags | Confident | prior milestone closeouts (v1.15/v1.14/v1.13); milestone.complete count-inflation memory |

## Corrections Made

### Reference baseline schema posture
- **Original assumption:** Route A — pin `config :mailglass, :schema, "public"` in
  reference/host_app to keep the baseline byte-for-byte deterministic.
- **User correction:** Adopt the new `mailglass` default schema in the reference baseline —
  dogfood the real 2.0 behavior an adopter gets (tables land in `mailglass.*`).
- **Reason:** More representative of a real install; the frozen baseline should prove the
  shipped default, not the opt-out. Consequence recorded in D-07: planner must verify/update
  the trust-journey checkpoint contract for the schema-qualified shape.

### Version-trigger hedging
- **Original options presented:** (a) rehearse via RP dry-run PR before merge; (b)
  belt-and-suspenders — also pre-edit `.release-please-manifest.json`.
- **User choice:** (a) Rehearse via RP dry-run PR first — inspect the release PR and confirm
  2.0.0/2.0.0/2.0.0 targets BEFORE merge. Manifest pre-edit kept as documented fallback only.

## External Research

None performed — all questions resolved from internal pipeline mechanics.
