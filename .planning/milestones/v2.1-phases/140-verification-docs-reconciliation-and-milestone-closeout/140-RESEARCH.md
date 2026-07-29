# Phase 140: Verification, Docs Reconciliation, and Milestone Closeout - Research

**Researched:** 2026-07-08
**Domain:** Elixir/Phoenix verification closeout, documentation reconciliation, and GSD milestone handoff
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### the agent's Discretion
Planner/implementer may choose exact wording, section placement, and whether to add lightweight grep/docs-contract assertions for stale admin-asset phrases, as long as DOC-01/DOC-02 are satisfied and the focused gates remain the verification basis.

### Deferred Ideas (OUT OF SCOPE)

- Broader UI verification discipline, including running UI browser/persona gates earlier in future UI phases, remains deferred to a future UI/process milestone.
- SEED-003 ecosystem integrations, Cloudflare routing, synthetic inbound dev UI, `gen_smtp`, and additional provider work remain pull-gated and out of v2.1.
- Whole-suite no-search-path fixture migration remains future work unless the focused hostile lane proves dishonest.
- Release ceremony/version bump/Hex publish work is out of Phase 140; v2.1 closeout prepares for audit/archive only.
- Cowlib advisory allowlist cleanup remains a trigger-based `/gsd-quick` maintenance item when upstream ships a fix.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` - Not folded because it is unrelated dependency/security maintenance keyed to an upstream release trigger, not v2.1 docs/verification closeout.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHEMA-01 | `Mailglass.Webhook.Replay` updates projections in the configured schema under hostile no-search-path conditions. | Already satisfied by Phase 138; Phase 140 should rerun `mix verify.schema_prefix` as the focused trust lane. [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| SCHEMA-02 | Unsubscribe replay/idempotency conflict lookups read from the configured schema under hostile no-search-path conditions. | Already satisfied by Phase 138; include in the same focused schema-prefix rerun. [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| SCHEMA-03 | Raw repo calls and transaction callbacks are prefixed, facade-routed, or allowlisted with a static guard. | `mix verify.schema_prefix` runs the raw repo prefix contract and strict Credo guard. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| SCHEMA-04 | Inbound repo-option extension points retain facade/default prefix contracts. | `mix verify.schema_prefix` delegates the inbound contract test through a subdirectory command. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| AAU-01 | First HTML emits current-mount rooted stylesheet hrefs across admin routes. | Rerun the Phase 139 fast ExUnit matrix. [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] |
| AAU-02 | Hard refreshes/direct deep links load CSS and font assets with 200 responses. | Rerun the focused Playwright `admin asset hard load` grep. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| AAU-03 | Asset proof passes under arbitrary alternate mount paths without public router macro options. | ExUnit and Playwright route matrices include alternate preview/operator/inbound mount roots. [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| AAU-04 | Browser gate fails on CSS/font 404s and asserts token-backed computed styling. | Playwright observes asset responses and computed fonts/backgrounds, not screenshots. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| GATE-01 | Focused schema-prefix lane exists and runs runtime/static proofs. | Alias exists in root `mix.exs` and passed in Phase 138 verification. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| GATE-02 | Dual-schema advisory matrix stays a canary while focused no-search-path lane is fail-closed proof. | Advisory workflow comments name the canary/proof distinction and Phase 138 verification confirmed it. [VERIFIED: .github/workflows/advisory-matrix.yml] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| GATE-03 | Admin URL robustness has fast href assertions and serialized browser proof. | Phase 139 verification passed the ExUnit matrix, bundle/token checks, and Playwright grep. [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md] |
| DOC-01 | `design-system.md`, `run-the-demo.md`, and admin relative-asset backlog no longer claim the hard-refresh/deep-link issue remains unresolved. | These three targets currently still contain stale unresolved/unstyled language and need reconciliation. [VERIFIED: rg over docs/backlog] |
| DOC-02 | Active planning artifacts keep broader UI verification discipline and ecosystem integrations explicitly deferred. | ROADMAP, REQUIREMENTS, PROJECT, and STATE already contain the v2.1 deferral framing; Phase 140 should preserve it and update requirement status after DOC-01/02 proof. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/STATE.md] |
</phase_requirements>

## Summary

Phase 140 is a closeout and truth-reconciliation phase, not a product or UI implementation phase. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] The planner should use the existing focused gates as truth: root `mix verify.schema_prefix` for schema-prefix correctness, `mailglass_admin` ExUnit tests for first-HTML mount-root stylesheet hrefs, and the serialized Playwright `admin asset hard load` grep for hard-refresh/browser behavior. [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js]

The implementation target is small and concrete: replace stale unresolved wording in `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and `.planning/backlog/admin-relative-asset-url-styling.md`; then update active planning artifacts only enough to mark DOC-01/DOC-02 and milestone drift truth. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: rg over docs/backlog] Historical v1.7 deferral lines in `STATE.md` can remain as history, but the active current-position section should record Phase 140's superseding truth if edited. [VERIFIED: .planning/STATE.md]

**Primary recommendation:** Plan one narrow docs/verification wave: rerun focused Phase 138/139 proof lanes, reconcile the three stale docs/backlog surfaces, add a lightweight stale-phrase grep or docs-contract assertion if cheap, update active planning status, create Phase 140 verification evidence, and hand off to `/gsd-complete-milestone` rather than running milestone archive inside this phase. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] [VERIFIED: .planning/milestones/v1.11-phases/103-verification-idempotent-closeout/103-04-SUMMARY.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Schema-prefix closeout proof | Test harness / CI | Database / Ecto repo layer | `mix verify.schema_prefix` exercises hostile runtime proofs plus static guard against missing `prefix:` recurrence. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| Admin first-HTML href proof | Test harness / Phoenix ConnTest | Browser / LiveView render layer | `admin_asset_url_test.exs` verifies rendered first HTML, so planner should not assign this to docs-only review. [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] |
| Admin hard-refresh asset proof | Browser automation | Static asset routing | Playwright listens for stylesheet/font network failures and asserts computed styles under direct `page.goto` loads. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| User-facing demo troubleshooting copy | Documentation | Test evidence | Public docs should state observable behavior and regression recovery without internal `MountPath` mechanics. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] |
| Design-system implementation rationale | Maintainer documentation | Backlog seed | Maintainer docs/backlog may retain strategy and rejected alternatives to prevent architecture churn. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] |
| Milestone archival readiness | Planning artifacts / GSD | Verification reports | Phase 140 prepares evidence; `/gsd-complete-milestone` performs the archive after this phase. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] |

## Project Constraints (from CLAUDE.md)

- This is an Elixir/Phoenix library with three sibling Hex packages: `mailglass`, `mailglass_admin`, and `mailglass_inbound`. [VERIFIED: CLAUDE.md]
- There is no adopter-facing Node toolchain; Node/Playwright is developer verification tooling for admin browser gates. [VERIFIED: CLAUDE.md] [VERIFIED: mailglass_admin/package.json]
- `mailglass_admin/priv/static/app.css` is committed, and admin CSS changes must be followed by bundle rebuild plus `git diff --exit-code priv/static/`; Phase 140 should avoid CSS changes entirely. [VERIFIED: CLAUDE.md] [VERIFIED: mailglass_admin/mix.exs]
- Optional deps are gated through `Mailglass.OptionalDeps.*`; Phase 140 should not add optional dependency surface. [VERIFIED: CLAUDE.md]
- Do not write to admin static assets without committing the rebuilt bundle; again, Phase 140 should not touch static assets. [VERIFIED: CLAUDE.md]
- Brand voice for docs is clear, exact, calm, user-recoverable, and technical without being intimidating. [VERIFIED: CLAUDE.md] [VERIFIED: brandbook/brand-book.md via CONTEXT reference]
- Marketing email, multi-channel notifications, ecosystem integrations, and transport expansion are out of scope unless a future milestone selects them. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md]
- `./AGENTS.md`, `./.claude/CLAUDE.md`, `.claude/skills/`, and `.agents/skills/` were not present in this workspace scan. [VERIFIED: shell checks]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Mix / ExUnit | Mix 1.19.5 running locally; project `.tool-versions` pins Elixir 1.18.4 / Erlang 27.3.4.13 | Root and sibling package test aliases | Existing project test harness and CI alias surface. [VERIFIED: shell `mix --version`] [VERIFIED: .tool-versions] |
| Ecto/Postgrex test database | Ecto 3.14.0, Postgrex 0.22.2 in root deps | Schema-prefix runtime proof and SQL sandbox-backed tests | Existing schema-prefix lane depends on database-backed ExUnit tests. [VERIFIED: `mix deps`] [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] |
| Credo | Root 1.7.19, admin 1.7.18 | Static raw repo prefix recurrence guard and project lint | `mix verify.schema_prefix` includes strict Credo. [VERIFIED: `mix deps`] [VERIFIED: mix.exs] |
| Phoenix / LiveView test stack | Phoenix 1.8.8; root LiveView 1.1.32; admin LiveView 1.1.28 | Admin first-HTML and route rendering tests | Existing admin proof uses Phoenix Conn/LiveView route rendering. [VERIFIED: `mix deps`] [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] |
| Playwright Test | `@playwright/test` 1.59.1 | Serialized browser proof for CSS/font network and computed styles | Existing `npm run test:operator-browser` runs Playwright with `--workers=1`. [VERIFIED: mailglass_admin/package.json] [VERIFIED: `npm ls`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Floki | 0.38.4 | Parse first HTML stylesheet links in ExUnit | Already used by `admin_asset_url_test.exs`. [VERIFIED: `mix deps`] [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] |
| ripgrep | 15.1.0 local | Stale phrase inventory and docs-contract smoke checks | Use for DOC-01/DOC-02 stale wording assertions. [VERIFIED: shell `rg --version`] |
| GSD tools | `/Users/jon/.asdf/installs/nodejs/22.14.0/bin/gsd-tools` | Phase init and optional commit helper | `init.phase-op` confirmed output path and `commit_docs: true`. [VERIFIED: `gsd-tools query init.phase-op 140`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Focused schema-prefix alias | Full dual-schema advisory suite | Broad canary can align `search_path` with configured schema and mask the bug class Phase 138 targeted. [VERIFIED: .github/workflows/advisory-matrix.yml] |
| Network/computed-style browser proof | Screenshot or pixel-diff visual baselines | Phase 140 context rejects screenshot/pixel-diff expansion; current proof checks actual asset load and token-backed styles. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| Narrow stale-phrase docs guard | Full docs-contract rewrite | Existing docs-contract patterns are available, but DOC-01 can be satisfied with a targeted grep or one focused assertion. [VERIFIED: test/mailglass/docs_contract_test.exs] [VERIFIED: lib/mix/tasks/mailglass.docs.check.ex] |

**Installation:**

No new package installation is recommended for Phase 140. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

**Version verification:**

```bash
mix --version
mix deps | rg 'ecto|postgrex|credo|phoenix|phoenix_live_view|floki'
cd mailglass_admin && npm ls @playwright/test @axe-core/playwright --depth=0
```

## Package Legitimacy Audit

Not applicable. Phase 140 should install no external packages and should use existing Mix, ExUnit, Credo, and Playwright tooling. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] [VERIFIED: mailglass_admin/package.json]

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Phase 138 evidence
  -> mix verify.schema_prefix
  -> hostile DB tests + raw-repo guard + strict Credo + inbound contract
  -> schema gate evidence

Phase 139 evidence
  -> admin first-HTML ExUnit matrix
  -> token/bundle checks
  -> serialized Playwright admin asset hard-load proof
  -> admin URL gate evidence

Schema + admin evidence
  -> Phase 140 docs/backlog reconciliation
  -> DOC-01 stale-phrase proof + DOC-02 deferral proof
  -> 140-VERIFICATION.md / summary evidence
  -> /gsd-complete-milestone audit/archive handoff
```

### Recommended Project Structure

```text
.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/
├── 140-CONTEXT.md       # locked decisions already gathered
├── 140-RESEARCH.md      # this file
├── 140-PLAN.md          # planner output, likely one narrow plan
├── 140-SUMMARY.md       # executor summary after docs/verification closeout
└── 140-VERIFICATION.md  # verifier or closeout evidence before milestone archive
```

### Pattern 1: Focused Gate Rerun Before Docs Truth

**What:** Reconfirm the gates that justify changing docs from "known limitation" to "resolved/proven." [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

**When to use:** Before rewriting unresolved admin-asset copy or marking DOC-01/DOC-02 complete. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```bash
# Source: mix.exs and Phase 139 verification
mix verify.schema_prefix
cd mailglass_admin && MIX_ENV=test mix test \
  test/mailglass_admin/admin_asset_url_test.exs \
  test/mailglass_admin/mount_path_test.exs \
  --warnings-as-errors
cd mailglass_admin && MIX_ENV=test mix test \
  test/mailglass_admin/token_parity_test.exs \
  test/mailglass_admin/bundle_test.exs \
  --warnings-as-errors
cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"
```

### Pattern 2: Public Docs Say Behavior, Maintainer Docs Keep Mechanism

**What:** User-facing `guides/run-the-demo.md` should say hard refreshes and direct deep links should stay styled and name the focused proof as the regression check; maintainer-facing docs/backlog can preserve `MountPathHook`/`MountPath`/`Layouts.css_url` and rejected alternatives. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

**When to use:** Rewriting the demo troubleshooting section and design-system known-limitation block. [VERIFIED: guides/run-the-demo.md] [VERIFIED: mailglass_admin/docs/design-system.md]

**Example:**

```markdown
<!-- Source: Phase 140 CONTEXT.md D-04/D-05 -->
Hard refreshes and direct deep links should stay styled. If a route loads
unstyled, treat it as a regression and rerun the admin asset browser proof.
```

### Pattern 3: Stale Phrase Guard

**What:** Add a cheap docs-contract assertion or final grep that fails if the obsolete unresolved-issue wording remains. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] [VERIFIED: test/mailglass/docs_contract_test.exs]

**When to use:** If the planner wants DOC-01 to be fail-closed rather than review-only. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```bash
# Source: rg inventory from research
rg -n "Navigate from the dashboard|Tracked as GAP-22|hard refresh on a deep URL can load unstyled|direct loads unstyled" \
  guides/run-the-demo.md \
  mailglass_admin/docs/design-system.md \
  .planning/backlog/admin-relative-asset-url-styling.md
```

### Anti-Patterns to Avoid

- **Treating advisory matrix green as the schema-prefix proof:** The advisory matrix is explicitly a canary because its harness can mask missing `prefix:` with `search_path`. [VERIFIED: .github/workflows/advisory-matrix.yml]
- **Putting internal mount-path machinery in public demo docs:** Phase context reserves mechanism details for maintainer-facing docs/backlog. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]
- **Expanding to full UI/a11y/persona sweep:** Broader UI verification discipline is explicitly deferred. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/backlog/ui-browser-gate-during-phases-not-only-at-release.md]
- **Running release ceremony inside Phase 140:** Phase 140 prepares closeout and hands off to `/gsd-complete-milestone`; it does not cut a release. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema-prefix trust | New scanner or full custom DB harness | `mix verify.schema_prefix` | Existing alias already composes hostile tests, raw guard, Credo, and inbound contract. [VERIFIED: mix.exs] |
| Admin first-load URL trust | Manual browser inspection | Existing ExUnit route matrix and Playwright hard-load proof | Phase 139 tests assert exact hrefs, CSS/font responses, and computed styles. [VERIFIED: mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs] [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| Docs stale-wording detection | Broad prose parser | `rg` or narrow docs-contract assertion | Existing repo uses deterministic token/phrase checks for docs drift. [VERIFIED: lib/mix/tasks/mailglass.docs.check.ex] [VERIFIED: test/mailglass/docs_contract_test.exs] |
| Milestone archive | Hand-authored archive moves | `/gsd-complete-milestone` after Phase 140 verification | GSD closeout is the existing lifecycle boundary. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** Phase 140 closes the gap between verified behavior and written truth; custom verification strategy is lower value than rerunning the already focused lanes and preventing stale copy from surviving. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Stale Public Copy Survives With "Resolved" Backlog Status

**What goes wrong:** The backlog seed is marked resolved but `guides/run-the-demo.md` still tells users to avoid hard refreshes. [VERIFIED: guides/run-the-demo.md] [VERIFIED: .planning/backlog/admin-relative-asset-url-styling.md]

**Why it happens:** DOC-01 spans public docs, maintainer docs, and backlog, so updating only one surface creates drift. [VERIFIED: .planning/REQUIREMENTS.md]

**How to avoid:** Update all three DOC-01 targets and run a stale-phrase grep. [VERIFIED: rg over docs/backlog]

**Warning signs:** Phrases like `known limitation`, `Navigate from the dashboard`, `Tracked as GAP-22`, or `can load unstyled` remain in current-state sections. [VERIFIED: rg over docs/backlog]

### Pitfall 2: Editing History Instead Of Current Truth

**What goes wrong:** A planner rewrites old v1.7 historical STATE entries instead of adding current Phase 140 truth. [VERIFIED: .planning/STATE.md]

**Why it happens:** `STATE.md` contains both historical decision logs and current active milestone sections. [VERIFIED: .planning/STATE.md]

**How to avoid:** Preserve historical entries unless they are explicitly current-state drift; add or update the current v2.1/Phase 140 section instead. [VERIFIED: .planning/STATE.md]

**Warning signs:** Edits touch old `[79-03-B]` history but do not update current v2.1 status or requirements. [VERIFIED: .planning/STATE.md]

### Pitfall 3: Over-Widening The Gate

**What goes wrong:** Phase 140 turns into full `mix ci`, full UI browser/persona process debt, whole-suite no-search-path cleanup, or release work. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

**Why it happens:** Closeout phases invite "one more thing" cleanup. [ASSUMED]

**How to avoid:** Treat only the focused lanes as pass/fail; list deferred scope explicitly. [VERIFIED: .planning/REQUIREMENTS.md]

**Warning signs:** Plan tasks mention SEED-003, Cloudflare, full no-search-path fixture migration, screenshots, or Hex publish. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

### Pitfall 4: Browser Gate Concurrency Or Asset Bundle Drift

**What goes wrong:** The browser proof is run without the existing serialized command or triggers static bundle drift. [VERIFIED: mailglass_admin/package.json] [VERIFIED: mailglass_admin/mix.exs]

**Why it happens:** `test:operator-browser` intentionally builds assets and runs Playwright with `--workers=1`; `verify.preview` also checks `git diff --exit-code priv/static/`. [VERIFIED: mailglass_admin/package.json] [VERIFIED: mailglass_admin/mix.exs]

**How to avoid:** Use the existing npm script and verify no `priv/static` diff after browser/admin verification. [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md]

**Warning signs:** Direct `playwright test` without config/workers or a dirty `mailglass_admin/priv/static/app.css`. [VERIFIED: mailglass_admin/package.json] [VERIFIED: mailglass_admin/mix.exs]

## Code Examples

Verified patterns from local sources:

### Closeout Gate Command Set

```bash
# Source: mix.exs, mailglass_admin/package.json, 139-VERIFICATION.md
mix verify.schema_prefix
cd mailglass_admin && MIX_ENV=test mix test \
  test/mailglass_admin/admin_asset_url_test.exs \
  test/mailglass_admin/mount_path_test.exs \
  --warnings-as-errors
cd mailglass_admin && MIX_ENV=test mix test \
  test/mailglass_admin/token_parity_test.exs \
  test/mailglass_admin/bundle_test.exs \
  --warnings-as-errors
cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"
git diff -- mailglass_admin/priv/static/app.css mailglass_admin/priv/static/fonts mailglass_admin/priv/static/mailglass-logo.svg
```

### Stale-Text Guard

```bash
# Source: rg inventory during research
rg -n "Navigate from the dashboard|Tracked as GAP-22|hard refresh on a deep URL can load unstyled|direct loads unstyled|known limitation" \
  guides/run-the-demo.md \
  mailglass_admin/docs/design-system.md \
  .planning/backlog/admin-relative-asset-url-styling.md
```

### Deferral Drift Check

```bash
# Source: ROADMAP/REQUIREMENTS/PROJECT/STATE DOC-02 surfaces
rg -n "broader UI verification discipline|SEED-003 ecosystem integrations|whole-suite no-search-path|release ceremony" \
  .planning/ROADMAP.md \
  .planning/REQUIREMENTS.md \
  .planning/PROJECT.md \
  .planning/STATE.md
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bare relative admin stylesheet URLs were documented as a known limitation. | Mount-rooted asset URLs are treated as the intended strategy and proven across the route matrix. | v2.1 Phase 139, verified 2026-07-08. [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md] | Docs should no longer tell users deep-link hard refresh is expected to be unstyled. |
| Dual-schema full suite was tempting as schema proof. | `mix verify.schema_prefix` is the fail-closed no-search-path proof; dual-schema matrix is a canary. | v2.1 Phase 138, verified 2026-07-07. [VERIFIED: .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md] | Closeout should cite the focused lane, not advisory status. |
| UI proof could drift toward screenshots/persona sweeps. | Asset proof is network and computed-style based, screenshot-free. | v2.1 Phase 139. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] | Keeps Phase 140 narrow and avoids UI-process milestone scope. |

**Deprecated/outdated:**

- `guides/run-the-demo.md` workaround telling users to navigate from the dashboard instead of reloading a deep URL is outdated after Phase 139 proof. [VERIFIED: guides/run-the-demo.md] [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md]
- `mailglass_admin/docs/design-system.md` "Known limitations" entry describing relative asset URLs as current unstyled-deep-link behavior is outdated as current-state guidance. [VERIFIED: mailglass_admin/docs/design-system.md]
- Backlog acceptance checkboxes in `.planning/backlog/admin-relative-asset-url-styling.md` are stale because Phase 139 satisfied AAU-01..04 and GATE-03. [VERIFIED: .planning/backlog/admin-relative-asset-url-styling.md] [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Closeout phases invite opportunistic cleanup. | Common Pitfalls | Low; locked Phase 140 context already forbids widening, so planning does not depend on this generalization. |

## Open Questions

1. **Should DOC-01 get an automated stale-phrase guard?**
   - What we know: Context permits lightweight grep/docs-contract assertions, and existing docs-contract patterns are available. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] [VERIFIED: test/mailglass/docs_contract_test.exs]
   - What's unclear: Whether the planner values a permanent test or a one-time verification command for these planning/docs surfaces. [ASSUMED]
   - Recommendation: Add a one-time verification command at minimum; add a narrow docs test only if it stays low-churn. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | ExUnit proof lanes | yes | Elixir 1.19.5 / Mix 1.19.5 local; `.tool-versions` pins Elixir 1.18.4 | Use project `.tool-versions` via asdf if local version mismatch matters. [VERIFIED: shell commands] |
| Erlang/OTP | Elixir runtime | yes | OTP 28 local; `.tool-versions` pins Erlang 27.3.4.13 | Use asdf pinned version for CI parity. [VERIFIED: shell commands] |
| Postgres | Schema-prefix tests | yes | `pg_isready` accepting connections on `/tmp:5432`; `psql` 14.17 | Start local Postgres before gate rerun. [VERIFIED: shell commands] |
| Node / npm | Playwright proof | yes | Node 22.14.0, npm 11.1.0 | Existing `mailglass_admin/node_modules` is present. [VERIFIED: shell commands] |
| Playwright browser tooling | Admin asset browser proof | yes | Playwright 1.59.1 | Reinstall deps only if node_modules is missing. [VERIFIED: `npm ls`] |
| ripgrep | Stale phrase checks | yes | 15.1.0 | POSIX grep if unavailable. [VERIFIED: shell commands] |
| Docker | Not required by Phase 140 core path | yes | 29.5.2 | Not needed unless user expands to demo evidence, which is out of scope. [VERIFIED: shell commands] |

**Missing dependencies with no fallback:** none found. [VERIFIED: shell commands]

**Missing dependencies with fallback:** none found. [VERIFIED: shell commands]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; Playwright Test 1.59.1 for browser proof. [VERIFIED: mix.exs] [VERIFIED: mailglass_admin/package.json] |
| Config file | Root `mix.exs`; `mailglass_admin/mix.exs`; `mailglass_admin/playwright.config.cjs`. [VERIFIED: file reads] |
| Quick run command | `mix verify.schema_prefix` plus `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md] |
| Full suite command | `mix verify.schema_prefix && cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --warnings-as-errors && cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"`. [VERIFIED: local files] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SCHEMA-01 | Replay projection writes target configured schema under hostile `search_path`. | integration | `mix verify.schema_prefix` | yes |
| SCHEMA-02 | Unsubscribe replay/idempotency conflict reads target configured schema under hostile `search_path`. | integration | `mix verify.schema_prefix` | yes |
| SCHEMA-03 | Raw repo/Multi callback recurrence is blocked. | static + unit | `mix verify.schema_prefix` | yes |
| SCHEMA-04 | Inbound raw repo contracts use explicit prefix/default facade. | unit/integration | `mix verify.schema_prefix` | yes |
| AAU-01 | First HTML stylesheet hrefs are mount-rooted. | ExUnit ConnTest | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` | yes |
| AAU-02 | Direct hard loads load CSS/fonts with valid responses. | Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | yes |
| AAU-03 | Alternate mount roots pass without public router options. | ExUnit + Playwright | Same AAU-01/AAU-02 commands | yes |
| AAU-04 | Browser gate asserts token-backed computed styling. | Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | yes |
| GATE-01 | Focused schema-prefix lane exists and passes. | alias smoke | `mix verify.schema_prefix` | yes |
| GATE-02 | Advisory canary/proof distinction remains documented. | source grep | `rg -n "canary|focused no-search-path|verify.schema_prefix" .github/workflows/advisory-matrix.yml .planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md` | yes |
| GATE-03 | Fast href and serialized browser proof both pass. | mixed | AAU-01/AAU-02 commands | yes |
| DOC-01 | Stale unresolved admin-asset wording removed/reconciled. | docs grep or docs-contract | `rg -n "Navigate from the dashboard|Tracked as GAP-22|hard refresh on a deep URL can load unstyled|direct loads unstyled" guides/run-the-demo.md mailglass_admin/docs/design-system.md .planning/backlog/admin-relative-asset-url-styling.md` should return no current-state stale hits | yes |
| DOC-02 | Active planning artifacts preserve deferrals. | source grep | `rg -n "broader UI verification discipline|SEED-003 ecosystem integrations|whole-suite no-search-path" .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/STATE.md` | yes |

### Sampling Rate

- **Per task commit:** Run the focused command matching the edited surface: docs grep for docs edits; `mix verify.schema_prefix` for planning gate evidence; admin ExUnit for design-system/demo copy tied to asset proof. [VERIFIED: phase scope]
- **Per wave merge:** Run `mix verify.schema_prefix`, admin ExUnit href/mount tests, token/bundle tests, and focused Playwright grep. [VERIFIED: local files]
- **Phase gate:** Create/collect Phase 140 verification evidence after all focused lanes and DOC-01/DOC-02 checks pass, then hand off to `/gsd-complete-milestone`. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md]

### Wave 0 Gaps

- [ ] Optional `test/mailglass/docs_contract_test.exs` addition if the planner chooses a permanent DOC-01 stale-phrase guard. [VERIFIED: test/mailglass/docs_contract_test.exs]
- [ ] Optional final shell grep if the planner keeps DOC-01 guard outside permanent tests. [VERIFIED: rg over docs/backlog]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct product change | Do not change admin auth/session routes; Phase 139 proof already uses existing operator login support for browser cases. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| V3 Session Management | no direct product change | Keep Playwright proof on existing `test:operator-browser` support paths; do not alter session lifecycle. [VERIFIED: mailglass_admin/e2e/admin-assets.spec.js] |
| V4 Access Control | yes, as regression boundary | Preserve alternate operator mount proof through existing macro/auth controls; do not add public router options. [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md] |
| V5 Input Validation | yes, docs/trust boundary | Docs and backlog must not overclaim behavior beyond route matrix; stale-phrase guard prevents misleading operational guidance. [VERIFIED: .planning/REQUIREMENTS.md] |
| V6 Cryptography | no | No CSRF, token, signature, or crypto behavior changes are in Phase 140 scope. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misleading docs claim fixed behavior is still broken | Repudiation / operational confusion | Reconcile public docs and backlog against Phase 139 verification; add stale-phrase check. [VERIFIED: .planning/REQUIREMENTS.md] |
| Treating advisory matrix as fail-closed proof | Tampering with trust model | Keep `mix verify.schema_prefix` as the pass/fail schema-prefix proof. [VERIFIED: .github/workflows/advisory-matrix.yml] |
| Public docs expose internals as user action | Information disclosure / support burden | Keep `MountPathHook`/`MountPath` mechanics in maintainer docs/backlog, not user troubleshooting copy. [VERIFIED: .planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md] |
| Browser proof bypasses auth controls on alternate mount | Elevation of privilege | Use existing Phase 139 route matrix and operator login setup; do not add new route macros or options. [VERIFIED: .planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md] |

## Sources

### Primary (repo-local, tool-verified)

- `.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-CONTEXT.md` - locked scope, decisions, canonical refs, docs targets, deferrals.
- `.planning/REQUIREMENTS.md` - DOC-01/DOC-02, SCHEMA, AAU, GATE traceability.
- `.planning/ROADMAP.md` - Phase 138/139/140 dependencies and closeout success criteria.
- `.planning/STATE.md` - current v2.1 position, deferrals, historical GAP-22 context.
- `.planning/PROJECT.md` - v2.1 milestone intent and scope locks.
- `.planning/phases/138-schema-prefix-no-search-path-hardening/138-VERIFICATION.md` - schema-prefix gate evidence.
- `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md` - admin asset proof evidence.
- `mix.exs` - `verify.schema_prefix` alias and preferred env.
- `.github/workflows/advisory-matrix.yml` - canary/proof distinction.
- `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs` - first-HTML href matrix.
- `mailglass_admin/e2e/admin-assets.spec.js` and `mailglass_admin/playwright.config.cjs` - browser asset proof and serialization.
- `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, `.planning/backlog/admin-relative-asset-url-styling.md` - stale DOC-01 targets.
- `CLAUDE.md` - project constraints.

### Secondary (websearch seam, not used for recommendations)

- Built-in WebSearch returned generic, non-project-specific closeout/reconciliation results; digest cached to record that local repo artifacts are the usable authority for this phase. [VERIFIED: research-store put output]

### Tertiary (LOW confidence)

- The general statement that closeout phases invite opportunistic cleanup is an assumption, retained only as a low-risk pitfall framing. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - verified from local installed versions, package manifests, and Mix deps; no new package recommendation. [VERIFIED: shell commands]
- Architecture: MEDIUM - repo-local phase artifacts and prior verifications are authoritative for this project, while the GSD classify-confidence seam returned MEDIUM for the websearch provider and LOW for local provider labels. [VERIFIED: classify-confidence seam]
- Pitfalls: MEDIUM - most are directly grounded in locked context and stale phrase inventory; one cleanup-risk framing is assumed. [VERIFIED: local files] [ASSUMED]

**Research date:** 2026-07-08
**Valid until:** 2026-07-15 for active working-tree details; rerun stale-phrase grep and focused gate commands if planning happens after further edits. [ASSUMED]
