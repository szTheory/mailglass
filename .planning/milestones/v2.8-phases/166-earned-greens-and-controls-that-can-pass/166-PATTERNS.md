# Phase 166: Earned Greens and Controls That Can Pass - Pattern Map

**Mapped:** 2026-09-17
**Files analyzed:** 13 (all modified/net-new; this is a CI/control-plane phase — no app-tier files)
**Analogs found:** 13 / 13 (every file has an in-repo analog; several are same-repo siblings, not
cross-domain guesses)

All line numbers below were re-verified live this session (`grep -n` + `Read`, 2026-09-17) — do not
trust `166-CONTEXT.md`'s citations for `post-publish-smoke.yml` (Correction 1 in 166-RESEARCH.md
applies; corrected numbers are used throughout this file). Every path cited is git-tracked source
(no `.gsd/`, no plugin-synced mirror) — this is the primary repo, not a capability install.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `mailglass_admin/mix.exs` (`aliases/0`, `deps/0`) | config | CRUD (alias/dep table edit) | same file, `mix.exs` (root) `deps/0` + `mailglass_inbound/mix.exs` `deps/0` | exact (in-repo sibling) |
| `config/coverage_baselines/admin.json` (NEW) | config | batch (measured snapshot, ratchet-compared) | `config/coverage_baselines/core.json` | exact |
| `test/scripts/lane_classification_drift_test.exs` (extended: `@ci_yml_suite_floor_occurrences` trio) | test | transform (string-occurrence counting + drift assertion) | same file's existing `@advisory_matrix_path` / `@suite_floor_env_occurrences` `describe` block (lines 592-641) | exact (self-mirror, same file) |
| `.github/workflows/ci.yml` (GREEN-02 coverage step, GREEN-03 env line, GREEN-04 isolated demo build step, GREEN-05 cache-key segment) | config (workflow) | request-response (CI job steps) | same file's `core_deterministic_suite` (:444-452) and `support_contract_core` (:288-296) jobs | exact (self-mirror, same file) |
| `test/mix/tasks/mailglass.repo.hygiene_test.exs` (new cases for widened PR predicate) | test | request-response (stubs `gh` CLI, asserts task output) | same file's existing `pull_requests` cases (:312-357) and `with_hygiene_environment/3` fixture (:405-460) | exact (self-mirror, same file) |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` (`pull_requests/1`, `status/1`, exit-code split) | utility (Mix task) | request-response (shells to `gh`, classifies JSON) | same file's `expired_entries`-style `cannot_check`/`check` classification (:276-433) | exact (self-mirror, same file) |
| `.github/workflows/post-publish-smoke.yml` (CTRL-01: `baseline-versions` verb, mode input, cron-guard widen) | route/config (workflow event branching) | request-response + pub-sub (schedule/dispatch event routing) | same file's existing `EVENT_NAME`-branched command selection (:129-130) and `workflow_dispatch` input block (:15-30) | exact (self-mirror, same file) |
| `scripts/check_post_publish_target.sh` (CTRL-01: baseline-mode digest bypass) | utility (shell) | transform (JSON policy validation) | same file's existing digest-check block (:86-98) | exact (self-mirror, same file) |
| `.github/workflows/release-please.yml` (CTRL-02: delete early `exit 0`; CTRL-03: retry/backoff) | config (workflow) | event-driven (push/schedule-triggered release proposal pipeline) | same file's `continue-on-error` + classify pattern already used at `:459`/`:502`/`:662` | exact (self-mirror, same file) |
| `lib/mailglass/supply_chain/accepted_advisories.ex` (`@entries` reason/recheck_by rewrite) | model (data-only constant) | CRUD (static allowlist read) | same file — no external analog needed, this is the canonical source | exact (self-mirror) |
| `test/mailglass/supply_chain/accepted_advisories_test.exs` (date-lockstep rewrite) | test | transform (date-boundary assertions) | same file's existing boundary tests (:155-177) | exact (self-mirror) |
| `mailglass_admin/mix.lock` (NEW excoveralls entry) | config | CRUD (dependency lock) | `mailglass_inbound/mix.lock` excoveralls entry | exact (in-repo sibling) |
| GREEN-05 committed note (new markdown deliverable, not code) | config/docs | transform (structural proof, not runnable test) | none in-repo — genuinely novel artifact shape (see "No Analog Found") | no analog |
| `reference/demo_app/` isolated Hex-deps CI step (GREEN-04, lands in `ci.yml`) | config (workflow) | batch (one-shot dep resolution + compile) | same file's existing path-dep demo install/compile steps (:276-281, :424-437) — **structure to mirror, dependency-resolution mode to invert** | role-match (mirrors shape, deliberately diverges in the `MAILGLASS_DEMO_DEPS=hex` env) |

## Pattern Assignments

### `mailglass_admin/mix.exs` (config, CRUD) — GREEN-01/GREEN-02/GREEN-04(dep)/GREEN-02(dep)

**Analog:** same file, `mailglass_inbound/mix.exs`, root `mix.exs`

**Alias to redefine (D-01/D-02)** — current 9-file allow-list, lines 208-210:
```elixir
"verify.support_contract.admin": [
  "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors"
],
```
Redefine the body to a directory-scoped run (D-01: **not** `verify.preview`, which additionally runs
`mailglass_admin.assets.build` + `cmd git diff --exit-code priv/static/` at lines 202-207 — a
Tailwind/daisyUI rebuild landmine):
```elixir
"verify.support_contract.admin": [
  "test --warnings-as-errors"
],
```
`ci: ["ci.fast", "verify.support_contract.admin"]` (line 188-191) and `verify.phase_05` (line 213)
call the alias by **name** — zero edits needed there (D-02, confirmed by
`test/scripts/ci_parity_drift_test.exs:184` matching alias names only).

**ExCoveralls dep pattern to copy (D-05)** — from `mailglass_inbound/mix.exs`:
```elixir
# mailglass_inbound/mix.exs:22
test_coverage: [tool: ExCoveralls],
# mailglass_inbound/mix.exs:129
{:excoveralls, "~> 0.18", only: [:test]},
```
Add both to `mailglass_admin/mix.exs`'s `project/0` (`test_coverage:` key) and `deps/0` (line
95-131 is the existing `deps/0` body — append the excoveralls line near the other `only: [:dev,
:test]`/`only: :test` deps, e.g. next to `{:lazy_html, ">= 0.1.0", only: :test}` at line 131). No
`coveralls.json` config file exists anywhere in the repo for core or inbound — do not introduce one
for admin either (command-line flags only, per RESEARCH's Alternatives Considered).

---

### `config/coverage_baselines/admin.json` (config, batch) — GREEN-02

**Analog:** `config/coverage_baselines/core.json` (verbatim, quoted in full):
```json
{
  "package": "mailglass",
  "cohort": "test/mailglass",
  "covered_lines": 5357,
  "relevant_lines": 8469,
  "percentage": 63.254221,
  "toolchain": "1.18.4/27",
  "image": "hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim",
  "command": "make toolchain CMD='mix coveralls.json test/mailglass --warnings-as-errors'",
  "report_sha256": "c5ca06e889aba2d0db8be79103e7f98db7c7fb9eb8b3d0b12e4f72b5df49ffc0",
  "measured_at": "2026-08-17"
}
```
Admin's equivalent needs `"package": "mailglass_admin"`, `"cohort": "test"` (or whatever directory
argument the new `mix coveralls.json` invocation uses), and every numeric field **measured from a
green run of the widened 510-test suite** — generate in the same PR that widens the alias (D-06),
never hand-picked.

**Consuming script (unmodified, D-06)** — `scripts/check_coverage_floor.sh`, quoted in full:
```bash
#!/usr/bin/env bash
set -euo pipefail

baseline="${1:?baseline JSON path required}"
report="${2:?ExCoveralls JSON report path required}"
expected_toolchain="${3:?exact Elixir/OTP toolchain required}"

test -r "$baseline" || { echo "coverage baseline missing: $baseline" >&2; exit 1; }
test -r "$report" || { echo "coverage report missing: $report" >&2; exit 1; }

actual="$(elixir -e 'IO.write(System.version() <> "/" <> to_string(:erlang.system_info(:otp_release)))')"
test "$actual" = "$expected_toolchain" || {
  echo "coverage toolchain mismatch: expected $expected_toolchain, got $actual" >&2
  exit 1
}

node -e '
const fs = require("fs");
const [basePath, reportPath] = process.argv.slice(1);
const base = JSON.parse(fs.readFileSync(basePath, "utf8"));
const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
const files = report.source_files;
if (!Array.isArray(files) || files.length === 0) throw new Error("coverage report has no source_files");
let covered = 0, relevant = 0;
for (const file of files) for (const hit of Object.values(file.coverage || {})) {
  if (hit !== null) { relevant++; if (hit > 0) covered++; }
}
if (!Number.isInteger(base.covered_lines) || !Number.isInteger(base.relevant_lines) || typeof base.percentage !== "number") throw new Error("baseline lacks measured coverage counts");
const percentage = covered / relevant * 100;
if (covered < base.covered_lines || relevant < base.relevant_lines || percentage < base.percentage) throw new Error(`coverage regression: ${covered}/${relevant} (${percentage}), baseline ${base.covered_lines}/${base.relevant_lines} (${base.percentage})`);
' "$baseline" "$report"
```
Note: this script uses `node -e` for JSON diffing — this is dev/CI tooling only, not shipped to
adopters, so it does not violate the "no Node toolchain" adopter-facing constraint (see the
`feedback_zero_node_is_adopter_facing` memory). Do not "fix" this into pure bash; it's an established
pattern already used for `core.json`.

**CI step to mirror (D-37 PR-1)** — `.github/workflows/ci.yml:292-295` (`support_contract_core` job),
quoted verbatim:
```yaml
      - name: Collect and enforce core coverage floor
        run: |
          mix coveralls.json --output-dir coverage/core test/mailglass --warnings-as-errors
          bash scripts/check_coverage_floor.sh config/coverage_baselines/core.json coverage/core/excoveralls.json 1.18.4/27
```
The admin equivalent lands as a new step inside the same job (`support_contract_admin`, whose
existing invocation is at `ci.yml:916-917`:
`run: cd mailglass_admin && mix verify.support_contract.admin`):
```yaml
      - name: Collect and enforce admin coverage floor
        working-directory: mailglass_admin
        run: |
          mix coveralls.json --output-dir ../coverage/admin test --warnings-as-errors
          bash ../scripts/check_coverage_floor.sh ../config/coverage_baselines/admin.json ../coverage/admin/excoveralls.json 1.18.4/27
```
Verify relative paths against the actual job's `working-directory:`/`defaults:` when writing the
plan — `mailglass_admin/` is a sibling package.

---

### `test/scripts/lane_classification_drift_test.exs` (test, transform) — GREEN-03

**Analog:** same file's existing `advisory-matrix.yml` trio, lines 43, 56, 592-641, 1280-1286
(quoted verbatim, this is the exact template to mirror per D-08):
```elixir
# lines ~43-56
@advisory_matrix_path Path.join(@repo_root, ".github/workflows/advisory-matrix.yml")
@suite_floor_env_entry ~s(MAILGLASS_SUITE_FLOOR: "1")
@suite_floor_env_occurrences 2
```
```elixir
# lines 592-641 — the describe block to mirror verbatim, retargeted at ci.yml
describe "advisory-matrix.yml's suite-floor opt-in (HARNESS-03)" do
  test "the full-suite steps carry the suite-floor env entry exactly twice, with the " <>
         "literal value SuiteFloor compares against" do
    occurrences = count_suite_floor_env_entries()

    assert occurrences == @suite_floor_env_occurrences,
           "expected exactly #{@suite_floor_env_occurrences} `#{@suite_floor_env_entry}` " <>
             "entries in advisory-matrix.yml ..."
  end

  test "anti-vacuity: the parser finds the workflow and the env entry it counts" do
    source = File.read!(@advisory_matrix_path)

    assert byte_size(source) > 0, "advisory-matrix.yml parsed to an empty string ..."

    assert String.contains?(source, @suite_floor_env_entry),
           "advisory-matrix.yml contains no `#{@suite_floor_env_entry}` at all. ..."
  end

  test "negative control: deleting one occurrence from the parsed source makes the count " <>
         "assertion report it" do
    source = File.read!(@advisory_matrix_path)

    assert count_suite_floor_env_entries(source) == @suite_floor_env_occurrences,
           "sanity check failed: the unmodified workflow should already carry both entries"

    broken = String.replace(source, @suite_floor_env_entry, "", global: false)

    assert count_suite_floor_env_entries(broken) == @suite_floor_env_occurrences - 1,
           "removing one occurrence must be observable by the same counting function ..."
  end
end
```
```elixir
# lines 1280-1286 — the counting helper, parameterized by @advisory_matrix_path today
defp count_suite_floor_env_entries(source \\ nil) do
  (source || File.read!(@advisory_matrix_path))
  |> String.split(@suite_floor_env_entry)
  |> length()
  |> Kernel.-(1)
end
```
**New code (D-08):** add `@ci_yml_path Path.join(@repo_root, ".github/workflows/ci.yml")` (the
module already declares `@ci_yml_path` for other tests — confirm no name collision, or reuse it),
a new `@ci_yml_suite_floor_occurrences 1` (one occurrence — the single `core_deterministic_suite`
step), a parallel `count_suite_floor_env_entries_in_ci_yml/1` (or parameterize the existing helper
to take a path), and the same three-test trio (assertion, anti-vacuity, negative control) targeted
at `ci.yml`. **Do not** touch `@suite_floor_env_occurrences` (D-07: it counts `advisory-matrix.yml`
only; bumping 2→3 would make that test red against an unchanged file).

**Runtime consumer (unmodified, D-09/D-10)** — `test/support/suite_floor.ex`:
- `@executed_floors` (public/private) at lines 286-289 — floors are 1576/1575 against ~2145
  executed today.
- `@skipped_ceiling 7` at line 307 — matches measured 7 skipped.
- `@known_exclusion_tags` at lines 245-259.
- Growth-nudge-is-warning-not-failure at lines 693-711.

**CI env line (D-09)** — add to `ci.yml:444-452`'s existing `env:` block (quoted verbatim, current
state):
```yaml
      - name: Run deterministic core suite
        # Full root suite: no directory filter, exclusions, fixed seed, or
        # advisory continuation. Suite-floor and skip-ledger contracts run as
        # part of this invocation and reject silent scope erosion.
        id: deterministic-core
        env:
          MAILGLASS_TIMEOUT_EVIDENCE_PATH: tmp/timeout-evidence/database.ndjson
          MAILGLASS_TIMEOUT_EVIDENCE_COMMAND: mix test --warnings-as-errors
        run: mix test --warnings-as-errors
```
Add `MAILGLASS_SUITE_FLOOR: "1"` into that `env:` block — this is the one occurrence the new
`@ci_yml_suite_floor_occurrences 1` guard counts.

---

### `.github/workflows/post-publish-smoke.yml` (route/config, request-response+pub-sub) — CTRL-01

**Analog:** same file's existing event-branching (re-verified this session; line numbers corrected
from CONTEXT.md's stale `:263-265`/`:285-288` per RESEARCH.md Correction 1 — **grep by literal
string, not by line number, when implementing**):

**Command-selection branch to extend (verified at lines 128-130, not :263-265):**
```bash
# .github/workflows/post-publish-smoke.yml:128-130 [grep -n 'command="authorized-versions"']
command="authorized-versions"
if [ "$EVENT_NAME" = "schedule" ]; then command="completed-versions"; fi
```
Add a `baseline-versions` verb selected when `status == "inactive"` in
`.planning/release-target.json` (D-17 item 1).

**Dispatch inputs (unchanged shape, verified at lines 15-30) — add a new mode input alongside
these, keep `required: true`:**
```yaml
    inputs:
      core_version:
        description: "Exact published mailglass version from the protected target"
        required: true
        type: string
      admin_version:
        description: "Exact published mailglass_admin version from the protected target"
        required: true
        type: string
      inbound_version:
        description: "Exact published mailglass_inbound version from the protected target"
        required: true
        type: string
      target_ref:
        description: "Immutable 40-character tag SHA validated by the protected publisher"
        required: true
        type: string
```

**40-hex fail-closed guard (verified at lines 73-77, one line off CONTEXT's `:78`) — condition on
mode, do not weaken:**
```bash
# .github/workflows/post-publish-smoke.yml:73-77
if [ "$EVENT_NAME" = "workflow_dispatch" ]; then
  if ! [[ "$INPUT_TARGET_REF" =~ ^[0-9a-f]{40}$ ]]; then
    write_resolution "cannot-check" "invalid_protected_target_ref" "invalid" "" "" "" "" "" ""
    exit 1
  fi
fi
```

**Cron-guard predicate to widen (verified at line 296, not `:285-288`):**
```js
// .github/workflows/post-publish-smoke.yml:296 [grep -n "eventName === 'schedule' && process.env.COMPLETED"]
if (eventName === 'schedule' && process.env.COMPLETED !== 'true') {
  core.setFailed('Scheduled smoke requires an immutable completed target.');
  return;
}
```
Widen to `COMPLETED === 'true' || BASELINE === 'true'` — emit a **distinct** `baseline=true` output
from the new resolution verb; never reuse `completed=true` for an inactive ledger (D-17 item 3).

**Digest-bypass target (verified at lines 86-91-ish in `scripts/check_post_publish_target.sh`):**
```bash
# scripts/check_post_publish_target.sh:86-91
if ! expected_digest=$(jq -er \
  '.publishable_content.digest | select(type == "string" and test("^[0-9a-f]{64}$"))' \
  "$target"); then
  echo "ERROR: authorized content digest is missing or malformed" >&2
  exit 1
fi
```
`close_out_successor/3` in `scripts/release_policy.exs` (verified at ~line 620-624) sets
`"digest" => nil`:
```elixir
"publishable_content" => %{
  "algorithm" => "sha256",
  "digest" => nil,
  "excludes" => [".planning/release-target.json"]
},
```
CTRL-01's baseline-mode target check must skip the 64-hex digest requirement specifically for
baseline mode (D-17 item 4), not remove it for the live-dispatch path.

---

### `.github/workflows/release-please.yml` (config, event-driven) — CTRL-02/CTRL-03

**Analog:** same file's own `continue-on-error` + classify-then-gate pattern, already used three
times in the proposal path (verified lines 459, 502, 662).

**CTRL-02 — the early exit to delete (verified lines 90-95):**
```bash
# .github/workflows/release-please.yml:92-95
if [ -z "${CANDIDATE_DIGEST:-}" ]; then
  ...
  exit 0
fi
```
This makes the dead `elif` branch reachable (verified line 104:
`elif ! expected_tags_text=$(scripts/release_policy_expected_tags.sh "$manifest")`). Downstream,
the already-tagged-SHA skip (verified lines 141-142, 162-165) is what CTRL-02 restores:
```bash
# :141-142
echo "should_run=false" >>"$GITHUB_OUTPUT"
exit 0
...
# :162-165
if grep -qx 'autorelease: tagged' <<<"$labels"; then
  ...
  echo "should_run=false" >>"$GITHUB_OUTPUT"
  exit 0
fi
```

**CTRL-03 — classify-then-gate pattern to extend (verified `gh api --include` at line 119; the
`continue-on-error` steps to model the new retry loop on, verified at lines 459 and 502):**
```yaml
# :459 (proposal-discovery step header)
      - name: Discover an open Release Please proposal before capture
        id: proposal-discovery
        if: ${{ steps.release-preflight.outputs.should_run == 'true' && github.event.inputs.candidate_digest == '' }}
        continue-on-error: true
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          should_capture=true
          result_status=""
          result_reason=""

          if ! prs=$(gh pr list --head release-please--branches--main --base main --state open --json number,headRefOid,baseRefOid); then
            should_capture=false
            result_status=cannot-check
            result_reason=github_evidence_unavailable
            printf 'should_capture=%s\nresult_status=%s\nresult_reason=%s\n' "$should_capture" "$result_status" "$result_reason" >> "$GITHUB_OUTPUT"
            exit 1
          fi
```
This is the exact "classify a failed `gh api`/`gh pr` call into a named `result_status`/
`result_reason` output, never crash the job" shape to reuse for the bounded retry loop around
`gh api` at `:119`/`:179` (D-20) — wrap the call in a bash loop that retries on 403/429 +
`/secondary rate/i` body match, sleeping per D-22's policy (retry-after → x-ratelimit-reset only if
remaining==0 → 60s floor, ×2 escalation, 3 attempts), before falling through to this same
`cannot-check` classification on final failure.

**The one non-`continue-on-error` API step (verified: `id: release`, ~line 291-296):**
```yaml
      - id: release
        ...
        uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7  # v5.0.0
        with:
          token: ${{ secrets.RELEASE_PLEASE_PAT }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
          skip-github-release: ${{ github.event.inputs.candidate_digest == '' }}
```
This is the step CTRL-03 must wrap in `continue-on-error: true` + one guarded backoff re-run
(D-20) — currently the only step in the proposal path without that protection.

**The gate — byte-for-byte unchanged (D-21, verified line 739):**
```bash
[ "$RESULT_STATUS" = pass ] || { [ "$RESULT_STATUS" = pending ] && [ "$RESULT_REASON" = no_open_proposal ]; }
```

---

### `lib/mailglass/supply_chain/accepted_advisories.ex` (model, CRUD) — CTRL-04

**Analog:** same file — this is the canonical source, no external analog. Both entries verified
verbatim at lines 62-89:
```elixir
@entries [
  %{
    id: "EEF-CVE-2026-43966",
    aliases: [],
    package: "cowlib",
    severity: "MEDIUM",
    reason:
      "HTTP Response Splitting via non-VCHAR bytes; no upstream fix as of cowlib 2.19.0 " <>
        "(Hex hex.audit/EEF-CVE database); absent from mirego's mix_audit DB under cowlib " <>
        "entirely (an upstream data gap, not a suppression); transitive via " <>
        "cowboy/plug_cowboy/phoenix, unavoidable for any web server.",
    accepted_on: ~D[2026-07-28],
    recheck_by: ~D[2026-10-26]
  },
  %{
    id: "EEF-CVE-2026-43969",
    aliases: ["GHSA-g2wm-735q-3f56"],
    package: "cowlib",
    severity: "LOW",
    reason:
      "Cookie Request Header Injection; no upstream fix as of cowlib 2.19.0 (Hex " <>
        "hex.audit/EEF-CVE database); mirego's mix_audit DB range for this advisory closes " <>
        "at <= 2.16.1, so mix deps.audit no longer flags cowlib 2.19.0 for it — the entry " <>
        "stays because the Hex-native hex.audit side still reports it live; this is WHY " <>
        "expired_entries/1 and unused_entries/1 are scoped to --kind hex only, not a " <>
        "contradiction.",
    accepted_on: ~D[2026-07-28],
    recheck_by: ~D[2026-10-26]
  }
]
```
Edit **only** the `reason:` string (both entries) to the permanent-refusal framing (D-29) and
`recheck_by:` (both entries) to `~D[2027-03-17]` (D-30, USER DECISION). `expired_entries/1` (lines
189-191, uses `Date.utc_today()` default at 188) and `unused_entries/1` (200-202) are untouched —
data-only edit (D-31 exemption, state explicitly in plan/PR).

**Test lockstep, verified verbatim at lines 155, 158-165, 168-174, 177 in
`test/mailglass/supply_chain/accepted_advisories_test.exs`:**
```elixir
test "an entry whose recheck_by is exactly today is NOT flagged (strictly-after semantics)" do
  assert AcceptedAdvisories.expired_entries(~D[2026-10-26]) == []
end

test "an entry whose recheck_by was yesterday IS flagged" do
  result = AcceptedAdvisories.expired_entries(~D[2026-10-27])

  assert Enum.map(result, & &1.id) == [
           "EEF-CVE-2026-43966",
           "EEF-CVE-2026-43969"
         ]
end

test "reports every entry after the latest recheck date" do
  result = AcceptedAdvisories.expired_entries(~D[2026-12-01])

  assert Enum.map(result, & &1.id) == [
           "EEF-CVE-2026-43966",
           "EEF-CVE-2026-43969"
         ]
end

test "no entries are flagged before recheck_by has arrived" do
  assert AcceptedAdvisories.expired_entries(~D[2026-07-28]) == []
end
```
`~D[2026-10-26]`/`~D[2026-10-27]` must move to the new `recheck_by` boundary (`~D[2027-03-17]` /
`~D[2027-03-18]`) and — critically — the `~D[2026-12-01]` test currently asserts **both entries ARE
expired**, which becomes false once `recheck_by` moves past that date; it must be rewritten to
assert `== []` (or a date past the new boundary substituted). Land both files in one commit
(D-33/Pitfall 3 — the Phase 125 pin-drift shape, third occurrence).

---

### `dev/mix/tasks/mailglass.repo.hygiene.ex` (utility, request-response) — CTRL-05

**Analog:** same file's existing classify-and-aggregate pattern.

**Exit-code collapse to split (verified lines 46-48):**
```elixir
if result.status != :pass do
  exit({:shutdown, 1})
end
```
And the aggregation it feeds (verified lines 427-433):
```elixir
defp status(checks) do
  cond do
    Enum.any?(checks, &(&1.status == :cannot_check)) -> :cannot_check
    Enum.any?(checks, &(&1.status == :blocked)) -> :blocked
    true -> :pass
  end
end
```
D-34: give `:cannot_check` its own distinct non-zero exit code, distinguishable from `:blocked`'s —
**never exit 0 for `:cannot_check`** (that would be a permanent-green, the CTRL-03 temptation class).

**PR predicate to replace (verified lines 275-301, the `pull_requests/1` function; predicate itself
at lines 293-300):**
```elixir
defp pull_requests(repo) do
  if System.find_executable("gh") == nil do
    cannot_check(:pull_requests, "GitHub CLI is not installed; open PRs were not checked.", %{})
  else
    args = [
      "pr",
      "list",
      "--state",
      "open",
      "--limit",
      "100",
      "--json",
      "number,title,isDraft,headRefName,updatedAt,mergeStateStatus"
    ]

    case cmd(repo, "gh", args) do
      {json, 0} ->
        case Jason.decode(json) do
          {:ok, prs} when is_list(prs) ->
            status =
              if Enum.empty?(prs) do
                :pass
              else
                :blocked
              end

            check(:pull_requests, status, pr_message(prs), %{
              open_count: length(prs),
              prs: prs
            })
```
D-35: widen the `--json` field list to add `createdAt` (age) and `statusCheckRollup` (failing-check
status), and replace `Enum.empty?(prs), do: :pass, else: :blocked` with "open **>14d** or failing a
required check."

**Test fixture pattern to extend (verified lines 318-357 and the `gh` stub-script generator at lines
405-460 in `test/mix/tasks/mailglass.repo.hygiene_test.exs`):**
```elixir
empty =
  with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end, pr_response: "[]")

assert check(empty, :pull_requests).status == :pass
assert check(empty, :pull_requests).details == %{open_count: 0, prs: []}

prs =
  with_hygiene_environment(repo, fn -> Hygiene.audit(repo) end,
    pr_response: "[{\"number\":222,\"title\":\"Candidate\"}]"
  )

assert check(prs, :pull_requests).status == :blocked
assert check(prs, :pull_requests).details.open_count == 1
assert check(prs, :pull_requests).details.prs == [%{"number" => 222, "title" => "Candidate"}]
```
`with_hygiene_environment/3` (lines 405-460) generates a fake `gh` executable as a bash script on
`$PATH` that branches on `$1 pr list` vs `$1 run list`, returning a caller-supplied `pr_response`
JSON string — this is the fixture mechanism to reuse for new cases exercising `createdAt`-aged and
`statusCheckRollup`-failing PR shapes:
```bash
# generated fixture body, test/mix/tasks/mailglass.repo.hygiene_test.exs:427-436
if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
  if [ "#{pr_query_exit}" -ne 0 ]; then
    echo 'PR query unavailable' >&2
    exit #{pr_query_exit}
  fi

  echo '#{pr_response}'
  exit 0
fi
```
New test cases should pass `pr_response:` JSON strings including `createdAt` timestamps >14 days
old, and `statusCheckRollup` entries with a `FAILURE`/`ERROR` conclusion, then assert the new
`:blocked` classification fires — while a healthy (<14d, all-green) PR stays `:pass` (this is the
"a healthy PR does not red it" acceptance half of CTRL-05).

---

### GREEN-04: `reference/demo_app` isolated Hex-deps CI step

**Analog:** same file's (`ci.yml`) existing path-dep demo install steps — mirror the **shape**,
invert the **dependency-resolution mode**:
```yaml
# ci.yml:276-281 [VERIFIED — existing path-dep demo build, DO NOT flip this one]
      - name: Install demo deps
        working-directory: reference/demo_app
        run: mix deps.get --check-locked
      - name: Compile demo app for coverage
        working-directory: reference/demo_app
        run: mix compile --warnings-as-errors
```
`reference/demo_app/mix.exs:60-76` [VERIFIED] swaps to hex deps via `MAILGLASS_DEMO_DEPS`:
```elixir
defp mailglass_dep do
  if hex_deps?(), do: {:mailglass, "~> 2.0"}, else: {:mailglass, path: "../..", override: true}
end

defp mailglass_admin_dep do
  if hex_deps?(),
    do: {:mailglass_admin, "~> 2.0"},
    else: {:mailglass_admin, path: "../../mailglass_admin", override: true}
end

defp mailglass_inbound_dep do
  if hex_deps?(),
    do: {:mailglass_inbound, "~> 2.0"},
    else: {:mailglass_inbound, path: "../../mailglass_inbound", override: true}
end

defp hex_deps?, do: System.get_env("MAILGLASS_DEMO_DEPS") == "hex"
```
`[VERIFIED]` `MAILGLASS_DEMO_DEPS` does not appear anywhere in `.github/workflows/ci.yml` today
(confirmed by grep — only the `mix.exs` reference exists). GREEN-04's new CI step is a **separate**
job or a separate `MIX_BUILD_PATH` within an existing job (D-11, Claude's Discretion), running:
```bash
MAILGLASS_DEMO_DEPS=hex mix deps.get --check-locked && mix compile
```
in `reference/demo_app`. Never edit the existing steps at `ci.yml:276-281` / `:424-437` (those
prove the working tree under test — D-11).

---

## Shared Patterns

### Alias-name-matched parity
**Source:** `test/scripts/ci_parity_drift_test.exs:184` (verified verbatim):
```elixir
"Support Contract Admin (Elixir 1.18 / OTP 27)" => ["verify.support_contract.admin"],
```
**Apply to:** GREEN-01's alias redefinition, and any other alias-body change in this phase. The
parity test matches on **name**, not body — redefine freely, `ci.yml` needs zero edits as long as
the alias name is unchanged (`ci.yml:916-917` invocation `cd mailglass_admin && mix
verify.support_contract.admin` stands as-is).

### Measured-ratchet floors, never hand-picked percentages
**Source:** `config/coverage_baselines/core.json` + `scripts/check_coverage_floor.sh` (both quoted
in full above).
**Apply to:** `config/coverage_baselines/admin.json` (GREEN-02). The triple
(`covered_lines`/`relevant_lines`/`percentage`) plus `report_sha256` plus an exact-toolchain
assertion is the load-bearing shape — a bare percentage loses the `relevant_lines` half of the
ratchet and either passes vacuously or reds immediately.

### Occurrence-count drift guard (D-08 pattern)
**Source:** `test/scripts/lane_classification_drift_test.exs:43-56,592-641,1280-1286` (quoted in
full above).
**Apply to:** GREEN-03's `ci.yml` extension. A constant + anti-vacuity test + negative-control test,
never a bare count bump on an unrelated file's existing guard (D-07's named anti-pattern).

### Classify-then-gate for GitHub API evidence
**Source:** `.github/workflows/release-please.yml` (verified `continue-on-error: true` steps at
lines 459, 502, 662; the gate at line 739: `[ "$RESULT_STATUS" = pass ] || { [ "$RESULT_STATUS" =
pending ] && [ "$RESULT_REASON" = no_open_proposal ]; }`).
**Apply to:** CTRL-03's retry loop around `gh api` calls, and any other GitHub-API-touching step in
this phase (CTRL-05's `gh pr list`). Every API step except the one non-`continue-on-error` action
step (`id: release`, ~line 291) already follows this shape — extend it, never invent a new
evidence-reporting convention.

### Two-file doc/test lockstep (Phase 125 pin-drift shape, third occurrence — D-33)
**Source:** `lib/mailglass/supply_chain/accepted_advisories.ex:73,88` (`recheck_by`) +
`test/mailglass/supply_chain/accepted_advisories_test.exs:155-177` (hardcoded date assertions).
**Apply to:** CTRL-04. A literal value asserted verbatim by a test, split across two files — moving
one without the other produces a deterministic red. Land in one commit.

### `gh` CLI stub-script fixture (test-infrastructure pattern)
**Source:** `test/mix/tasks/mailglass.repo.hygiene_test.exs:405-460`, `with_hygiene_environment/3`
— generates a fake `gh` executable on `$PATH` that branches on subcommand and returns
caller-supplied JSON.
**Apply to:** CTRL-05's new test cases (aged/failing-check PR shapes) — reuse the existing helper's
`pr_response:`/`pr_query_exit:` options rather than building a new stub mechanism.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| GREEN-05 committed note (new markdown deliverable proving cache non-contamination) | docs/config | transform (structural proof) | Not code — a documented key-space table + CI-observed proof + lock-diff evidence. No existing "prove a negative about GitHub Actions cache internals" artifact exists in this repo to mirror; RESEARCH.md's Architecture Patterns section and D-15's three-part structure (key-space table, CI-run evidence, lock-authority proof) is the closest thing to a template — treat 166-RESEARCH.md's D-13/D-14/D-15 prose as the source material, not an in-repo file. |
| Bounded retry/backoff loop implementation itself (the literal bash sleep/escalation logic for CTRL-02/CTRL-03) | utility (shell, embedded in workflow YAML) | request-response | Confirmed via grep: no existing retry/backoff loop with sleep-and-retry semantics exists anywhere in `.github/workflows/*.yml` today. The closest thing (`continue-on-error` + classify, see Shared Patterns above) handles *reporting* a transient failure but never *retries* the call. The retry loop's concrete algorithm (403/429 + `/secondary rate/i` classification, `retry-after` → `x-ratelimit-reset` → 60s floor, ×2 escalation, 3 attempts) is net-new and must be written from 166-CONTEXT.md D-22/D-24's specification and 166-RESEARCH.md's GitHub-docs citations, not copied from an in-repo analog. `ensure-live-ci-runs` in `publish-hex.yml` was checked and does **not** contain a rate-limit retry loop — CLAUDE.md's reference to it is about a different problem (bot-merged SHA missing a `ci.yml` run), now itself listed as obsolete guidance. |
| `faketime`-based CTRL-04 verification step | CI verification tooling | batch (one-shot OS-level clock spoof) | Genuinely new to this repo — no prior use of `faketime`/libfaketime anywhere. 166-RESEARCH.md flags this as unverified for BEAM clock reads (Open Question 1) and recommends a smoke-test-first approach with a test-date-rewrite fallback if it doesn't intercept Erlang's clock reads. |

## Metadata

**Analog search scope:** `mailglass_admin/`, `mailglass_inbound/`, root `mix.exs`, `config/`,
`scripts/`, `test/scripts/`, `test/support/`, `test/mailglass/supply_chain/`, `test/mix/tasks/`,
`dev/mix/tasks/`, `.github/workflows/*.yml`, `lib/mailglass/supply_chain/`, `reference/demo_app/`.
**Files scanned:** ~25 (all directly read/grepped this session; no directory-wide Glob sweep was
needed because 166-CONTEXT.md and 166-RESEARCH.md already named every target file precisely).
**Pattern extraction date:** 2026-09-17.
**Toolchain used for any local verification commands referenced above:**
`ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` (per project convention — bare
`mix` fails with a misleading `corrupt atom table` otherwise).
