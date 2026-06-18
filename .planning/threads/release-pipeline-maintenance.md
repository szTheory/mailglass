# Thread: Release-Pipeline Maintenance (post-v1.12)

**Opened:** 2026-06-17
**Status:** ✅ closed 2026-06-18 — all items resolved (see Exit Signal)
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

2. **✅ DONE (2026-06-18) — reference baseline de-hardcoded + refreshed to 1.7.0.** Resolved via
   `/gsd-quick` (task `260618-1qj`); commit `7cbef50b`; CI green (both Trust Lane jobs success).
   Instead of just bumping `~> 1.4` → `~> 1.7` (which would have to be redone every release), made
   the whole baseline **version-agnostic** so it never needs coordinated edits again:
   - `check_clean_baseline_hex_only.sh` now asserts each sibling resolves via `:hex` with a
     well-formed version string — dropped the hardcoded `{"mailglass", :hex, "1.4.5"}` list. The
     committed `mix.lock` is the reproducible pin; the guard enforces "real Hex consumer, not
     `path:`/`git:`," which is the property that mattered.
   - `ci_trust_lane_contract_test.exs` made version-agnostic (regexes + repurposed the stale-version
     test into a non-Hex-source-rejection test).
   - Pins widened `~> 1.4`/`~> 1.1` → `~> 1.0`; both locks refreshed 1.4.5/1.4.5/1.1.5 →
     **1.7.0/1.7.0/1.4.0** (the baseline was silently frozen at 1.4.5, exercising stale code).
   - **The swoosh-lock-drift footgun is now moot** for the baseline (nothing asserts an exact
     version; swoosh→1.26.1 is intentional). Supersedes the old "coordinated 5-file change" warning
     in [[project_reference_baseline_coupling]] / [[project_demo_app_swoosh_lock_drift]].
   - **Future refresh = one command, no edits:** `mix deps.update mailglass mailglass_admin
     mailglass_inbound` in each reference app (demo_app needs `MAILGLASS_DEMO_DEPS=hex`).

3. **`guard-release-trigger`** — exercised + passed + already the single required branch-protection
   check. No action needed; recorded for completeness.

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

5. **✅ DONE (2026-06-18) — `Core Full Suite Advisory` lane fixed (decision: FIX, quarantine).**
   Resolved via `/gsd-quick` (task `260617-tgw`); commit `abadbb32`. Advisory Matrix run on the fix
   SHA = **both jobs green** (Core Full Suite + Provider Compatibility).
   - **Real cause (memory's "~57 Oban failures" was stale):** the latest red run was
     `1191 tests, 9 failures`, and all 9 were in **5 maintainer dev-tooling modules** (zero in
     `lib/`): `ReferenceHost.{CompileSmoke,WebhookOperatorPath,TrustRunnerCheckpointContract}Test`,
     `DemoDataTest`, `Publish.PostPublishSmokeContractTest`. They fail **structurally** — they need
     the full repo workspace (sibling `MailglassInbound` compiled, reference/host_app + demo_app with
     fetched deps) which the isolated-core `mix deps.get && mix test` lane never sets up. They fail
     identically locally; they had **never** been green in CI.
   - **Why FIX not RETIRE:** the required green lanes run only narrow curated file lists
     (`verify.support_contract.core` = 11 files, provider-compat ≈ 11). Of 157 core test files, the
     bulk (renderer, outbound, most of `test/mailglass/**`) run **only** in this advisory lane —
     retiring would drop the only CI coverage of ~120 lib test files.
   - **Fix:** tagged the 5 modules `@moduletag :requires_workspace` + added
     `--exclude requires_workspace` to the advisory lane. Their behaviors are already covered by the
     Trust Lane / Demo Browser Evidence / publish-hex post-publish-smoke lanes, so no real coverage
     lost; the lane now runs the ~1180 real lib tests as a meaningful green canary.

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

**✅ CLOSED 2026-06-18.** All items resolved: item 1 (`1e0e60b1`), item 2 (`7cbef50b` — baseline
de-hardcoded + refreshed to 1.7.0), item 3 (no-op), item 4 (held PRs #75/#76 merged), item 5
(`abadbb32` — advisory lane fixed). No remaining work; the release pipeline is in a clean, low-
maintenance state and future releases need no baseline babysitting.
