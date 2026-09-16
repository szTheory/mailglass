---
phase: quick-260916-ldh
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scripts/release_policy.exs
  - scripts/release_policy_close_out.sh
  - test/scripts/release_policy_test.exs
  - test/scripts/release_policy_close_out_test.exs
  - .github/workflows/release-please.yml
  - test/scripts/release_policy_contract_test.exs
autonomous: true
requirements: ["QUICK-260916-ldh"]

estimate:
  tokens: 70000
  raw_tokens: 55000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "A release-target ledger left at `authorized`/`published`/`completed` after a real publish can be returned to `inactive` by a single command, with no hand-editing of JSON."
    - "The close-out transition can only ever produce `status: inactive` — it can never emit a `captured`, `authorized`, `published`, or `completed` ledger, so it cannot manufacture publish authorization."
    - "Close-out refuses to run unless all three candidate versions are live, non-retired releases on Hex whose checksums come from the Hex release API, and the core release tag resolves to a real commit."
    - "A push to `main` with a stranded post-publication ledger no longer fails the release-please proposal-capture control closed; it self-heals in memory and reports the strand by reason."
    - "The existing seven coupled release suites stay green."
  artifacts:
    - "scripts/release_policy.exs — `close_out/3` + `cli([\"close-out\", ...])`"
    - "scripts/release_policy_close_out.sh — evidence-gated wrapper, `--write` applies in place"
    - "test/scripts/release_policy_close_out_test.exs — offline wrapper tests with a stubbed `curl`"
  key_links:
    - "close_out/3 output must pass validate_target/1 before it is returned (self-check, fail closed)"
    - "wrapper's Hex checksums feed release_policy_hex_release_state.sh, which is the retirement/format gate"
    - "release-please.yml capture control `case \"$target_status\"` (currently lines 558-594) routes the healed ledger into the existing `inactive)` capture path"
---

<objective>
Add the missing write path that returns a post-publication release-target ledger to `inactive`, so release-please stops failing closed on every push to `main` after a real release.

Purpose: the ledger has no transition out of `authorized`/`published`/`completed`. Every real release therefore strands it, and `release-please.yml` blocks with `proposal_identity_mismatch` (the 2.5.0 strand went unnoticed ~4 weeks, 0 successes in 100 runs). This plan adds the mechanism only — the current file was already closed out by hand in PR #266, which this branch is stacked on.

Output: a non-authorizing `close-out` verb in the policy module, an evidence-gated shell wrapper, workflow self-heal, and tests for all three.
</objective>

<design_decision>
**Chosen: option (a) — a new `close-out` verb in `scripts/release_policy.exs` that PRINTS the successor — plus a bounded, provably non-authorizing form of (c) as the trigger. Option (b) is rejected.**

Rationale, from live reading of the repo:

1. **(b) is rejected on security grounds.** `.github/workflows/publish-hex.yml` declares `permissions: contents: read` at the top level and re-declares `contents: read` on every job that narrows it (lines 62-63, 368-369, 526-527, 1258-1259). That workflow is the one holding `HEX_API_KEY` through the `hex-publish` environment. Turning the publishing workflow into a repository writer to do bookkeeping is a real privilege expansion on the highest-value workflow in the repo for a bookkeeping gain. Not worth it.

2. **(a) is the shape that matches the module.** `capture-candidate` (line 368) already establishes the convention: validate, compute, `IO.puts(Jason.encode!(...))`, let the caller decide what to do with it. Close-out is the mirror image of capture and belongs beside it.

3. **The transition is non-authorizing by construction, which is what makes automating it safe.** `close_out/3` hard-codes `status: "inactive"` and `states: {capture: inactive, authorization: unauthorized, publication: not_started}`, nils `candidate_versions`, `proposal_identity`, `publishable_content.digest`, and `final_identity`. It has no code path that emits any other status, and it re-runs its own output through `validate_target/1` before returning. An `inactive` ledger authorizes nothing: it must still go through capture → dual authorization → protected dispatch to publish anything. So an automated close-out writer cannot manufacture authorization — it can only ever move *away* from it.

4. **Its input gate is stronger than the ledger's self-report.** Rather than trusting `status == "published"`, the wrapper requires live proof: each candidate version must return HTTP 200 from `https://hex.pm/api/packages/<pkg>/releases/<version>`, be non-retired, and yield a `checksum` that the existing hardened `scripts/release_policy_hex_release_state.sh` then re-verifies as `exists`; and `mailglass-v<core>` must resolve to a real 40-hex commit. Checksums are read from the Hex API, never computed or invented. When the ledger *does* carry `final_identity.publication_evidence`, close-out additionally requires the supplied tag SHA and checksums to equal that recorded evidence.

5. **Accepted input statuses are `authorized`, `published`, and `completed` — deliberately including `authorized`.** This is the answer to "should `publication` advance to `published` in the fan-out": **no, not here.** Nothing writes the ledger at all today, so the *actual* strand state after a real release is `authorized` + `publication: not_started` (that is exactly the 2.5.0 case, which lands in the `captured|authorized)` branch at line 563 and fails `proposal_identity_mismatch`). A close-out that only accepted `published` would never fire on the failure it exists to fix. Advancing `publication` in the fan-out is the same `contents: write` regression as (b) and is explicitly out of scope; the live-Hex gate is a stronger substitute for that self-report anyway. Recorded here so it is not silently dropped.

6. **Trigger: bounded self-heal in `release-please.yml`, not a workflow push to protected `main`.** The capture control (lines 556-594) already `git show`s the source ledger into a temp file `$source_target` and branches on its status. The `captured|authorized)` and `completed)` branches are extended to first attempt close-out on that temp copy; on success the control proceeds down the existing `inactive)` capture path and reports the strand via a distinct reason. Because the healed ledger is `inactive`, this self-heal cannot authorize anything (point 3), which is precisely why the (c)-shaped trigger is acceptable here and would not be if close-out could emit any other status. Persisting the healed file to `main` stays a one-command maintainer action (`scripts/release_policy_close_out.sh --write`) rather than granting a workflow direct push to a protected branch, and rather than committing onto the release-please PR branch — the control at line 281 asserts `cmp -s` equality between the branch ledger and main's ledger, so writing a different ledger to that branch would break the very control being fixed.

**Commit type:** `release-please-config.json` lists `.github`, `.planning`, `scripts`, and `test` in the core package's `exclude-paths` (verified in the config on disk, 12 entries). Every file this plan touches is inside those excluded paths, so no commit here can trigger a release. Use `fix(release):` or `chore(release):` — do not use `feat(...)`, which is the commit type that caused the accidental 1.6.2 release train.
</design_decision>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@scripts/release_policy.exs
@scripts/release_policy_hex_release_state.sh
@scripts/verify_published_release.sh
@.planning/release-target.json
@test/scripts/release_policy_test.exs
@test/scripts/verify_published_release_test.exs
</context>

<preconditions>
The Elixir toolchain must be exported before any `mix` invocation in this plan:
`export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`
Bare `mix` fails with a misleading `corrupt atom table` error because `.tool-versions` pins erlang versions that are not installed locally. The tracked `.tool-versions` is the correct CI contract — do not edit it.
</preconditions>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Non-authorizing `close_out/3` + `close-out` CLI verb in the policy module</name>
  <files>scripts/release_policy.exs, test/scripts/release_policy_test.exs</files>
  <read_first>
    scripts/release_policy.exs in full — specifically `cli(["capture-candidate", ...])` (line 368) for the print-don't-write convention, `lifecycle/1` (line 397) for the exact `inactive` invariants, `evidence/2` (line 486) for how `hex_release_endpoints`/`historical_tag` are validated against `baselines`, `candidate_final_identity/1` (line 551), and `published_final_identity/2` (line 555).
    test/scripts/release_policy_test.exs lines 300-467 for the `captured_target/0`, `published_target/0`, `completed_target/0`, `evidence/0`, `run_cli/1`, `in_tmp/1`, and `write_json/3` fixtures to reuse.
  </read_first>
  <behavior>
    - Given a `published` target, `close_out/3` with the recorded tag SHA and recorded publication checksums returns `{:ok, successor}` where `successor["status"] == "inactive"`, `successor["states"] == %{"capture" => "inactive", "authorization" => "unauthorized", "publication" => "not_started"}`, `candidate_versions == nil`, `proposal_identity == %{"head_sha" => nil, "source_sha" => nil}`, `publishable_content["digest"] == nil`, and `final_identity == %{"tag_sha" => nil}` exactly.
    - The successor's `baselines` equal the input's `candidate_versions`; `required_evidence_identifiers.hex_release_endpoints` are rebuilt from the new baselines; `hex_release_checksums` equal the supplied checksums; `historical_tag == "mailglass-v" <> new core version`; `historical_tag_sha == tag_sha`; `hex_package_endpoints`, `package_set`, and `schema_version` are carried through unchanged.
    - `validate_target/1` accepts the successor (the function re-validates its own output before returning; if that self-check fails it returns an error instead of the successor).
    - Non-authorizing property: for each accepted input status (`authorized`, `published`, `completed`), the successor makes `candidate_digest/1` and `expected_tags/1` return `{:error, %{reason: :inactive_candidate}}`, and there is no argument for which `close_out/3` returns a successor whose `status` is not `"inactive"`.
    - `advances/2` semantics move forward: `validate_candidate/2` against the successor fails for the versions that were just released, and succeeds only for strictly greater versions.
    - Refusals (each returns `{:error, _}`, never a successor): input `status == "inactive"`; input whose `states["capture"] != "captured"`; malformed `tag_sha` (not 40-hex); checksums map with a missing/extra package key or a non-sha256 value; for a `published`/`completed` input, a `tag_sha` that differs from `final_identity["tag_sha"]` or checksums that differ from `final_identity["publication_evidence"]["hex_release_checksums"]`.
    - CLI: `close-out TARGET_PATH TAG_SHA CHECKSUMS_JSON_PATH` prints the successor as pretty JSON with a trailing newline and exits 0; any refusal exits non-zero and prints no JSON. Two runs on identical input produce byte-identical output.
  </behavior>
  <action>
    Add a public `close_out/3` to `Mailglass.ReleasePolicy` taking `(target, tag_sha, checksums)`, placed next to the other public validators, and a `cli(["close-out", target_path, tag_sha, checksums_path])` clause placed immediately after the `capture-candidate` clause and before the catch-all `cli(_)`.

    Implement `close_out/3` as a `with` pipeline in the existing style: `validate_target/1` on the input; require `target["status"]` to be one of `authorized`/`published`/`completed` and `target["states"]["capture"] == "captured"`, else a new error reason such as `:close_out_not_applicable`; require `sha1?(tag_sha)` and reuse the existing private `checksum_map/1` for the checksums; when `target["final_identity"]` carries `publication_evidence`, require `tag_sha` and `checksums` to equal the recorded values via the existing `exact_value/3`, else a reason such as `:close_out_evidence_mismatch`. Then construct the successor map by hard-coding the `inactive` shape (never by copying the input status or states), derive `baselines` from `candidate_versions`, rebuild `hex_release_endpoints`/`historical_tag`/`historical_tag_sha`/`hex_release_checksums`, and finish the pipeline with `validate_target(successor)` so nothing invalid can escape. Reuse `@packages` and the existing private helpers rather than restating literals.

    The CLI clause reads both JSON files with the existing `read_json/1`, calls `close_out/3`, and on success writes `Jason.encode!(successor, pretty: true)` followed by a newline to stdout; on any error it calls `System.halt(1)` like every neighbouring clause. It must not write any file.

    Add the tests described in `<behavior>` to `test/scripts/release_policy_test.exs`, reusing `published_target/0`, `completed_target/0`, and an `authorized` variant derived from `captured_target/0`, plus `run_cli/1` and `in_tmp/1`/`write_json/3` for the CLI-level cases. Do not add network access to any test.
  </action>
  <verify>
    <automated>export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && cd /Users/jon/projects/mailglass && mix format --check-formatted scripts/release_policy.exs test/scripts/release_policy_test.exs && mix test test/scripts/release_policy_test.exs</automated>
  </verify>
  <done>`mix test test/scripts/release_policy_test.exs` is fully green including the new close-out cases, and no test in it reaches the network.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Evidence-gated `release_policy_close_out.sh` wrapper</name>
  <files>scripts/release_policy_close_out.sh, test/scripts/release_policy_close_out_test.exs</files>
  <read_first>
    scripts/release_policy_hex_release_state.sh in full (it takes PACKAGE VERSION CHECKSUM and echoes `exists`/`absent`, and is the retirement + checksum-format gate).
    scripts/verify_published_release.sh lines ~180-239 for how that script feeds ledger checksums into `release_policy_hex_release_state.sh` and asserts `exists`.
    test/scripts/verify_published_release_test.exs lines 20-145 and 320-345 for the established offline pattern: a fake `curl` (and `gh`) written into a temp `bin/`, prepended to `PATH`, logging requested URLs to `FAKE_CURL_LOG`.
  </read_first>
  <behavior>
    - Happy path: given a ledger whose candidate versions all return HTTP 200 non-retired Hex releases and whose `mailglass-v<core>` tag resolves, the wrapper prints the `inactive` successor JSON to stdout and exits 0 without modifying any file.
    - `--write` replaces the ledger file in place with exactly the bytes it would have printed, via a temp file and `mv` (never a partial write), and is a no-op on the file when any gate fails.
    - It requests exactly the three release endpoints for the *candidate* versions, in package order — asserted from the fake-curl log.
    - Refusals, each exiting non-zero with a message on stderr and leaving the ledger byte-identical: ledger status `inactive`; any package returning HTTP 404; any package whose Hex payload is retired or whose checksum is malformed; a `mailglass-v<core>` tag that does not resolve; a ledger whose recorded publication evidence disagrees with what Hex reports.
    - Checksums are only ever taken from the Hex response body; the wrapper never computes, defaults, or accepts a checksum argument.
  </behavior>
  <action>
    Create `scripts/release_policy_close_out.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`, mode 0755, matching the argument-parsing and error style of the sibling `release_policy_*.sh` scripts. Accept `--target PATH` (default `.planning/release-target.json`), `--repo PATH` (default the repo root, for tag resolution), and `--write`.

    Sequence, failing closed at each step: read `.status` with `jq -er` and require it to be `authorized`, `published`, or `completed`; read `.candidate_versions` per package; for each package `curl` the release endpoint `https://hex.pm/api/packages/<pkg>/releases/<version>`, capture the HTTP status and body, require 200, and extract `.checksum`; pass each fetched checksum through `scripts/release_policy_hex_release_state.sh <pkg> <version> <checksum>` and require the output to be exactly `exists` (this is what enforces retirement and format — do not re-implement it); resolve the tag with `git -C <repo> rev-parse --verify "refs/tags/mailglass-v<core>^{commit}"` and require a 40-hex result; assemble the fetched checksums into a temp JSON file; invoke the policy CLI with `mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- close-out <target> <tag_sha> <checksums_json>` exactly as the other wrappers do; capture stdout; with `--write`, write it to a temp file beside the target and `mv` into place, otherwise print it. Clean up temp files with a `trap`.

    Add `test/scripts/release_policy_close_out_test.exs` in the style of `verify_published_release_test.exs`: `use ExUnit.Case, async: false` (it shells out to Mix), a per-test temp root, a fake `curl` on `PATH` serving fixture bodies keyed by URL and logging to `FAKE_CURL_LOG`, and a real `git init` temp repo with a real `mailglass-v<core>` tag for the tag-resolution cases. Cover every bullet in `<behavior>`. No test may reach the network.
  </action>
  <verify>
    <automated>export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && cd /Users/jon/projects/mailglass && bash -n scripts/release_policy_close_out.sh && test -x scripts/release_policy_close_out.sh && mix test test/scripts/release_policy_close_out_test.exs</automated>
  </verify>
  <done>The wrapper is executable and syntax-clean, its test file is green offline, and a failed gate provably leaves the ledger byte-identical (asserted in the test).</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Self-heal the release-please capture control and contract-test the wiring</name>
  <files>.github/workflows/release-please.yml, test/scripts/release_policy_contract_test.exs</files>
  <read_first>
    .github/workflows/release-please.yml lines 540-605 — the `Capture Release Please proposal identity without activation` step: `source_target=$(mktemp)`, `git show "$source_sha":.planning/release-target.json > "$source_target"` (line 544), `target_status=$(jq -er '.status' "$source_target")` (line 556), and the `case "$target_status" in` block spanning lines 558-594 with its `inactive)` (559), `captured|authorized)` (563), `completed)` (585), and `*)` (590) branches. Confirm these line numbers on disk before editing — do not trust them blind.
    test/scripts/release_policy_contract_test.exs lines 1-45 for the `@release_please` / `@publish` path constants and the file-reading assertion style used for workflow contracts.
  </read_first>
  <behavior>
    - The capture control no longer has any status branch that can only fail: a `completed` ledger is no longer an unconditional `result_reason=release_target_completed` dead end, and a post-publication `authorized` ledger is no longer an unconditional `proposal_identity_mismatch`.
    - When close-out succeeds on the temp `$source_target` copy, the control continues down the existing `inactive` capture path against the healed copy and reports a distinct reason (e.g. `release_target_closed_out`) so the strand is visible in the control result rather than silent.
    - When close-out fails its evidence gates, the control still blocks with its existing reason — the self-heal can only turn a block into a pass when Hex proves the release is live.
    - The control never writes `.planning/release-target.json` in the repository working tree or pushes it; the healed ledger exists only in the temp file for that run.
    - `result_status` remains one of the four values the downstream writer accepts (`pass|blocked|cannot-check|pending`), so the `*) status=cannot-check; reason=invalid_capture_result` fallback at line 631 is not triggered by the new reason.
  </behavior>
  <action>
    In the `captured|authorized)` and `completed)` branches of the capture control, before the existing block/mismatch logic, attempt `scripts/release_policy_close_out.sh --target "$source_target" --repo "$GITHUB_WORKSPACE"` (no `--write`) into a temp file. On success, replace `$source_target` with the healed JSON, set `target_status=inactive`, set the reported reason to `release_target_closed_out`, and fall through to the same `capture-candidate` invocation the `inactive)` branch uses — factor that invocation into a shell function rather than duplicating the command line, so the two call sites cannot drift. On failure, leave the existing behaviour exactly as it is today (the `captured|authorized)` identity checks and their `proposal_identity_mismatch`, and a blocked `completed` path). Keep `set -euo pipefail` semantics intact: the close-out attempt must be run so a non-zero exit does not abort the step (`if ! ...; then` / explicit `set +e` around it in the local style).

    Add a contract test to `test/scripts/release_policy_contract_test.exs` asserting on the workflow text that: the capture step invokes `scripts/release_policy_close_out.sh`; it does so without `--write`; the `completed)` branch is no longer an unconditional block; and `release_target_closed_out` appears as a reason. Assert on substrings/regex over the file, matching the existing style in that module.

    Do not modify `.planning/release-target.json`. Do not grant any workflow new `permissions`.
  </action>
  <verify>
    <automated>export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && cd /Users/jon/projects/mailglass && python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/release-please.yml'))" && git diff --quiet -- .planning/release-target.json && mix test test/scripts/release_policy_contract_test.exs test/scripts/workflow_hardening_contract_test.exs test/scripts/release_trigger_recovery_test.exs</automated>
  </verify>
  <done>The workflow still parses as YAML, `.planning/release-target.json` is untouched, and the three workflow-coupled suites are green including the new close-out contract assertions.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Hex API → close-out wrapper | Untrusted remote JSON becomes the checksums recorded as the new baseline evidence. |
| Release Please PR head → capture control | Attacker-influencable branch content reaches a step that now also runs close-out. |
| Ledger file → publish authorization | The ledger is the sole authorizer of a Hex publish; any new writer is a potential authorization forger. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-ldh-01 | Elevation of Privilege | `close_out/3` | critical | mitigate | Status and states are hard-coded to the `inactive`/`unauthorized`/`not_started` triple and the result is re-run through `validate_target/1` before return, so no input can yield an authorizing ledger (Task 1 non-authorizing property test). |
| T-ldh-02 | Spoofing | Hex API response | high | mitigate | Checksums are only accepted from an HTTP 200 release endpoint and are re-verified through the existing hardened `release_policy_hex_release_state.sh`, which rejects retired/malformed releases; no checksum may be supplied by the caller (Task 2). |
| T-ldh-03 | Tampering | release-please capture control | high | mitigate | Self-heal operates on the temp `git show` copy of the *source* (protected base) ledger only, never the PR head's, never writes the repo file, and never pushes; a failed gate preserves the existing block (Task 3). |
| T-ldh-04 | Denial of Service | stranded ledger | high | mitigate | This is the defect being closed: the `completed)` dead-end branch and the post-publication `authorized` mismatch stop failing every run closed once Hex proves the release is live. |
| T-ldh-05 | Repudiation | silent healing | medium | mitigate | The heal reports a distinct `release_target_closed_out` reason into the control result JSON rather than passing silently. |
| T-ldh-SC | Tampering | package installs | low | accept | No npm/pip/cargo or Hex dependency is added by this plan; nothing to audit. |
</threat_model>

<verification>
Run the full coupled gate from the repo root with the toolchain exported:

```
export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27
cd /Users/jon/projects/mailglass
mix format --check-formatted
mix test \
  test/scripts/release_policy_test.exs \
  test/scripts/release_policy_close_out_test.exs \
  test/scripts/release_policy_contract_test.exs \
  test/scripts/reconcile_release_versions_test.exs \
  test/scripts/verify_published_release_test.exs \
  test/scripts/release_trigger_recovery_test.exs \
  test/scripts/workflow_hardening_contract_test.exs \
  test/scripts/linked_release_concurrency_test.exs
git diff --stat -- .planning/release-target.json
```

The last command must print nothing: the ledger file is not touched by this plan.
</verification>

<success_criteria>
- All eight suites above are green; none reaches the network.
- `.planning/release-target.json` is unchanged by the diff.
- No workflow gained new `permissions`.
- The commit uses `fix(release):` or `chore(release):` — never `feat(...)` — since every touched path is inside the core package's `exclude-paths`.
</success_criteria>

<output>
Create `.planning/quick/260916-ldh-add-a-close-out-path-so-a-published-rele/260916-ldh-SUMMARY.md` when done.
</output>
