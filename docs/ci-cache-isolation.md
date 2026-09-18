# CI Cache Isolation (GREEN-05)

**Question this note closes:** FINDINGS.md FG-4 raised the possibility that the two
trust lanes (`trust_lane_repo_head`, `trust_lane_clean_baseline`) could restore a
`actions/cache` entry populated by a *different* job — for example a cache saved by
`support_contract_core` or `core_deterministic_suite`, which install `mailglass`,
`mailglass_inbound`, and `reference/demo_app` (and, for the latter,
`reference/host_app`) path deps against the working tree — and end up compiling
against a different, contaminated dependency tree than the one the trust lane
itself resolves and tests.

**Verdict, stated up front:** FG-4 is refuted, by construction (Part 1) and by two
closing facts about what the trust lanes actually cache and resolve (Part 1 §
Closing facts). Part 2 supplies the CI-observed restore evidence that the
by-construction argument predicts. Part 3 supplies a local lock-authority proof
that the trust lanes resolve the pinned 2.0.0 line, not "live" 2.6.0/2.6.0/2.3.0 —
closing the second, previously-unestablished half of the FG-4 premise.

---

## Part 1 — Key-space table

Every `actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9` (v6.1.0) step in
`.github/workflows/ci.yml`, one row per step, with the declared `path:` list
verbatim and the `key:` expression:

| Job | `path:` (verbatim) | `key:` expression |
|---|---|---|
| `compile_warnings` | `deps` | `mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV \|\| 'dev' }}-${{ hashFiles('**/mix.lock') }}` |
| `compile_no_optional_deps` | `deps` | same `mix-…` expression |
| `support_contract_core` | `deps`, `mailglass_inbound/deps`, `reference/demo_app/deps` | same `mix-…` expression |
| `mix_task_tests` | `deps` | same `mix-…` expression |
| `core_deterministic_suite` | `deps`, `mailglass_inbound/deps`, `reference/host_app/deps`, `reference/demo_app/deps` | same `mix-…` expression |
| `inbound_test` | `deps`, `mailglass_inbound/deps` | same `mix-…` expression |
| `inbound_compile_no_optional_deps` | `deps`, `mailglass_inbound/deps` | same `mix-…` expression |
| `credo_strict` | `deps` | same `mix-…` expression |
| `dialyzer` (deps cache) | `deps` | same `mix-…` expression |
| `dialyzer` (PLT cache) | `_build/test/*.plt` | `plt-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ hashFiles('**/mix.lock') }}` |
| `docs_warnings_as_errors` | `deps` | same `mix-…` expression |
| `hex_audit` | `deps` | same `mix-…` expression |
| `deps_audit_advisory` | `deps` | same `mix-…` expression |
| `installer_golden_gate` | `deps` | same `mix-…` expression |
| `support_contract_admin` | `deps`, `mailglass_admin/deps` | same `mix-…` expression |
| `operator_browser_gate` | `deps`, `mailglass_admin/deps` | same `mix-…` expression |
| `preview_capture_advisory` | `deps`, `mailglass_admin/deps` | same `mix-…` expression |
| `trust_lane_repo_head` | `deps` | `mix-trust-repo-head-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV \|\| 'dev' }}-${{ hashFiles('**/mix.lock') }}` **(disambiguated, this plan)** |
| `trust_lane_clean_baseline` | `deps` | `mix-trust-clean-baseline-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV \|\| 'dev' }}-${{ hashFiles('**/mix.lock') }}` **(disambiguated, this plan)** |

`inbound_dialyzer` uses the composite action `./.github/actions/setup-beam-mix`
rather than a direct `actions/cache` step in `ci.yml`, so it is outside this
table's scope (it is not a `mix-`-keyed `actions/cache` step here).

**Distinct path lists, grouped:**

1. `deps` — 11 steps (`compile_warnings`, `compile_no_optional_deps`,
   `mix_task_tests`, `credo_strict`, `dialyzer` deps cache,
   `docs_warnings_as_errors`, `hex_audit`, `deps_audit_advisory`,
   `installer_golden_gate`, `trust_lane_repo_head`, `trust_lane_clean_baseline`).
2. `deps` + `mailglass_inbound/deps` + `reference/demo_app/deps` — 1 step
   (`support_contract_core`).
3. `deps` + `mailglass_inbound/deps` + `reference/host_app/deps` +
   `reference/demo_app/deps` — 1 step (`core_deterministic_suite`).
4. `deps` + `mailglass_inbound/deps` — 2 steps (`inbound_test`,
   `inbound_compile_no_optional_deps`).
5. `deps` + `mailglass_admin/deps` — 3 steps (`support_contract_admin`,
   `operator_browser_gate`, `preview_capture_advisory`).

That is **five distinct path lists** sharing the `mix-` key-string prefix (18
`actions/cache` steps total across those five groups), plus the separate
`plt-`-keyed PLT cache on `dialyzer` (not part of the `mix-` key space at all).
**The shared key *string* therefore produces five independent cache entries, not
one shared cache** — before this plan's key-segment change, groups 1's 11 members
(including both trust lanes) shared a single cache entry per unique
`hashFiles('**/mix.lock')` value; after this plan's change, the two trust lanes
each have their own entry, disjoint from the other 9 members of group 1 too.

**Mechanism (why this table demonstrates non-contamination rather than asserting it):**

- `actions/cache` computes the cache **version** by SHA-256-hashing the declared
  `path` list (`packages/cache/src/internal/cacheUtils.ts`, `getCacheVersion`).
  The cache service filters candidate entries by that version before it ever
  considers the `key`/`restore-keys` strings. A step whose `path:` is `deps`
  alone can never be served an entry saved under `path: deps, mailglass_admin/deps`
  — the version hash differs, so the candidate is filtered out server-side.
  `restore-keys` **prefix matching operates only within a version**, so it
  cannot rescue a cross-version (cross-path-list) mismatch. This is why group 1
  (bare `deps`) and group 5 (`deps` + `mailglass_admin/deps`) can never collide
  even though `support_contract_admin`'s key literally starts with the same
  `mix-${{ runner.os }}-…` prefix as `trust_lane_repo_head`'s pre-this-plan key
  did.
- Cache **restore** calls `extractTar` with no path argument: it extracts the
  saved archive's full contents into `$GITHUB_WORKSPACE`, all-or-nothing. There
  is no mechanism for a restore to selectively materialize only some of a saved
  archive's paths into the workspace, or to leave part of a differently-shaped
  archive un-extracted. So even setting the version-hash gate aside, "partial
  contamination" is not a mechanism `actions/cache` exposes.

### Closing facts (D-14)

- **Neither trust lane caches `reference/host_app/deps` at all.** Both jobs'
  cache step declares `path: deps` only (group 1, above) — confirmed directly in
  the table. The jobs that *do* save `reference/host_app/deps` are
  `support_contract_core` (group 2) and `core_deterministic_suite` (group 3).
  Those two use different path lists (and thus different cache versions) than
  either trust lane, so even a same-run cache save from
  `core_deterministic_suite` could not be restored by a trust lane's `deps`-only
  cache step.
- **The trust lanes' `deps.get` still honors `reference/host_app/mix.lock`.**
  Confirmed directly in Part 3 below: the pinned line is `2.0.0` for all three
  sibling packages, and a real local `mix deps.get` against that lock reports
  "All dependencies are up to date" with zero changes. So the "resolving live
  2.6.0/2.6.0/2.3.0" half of the FG-4 premise was never established either —
  the trust lanes resolve exactly what the committed lock pins.

---

## Part 2 — CI-observed restore evidence

*Populated from the first real CI run of this PR (Task 3 — post-merge evidence).*

**Status at time of writing:** not yet populated. The lane-specific key segment
landed in this commit for the first time, so the first CI run on this branch is
expected to report a **cache MISS** for both trust lanes — see the cold-start
caveat below. That miss is itself part of the evidence this Part records: a
`Cache not found for input keys: mix-trust-repo-head-…` / `mix-trust-clean-baseline-…`
line, followed by the new listing step showing `reference/host_app/deps` absent
before `deps.get` runs (nothing was restored to seed it, and no other job's
cache path list includes it).

Run URL, restore log lines, and listing-step output are pasted here by Task 3
after the PR's CI has actually run — see 166-05-SUMMARY.md for whether Task 3
completed synchronously as part of this plan or was deferred as
`external_job_waiting`.

---

## Part 3 — Lock-authority proof

Local run (2026-09-17, this plan, toolchain 1.18.4/OTP 27.3.4.15), matching
exactly what both trust lanes' `mix deps.get` (`working-directory:
reference/host_app`, `env: MIX_ENV: dev`) does:

```
$ grep -n 'mailglass' reference/host_app/mix.lock
  "mailglass": {:hex, :mailglass, "2.0.0", ...}
  "mailglass_admin": {:hex, :mailglass_admin, "2.0.0", ...}
  "mailglass_inbound": {:hex, :mailglass_inbound, "2.0.0", ...}

$ cd reference/host_app && MIX_ENV=dev mix deps.get
...
All dependencies are up to date
```

`git status --short reference/host_app/` reports no changes after the run — the
lock was not rewritten, confirming `deps.get` resolved to the values already
pinned rather than to any newer published version. The committed
`reference/host_app/mix.lock` pins `mailglass`, `mailglass_admin`, and
`mailglass_inbound` at **`2.0.0`** — not the live-published `2.6.0` / `2.6.0` /
`2.3.0` line (`.planning/release-target.json` baselines). "Resolving live 2.6.0"
was never the trust lanes' behavior; this closes that half of FG-4 with direct
observation rather than inference.

---

## Verdict

**FINDINGS.md FG-4 is refuted by construction.** `actions/cache`'s version-hash
gate (Part 1) makes a cross-path-list cache collision structurally impossible;
neither trust lane declares `reference/host_app/deps` as a cached path at all
(D-14, Part 1 closing facts); and the trust lanes' dependency resolution honors
the committed `reference/host_app/mix.lock` at `2.0.0`, not a live published
version (Part 3). The lane-specific cache-key segment added alongside this note
is additional belt-and-braces disambiguation, not the mechanism that makes
cross-lane contamination impossible — the version-hash gate already does that.

## Cold-start caveat (D-16)

This PR changes the `key:` (and `restore-keys:`) of both trust lanes' cache
steps. Changing a cache step's `key`/`restore-keys` — like changing its `path:`
list — creates a brand-new cache entry namespace. The **first** CI run on this
branch (and the first run after merge to `main`) is therefore expected to report
a cache **miss** — `Cache not found for input keys: mix-trust-repo-head-…` /
`mix-trust-clean-baseline-…` — for both trust lanes. This is a one-run slowdown
(a fresh `mix deps.get` instead of a cache-warmed one), **not a regression**.
Subsequent runs on the same branch/lock-hash populate and then hit the new,
disambiguated entries normally.
