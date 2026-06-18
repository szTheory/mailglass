# Thread: Release-Pipeline Maintenance (post-v1.12)

**Opened:** 2026-06-17
**Status:** open — small, concrete maintenance items (NOT a milestone)
**Priority:** low/medium (release-robustness; no adopter-facing functional gap)
**Owner:** maintainer

## Why this exists

v1.12 was the first real Hex cut since 1.6.2 (the v1.7–v1.11 body had only ever run in local phase
execution). Pushing it before merge surfaced six pre-flight CI regressions — all fixed — plus a few
durable pipeline-robustness items worth tracking so the *next* release ceremony is smoother. These are
maintenance-tier; handle with `/gsd-quick` or a todo, not a feature milestone.

## Items

1. **✅ DONE (2026-06-17) — `gate-ci-green` advisory-classifier gap.** In `publish-hex.yml`,
   `isAdvisory()` only matched `"Operator Browser Gate"` or the `" Advisory ("` naming convention,
   so the non-required lane `"Demo Browser Evidence (Docker Compose / Chromium)"` was treated as
   *blocking*. Fixed via `/gsd-quick` (commit `1e0e60b1`): added `"Demo Browser Evidence"` to the
   explicit `ADVISORY_LANES` array + updated the comment to name both predates-convention lanes.
   Verified: yaml parses; `isAdvisory()` classifies it advisory while required lanes still block.
   Quick-task artifacts: `.planning/quick/260617-oj1-harden-publish-hex-yml-gate-ci-green-isa/`.

2. **Reference baseline pin bump (deferred).** `reference/host_app` + `reference/demo_app` pin
   `{:mailglass, "~> 1.4"}`; `~> 1.4` already resolves 1.7.0 so nothing is broken, but a bump to
   `~> 1.7` would keep the baseline honest. NOTE: this is a coordinated multi-file change (2 mix.exs
   + 2 mix.lock + `check_clean_baseline_hex_only.sh` + `ci_trust_lane_contract_test.exs`), and any
   `mix` run in `demo_app` re-bumps the swoosh lock — see the two relevant user memories before doing it.

3. **`guard-release-trigger`** — exercised + passed + already the single required branch-protection
   check. No action needed; recorded for completeness.

---

## NEXT-SESSION FOCUS — two open follow-ups from the 2026-06-17 repo-hygiene pass

The repo-hygiene pass (pushed `main`, triaged PRs 6→2, deleted preserve branches, confirmed CI/GSD
clean) left exactly two tracked items. Both are `/gsd-quick`-sized — start a fresh session, pick either.

4. **✅ DONE (2026-06-18) — Held dependency PRs #75 (swoosh) + #76 (premailex) merged.**
   Resolved via `/gsd-quick` (task `260617-syd`). Both merged to main; branches deleted.
   - **#76 `premailex` 0.3.20 → 1.0.0** (major) — **MERGED** (`9c3bbfea`). Reviewed safe:
     mailglass's only call site is the bare `Premailex.to_inline_css/1` (`renderer.ex:239`); the
     1.0.0 breaking changes are confined to the `/2` options API + the now-optional pluggable
     parser, neither of which we touch (mailglass declares `{:floki, "~> 0.38"}` directly,
     satisfying premailex's new `~> 0.24` optional floki). Validated locally:
     `mix test test/mailglass/renderer_test.exs` = 20/20 green against 1.0.0, compiles
     warnings-clean. The PR's `Compile No Optional Deps` red was a **false alarm** — the 11-day-old
     branch was BEHIND main's #77 ex_doc bump (stale `ex_doc`/`earmark_parser`/`makeup_erlang`
     lock); cleared by `gh pr update-branch`.
   - **#75 `swoosh` 1.26.0 → 1.26.1** (patch) — **MERGED** (`50b49206`). The "coordinated
     baseline change" caution was **over-stated**: the trust-lane guard
     (`ci_trust_lane_contract_test.exs` + `check_clean_baseline_hex_only.sh`) validates the
     **mailglass** sibling-pin Hex-cleanliness in `reference/host_app/mix.lock` — it is **NOT
     coupled to swoosh versions**. #75 touches only the **root** `mix.lock`; reference apps stay
     frozen at 1.26.0 (untouched). Both Trust Lane checks passed. Durable correction: a root-lock
     swoosh patch bump is a one-PR merge, not a 5-file baseline change. (The 5-file machinery is
     only for the *mailglass pin* bump — item 2.) Its `Compile No Optional Deps` failed once on the
     same transient ex_doc dep-cache race; passed on rerun.
   - **Merge-mechanics confirmed (durable):** dependabot PRs sit `BLOCKED` until approved;
     `enforce_admins: false`, so `gh pr review --approve` → `gh pr merge <N> --admin --squash
     --delete-branch` is the path. Only required status check is `guard-release-trigger`. The
     persistently-red `Core Full Suite Advisory` lane (item 5) is non-blocking and was accepted.
   - **New durable gotcha:** the `Compile No Optional Deps` CI lane does NOT run `mix deps.get` and
     relies on a lock-hash-keyed deps cache; a dependabot PR created before an unrelated dev-dep
     bump (e.g. ex_doc) lands on main will show a spurious `lock mismatch` on ex_doc/earmark/makeup
     until the branch is updated and/or the job is re-run against the current cache. Not a real
     incompatibility — `gh pr update-branch` + rerun clears it.

5. **`Core Full Suite Advisory` lane is *persistently* red — fix-or-retire decision.**
   Suggested entry: `/gsd-quick` (or `/gsd-debug` if root-causing the failures).
   - The `Core Full Suite Advisory (Elixir 1.18 / OTP 27)` lane fails on essentially every main push
     AND every PR — not intermittently. It's correctly **non-blocking** (advisory, not a
     branch-protection-required check), which is why releases/merges still go through. But a
     *permanently* red lane is noise that masks real regressions and keeps the `Advisory Matrix`
     workflow red on main.
   - Likely cause per user memory: the full core suite includes ~57 unrelated Oban failures under
     non-deterministic conditions (see the bare-`mix test` / inbound-suite-flake memories).
   - Decision to make: **fix** the failing tests (deterministic seed / isolate the Oban tests) **or
     formally retire/quarantine** them out of the advisory lane so the lane can go green and mean
     something. Either way the lane should stop being permanently red.

## Durable release-ceremony lessons (graduation candidates → cross-milestone trends)

- **Push-before-merge is the real CI gate** for any body assembled by local phase execution
  (paths-ignore / no-CI commits). The first real push will surface format/Dialyzer/ex_doc/docs-check
  regressions that local per-phase runs never caught. Budget a pre-flight greening pass into every
  release ceremony close.
- **Publish fan-out races** (one `publish-hex` run per release event; race-loser `publish-core` jobs
  fail "already published"; post-publish-smoke can false-negative on a ~5-min Hex-index timeout —
  re-dispatch on the tag). Expected behavior; verify against Hex directly, don't trust the red job.
- **Hands-free auto-merge can stall** when non-required advisory lanes are red + Release Please's
  hourly PR regeneration churns; recover via maintainer admin-override after explicit go/no-go with
  all *required* checks green.

## Exit Signal

Closes when: item 1 ✅ done; item 2 done or formally deferred with a review date; item 4 ✅ done
(held PRs #75/#76 both merged 2026-06-18); item 5 (`Core Full Suite Advisory`) fixed or formally
retired from the advisory lane. **Remaining:** item 2 (deferred) + item 5 (next `/gsd-quick`).
