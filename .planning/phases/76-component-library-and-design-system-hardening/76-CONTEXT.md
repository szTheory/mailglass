# Phase 76: Component-Library and Design-System Hardening - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

The admin design system applies its own token scale and component vocabulary consistently:
**one** `Components.status_badge/1` atom replaces the divergent private `badge_class/1` copies;
support cards gain a primary/secondary triage hierarchy; the token-conformance grep returns
zero violations; the rebuilt asset bundle is committed.

This is an **admin-only internal refactor** (DOM/CSS/LiveView internals — non-stable per D-24).
It is gated by the **frozen** Phase 74 contract (`74-UI-SPEC.md` taxonomy + support-card layout;
`74-GAP-REGISTER.md` rows). The taxonomy and conflict resolutions are LOCKED — this phase
implements them, it does not relitigate them.

**In scope (DS-01..DS-04):** unified status badge + deletion of all private copies; admin-wide
token migration (type + spacing); support-card hierarchy restructure; committed bundle.

**Out of scope (anti-churn contract):** any change without a Phase 74 gap-register row at
severity ≥ 3; motion work (Phase 77); seed expansion (Phase 78); the `motion-reveal` re-fire fix
(GAP-19, Phase 77); the deep-link CSS bug (GAP-22, deferred to Phase 79 per Phase 75 D-17); any
touch to `mailglass_operator_routes/2`, `MailglassAdmin.Auth`, replay semantics, operator session
contract, or `reference/host_app|demo_app` version pins; the `mailglass_inbound` `@outcomes` schema
atoms (locked 1.0 contract).
</domain>

<decisions>
## Implementation Decisions

All decisions are grounded in codebase analysis (verified file:line) and the frozen `74-UI-SPEC.md`.
"(locked by UI-SPEC)" marks decisions the frozen spec already fixes.

### Badge Consolidation Scope (DS-01)
- **D-01:** Delete **all FIVE** live `badge_class/1` copies — not three. The ROADMAP success
  criterion and REQUIREMENTS DS-01 text say "three", but that figure predates the Phase 74 audit
  which found two **latent verbatim duplicates**. The five are:
  `operator/deliveries_list.ex:80-84` (GAP-01/02, phantom `:suppressed`),
  `operator/timeline.ex:130-135` (GAP-03, full-string structural outlier),
  `inbound/records_list.ex:97-101` (GAP-04, singular atoms),
  `operator/detail_header.ex:81-85` (GAP-05, latent dup of deliveries_list),
  `inbound/detail_header.ex:142-146` (GAP-06, latent dup of records_list).
  All call sites route through `Components.status_badge/1`. Missing a latent copy = the Pitfall-5
  silent-color-divergence failure (list view fixed, detail header still wrong).
- **D-02:** Singular→past-tense inbound normalization (`:accept`→`:accepted`, `:reject`→`:rejected`,
  `:bounce`→`:bounced`) happens in an **admin-side call-site adapter** — `record_outcome/1`
  (`records_list.ex:88`) and the equivalent read in `inbound/detail_header.ex` — **never** in
  `mailglass_inbound`. Its `@outcomes [:no_match, :accept, :ignore, :reject, :bounce, :failed]`
  (`execution_run.ex:17`, `replay_run.ex:17`) is a locked stable-1.0 schema contract. The adapter
  must preserve the existing nil-tolerance (list projection may carry no `:outcome`). (locked by
  UI-SPEC Conflict 2.)

### status_badge Component Shape (DS-01)
- **D-03:** `Components.status_badge/1` is a **sibling** to the existing `badge/1` (`:warning`/`:stub`
  Preview-sidebar atom, `components.ex:91-114`). It does NOT replace or absorb `badge/1` — that
  atom serves the Preview surface (out of GAP-01..06 scope; absorbing it would be uncited churn).
- **D-04:** **Render icon + label** (USER DECISION). This is a deliberate, recorded **amendment**
  to the frozen UI-SPEC's label-only `<span>` sketch (UI-SPEC:171,223), resolved in favor of the
  literal REQUIREMENTS DS-01 contract: "icon + label, never color alone." Consequences this phase
  must own:
  - A **per-atom Heroicon mapping** (`status_icon/1`) covering every atom in all four taxonomy
    tables (14 outbound + 6 inbound + 4 timeline). Research/planner defines the mapping as an
    **icon column extending the frozen taxonomy** (semantic: success→`hero-check-circle`-family,
    error→`hero-x-circle`/`hero-exclamation-*`, warning→`hero-exclamation-triangle`, in-flight→
    `hero-arrow-path`/`hero-paper-airplane`, neutral→`hero-question-mark-circle` — final names are
    the planner's to fix, must be consistent and on-brand).
  - Icons are **outline-style Heroicons** (brand book empty-state icon rule: outline,
    `text-secondary`/inherit) and **decorative** (`aria-hidden`, the text label carries the
    semantic — avoid screen-reader double-read).
  - **390px overflow re-check (GAP-10):** an icon widens every badge; the Phase 79 / local 390px
    review must confirm badges do not clip or overflow in compressed rows.
- **D-05:** `status_class/1`, `status_label/1`, and `status_icon/1` return **only literal complete
  strings**, one pattern-matched clause per atom — zero interpolation (Pitfall 1 / JIT; an
  interpolated `badge-#{x}` or `hero-#{x}` is tree-shaken out of the bundle and renders unstyled/
  iconless). `attr :status, :atom, values: [...]` + `attr :size, :atom, values: [:sm, :md]`,
  default `:sm` → `badge-sm`, matching house style (`components.ex:91`). The component always emits
  the base `badge` class; call sites do NOT prepend `"badge"`/`"badge badge-sm"` (locked by
  UI-SPEC Base Class Rule, standardizing the timeline divergence).

### Support-Card Restructure (DS-03)
- **D-06:** Restructure `support_cards.ex` in place (the flat `xl:grid-cols-2` at line 29) into the
  two-tier hierarchy: **Tier 1** = full `card bg-base-200 border border-base-300 rounded-box p-lg`
  containers for non-zero/actionable counts; **Tier 2** = compact `border-t border-base-300`
  horizontal row for zero-state items (`text-secondary text-label`). Consumes the **same**
  `@support_summary` map already passed from `operator_live.ex` (`failed_ingest.count`,
  `orphan_backlog.count`, `replay_outcomes.counts`, `reconcile_facts.*` from
  `SupportSummary.summarize_tenant/1`) — **no new data plumbing**. Suppression count reads from the
  separate `@suppression_count` assign (Phase 75's `count_active_suppressions/1`,
  `suppressions.ex:56`), NOT the summary map. (locked by UI-SPEC Support-Card layout.)
- **D-07:** **Restructure-first, then tokenize** (Pitfall 4 — never the reverse). Count styling
  (`text-display font-bold` + Health Count Colors semantic color: failures `text-error`, orphans
  `text-warning`, all-clear `text-success`, suppressions `text-secondary`) is applied to the FINAL
  restructured markup, reusing the Overview health-card pattern at `operator_live.ex:287-294`.

### Token Migration (DS-02)
- **D-08:** Token migration is **admin-wide HEEx**, not only the GAP-16/17-named files. Blast
  radius: ~274 `text-(sm|base|xs)` across ~22 files, ~45 `gap-3/4/6` across ~15 files. Mapping:
  `text-sm`/`text-base`→`text-body`, `text-xs`→`text-label`, `gap-3`→`gap-sm`, `gap-4`→`gap-md`,
  `gap-6`→`gap-lg`. There are already **zero** `font-medium/semibold` and **zero** `z-[` arbitrary
  values. The single hex (`#ffffff`, `preview/tabs.ex:113`) is inside an inline `style=` device-
  frame attribute (not a Tailwind class, not strictly class-gated) — convert to a CSS var for
  cleanliness. `tracking-[0.08em]` (43 occ.) is **NOT** in the Phase 76 gate list — leave it.
- **D-09:** Phase 75's Overview/orientation markup (`operator_live.ex:279-362`, `Shell.orientation_strip/1`)
  is already token-clean — **excluded** from migration (re-tokenizing it would be uncited churn).
  The remaining `text-sm/base/xs` in `operator_live.ex` live in the pre-existing Deliveries `:else`
  branch (line 363+), which IS in scope.

### Regression Test + Bundle (DS-01, DS-04)
- **D-10:** New regression test at `test/mailglass_admin/components_test.exs` (no test file exists
  for the root `Components` module yet) using `render_component(&Components.status_badge/1, ...)` and
  `assert html =~ ...` (house pattern: `inbound/components_test.exs:26`, `operator/shell_test.exs:12`).
  Assert the **exact CSS class per atom across all four taxonomy tables** — including the new atoms
  with no prior copy (`:queued`, `:opened`, `:clicked`, `:autoresponded`, `:unknown`, `:failed_ingest`)
  and, per D-04, the **per-atom icon name**. One assertion per atom (Pitfall 5).
- **D-11:** Bundle rebuild is `mix mailglass_admin.assets.build` (runs `tailwind default --minify`,
  `mailglass_admin.assets.build.ex:28`), committing `mailglass_admin/priv/static/app.css` in the
  **same PR** as every HEEx change. PR ends with `git diff --exit-code priv/static/` clean
  (CLAUDE.md "Things Not To Do" #6; Phase 79 final gate). New daisyUI classes this phase introduces
  (`badge-primary` for `:dispatched`/`:queued`/`:sent`) **and** any new `hero-*` icon names (D-04)
  must appear literally so the JIT includes them, or they render unstyled in production.

### Cross-Phase
- **D-12:** Phase 75 (COMPLETE) did **not** touch any badge call site — all 5 `badge_class/1`
  copies remain in their pre-audit divergent state (singular inbound atoms + phantom `:suppressed`
  confirmed present post-75). The UI-SPEC sequencing note ("status_badge must land before Phase 75
  finalizes Inbound orientation") is moot: Phase 75's inbound work was orientation-strip only
  (`shell.ex`), not badge rendering. Phase 76 has a clean, conflict-free consolidation surface.

### Anti-Churn Gap-Register Citations (mandatory gate)
Every build task must cite a Phase 74 gap row at severity ≥ 3:
- **DS-01 (badge):** GAP-01, GAP-02, GAP-03, GAP-04, GAP-05, GAP-06
- **DS-02 (token):** GAP-08, GAP-10, GAP-16, GAP-17 (GAP-18 sev-2, opportunistic)
- **DS-03 (support-card):** GAP-13, GAP-14 (GAP-15 sev-2, addressed by the restructure)
- **DS-04 (bundle):** the `git diff --exit-code priv/static/` gate; tied to every HEEx change above

### Claude's Discretion
- The final per-atom Heroicon names in `status_icon/1` (within outline-style, on-brand, semantically
  consistent constraints — D-04).
- Internal form of the status mapping clauses (case vs function-head pattern match) — any clean,
  literal-string form.
- Exact ordering of badge consolidation vs token migration vs support-card restructure across plans/
  waves (planner's sequencing call), provided restructure-first-then-tokenize (D-07) holds for the
  support cards.
- Whether the inbound past-tense adapter is a shared helper reused by both `records_list.ex` and
  `inbound/detail_header.ex` or duplicated — shared helper recommended to prevent re-divergence.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — FROZEN contract. Canonical
  Status-Badge Taxonomy Table (all 4 sub-tables + 5 conflict resolutions), Support-Card
  Primary/Secondary Hierarchy Layout, Health Count Colors, Base Class Rule, Implementation Notes
  (Pitfalls 1–5).
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — GAP-01..06 (badge),
  GAP-08/10 (390px spacing), GAP-13/14/15 (support-card), GAP-16/17/18 (token drift). Severity
  rubric + anti-churn citation gate.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — baseline e2e
  heading/seed-count assertions; consult before any markup change that could ripple Playwright.
- `.planning/phases/75-information-architecture-navigation-and-orientation/75-CONTEXT.md` — Phase 75
  decisions (Overview route, `count_active_suppressions/1`, orientation strip) that define the
  already-shipped surface Phase 76 builds on.
- `.planning/REQUIREMENTS.md` — DS-01..DS-04 acceptance text (note: DS-01 "three"/"icon + label"
  reconciled here by D-01 and D-04).
- `mailglass_admin/docs/design-system.md:104-121` — the six conformance pillars (token/grep gate
  definitions).
- `prompts/mailglass-brand-book.md` — palette, typography (400/700 only; no faux-bold), icon style
  (outline Heroicons), voice.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Existing `badge/1`** (`mailglass_admin/lib/mailglass_admin/components.ex:91-114`) — house pattern
  for the new `status_badge/1`: `attr :variant, :atom, values: [...], required: true` + private
  literal-string mapping defp (`alert_class/1`, `components.ex:86-89`). Keep `badge/1`; add
  `status_badge/1` alongside.
- **Overview health-card pattern** (`operator_live.ex:287-294`) — `text-display font-bold` +
  conditional semantic color; reuse for support-card Tier 1 counts.
- **`SupportSummary.summarize_tenant/1`** (`lib/mailglass/operator/support_summary.ex:21-35`) —
  already supplies `failed_ingest.count`, `orphan_backlog.count`, `replay_outcomes.counts`,
  `reconcile_facts.{reconciled_count, still_unmatched_count}`. No change needed.
- **`count_active_suppressions/1`** (`lib/mailglass/operator/suppressions.ex:56`, shipped Phase 75)
  — wired at `operator_live.ex:615`, surfaced as `@suppression_count`.
- **Test patterns** — `render_component/2` + `assert html =~` at
  `test/mailglass_admin/inbound/components_test.exs:26`, `test/mailglass_admin/operator/shell_test.exs:12`.
- **Asset build** — `mix mailglass_admin.assets.build` (`mailglass_admin.assets.build.ex:28`),
  committed bundle `mailglass_admin/priv/static/app.css`; `BundleTest` enforces <150KB + font set.

### Established Patterns
- daisyUI 5 badge classes verified present: `badge-primary/success/warning/error/outline`,
  `badge-sm/md` (UI-SPEC Pitfall 3). `badge-outline` not `badge-ghost`.
- Literal-string-only class helpers (Pitfall 1 / JIT) — never interpolate class or icon names.
- Bundle-rebuild-in-same-PR discipline (Pitfall 2; `git diff --exit-code priv/static/` gate).
- Restructure-before-tokenize (Pitfall 4).

### Integration Points
- 5 `badge_class/1` deletion sites → all route through `Components.status_badge/1` (D-01).
- Inbound past-tense adapter at `records_list.ex` `record_outcome/1` + `inbound/detail_header.ex` (D-02).
- `support_cards.ex:29` flat grid → Tier1/Tier2 restructure (D-06), reading `@support_summary` +
  `@suppression_count`.
- New `hero-*` icon names + `badge-primary` must enter the JIT bundle (D-11).
</code_context>

<specifics>
## Specific Ideas

- **Badge = icon + label** (user-chosen, D-04). This is the one deliberate divergence from the frozen
  UI-SPEC label-only sketch — recorded as an amendment in favor of DS-01's literal text. It creates a
  new sub-deliverable: the per-atom Heroicon mapping (`status_icon/1`) and a 390px overflow re-check.
- Icons decorative/`aria-hidden`; the text label remains the accessible semantic.
- Prefer a shared inbound past-tense adapter helper over duplicating it across the two inbound files.
</specifics>

<deferred>
## Deferred Ideas

- **`motion-reveal` re-fire fix (GAP-19)** — Phase 77, not here (UI-SPEC §Motion-Reveal Re-Fire Fix).
- **Deep-link unstyled-CSS bug (GAP-22)** — deferred to Phase 79 per Phase 75 D-17 (touches stable
  asset-serving seam).
- **Motion vocabulary application (GAP-20/21)** — Phase 77.
- **Seed expansion to reach every badge color / card branch (SEED-01/02)** — Phase 78.
- **GAP-18 (`mono` class on ledger IDs/timestamps, sev-2)** — opportunistic during the token pass if
  cheap; does not block closeout.
- **Absorbing/refactoring the Preview `badge/1` atom** — out of scope (no GAP citation; D-03).

### Reviewed Todos (not folded)
None — no pending todos matched Phase 76 scope (the open `#25`/`#32` hackney/post-publish-smoke todo
is release-infra, unrelated to admin component hardening).
</deferred>
