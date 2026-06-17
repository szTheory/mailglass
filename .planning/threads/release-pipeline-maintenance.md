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

1. **`gate-ci-green` advisory-classifier gap (highest value).** In `publish-hex.yml`, `isAdvisory()`
   only matches `"Operator Browser Gate"` or the `" Advisory ("` naming convention. The lane
   `"Demo Browser Evidence (Docker Compose / Chromium)"` matches neither, so a red Demo Browser
   Evidence lane is treated as *blocking* despite not being a branch-protection-required check.
   v1.12 sidestepped this by greening the test; harden the classifier (add to `ADVISORY_LANES` or
   rename the lane) so non-required ⇒ advisory holds by rule. Source: `v1.12-MILESTONE-AUDIT.md`
   Follow-ups.

2. **Reference baseline pin bump (deferred).** `reference/host_app` + `reference/demo_app` pin
   `{:mailglass, "~> 1.4"}`; `~> 1.4` already resolves 1.7.0 so nothing is broken, but a bump to
   `~> 1.7` would keep the baseline honest. NOTE: this is a coordinated multi-file change (2 mix.exs
   + 2 mix.lock + `check_clean_baseline_hex_only.sh` + `ci_trust_lane_contract_test.exs`), and any
   `mix` run in `demo_app` re-bumps the swoosh lock — see the two relevant user memories before doing it.

3. **`guard-release-trigger`** — exercised + passed + already the single required branch-protection
   check. No action needed; recorded for completeness.

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

Closes when item 1 is fixed (or explicitly waived) and item 2 is either done or formally deferred
with a review date.
