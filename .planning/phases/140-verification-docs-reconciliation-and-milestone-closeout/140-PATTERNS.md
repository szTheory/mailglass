# Phase 140: Verification, Docs Reconciliation, and Milestone Closeout - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 10 new/modified files
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/docs/design-system.md` | documentation | transform | `mailglass_admin/docs/design-system.md` + `139-VERIFICATION.md` | exact |
| `guides/run-the-demo.md` | documentation | transform | `guides/run-the-demo.md` | exact |
| `.planning/backlog/admin-relative-asset-url-styling.md` | backlog | transform | `.planning/backlog/admin-relative-asset-url-styling.md` | exact |
| `.planning/REQUIREMENTS.md` | planning doc | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/ROADMAP.md` | planning doc | transform | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | store | event-driven | `.planning/STATE.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-VERIFICATION.md` | phase artifact | batch | `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md` | exact |
| `.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-SUMMARY.md` | phase artifact | batch | `.planning/milestones/v1.11-phases/103-verification-idempotent-closeout/103-04-SUMMARY.md` | role-match |
| `test/mailglass/docs_contract_test.exs` *(optional)* | test | file-I/O | `test/mailglass/docs_contract_test.exs` | exact |

## Pattern Assignments

### `mailglass_admin/docs/design-system.md` (documentation, transform)

**Analog:** `mailglass_admin/docs/design-system.md` plus Phase 139 proof record.

**Current stale block to replace** (`mailglass_admin/docs/design-system.md` lines 160-178):

```markdown
## Known limitations

- **Relative asset URLs + trailing slash.** The CSS/font URLs are *relative* so
  the bundle resolves under any adopter mount path. The consequence: a page is
  only styled when the relative `css-<md5>` resolves to the operator mount root
  where the asset route lives. In practice the dashboard is entered at its mount
  root and navigated in-app (live navigation keeps the stylesheet loaded), so
  this is invisible in normal use — but a **hard refresh on a deep URL can load
  unstyled**. This is the asset-serving strategy (a stable seam), independent of
  the design system; fixing it robustly is a separate change.
```

**Copy the evidence framing from** (`.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md` lines 48-54):

```markdown
| 1 | Generated stylesheet hrefs are rooted at the effective mount path for preview, scenario, error, gallery, operator, inbound, query deep-link, and alternate paths. | VERIFIED | `admin_asset_url_test.exs` defines 13 first-HTML route cases and parses exactly one root-layout stylesheet link. |
| 2 | Direct hard loads do not request CSS/fonts relative to nested LiveView paths. | VERIFIED | `admin-assets.spec.js` creates 12 independent `admin asset hard load:` Playwright cases. |
| 4 | Browser verification fails on CSS/font 404s and asserts token-backed computed styling after direct `page.goto` loads. | VERIFIED | The browser spec checks `requestfailed` and `response.status()`, not DOM readiness alone. |
```

**Implementation note:** Keep the design-system doc maintainer-facing. It may name `MountPathHook`, `MountPath`, and `Layouts.css_url/1`, but it should no longer describe hard-refresh/deep-link styling as an unresolved current limitation after Phase 139 proof.

---

### `guides/run-the-demo.md` (documentation, transform)

**Analog:** Existing troubleshooting entry style in `guides/run-the-demo.md`.

**Troubleshooting style pattern** (`guides/run-the-demo.md` lines 118-139):

```markdown
## Troubleshooting

**`Error: port is already allocated`** — another process (often a second demo)
holds 4015 or 5415. Pick a different band: `make demo MAILGLASS_DEMO_HTTP_PORT=4025
MAILGLASS_DEMO_DB_PORT=5425`.

**Health never goes green** — `make demo-logs` shows what the app is doing. The
first build legitimately takes a couple of minutes while dependencies download;
after that, a stall usually means Postgres didn't come up — `make demo-clean`
then `make demo` for a fresh start.
```

**Current stale entry to rewrite** (`guides/run-the-demo.md` lines 129-131):

```markdown
**Styles look unstyled after a hard refresh on a deep link** — a known
limitation (admin asset URLs resolve relative to the mount root). Navigate from
the dashboard rather than reloading a deep URL. Tracked as GAP-22.
```

**Required copy shape:** User-facing docs should describe observable behavior and recovery, not internal mount machinery. Use the Phase 140 context phrase shape: "Hard refreshes and direct deep links should stay styled; if they do not, run the admin asset browser proof and treat it as a regression."

---

### `.planning/backlog/admin-relative-asset-url-styling.md` (backlog, transform)

**Analog:** The same backlog seed structure.

**Status note pattern to update** (lines 3-8):

```markdown
> **Promoted 2026-07-07.** This seed is now active in v2.1 Phase 139
> (`AAU-01..04`, `GATE-03`) as "Admin asset first-load/deep-link proof." The
> selected direction is approach A, root-relative URLs computed from the effective
> mount path via the existing `MountPathHook`/`MountPath`/layout `css_url`
> mechanism.
```

**Accepted/rejected alternatives pattern** (lines 44-59):

```markdown
## Candidate approaches

- [x] **A — Root-relative anchored asset URL.** Compute the asset path from the
  request/mount path at render time ... **Selected for v2.1 Phase 139.**
- [ ] **B — Emit asset routes at the `/inbound` sub-scope too**
- [ ] **C — `<base href>` in the root layout**
- [ ] **D — Canonicalize the URL**
```

**Acceptance checklist to close** (lines 60-73):

```markdown
## Acceptance

- [ ] **AAU-01** — Loading the operator dashboard at its canonical adopter URL
- [ ] **AAU-02** — Hard refresh on `/inbound` ...
- [ ] **AAU-03** — Works under an arbitrary adopter mount path ...
- [ ] **AAU-04** — A browser-evidence assertion ...
- [ ] **AAU-05** — Asset-URL behavior documented in
  `mailglass_admin/docs/design-system.md` is updated once the fix lands.
```

**Implementation note:** Mark Phase 139 as the resolution point, check off AAU acceptance items supported by `139-VERIFICATION.md`, and preserve approaches B-D as rejected primary fixes.

---

### `.planning/REQUIREMENTS.md` (planning doc, transform)

**Analog:** Existing requirement and traceability rows.

**DOC requirement pattern** (lines 57-64):

```markdown
### DOC - Documentation and planning reconciliation

- [ ] **DOC-01**: `mailglass_admin/docs/design-system.md`, `guides/run-the-demo.md`, and the admin
  relative-asset backlog item no longer claim hard-refresh/deep-link styling remains unresolved after the
  proof passes.

- [ ] **DOC-02**: Active planning artifacts keep broader UI verification discipline and ecosystem
  integrations explicitly deferred so v2.1 stays a narrow hardening milestone.
```

**Traceability update pattern** (lines 95-111):

```markdown
| REQ-ID | Phase | Status |
|--------|-------|--------|
| GATE-03 | Phase 139 | Complete |
| DOC-01 | Phase 140 | Pending |
| DOC-02 | Phase 140 | Pending |
```

**Implementation note:** Flip only DOC-01/DOC-02 and "last updated" after the docs/backlog and deferral checks pass. Do not reopen completed SCHEMA/AAU/GATE rows.

---

### `.planning/ROADMAP.md` (planning doc, transform)

**Analog:** Current active phase row and phase details.

**Active phase status row** (lines 53-57):

```markdown
- [ ] **Phase 140: Verification, docs reconciliation, and milestone closeout** - Run the focused gates,
  reconcile stale docs/backlog text, verify deferrals remain explicit, and prepare the milestone for audit
  and archive. **Requirements:** DOC-01, DOC-02, plus all open gate requirements. **Success:** docs no
  longer describe the admin asset issue as unresolved after proof, v2.1 artifacts stay narrow, and the
  milestone is ready for `/gsd-complete-milestone`.
```

**Success-criteria pattern** (lines 139-158):

```markdown
### Phase 140: Verification, docs reconciliation, and milestone closeout

**Goal:** Confirm the focused gates are trustworthy, update stale docs/backlog statements, keep deferred
scope explicit, and prepare v2.1 for audit/archive.
**Depends on:** Phases 138 and 139.
**Requirements:** DOC-01, DOC-02, all gate requirements
**Plans:** TBD by `/gsd-plan-phase 140`
```

**Implementation note:** Update the Phase 140 checkbox and plans count only after the phase work completes. Preserve the deferral wording at lines 34-37 and success criterion 3 at lines 153-154.

---

### `.planning/STATE.md` (store, event-driven)

**Analog:** Current position plus append-only decision log.

**Current-position pattern** (lines 26-31):

```markdown
## Current Position

Phase: 140
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-08
```

**Decision-log append pattern** (lines 257-270):

```markdown
- [Phase 138-04]: Expose Phase 138 proof as mix verify.schema_prefix, a focused lane rather than a full dual-schema matrix or full-suite alias.
- [Phase 139-02]: Kept browser asset robustness proof in a focused Playwright spec under the existing serialized operator browser gate.
- [Phase 139-02]: Production asset routing, CSS, tokens, HEEx markup, package versions, and router macro APIs stayed unchanged; proof only.
```

**Deferral surface to preserve** (lines 438-442):

```markdown
- **Remove the cowlib advisory allowlist when upstream fixes** ...
- **Run the UI browser/persona gate during phases, not only at release** ...
```

**Implementation note:** Add Phase 140 truth in current sections and decision log. Do not rewrite old v1.7 GAP-22 history unless it is explicitly presented as current truth.

---

### `.planning/PROJECT.md` (config, transform)

**Analog:** Current milestone and state blocks.

**Current milestone pattern** (lines 11-48):

```markdown
## Current Milestone: v2.1 Postgres + Admin URL Hardening (OPENED 2026-07-07)

**Goal:** Make schema-isolated runtime paths and admin first-load asset URLs fail closed and prove them
with focused gates, without adding product capability or redesigning the admin UI.

**Target features (dependency-ordered, smallest safe surface first):**
- **Verification, docs, and backlog reconciliation (Phase 140)** - wire focused gates, keep the broad
  dual-schema advisory matrix as a canary, update stale docs/backlog that still describe the admin
  deep-link asset issue as unresolved, and close the milestone.
```

**Current-state line to reconcile if edited** (lines 140-144):

```markdown
**v2.1 IN PROGRESS 2026-07-07 - Postgres + Admin URL Hardening.** Phase 138 is complete and verified:
focused no-search-path schema-prefix hardening now has hostile runtime proof, raw-repo/static guard
coverage, and a green `mix verify.schema_prefix` lane. Phase 139 is next for admin asset URL hard-refresh
proof, followed by Phase 140 verification/docs closeout.
```

**Footer pattern** (line 721):

```markdown
*Last updated: 2026-07-07 - **v2.1 Phase 138 complete** ... Phase 139 admin first-load/deep-link asset URL proof next; broader UI verification discipline and ecosystem integrations deferred.*
```

**Implementation note:** If PROJECT is touched, reconcile Phase 139 from "next" to proven and Phase 140 to closeout status. Keep scope locks unchanged.

---

### `.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-VERIFICATION.md` (phase artifact, batch)

**Analog:** `.planning/phases/139-admin-asset-first-load-deep-link-proof/139-VERIFICATION.md`

**Frontmatter pattern** (lines 1-34):

```markdown
---
phase: 139-admin-asset-first-load-deep-link-proof
verified: 2026-07-08T13:49:23Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirement_coverage:
  - id: AAU-01
    status: satisfied
    evidence: "First-HTML href matrix ... passed ..."
automated_checks:
  - command: "cd mailglass_admin && MIX_ENV=test mix test ..."
    result: "PASS - 21 tests, 0 failures"
human_verification: []
next_action: "Proceed to Phase 140 documentation/reconciliation; no Phase 139 gaps found."
---
```

**Behavioral spot-check table** (lines 89-99):

```markdown
| Behavior | Command | Result | Status |
|---|---|---|---|
| Fast first-HTML href and mount-path proof | `cd mailglass_admin && MIX_ENV=test mix test ...` | 21 tests, 0 failures | PASS |
| Serialized direct browser hard-load proof | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | 12 Playwright tests, 0 failures | PASS |
| Bundle drift after browser rebuild | `git diff -- mailglass_admin/priv/static/app.css ...` | No diff | PASS |
```

**Requirements coverage pattern** (lines 105-115):

```markdown
| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| AAU-01 | 139-01 | First HTML emits current-mount rooted stylesheet hrefs ... | SATISFIED | `admin_asset_url_test.exs` route matrix and 21-test ExUnit pass. |
```

**Implementation note:** For Phase 140, include DOC-01, DOC-02, SCHEMA/GATE rerun evidence, admin ExUnit/browser rerun evidence, stale-phrase grep result, and deferral grep result. Keep `human_verification: []` if all claims are automated.

---

### `.planning/phases/140-verification-docs-reconciliation-and-milestone-closeout/140-SUMMARY.md` (phase artifact, batch)

**Analog:** `.planning/milestones/v1.11-phases/103-verification-idempotent-closeout/103-04-SUMMARY.md`

**Frontmatter and tracking pattern** (lines 1-51):

```markdown
---
phase: 103-verification-idempotent-closeout
plan: "04"
subsystem: milestone-closeout
tags: [milestone-audit, verification, closeout, gsd-audit-milestone]

requires:
  - phase: 103-03
    provides: All-gates verification battery green; prepare-only ceremony verified
provides:
  - Phase 103 VERIFICATION.md (gates-complete proof for Phase 103 closeout)
affects:
  - .planning/phases/103-verification-idempotent-closeout/103-VERIFICATION.md (created)
---
```

**Accomplishment and gate pattern** (lines 65-81):

```markdown
## Accomplishments

- Confirmed all D-15 prerequisites satisfied: zero open GAP rows, ratchet armed, gates green (Plans 01-03)
- Created `103-VERIFICATION.md` as Phase 103's final verification artifact ...

## Prerequisite Gate Check (D-15 Ordering)

| Gate | Check | Result |
|------|-------|--------|
| 103-VERIFICATION.md exists | `ls .planning/phases/103-*/103-VERIFICATION.md` | PASS |
```

**Closeout self-check pattern** (lines 140-147):

```markdown
## Self-Check: PASSED

- FOUND: `.planning/phases/103-verification-idempotent-closeout/103-VERIFICATION.md`
- Audit status confirmed: `grep 'status: passed' .planning/v1.11-MILESTONE-AUDIT.md` returns match
```

**Implementation note:** Phase 140 summary should not archive the milestone itself. It should say the milestone is ready for `/gsd-complete-milestone`.

---

### `test/mailglass/docs_contract_test.exs` *(optional)* (test, file-I/O)

**Analog:** Existing docs-contract test module.

**Imports and module pattern** (lines 1-3):

```elixir
defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers
```

**File read + assert/refute pattern** (lines 170-207):

```elixir
test "migration-from-swoosh opens with the value-prop pitch before subordinate framing" do
  migration = File.read!("guides/migration-from-swoosh.md")

  value_prop_keywords = [
    "transport",
    "framework layer",
    "preview",
    "webhooks",
    "audit",
    "suppressions",
    "multi-tenancy"
  ]

  for kw <- value_prop_keywords do
    assert migration =~ kw,
           "migration-from-swoosh.md is missing value-prop keyword: #{inspect(kw)}"
  end

  refute migration =~ "~> 0.3", "migration-from-swoosh.md still contains stale ~> 0.3 pin"
end
```

**Cross-file docs assertion pattern** (lines 321-341):

```elixir
test "compatibility and upgrade guides are wired into Tier 1 docs" do
  compatibility = File.read!("guides/compatibility-and-deprecations.md")
  upgrade = File.read!("guides/upgrading-to-v1_0.md")
  testing = File.read!("guides/testing.md")
  trust_doc = File.read!("mailglass_admin/docs/operator-trust.md")
  docs_check = File.read!("lib/mix/tasks/mailglass.docs.check.ex")

  assert compatibility =~ "stable lane"
  assert docs_check =~ "\"guides/testing.md\""
  assert docs_check =~ "\"mailglass_admin/docs/operator-trust.md\""
end
```

**Implementation note:** Add a permanent stale-phrase guard only if it stays narrow. Otherwise record the one-time `rg` stale-phrase check in `140-VERIFICATION.md`.

## Shared Patterns

### Focused Schema-Prefix Gate

**Source:** `mix.exs`
**Apply to:** Phase 140 verification report and closeout summary.

**Preferred env registration** (lines 75-83):

```elixir
"verify.docs.contract": :test,
"verify.docs.contract.inbound": :test,
"verify.docs.migration": :test,
"verify.schema_prefix": :test
```

**Alias body** (lines 313-318):

```elixir
"verify.schema_prefix": [
  "test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix --warnings-as-errors",
  "cmd mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs --warnings-as-errors",
  "credo --strict",
  "cmd --cd mailglass_inbound mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors"
],
```

### Advisory Matrix Is A Canary

**Source:** `.github/workflows/advisory-matrix.yml`
**Apply to:** `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `140-VERIFICATION.md`.

**Core canary comment** (lines 105-111):

```yaml
# Phase 138 GATE-02: this dual-schema full-suite job is a broad canary,
# not the fail-closed proof for schema-prefix correctness. The test
# harness aligns Config.schema/0 with MAILGLASS_SCHEMA and also puts the
# matrix schema on the connection search_path, so search_path-dependent
# runtime calls can still pass here. The focused no-search-path proof is
# `mix verify.schema_prefix`, which runs hostile runtime tests plus the
# raw-repo prefix guard and strict Credo.
```

**Focused proof step** (lines 122-125):

```yaml
- name: Run focused schema-prefix proof
  env:
    MAILGLASS_SCHEMA: ${{ matrix.schema }}
  run: mix verify.schema_prefix
```

### Admin First-HTML Href Proof

**Source:** `mailglass_admin/test/mailglass_admin/admin_asset_url_test.exs`
**Apply to:** Verification evidence and docs truth claims.

**Route matrix pattern** (lines 14-94):

```elixir
@route_cases [
  %{
    name: "preview index",
    path: "/dev/mail",
    mount_root: "/dev/mail",
    access: :public
  },
  %{
    name: "alternate inbound query deep link",
    path: "/secure/console/inbound?tenant_id=test-tenant&provider=ses",
    mount_root: "/secure/console",
    access: :operator
  }
]
```

**Assertion pattern** (lines 168-204):

```elixir
defp assert_stylesheet_href_rooted!(href, mount_root, path) do
  expected = Path.join(mount_root, "css-#{MailglassAdmin.Controllers.Assets.css_hash()}")

  assert href == expected,
         "expected #{path} to emit stylesheet href #{expected}, got #{inspect(href)}"

  refute String.starts_with?(href, "css-"),
         "stylesheet href must not be bare relative, got #{inspect(href)}"
end
```

### Admin Browser Asset Proof

**Source:** `mailglass_admin/package.json`, `mailglass_admin/e2e/admin-assets.spec.js`
**Apply to:** Verification evidence, demo docs recovery guidance.

**Serialized script** (`mailglass_admin/package.json` lines 4-6):

```json
"scripts": {
  "test:operator-browser": "mix mailglass_admin.assets.build && playwright test --config=playwright.config.cjs --workers=1"
}
```

**Network response proof** (`mailglass_admin/e2e/admin-assets.spec.js` lines 196-275):

```javascript
function collectAssetResponses(page, expectedMountRoot) {
  const failures = [];
  const responses = [];
  const responseTasks = [];

  const onRequestFailed = request => {
    if (!isTrackedAssetRequest(request)) return;
    failures.push({ type: request.resourceType(), url: request.url() });
  };

  return {
    async assert(routeCase) {
      await Promise.all(responseTasks);
      expect(failures, `${routeCase.name} stylesheet/font request failures`).toEqual([]);
      const stylesheetResponses = responses.filter(response => response.type === "stylesheet");
      const fontResponses = responses.filter(response => response.type === "font");
      expect(stylesheetResponses.length).toBeGreaterThan(0);
      expect(fontResponses.length).toBeGreaterThan(0);
    }
  };
}
```

**Looped direct-load cases** (`mailglass_admin/e2e/admin-assets.spec.js` lines 361-367):

```javascript
test.describe("admin asset hard loads", () => {
  for (const routeCase of routeCases) {
    test(`admin asset hard load: ${routeCase.name}`, async ({ page }) => {
      await assertDirectAssetLoad(page, routeCase);
    });
  }
});
```

### Docs Contract Assertions

**Source:** `test/mailglass/docs_contract_test.exs`
**Apply to:** Optional permanent stale-phrase guard.

Use simple `File.read!/1` plus `assert`/`refute` checks with explicit failure messages. Keep this in `describe "Guide contracts"` unless the planner chooses a one-time `rg` verification instead.

### Scope And Deferral Preservation

**Source:** `.planning/REQUIREMENTS.md`
**Apply to:** All planning docs and verification artifacts.

**Out-of-scope lines to preserve** (lines 68-91):

```markdown
- New providers, transports, routes, public product capabilities, or release ceremony.
- Admin redesign, brand refresh, token changes, component changes, layout changes, or motion work.
- Screenshot/pixel-diff visual gating. Browser proof is network + computed-style based.
- SEED-003 ecosystem integrations, Cloudflare routing, synthetic inbound dev UI, `gen_smtp`, or additional
  provider work.

## Future Requirements (deferred, not this milestone)

- Broader UI verification discipline after v2.1, including any full admin visual/a11y sweep the maintainer
  chooses to run.
- A whole-suite no-search-path fixture cleanup if the focused lane exposes broader systemic drift.
- Ecosystem integrations only with real adopter pull.
```

## No Analog Found

All expected Phase 140 files have close analogs in the current codebase or planning corpus.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | - |

## Metadata

**Analog search scope:** `mailglass_admin/docs`, `guides`, `.planning/backlog`, `.planning/{REQUIREMENTS,ROADMAP,STATE,PROJECT}.md`, `.planning/phases/138-*`, `.planning/phases/139-*`, `.planning/milestones/v1.11-phases/103-*`, `test/mailglass`, `mailglass_admin/test`, `mailglass_admin/e2e`, `mix.exs`, `.github/workflows/advisory-matrix.yml`
**Files scanned:** 20 focused files plus targeted `rg` searches over planning/docs/test surfaces
**Pattern extraction date:** 2026-07-08
