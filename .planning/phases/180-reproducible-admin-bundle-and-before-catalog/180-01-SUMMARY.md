---
phase: 180-reproducible-admin-bundle-and-before-catalog
plan: 01
subsystem: admin-asset-pipeline
tags: [tailwind, bundle-drift, mix-task, exunit-contract-test, ci-lane, release-hygiene]

requires:
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: copy.ex gloss text (the source of the red-at-HEAD drift) and the contract-test, lane and commit-kind conventions this plan follows
provides:
  - "`mix mailglass_admin.assets.build --check`: byte-for-byte drift gate against a fresh pinned Tailwind 4.1.12 build, writing nothing inside priv/static"
  - "`@source not inline(\"prose\");` so the committed 136,877-byte bundle is reproducible again"
  - "`MailglassAdmin.AssetsCheck` (non-shipped dev/ module): check/1, run_check!/1, format_error/1"
  - "`--check` wired as alias step 1 of `verify.support_contract.admin` (required `support_contract_admin` lane) and as the last step of `verify.preview`"
  - "26-case bundle_reproducibility_contract_test.exs: positive, hermetic teeth, source-side teeth, wiring with negative controls, fail-closed"
  - "Corrected prose: no file claims a CI git-diff of priv/static any more"
affects: [180-02, 180-03, 180-04, 181-token-swap, 183-docs-pass]

actuals:
  tokens: 8465
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "One compare function, two entry points (alias step plus ExUnit) so neither can be removed alone"
    - "Shipped Mix task reaches a dev-only module through Code.ensure_loaded? and apply/3, keeping the Hex tarball free of a compile-time Tailwind reference"
    - "Replace the Tailwind profile's own --output= entry instead of appending a second flag (the CLI comma-joins duplicates)"

key-files:
  created:
    - mailglass_admin/dev/mailglass_admin/assets_check.ex
    - mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs
    - .planning/phases/180-reproducible-admin-bundle-and-before-catalog/deferred-items.md
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex
    - mailglass_admin/lib/mix/tasks/mailglass_admin.assets.watch.ex
    - mailglass_admin/mix.exs
    - mailglass_admin/.gitattributes
    - mailglass_admin/.gitignore
    - mailglass_admin/docs/design-system.md

key-decisions:
  - "Inline `@source not inline(\"prose\")` (D-03) over a path exclusion; the path form drops four real classes (F13)"
  - "Compare logic lives in dev/ and the shipped task delegates via apply/3 (D-02 allowed it; publish allowlist stayed unchanged, proven by mailglass.publish.check --allowlist-only)"
  - "Contract test asserts the drift shape (fresh larger than committed, offset inside the file) for the removed-prose case, not the measured 139137/136877/74051 sizes, which are recorded here instead so a later legitimate token or copy change is not turned into test churn"
  - "D-07 ordering deviation held: emulated linux/amd64 cmp now, real ubuntu-latest proof from the phase PR's first support_contract_admin run"

requirements-completed: [BRPIPE-01]

coverage:
  - id: D1
    description: "A fresh pinned Tailwind 4.1.12 build is byte-identical to the committed priv/static/app.css (136,877 bytes) once the prose scan exclusion is in place; the exclusion removal reproduces the HEAD drift"
    requirement: BRPIPE-01
    verification:
      - kind: integration
        ref: "cd mailglass_admin && MIX_ENV=test mix mailglass_admin.assets.build --check (exit 0, 'Admin bundle matches a fresh build (136877 bytes).')"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs#positive check: the committed bundle is what the generator produces"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs#removing the @source not inline(\"prose\") exclusion reports drift"
        status: pass
    human_judgment: false
  - id: D2
    description: "A missing, truncated, one-byte-flipped, final-byte-flipped or extended committed bundle, an appended CSS rule, and a utility token planted in lib/ each fail the check and name the fix command"
    requirement: BRPIPE-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs#detectors have teeth: committed-file mutations / source-side mutations"
        status: pass
    human_judgment: false
  - id: D3
    description: "The check sits in the required support_contract_admin lane: alias step 1, no test-file allow-list, ci.yml runs the alias, ci_green needs the job, each with a negative control"
    requirement: BRPIPE-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs#wiring: the check sits in a lane that actually runs"
        status: pass
      - kind: integration
        ref: "MIX_BUILD_PATH=<empty>/test mix verify.support_contract.admin (cold start, exit 0, 1318 tests, 0 failures, check line before the test run)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A Tailwind install or download failure, a missing binary, a non-zero exit and a silent exit 0 never become a pass"
    requirement: BRPIPE-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs#fail closed: a Tailwind failure is never a pass"
        status: pass
    human_judgment: false
  - id: D5
    description: "Byte equality on the real ubuntu-latest runner (first CI run of support_contract_admin on the phase PR)"
    requirement: BRPIPE-01
    verification: []
    human_judgment: true
    rationale: "Only a real CI run can supply the ubuntu-latest bytes; the local emulated linux/amd64 cmp is identical, but the phase PR does not exist yet. The verifier reads the run ID and its --check line from the lane itself, not from owner review."

duration: 9min
completed: 2026-11-15
status: complete
commits: 6
plan_head_before: 5d28a9af054dd1f15a0410568351f6df25e95b01
plan_head_after: 78f5e92a487c8a92fe6af94d0c4a0736558971c0
---

# Phase 180 Plan 01: Reproducible Admin Bundle Summary

**`mix mailglass_admin.assets.build --check` rebuilds the admin bundle with the pinned Tailwind 4.1.12 into a temp file and byte-compares it to the committed `priv/static/app.css`; it is the first step of the required `verify.support_contract.admin` lane, backed by a 26-case mutation-proven contract test, after a one-line `@source not inline("prose")` directive cleared the 2,260-byte drift Phase 179 copy text had introduced.**

## Performance

- **Duration:** 9 min (524 s wall clock; the cold-start lane run was 79 s of that)
- **Started:** 2026-11-15T00:19:41Z
- **Completed:** 2026-11-15T00:28:20Z (last task commit; SUMMARY follows)
- **Tasks:** 3 of 3
- **Files modified:** 9 source files plus this SUMMARY and `deferred-items.md`

## Accomplishments

- **Red-at-HEAD resolved first (D-03).** The word "prose" in Phase 179 `copy.ex` gloss text made the plain-text scanner emit daisyUI `.prose` rules. `@source not inline("prose");` returns a fresh build to the committed 136,877 bytes. `priv/static/app.css` is byte-identical to before (no churn commit); `.max-w-prose` is still emitted.
- **`--check` gate (D-02).** `MailglassAdmin.AssetsCheck` swaps only the profile's `--output=` entry for a unique temp path (never appends a second flag, F1), runs the pinned binary with `BROWSERSLIST_IGNORE_OLD_DATA=1`, compares bytes, and always removes the temp file. The shipped task keeps zero compile-time references to `Tailwind` (`grep -c 'Tailwind\.'` = 0) and delegates through `Code.ensure_loaded?` plus `apply/3`.
- **Lane wiring (D-04).** `mailglass_admin.assets.build --check` is step 1 of `verify.support_contract.admin` and the final step of `verify.preview` (alias name kept for `scripts/check_phase173_candidate.sh:245`). No CI job, no dependency and no `ci.yml` line was added.
- **Contract test (D-06).** 26 cases in `bundle_reproducibility_contract_test.exs` (3.4 s): positive, hermetic committed-file teeth, source-side teeth on a relocated copy of the inputs, option handling, wiring with negative controls, fail-closed. Three source mutations each turned it red and were restored.
- **False claims corrected (D-05).** `.gitattributes`, `.gitignore`, the `assets.watch` and `assets.build` moduledocs, `docs/design-system.md` and the `mix.exs` alias comment no longer say CI diffs `priv/static`. `grep -l 'git diff --exit-code'` over those six files prints 0.
- **Cold start proven (A3/P12).** From an empty `MIX_BUILD_PATH` the lane compiled every dep and the project, downloaded Tailwind 4.1.12 beside the empty build path, printed the `--check` confirmation before the suite, and passed.

## Task Commits

1. **Task 1 (tracer): end-to-end `--check`** (four separate commits per D-09 and F12)
   - `3c24adab` chore(admin): exclude the English word prose from the Tailwind scan (`app.css` only)
   - `c8bea866` chore(admin): add the admin bundle drift compare module (`dev/` only)
   - `22199f22` fix(admin): add --check drift mode to mailglass_admin.assets.build (`lib/mix/tasks` only)
   - `ed286cb8` ci(admin): run the bundle drift check first in the admin support contract (`mix.exs` only)
2. **Task 2: contract test with teeth, wiring and fail-closed cases** - `e4085d5f` test(admin)
3. **Task 3: correct the false CI-diff claims, prove the lane cold** - `78f5e92a` docs(admin)

**Plan metadata:** the `docs(180-01)` commit that adds this SUMMARY, `deferred-items.md`, STATE.md, ROADMAP.md and REQUIREMENTS.md.

Tracer gate: `<verify>` re-run end to end after Task 1 (exit 0, `git diff --quiet -- priv/static`, no `app.css?*` litter) before expanding to Task 2: Tracer verified end-to-end, expanding.

## Evidence (all labelled local unless it names a CI run)

### Red at HEAD, then green (D-03), local evidence

With the directive absent (HEAD state, tree otherwise as in this plan), `MIX_ENV=test mix mailglass_admin.assets.build --check` exited 1:

```
** (Mix) Admin bundle drift: a fresh build is 139137 bytes, the committed priv/static/app.css is 136877 bytes, first difference at byte 74051. Run mix mailglass_admin.assets.build and commit priv/static/app.css.
```

With the directive present it exited 0: `Admin bundle matches a fresh build (136877 bytes).`

### Drifted bundle fails the lane at alias step 1 (ROADMAP criterion 2), local evidence

With the directive removed in a scratch edit, `mix verify.support_contract.admin` exited 1 with the same drift message and no ExUnit output (`Running ExUnit`, `tests,` and `failures` all absent): the lane stops at step 1, before any test runs. The file was restored with `git checkout --`. The lane itself is cited by the phase PR's CI run ID (below), never by this local run. No throwaway draft PR was opened (one open PR at a time; the alias runs verbatim in CI).

### Platform equality (D-07, F2), local emulated evidence

Official `tailwindcss-linux-x64` v4.1.12, sha256 `5eeee66ea237eae9a160fa3314fd0cf76ab993551a99fafb16fa1db6c6b90289` (verified equal to the vendor release sum before use), run in `docker run --platform linux/amd64 ubuntu:24.04` (`uname -m` printed `x86_64`) with workdir `/repo/mailglass_admin`, env `BROWSERSLIST_IGNORE_OLD_DATA=1`, args `--input=assets/css/app.css --output=/tw/out.css --minify`: 136,877 bytes, `cmp` against `mailglass_admin/priv/static/app.css` reported byte-identical.

linux-amd64-cmp: identical

This is local evidence from an emulated run of the same binary and CPU architecture ubuntu-latest uses. It is a blocking precondition of 180-04 Task 3 and it is satisfied. The real `ubuntu-latest` proof is the first CI run of `support_contract_admin` on the phase PR (any admin code change sets `code=true`).

**CI run record (D-07, pending, append when it completes):**

- support_contract_admin run ID: _pending the phase PR_
- its `--check` output line: _pending_ (expected `Admin bundle matches a fresh build (136877 bytes).`)

If those CI bytes differ, apply the D-07 fallback from the plan's `decisions_recorded`: pin the check to the CI platform and never loosen the compare.

### Mutation protocol (METHODOLOGY), local evidence

Baseline 26 tests, 0 failures. Each mutation was applied, the file run, then restored with `git checkout --` and re-run green:

| Mutation | Red test |
|----------|----------|
| (a) `rescue _ -> :ok` around the installer call in `assets_check.ex` | `fail closed ... an installer that raises propagates the raise` (1 failure) |
| (b) delete the `--check` step from the `verify.support_contract.admin` alias | `wiring ... alias first step is the --check step` and `wiring ... negative controls` (2 failures) |
| (c) compare ignores the last byte | `committed-file mutations ... a flipped final byte is drift at the last offset` (1 failure) |

### Cold start from an empty build path (W6, A3/P12), local evidence

`MIX_BUILD_PATH=<fresh mktemp>/test mix verify.support_contract.admin` (CI restores dep sources only, never `_build`): exit 0 in 79 s. Output showed every dep, `mailglass`, `mailglass_inbound` and `mailglass_admin` compiling from nothing, `[debug] Downloading tailwind from https://github.com/tailwindlabs/tailwindcss/releases/download/v4.1.12/tailwindcss-macos-arm64`, then `Admin bundle matches a fresh build (136877 bytes).` before `Running ExUnit`, then `1318 tests, 0 failures, 1 excluded`. `tailwind-macos-arm64-4.1.12` existed beside the empty build path. The temp directory was removed.

### Other gates, local evidence

- `mix format --check-formatted` inside `mailglass_admin`: exit 0 (whole package).
- `mix credo --strict` on the four touched Elixir files: no issues.
- `MIX_ENV=test mix mailglass.publish.check --allowlist-only` at the root: exit 0; mailglass_admin allowlist `unchanged`, denylist `unchanged` (the dev/ module never ships).
- Boundary: `git diff --quiet 5d28a9af -- mailglass_admin/priv/static brandbook mix.lock mailglass_admin/mix.lock mailglass_inbound/mix.lock .github/workflows/ci.yml` holds. No token, font, logo, visible copy, dependency or CI job changed. `CLAUDE.md` is untouched since `7a848162`.

### Lane table (which lane proves what)

| Proof | Lane |
|-------|------|
| `--check` as alias step 1; contract test; wiring assertions | REQUIRED: `support_contract_admin` only |
| ubuntu-latest byte equality | REQUIRED lane, first run on the phase PR (pending) |
| `operator_browser_gate`, demo browser evidence | ADVISORY, never cited as proof |

## Files Created/Modified

- `mailglass_admin/assets/css/app.css` - `@source not inline("prose");` with a one-line comment
- `mailglass_admin/dev/mailglass_admin/assets_check.ex` - NEW non-shipped `MailglassAdmin.AssetsCheck` (check/1, run_check!/1, format_error/1)
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` - `--check` flag, strict option parsing, moduledoc with the D-08 input list
- `mailglass_admin/mix.exs` - alias step 1, `verify.preview` re-point, rewritten comment
- `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs` - NEW, 26 cases
- `mailglass_admin/.gitattributes`, `.gitignore`, `lib/mix/tasks/mailglass_admin.assets.watch.ex`, `docs/design-system.md` - stale CI-diff claims rewritten

## Decisions Made

- D-03 inline form, D-01 (no assembly script), D-02 (dev/ module plus guarded `apply/3`), D-04 (existing required lane, no new job), D-05, D-06, D-07 as recorded in the plan; see `key-decisions` above.
- The removed-prose case asserts drift shape, not literal sizes (see Deviation 1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Removed-prose test asserts shape, not the measured sizes**
- **Found during:** Task 2
- **Issue:** The behavior block lists `{:drift, 139137, 136877, 74051}` for the removed-directive case. Hard-coding those makes a required-lane test fail on any legitimate later change to tokens or copy (Phase 181 rewrites tokens and therefore the committed size).
- **Fix:** The test asserts `{:drift, fresh, committed_size, offset}` with `fresh > committed_size` and `offset < committed_size`, and keeps the measured numbers in a comment and in this SUMMARY. The numbers are still reproduced and quoted above.
- **Files modified:** `mailglass_admin/test/mailglass_admin/bundle_reproducibility_contract_test.exs`
- **Committed in:** `e4085d5f`

**2. [Rule 2 - Missing Critical] Two extra teeth cases so mutation (c) can go red**
- **Found during:** Task 2 mutation protocol
- **Issue:** The planned cases flip a byte at offset 1000 and truncate; none touches the last byte, so "compare ignores the last byte" would have stayed green.
- **Fix:** Added `a flipped final byte is drift at the last offset` and `one extra trailing byte is drift at the original length`. Mutation (c) now fails exactly the final-byte case.
- **Files modified:** same test file
- **Committed in:** `e4085d5f`

**3. [Scope boundary] The plan's third Task 3 verify command is red for reasons outside this plan**
- **Found during:** Task 3
- **Issue:** `cd mailglass_admin && MIX_ENV=dev mix docs --warnings-as-errors` exits 1 with 5 distinct pre-existing "documentation references ... but it is hidden" warnings in `docs/api_stability.md` (lines 150, 151, 152, 155) and `lib/mailglass_admin/preview/sidebar.ex:474`. None is in a file this plan touched or names a doc it edited; the CI job `docs_warnings_as_errors` gates root (core) docs only.
- **Fix:** Not fixed (out of scope). Logged in `deferred-items.md`. The docs build itself completed and generated output; no warning mentions `design-system.md`, `AssetsCheck` or the asset tasks.
- **Verification:** warning list inspected file by file against `git diff 5d28a9af..HEAD --name-only`.

**4. [Process] Commit subjects follow the plan's `type(admin):` scope, not `type(180-01):`**
- **Found during:** self-check
- **Issue:** The plan prescribes exact subjects (`chore(admin): ...`, `fix(admin): ...`, `ci(admin): ...`, `test(admin): ...`, `docs(admin): ...`) so Release Please and Guard Release Trigger classify them by kind and package scope (F12). The generic `{type}({phase}-{plan})` format was therefore not used, and `gsd check evaluation-scope --plan 180-01 --commits-only` returns `no-matching-commits` because it matches on that subject token.
- **Fix:** None needed. The authoritative record is the persisted base ledger: `plan_head_before..plan_head_after` in the frontmatter (6 commits, measured with `git rev-list --count`), listed under Task Commits.

---

**Total deviations:** 4 (2 Rule 2 test-strength additions, 1 out-of-scope finding logged, 1 commit-subject process note). **Impact on plan:** none on scope; deviations 1 and 2 make the required-lane test more durable and more sensitive.

## Issues Encountered

None blocking. Small implementation notes: `File.cp_r!` needs the destination parent to exist (the hermetic tree helper creates `mailglass_admin/` first); `OptionParser.parse/2` returns invalid flags with their leading dashes, so the task prints them as given.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path, file-access surface or trust-boundary schema. The Tailwind download path is the existing `tailwind` dep behaviour (T-180-02 accepted in the plan); the check now fails closed on it (T-180-03 mitigated, mutation (a) proves it).

## Follow-ups

- **CLAUDE.md "Things Not To Do" #6 still says CI runs a git-diff of `priv/static`.** Fix in the Phase 183 docs pass (owner sign-off; D-05 defers it). Not edited here.
- **Owner-visible, separate finding:** `warning: MailglassDemo.QuickViewScenarios is not included in any boundary` (`reference/persona_spec/quick_view_scenarios.ex:0`) is pre-existing. It makes `mix compile --warnings-as-errors` exit 1 at HEAD, so the admin `ci.fast` alias and `verify.preview` fail on a cold compile. The new gate deliberately does not couple to a warnings-free compile.
- **Owner-visible, separate finding:** admin `mix docs --warnings-as-errors` is red at HEAD (Deviation 3, `deferred-items.md`).
- **D-07 CI record:** append the first `support_contract_admin` run ID and its `--check` line here and to VERIFICATION once the phase PR runs.
- No test hard-codes `_build`; the cold-start run needed no follow-up for hard-coded build paths.

## Release effect

This plan's `fix(admin):` commit (`22199f22`, `lib/mix/tasks/mailglass_admin.assets.build.ex`) is release-visible: on merge to main Release Please proposes a `mailglass_admin` patch bump. Its `ci(admin):`, `chore(admin):`, `test(admin):` and `docs(admin):` commits are non-bump kinds but are listed in that release PR (only `feat`, `fix` and `!` bump, per `scripts/guard_release_trigger.sh` ~line 140, which classifies by commit kind). The fail-closed `.planning/release-target.json` ledger and the `hex-publish` approval gate still apply unchanged. This phase initiates no release and edits neither the ledger nor any release config.

## Next Phase Readiness

- Plan 180-02 (BRPIPE-02 nested `data-theme` removal) and 180-04 (catalog) can build on a reproducible, gate-green bundle. The platform precondition for 180-04 Task 3 is satisfied (`linux-amd64-cmp: identical` above).
- Removing nested `data-theme` in 180-02 must keep `--check` green: it changes `lib/` text and Tailwind scans it, so run `mix mailglass_admin.assets.build --check` after every `lib/` edit that adds text (P1).
- Phase 181 edits `brandbook/tokens.css`; regenerate the bundle through `mix mailglass_admin.assets.build` and commit it in the same change, or this lane goes red by design.

---
*Phase: 180-reproducible-admin-bundle-and-before-catalog*
*Completed: 2026-11-15*

## Self-Check: PASSED

- Created files exist on disk: `assets_check.ex`, `bundle_reproducibility_contract_test.exs`, `deferred-items.md`, plus the four modified source files.
- All six task commits are ancestors of HEAD: `3c24adab`, `c8bea866`, `22199f22`, `ed286cb8`, `e4085d5f`, `78f5e92a`.
- Task 1 acceptance greps hold: directive count 1, `--check` alias count 2, old `cmd git diff` step count 0, `Tailwind.` references in the shipped task 0, `priv/static` unchanged since `5d28a9af`.
- `linux-amd64-cmp:` machine line appears exactly once.
