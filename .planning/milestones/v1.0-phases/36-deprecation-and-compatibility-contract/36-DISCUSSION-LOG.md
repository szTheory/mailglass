# Phase 36: Deprecation and Compatibility Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or
> execution agents. Decisions are captured in `36-CONTEXT.md`.

**Date:** 2026-05-05
**Phase:** 36-deprecation-and-compatibility-contract
**Mode:** research synthesis
**Areas analyzed:** canonical docs, support matrix, upgrade path,
deprecation policy, warnings-as-errors DX

## Recommendations Presented

### Canonical compatibility docs
| Recommendation | Confidence | Evidence |
|---|---|---|
| Publish one canonical compatibility guide separate from `api_stability` inventories. | Confident | `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, ExDoc extras in `mix.exs`, `mailglass_admin/mix.exs` |
| Point README/admin README/MAINTAINING to that guide instead of carrying partially independent policy text. | Confident | `README.md`, `mailglass_admin/README.md`, `MAINTAINING.md`, `mailglass.docs.check` |

### Support matrix posture
| Recommendation | Confidence | Evidence |
|---|---|---|
| Keep the support matrix narrow and semantic, aligned to current package metadata and tested lanes. | Confident | `mix.exs`, `mailglass_admin/mix.exs`, `.github/workflows/ci.yml`, `.planning/PROJECT.md` |
| Treat `mailglass_admin` as a matched sibling and keep `mailglass_inbound` out of the `v1.x` promise. | Confident | `mailglass_admin/mix.exs`, `README.md`, `.planning/PROJECT.md` |
| Document optional deps as supported integration lanes when present, while the core contract remains green without them. | Confident | `mix.exs`, `scripts/verify_support_contract.sh`, `MAINTAINING.md` |

### Upgrade path and compatibility lane
| Recommendation | Confidence | Evidence |
|---|---|---|
| Publish one canonical `latest 0.x -> 1.0` guide and subordinate existing transitional guides under it. | Confident | `guides/upgrading-from-v0_1.md`, `guides/migration-from-swoosh.md`, `.planning/ROADMAP.md` |
| Use a dual-lane contract: stable lane for the preferred `1.x` front door, compatibility lane for a small explicit set of retained legacy bridges. | Likely | `lib/mailglass/message.ex`, `lib/mailglass/outbound.ex`, `docs/api_stability.md`, `lib/mix/tasks/mailglass.stability.check.ex` |
| Treat `Mailglass.Outbound.send/2` as legacy compatibility bridge rather than canonical front door. | Likely | `lib/mailglass/outbound.ex`, `docs/api_stability.md`, `lib/mix/tasks/mailglass.stability.check.ex` |

### Deprecation and strict-CI DX
| Recommendation | Confidence | Evidence |
|---|---|---|
| Distinguish warning-emitting deprecated APIs from silent legacy-supported aliases/paths. | Confident | `lib/mailglass/message.ex`, `mix.exs`, `mailglass_admin/mix.exs`, `MAINTAINING.md` |
| Document warning channel and `--warnings-as-errors` impact per retained path. | Confident | `.github/workflows/ci.yml`, `scripts/verify_support_contract.sh`, `MAINTAINING.md` |
| Remove nothing documented for adopters before `v2.0`, except narrow security/correctness emergencies explicitly called out. | Likely | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, Elixir compatibility/deprecations precedent |

## External Research

- **SemVer**: declare the public API first, deprecate before incompatible removal.  
  Source: `https://semver.org/`
- **Elixir**: minor/patch compatibility is the norm; compatibility exceptions
  and warnings-as-errors fallout are called out explicitly; removals happen only
  on major versions.  
  Source: `https://hexdocs.pm/elixir/1.15.5/compatibility-and-deprecations.html`
- **Rails**: support windows are explicit; breaking changes are paired with
  deprecations in earlier releases.  
  Source: `https://guides.rubyonrails.org/maintenance_policy.html`
- **Django**: keep deprecation shims across multiple feature releases before
  removal.  
  Source: `https://docs.djangoproject.com/en/4.2/internals/release-process/`
- **SQLAlchemy**: staged migration mode plus warnings made large-version
  migration tractable for strict users.  
  Source: `https://docs.sqlalchemy.org/20/changelog/migration_20.html`
- **Swoosh**: immediate ecosystem precedent for clean composable APIs and sharp
  separation of concerns.  
  Source: `https://readme.hex.pm/swoosh/1.3.1`
- **Ecto**: successful Elixir-library precedent for stable API plus narrow
  branch support posture.  
  Source: `https://github.com/elixir-ecto/ecto`

## Corrections Made

No corrections yet. The user asked for recommendation-first research synthesis
and explicitly delegated the decision-making burden.

## Shift-Left Note

Future planning for compatibility/deprecation phases should require a
deprecation-DX inventory before implementation:

- surface
- replacement
- warning channel
- `--warnings-as-errors` impact
- support-until version
- proof artifact

That recommendation was folded into `36-CONTEXT.md` as a downstream decision.
