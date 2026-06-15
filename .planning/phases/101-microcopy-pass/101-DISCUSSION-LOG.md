# Phase 101: Microcopy Pass - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-15
**Phase:** 101-microcopy-pass
**Mode:** assumptions
**Areas analyzed:** LD application state, Conformance check scope, Edit-site structure, Loading-state scope

## Assumptions Presented

### LD application state (per-LD ledger)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 12 of 16 COPY-LDs already applied verbatim on disk (LD-01..06, 08, 10..14, 16-rendered); phase is verify + residual mop-up, not 16 edits | Confident | `MICROCOPY.md` LDs vs on-disk: `deliveries_list.ex:24-31`, `records_list.ex:93-101`, `preview_live.ex:358-408`, `filters_form.ex:67`, `shell.ex:339-350`, `suppression_card.ex:14-60`, both replay_modals; `99/100-CONTEXT.md` claim LD-03/04/05/06/10/16 |
| Residuals: `inbound_live.ex:227` (LD-16 flash), `:219` ("this message's"→InboundMessage), `:289` ("received message" subtitle) | Confident | grep at cited file:line; surface phases updated rendered panes not all `put_flash` strings |
| LD-09 (no "Oops") already satisfied in source; work is the CHECK not an edit | Confident | repo-wide grep over `lib/mailglass_admin/`; dossier §3a "None confirmed in current codebase" |

### Conformance check scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Criterion 3 requires EXTENDING the voice check to Operator + Inbound surfaces; existing tests insufficient | Confident | `voice_test.exs:19-21` renders `/dev/mail` only; `conformance_advisory_test.exs:18-34` gates CSS not copy; ratchet scores PNGs |
| Extension lives in `voice_test.exs`, data-driven, reuse script-strip regex; flash strings need triggered-event or grep guard (static render won't catch them) | Confident / Likely | `voice_test.exs:14,27`; `inbound_live_test.exs` precedent; flash at `inbound_live.ex:219,227` renders only on action |

### Edit-site structure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Orientation tips centralized in `operator/shell.ex` `copy_for/1` (3 clauses), LD-11/12 already applied | Confident | `shell.ex:315,335-366` |
| Copy split across rendered-pane (done) / flash-toast (residual) / subtitle site classes | Confident | LD-16 rendered at `:385` but flash at `:227` stale |

### Loading-state scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| COPY-LD-15 is a NO-OP; no loading skeletons exist; adding them is scope creep | Likely | only `replay_modal.ex:90` loading copy; LD-15 gated "if loading states are added" (`MICROCOPY.md:502`); `99-CONTEXT.md:101` intent never implemented |

## Corrections Made

No corrections — all assumptions confirmed via "Yes, proceed".

## External Research

None performed — phase fully resolvable from the Phase 96 dossier + on-disk source.
