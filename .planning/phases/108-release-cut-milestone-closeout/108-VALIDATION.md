---
phase: 108
slug: release-cut-milestone-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 108 — Validation Strategy

> Phase 108 is a **release ceremony + milestone closeout**, not a code-writing phase.
> "Validation" here means verifiable **release-gate checks** — each with a binary pass/fail
> and a specific command — not ExUnit tests. The gates below are the sampling contract.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Release-gate checks (GitHub Actions + `mix hex.info` + shell smoke), not ExUnit |
| **Config file** | none — gates run against live workflows / Hex |
| **Quick run command** | `gh run list --workflow ci.yml --branch main --limit 3` |
| **Full suite command** | per-wave gate battery (see Release Gate Checks below) |
| **Estimated runtime** | post-publish smoke ~2–5 min; full ceremony minutes-to-an-hour incl. RP/cron latency |

---

## Live State (verified this session — supersedes RESEARCH assumptions)

- **Release Please PR #84 ("chore: release main") is ALREADY OPEN** and proposes
  `mailglass 1.7.0 / mailglass_admin 1.7.0 / mailglass_inbound 1.4.0` with the manifest and all
  three `@version` attrs bumped.
- **Inbound is 1.4.0 (minor), NOT 1.3.2 (patch).** The bump was driven by `feat(99-01):
  implement tenant-scoped inbound summary read model` (a v1.11 commit touching
  `mailglass_inbound/`), so inbound bumps on its own — no new `fix(inbound):` commit is needed.
- **The inbound re-pin (REL-02 / D-13) is ALREADY ENCODED in PR #84:** the RP sed step rewrote
  `mailglass_inbound/mix.exs` `{:mailglass, "== 1.6.2"}` → `{:mailglass, "== 1.7.0"}`. The plan's
  REL-02 action is therefore **verify** the pin in the PR (and that inbound publishes from the
  release event), not author a new commit.
- **Publish allowlist `.planning/publish/mailglass-files.expected` is STALE** — confirmed missing
  the 3 v1.12 guides (`learning-path.md`, `production-go-live-checklist.md`,
  `errors-and-troubleshooting.md`) and 2 modules (`installer/doctor.ex`,
  `mix/tasks/mailglass.doctor.ex`). `mix mailglass.publish.check` will fail until regenerated.
  This is the one real **Wave-0 blocker** and must merge into the release PR (or land on main and
  let RP rebase) before publish.

---

## Sampling Rate

- **After every task commit:** Run that wave's gate checks (see table).
- **After every wave:** Re-confirm the prior wave's gates still hold (idempotent re-checks).
- **Before closing Phase 108:** REG-08 through REG-12 all green.
- **Max feedback latency:** post-publish smoke ≤ 5 min; RP merge→publish ≤ 1 h (hourly cron self-heal).

---

## Release Gate Checks (in order)

| Gate | Wave | Command / Verification | Pass Condition |
|------|------|------------------------|----------------|
| REG-01: main CI green on tagged SHA | 0 | `gh run list --workflow ci.yml --branch main --limit 5` | A completed green `ci.yml` run exists on the SHA to be tagged (force via `gh workflow run ci.yml --ref main` if `.planning`-only commits suppressed it) |
| REG-02: allowlist clean (core) | 0 | `cd mailglass && mix mailglass.publish.check` | Exits 0 — after regenerating to include the 3 new guides + 2 modules |
| REG-03: allowlist clean (admin) | 0 | `cd mailglass_admin && mix mailglass.publish.check` | Exits 0 |
| REG-04: allowlist clean (inbound) | 0 | `cd mailglass_inbound && mix mailglass.publish.check` | Exits 0 |
| REG-05: RP PR proposes all 3 packages | 1 | `gh pr diff 84` (manifest) | `.": "1.7.0"`, `mailglass_admin: "1.7.0"`, `mailglass_inbound: "1.4.0"` |
| REG-06: inbound re-pin present in PR | 1 | `gh pr diff 84` (`mailglass_inbound/mix.exs`) | Shows `{:mailglass, "== 1.7.0"}` (REL-02 encoded) |
| REG-07: CHANGELOGs reflect v1.7–v1.12 work | 1 | `gh pr diff 84` (`CHANGELOG.md`, per-package) | Entries present; hand-curate only if RP output is thin (REL-01) |
| REG-08: RP PR merges green + publish fires | 2 | `gh pr view 84` / Actions | PR merged; `release-please.yml` cascades (or `gh workflow run release-please.yml` recovery) |
| REG-09: core on Hex | 3 | `mix hex.info mailglass 1.7.0` | Output contains "Released:" |
| REG-10: admin on Hex | 3 | `mix hex.info mailglass_admin 1.7.0` | Output contains "Released:" |
| REG-11: inbound on Hex with correct pin | 3 | `mix hex.info mailglass_inbound 1.4.0` | Shows dependency `mailglass == 1.7.0` |
| REG-12: Hex resolution + consumer smoke | 4 | `DEP_MODE=hex bash scripts/consumer_install_smoke.sh` | `mix deps.get` resolves all 3 from Hex; `GET /dev/mail/` → 200 |
| REG-13: post-publish-smoke green | 4 | Monitor `post-publish-smoke.yml` run | Pass — OR the only red is the known swoosh-1.26.x/hackney #32 false-positive (distinguish, do not block) |
| REG-14: milestone audit + archive | 5 | `ls .planning/milestones/v1.12-*` | ROADMAP + REQUIREMENTS + MILESTONE-AUDIT archived; phase counts manually corrected for 999.x inflation |
| REG-15: v1.12 tag | 5 | `git tag -l v1.12` | Tag exists |

---

## Per-Wave Verification Map

| Wave | Requirement | Gates | Irreversible? | Checkpoint |
|------|-------------|-------|---------------|------------|
| 0 — Pre-flight hygiene | REL-01 (allowlist, green main) | REG-01..04 | No | — |
| 1 — Verify RP PR contents | REL-01, REL-02 | REG-05..07 | No | — |
| 2 — Merge + publish | REL-01 | REG-08 | **YES (Hex publish — cannot unpublish after 24 h)** | Maintainer authorizes merge |
| 3 — Confirm Hex live | REL-01, REL-02 | REG-09..11 | No (read-only) | — |
| 4 — Resolution + smoke | REL-02 | REG-12, REG-13 | No | — |
| 5 — Milestone closeout | (milestone) | REG-14, REG-15 | No (tag is cheap to re-cut) | — |

---

## Wave 0 Requirements

- [ ] Regenerate `.planning/publish/mailglass-files.expected` (and admin/inbound if drifted) so the
      3 new guides + 2 modules are captured — clean tree first (publish allowlist snapshots the
      working tree incl. untracked files).
- [ ] Confirm a green `ci.yml` run exists on the to-be-tagged SHA.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authorize the irreversible Hex publish | REL-01 | Hex packages cannot be unpublished after 24 h; this is the one maintainer go/no-go | Maintainer reviews PR #84 diff (versions, CHANGELOGs, pin) then merges |
| Distinguish #32 swoosh/hackney smoke red from a real failure | REL-02 | Known false-positive in `post-publish-smoke` consumer-install lane unrelated to the shipped version | If the only failing step is `Consumer install` with `missing hackney dependency`, it is #32 — not a release blocker |

---

## Assumptions Log (corrected vs RESEARCH)

| # | Claim | Status |
|---|-------|--------|
| A1 | Inbound bumps to `1.3.2` (patch) from a `fix(inbound):` commit | **WRONG** — live PR #84 shows `1.4.0` (minor) from `feat(99-01)`; no new commit needed |
| A2 | No RP PR is open yet | **WRONG** — PR #84 is already open at 1.7.0/1.7.0/1.4.0 |
| A3 | Reference baseline `~> 1.4` already satisfies `1.7.0`, so the 5-file baseline bump is deferred | Holds — baseline re-pin is out of scope for this phase |
| A4 | Publish allowlist needs refreshing for the new guides/modules | **CONFIRMED** — 5 entries missing; real Wave-0 blocker |
