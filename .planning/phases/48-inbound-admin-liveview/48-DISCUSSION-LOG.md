# Phase 48: Inbound Admin LiveView - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 48-inbound-admin-liveview
**Mode:** assumptions
**Areas analyzed:** Cross-package dependency strategy; Inbound read-model location + tenancy; Routing-trace reflection API; Replay + capability gates; PubSub consumer + nav mounting + component clones

## Assumptions Presented

### Cross-package dependency strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Optional, runtime-gated dep `{:mailglass_inbound, "~> 0.2", optional: true}` (floating, not `==`; kept out of release-please PINS) | Confident | `release-please-config.json`/`.release-please-manifest.json` (inbound excluded, 0.x); `release-please.yml:145-164` sed keyed on literal `mailglass` + `== X.Y.Z`; `mailglass_admin/mix.exs:100-135` |
| Do NOT add `MailglassInbound` to Boundary `deps:`; gate via runtime `apply/3` + `OptionalDeps.MailglassInbound` + `@compile no_warn_undefined` | Confident (research-upgraded) | `deps/boundary/lib/boundary/checker.ex:24-61` `unknown_dep` on absent app; `lib/mailglass.ex:55-60` Oban precedent; `optional_deps/phoenix_live_reload.ex` |
| Entire inbound admin surface gated behind `available?/0` | Confident | `optional_deps/phoenix_live_reload.ex` whole-feature gating precedent |

### Inbound read-model location + tenancy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Read-model in `mailglass_inbound` as `@moduledoc false` `Internal.Operator.*`, via `Repo` + `Tenancy.scope/2`, tenant-required-or-empty | Likely | outbound precedent `lib/mailglass/operator/deliveries.ex:18-50`; inbound has zero `Tenancy.scope` today; `Internal.Replay` `@moduledoc false` posture; `repo.ex` facade |
| Admin tenant-gates the record BEFORE calling un-scoped `Internal.Replay.replay/2` | Confident | `internal/replay.ex:30-38` loads by `id` only, no tenant filter |

### Routing-trace reflection API
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `@moduledoc false` per-clause `Matcher.explain/2` reusing existing predicates | Confident | `router/matcher.ex:31` (public bool) + `:45-48`/`:37` (defp predicates); `router/route.ex:7-14` 4-field finite struct |
| Discover routes via explicit `:inbound_router` macro option threaded like `:auth` (no global config) | Confident | routes are per-request plug opts (`persist.ex:281-287`); no `Application.get_env(:mailglass_inbound, :router)` exists (grep) |

### Replay + capability gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Replay via `Internal.Replay.replay(record_id, opts)` → `Execution.execute(source: :replay)` append-only | Confident | `internal/replay.ex:13-28`, error reasons map to UI-SPEC copy |
| `:replay_inbound` + `:reveal_raw` ride existing `Auth.authorize/3` (`atom()` action) — no new auth surface | Confident | `auth.ex:33` action type `:operator_access \| :destructive_action \| atom()` |
| Add inbound sibling `MailglassAdmin.Inbound.DestructiveAction` rather than reuse outbound verbatim | Likely | `operator/destructive_action.ex:18-22` hard-codes `:delivery`/`:replay_target` keys; adopters may match `%Delivery{}` |

### PubSub consumer + nav mounting + component clones
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 45 broadcast already landed; Phase 48 adds only consumer-side `inbound_record_inserted/1` builder + subscribe; new records prepend, don't steal selection | Confident | `ingress/plug.ex` post-commit broadcast on `Mailglass.PubSub`; `mailglass_inbound/.../pub_sub/topics.ex:33-34` |
| `/admin/inbound` in existing operator `live_session` (Auth gate), not dev-preview; nav link added; gated by `available?/0` | Confident | `router.ex` `mailglass_operator_routes/2` + `Operator.Mount`; dev-preview session bypasses Auth |
| Clone operator components as `Inbound.*` siblings; promote `mask_recipient/1` to public `Components` helper | Likely | `deliveries_list.ex:98-100` private `mask_recipient/1`; UI-SPEC "sibling, not refactor"; PII-discipline = one audited definition |

## Corrections Made

No corrections — the user confirmed all five areas with "Yes, proceed."

## External Research

Spawned a research agent to resolve the two codebase-insufficient gaps the analyzer flagged. Both returned High confidence:

- **release-please rewrite of the new optional inbound dep:** the publish-time sed pin (`release-please.yml:145-164`) iterates a `PINS` array containing only `mailglass` and matches the exact tuple `{:mailglass, "== X.Y.Z"}`. A `{:mailglass_inbound, "~> 0.2", optional: true}` entry is structurally invisible (different atom, `~>` not `==`). Safe to add as a plain floating dep; keep out of `PINS`. (Source: repo `.github/workflows/release-please.yml`, `mailglass_admin/mix.exs`.)
- **Boundary handling of an absent optional cross-package dep:** listing `MailglassInbound` in Boundary `deps:` when the app is absent (no-optional-deps lane) returns `nil` from `Boundary.get/2` and emits an `unknown_dep` error, breaking `mix compile --no-optional-deps --warnings-as-errors`. Boundary has no per-dep "may be absent" option. **Recommended idiom:** leave `deps: [Mailglass], exports: [Router]` unchanged and route all `MailglassInbound.*` access through runtime `Code.ensure_loaded?` + `apply/3` + `@compile {:no_warn_undefined, ...}`, matching the in-repo Oban + phoenix_live_reload precedents. (Source: vendored `deps/boundary/lib/boundary/checker.ex:24-61`, `mix/view.ex:69-188`; hexdocs boundary 0.10.4.)

> Note: this research **overturned** the analyzer's initial "extend Boundary `deps:`" assumption — the final CONTEXT D-48-02 reflects the corrected runtime-gated idiom.
