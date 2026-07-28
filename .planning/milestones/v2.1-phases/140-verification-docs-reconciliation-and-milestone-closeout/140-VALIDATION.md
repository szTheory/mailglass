---
phase: 140
slug: verification-docs-reconciliation-and-milestone-closeout
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-08
---

# Phase 140 - Validation Strategy

> Per-phase validation contract for focused verification, docs reconciliation, and milestone closeout readiness.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix; Playwright Test 1.59.1 for admin browser proof; ripgrep for docs drift checks |
| **Config file** | Root `mix.exs`; `mailglass_admin/mix.exs`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `mix verify.schema_prefix && cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` |
| **Full suite command** | `mix verify.schema_prefix && cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --warnings-as-errors && npm run test:operator-browser -- --grep "admin asset hard load"` |
| **Estimated runtime** | ~3-8 minutes, dominated by database-backed Mix verification and Playwright |

---

## Sampling Rate

- **After every docs/backlog task commit:** Run the stale phrase grep for DOC-01 targets.
- **After every planning-artifact task commit:** Run the DOC-02 deferral grep across ROADMAP, REQUIREMENTS, PROJECT, and STATE.
- **After every verification-gate task commit:** Run the specific focused gate changed or cited by the task.
- **After every plan wave:** Run the full suite command.
- **Before `/gsd:verify-work`:** Full suite and DOC-01/DOC-02 drift checks must be green.
- **Max feedback latency:** one task commit between automated checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 140-01-01 | 140-01 | 1 | SCHEMA-01..04, GATE-01 | T-140-01 | Focused schema-prefix proof remains fail-closed under hostile no-search-path conditions | integration/static | `mix verify.schema_prefix` | yes | green |
| 140-01-02 | 140-01 | 1 | AAU-01, AAU-03, GATE-03 | T-140-02 | First HTML uses mount-rooted admin asset hrefs across route matrix | ExUnit ConnTest | `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` | yes | green |
| 140-01-03 | 140-01 | 1 | AAU-02, AAU-04, GATE-03 | T-140-03 | Direct hard loads fetch CSS/fonts and retain token-backed computed styling | Playwright | `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | yes | green |
| 140-01-04 | 140-02 | 1 | DOC-01 | T-140-04 | Public and maintainer docs no longer describe the verified admin hard-refresh behavior as currently unresolved | docs grep or docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | yes | green |
| 140-01-05 | 140-03 | 1 | DOC-02 | T-140-05 | Active planning artifacts preserve future-scope deferrals without promoting unrelated work into v2.1 closeout | source grep | `rg -n "broader UI verification discipline|SEED-003 ecosystem integrations|whole-suite no-search-path" .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/STATE.md` | yes | green |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

Optional hardening if the planner chooses it:

- [x] Add a narrow docs-contract assertion for DOC-01 stale phrases in `test/mailglass/docs_contract_test.exs`.

---

## Manual-Only Verifications

All phase behaviors have automated or source-grep verification. Milestone archive itself remains manual/lifecycle work after Phase 140 and belongs to `/gsd-complete-milestone`, not this phase plan.

---

## Validation Sign-Off

- [x] All tasks have an automated or source-grep verification path
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency bounded to one task commit
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete

## Validation Audit 2026-07-08

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 5 |
| Escalated | 0 |

Phase 140's validation strategy was audited during v2.1 milestone closeout after the closeout verification report existed. No new tests were required: `140-VERIFICATION.md` records all schema-prefix, admin asset, docs-contract, and planning-deferral commands green, with 13/13 requirements satisfied.
