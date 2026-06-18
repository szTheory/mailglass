---
quick_id: 260617-syd
description: Triage held dependency PRs #76 premailex and #75 swoosh
status: in-progress
date: 2026-06-18
---

# Quick Task 260617-syd: Triage held dependency PRs #76 (premailex) + #75 (swoosh)

## Objective

Resolve the two dependency PRs held open during the 2026-06-17 repo-hygiene pass
(thread `release-pipeline-maintenance.md` item 4): decide merge-or-close for each
after a real compatibility review, not a blind bump.

- **#76 `premailex` 0.3.20 → 1.0.0** — major bump. Review the 1.0.0 changelog,
  check mailglass's premailex usage surface, validate the rendering pipeline, then
  merge or close.
- **#75 `swoosh` 1.26.0 → 1.26.1** — patch bump. Confirm it does NOT violate the
  frozen trust-lane baseline before merging.

## Investigation findings

### #76 premailex 1.0.0
- **Usage surface:** single call site `Premailex.to_inline_css(html)` (1-arity) at
  `lib/mailglass/renderer.ex:239`; config default `:premailex`
  (`lib/mailglass/config.ex:75-77`). The plaintext walker uses mailglass's own Floki,
  independent of premailex.
- **1.0.0 breaking changes:** the `/2` signature gained `:remove_style_tags` (replacing
  `:optimize`); `HTMLInlineStyles.process/3` → `/2`; Floki became **optional** and a
  pluggable parser model was added (`lazy_html`, `:xmerl` fallbacks). The bare
  `to_inline_css/1` call mailglass uses is **unaffected**, and mailglass declares
  `{:floki, "~> 0.38"}` directly (satisfies premailex's new `~> 0.24` optional floki).
- **Local validation:** checked out the PR, `mix deps.get` (premailex 1.0.0, no lock
  drift), `mix test test/mailglass/renderer_test.exs` → **20 tests, 0 failures**
  (CSS-inlining + VML/MSO plaintext pipeline intact); compiles warnings-clean.
- **CI red was a false alarm:** `Compile No Optional Deps` failed only because the
  11-day-old branch was BEHIND main (stale `ex_doc`/`earmark_parser`/`makeup_erlang`
  lock vs main's #77 bump). Resolved by `gh pr update-branch`.

### #75 swoosh 1.26.1
- Touches **only the root `mix.lock`** (swoosh `~> 1.25` in mix.exs already allows it).
- The trust-lane guard (`scripts/check_clean_baseline_hex_only.sh` +
  `test/mailglass/publish/ci_trust_lane_contract_test.exs`) validates the **mailglass**
  sibling pin in `reference/host_app/mix.lock` is Hex-sourced/well-formed — it is
  **not coupled to swoosh versions**. Reference apps stay frozen at swoosh 1.26.0
  (untouched). Both Trust Lane checks pass on the PR.
- Also stale (req 0.5.18→0.6.1, but main already has req 0.6.1) → updated branch so it
  reduces to a swoosh-only patch.

## Tasks

1. **Update both stale branches to current main** so CI runs on a clean merge-ref.
   - verify: `gh pr view <N> --json mergeStateStatus` no longer `BEHIND`.
   - done: fresh CI matrix runs on each.
2. **Merge each PR on green** (accepting the known persistently-red
   `Core Full Suite Advisory` lane — item 5, unrelated Oban flakes; only required check
   is `guard-release-trigger`). Path: `gh pr review --approve` → `gh pr merge <N>
   --admin --squash --delete-branch`.
   - verify: `gh pr view <N> --json state` = `MERGED`; `main` CI green post-merge.
   - done: both branches deleted, thread item 4 closeable.

## Out of scope
- Item 2 (reference baseline `~> 1.4` → `~> 1.7` mailglass pin bump) — separate
  coordinated change, not required by either PR.
- Item 5 (`Core Full Suite Advisory` fix-or-retire) — the next quick task.
