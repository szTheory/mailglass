# Phase 132: Config + `Mailglass.Identifier` foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 132-config-mailglass-identifier-foundation
**Mode:** assumptions (+ per-area research subagents at user request)
**Areas analyzed:** Config accessor caching; `Mailglass.Identifier` module shape; Inbound mirror

## Assumptions Presented

### Area 1 — Config key + accessor caching
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `:schema` NimbleOptions key (default `"mailglass"`, `"public"` opt-out) | Confident | `config.ex:4+` `@schema`; dossier §3.1 |
| `schema/0` reads `:persistent_term {Mailglass.Config, :schema}`, boot-warmed + lazy cold-miss backfill | Confident | `config.ex:544` `:theme` cache, `get_theme/0:630` |

### Area 2 — `Mailglass.Identifier` module shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| NEW `identifier.ex` holding the regex; `validate!/2`; refactor `postgres.ex` private fn to delegate | Confident | `postgres.ex:121-140`; dossier §7 |
| Preserve `Mailglass.ConfigError` shape (errors-as-contract) | Confident | `errors/config_error.ex`; CLAUDE.md DNA |

### Area 3 — Inbound mirror
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `config :mailglass_inbound, :schema`; reuse `Mailglass.Identifier`; same lazy-populate cache | Confident | inbound `config.ex:103/165`; dossier §3.7 |
| Inbound `validate_at_boot!/0` exists but is NOT wired at boot | Confident | inbound `application.ex` (no call) |

## Corrections Made

User did not accept/correct directly — instead requested deep per-area research
(pros/cons/tradeoffs, Elixir/Ecto/Oban idioms, cross-ecosystem lessons, DX, `prompts/`
research) to one-shot a coherent recommendation set. Three parallel `gsd-advisor-researcher`
agents ran (one per area). Findings REFINED the assumptions in three material ways, all
locked into CONTEXT.md:

### Area 1 — refinements
- **Original:** validate inside `schema/0`; return `"mailglass"` default on cold miss.
- **Researched decision:** validate ONCE at the cache-write boundary, never per read
  (the dossier §3.1 per-read `validate!` sketch is a regex on the hottest path →
  superseded, D-04). Cold miss uses a SENTINEL + self-heal, NOT a silent default —
  a silent default masks a `"public"` opt-out and splits writes across schemas (D-03).
  No cache invalidation; persistent_term write is boot-once (global-GC-scan hazard, D-05).
- **Reason:** correctness (avoid silent cross-schema corruption) + hot-path perf +
  `:persistent_term.put/2` GC cost.

### Area 2 — refinements
- **Original:** `validate!/2` returns the string; keep `ConfigError`.
- **Researched decision:** confirmed string return (pipeable, D-07) + keep `ConfigError`
  not a new `IdentifierError` (preserves closed error union, D-08); single bang function
  only, NO `valid?/1`/`validate/2` (YAGNI on closed API, D-09); **ADD a 63-byte
  NAMEDATALEN length guard** (Postgres silently truncates >63 bytes — aliasing hazard;
  strictly stricter, safe addition, D-10). Delegate refactor is byte-identical (D-11).
- **Reason:** API-stability discipline + closing the silent-truncation footgun.

### Area 3 — refinements
- **Original:** reuse `Mailglass.Identifier`; same lazy cache; add schema validation to
  inbound boot.
- **Researched decision:** confirmed reuse (inbound already raises `Mailglass.ConfigError`
  in its plug + all four providers → coupling already exists, D-13); cache ONLY `:schema`,
  leave `retention/0`/`rate_limit/0` uncached (D-14); **WIRE
  `validate_at_boot!/0` into inbound `application.ex` start/2** (fixes the pre-existing
  never-called gap; fail-fast + cache warm; `:schema` is inbound's own env so inbound owns
  boot, D-15).
- **Reason:** family coherence + fixing a latent gap + correct ownership boundary.

## External Research
- **`:persistent_term` for hot-path config** — zero-copy shared-heap pointer read vs
  `Application.get_env`'s ETS lookup+copy per call; `put/2` triggers a global GC scan so
  writes must be rare. Oban builds `%Oban.Config{}` once at boot, reads-many (same shape).
  (Sources: stratus3d perf note, elixirforum persistent_term-vs-constant-terms, Oban.Config docs.)
- **Postgres identifier grammar + NAMEDATALEN 63** — `\A[a-zA-Z_][a-zA-Z0-9_]*\z` matches
  the unquoted-identifier grammar; identifiers >63 bytes are silently truncated → add a
  length guard. Oban/Ecto interpolate prefix into `CREATE SCHEMA`/DDL and rely on
  identifier-shaped input; the PraisonAI GHSA-rg3h-x3jw-7jm5 fix landed the same restricted
  regex against DDL injection. (Sources: PostgreSQL §4.1 lexical, Oban.Migrations docs, PraisonAI advisory.)
- **Sibling-package config sharing** — Oban Web/Pro reuse Oban core's validators rather
  than re-implementing; validates the reuse-`Mailglass.Identifier` decision for inbound.
