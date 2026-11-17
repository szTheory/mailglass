---
phase: "180"
slug: reproducible-admin-bundle-and-before-catalog
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-14"
---

# Phase 180 — Validation Strategy

> Audit result: BRPIPE-01, BRPIPE-02, and BRPIPE-03 have existing behavioral tests with phase-completion execution evidence. The former Wave 0 checklist was stale: its tests and support files are present. No uncovered machine-checkable behavior remained, so this audit added no tests.
>
> Coverage sign-off does not mean every current project lane is green. The current Admin alias evidence supplied for this audit contains one FaviconCatalogTest producer-SHA mismatch. That failure is preserved as an evidence limitation; this audit did not rerun the alias or recapture/rewrite favicon evidence. See Current Audit Evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit in mailglass_admin; Playwright 1.59.1 for advisory browser checks |
| Config | mailglass_admin/mix.exs aliases; mailglass_admin/playwright.config.cjs; reference/demo_app/assets/playwright.catalog.config.cjs |
| Required lane | cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin |
| Bundle contract | cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/bundle_reproducibility_contract_test.exs --warnings-as-errors --seed 0 |
| Theme ownership contracts | cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/root_theme_ownership_contract_test.exs test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/router_test.exs --warnings-as-errors --seed 0 |
| Catalog contract | cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/before_catalog_manifest_test.exs --warnings-as-errors --seed 0 |
| Browser, advisory | cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npx playwright test --config=playwright.config.cjs --workers=1 e2e/theme-ownership.spec.js |
| Toolchain | ASDF_ERLANG_VERSION=27.3.4.15 and ASDF_ELIXIR_VERSION=1.18.4-otp-27 for Mix commands |

Only support_contract_admin is required evidence for the ExUnit contracts. The browser suites and catalog capture run are advisory or one-shot evidence; neither replaces the required-lane tests.

---

## Per-Requirement Verification Map

| Requirement | Observable behavior | Test type | Automated command / artifact | Lane | Audit status |
|-------------|---------------------|-----------|------------------------------|------|--------------|
| BRPIPE-01 | Fresh pinned Tailwind build matches committed app.css; byte drift, truncation, missing output, source drift, bad wiring, or installer failure is rejected | Integration + hermetic unit | Bundle command above; mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs | REQUIRED | COVERED — 26 tests passed at phase completion; mutation cases were shown red and restored green. |
| BRPIPE-01 | Required alias begins with --check and CI wires that alias into ci_green | Static contract | Same bundle contract file; cd mailglass_admin && mix verify.support_contract.admin | REQUIRED | COVERED — wiring assertions and cold-start lane evidence are in 180-01-SUMMARY.md. |
| BRPIPE-01 | Official ubuntu-latest runner produces identical committed bytes | CI environment | First support_contract_admin run on the phase PR; record run ID and the bundle check line | REQUIRED external observation | PENDING — the phase summaries record emulated linux/amd64 byte equality, but no ubuntu-latest run result was supplied or observed in this audit. |
| BRPIPE-02 | Root html owns data-theme; nested theme attributes and local color-token redeclarations are rejected; shell and preview state render without nested ownership | Static + LiveView | Theme contract command above; mailglass_admin/test/mailglass_admin/operator_live_test.exs and inbound_live_test.exs are part of the required support lane | REQUIRED | COVERED — the root ownership contract had 23 passing tests and mutation evidence; phase summaries record the required lane green at completion. |
| BRPIPE-02 | Computed theme tokens follow the html element across the cookie × OS matrix | Browser | mailglass_admin/e2e/theme-ownership.spec.js | ADVISORY | COVERED historically — 37 browser cases passed in 180-03-SUMMARY.md; this audit did not run a browser check and makes no claim about current rendered output. |
| BRPIPE-03 | Catalog schema, content hashes, file allowlist, source binding, budgets, privacy rules, and seeded-case stop line are checked | Hermetic unit | Catalog command above; mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs | REQUIRED | COVERED — 48 tests passed, the catalog evaluated LIVE, and recorded mutation cases were red before restoration. |
| BRPIPE-03 | Capture refuses dirty/stale inputs, checks served bytes and determinism, and promotes only validated output | Script / one-shot integration | reference/demo_app/assets/catalog/capture-before-catalog.cjs and before-catalog.spec.js | One-shot; not CI | COVERED historically — the final run reported 82 Playwright tests passed and promoted 80 captures. No capture was run during this audit. |

### Phase Artifacts Present

The tests and support files listed by the original Wave 0 checklist exist:

- mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs
- mailglass_admin/test/mailglass_admin/root_theme_ownership_contract_test.exs
- mailglass_admin/test/mailglass_admin/before_catalog_manifest_test.exs
- mailglass_admin/e2e/theme-ownership.spec.js
- mailglass_admin/dev/mailglass_admin/assets_check.ex
- reference/demo_app/lib/mailglass_demo/catalog_seed.ex
- reference/demo_app/assets/catalog/before-catalog.spec.js
- reference/demo_app/assets/catalog/capture-before-catalog.cjs
- reference/demo_app/assets/playwright.catalog.config.cjs

---

## Mutation Evidence

The phase summaries record negative controls for every required contract family, then restoration and green reruns:

- BRPIPE-01: byte flips, truncation, deletion, source-side drift, removed prose exclusion, alias wiring changes, and installer failure.
- BRPIPE-02: nested data-theme attributes, color-token redeclarations, preview iframe sandbox changes, and removed frame state marker.
- BRPIPE-03: modified PNG bytes, unlisted files, dirty manifests, budget violations, stale source markers, and seeded-case stop-line violations.

These are behavioral tests and failure-path checks, not file-existence assertions alone.

---

## Historical Phase-Completion Evidence

The following results are from the phase execution records, not fresh browser or lane output from this audit:

| Plan | Recorded result |
|------|-----------------|
| 180-01 | Bundle contract: 26 tests, 0 failures. Empty-build-path required lane: 1318 tests, 0 failures, 1 excluded. Emulated linux/amd64 Tailwind binary matched the committed bundle. |
| 180-02 | Root theme contract: 23 tests, 0 failures. Required lane: 1341 tests, 0 failures, 1 excluded. |
| 180-03 | Theme ownership browser spec: 37 passed. Its browser lane was advisory; the required proof remained in support_contract_admin. |
| 180-04 | Manifest contract: 48 tests, 0 failures; catalog LIVE. Final catalog run: 82 Playwright tests passed, 80 captures promoted. Required lane: 1389 tests, 0 failures, 1 excluded. |

See 180-01-SUMMARY.md through 180-04-SUMMARY.md for commands, mutation details, and recorded caveats.

---

## Current Audit Evidence

Results below were supplied from the 2026-11-17 run. The full Admin alias was not rerun during this audit.

| Check | Reported result | Scope and limitation |
|-------|-----------------|----------------------|
| Storybook/evidence contracts | 42 passed | Contract result only; no browser output is inferred. |
| Core contracts | 82 passed | Contract result only. |
| Inbound deterministic suite | 481 passed; 3 properties excluded | Exclusions remain recorded; they are not counted as passed properties. |
| Focused rendering checks | Delivery badge sizing and mobile card spacing passed | No unseen browser rendering or screenshot result is claimed. |
| Admin support alias | Reached ExUnit and reported 1824 tests, 1 failure | Sole failure: FaviconCatalogTest found that the existing favicon-299c1aa-20261116T231912Z producer SHA differs from the current file. Preserve this as an evidence limitation; do not recapture or rewrite favicon evidence. The alias result is not green, and this failure is not classified as a Phase 180 implementation defect. |

No additional browser suite or catalog capture was run during this audit; the focused rendering checks above are separately reported as passed.

---

## External Evidence and Limits

- The real ubuntu-latest byte-equality run remains unobserved in the evidence supplied for this audit. The historical linux/amd64 emulation result does not substitute for that CI record.
- Browser output in the map is explicitly historical and advisory. No current browser result is claimed.
- The current favicon producer/file SHA mismatch remains an evidence stop. Resolving it requires a separate authorized evidence decision; this audit preserves the mismatch and does not recapture or rewrite its artifact.
- The before-catalog artifact remains unchanged. Its established constraints and Phase 181 hand-off are documented in 180-04-SUMMARY.md.

---

## Validation Sign-Off

- [x] All BRPIPE-01 through BRPIPE-03 behaviors map to existing automated tests or recorded one-shot checks.
- [x] All original Wave 0 tests and support files are present.
- [x] Existing mutation evidence covers the negative paths recorded by the plans.
- [x] Advisory browser evidence is distinguished from required-lane proof.
- [x] nyquist_compliant: true — no uncovered Phase 180 test behavior was found.
- [ ] Real ubuntu-latest byte-equality run ID recorded — post-PR evidence remains pending.
- [ ] Current Admin alias green — not established; the supplied run stopped on the preserved favicon SHA evidence mismatch.

**Approval:** Nyquist coverage audit complete; the two open evidence rows above remain explicit.

## Validation Audit 2026-11-17

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
