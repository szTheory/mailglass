---
quick_id: 260617-syd
description: Triage held dependency PRs #76 premailex and #75 swoosh
status: complete
date: 2026-06-18
---

# Quick Task 260617-syd — Summary

Resolved both held dependency PRs from thread `release-pipeline-maintenance.md` item 4.
Both reviewed for real compatibility (not blind-bumped) and **merged**.

## Outcome

| PR | Bump | Verdict | Merge commit |
|----|------|---------|--------------|
| #76 | premailex 0.3.20 → **1.0.0** (major) | merged | `9c3bbfea` |
| #75 | swoosh 1.26.0 → **1.26.1** (patch) | merged | `50b49206` |

Resulting root `mix.lock`: premailex 1.0.0 + swoosh 1.26.1. Zero open PRs; both branches deleted.

## #76 premailex 1.0.0 — why safe

- **Usage surface:** single bare `Premailex.to_inline_css/1` call at `lib/mailglass/renderer.ex:239`;
  config default `:premailex` (`config.ex:75-77`). Plaintext walker uses mailglass's own Floki.
- **1.0.0 breaking changes** (changelog): `/2` options reshaped (`:remove_style_tags` replaces
  `:optimize`), `HTMLInlineStyles.process/3`→`/2`, Floki made optional + pluggable parser
  (`lazy_html`/`:xmerl`). **None affect the bare `/1` call;** mailglass declares `{:floki, "~> 0.38"}`
  directly (satisfies premailex's new `~> 0.24` optional floki).
- **Local validation:** checked out PR, `mix deps.get` (premailex 1.0.0, no lock drift),
  `mix test test/mailglass/renderer_test.exs` → **20 tests, 0 failures** (CSS inlining + VML/MSO
  plaintext pipeline intact), compiles warnings-clean.
- **CI red was a false alarm:** `Compile No Optional Deps` failed only because the branch was BEHIND
  main's #77 ex_doc bump → resolved by `gh pr update-branch`; passed after.

## #75 swoosh 1.26.1 — why safe + a correction

- Root-`mix.lock`-only patch (mix.exs `~> 1.25` already allows it).
- **Trust-lane caution was over-stated:** `ci_trust_lane_contract_test.exs` +
  `check_clean_baseline_hex_only.sh` validate the **mailglass sibling-pin** Hex-cleanliness in
  `reference/host_app/mix.lock` — **not swoosh versions**. Reference apps stay frozen at swoosh 1.26.0
  (untouched). Both Trust Lane checks green. A root-lock swoosh patch is a one-PR merge, NOT the
  5-file coordinated change (that machinery is only for the *mailglass pin* bump — item 2).
- Same transient `Compile No Optional Deps` ex_doc dep-cache race; **passed on rerun**.

## Durable gotcha recorded

`Compile No Optional Deps` does not run `mix deps.get` (relies on a lock-hash-keyed deps cache). A
dependabot PR opened before an unrelated dev-dep bump lands on main shows a spurious `lock mismatch`
on `ex_doc`/`earmark_parser`/`makeup_erlang` until the branch is updated and/or the job re-run. Not a
real incompatibility. (Captured in the thread.)

## Merge mechanics used

`gh pr review <N> --approve` → `gh pr merge <N> --admin --squash --delete-branch`. Accepted the
persistently-red non-blocking `Core Full Suite Advisory` lane (item 5). Only required check is
`guard-release-trigger`.

## Follow-ups (unchanged)

- Item 2: reference baseline `~> 1.4` → `~> 1.7` mailglass pin bump — deferred (separate 5-file change).
- Item 5: `Core Full Suite Advisory` fix-or-retire — the next `/gsd-quick`.
