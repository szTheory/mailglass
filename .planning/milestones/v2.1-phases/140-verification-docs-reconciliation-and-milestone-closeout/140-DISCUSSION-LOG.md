# Phase 140: Verification, docs reconciliation, and milestone closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-07-08
**Phase:** 140-verification-docs-reconciliation-and-milestone-closeout
**Mode:** assumptions + recommendation-first research
**Areas analyzed:** Focused Gate Trust, Docs And Backlog Truth, Closeout Boundary

## Assumptions Presented

### Focused Gate Trust

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 140 should treat the existing focused lanes as the closeout truth: `mix verify.schema_prefix` for schema-prefix proof, plus the admin first-HTML and serialized browser asset proofs for admin URL robustness. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `mix.exs`, `.github/workflows/advisory-matrix.yml`, `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs`, `mailglass_admin/e2e/admin-assets.spec.js`, Phase 138/139 verification artifacts |

### Docs And Backlog Truth

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 140 should update only the stale admin asset documentation/backlog claims to say the hard-refresh/deep-link styling issue is resolved/proven by Phase 139, while preserving the mount-aware strategy and rejected alternatives. | Confident | DOC-01 names `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and `.planning/backlog/admin-relative-asset-url-styling.md`; those files still describe the issue as unresolved while `139-VERIFICATION.md` records AAU-01..04 and GATE-03 satisfied |

### Closeout Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 140 should reconcile active planning state for v2.1 audit/archive readiness without promoting deferred broader UI verification, ecosystem integrations, full no-search-path suite migration, release work, or unrelated maintenance todos. | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and the cowlib todo's own maintenance-tier `/gsd-quick` framing |

## User Direction

The user requested deeper one-shot recommendation research for each assumption, using subagents and considering:

- Pros, cons, and tradeoffs for each approach.
- Idiomatic Elixir/Plug/Ecto/Phoenix conventions for this kind of library/app.
- Lessons from successful libraries/apps in Elixir and other ecosystems.
- Developer ergonomics, SRE/DevOps, architecture, principle of least surprise, and maintainer cost.
- UI/UX, content design, brand voice, accessibility/performance/design-system concerns where applicable.
- Prompt research under `prompts/`, with newer `brandbook/brand-book.md` preferred over older prompt-era brand material.
- A cohesive recommendation set that lets the maintainer avoid another decision round.

## Research Summary

### Focused Gate Trust

Recommendation: use focused lanes as closeout truth.

Tradeoffs considered:

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Focused lanes as truth | Matches v2.1 scope, proves exact failures, keeps contributor gate understandable, follows project DNA of one focused verifier per concern | Does not claim whole-suite no-search-path conversion or full UI/a11y coverage | Selected |
| Broad-suite closeout | More incidental regression discovery | Dual-schema suite can still pass search-path-masked bugs; broad no-search-path sweep is a new fixture migration; high false-red risk | Rejected unless focused proof fails |
| Advisory-only canary | Low friction, useful trend signal | Not fail-closed for schema-prefix correctness or browser styling | Rejected as sole proof |

Relevant ecosystem lessons:

- Ecto's official `:prefix` repo option is the idiomatic schema-selection mechanism for Postgres schema paths.
- ExUnit tags/filters support focused lanes for targeted proof.
- Phoenix/LiveView testing distinguishes disconnected first HTML from connected browser behavior, matching the Phase 139 split between first-HTML and Playwright proof.
- Laravel mail fakes and Rails mail previews show good DX comes from focused assertions around user-visible behavior, not broad incidental verification.

### Docs And Backlog Truth

Recommendation: update stale claims as resolved/proven, preserve history where useful.

Tradeoffs considered:

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Update stale current-state claims and preserve strategy/history | Aligns with DOC-01, reflects proof, removes false demo workaround, preserves rejected alternatives | Must avoid overclaiming beyond verified route matrix | Selected |
| Leave cautionary limitation language | Conservative | Public docs lie about current behavior and make a fixed issue look broken | Rejected except in explicit historical wording |
| Delete history entirely | Clean public surface | Erases rejected-alternative rationale and invites repeated architecture churn | Rejected |

Relevant ecosystem/content lessons:

- User-facing docs should describe the reader's job and observable behavior first; implementation details belong in maintainer docs.
- The current brandbook favors clear, exact, calm copy and recovery-oriented language.
- Framework docs separate current behavior from migration/history notes; mailglass should do the same.

### Closeout Boundary

Recommendation: keep strict closeout scope.

Tradeoffs considered:

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Strict Phase 140 closeout | Preserves v2.1 as maintenance-only, keeps audit surface small, aligns with DOC-01/DOC-02 | Does not pay down broader process debt | Selected |
| Fold related deferred items | Captures while-in-context work | Violates milestone boundary, mixes future UI/process work with closeout, increases review cost | Rejected |
| Start release/audit/refactor/maintenance work inside Phase 140 | Could drain old items | Contradicts no-release/no-product-expansion locks and entangles unrelated triggers | Rejected |

Relevant ecosystem/project lessons:

- Prior retrospectives show deferred real gates can cause release-time pain, but the remedy for v2.1 is rerunning the already-focused real gates, not widening closeout into unrelated work.
- Project DNA favors explicit deferred items, narrow phase gates, and documentation contracts that prevent silent drift.
- Mature release practice separates release PRs/publish posture from normal closeout work.

## Corrections Made

The user did not correct an assumption. Instead, the user requested deeper research and a cohesive recommendation set. The original three assumptions were retained and expanded into the final decisions in `140-CONTEXT.md`.

## Folded Todos

None.

## Reviewed Todos

- `.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` - Reviewed and not folded. It is trigger-based dependency/security maintenance for `/gsd-quick`, not v2.1 docs/verification closeout.

## External Research

- Ecto `:prefix` repo/query-prefix semantics: `https://ecto.hexdocs.pm/Ecto.Repo.html`, `https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix`
- ExUnit focused tags/filters: `https://ex-unit.hexdocs.pm/ExUnit.Case.html`
- Phoenix/LiveView first-render and testing model: `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html`, `https://phoenix.hexdocs.pm/testing.html`
- Plug static request-path asset serving: `https://hexdocs.pm/plug/Plug.Static.html`
- Prior-art DX references: Rails Action Mailer previews/testing, Laravel mail fake/assertions, Django Anymail normalized tracking.

## Outcome

Created a Phase 140 context that locks a recommendation-first closeout plan:

- Focused gates define v2.1 proof.
- Docs/backlog must reflect verified current behavior.
- Deferred work remains visible but outside Phase 140.
- Downstream planners should implement without reopening routine decision menus.
