# Phase 166: Earned Greens and Controls That Can Pass - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-09-17
**Phase:** 166-earned-greens-and-controls-that-can-pass
**Mode:** assumptions
**Calibration:** minimal_decisive (`config.json` `preferences.vendor_philosophy: opinionated`)
**Areas analyzed:** Admin lane truth (GREEN-01/02), Suite floor and its drift guard (GREEN-03),
Demo Hex pins and the trust-lane cache (GREEN-04/05), Controls (CTRL-01..05), PR slicing under WIP-1

## Methodology Lenses Applied

`.planning/METHODOLOGY.md`:

- **Decisive-By-Default Research Posture** — applied. Two research passes (codebase analyzer +
  external research) were run before any question reached the user; 36 of 38 decisions were locked
  from evidence without escalation.
- **Recommendation-First Synthesis** — applied. Only two items were escalated, both meeting the
  "materially changes long-term maintainer burden or an explicit project constraint" bar: the
  `lib/` scope-constraint collision and the expiry-extension policy call. Both were presented
  recommendation-first.
- **Honest Surface Area** — flagged and binding on CTRL-04: the `:reason` rewrite exists precisely
  because the current text ("no upstream fix as of cowlib 2.19.0") implies a pending fix that will
  never arrive.
- **Compatibility Contract Ergonomics** — not triggered; this phase changes no public contract.

## Assumptions Presented

### Admin lane truth (GREEN-01, GREEN-02)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Redefine `verify.support_contract.admin` itself; do NOT route via `verify.preview` (asset-rebuild landmine) | Confident | `mailglass_admin/mix.exs:208`, `:202-207`; `mix.exs:435`, `:328`; `ci_parity_drift_test.exs:184`; `ci.yml:916-917` |
| Exclusions need no work | Confident | `mailglass_admin/test/test_helper.exs:1`; `voice_test.exs:112`; `axe_baseline_test.exs:26-30` |
| 510 tests have never run under `--warnings-as-errors`; budget a test-file cleanup, keep the flag | Likely | `mix.exs:208` scopes the flag to 9 files; FINDINGS.md:22 measured 510/0 under bare `mix test` |
| GREEN-02 requires first adding ExCoveralls to admin, then a measured baseline with no margin | Confident | no `excoveralls`/`test_coverage:` in `mailglass_admin/mix.exs`; cf. `mailglass_inbound/mix.exs:22,129`; `scripts/check_coverage_floor.sh:11-15`; `config/coverage_baselines/core.json:8` |

### Suite floor and its drift guard (GREEN-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The roadmap's literal "2 → 3" bump is WRONG and would red the drift test; the constant counts `advisory-matrix.yml` only | Confident | `lane_classification_drift_test.exs:43`, `:592-641`, `:1280-1286`; `test/support/suite_floor.ex:798` is the only other reader |
| The real work is extending the guard to `ci.yml` (new constant + anti-vacuity + negative control) | Confident | same |
| Floor passes on today's numbers with no re-pinning | Likely | `suite_floor.ex:286-289`, `:307`, `:693-711`, `:245-259`; `ci.yml:446-452`; FINDINGS.md:20 |
| Residual risk: this lane does not exclude `:requires_workspace` — demonstrate locally first | Likely | `ci.yml:446-452` has no CLI `--exclude` |

### Demo Hex pins and the trust-lane cache (GREEN-04, GREEN-05)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| GREEN-04 is a NEW isolated build; never a flip of existing path-dep demo steps | Confident | `reference/demo_app/mix.exs:60-76`; `reference/demo_app/mix.lock:21-23`; `ci.yml:276-281`, `:424-437` |
| FINDINGS FG-4's cache-contamination premise is refuted by construction | Confident (upgraded by external research) | `actions/cache` `getCacheVersion` hashes `paths` into the cache version; `extractTar` takes no path arg; `ci.yml` 19 cache steps / 5 path lists = 4 independent entries |
| Neither trust lane caches `reference/host_app/deps`, and resolution is lock-pinned at 2.0.0 | Confident | `ci.yml:1206`, `:1291` (`path: deps` only); savers at `:261-270`, `:403-413`; `reference/host_app/mix.lock:20-22` |
| The note must demonstrate (key-space table + measured pre-`deps.get` listing + lock-authority proof), not assert | Confident | requirement's explicit "'probably fine' does not satisfy this" clause |

### Controls (CTRL-01..CTRL-05)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| CTRL-01 is four coordinated edits (verb + dispatch mode + cron-guard predicate + digest-free baseline check) | Confident | `post-publish-smoke.yml:15-30`, `:73-78`, `:263-265`, `:285-288`; `release_policy.exs:332-345`, `:620-624`; `scripts/check_post_publish_target.sh:86-98` |
| CTRL-02 = delete the early `exit 0`, resurrecting dead code — not new preflight logic | Confident | `release-please.yml:90-94`, `:101`, `:127-132`, `:145-167`, `:298` |
| CTRL-03 retry belongs at the two `gh api` sites + one guarded action re-run; gate at `:736-739` untouched | Likely → Confident (research-pinned) | `release-please.yml:119`, `:179`, `:292-306`; already-classifying steps `:457-460`, `:497-510`, `:677-687` |
| Retry policy: match 403 OR 429 + `/secondary rate/i`; 60s floor; ×2; 3 attempts; then hard-fail | Confident | GitHub REST rate-limit docs (normative 60s floor, no documented max count) |
| Do NOT model on octokit / `actions/github-script` defaults (sub-60s, 403 exempt); no pre-flight probe is buildable | Confident | `@octokit/plugin-retry` `doNotRetry` includes 403, quadratic 1/4/9s; `github-script` `retries: "0"`, exempts 403; GitHub: no way to check secondary-limit status |
| CTRL-04: entries stay; no fix exists or will | Confident (source-verified) | OSV `EEF-CVE-2026-43966`/`-43969`: no `fixed` event, 2.20.0 listed, modified 2026-09-09 (cowlib 2.20.0 published 2026-09-08); cowlib 2.20.0 source unchanged |
| CTRL-04: no upgrade escape — "bump cowlib" steps are struck | Confident | cowboy 2.19.0 (latest) requires `cowlib >= 2.20.0`; 2.20.0 is latest |
| CTRL-04: `:reason` already carries the justification; no schema field needed | Confident | `accepted_advisories.ex:62-89` |
| CTRL-04: no in-process clock fake exists and none may be added | Confident | `dev/mix/tasks/mailglass.audit.ex:145`; `accepted_advisories.ex:188` |
| CTRL-04: two-file lockstep; `:168-174` currently asserts the negation of the criterion | Confident | `accepted_advisories_test.exs:155,159,168-174,177` |
| CTRL-05: split `cannot_check` to its own non-zero code + widen the `--json` fields for the new predicate | Confident | `mailglass.repo.hygiene.ex:46-48`, `:280-292`, `:294-305`, `:427-433`; `repo-hygiene.yml:38-45` |

## Corrections Made

No assumptions were corrected. Two items were escalated as genuinely strategic forks under
METHODOLOGY's Recommendation-First Synthesis; the user selected the recommended option on both.

### CTRL-04 — collision with the milestone's "no product code changes" constraint
- **Question:** the milestone names DOCS-05's `css_inliner` as the *single* permitted `lib/` change
  (and that is in Phase 167), yet CTRL-04 necessarily edits
  `lib/mailglass/supply_chain/accepted_advisories.ex`.
- **Options presented:** data-only exemption stated explicitly (recommended) / relocate the allowlist
  data out of `lib/` / defer CTRL-04 to Phase 167.
- **User selection:** **data-only exemption, stated explicitly** → D-31.
- **Alternatives rejected:** relocation is a structural refactor of a supply-chain control inside a
  5-day timebox; deferral forfeits the calendar buffer against the 2026-10-27 red.

### CTRL-04 — new `recheck_by` value
- **Question:** given a permanently declined upstream fix, the current ~3-month cadence re-asks a
  settled question, but the standing prohibition forbids deleting or defanging an expiry.
- **Options presented:** `~D[2027-03-17]` 6 months (recommended) / `~D[2026-12-26]` keep ~3 months /
  `~D[2027-09-17]` 12 months.
- **User selection:** **`~D[2027-03-17]` (6 months)** → D-30.
- **Rationale carried forward:** halves the churn while keeping the expiry real and fail-closed;
  requires the reason to name a cheap falsifiable re-check (a cowlib release > 2.20.0 that validates
  input, or an OSV `fixed` event). 12 months was rejected as long enough that a cowlib 3.0 — which
  the maintainer signalled would undocument the functions — could go unnoticed.

## External Research

Three topics were flagged by the codebase analyzer as unresolvable from the tree alone. All three
returned findings that **changed** planning decisions rather than merely confirming them.

- **cowlib `EEF-CVE-2026-43966` / `-43969` upstream status at 2.20.0:** no fix exists and none is
  expected. Six fix PRs (ninenines/cowlib #154, #163, #164, #165, #166, #169) all closed unmerged;
  maintainer position *"Both CVEs are invalid… Neither Gun nor Cowboy are vulnerable"*
  (ninenines/cowlib#167, 2026-08-06). OSV re-confirmed 2.20.0 affected on 2026-09-09, one day after
  2.20.0 shipped; SEMVER range carries `introduced: 2.9.0` and **no** `fixed` event. Verified in
  2.20.0 source that `cow_cookie:cookie/1` and `cow_http_struct_hd:escape_string/2` are unchanged.
  No upgrade escape: cowboy 2.19.0 (latest) requires `cowlib >= 2.20.0 and < 3.0.0`. Mitigation is
  framework-layer (Cowboy 2.16.0+ `invalid_response_headers`, Gun 2.4.0+ `invalid_request_headers`).
  Entries are kept "used" solely by the `mailglass_admin` scan.
  *Sources:* api.osv.dev/v1/vulns/EEF-CVE-2026-43966 and -43969; cna.erlef.org/cves/;
  raw cowlib 2.20.0 `src/cow_cookie.erl` + `src/cow_http_struct_hd.erl`; ninenines/cowlib issues
  #152/#155/#167 and PRs #154/#163/#164/#165/#166/#169; ninenines.eu/articles/security-strategy/;
  hex.pm/api/packages/{cowlib,cowboy}; mirego/elixir-security-advisories `GHSA-g2wm-735q-3f56.yml`.
  *Confidence impact:* resolves CTRL-04's disposition to **extend-with-rewritten-justification** at
  very high confidence, and **strikes any "bump cowlib to clear the audit" plan step**.

- **GitHub secondary-rate-limit retry guidance:** the normative contract is a 60-second floor with no
  documented maximum retry count; classify on **403 or 429** plus a `/secondary rate/i` body match,
  never on headers; `retry-after` → `x-ratelimit-reset` (only when remaining==0) → 60s fallback;
  exponential escalation; a cap must exist but its value is project policy. There is **no way to
  check secondary-limit status**, so no pre-flight probe is buildable. Library defaults are all worse
  than GitHub's own guidance: `@octokit/plugin-retry` lists 403 in `doNotRetry` and uses quadratic
  1/4/9s; `actions/github-script` bundles retry but not throttling, defaults `retries: "0"`, exempts
  403 — and `googleapis/release-please-action` inherits that posture, which is why a guarded outer
  re-run is the only lever. `gh` has no retry and no `--retry` flag (cli/cli#3292).
  *Sources:* docs.github.com REST rate-limits + best-practices pages;
  octokit/plugin-throttling.js and plugin-retry.js sources; actions/github-script `action.yml` and
  `src/retry-options.ts`; cli/cli#3292.
  *Confidence impact:* raises CTRL-03's retry design to high confidence and **corrects a likely
  planning assumption** — modelling the loop on octokit or `github-script` defaults would produce a
  loop that looks correct and never waits long enough.

- **`actions/cache` restore semantics:** the `path` list is SHA-256-hashed into the cache **version**
  and filtered server-side, so same-key/different-path is a **total miss**, not a partial extraction;
  `restore-keys` prefix matching cannot rescue a version mismatch. Restore calls `extractTar` with no
  path argument — extraction is all-or-nothing into `$GITHUB_WORKSPACE`.
  *Sources:* actions/toolkit `packages/cache/src/internal/cacheUtils.ts` (`getCacheVersion`),
  `internal/tar.ts`, `cache.ts`; actions/cache README § Cache Version; actions/cache issues
  #1444/#1653/#1229/#1454; actions/toolkit #1579 / PR #1378.
  *Confidence impact:* **inverts GREEN-05's premise.** The contamination mechanism is refuted by
  implementation, not merely unobserved — which is what lets the committed note clear the "a
  'probably fine' verdict does not satisfy this" bar. Also adds a plan-visible caveat: changing any
  existing `path:` list cold-starts that cache (a one-run slowdown, not a regression).
