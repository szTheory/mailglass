# Phase 49: Inbound Runtime Operator Tooling - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 49-inbound-runtime-operator-tooling
**Mode:** assumptions + per-area advisor research (decisive-by-default methodology)
**Areas analyzed:** Config surface · Mix tasks (doctor/replay/prune) · Ingress rate limiter · Suppression flag-only + InboundMessage contract · Prune/retention

## Process

1. `gsd-assumptions-analyzer` deep-read the codebase and surfaced 3 assumption areas + 2 minor research flags.
2. Two research flags resolved locally (read `Mailglass.OptionalDeps.GenSmtp` for MIME-03 reporting; Oban-cron idiom from `Webhook.Pruner`).
3. User directed full research-driven treatment → **five parallel `gsd-advisor-researcher` agents**, one per gray area,
   pressure-testing each default against Elixir/Plug/Ecto/Phoenix idioms, cross-ecosystem lessons, DX, and the `prompts/` research.
4. One escalation attempted (the public `%InboundMessage{}` struct field shape). User declined to be asked → directed a
   **sixth deep-research agent** to one-shot it. Result overturned the initial lean (see Corrections).
5. All decisions locked from synthesis; no further user questions.

## Assumptions Presented (post-research, all locked)

### Config surface
| Assumption | Confidence | Evidence |
|---|---|---|
| `:mailglass_inbound` app env via validated `MailglassInbound.Config` (NOT core `Mailglass.Config`) | Confident | `config.ex` is `:mailglass`-scoped; `plug.ex:346-401` reads `:mailglass_inbound`; ActionMailbox precedent |

### Mix tasks
| Assumption | Confidence | Evidence |
|---|---|---|
| Thin tasks in `mailglass_inbound/lib/mix/tasks/` → `Internal.{Doctor,Prune}` + `Operator.Formatter` | Confident | `mail.doctor.ex`, `deliverability/formatter.ex`, boundary law |
| Doctor 3-state exit (0/1/2) + `--format json` + `--strict` | Confident | Credo exit-status model; clig.dev |
| Route-conflict via `Router.Matcher.matches_route?/2` reuse; regex-vs-regex = warn | Confident | `matcher.ex` single-source-of-truth; undecidability |
| `:source` field on `Route` via `__CALLER__` for actionable reports | Confident | `router.ex:49` macro; Rails `routes --unused` |
| Replay stays single-record; CLI iterates; `[y/N]`+`--yes`+`--dry-run` | Confident | `internal/replay.ex` arity; `Mix.shell().yes?/1` |

### Rate limiter
| Assumption | Confidence | Evidence |
|---|---|---|
| Inbound-local ETS leaky-bucket; NOT reuse core; no Hammer | Confident | `rate_limiter.ex` Message-bound + `:transactional` + core-only supervisor |
| Post-verify/post-tenant/pre-persist; 429+Retry-After tuple, never raise | Confident | `plug.ex` `{resp, meta}` idiom; DoS-amplifier avoidance |
| `Retry-After` only (no `X-RateLimit-*`) | Confident | provider-poster consumer; IETF draft not an RFC |
| Recipient full-addr in ETS key (internal-only); telemetry carries bucket type | Confident | `rate_limiter.ex:43` PII rule scoping |
| Dedicated `[:mailglass_inbound, :rate_limit, :stop]` + whitelist extension | Confident | IOPS-04 mandates the event |

### Suppression flag-only
| Assumption | Confidence | Evidence |
|---|---|---|
| Compute in `Persist` via core `SuppressionStore.check/2`, no `:stream`, degrade-open | Confident | `suppression_store/ecto.ex` tenant-scope + nil-stream clause |
| New `suppression_flagged` column (NOT NULL default false); admin reads column | Confident | append-only tables; IADM-02 read-model |
| No auto-bounce / no auto-suppression | Confident | backscatter consensus; ActionMailbox; domain-language doc |

### Prune/retention
| Assumption | Confidence | Evidence |
|---|---|---|
| Shared-table source-split (4 windows / 3 tables); read source via `ExecutionRun` | Confident | both schemas map `mailglass_inbound_replay_runs`; `source` Enum |
| Keep `on_delete: :nothing` + explicit child-first batched deletes (NOT cascade) | Confident | FK migration; cascade un-batches + can't express independent windows |
| Batched `DELETE ... LIMIT 1000 FOR UPDATE SKIP LOCKED` + `pg_try_advisory_lock`; no VACUUM | Confident | Sequin/Oban retention idiom |
| `prune/0` Oban-independent; worker shipped+documented+unregistered; mix runs sync w/o Oban | Confident | `Webhook.Pruner` structure; honest improvement over exit-1 |
| Evidence 30d (ActionMailbox parity); `:infinity` disables; GDPR note | Confident | `incinerate_after` default; `pruner.ex:91` |

## Corrections Made

### Suppression surface signal — the one researched-not-asked decision
- **Original assumption (analyzer + first suppression agent):** add a free system-owned `:metadata` map to
  `%InboundMessage{}`; surface `metadata.suppression_flagged`.
- **Correction (sixth deep-research agent, decisive):** use a typed framework-owned nested struct
  `%MailglassInbound.InboundMessage.Signals{}` on a new `:signals` field; surface `signals.suppression_flagged`.
- **Reason:** mailglass already uses `:metadata` for **adopter-owned** application data on outbound `Mailglass.Message`
  (+ `put_metadata/3`) and the domain-language doc defines Metadata = application-defined. Reusing the name for
  *framework-derived* facts inverts its meaning across the framework. The typed nested struct is the
  `Ecto.Schema.Metadata`/`__meta__` archetype — non-nil/defaulted (no nil-vs-missing-key ambiguity for old records),
  dialyzer-checkable, pattern-matchable, extensible additively. This overrides IOPS-05's literal
  `.metadata.suppression_flagged` wording as a documented improvement (SESI-04-erratum precedent).

No other corrections — all other assumptions confirmed by research.

## External Research (highlights)

- Config namespacing: Elixir library guidelines + Michał Muskała + Rails ActionMailbox → sibling package owns its app key.
- Doctor UX: Credo 3-tier exit statuses; clig.dev confirmation/dry-run/`--yes` tiers; flutter/brew "doctor" loved-traits.
- Rate limiting: Hammer/PlugAttack landscape (deliberately not adopted); leaky-bucket over fixed-window; Rack::Attack
  per-throttle `Retry-After`; IETF RateLimit draft (not an RFC) → `Retry-After` only.
- Struct contract: Ecto.Schema.Metadata, Broadway.Message, Plug.Conn/Swoosh `:private`/`:assigns`; Django `META`/Rack
  `env` grab-bag footgun; ActionMailbox dropping SPF/DKIM facts for lack of a typed home.
- Retention: Postgres batched `FOR UPDATE SKIP LOCKED` + advisory locks; ActionMailbox `incinerate_after` 30d;
  cascade-un-batches footgun.
