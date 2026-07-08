# Phase 140: Verification, docs reconciliation, and milestone closeout - Context

**Gathered:** 2026-07-08 (assumptions mode + recommendation-first research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 140 closes the v2.1 Postgres + Admin URL Hardening milestone by rerunning and recording the focused schema-prefix and admin-asset proof lanes, updating stale docs/backlog text that still describes the admin hard-refresh/deep-link styling issue as unresolved, preserving explicit deferrals, and preparing the milestone for `/gsd-complete-milestone`.

This phase does not add product capability, change router/admin public APIs, redesign the admin UI, broaden the no-search-path suite migration, start a release cut, or promote deferred ecosystem/UI-verification work. If a focused gate fails or the docs reveal that Phase 139 proof is incomplete, fix or replan that targeted gap instead of widening Phase 140 into a new milestone.
</domain>

<decisions>
## Implementation Decisions

### Focused Gate Trust
- **D-01:** Treat the existing focused lanes as Phase 140 closeout truth: `mix verify.schema_prefix` for hostile no-search-path schema-prefix correctness, plus the Phase 139 admin first-HTML href proof and serialized browser hard-load asset proof for admin URL robustness.
- **D-02:** Keep the broad dual-schema advisory matrix as a canary, not the pass/fail definition for v2.1 closeout. It can discover regressions, but it is explicitly not fail-closed for schema-prefix correctness because its harness can align `search_path` with the configured schema.
- **D-03:** Do not replace the focused gates with advisory-only status, screenshot/pixel-diff visual baselines, a whole-suite no-search-path migration, or a full admin UI/a11y sweep. Those are different work unless a focused v2.1 proof fails.

### Docs And Backlog Truth
- **D-04:** Update the current-state docs/backlog truth for the admin asset issue: hard refreshes and deep links should now stay styled under the verified route matrix, including alternate mount roots. If they do not, that is a regression to investigate with the Phase 139 browser evidence gate.
- **D-05:** In user-facing docs such as `guides/run-the-demo.md`, describe the observable behavior and recovery path, not the internal `MountPathHook`/`MountPath`/`Layouts.css_url` machinery. Keep implementation strategy and rejected alternatives in maintainer-facing docs/backlog where they prevent repeated architecture churn.
- **D-06:** Preserve the selected mount-aware strategy and rejected alternatives as historical guardrails: root-relative mount-root asset URLs remain the intended path; duplicate nested routes, CDN/host assets, `<base>`, redirects, and public router macro options remain rejected primary fixes unless new evidence invalidates the narrower strategy.
- **D-07:** Write docs in the current brand voice: plain, exact, calm, user-recoverable copy. Avoid false cautions that make a fixed behavior look broken, but do not overclaim beyond the Phase 139 proof matrix.

### Closeout Boundary
- **D-08:** Keep Phase 140 as strict closeout scope: verify focused gates, reconcile DOC-01/DOC-02 files and active planning state, then hand off to `/gsd-complete-milestone`.
- **D-09:** Do not fold in broader UI verification discipline, SEED-003 ecosystem integrations, full no-search-path fixture cleanup, release ceremony work, dependency/security maintenance, or unrelated pending todos.
- **D-10:** The pending cowlib advisory allowlist todo is reviewed but not folded. It remains trigger-based maintenance for `/gsd-quick` when upstream ships a fix.

### Methodology Applied
- **D-11:** Apply the project methodology lenses directly: Decisive-By-Default and Recommendation-First mean planners should implement the coherent default above without reopening routine option menus; Honest Surface Area means docs must reflect current verified runtime behavior and keep future/deferred claims explicit.

### Claude's Discretion
Planner/implementer may choose exact wording, section placement, and whether to add lightweight grep/docs-contract assertions for stale admin-asset phrases, as long as DOC-01/DOC-02 are satisfied and the focused gates remain the verification basis.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Milestone Contracts
- `.planning/ROADMAP.md` - Phase 140 scope, success criteria, active v2.1 phase list, and explicit deferrals.
- `.planning/REQUIREMENTS.md` - DOC-01, DOC-02, GATE-01..03, AAU-01..04, SCHEMA-01..04 traceability and out-of-scope list.
- `.planning/PROJECT.md` - v2.1 locked decisions, maintenance-only posture, and scope locks.
- `.planning/STATE.md` - current position after Phase 139 and active deferred/backlog context.
- `.planning/METHODOLOGY.md` - Decisive-By-Default, Honest Surface Area, and Recommendation-First lenses.

### Prior Phase Proof
- `.planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md` - Passed hostile schema-prefix proof, raw-repo guard, focused alias, and advisory-canary distinction.
- `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-CONTEXT.md` - Locked mount-aware asset strategy and route/browser proof expectations.
- `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md` - Passed first-HTML href matrix, CSS/font network proof, alternate mount roots, and computed-style proof.
- `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VALIDATION.md` - Validation record for AAU/GATE behavior.

### Verification Surfaces
- `mix.exs` - `verify.schema_prefix` alias and related focused verification aliases.
- `.github/workflows/advisory-matrix.yml` - Broad dual-schema canary comments and focused schema-prefix proof wiring.
- `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` - First-HTML stylesheet href matrix.
- `mailglass_admin/test/mailglass_admin/mount_path_test.exs` - Pure route-shape mount base coverage.
- `mailglass_admin/e2e/admin-assets.spec.js` - Serialized browser CSS/font network and computed-style proof.
- `mailglass_admin/playwright.config.cjs` - Browser gate server and serialization setup.
- `mailglass_admin/test/mailglass_admin/token_parity_test.exs` - Token-backed compiled CSS parity proof.
- `mailglass_admin/test/mailglass_admin/bundle_test.exs` - Admin bundle integrity coverage.

### Docs and Backlog Targets
- `mailglass_admin/docs/design-system.md` - Current stale known-limitation text and design-system verification guidance to reconcile.
- `guides/run-the-demo.md` - Current stale demo troubleshooting workaround to remove or rewrite as regression guidance.
- `.planning/backlog/admin-relative-asset-url-styling.md` - Backlog seed promoted to Phase 139; acceptance checkboxes and problem/status text need resolved/proven reconciliation.
- `brandbook/brand-book.md` - Current canonical brand/voice source; supersedes older prompt-era brand text where they differ.

### Deferred/Reviewed Items
- `.planning/backlog/ui-browser-gate-during-phases-not-only-at-release.md` - Broader UI verification process debt; keep deferred to a future UI/process milestone.
- `.planning/seeds/SEED-003-ecosystem-integrations.md` - Ecosystem integrations seed; keep deferred/pull-gated.
- `.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` - Reviewed but not folded trigger-based maintenance item.

### Prompt Research Used for Recommendation Synthesis
- `prompts/Phoenix needs an email framework not another mailer.md` - Product/DX vision, prior-art lessons, and scope-creep risk.
- `prompts/mailglass-engineering-dna-from-prior-libs.md` - Project DNA: focused phase verification, docs contracts, narrow gates, release hygiene.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - OSS library CI/CD and docs-as-product guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - Elixir library ergonomics, explicit APIs, docs, and public surface discipline.
- `prompts/phoenix-best-practices-deep-research.md` - Phoenix testing hierarchy and web-layer verification guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` - LiveView lifecycle and proof strategy for first render/browser behavior.
- `prompts/mailer-domain-language-deep-research.md` - Email-domain nouns and user/job framing.

### Official Ecosystem References
- `https://ecto.hexdocs.pm/Ecto.Repo.html` - Ecto `:prefix` repo option semantics.
- `https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix` - Query-prefix precedence and repo-operation prefix example.
- `https://ex-unit.hexdocs.pm/ExUnit.Case.html` - ExUnit tags/filters for focused test lanes.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html` - LiveView disconnected first render and connected lifecycle testing model.
- `https://phoenix.hexdocs.pm/testing.html` - Phoenix testing structure and ConnCase integration style.
- `https://hexdocs.pm/plug/Plug.Static.html` - Plug static asset serving request-path semantics.
- `https://guides.rubyonrails.org/action_mailer_basics.html` - Rails mail preview/testing precedent.
- `https://laravel.com/docs/13.x/mail` - Laravel mail fake/assertion DX precedent.
- `https://anymail.dev/en/latest/sending/tracking/` - Django Anymail normalized webhook/status-tracking precedent.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify.schema_prefix`: already delegates to hostile core tests, raw-repo guard tests, strict Credo, and inbound schema-prefix contract tests.
- `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs`: already verifies rendered root-layout stylesheet hrefs for preview/operator/inbound/gallery/query/alternate routes.
- `mailglass_admin/e2e/admin-assets.spec.js`: already verifies direct hard-load CSS/font network responses and token-backed computed styles without screenshots.
- `.github/workflows/advisory-matrix.yml`: already documents why broad dual-schema jobs are canaries rather than fail-closed proof.
- Existing docs-contract patterns in the repo can be reused if planners want a lightweight anti-regression guard against stale admin asset caveat text.

### Established Patterns
- Mailglass phases use focused verification lanes for bounded correctness questions rather than a kitchen-sink closeout gate.
- Planning artifacts keep active scope and deferred scope explicit; historical backlog is preserved when it prevents repeated debate.
- Public/docs copy should describe what users can observe and do, while maintainer docs may carry implementation rationale.
- Admin UI proof for this milestone is network + computed-style based, not visual redesign, screenshots, or pixel diffs.

### Integration Points
- Phase 140 implementation should update `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, `.planning/backlog/admin-relative-asset-url-styling.md`, and active planning artifacts as needed to close DOC-01/DOC-02.
- Verification evidence should cite the focused commands from Phase 138 and Phase 139, not broad advisory-only status.
- Milestone closeout should run after Phase 140 via `/gsd-complete-milestone`, not inside the phase implementation itself.
</code_context>

<specifics>
## Specific Ideas

- Use the phrase shape "Hard refreshes and direct deep links should stay styled; if they do not, run the admin asset browser proof and treat it as a regression" for user-facing docs.
- In `guides/run-the-demo.md`, remove the old advice to navigate from the dashboard instead of reloading deep links.
- In the backlog seed, mark Phase 139 as the resolution point and complete the AAU acceptance checklist, while keeping rejected approaches B-D as guardrails.
- In design-system docs, replace the old "Known limitations" entry with a current-state note that the issue was resolved/proven in v2.1 Phase 139 and that future regressions are covered by the focused asset gate.
- Avoid exposing backend internals in user docs unless needed for maintainers to diagnose a regression.
</specifics>

<deferred>
## Deferred Ideas

- Broader UI verification discipline, including running UI browser/persona gates earlier in future UI phases, remains deferred to a future UI/process milestone.
- SEED-003 ecosystem integrations, Cloudflare routing, synthetic inbound dev UI, `gen_smtp`, and additional provider work remain pull-gated and out of v2.1.
- Whole-suite no-search-path fixture migration remains future work unless the focused hostile lane proves dishonest.
- Release ceremony/version bump/Hex publish work is out of Phase 140; v2.1 closeout prepares for audit/archive only.
- Cowlib advisory allowlist cleanup remains a trigger-based `/gsd-quick` maintenance item when upstream ships a fix.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` - Not folded because it is unrelated dependency/security maintenance keyed to an upstream release trigger, not v2.1 docs/verification closeout.
</deferred>

---

*Phase: 140-verification-docs-reconciliation-and-milestone-closeout*
*Context gathered: 2026-07-08*
