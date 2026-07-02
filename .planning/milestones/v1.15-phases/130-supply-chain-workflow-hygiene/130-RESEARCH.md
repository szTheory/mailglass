# Phase 130: Supply Chain + Workflow Hygiene — Research

**Researched:** 2026-07-01
**Domain:** GitHub Actions CI/CD, mix_audit, OSV.dev API, GitHub Actions supply-chain tooling
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **SUPPLY-01 (LD-4):** `mix deps.audit` runs advisory (non-blocking) on PR; blocks only at the publish gate. Must never red an open PR under an unfixable-advisory wave.
- **SUPPLY-02:** `dependabot.yml` watches `mailglass_admin` and `mailglass_inbound` sibling locks. `reference/` apps are EXCLUDED (frozen deterministic baselines).
- **SUPPLY-03 (LD-4):** Cowlib `@accepted_advisories` OSV-staleness forcing function: loud CI warning on every run + hard block at publish; fail-OPEN on OSV API outage.
- **SUPPLY-04 (LD-11):** `actionlint` gates `.github/workflows/**` changes on PR. Add `actions/dependency-review-action` (SHA-pinned). Scaffolding EXISTS — close the gap.
- **SUPPLY-05 (LD-13):** Add Elixir 1.19 / OTP 28 advisory row to `advisory-matrix.yml`; runs push+cron ONLY (NEVER on PR, NEVER blocking). Document floor-coincidence invariant. CONTEXT.md confirms advisory-matrix currently triggers on PR — must remove that trigger for the 1.19 row, or scope triggers per-job (not possible in YAML) — the solution is to split the 1.19 row into a separate `if:` condition or separate file. See SUPPLY-05 gap below.
- **Out of scope:** No `lib/` changes; no Dialyzer promotion (LD-7); no release cut (Phase 131); no `deps.unlock --check-unused` cleanup.

### Claude's Discretion

- Exact mix_audit dep version (use latest: `2.1.5`)
- Alias wiring for `mix ci` (add `deps.audit` step)
- OSV-staleness check implementation shape
- `dependency-review-action` SHA pin
- Whether the advisory row lives in `advisory-matrix.yml` or a new workflow

### Deferred Ideas (OUT OF SCOPE)

- Dialyzer / format / credo / compile-warnings promotion to required (LD-7)
- Real Hex release cut + consumer/post-publish smoke (LD-1) — Phase 131
- `deps.unlock --check-unused` orphaned-transitive cleanup
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUPPLY-01 | `mix deps.audit` advisory on PR, blocking at publish gate | mix_audit 2.1.5 verified; ci.yml advisory-lane pattern exists; publish.check.ex Step 13 is the hook point |
| SUPPLY-02 | dependabot.yml watches admin + inbound sibling locks | Both `mailglass_admin/mix.lock` and `mailglass_inbound/mix.lock` exist; reference/ must be excluded |
| SUPPLY-03 | OSV-staleness forcing function for @accepted_advisories | OSV batch API `/v1/query` confirmed; fail-open pattern clear; audit_allowlist_test.exs is the test seam |
| SUPPLY-04 | actionlint gates workflow PRs; add dependency-review | actionlint.yml already exists and does gate PRs; gap is dependency-review only |
| SUPPLY-05 | 1.19/OTP 28 advisory row, push+cron only, LD-13 invariant documented | OTP 28.5+ and Elixir 1.19.0 released; setup-beam supports both; advisory-matrix.yml currently fires on PR — must fix trigger scope |
</phase_requirements>

---

## Summary

Phase 130 is the supply-chain hardening layer for the v1.15 milestone. It adds five complementary guards: a `mix deps.audit` advisory PR lane that CANNOT red an open PR (SUPPLY-01), dependabot coverage for the two sibling packages (SUPPLY-02), a staleness-forcing-function for the cowlib OSV allowlist (SUPPLY-03), confirmation and completion of the actionlint+dependency-review gate (SUPPLY-04), and a 1.19/OTP28 advisory matrix row with a documented floor-coincidence invariant (SUPPLY-05).

The core design invariant — a supply-chain guard must NEVER red an open PR under an unfixable transitive CVE — shapes every decision. The advisory-on-PR / block-at-publish asymmetry is deliberately testable without a real CVE, using publish.check.ex's `unaccepted_audit_findings/1` function and the existing `AuditAllowlistTest` fixture pattern.

The true scope delta is smaller than the ROADMAP prose implies: SUPPLY-04 (actionlint) is ~90% done — the workflow exists, fires on PR, lints workflow files, and is SHA-pinned. The gap is adding `actions/dependency-review-action`. SUPPLY-05 is a single matrix row addition but requires fixing advisory-matrix.yml's current `pull_request:` trigger (it currently fires on PR, contradicting SUPPLY-05's push+cron-only requirement).

**Primary recommendation:** Implement in two plans — Plan 01 covers the pure YAML/config additions (SUPPLY-02, 04, 05), Plan 02 covers the Elixir code additions (SUPPLY-01 ci.yml lane + mix.exs dep, SUPPLY-03 OSV check in publish.check.ex + tests).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Advisory dep scan on PR | CI/CD (ci.yml advisory lane) | mix.exs (dep declaration) | The scan is a CI job; the tool is a dev-only dep |
| Blocking dep scan at publish | API/Backend (publish.check.ex Step N+1) | — | publish.check.ex already owns the allowlist lifecycle (Step 13 hex.audit) |
| OSV allowlist staleness check | API/Backend (publish.check.ex) + CI (every-run warning) | — | Elixir inline in publish.check.ex is testable; CI step emits the warning |
| Dependabot sibling coverage | CI config (dependabot.yml) | — | Pure YAML; no code involved |
| Actionlint + dependency-review | CI config (actionlint.yml) | — | Existing workflow extended with one action |
| 1.19/OTP28 advisory row | CI config (advisory-matrix.yml) | — | Single matrix entry, trigger-scoped |

---

## 1. Current-State → Gap Delta per SUPPLY Item

### SUPPLY-01 — `mix deps.audit` (mix_audit)

**What exists:**
- `ci.yml` has a `hex_audit` job (line 528–551) that runs `mix hex.audit` on PR — **advisory, not required** (not in `ci_green.needs`). `[VERIFIED: live file read]`
- `publish.check.ex` Step 13 runs `mix hex.audit` inside the isolated tarball audit root (lines 1040–1073) with the `@accepted_advisories` allowlist. `[VERIFIED: live file read]`
- `mix_audit` (`:mix_audit`) is **not in `mix.exs` deps** — confirmed by grep. `[VERIFIED: live file read]`
- No `deps.audit` alias exists in `mix.exs` `aliases`. `[VERIFIED: live file read]`
- No `mix deps.audit` step exists anywhere in `ci.yml`. `[VERIFIED: live file read]`

**What must be added:**
1. `mix.exs`: Add `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}` — dev-only tool, not shipped to adopters. `[VERIFIED: Hex]` — latest is `2.1.5` (2025-06-09).
2. `ci.yml`: Add a `deps_audit_advisory` job after the `hex_audit` job, with `continue-on-error: true` (or equivalent), name that sorts advisory via the `isAdvisory()` regex in publish-hex.yml (`/ Advisory \(/.test(jobName)`) — name it `Deps Audit Advisory (Elixir 1.18 / OTP 27)` so it matches the publish gate's advisory pattern automatically.
3. `publish.check.ex`: Add a Step 14 `run deps.audit` that calls `mix deps.audit` in the tarball audit root with the **same** `@accepted_advisories` allowlist logic (parallel to `verify_audit/1`). This blocks delivery if `mix deps.audit` reports findings not in the allowlist.
4. `mix.exs` aliases: Add `deps.audit` to the `ci` alias (after `hex.audit`) so local parity is maintained.
5. `Mailglass.CILanes` (`test/support/ci_lanes.ex`): Add `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` to `@advisory_lanes_ci`. Also add a matcher to `ci_parity_drift_test.exs`. These are needed by the GATE-03 meta-test and MIXCI-03 parity-drift test — see Pitfalls section.

**Why `mix deps.audit` complements rather than replaces `mix hex.audit`:**
- `mix hex.audit` (built-in Hex tool) checks against the Hex security advisory database (hex.pm advisories). `[ASSUMED]`
- `mix deps.audit` (mix_audit) checks against the elixir-security-advisories GitHub DB (a different, community-maintained database with broader coverage). `[CITED: github.com/mirego/mix_audit]`
- Both databases have overlapping but non-identical coverage — running both increases advisory detection breadth. `[ASSUMED]`
- The publish gate runs BOTH: `hex.audit` at Step 13 (exists), `deps.audit` at new Step 14 (to add).

### SUPPLY-02 — dependabot sibling coverage

**What exists:**
- `.github/dependabot.yml` (5 lines): one `mix` entry at `directory: "/"` (weekly) and one `github-actions` entry at `directory: "/"` (weekly). `[VERIFIED: live file read]`
- `mailglass_admin/mix.lock` — **exists**. `[VERIFIED: ls output]`
- `mailglass_inbound/mix.lock` — **exists**. `[VERIFIED: ls output]`
- `reference/host_app/mix.lock` and `reference/demo_app/mix.lock` — both **exist** and must be EXCLUDED (frozen deterministic baselines per reference-baseline-coupling constraint). `[VERIFIED: ls output]`

**What must be added:**
Two `mix` ecosystem entries:
```yaml
- package-ecosystem: "mix"
  directory: "/mailglass_admin"
  schedule:
    interval: "weekly"
- package-ecosystem: "mix"
  directory: "/mailglass_inbound"
  schedule:
    interval: "weekly"
```
No entries for `reference/host_app` or `reference/demo_app`. No open-PR-limit is set on the existing entries, so none is needed on the new ones (inherit default of 5). `[ASSUMED]`

**Gap:** 2 YAML stanzas to add. Total effort: trivial.

### SUPPLY-03 — OSV-staleness forcing function

**What exists:**
- `publish.check.ex` `@accepted_advisories` at lines 60–65: two cowlib advisory IDs with inline rationale comments. `[VERIFIED: live file read]`
- `test/mailglass/publish/audit_allowlist_test.exs` — tests `unaccepted_audit_findings/1` with fixture output strings, including an existing test for "accepts only unfixable cowlib advisories." `[VERIFIED: live file read]`
- No OSV check exists anywhere in the codebase or CI. `[VERIFIED: grep]`

**What must be added:**

**Implementation shape — inline Elixir in publish.check.ex (recommended over shell):**

Rationale: testable in `AuditAllowlistTest`; shares the same Elixir process; the fail-open path is explicit in a `try/rescue` or `with` clause. A shell script would require spawning a process, piping JSON, and has no natural unit-test seam.

Concrete mechanism:
1. In `publish.check.ex`, add a private function `check_osv_advisory_staleness/1` that, for each entry in `@accepted_advisories`:
   a. Queries the OSV.dev batch API: `POST https://api.osv.dev/v1/querybatch` with `{"queries": [{"package": {"name": "cowlib", "ecosystem": "Hex"}, "version": "<version>"}]}`  or uses the advisory-lookup endpoint `GET https://api.osv.dev/v1/vulns/<advisory-id>` to check if the advisory still exists.
   b. If the OSV API returns the advisory as STILL OPEN (no `withdrawn` field): the allowlist entry is CURRENT — log a notice.
   c. If the OSV API returns that the advisory has been **withdrawn** or lists a **fixed version** now available: the allowlist entry is STALE — this is a forcing event.
   d. If the OSV API request fails (network error, timeout, non-200): **FAIL-OPEN** — log a loud warning and continue.

2. Wire into `publish.check.ex` in two places:
   - **Every `mix mailglass.publish.check` run** (not just the publish gate): emit a `IO.puts(:stderr, "[publish.check] WARNING: OSV staleness check...")` warning even for accepted advisories on every invocation. This is the "loud CI warning on every run."
   - **At the publish step**: the staleness check result is **blocking** — if an allowlist entry is confirmed stale (OSV withdrew or fixed), `fail_step/2` blocks delivery.
   - **Fail-open** on network error: use `try/rescue` or `{:ok, _} / {:error, _}` pattern; network error falls through to a log warning, does NOT block.

3. **Test seam**: Add tests to `audit_allowlist_test.exs` (or a new `osv_staleness_test.exs`) using Mox or process-level injection to mock HTTP responses. The test cases:
   - OSV returns advisory exists → allowlist is current → no block
   - OSV returns advisory withdrawn → allowlist is stale → block
   - OSV API network error (exception) → fail-open → no block

**OSV API endpoint (authoritative):** `https://api.osv.dev/v1/vulns/<ID>` where `<ID>` is e.g. `EEF-CVE-2026-43966`. The response includes a `withdrawn` field (ISO date string) if the advisory was withdrawn. A missing `withdrawn` field means still active. `[ASSUMED — OSV API structure from training knowledge; verify against https://google.github.io/osv.dev/api/]`

**HTTP client**: Use `:httpc` (OTP built-in, already in `extra_applications`). No new dep required.

### SUPPLY-04 — actionlint gap + dependency-review

**What exists:**
- `.github/workflows/actionlint.yml` — **fully functional**. Triggers on `pull_request` against `main` when `.github/workflows/*.yml|*.yaml` or `scripts/check_tests_gate.sh` change. Runs `rhysd/actionlint@914e7df...  # v1.7.12` SHA-pinned. Also verifies the Tests-gate halt-on-failure property. `[VERIFIED: live file read]`

**SUPPLY-04 gap assessment:**

| Sub-requirement | Status | Gap |
|----------------|--------|-----|
| `actionlint` gates workflow PRs on `.github/workflows/**` | DONE | None — already fires on PR, SHA-pinned v1.7.12 |
| Fails a malformed workflow PR | EFFECTIVELY DONE | actionlint's job exits non-zero on actionlint errors; the `pull_request` trigger means it will fail a malformed-workflow PR |
| `actions/dependency-review-action` added | MISSING | Must add one step |
| All third-party actions SHA-pinned | DONE (for existing) | New dep-review action needs SHA pin |

**What must be added:**
Add `actions/dependency-review-action` as a step in `actionlint.yml`. This action checks manifests (mix.lock) changed in a PR for known vulnerabilities.

Latest release: `v5.0.0` — SHA `a1d282b36b6f3519aa1f3fc636f609c47dddb294`. `[VERIFIED: GitHub API]`

The step requires `contents: read` AND `pull-requests: write` permissions (to post PR comments), or `read` only if no comment posting. Since this is an advisory step (not blocking), `contents: read` is sufficient for the scan; add `pull-requests: write` only if comment posting is desired.

```yaml
- name: Dependency review
  uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294  # v5.0.0
  with:
    fail-on-severity: critical
```

This must run only on `pull_request` events (which the workflow already scopes to). The `actions/dependency-review-action` requires a pull_request context by design — it diffs the base vs head. `[CITED: github.com/actions/dependency-review-action]`

**Permission update needed in actionlint.yml:** Current `permissions: contents: read`. Dependency-review-action needs no additional perms for scan-only mode; if we want it to post inline PR comments, add `pull-requests: write`.

**Staleness check for actionlint itself:** `rhysd/actionlint@914e7df` is v1.7.12 (2024-era). Verify this is still the latest SHA before shipping — Dependabot watches `.github/workflows/` so it will catch drift going forward.

### SUPPLY-05 — 1.19/OTP28 advisory row + floor-coincidence invariant

**Current state of advisory-matrix.yml:**
- Triggers: `push`, **`pull_request`**, `schedule` (cron `21 4 * * *`), `workflow_dispatch`.
- Matrix: only `elixir: "1.18" / otp: "27"` row.
- Jobs: `core_full_suite_advisory` and `provider_compatibility_advisory`.
- **PROBLEM:** The `pull_request:` trigger means ANY PR that touches any file causes the advisory-matrix jobs to run on PR. This is currently acceptable because the 1.18/OTP27 row is the same as the required lane — but SUPPLY-05 requires 1.19/OTP28 to NEVER run on PR. `[VERIFIED: live file read]`

**What must be added and how to scope it:**

The YAML-level fix: the simplest approach is to add an `if:` condition to the 1.19/OTP28 matrix row that excludes `pull_request` events, but GitHub Actions matrix-level `if:` filters on job level only, not row level — a job-level `if` applies to ALL rows.

**Recommended solution:** Restructure `advisory-matrix.yml` to remove the `pull_request:` trigger entirely OR add the 1.19 row with a separate job that has `if: github.event_name != 'pull_request'` on the JOB level, while keeping the existing 1.18 row on its own job definition (or keeping 1.18 within the same matrix but adding the PR trigger back only for 1.18 via a separate job).

The cleanest approach: **split into two job definitions in the same file**:
- `core_full_suite_advisory` (existing job, 1.18/OTP27 matrix row): keep `if: always()` (no PR restriction) — the 1.18 advisory run on PRs is harmless (it's the same toolchain as required, provides value as a broader test).
- Add a new job `core_latest_elixir_advisory` with `if: github.event_name != 'pull_request'` and matrix `{elixir: "1.19", otp: "28"}`.

This avoids removing the PR trigger from the whole workflow, preserving the 1.18 advisory run on PRs (which provides value), while ensuring 1.19 NEVER runs on PR.

**Job naming:** `Core Full Suite Advisory (Elixir 1.19 / OTP 28)` — this name matches the `isAdvisory()` pattern `/ Advisory \(/.test(jobName)` in publish-hex.yml's gate-ci-green, so a red 1.19 run on push/cron NEVER blocks the publish gate. `[VERIFIED: live publish-hex.yml read]`

**Elixir 1.19 + OTP 28 availability:**
- OTP 28 latest: `28.5.0.2` / `28.5` confirmed released. `[VERIFIED: GitHub API]`
- Elixir 1.19.0 released: `2025-10-16`. `[VERIFIED: GitHub API]`
- erlef/setup-beam v1.24.1 is latest (released after v1.24.0). `[VERIFIED: GitHub API]`
- setup-beam versions.json did not return results for 1.19 in the API check (possible network issue), but SYNTHESIS.md §P2-B cites 1.19/OTP28 as the standard advisory row and CICD-RELEASE-HARDENING.md confirms it (line 206). `[ASSUMED: setup-beam supports 1.19/OTP28]` — verify by checking erlef/setup-beam README or attempting a test run.

**advisory-matrix.yml cache key concern for 1.19 row:** The 1.19 row is inside `advisory-matrix.yml` which is EXEMPT from the canonical cache key rewrite (Phase 129 plan explicitly excluded `advisory-matrix.yml` — "advisory-matrix.yml: EXEMPT"). The 1.19 row will use the legacy broad key OR a new key. Since it's an advisory row, cache staleness is acceptable (at worst it re-fetches). Use a simple `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` key for this row — but include the toolchain dimension to avoid cross-toolchain artifact bleeding: `mix-${{ runner.os }}-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}`.

**Floor-coincidence invariant (LD-13) documentation location:**
- A comment in the `core_latest_elixir_advisory` job header in `advisory-matrix.yml`.
- A one-liner in `.planning/research/milestone-cicd/SYNTHESIS.md` §2 (already recorded as LD-13).
- Optionally: a comment in `mix.exs` near the `elixir: "~> 1.18"` floor declaration.

The invariant text (verbatim from SYNTHESIS.md LD-13): "whenever the required pin advances past 1.18, either add a 1.18 floor row to the required lane or raise the declared `elixir:` floor — never let the tested version outrun the declared `~> 1.18`."

---

## 2. mix_audit Integration (SUPPLY-01 Deep Dive)

**Package:** `mix_audit` — `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}`. Latest: `2.1.5` (2025-06-09). `[VERIFIED: mix hex.info]`

**Invocation:** `mix deps.audit` — scans `mix.lock` against the elixir-security-advisories DB (stored in `~/.hex/hex_cache` or downloaded fresh). Exits non-zero if any unaddressed advisory is found.

**Advisory PR lane in ci.yml:**

```yaml
deps_audit_advisory:
  name: Deps Audit Advisory (Elixir 1.18 / OTP 27)
  runs-on: ubuntu-latest
  needs: [changes]
  if: needs.changes.outputs.code == 'true'
  continue-on-error: true
  steps:
    - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
    - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
      with:
        version-file: .tool-versions
        version-type: strict
    - uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
      with:
        path: deps
        key: mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-${{ hashFiles('**/mix.lock') }}
        restore-keys: |
          mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-
    - run: mix deps.get
    - run: mix deps.audit
```

**Key design choices:**
- `continue-on-error: true` makes the step non-blocking at the GitHub runner level. However, publish-hex.yml's `gate-ci-green` checks `conclusion` of named jobs; a job with `continue-on-error: true` reports `conclusion: success` even if the step failed — which is what we want (advisory means never blocks). `[ASSUMED — standard GitHub Actions behavior for continue-on-error]`
- The job name `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` matches the regex `/ Advisory \(/.test(jobName)` in `gate-ci-green`, so it's treated as advisory at publish time too. A red `deps.audit` never blocks the publish gate via this path.
- The publish gate BLOCKS via a separate path: `publish.check.ex` Step N (new) calls `mix deps.audit` directly in the tarball isolation root, using the same allowlist.

**Publish gate blocking (publish.check.ex):**

Add after the existing `step(counts, :update, package, "run hex.audit", ...)` call (line 159):

```elixir
{counts, ctx} = step(counts, :update, package, "run deps.audit", ctx, &verify_deps_audit/1)
```

The `verify_deps_audit/1` function mirrors `verify_audit/1` but invokes `mix deps.audit` and applies `unaccepted_audit_findings/1` (the SAME parser function already tested for `hex.audit` output). Note that `mix deps.audit` output format differs slightly from `mix hex.audit` — verify the output format and adjust the parser if needed. `[ASSUMED — output format similarity; verify by reading mix_audit source or running locally]`

**CILanes registration:** The new `deps_audit_advisory` CI job name must be added to `@advisory_lanes_ci` in `test/support/ci_lanes.ex` AND a matcher must be added to `ci_parity_drift_test.exs`. Failing to do this causes the GATE-03 `required_checks_test.exs` anti-vacuity check to fail (it counts required lanes, not advisory lanes, so it won't directly fail — but the parity-drift test will fail if the new lane is added to `ci_lanes.ex` without a matcher). See Pitfalls section.

---

## 3. OSV-Staleness Forcing Function (SUPPLY-03 Deep Dive)

**OSV API reference:** `GET https://api.osv.dev/v1/vulns/{id}` — returns JSON with a `withdrawn` field (RFC3339 date string) if the advisory was withdrawn, or omits the field if still active. `[ASSUMED — from OSV documentation; verify at https://google.github.io/osv.dev/api/]`

**Implementation in publish.check.ex (recommended):**

```elixir
defp check_osv_advisory_staleness do
  @accepted_advisories
  |> Enum.map(fn {id, _reason} ->
    url = "https://api.osv.dev/v1/vulns/#{id}"
    case osv_get(url) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"withdrawn" => withdrawn_at}} ->
            {:stale, id, withdrawn_at}
          {:ok, _} ->
            {:active, id}
          {:error, _} ->
            {:error, id, :parse_error}
        end
      {:error, reason} ->
        {:error, id, reason}
    end
  end)
end

defp osv_get(url) do
  try do
    :httpc.request(:get, {String.to_charlist(url), []}, [{:timeout, 5000}], [])
    |> case do
      {:ok, {{_, 200, _}, _, body}} -> {:ok, List.to_string(body)}
      {:ok, {{_, status, _}, _, _}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :exception}
  end
end
```

**Wiring into publish.check.ex — two call sites:**

1. **Loud CI warning (every run of `mix mailglass.publish.check`):** In `execute_package/2`, before the step chain, call `check_osv_advisory_staleness/0` and emit warnings via `IO.puts(:stderr, ...)` for stale or error results. Do NOT block here.

2. **Hard block at publish (new Step 15):** Add a new step `"verify osv advisory freshness"` that calls `check_osv_advisory_staleness/0` and calls `fail_step/2` on `{:stale, id, _}` results. `{:error, _, _}` results trigger `IO.puts(:stderr, "[publish.check] WARNING: OSV API unavailable for #{id} — skipping staleness check (fail-open)")` and continue. `{:active, _}` results are logged as notices.

**Step ordering:** Place OSV-staleness as new Step 15, after the existing `run hex.audit` (Step 13) and new `run deps.audit` (Step 14). This is the least-disruptive insertion.

**Testability:** In `test/mailglass/publish/audit_allowlist_test.exs` (or a new `osv_staleness_test.exs`), test `check_osv_advisory_staleness/0` by temporarily overriding `@accepted_advisories` with a module attribute or by passing a parameterized list. Alternative: extract the HTTP call into an injected callback so tests can pass a mock response map without hitting the network.

**Fail-open guarantee:** Network errors, timeouts, and parse errors must all reach `{:error, _, _}` and never reach `{:stale, _, _}`. The `try/rescue` in `osv_get/1` ensures exceptions from `:httpc` (not just tuples) are caught. `[ASSUMED — :httpc behavior under network failure]`

---

## 4. dependabot Sibling Coverage (SUPPLY-02 — Exact YAML)

**Exact additions to `.github/dependabot.yml`:**

```yaml
  - package-ecosystem: "mix"
    directory: "/mailglass_admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "mix"
    directory: "/mailglass_inbound"
    schedule:
      interval: "weekly"
```

**Exclusion rationale for `reference/` apps:** `reference/host_app` and `reference/demo_app` are frozen deterministic baselines (see memory `project_reference_baseline_coupling.md`). Dependabot PRs against them would create the exact "coordinated 5-file change" nightmare the baseline coupling constraint exists to prevent. Do NOT add entries for them. `[VERIFIED: CONTEXT.md + memory file]`

**Convention alignment:** The existing entries use `interval: "weekly"` with no `open-pull-requests-limit` (default 5). New entries match. No `labels:` or `reviewers:` overrides needed. `[VERIFIED: live dependabot.yml read]`

---

## 5. actionlint Gap + Dependency-Review (SUPPLY-04)

### Actionlint — gap is zero

The existing `actionlint.yml` already:
- Triggers on PR for `.github/workflows/*.yml|*.yaml` changes
- Runs `rhysd/actionlint@914e7df21a07ef503a81201c76d2b11c789d3fca  # v1.7.12` (SHA-pinned)
- Has `permissions: contents: read`

A malformed workflow PR WILL be failed by this job: actionlint exits non-zero on syntax/semantic errors, the job has no `continue-on-error`, and the PR trigger means it runs before merge. `[VERIFIED: live file read]`

The only gap under SUPPLY-04 is the `dependency-review-action` step.

### Dependency-Review addition

**Add to `actionlint.yml`** (existing workflow, new step after the actionlint step):

```yaml
      - name: Dependency review
        # Scans dependency manifest changes in PRs for known vulnerabilities.
        # Advisory only (continue-on-error) per LD-4: never red an open PR.
        # Only meaningful on pull_request events; the workflow's existing
        # pull_request trigger provides that context.
        uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294  # v5.0.0
        continue-on-error: true
        with:
          fail-on-severity: high
```

**SHA:** `a1d282b36b6f3519aa1f3fc636f609c47dddb294` (confirmed as v5.0.0 via GitHub API). `[VERIFIED: GitHub API]`

**Why `continue-on-error: true`:** The dependency-review-action checks the PR diff for newly introduced vulnerable deps. Under a v1.14-style wave of unfixable advisories, it would red every dep-PR. `continue-on-error` keeps it informative (fails the step, shows in UI) without blocking the PR. `[ASSUMED — consistent with LD-4 advisory-on-PR philosophy]`

**Permissions:** `dependency-review-action` with `fail-on-severity` scan-only mode needs only `contents: read` (already set). No `pull-requests: write` needed unless comment-posting is desired.

**Trigger scope:** `dependency-review-action` works ONLY on `pull_request` and `pull_request_target` events. The existing workflow trigger is `pull_request` — compatible. For `workflow_dispatch` triggers (which the current actionlint.yml also has), this step will fail because there's no PR diff context. Add a job-level `if: github.event_name == 'pull_request'` to the new step only, OR wrap it in a separate step condition.

---

## 6. 1.19/OTP28 Advisory Row (SUPPLY-05)

### Verified version availability

- **OTP 28:** Released, latest `28.5.0.2`. `[VERIFIED: GitHub API erlang/otp]`
- **Elixir 1.19.0:** Released `2025-10-16`. `[VERIFIED: GitHub API elixir-lang/elixir]`
- **setup-beam support:** `[ASSUMED]` — erlef/setup-beam v1.24.x is current; Elixir 1.19 was released in October 2025, well within setup-beam's maintenance window. Verify by checking the setup-beam versions.json or readme before executing.
- **OTP 28 + Elixir 1.19 compatibility:** Elixir 1.19 targets OTP 27+ (per Elixir release notes); OTP 28 is officially supported. `[ASSUMED]`

### Advisory-matrix.yml PR trigger fix

**Current problem:** `advisory-matrix.yml` has `pull_request: branches: [main]` (line 6), which means ALL jobs in the workflow run on PR. The 1.19 row MUST NOT run on PR.

**Solution — add a new job with `if: github.event_name != 'pull_request'`:**

```yaml
  core_latest_elixir_advisory:
    name: Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }})
    if: github.event_name != 'pull_request'
    # LD-13 floor-coincidence invariant:
    # This row tests the LATEST Elixir/OTP line (advisory, non-blocking).
    # INVARIANT: whenever the required pin advances past 1.18, either add a 1.18
    # floor row to the required lane or raise the declared `elixir:` floor in
    # mix.exs — never let the tested version outrun the declared `~> 1.18`.
    # See SYNTHESIS.md LD-13.
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - elixir: "1.19"
            otp: "28"
    # ... (same services/env/steps as core_full_suite_advisory, with otp/elixir from matrix)
```

**Note on cache key for this job:** Use `mix-${{ runner.os }}-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}` for the 1.19 row — the advisory-matrix.yml is EXEMPT from the canonical `.tool-versions` key (Phase 129 scope fence), and a toolchain-parameterized key is appropriate here since the matrix drives the toolchain. `[VERIFIED: Phase 129 plan explicitly exempts advisory-matrix.yml]`

**Where to document LD-13 invariant:**
1. Comment in the new `core_latest_elixir_advisory` job header (shown above) — this is the primary runtime location.
2. `mix.exs` — brief comment near the `elixir: "~> 1.18"` project floor declaration.
3. SYNTHESIS.md already records LD-13 as the decision-of-record — no change needed there.

### advisory-matrix.yml does NOT need a parallel `provider_compatibility_advisory` 1.19 row

The existing `provider_compatibility_advisory` job (1.18/OTP27) runs provider tests that require live sandbox credentials, which may not be OTP28-compatible yet. Adding a 1.19 row for this is out of scope for Phase 130 — the SUPPLY-05 requirement mentions only the core advisory row, and SYNTHESIS.md LD-13 scopes the advisory row to the core full suite. `[ASSUMED — scope interpretation; confirm with REQUIREMENTS.md wording which says "latest-Elixir advisory row"]`

---

## 7. Testing the PR-vs-Publish Asymmetry (SUPPLY-01)

**Core success criterion:** A simulated unfixable advisory reds the publish gate but NOT open PRs.

**How to test without a real CVE:**

The test seam already exists: `unaccepted_audit_findings/1` in `publish.check.ex` is `@doc false` (unit-testable per the existing comment at line 1082) and is exercised by `test/mailglass/publish/audit_allowlist_test.exs`.

**The simulated advisory approach:**

1. **Advisory-on-PR (non-blocking):** The `deps_audit_advisory` CI job has `continue-on-error: true`. Verify this via the GATE-03/parity meta-tests — the job name follows the `Advisory` convention which the publish gate treats as non-blocking. No new test needed; the meta-test structure already validates this.

2. **Block at publish:** `verify_deps_audit/1` in `publish.check.ex` calls `unaccepted_audit_findings/1` which is tested in `AuditAllowlistTest`. Add a test:

```elixir
test "verify_deps_audit blocks on a fixable advisory not in allowlist" do
  # Simulate mix deps.audit output with a non-allowlisted advisory
  output = "  some_dep 1.0.0 - GHSA-xxxx-yyyy-zzzz (HIGH)"
  assert Check.unaccepted_audit_findings(output) != []
end
```

3. **Publish-gate meta-test:** Add an assertion in `audit_allowlist_test.exs` that the cowlib advisory IDs ARE in the allowlist (proving accepted = non-blocking at publish), and that a NEW advisory ID is NOT (proving the block fires).

4. **Advisory-vs-publish behavior assertion** — the definitive simulation: run `mix mailglass.publish.check` locally against a tarball with a crafted `mix.lock` entry that has a known advisory in the mix_audit DB, confirm it fails. This is a manual verification step — not automatable in CI without a real CVE.

**Existing test structure to align with:** Prior phases use ExUnit contract tests (`AuditAllowlistTest` already exists). The OSV-staleness tests should live in the same file or a sibling `osv_staleness_test.exs`. The advisory-PR asymmetry is validated by the meta-test structure (GATE-03 + MIXCI-03 tests).

---

## 8. Pitfalls / Footguns

### Pitfall 1: CI Green fan-in gate and the advisory-lane naming contract

**What goes wrong:** Adding a new `deps_audit_advisory` CI job WITHOUT naming it with `Advisory (` in the name causes `gate-ci-green` in `publish-hex.yml` to treat it as a blocking non-required lane. The gate's `isAdvisory()` function checks: `/ Advisory \(/.test(jobName)`. A job named `Deps Audit (Elixir 1.18 / OTP 27)` (missing the word `Advisory`) would be treated as a blocking unknown lane.

**How to avoid:** Name the job `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` — this matches the isAdvisory regex. Verify in publish-hex.yml lines 267-269.

**Why it happens:** The `gate-ci-green` explicitly lists `REQUIRED_LANES` (5 lanes) and `ADVISORY_LANES` (2 by name), then uses the advisory-naming convention for everything else. A mis-named new lane falls into the "non-required, non-advisory" bucket at lines 273-281, which blocks publish.

### Pitfall 2: CILanes registration — GATE-03 and MIXCI-03 meta-tests

**What goes wrong:** Adding the new `Deps Audit Advisory` job to `ci.yml` WITHOUT updating `Mailglass.CILanes` causes:
- `ci_parity_drift_test.exs` (MIXCI-03) to potentially fail if the parity check is strict about covering ALL jobs in ci.yml (it currently only checks lanes DECLARED in CILanes — so a new advisory lane added to ci.yml but NOT to CILanes is NOT checked; but the intent of LD-10 is that the CI lanes source of truth be kept current).
- If the job IS added to `@advisory_lanes_ci` in CILanes but a matcher is NOT added to `ci_parity_drift_test.exs`, the anti-vacuity guard in MIXCI-03 that checks "every ci_lanes lane has a matcher" will FAIL.

**Exact files to update together:**
1. `test/support/ci_lanes.ex` — add `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` to `@advisory_lanes_ci`.
2. `test/scripts/ci_parity_drift_test.exs` — add a matcher for this lane in `matcher_for/1` AND in the `matcher_lanes` MapSet in the anti-vacuity test (the hardcoded set at the bottom of the anti-vacuity test).
3. The `mix ci` alias in `mix.exs` must cover this lane — add `"deps.audit"` as a step. The matcher for the new lane should check `any_step?(&1, "deps.audit")`.

**Required-checks meta-test (required_checks_test.exs):** This test checks `ci_green.needs` set-equality against `Mailglass.CILanes.required_lanes()`. The new advisory lane is NOT added to `ci_green.needs` (it's advisory, not required). No change needed in `required_checks_test.exs`. `[VERIFIED: understanding of test structure]`

### Pitfall 3: SHA-pin drift for actionlint and dependency-review-action

**What goes wrong:** Shipping a non-pinned action reference (e.g., `uses: actions/dependency-review-action@v5`) violates CLAUDE.md ("All third-party GitHub Actions pinned to commit SHA"). Dependabot will NOT auto-update an untagged reference.

**How to avoid:** Pin to commit SHA at time of writing. The SHA for `actions/dependency-review-action@v5.0.0` is `a1d282b36b6f3519aa1f3fc636f609c47dddb294`. `[VERIFIED: GitHub API]` Include the `# v5.0.0` comment. Dependabot (watching `.github/workflows/`) will send a PR when a new version releases.

### Pitfall 4: advisory-matrix.yml 1.19 row cache — cross-toolchain artifact bleeding

**What goes wrong:** Using the same `key:` for the 1.19 and 1.18 rows (both hashed on `**/mix.lock`) means they share `_build` artifacts. OTP 28's compiled BEAM files are not compatible with OTP 27. If 1.18 restores into the 1.19 row's cache slot, the 1.19 compile will fail with cryptic errors.

**How to avoid:** Include `${{ matrix.elixir }}-${{ matrix.otp }}` in the cache key for the 1.19 advisory row, scoping it to the toolchain. The existing 1.18 rows in advisory-matrix.yml don't need to change (they're already isolated because the new 1.19 job is a separate job definition with a separate cache key).

### Pitfall 5: publish.check.ex hex.audit vs deps.audit — different output formats

**What goes wrong:** `verify_deps_audit/1` reusing `unaccepted_audit_findings/1` (which was written for `mix hex.audit` output) may mis-parse `mix deps.audit` output if the formats differ.

**How to avoid:** Read `mix deps.audit` output format from the mix_audit source or by running locally. The mix_audit 2.1.5 output format should produce lines like `  <pkg> <version> - <GHSA-id> <description>`. Write a separate `unaccepted_deps_audit_findings/1` if the formats differ significantly, and add a new fixture test.

### Pitfall 6: OSV API fail-open must cover ALL error paths

**What goes wrong:** A timeout, SSL error, DNS failure, or non-200 HTTP response must ALL reach the `{:error, _, _}` branch. If `:httpc.request/4` raises an exception instead of returning a tuple (which it can under certain failure modes), the `try/rescue` in `osv_get/1` is critical.

**How to avoid:** Wrap the `:httpc` call in `try/rescue` as shown above. Test all three paths: active advisory, stale advisory, network error (mock or stub).

### Pitfall 7: advisory-matrix.yml 1.19 row + dependabot.yml open-PR-limit interaction

**What goes wrong:** Adding dependabot entries for `mailglass_admin` and `mailglass_inbound` will trigger dependabot PRs for each. If there are many stale deps, this could flood the PR queue. The default open-PR-limit is 5 per ecosystem/directory.

**How to avoid:** The existing entries don't set `open-pull-requests-limit`, so the new entries inherit the default of 5. No immediate action needed; monitor after Phase 130 lands.

### Pitfall 8: `mix ci` alias must include `deps.audit` for MIXCI-03 parity

**What goes wrong:** The MIXCI-03 parity-drift test verifies that `mix ci ∪ ci.browser` covers every lane in `Mailglass.CILanes`. If `"Deps Audit Advisory"` is added to `@advisory_lanes_ci` but `deps.audit` is NOT added to the `ci` alias in `mix.exs`, the test fails.

**How to avoid:** Add `"deps.audit"` to the `ci` alias in `mix.exs`. The matcher in `ci_parity_drift_test.exs` should check `any_step?(&1, "deps.audit")`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dep vulnerability scanning | Custom parser against hex API | `mix deps.audit` (mix_audit 2.1.5) | Maintained DB, correct output format, standard tool |
| Workflow YAML linting | Custom YAML parser | `rhysd/actionlint` (already present) | Handles Actions-specific semantics |
| Dep manifest PR scanning | Custom diff + vuln check | `actions/dependency-review-action@v5.0.0` | GitHub-maintained, handles all ecosystems |
| HTTP JSON fetch in Elixir | Custom HTTP client | `:httpc` (OTP built-in, already in `extra_applications`) | No new dep, already available |
| Advisory allowlist lifecycle | Custom advisory DB sync | OSV.dev API + existing `@accepted_advisories` pattern | Authoritative upstream, fail-open is one try/rescue |

---

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| mix_audit 2.1.5 | Hex | ~3 yrs | N/A (Elixir ecosystem standard) | github.com/mirego/mix_audit | OK | Approved |
| actions/dependency-review-action v5.0.0 | GitHub Actions | GitHub-maintained | N/A | github.com/actions/dependency-review-action | OK | Approved |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious (SUS):** none

---

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mix_audit | 2.1.5 | `mix deps.audit` — elixir-security-advisories scan | Standard Elixir security tool; maintained by Mirego |
| actions/dependency-review-action | v5.0.0 (SHA: a1d282b) | PR dep manifest scanning | GitHub-official action; integrates with OSV/GitHub Advisory DB |
| rhysd/actionlint | v1.7.12 (already present, SHA: 914e7df) | Workflow YAML linting | Already in actionlint.yml — no change needed |
| OSV.dev API | v1 | Advisory staleness check | Google-maintained, authoritative for withdrawn advisories |

**Installation (mix.exs):**
```elixir
{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
```

---

## Validation Architecture

Observable checks that prove each SUPPLY item:

### SUPPLY-01 — mix_audit advisory-on-PR, blocking-at-publish

| Proof | Test / Command | What it Proves |
|-------|----------------|----------------|
| Advisory lane exists in ci.yml | `grep "deps_audit_advisory" .github/workflows/ci.yml` | Lane is defined |
| Lane name matches isAdvisory() | `grep "Deps Audit Advisory" .github/workflows/ci.yml` | Never blocks publish gate |
| `continue-on-error: true` | `grep "continue-on-error: true" .github/workflows/ci.yml` | Never reds a PR |
| Lane in CILanes advisory set | `mix test test/scripts/required_checks_test.exs` (GATE-03) | Set-equality maintained |
| Parity drift test passes | `mix test test/scripts/ci_parity_drift_test.exs` | MIXCI-03 — alias covers lane |
| Allowlist blocks non-accepted | `mix test test/mailglass/publish/audit_allowlist_test.exs` | Publish gate fires on fixable advisories |
| New deps_audit step in publish.check | `grep "deps.audit" lib/mix/tasks/mailglass.publish.check.ex` | Step 14 exists |
| `:mix_audit` in mix.exs | `grep "mix_audit" mix.exs` | Dep declared |

### SUPPLY-02 — dependabot sibling coverage

| Proof | Test / Command | What it Proves |
|-------|----------------|----------------|
| admin entry in dependabot.yml | `grep "mailglass_admin" .github/dependabot.yml` | Admin lock watched |
| inbound entry in dependabot.yml | `grep "mailglass_inbound" .github/dependabot.yml` | Inbound lock watched |
| reference/ NOT in dependabot.yml | `grep -v "reference" .github/dependabot.yml` | Frozen baselines excluded |

### SUPPLY-03 — OSV-staleness forcing function

| Proof | Test / Command | What it Proves |
|-------|----------------|----------------|
| OSV function exists | `grep "osv\|OSV" lib/mix/tasks/mailglass.publish.check.ex` | Implementation added |
| Fail-open test passes | `mix test test/mailglass/publish/audit_allowlist_test.exs` (new test) | Network error → no block |
| Stale advisory test | new test case in osv_staleness_test.exs or audit_allowlist_test.exs | Withdrawn advisory → fail |
| Active advisory test | new test case | Active advisory → no block |

### SUPPLY-04 — actionlint + dependency-review

| Proof | Test / Command | What it Proves |
|-------|----------------|----------------|
| dependency-review step SHA-pinned | `grep "dependency-review-action@" .github/workflows/actionlint.yml` | SHA present |
| actionlint still fires on workflow PRs | Existing behavior confirmed by file read | No regression |
| actionlint.yml passes actionlint | `actionlint .github/workflows/actionlint.yml` (local) | Meta-lint: the linter file is itself valid |

### SUPPLY-05 — 1.19/OTP28 advisory row + invariant

| Proof | Test / Command | What it Proves |
|-------|----------------|----------------|
| 1.19 row exists in advisory-matrix.yml | `grep '"1.19"' .github/workflows/advisory-matrix.yml` | Row added |
| `if: github.event_name != 'pull_request'` on 1.19 job | `grep "event_name" .github/workflows/advisory-matrix.yml` | Never runs on PR |
| Not in ci_green.needs | `grep "core_latest_elixir_advisory" .github/workflows/ci.yml` (should be absent) | Not required |
| Not in REQUIRED_LANES | `grep "1.19" .github/workflows/publish-hex.yml` (should be absent from REQUIRED_LANES list) | Not required at publish |
| LD-13 comment in workflow | `grep "LD-13\|floor-coincidence" .github/workflows/advisory-matrix.yml` | Invariant documented |
| Advisory naming convention | job name contains `"Advisory ("` | isAdvisory() pattern matches |

---

## Open Questions

1. **mix deps.audit output format vs hex.audit output format**
   - What we know: `mix hex.audit` output uses `  <pkg> <ver> - <ID> (<SEV>)` format; `mix deps.audit` (mix_audit) uses a different format from the elixir-security-advisories DB which uses GHSA IDs.
   - What's unclear: Whether `unaccepted_audit_findings/1` (built for hex.audit's EEF-CVE IDs) needs a separate parser for deps.audit GHSA IDs.
   - Recommendation: Run `mix deps.audit` locally (after adding the dep) to inspect output format; if formats differ, write `unaccepted_deps_audit_findings/1` as a peer function.

2. **setup-beam Elixir 1.19 + OTP 28 version strings**
   - What we know: OTP 28.5 and Elixir 1.19.0 are released; setup-beam v1.24.x is current.
   - What's unclear: Whether setup-beam's versions.json carries exact 1.19.x + OTP 28.x builds for ubuntu-latest (could not fetch at research time).
   - Recommendation: Use bare `"1.19"` and `"28"` in the advisory matrix `with:` block and let setup-beam resolve; OR check the erlef/setup-beam README for the supported version format. The advisory-matrix.yml is EXEMPT from the version-file contract (its purpose IS to test specific toolchains, not derive from `.tool-versions`).

3. **OSV API advisory ID format for cowlib advisories**
   - What we know: `@accepted_advisories` uses `EEF-CVE-2026-43966` and `EEF-CVE-2026-43969`. OSV.dev uses its own ID scheme (OSV IDs are the canonical form; `EEF-CVE-*` may be aliases).
   - What's unclear: Whether `GET /v1/vulns/EEF-CVE-2026-43966` resolves on the OSV API or requires the OSV-format alias.
   - Recommendation: Test the API endpoint at `https://api.osv.dev/v1/vulns/EEF-CVE-2026-43966` before implementing. If it 404s, use the aliased OSV IDs from the hex.audit output (which includes `aka:` lines pointing to the canonical OSV ID).

---

## Environment Availability

SKIPPED — Phase 130 is pure CI config changes (YAML) + Elixir code additions in publish.check.ex. No external services required beyond the OSV.dev API (network-only, fail-open by design).

---

## Sources

### Primary (HIGH confidence — verified against live repo files)
- `.github/workflows/actionlint.yml` — confirmed full content, SHA pin, trigger scope
- `.github/workflows/advisory-matrix.yml` — confirmed PR trigger, current matrix (1.18/OTP27 only)
- `.github/workflows/ci.yml` — confirmed advisory lane structure, ci_green.needs, isAdvisory pattern
- `.github/workflows/publish-hex.yml` — confirmed gate-ci-green REQUIRED_LANES + ADVISORY_LANES + isAdvisory()
- `lib/mix/tasks/mailglass.publish.check.ex` — confirmed @accepted_advisories (lines 60-65), Step 13 hex.audit (lines 1040-1106)
- `mix.exs` — confirmed no mix_audit dep, no deps.audit alias
- `.github/dependabot.yml` — confirmed current 2-entry structure
- `test/support/ci_lanes.ex` — confirmed @advisory_lanes_ci structure
- `test/scripts/required_checks_test.exs` — confirmed GATE-03 set-equality test
- `test/scripts/ci_parity_drift_test.exs` — confirmed MIXCI-03 matcher structure + anti-vacuity guards
- `test/mailglass/publish/audit_allowlist_test.exs` — confirmed existing test seam for unaccepted_audit_findings/1
- `.planning/research/milestone-cicd/SYNTHESIS.md` — LD-4, LD-11, LD-13 decision-of-record
- `.planning/phases/129-cache-key-plt-correctness/129-01-PLAN.md` — advisory-matrix.yml EXEMPT scope fence

### Secondary (MEDIUM confidence — GitHub API verified)
- `actions/dependency-review-action` v5.0.0 SHA: `a1d282b36b6f3519aa1f3fc636f609c47dddb294` — GitHub API confirmed
- OTP 28.5 released — GitHub API confirmed (erlang/otp releases)
- Elixir 1.19.0 published 2025-10-16 — GitHub API confirmed
- mix_audit 2.1.5 (2025-06-09) — `mix hex.info mix_audit` confirmed

### Tertiary (LOW confidence — assumed / training knowledge)
- OSV.dev API endpoint format (`/v1/vulns/<id>`) and `withdrawn` field schema
- mix deps.audit output format vs hex.audit output format
- setup-beam versions.json coverage for Elixir 1.19 + OTP 28

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `continue-on-error: true` on a CI job causes `gate-ci-green` to see it as `success` | SUPPLY-01 | If wrong: a red deps.audit job might block publish via the non-required non-advisory path. Mitigation: use the `Advisory (` naming convention so isAdvisory() catches it as a fallback. |
| A2 | setup-beam v1.24.x supports Elixir 1.19 + OTP 28 on ubuntu-latest | SUPPLY-05 | If wrong: the 1.19 advisory row fails at setup-beam step, not at tests — advisory red, not blocking. Acceptable. |
| A3 | `EEF-CVE-2026-43966` resolves as an advisory ID on the OSV.dev v1 API | SUPPLY-03 | If wrong: the OSV check always returns an error → logs a warning and continues (fail-open). No blocking failure. |
| A4 | `mix deps.audit` output format is parseable by a straightforward Regex adaptation of `unaccepted_audit_findings/1` | SUPPLY-01 | If wrong: publish gate's Step 14 fails to detect advisory IDs → allowlist never triggers → advisory passes vacuously. Fix: run locally to verify format and write a dedicated parser. |
| A5 | Dependabot default open-PR-limit of 5 per directory is sufficient | SUPPLY-02 | If wrong: Dependabot may queue more than 5 dep PRs for sibling packages. Low severity; can add `open-pull-requests-limit:` later. |
| A6 | OTP 28 + Elixir 1.19 are compatible (Elixir 1.19 targets OTP 27+) | SUPPLY-05 | If wrong: the advisory row will always fail compile, producing permanent advisory noise. Can drop the 1.19/28 row and use 1.19/27 instead. |

---

## Metadata

**Confidence breakdown:**
- Current-state gap delta: HIGH — read every live file directly
- Standard stack (mix_audit): HIGH — verified on Hex
- Advisory-lane naming contract: HIGH — read isAdvisory() from publish-hex.yml
- OSV API mechanics: LOW — assumed from training knowledge, not verified via live API call
- Elixir 1.19 + OTP 28 setup-beam support: MEDIUM — versions released confirmed; setup-beam coverage assumed

**Research date:** 2026-07-01
**Valid until:** 2026-08-01 (stable CI tooling; dep versions unlikely to change in 30 days)
