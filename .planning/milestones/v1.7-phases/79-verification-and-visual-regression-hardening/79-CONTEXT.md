# Phase 79: Verification and Visual-Regression Hardening - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Closeout + release-ceremony-acknowledgment phase for the v1.7 "Admin UI — IA &
Design-System Polish v2" milestone. Phase 79 **validates** the complete system built
in Phases 74–78 against the Phase 74 gap register and proves the milestone is
release-ready. It records evidence and disposition; it is **not** a build phase and
must not introduce new product/observability features.

**In scope:** full `ui-audit.sh` matrix re-run + before/after comparison; gap-register
sev-4/5 closeout record; e2e extension for the new IA surfaces + fixing the
pre-existing replay-flow e2e failure; conformance + bundle gate verification;
GAP-22 deep-link final disposition; release-ceremony preparation (CHANGELOG +
matched version readiness).

**Out of scope:** changing any stable seam (router macro, Auth behaviour, replay
semantics, operator session contract, **asset-serving seam** — so no deep-link code
fix); new deps; brand-book amendment; bumping `reference/host_app` or
`reference/demo_app` mailglass pins; CI-promoted visual regression; manually running
`mix hex.publish` or hand-merging the Release Please PR.

**Requirements:** VERIF-01, VERIF-02, VERIF-03, VERIF-04.
</domain>

<decisions>
## Implementation Decisions

### Audit-Matrix Re-Run + Comparison (VERIF-01)
- **D-01:** Re-run `mailglass_admin/scripts/ui-audit.sh` to regenerate the 18-cell PNG
  matrix (3 surfaces × 3 viewports 390/768/1440 × light/dark), then compare
  before/after **manually or via local LLM-critique** against the `design-system.md`
  6-pillar rubric and the Phase 74 baseline. **No automated pixel-diff, no committed
  PNGs (gitignored under `tmp/ui-audit/` per D-06), no CI promotion (D-07).** The
  durable artifact is a textual before/after finding citing GAP rows, not binaries.
- **D-02:** VERIF-03's "screenshot→LLM-critique loop documented as a repeatable local
  ritual" is satisfied by expanding the existing runbook prose in
  `mailglass_admin/docs/design-system.md` (audit loop section ~lines 123–139). No new
  tooling — the `agent-browser` CLI is unversioned and stays local/ad-hoc.

### Gap-Register Sev-4/5 Closeout (VERIF-01)
- **D-03:** The open severity set at Phase 74 baseline is **five sev-4 rows, zero
  sev-5**: **GAP-01, GAP-03, GAP-05, GAP-06** (badge-class consolidation, resolved in
  Phase 76-02) and **GAP-13** (support-card flat-grid → Tier1/Tier2 hierarchy,
  resolved Phase 76-03 + seeds made reachable in 78-01). Phase 79 **re-walks each
  sev≥4 row against its resolving commit** and records closure; it does not re-fix.
- **D-04:** Closure is recorded in a **separate `79-GAP-CLOSEOUT.md` artifact**, NOT
  by editing the frozen `74-GAP-REGISTER.md` in place (the register's stable-ID
  anti-churn contract makes it read-only evidence). The closeout aggregates the
  per-phase SUMMARY "Gap Register Coverage" tables (e.g. 75-03-SUMMARY.md:193-197)
  into one register with resolved-by-commit evidence per row, mirroring the Phase 73
  RELEASE-RECORD separate-artifact precedent.

### e2e Extension (VERIF-02)
- **D-05:** Add **structural** Playwright coverage (not pixel-based) for the new IA
  surfaces currently untested in `operator.spec.js`: the **Operator Overview** landing
  (health-count cards `operator-overview-health` + nav CTAs `operator-overview-nav`),
  and **inbound + preview orientation strips / new IA testids** (only the deliveries
  orientation strip is asserted today, at ~line 101). e2e suite must end green.
- **D-06:** **Fix** the pre-existing "exact replay flow" e2e failure
  (`operator.spec.js` ~lines 104–131; tracked todo `preexisting-replay-flow-e2e-failure.md`,
  `resolves_phase: 79`) — do not document-and-skip. Leading hypothesis: positional
  `nth`-index selection (`deliveryRow(page, 3)`) drifted after Phase 78 expanded seeds
  (16 deliveries / 35 events); prefer anchoring the selection to a stable seed
  attribute over a hardcoded index. The only sanctioned permanent e2e exclusion is the
  `voice_test` "Oops" dep-JS noise — this replay failure is not on that list.

### Conformance + Bundle Gates (VERIF-03)
- **D-07:** Promote the five inline conformance greps from Phase 76-06 into a
  **committed `mailglass_admin/scripts/check-conformance.sh`** (sibling to
  `scripts/check_motion_conformance.sh`): `defp badge_class` (zero — proves "exactly
  one status→color definition"), `text-(sm|base|xs)`, `font-(medium|semibold)`,
  `gap-(3|4|6)`, hex colors — all over `mailglass_admin/lib/ --include="*.ex"`.
  Encode the `text-base-content` DaisyUI false-positive exclusion (Footgun-6). Run it
  plus the bundle-clean gate `git diff --exit-code mailglass_admin/priv/static/`.
  Validate by running, not by grep-proof (per `feedback_validate_credo_by_running_it`).

### Deep-Link GAP-22 Final Disposition (VERIF-04)
- **D-08:** **Re-confirm the Phase 75 D-17 deferral as the permanent v1.7 disposition
  — defer, do NOT fix.** A robust fix touches the stable asset-serving seam (relative
  `css-<md5>` URL resolving against the deep path on hard refresh), which is locked out
  of v1.7 churn scope. Bug manifests only on hard-refresh of a deep URL; stable under
  normal live navigation. Record the rationale in `79-GAP-CLOSEOUT.md`, hold GAP-22 at
  severity 3 so it does not block the zero-open-sev-4/5 closeout criterion. This is a
  decision/documentation deliverable, not code.

### Release Ceremony (VERIF-04 / SC-5)
- **D-09:** **Prepare/acknowledge only — Phase 79 does NOT manually cut or publish.**
  Deliverable is conventional-commit history + CHANGELOG readiness so the fully
  hands-free Release Please pipeline auto-opens its PR, auto-merges on green, and the
  publish fan-out publishes to Hex once v1.7 work lands on main. No manual
  `mix hex.publish`, no hand-merge of the Release Please PR, no Phase-73-style live
  RELEASE-RECORD with post-publish smoke (that was an inbound-only special case).
- **D-10:** **Target version: 1.5.0 minor.** The linked `mailglass` + `mailglass_admin`
  group bumps 1.4.5 → **1.5.0** (adopter-visible quality investment = minor per D-24).
  `mailglass`'s bump is administrative (no API change). `mailglass_inbound` is **not**
  in the linked-versions group — it takes a **separate exact-pin patch bump
  (1.1.5 → 1.1.6)** via its independent `{:mailglass, "== <version>"}` pin update
  (the inbound exact-pin must be manually re-pinned to the new core version each cut;
  see `project_release_engineering_gotchas` / `project_reference_baseline_coupling`).
- **D-11:** Core and inbound CHANGELOG entries are **administrative version-bump
  entries only** (no behavioral changes) — this is expected and correct per D-01
  linked-version mechanics, not a surprise.

### Folded Todos
- **D-12:** `preexisting-replay-flow-e2e-failure.md` (severity medium, `resolves_phase: 79`)
  is folded into Phase 79 scope and addressed by D-06.

### Claude's Discretion
- Exact `79-GAP-CLOSEOUT.md` schema, the conformance-script flag layout, and the precise
  e2e selector-anchoring approach are left to the planner/executor — the decisions above
  fix intent and constraints, not file-level mechanics.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — the frozen,
  read-only anti-churn register. Sev-4 rows GAP-01/03/05/06 (lines 117/119/121/122),
  GAP-13 (line 155), GAP-22 deferral (line 185), severity rubric (lines 52–62). Phase 79
  closes against it but must NOT edit it.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — frozen design
  contract (status-badge taxonomy, support-card hierarchy, motion matrix, state inventory).
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — baseline
  e2e heading / seed-count assertions the closeout must reconcile against.
- `.planning/REQUIREMENTS.md` — VERIF-01..VERIF-04 acceptance criteria (lines 45–48).
- `mailglass_admin/scripts/ui-audit.sh` — the 18-cell matrix runner; gitignore + no-CI
  contract (D-06/D-07 in its header).
- `mailglass_admin/docs/design-system.md` — 6 conformance pillars (lines 104–121), audit
  loop ritual (123–139), GAP-22 Known Limitations / disposition (~141–159).
- `mailglass_admin/e2e/operator.spec.js` — current e2e coverage; Overview gap; replay-flow
  index fragility (~lines 104–131).
- `.planning/phases/76-component-library-and-design-system-hardening/76-06-SUMMARY.md` —
  the five inline conformance gates (lines 70–77) to promote into a committed script.
- `.planning/phases/73-inbound-1-0-publish-evidence/73-01-RELEASE-RECORD.md` — release-record
  artifact precedent (Phase 79 does NOT replicate the live-cut version; prepare-only).
- `release-please-config.json` (linked group = `["mailglass","mailglass_admin"]`, inbound
  excluded) + `.release-please-manifest.json` (current 1.4.5/1.4.5/1.1.5).
- `.planning/todos/pending/preexisting-replay-flow-e2e-failure.md` — folded into scope (D-12).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_admin/scripts/ui-audit.sh` — existing 18-cell matrix runner; re-run as-is.
- `scripts/check_motion_conformance.sh` — precedent + sibling location for the new
  `mailglass_admin/scripts/check-conformance.sh`.
- `mailglass_admin/e2e/operator.spec.js` — extend in place; add Overview + orientation
  structural tests; fix replay-flow selector.
- Per-phase SUMMARY "Gap Register Coverage" tables (75-03, 76-02, 76-03, 77, 78) — source
  evidence to aggregate into `79-GAP-CLOSEOUT.md`.
- `mailglass_admin/mix.exs` `verify.preview` alias — existing structural verify entry point.

### Established Patterns
- Frozen-artifact + separate-closeout pattern (74 register is read-only; record status in a
  new file) mirrors the Phase 73 RELEASE-RECORD-vs-CHECKLIST split.
- Conformance checks become committed shell scripts (`check_motion_conformance.sh`), run
  rather than grep-proven.
- Fully hands-free Release Please pipeline (auto-PR, auto-merge on green, no-gate publish);
  linked-versions plugin matches mailglass+admin, inbound pinned separately.

### Integration Points
- `git diff --exit-code mailglass_admin/priv/static/` bundle-clean gate (D-08, GAP-19
  precedent in Phase 77).
- Inbound exact-pin (`mailglass_inbound/mix.exs` `{:mailglass, "== 1.4.5"}`) must be
  manually re-pinned to 1.5.0 when the core bump lands — known release-engineering gotcha.
- `reference/demo_app` re-bumps swoosh lock on any mix run; baseline pins are frozen and
  out of scope (do not touch).
</code_context>

<specifics>
## Specific Ideas

- Replay-flow e2e fix should anchor delivery selection to a stable seed attribute rather
  than a positional `nth`-index, to be resilient against future seed-count changes.
- The before/after audit finding should explicitly cite the GAP rows it demonstrates as
  improved (traceability back to the register).
</specifics>

<deferred>
## Deferred Ideas

- **Robust deep-link asset-serving fix** — permanently deferred for v1.7 per D-08 (touches
  the stable asset-serving seam). Candidate for a future milestone if adopter pull emerges.
- **CI-promoted visual regression / automated pixel-diff harness** — out of scope by
  locked decision (non-deterministic pixels, unversioned `agent-browser`); stays local/ad-hoc.
- **Active live-cut release ceremony (Phase-73 style with post-publish smoke)** — not this
  phase; the hands-free pipeline owns publish (D-09).

### Reviewed Todos (not folded)
- None beyond the folded replay-flow item (the only phase-79 match).
</deferred>
