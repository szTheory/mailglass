# Phase 37: Contract Enforcement and Trust Docs - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/testing.md` | documentation | informational | `guides/compatibility-and-deprecations.md`, `guides/operator-incident-support.md` | role-match |
| canonical admin trust doc (`guides/admin-trust.md` or package-local equivalent) | documentation | informational | `guides/operator-incident-support.md`, `mailglass_admin/docs/api_stability.md` | role-match |
| `mailglass_admin/README.md` | documentation | informational | existing `mailglass_admin/README.md` | exact |
| `mailglass_admin/docs/api_stability.md` | documentation | informational | existing `mailglass_admin/docs/api_stability.md` | exact |
| `guides/operator-incident-support.md` | documentation | informational | existing `guides/operator-incident-support.md` | exact |
| `lib/mix/tasks/mailglass.docs.check.ex` | task | batch | existing `lib/mix/tasks/mailglass.docs.check.ex` | exact |
| `lib/mix/tasks/mailglass.stability.check.ex` | task | batch | existing `lib/mix/tasks/mailglass.stability.check.ex` | exact |
| `mix.exs` | config | batch | existing `mix.exs` | exact |
| `scripts/verify_support_contract.sh` | utility | batch | existing `scripts/verify_support_contract.sh` | exact |
| `mailglass_admin/mix.exs` | config | batch | existing `mailglass_admin/mix.exs` | exact |
| `test/mailglass/docs_contract_test.exs` | test | contract | existing `test/mailglass/docs_contract_test.exs` | exact |
| new root trust-contract proof test (`test/mailglass/*trust*_test.exs` or similar) | test | contract | `test/mailglass/compatibility_contract_test.exs`, `test/mailglass/docs_migration_smoke_test.exs` | role-match |
| `test/mailglass/test_assertions_test.exs` | test | contract | existing `test/mailglass/test_assertions_test.exs` | exact |
| `test/mailglass/mailer_case_test.exs` | test | contract | existing `test/mailglass/mailer_case_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test | contract | existing `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | exact |

## Pattern Assignments

### Canonical guide plus pointer model

**Analogs:** `guides/compatibility-and-deprecations.md`, `guides/operator-incident-support.md`, `README.md`

**Observed pattern**
- One canonical guide carries the full contract.
- Tier 1 docs and READMEs point to that guide instead of duplicating policy.
- Docs checks assert required tokens and reject stale or conflicting story text.

**Planner guidance**
- Treat `guides/testing.md` as the canonical testing contract.
- Add one canonical admin trust doc rather than splitting the stable story across README and API inventory prose.
- Update README/API-stability pointer surfaces to point outward while staying narrowly inventory-shaped.

### Lightweight semantic enforcement

**Analogs:** `lib/mix/tasks/mailglass.docs.check.ex`, `lib/mix/tasks/mailglass.stability.check.ex`, `scripts/verify_support_contract.sh`

**Observed pattern**
- Mix tasks do targeted checks with explicit error messages.
- The root script composes existing package-local verification commands.
- No manifest snapshots or broad ABI scanners are used.

**Planner guidance**
- Reuse this style for Phase 37 proof wiring.
- Add exact-token checks and trust-doc assertions rather than generalized export scanning.
- Keep failure text seam-specific and maintainable.

### Compiled-doc and contract-test proof

**Analogs:** `test/mailglass/docs_contract_test.exs`, `test/mailglass/compatibility_contract_test.exs`, `test/mailglass/docs_migration_smoke_test.exs`

**Observed pattern**
- Contract tests assert canonical docs contain required phrases and references.
- Proof tests are deterministic, docs-driven, and release-blocking.
- They validate contract promises without adding runtime machinery.

**Planner guidance**
- Add one Phase 37 root proof test for the semantic stability workflow and trust-doc inventory.
- Extend docs contract tests instead of inventing a second assertion framework.

### Testing-helper truth comes from shipped semantics

**Analogs:** `lib/mailglass/test_assertions.ex`, `test/support/mailer_case.ex`, `test/support/oban_helpers.ex`, `test/mailglass/test_assertions_test.exs`, `test/mailglass/mailer_case_test.exs`

**Observed pattern**
- Public helper docs and module docs already define the intended semantics.
- Tests prove details such as mailbox-vs-storage behavior, async/process ownership, and Oban mode constraints.

**Planner guidance**
- Any testing-guide rewrite should be verified against these exact files.
- Prefer doc corrections and targeted proof tests before changing helper behavior.

### Stable seam, internal UI freedom for admin

**Analogs:** `mailglass_admin/README.md`, `mailglass_admin/lib/mailglass_admin/router.ex`, `mailglass_admin/lib/mailglass_admin/auth.ex`, `guides/operator-incident-support.md`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`

**Observed pattern**
- Stable admin promises are semantic: router macros, auth seam, session contract, authorization timing, replay outcomes.
- Internal UI details are explicitly excluded from the contract.
- Replay and reconcile are documented separately already.

**Planner guidance**
- Keep the admin trust doc semantic and seam-centered.
- Reuse `operator_live_test.exs`, router tests, and auth tests as proof surfaces rather than inventing UI-shape tests.

## Read-First Source Files

- `lib/mix/tasks/mailglass.docs.check.ex`
- `lib/mix/tasks/mailglass.stability.check.ex`
- `scripts/verify_support_contract.sh`
- `mix.exs`
- `mailglass_admin/mix.exs`
- `guides/testing.md`
- `lib/mailglass/test_assertions.ex`
- `test/support/mailer_case.ex`
- `test/support/oban_helpers.ex`
- `mailglass_admin/README.md`
- `mailglass_admin/lib/mailglass_admin/router.ex`
- `mailglass_admin/lib/mailglass_admin/auth.ex`
- `guides/operator-incident-support.md`
- `test/mailglass/docs_contract_test.exs`
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs`

## Anti-Patterns to Avoid

- Creating a heavy snapshot/export-diff tool instead of composing existing proof lanes.
- Writing docs that restate code behavior loosely enough to drift from the actual helper semantics.
- Using DOM/component assertions as proof of admin contract stability.
- Naming a new root proof command without wiring the trust-doc assertions into it.
