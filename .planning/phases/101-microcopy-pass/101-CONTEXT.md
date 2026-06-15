# Phase 101: Microcopy Pass - Context

**Gathered:** 2026-06-15 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A global "thoughtful maintainer" microcopy pass across all three settled admin
surfaces — **Operator** (`/ops/mail`), **Inbound** (`/ops/mail/inbound`), and
**Preview** (`/dev/mail`). Empty / error / loading / confirmation copy must be in
plain language that names the cause and serves each surface's JTBD, never "Oops".

Requirement: **COPY-01**. This is an adopter-visible-quality pass under the D-23
convergence rule (no new product features, routes, or capabilities). The copy
decisions are **already locked** in the Phase 96 dossier — this phase applies
residuals and makes the conformance check actually enforce them.

**In scope:** the 16 COPY-LD locked strings across the 3 surfaces, plus a
conformance/voice check that covers all 3 surfaces.
**Out of scope:** core/inbound functional code, email-template HEEx (recipient-facing),
`brandbook/` specimens, new loading-state UI, any new copy decisions not traceable
to a COPY-LD.
</domain>

<decisions>
## Implementation Decisions

### LD application state — most are already on disk
The surface phases 98/99/100 applied the bulk of the 16 COPY-LDs inline as part
of their own visible-copy work. Phase 101 is **verification + residual mop-up +
conformance enforcement**, NOT a 16-edit churn.

- **D-01:** Treat COPY-LD-01..16 as the locked spec (`.planning/research/v1.11/MICROCOPY.md`).
  Do NOT re-derive or re-word any decision — apply the locked strings verbatim.
- **D-02:** Already-applied (verify verbatim, do NOT re-touch — re-editing risks regressions):
  LD-01, LD-02 (`operator/deliveries_list.ex`), LD-03 (`inbound/records_list.ex`),
  LD-04, LD-05, LD-06, LD-08 (`preview_live.ex` — LD-05 "Preview the first Mailable"
  landed via GAP-02 in Phase 100), LD-10 ("Time window", `inbound/filters_form.ex`),
  LD-11, LD-12 (`operator/shell.ex` `copy_for/1`), LD-13 (both replay modals),
  LD-14 (`operator/suppression_card.ex`), LD-16 rendered prompt (`inbound_live.ex:385`).
- **D-03:** LD-09 (no "Oops"/"whoops"/"uh oh"/"something went wrong") is already
  satisfied in source. The work for LD-09 is the **conformance check**, not a string edit.

### Residual strings to fix (the actual edits)
The surface phases updated rendered panes but missed `put_flash`/subtitle strings:

- **D-04:** `inbound_live.ex:227` — no-selection error flash
  `"Select an inbound record … raw source"` → LD-16 wording
  (`"Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence."`).
- **D-05:** `inbound_live.ex:219` — replay-success flash
  `"…this message's timeline"` → `"…this InboundMessage's timeline"` (inbound-context noun).
- **D-06:** `inbound_live.ex:289` — subtitle `"…why a received message routed…"`
  → use the InboundMessage domain noun (LD-07/4b). Borderline (subtitle), but in
  scope for criterion 1.
- **D-07:** Before editing, planner must do a final per-surface source sweep for any
  other residual flash/toast/subtitle strings the dossier's pane-biased inventory
  may have missed (especially other `put_flash` sites in the LiveView modules).

### Conformance / voice check (success criterion 3)
- **D-08:** **Extend the conformance check to cover all three surfaces.** The existing
  `mailglass_admin/test/mailglass_admin/voice_test.exs` renders **Preview only**; the
  Phase-95 ratchet scores pixels, not copy; `test/scripts/conformance_advisory_test.exs`
  gates CSS Type tokens, not copy. So "a conformance/voice check stays green" is currently
  meaningless for 2 of 3 surfaces. Add Operator (`/ops/mail`) + Inbound (`/ops/mail/inbound`)
  coverage.
- **D-09:** The extended check asserts: (a) banned-word refutation (LD-09) on all three
  rendered surfaces; (b) a handful of canonical-string assertions (e.g. LD-01/03/11/12/14/16).
  Make it data-driven (module-attribute list of banned words + per-surface canonical strings)
  so future surfaces extend cheaply.
- **D-10:** Reuse the existing script-stripping regex (`voice_test.exs:27`) to avoid the
  documented phoenix.mjs `noops` false positive. Prefer extending `voice_test.exs` (add
  Operator/Inbound `describe` blocks on `MailglassAdmin.LiveViewCase`) over a new file.
- **D-11:** **Flash strings are not caught by static render.** `inbound_live.ex:219/227`
  only render on action — assert them via triggered LiveView events OR a source-level grep
  guard. The check must cover this class, not just first-render HTML.

### Loading states (COPY-LD-15)
- **D-12:** **NO-OP for this phase.** No surface has loading skeletons/spinners today;
  LD-15 is gated on "if explicit loading states are added." Adding loading UI is scope
  creep for a microcopy pass — deferred. (The pre-existing `operator/replay_modal.ex:90`
  resolution message may stay as-is; not required to change.)

### Claude's Discretion
- Exact test structure (describe-block layout, attribute names) and whether flash
  assertions use triggered events vs. a grep guard — planner/executor choice, as long
  as D-08..D-11 hold.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.11/MICROCOPY.md` — **THE SPEC.** 16 LOCKED DECISIONS
  (COPY-LD-01..16): exact strings, file:line targets, constraint bindings. The
  LOCKED DECISION table (lines 484–504) is the authoritative read.
- `.planning/research/v1.11/SUMMARY.md` — dossier synthesis; COPY-LD cross-references.
- `mailglass_admin/test/mailglass_admin/voice_test.exs` — existing preview-only voice
  check to extend (note the script-strip regex at line 27).
- `test/scripts/conformance_advisory_test.exs` — CSS Type/tracking conformance (NOT copy;
  context for what the ratchet does/doesn't cover).
- `.planning/RATCHET-GAP-REGISTER.md` — GAP status: GAP-02 fixed (LD-05 done),
  GAP-04 inbound filter labels (LD-10 copy done; rendering token side), GAP-07.
- `brandbook/brand-book.md` (Voice section, lines 44–75) — thoughtful-maintainer voice
  source of truth; "say this not that" pairs; seven domain nouns.
- `CLAUDE.md` — "Brand & Voice" + "Domain Language" (banned standalone terms, error exemplar).
- `guides/jobs.md` — per-surface JTBD map.
- Prior phase contexts: `.planning/phases/98-operator-deliveries-surface/98-CONTEXT.md`,
  `99-inbound-surface/99-CONTEXT.md`, `100-preview-surface/100-CONTEXT.md` (what each
  surface phase already touched).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`operator/shell.ex` `copy_for/1`** — orientation-strip tips centralized in one helper
  with three clauses (`:deliveries` lines ~335–344, `:inbound` ~346–355, `:preview` ~357–366),
  each returning `%{heading:, tips: [...]}`, shared across all 3 surfaces. LD-11/12 already
  applied here — single edit site if any tip needs touching.
- **`MailglassAdmin.LiveViewCase`** — test case used by `voice_test.exs`; mounts surfaces
  under the same router. `inbound_live_test.exs` is a precedent for rendering Inbound.
- **Script-strip regex** (`voice_test.exs:27`) — reuse to skip inlined phoenix.mjs `noops`.

### Established Patterns
- Copy lives in three distinct site classes:
  (a) **rendered-pane copy** in component modules (`deliveries_list.ex`, `records_list.ex`,
      `suppression_card.ex`, `replay_modal.ex`, `preview_live.ex`) — already LD-conformant;
  (b) **flash/toast strings** built via `put_flash` in LiveView modules
      (`inbound_live.ex:219,227,236,504-515`) — where the residual violations live;
  (c) **subtitles/static headers** (`inbound_live.ex:289`).
  The surface phases consistently updated (a) but missed strings in (b)/(c).
- Error-heading pattern: `[Noun] [past-tense verb]: [specific cause]` (LD-07); developer
  preview surface uses technical-precision exception (LD-08, e.g. `preview_props/0 raised an error`).
- Seven domain nouns enforced in copy: Mailable, Message, Delivery, Event, InboundMessage,
  Mailbox, Suppression. Banned standalone: "Email", "Status", "Notification".

### Integration Points
- Edits land in `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (residual flashes/subtitle)
  and `mailglass_admin/test/mailglass_admin/voice_test.exs` (conformance extension).
- No core/inbound functional code; no router/route changes; no CSS bundle change expected
  (copy-only) — but if any template touched, the `git diff --exit-code priv/static/` rule
  and asset rebuild still apply per milestone hard constraints.
- PII minimization preserved: replay modal headings use `mask_recipient/1` (LD-13 scope).
</code_context>

<specifics>
## Specific Ideas

- Apply COPY-LD strings **verbatim** — they are pre-adversarially-synthesized. No
  re-wording; deviations from a locked string are bugs, not improvements.
- The single highest-value net-new work is the **3-surface conformance check** —
  it's what makes criterion 3 meaningful and prevents future regressions.
</specifics>

<deferred>
## Deferred Ideas

- **Loading-state UI + COPY-LD-15 "Loading [Noun]s…" pattern** — no loading skeletons
  exist today; adding them is scope creep for a microcopy pass. If a future phase
  introduces async/loading surfaces, LD-15 supplies the exact copy pattern.
- **GAP-04 rendering-token side / GAP-07 Type-pillar tracking** — copy side (LD-10) is
  done; the CSS-token/tracking work belongs to the design-token/Type phases, not this
  microcopy pass.
- **Nudging `operator/replay_modal.ex:90` toward LD-15 form** — optional, not required.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
