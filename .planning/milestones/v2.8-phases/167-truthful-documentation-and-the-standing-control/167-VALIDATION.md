---
phase: 167
slug: truthful-documentation-and-the-standing-control
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-17
---

# Phase 167 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `167-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4-otp-27, per `.tool-versions`) |
| **Config file** | `mix.exs` (root), `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs` — no separate ExUnit config file |
| **Quick run command** | `mix test test/mailglass/docs_contract_test.exs test/mailglass/config_test.exs test/mailglass/mailable_test.exs` |
| **Full suite command** | `mix verify.support_contract.core` (root alias, `mix.exs:323-329`; the required `support_contract_core` CI lane, `ci.yml:224-225`) |
| **Estimated runtime** | ~15s targeted / ~3–5 min full core suite |

**Local toolchain prerequisite** (project memory — the tracked `.tool-versions` pins versions not
installed locally; bare `mix` fails as a misleading `corrupt atom table`):

```
export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27
```

The tracked `.tool-versions` is the correct CI contract — do not "fix" it.

---

## Sampling Rate

- **After every task commit:** Run the quick run command above
- **After every plan wave:** Run `mix verify.support_contract.core`
- **Before `/gsd-verify-work`:** Full core suite green, **plus** a `grep` sweep confirming no stale
  string from the `167-RESEARCH.md` Defect Ledger survives anywhere in the tree — this mirrors exit
  criterion 6's own phrasing ("`grep` for the corrected doc claims returns nothing")
- **Max feedback latency:** ~15 seconds (targeted), ~5 minutes (full core suite)

---

## Per-Task Verification Map

> Populated per task at plan time. Rows below are the requirement-level contract the planner's tasks
> must each map onto.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-01-T1–T3 | 01 | 1 | DOCS-03 | — | Correct release mechanics and close-out runbook remain pinned | unit (derived/source-text) | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ `docs_contract_test.exs` | ✅ green |
| 167-02-T1 | 02 | 2 | DOCS-02 | — | CLAUDE.md describes the live release path | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ `docs_contract_test.exs` | ✅ green |
| 167-02-T2 | 02 | 2 | DOCS-06 | — | Upgrade guide stays discoverable and changelog remains additive | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ `docs_contract_test.exs` | ✅ green |
| 167-03-T1 | 03 | 3 | DOCS-04 | — | Migration pins derive from manifests and release-time sync | unit + YAML structure | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ `docs_contract_test.exs` | ✅ green |
| 167-03-T2–T3 | 03 | 3 | DOCS-05 | — | `:none` config is rejected; code-adjacent docs track source | unit | `mix test test/mailglass/config_test.exs test/mailglass/docs_contract_test.exs test/mailglass/mailable_test.exs --warnings-as-errors` | ✅ focused tests | ✅ green |
| 167-04-T1–T2 | 04 | 1 | DOCS-01 | — | STATE facts are structurally pinned and live audit cannot misattribute colliding IDs | unit + fixture-backed shell integration | `mix test test/mailglass/state_md_contract_test.exs test/scripts/check_state_md_pr_refs_test.exs --warnings-as-errors` | ✅ both test files | ✅ green |
| 167-04-T3 | 04 | 1 | STAND-01 | — | Minor/patch Dependabot updates are grouped and capped; majors remain individual | static YAML structure + post-merge observation | PyYAML structural assertion; weekly observation | ✅ `.github/dependabot.yml` | ✅ static check green |

*Status: ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] CLAUDE.md, CONTRIBUTING.md, and MAINTAINING.md contract blocks added to
      `test/mailglass/docs_contract_test.exs`.
- [x] `scripts/check_state_md_pr_refs.sh` added with fixture-backed integration coverage, including
      the `#26`/`#260` prefix-collision regression; the test is in `verify.support_contract.core`.
- [x] `config_test.exs` inverts the `css_inliner: :none` case to an `assert_raise`.

*Everything else reuses existing test files and idioms — this is a low-Wave-0-gap phase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dependabot emits ≤1 grouped PR per lock directory per week | STAND-01 | GitHub-native behavior; nothing in-repo can assert what the Dependabot service will produce. Only observable after a scheduled run | Merge the `dependabot.yml` change, wait for the next weekly window, confirm ≤1 PR per lock directory and CI green with no hand edits. If a group reds, drop the culprit with `ignore` and re-run — **do not ungroup** |
| `STATE.md` claims match live GitHub state at read time | DOCS-01 | Open-PR/issue status is not permanently true. The Wave 0 script can check *referenced* PR/issue numbers against `gh`, but "is STATE.md's prose currently honest" needs a human read | Run `gh pr list --state open` and `gh issue list --state open`; confirm no `STATE.md` sentence is falsified. See Landmine below |

---

## Landmines Carried From Research

1. **DOCS-04 is a two-file lockstep** (the Phase 125 pin-drift shape). `guides/migration-from-swoosh.md`
   and `test/mailglass/docs_contract_test.exs` must move in the **same commit**, or the split produces
   a deterministic red. Research recommends disposition (b) — extend the existing sed resync step in
   `release-please.yml` and convert the hardcoded regex to the dynamic helper the README test already
   uses — which removes the lockstep permanently rather than re-tightening it.

2. **Do not hardcode live PR status into `STATE.md`.** PR #222 is closed (a permanent fact, safe to
   state); PR #280 opened 2026-09-17 and is currently red (not permanent, will change before or during
   execution). Closed PRs and merged commits may be stated as fact; anything open must point at live
   `gh pr list` state rather than assert a snapshot.

3. **`STATE.md` is normally machine-managed** (`docs(state):` commits; CLAUDE.md says never hand-edit).
   The DOCS-01 correction must not fight the GSD tooling — see RESEARCH.md for the reconciliation.

4. **Exit criterion 8 is a hard fence:** no diff in this milestone may remove or weaken a gate. Each
   change must read as "made a control able to reach its own pass state."

---

## Validation Sign-Off

- [x] All tasks have automated verification or an explicitly bounded GitHub-native observation
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all formerly missing references
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automation-first validation; STAND-01's real weekly Dependabot behavior remains a
post-merge observation, with its in-repository configuration asserted structurally.

## Validation Audit 2026-09-19

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

The gap was a missing durable regression for the state-reference audit's prefix-collision behavior.
`test/scripts/check_state_md_pr_refs_test.exs` now proves that `#26` is evaluated against its own
line rather than an earlier `#260` line, and `mix verify.support_contract.core` executes it.
