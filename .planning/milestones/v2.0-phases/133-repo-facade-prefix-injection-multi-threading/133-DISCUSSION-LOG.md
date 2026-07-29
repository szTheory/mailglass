# Phase 133: Repo-facade prefix injection + Multi threading - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 133-repo-facade-prefix-injection-multi-threading
**Mode:** assumptions
**Areas analyzed:** multi_opts location, Multi-builder threading points, operator subquery audit,
FACADE-04 verification vs. build order, admin proof + facade-bypass audit

## Assumptions Presented

### multi_opts/1 location + facade export surface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `multi_opts/1` public in `Mailglass.Repo`; `put_prefix/1` private; no new `Persistence` module | Confident | `repo.ex` already exports `multi/2` for Outbound; `repo/0` private "to keep facade narrow"; dossier §3.3/§7 |

### Exact Multi-builder threading points
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Thread into `Events.insert_opts/1`, Outbound insert/insert_all/update + inner insert_all(Event), Escalation | Confident | `events.ex:~176`, `outbound.ex` Multi steps, `escalation.ex:~124`; executor opts don't reach inner steps (footgun 2) |

### Operator subquery audit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reads inherit facade prefix; defensive `put_query_prefix/2` on `support_summary.ex:~197` `not exists` subquery | Likely | Dossier §3.4 "likely none"; one correlated `exists` subquery found; assert under integration test |

### FACADE-04 verification vs. A→B→C build order
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Full-suite-under-mailglass needs CREATE SCHEMA + raw-DDL qualification, which is Phase 134 (C), not 133 | Likely | `test_helper.exs` migrates with no prefix + no CREATE SCHEMA; `create table(prefix:)` fails if schema absent; trigger created unqualified until Phase C |

### Admin proof + facade-bypass audit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No runtime facade-bypass in lib/ (only migration.ex, out of scope); adapt operator_live_test.exs for FACADE-03 | Confident | grep of direct host-repo usage in lib/ hit only migration.ex; SuppressionStore.Ecto uses Repo.one/insert |

## Corrections Made

No blanket corrections. One strategic fork surfaced by the analyzer was escalated to the user (the
FACADE-04 verification-vs-build-order tension), because it adjusts a stated roadmap success criterion
and sets the 133/134 phase boundary — the kind of scope call a staff engineer wants to make.

### FACADE-04 scope (strategic fork)
- **Options presented:**
  - (A) Dedicated integration test now, full CI matrix axis in 134. Preserves locked A→B→C order.
  - (B) Pull minimal CREATE SCHEMA + trigger qualification forward into 133. Satisfies criterion 4
    literally but merges part of Phase C, breaking the B/C boundary.
  - (C) Full CI matrix axis now, accept a known-red mailglass lane until 134.
- **User choice:** (A) — Dedicated integration test now, full matrix in 134.
- **Consequence captured as D-06:** Phase 133 ships facade + a dedicated schema-isolation integration
  test (own CREATE SCHEMA + prefixed migration in setup, round-trip + `mailglass.*`/`public`-clean
  assertions). Roadmap §133 success criterion (4)'s "full core suite under BOTH schemas" clause moves
  to Phase 134; update ROADMAP/REQUIREMENTS wording during planning.

## External Research

None — the LOCKED dossier (§3.2–3.4, §5, §6) + the actual code fully settle the design. The one open
Ecto question (does a query `prefix:` propagate into a same-`from` correlated `exists` subquery) is
answered in-suite by the FACADE-04 integration test, with a zero-cost defensive `put_query_prefix/2`.
