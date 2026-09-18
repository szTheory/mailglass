---
phase: 167
slug: truthful-documentation-and-the-standing-control
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| TBD | TBD | 1 | DOCS-01 | — | N/A | generated script (advisory) | new `scripts/` check — see Wave 0 | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | DOCS-02 | — | N/A | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs` | ❌ W0 (new describe block) | ⬜ pending |
| TBD | TBD | 1 | DOCS-03 | — | N/A | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs` | ❌ W0 (new describe blocks) | ⬜ pending |
| TBD | TBD | 2 | DOCS-04 | — | N/A | unit (dynamic assertion) | `mix test test/mailglass/docs_contract_test.exs` | ✅ existing test extended | ⬜ pending |
| TBD | TBD | 2 | DOCS-05 | — | Invalid config key rejected at validation, not silently inert | unit | `mix test test/mailglass/config_test.exs test/mailglass/docs_contract_test.exs` | ✅ existing tests extended | ⬜ pending |
| TBD | TBD | 1 | DOCS-06 | — | N/A | unit (source-text) | `mix test test/mailglass/docs_contract_test.exs` | ✅ existing test extended | ⬜ pending |
| TBD | TBD | 1 | STAND-01 | — | Majors stay ungrouped so a breaking bump is individually reviewable | manual + observation | YAML review; a week's bumps arriving as ≤1 PR per lock directory | N/A — GitHub-native | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New `describe "CLAUDE.md contract"` / `describe "CONTRIBUTING.md contract"` /
      `describe "MAINTAINING.md contract"` blocks in `test/mailglass/docs_contract_test.exs` — none
      exist yet for these three files (only `README.md` and the guides have contract tests today)
- [ ] New script for DOCS-01's live-GitHub-state pin (e.g. `scripts/check_state_md_pr_refs.sh`) —
      **the one item in this phase with no direct existing pattern to extend.** Mirror the
      `repo-hygiene` script pattern; advisory, not gating
- [ ] Inverted `config_test.exs` case for `css_inliner: :none` (raise, not accept) — a flip of the
      existing acceptance case at `config_test.exs:17-21`, mirroring the adjacent `:invalid_backend`
      `assert_raise` already in that file. Not a net-new file

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
