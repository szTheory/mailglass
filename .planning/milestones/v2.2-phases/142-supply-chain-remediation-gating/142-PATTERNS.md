# Phase 142: Supply-Chain Remediation & Gating - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 13 (5 new, 8 modified)
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/supply_chain/accepted_advisories.ex` | model/utility (data + pure logic) | transform | `lib/mix/tasks/mailglass.publish.check.ex` (the `@accepted_advisories` map + its two parsers + OSV classify) | exact (extraction, not new design) |
| `dev/mix/tasks/mailglass.audit.ex` | controller (Mix task) | batch (subprocess orchestration + parse + gate) | `dev/mix/tasks/mailglass.repo.hygiene.ex` | exact (dev-path task precedent, named in CONTEXT D-01) |
| `test/mailglass/supply_chain/accepted_advisories_test.exs` | test | transform | `test/mailglass/publish/audit_allowlist_test.exs` | exact (same parser/classifier surface, moving) |
| `test/mix/tasks/mailglass_audit_test.exs` | test | batch | `test/mix/tasks/mailglass.repo.hygiene_test.exs` | exact (Mix-task test, IO/subprocess pattern) |
| `lib/mix/tasks/mailglass.publish.check.ex` (modify) | controller (Mix task) | batch | itself (thin-delegation edit) | n/a — edit site |
| `test/mailglass/publish/audit_allowlist_test.exs` (modify) | test | transform | itself | n/a — edit site |
| `.github/workflows/ci.yml` (modify) | config | event-driven | itself | n/a — edit site |
| `test/support/ci_lanes.ex` (modify) | config/registry | CRUD (bucket membership) | itself | n/a — edit site |
| `.github/workflows/publish-hex.yml` (modify) | config | event-driven | itself | n/a — edit site |
| `test/scripts/lane_classification_drift_test.exs` (modify) | test | transform | itself | n/a — edit site |
| `test/scripts/ci_parity_drift_test.exs` (modify) | test | transform | itself | n/a — edit site |
| `mix.exs` (modify) | config | batch | itself | n/a — edit site |
| `MAINTAINING.md` (modify) | docs | n/a | itself | n/a — edit site |

---

## Pattern Assignments

### `lib/mailglass/supply_chain/accepted_advisories.ex` (NEW — data + logic module, `lib/`)

**Analog:** `lib/mix/tasks/mailglass.publish.check.ex` (module header, `@accepted_advisories`, both parsers, OSV classify)

**Boundary declaration** — every `lib/` module in this repo declares this; the new module must too (RESEARCH F5, MEDIUM confidence, verify with `mix compile --warnings-as-errors`):
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1-2
defmodule Mix.Tasks.Mailglass.Publish.Check do
  use Boundary, classify_to: Mailglass
```
Apply the identical declaration to the new module:
```elixir
defmodule Mailglass.SupplyChain.AcceptedAdvisories do
  use Boundary, classify_to: Mailglass
```
Because both this module and the new `dev/` task classify into the same top-level `Mailglass` boundary, no `exports:`/`deps:` list entry is needed for cross-calls (same-boundary calls are unrestricted) — but confirm with an early `mix compile --warnings-as-errors` per F5 rather than assuming.

**Current allowlist shape to migrate (D-02 changes this from `%{id => reason}` to a list with `:id`/`:aliases`/`:package`/`:severity`/`:reason`/`:accepted_on`/`:recheck_by`)**:
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:48-67 (current, pre-extraction)
# Accepted hex.audit advisories — advisory IDs we deliberately allow past the
# Step-13 gate because NO patched version exists in ANY release of the affected
# package (OSV reports the advisory as "introduced <ver>" with no `fixed` event)
# AND the dep is a transitive ecosystem fixture we cannot drop. ...
@accepted_advisories %{
  "EEF-CVE-2026-43966" =>
    "cowlib HTTP Response Splitting (MEDIUM) — no upstream fix as of 2.17.1",
  "EEF-CVE-2026-43969" =>
    "cowlib Cookie Request Header Injection (LOW) — no upstream fix as of 2.17.1"
}
```
D-02 requires `:aliases` to tolerate an empty list (`EEF-CVE-2026-43966` has no GHSA alias; `EEF-CVE-2026-43969`'s is `GHSA-g2wm-735q-3f56`) and matching by `:id` OR any alias.

**Parser 1 to move verbatim (hex.audit output), only the `Enum.reject` matcher changes to be alias-aware**:
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1112-1136
@doc false
def unaccepted_audit_findings(output) do
  lines = String.split(output, "\n")

  retired =
    if Enum.any?(lines, &(&1 =~ ~r/retired/i)) and
         not Enum.any?(lines, &(&1 =~ ~r/No retired packages found/i)) do
      ["retired package(s) present"]
    else
      []
    end

  advisories =
    lines
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\s+(\S+)\s+\S+\s+-\s+(\S+)\s+\(/, line) do
        [_, pkg, id] -> [{pkg, id}]
        _ -> []
      end
    end)
    |> Enum.reject(fn {_pkg, id} -> Map.has_key?(@accepted_advisories, id) end)  # becomes alias-aware lookup
    |> Enum.map(fn {pkg, id} -> "#{pkg} #{id}" end)

  retired ++ advisories
end
```

**Parser 2 to move verbatim (deps.audit output), same alias-aware matcher change** — this is also the site of F2's stale comment that must be rewritten (it currently asserts GHSA/EEF asymmetry is permanent; D-02 closes it for `EEF-CVE-2026-43969`):
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1178-1211
# ... The @accepted_advisories keys are EEF-CVE ids,
# so a GHSA finding is never auto-suppressed today — that asymmetry is intended
# (the accepted cowlib advisories are not present in the mix_audit DB). ...  <- STALE, rewrite
@doc false
def unaccepted_deps_audit_findings(output) do
  lines = String.split(output, "\n")

  {findings, _pkg} =
    Enum.reduce(lines, {[], nil}, fn line, {acc, current_pkg} ->
      cond do
        match = Regex.run(~r/^\s*Name:\s+(\S+)/, line) ->
          [_, pkg] = match
          {acc, pkg}

        match = Regex.run(~r/^\s*URL:.*\/(GHSA-\S+)/, line) ->
          [_, id] = match
          {[{current_pkg, id} | acc], current_pkg}

        true ->
          {acc, current_pkg}
      end
    end)

  findings
  |> Enum.reverse()
  |> Enum.reject(fn {_pkg, id} -> Map.has_key?(@accepted_advisories, id) end)  # becomes alias-aware lookup
  |> Enum.map(fn {pkg, id} -> "#{pkg} #{id}" end)
end
```

**D-10 new checks (no existing analog — genuinely new territory, per RESEARCH "Don't Hand-Roll") — build as deterministic pure functions, stdlib `Date` only**:
```elixir
# No existing Date.compare/~D[...] pattern anywhere in lib/ or dev/ (grepped, zero
# hits per RESEARCH). Use plain stdlib comparison, no new dependency:
Date.compare(Date.utc_today(), recheck_by) == :gt
```
Model `expired_entries/1` and `unused_entries/2` after the existing `check_osv_advisory_staleness/0` / `classify_osv_response/2` split: a pure, unit-testable classify function plus a caller that decides to hard-fail. Brand-voice message convention (see Shared Patterns below) applies to both.

**Error/failure message convention to reuse verbatim style** (`mailglass.publish.check.ex:1094-1099`):
```elixir
fail_step(
  "run hex.audit",
  "Delivery blocked: mix hex.audit reported non-accepted issues for #{ctx.package} " <>
    "(#{Enum.join(unaccepted, ", ")}). A fix is available — bump the dep. Full output:\n#{String.trim(output)}"
)
```
D-10's new messages should read, e.g.:
- `"Delivery blocked: accepted advisory <id>'s recheck_by (<date>) has passed. Re-verify upstream status and update or remove the entry."`
- `"Delivery blocked: allowlist entry <id> matches no current finding — remove it."` (D-10's exact required wording)

---

### `dev/mix/tasks/mailglass.audit.ex` (NEW — dev-path Mix task)

**Analog:** `dev/mix/tasks/mailglass.repo.hygiene.ex` (module shape, `run/1`, arg parsing, exit convention) + `lib/mix/tasks/mailglass.publish.check.ex:982-1104` (per-directory subprocess pattern to reuse, not reinvent — F3)

**Module header + shortdoc/moduledoc/run signature to copy**:
```elixir
# Source: dev/mix/tasks/mailglass.repo.hygiene.ex:1-49
defmodule Mix.Tasks.Mailglass.Repo.Hygiene do
  use Boundary, classify_to: Mailglass
  use Mix.Task

  @shortdoc "Audit Mailglass repo release hygiene"

  @moduledoc since: "1.3.0"
  @moduledoc """
  Audits repository release hygiene before release or milestone work.

  ## Usage

      mix mailglass.repo.hygiene --check
      mix mailglass.repo.hygiene --check --format json
      mix mailglass.repo.hygiene --apply
  ...
  """

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv,
        strict: [check: :boolean, apply: :boolean, format: :string],
        aliases: [c: :check]
      )

    validate_cli!(opts, rest, invalid)
    ...
    emit(result, format)

    if result.status == :blocked do
      exit({:shutdown, 1})
    end
  end
```
Follow the same shape for `mix mailglass.audit`: `use Boundary, classify_to: Mailglass`, `use Mix.Task`, `@shortdoc`, `@moduledoc since: "<next-version>"`, `OptionParser.parse` with `strict:` (research's Open Question #1 recommends a `--kind hex|deps` flag mirroring `mailglass.publish.check`'s own `--package` convention), and `exit({:shutdown, 1})` on any non-accepted finding.

**Validation/`Mix.raise` convention for bad CLI args**:
```elixir
# Source: dev/mix/tasks/mailglass.repo.hygiene.ex:69-80
defp validate_cli!(opts, rest, invalid) do
  if opts[:check] && opts[:apply] do
    Mix.raise("Delivery blocked: choose either --check or --apply, not both.")
  end

  if opts[:format] && opts[:format] not in ["text", "json"] do
    Mix.raise("Delivery blocked: --format must be text or json.")
  end

  if rest != [] do
    Mix.raise("Delivery blocked: unknown args #{Enum.join(rest, " ")}")
  end
```

**Per-directory subprocess pattern — the exact `System.cmd(..., cd: dir)` shape to reuse, not re-derive (F3)**:
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:982-996 (fetch_compile_deps!/2)
defp fetch_compile_deps!(compile_root, ctx) do
  {output, status} =
    System.cmd("mix", ["deps.get"],
      cd: compile_root,
      env: mix_env(ctx),
      stderr_to_stdout: true
    )

  if status != 0 do
    fail_step(
      "compile tarball in isolation",
      "Delivery blocked: mix deps.get failed in the unpacked tarball. #{String.trim(output)}"
    )
  end
end
```
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex:1068-1104 (verify_audit/1) — the
# status-check/parse/filter/aggregate shape the new task's per-directory loop mirrors
defp verify_audit(ctx) do
  audit_root = compile_root(ctx)
  fetch_compile_deps!(audit_root, ctx)

  {output, status} =
    System.cmd("mix", ["hex.audit"], cd: audit_root, env: mix_env(ctx), stderr_to_stdout: true)

  if status != 0 do
    case unaccepted_audit_findings(output) do
      [] -> Map.put(ctx, :audit_output, ...)   # all findings accepted
      unaccepted -> fail_step("run hex.audit", "Delivery blocked: ...")
    end
  else
    Map.put(ctx, :audit_output, output)
  end
end
```
**IMPORTANT per F3:** `mix hex.audit` has NO `--path` flag — it must be invoked with `cd:` (as above) per directory, each needing its own prior `mix deps.get`. `mix deps.audit` (mix_audit) DOES have `--path` (`deps/mix_audit/lib/mix_audit/cli.ex:12`) and can run from root without `cd:` — e.g. `mix deps.audit --path mailglass_admin`. Do not use the same invocation strategy for both; they differ.

The three-directory scan list is a fixed literal (matches `.github/dependabot.yml`'s three `mix` ecosystem entries exactly — do not build a generic scanner):
```elixir
["", "mailglass_admin", "mailglass_inbound"]
```

**Failure-message brand convention** — reuse the exact "Delivery blocked: ... A fix is available — bump the dep." phrasing shown above, aggregating findings across all scanned directories before deciding the task's own exit code.

---

### `test/mailglass/supply_chain/accepted_advisories_test.exs` (NEW)

**Analog:** `test/mailglass/publish/audit_allowlist_test.exs` (full structure to copy/split; async test case pattern, `describe` blocks per function)

```elixir
# Source: test/mailglass/publish/audit_allowlist_test.exs:1-24
defmodule Mailglass.Publish.AuditAllowlistTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Mailglass.Publish.Check

  describe "unaccepted_audit_findings/1" do
    test "returns [] when the only findings are accepted (unfixable cowlib) advisories" do
      output = """
      Found packages with security advisories
      Advisories:
        cowlib 2.17.1 - EEF-CVE-2026-43966 (MEDIUM)
          aka: CVE-2026-43966
          HTTP Response Splitting via Non-VCHAR Bytes
        cowlib 2.17.1 - EEF-CVE-2026-43969 (LOW)
          aka: CVE-2026-43969, GHSA-g2wm-735q-3f56
      """

      assert Check.unaccepted_audit_findings(output) == []
    end
  end
```
For the new test module: `use ExUnit.Case, async: true`, `alias Mailglass.SupplyChain.AcceptedAdvisories`, and move the parser tests wholesale (they now call the new module directly instead of `Check`). Add new `describe "expired_entries/1"` and `describe "unused_entries/2"` blocks per D-10, each with a positive (fires) and negative (doesn't fire) case — anti-vacuity guard pattern below.

**Anti-vacuity guard shape to follow (quote in full) — every parser/classifier needs a negative-control test proving the check actually fires, not just that it compiles**:
```elixir
# Source: test/scripts/lane_classification_drift_test.exs:162-190 (abridged)
test "negative control: removing one entry from the parsed REQUIRED_LANES set " <>
       "makes the drift comparison report it (fail-loud property is tested)" do
  js_source = File.read!(@publish_hex_path)
  required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

  # Sanity: today the two sides agree — drift/2 reports two empty sets.
  assert drift(required_from_js, @required_lanes) == {MapSet.new(), MapSet.new()}

  removed_entry = "Installer Host Smoke"
  assert removed_entry in MapSet.to_list(required_from_js)

  broken_js_set = MapSet.delete(required_from_js, removed_entry)
  {only_in_broken_js_not_registry, only_in_registry_not_broken_js} =
    drift(broken_js_set, @required_lanes)

  assert only_in_registry_not_broken_js == MapSet.new([removed_entry]),
         "a vacuous pass is exactly the failure mode this test excludes: ..."
  assert MapSet.size(only_in_broken_js_not_registry) == 0
end
```
Apply this exact shape to `unused_entries/2`: inject an allowlist entry that matches nothing in synthetic audit output, assert it's reported; and to `expired_entries/1`: inject a past-dated `recheck_by`, assert it's reported, then assert a future-dated one is NOT reported.

**F2's required new positive test** (the existing `audit_allowlist_test.exs:108-126` test is actually a negative-control that a non-matching GHSA id is NOT suppressed — its name is misleading per RESEARCH F2). Add a new test using the REAL alias:
```elixir
# New test needed (no existing analog — this is the gap F2 identifies):
test "suppresses a deps.audit finding whose GHSA id is a registered alias" do
  output = """
  Name: cowlib
  Version: 2.19.0
  URL: https://github.com/advisories/GHSA-g2wm-735q-3f56
  Title: Cookie Request Header Injection

  Vulnerabilities found!
  """

  assert AcceptedAdvisories.unaccepted_deps_audit_findings(output) == []
end
```

---

### `test/mix/tasks/mailglass_audit_test.exs` (NEW)

**Analog:** `test/mix/tasks/mailglass.repo.hygiene_test.exs` (ExUnit case shape, `async: false` for subprocess-touching tests, helper-function structure)

```elixir
# Source: test/mix/tasks/mailglass.repo.hygiene_test.exs:1-31 (abridged)
defmodule Mix.Tasks.Mailglass.Repo.HygieneTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Mailglass.Repo.Hygiene

  test "reports a clean repo with release workflow readiness as pass" do
    repo = git_repo!()
    write_release_workflows!(repo)
    commit_all!(repo, "initial")

    result = Hygiene.audit(repo)

    assert result.status == :pass
    assert check(result, :git_state).status == :pass
  end

  test "blocks on dirty local state" do
    repo = git_repo!()
    ...
    result = Hygiene.audit(repo)

    assert result.status == :blocked
    ...
  end
```
Note the pattern: the task exposes a pure(ish) `audit/1`-style public function separate from `run/1`'s CLI/exit wrapper, so tests call the function directly rather than shelling out and capturing IO — prefer this over `ExUnit.CaptureIO` where possible, matching this precedent. `test/mix/tasks/` is auto-included by `verify.mix_tasks` (`mix.exs`, run inside `mix_task_tests`/`ci.yml`) — no new wiring is needed for this file to run in CI (RESEARCH, Wave 0 Gaps).

**D-15's required deterministic unit tests** (exit non-zero on synthetic HIGH-with-fix output, exit zero on cowlib-only output) belong in this file, testing the task's own aggregation/exit-decision function against synthetic multi-directory output — mirror the `case unaccepted_audit_findings(output) do [] -> ...; unaccepted -> fail_step(...) end` branch shape from `verify_audit/1` shown above.

---

### `lib/mix/tasks/mailglass.publish.check.ex` (MODIFY — thin delegation)

**Analog:** none needed — RESEARCH already specifies the exact target shape (Pattern 1, "Thin-delegation preserves the existing public test surface"):
```elixir
# Target shape after D-01 extraction
@doc false
def unaccepted_audit_findings(output),
  do: Mailglass.SupplyChain.AcceptedAdvisories.unaccepted_audit_findings(output)

@doc false
def unaccepted_deps_audit_findings(output),
  do: Mailglass.SupplyChain.AcceptedAdvisories.unaccepted_deps_audit_findings(output)
```
`@accepted_advisories` (currently at `:62`) is deleted entirely; all `Map.values(@accepted_advisories) |> Enum.join("; ")` call sites (`:1084`, `:1156`) and `check_osv_advisory_staleness/0`'s `Map.keys(@accepted_advisories)` (`:1219`) must be repointed at the new module's accessor. The stale comment at `:1179-1186` must be rewritten per F2 (see module section above).

---

### `.github/workflows/ci.yml` (MODIFY — Wave 1 rewiring + Wave 2 promotion)

**Analog:** the job itself, current shape to edit (Wave 1 target: both steps call `mix mailglass.audit --kind <hex|deps>` instead of bare `mix hex.audit`/`mix deps.audit`):
```yaml
# Source: .github/workflows/ci.yml:545-568 (hex_audit, current)
  hex_audit:
    name: Hex Audit (Elixir 1.18 / OTP 27)
    runs-on: ubuntu-latest
    needs: [changes]
    if: needs.changes.outputs.code == 'true'
    steps:
      - name: Checkout
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0
      - name: Set up OTP + Elixir
        uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict
      - name: Cache deps
        uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
        with:
          path: deps
          key: mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-
      - name: Install deps
        run: mix deps.get
      - name: Run Hex audit
        run: mix hex.audit
```
Replace the final `run: mix hex.audit` step with `run: mix mailglass.audit --kind hex` (naming per Claude's Discretion, D-01/Open Question #1). Same for `deps_audit_advisory` (`:570-601`), `run: mix deps.audit` → `run: mix mailglass.audit --kind deps`.

**`continue-on-error: true` + stale comment to delete (Wave 2, D-07/D-09) — verbatim current text**:
```yaml
# Source: .github/workflows/ci.yml:570-581
  deps_audit_advisory:
    name: Deps Audit Advisory (Elixir 1.18 / OTP 27)
    runs-on: ubuntu-latest
    needs: [changes]
    if: needs.changes.outputs.code == 'true'
    # Advisory-only: mix deps.audit surfaces transitive-dep advisories from the
    # elixir-security-advisories DB. Under an unfixable CVE wave it will red, so
    # continue-on-error keeps it non-blocking on PRs. The publish gate
    # (mailglass.publish.check Step 14) is where a non-allowlisted advisory
    # actually hard-blocks delivery. The "Advisory (" naming convention is what
    # publish-hex.yml gate-ci-green's isAdvisory() matches to skip it (SUPPLY-01).
    continue-on-error: true
```
The comment's `isAdvisory()` claim is false today (Phase 141 removed it) — delete the whole 6-line comment block, and delete `continue-on-error: true` (D-07: mandatory for `ci_green`'s shell-loop `needs.*.result` to see real failure).

**`ci_green`'s `needs:` list and result-check loop — both must change together (D-05 site 1)**:
```yaml
# Source: .github/workflows/ci.yml:1146-1165 (current)
  ci_green:
    name: CI Green
    runs-on: ubuntu-latest
    if: always()
    needs:
      - compile_no_optional_deps
      - installer_host_smoke
      - support_contract_core
      - support_contract_admin
      - trust_lane_repo_head
    steps:
      - name: Evaluate required lane results
        run: |
          FAILED_LANES=""
          for job_result in \
            "compile_no_optional_deps=${{ needs.compile_no_optional_deps.result }}" \
            "installer_host_smoke=${{ needs.installer_host_smoke.result }}" \
            "support_contract_core=${{ needs.support_contract_core.result }}" \
            "support_contract_admin=${{ needs.support_contract_admin.result }}" \
            "trust_lane_repo_head=${{ needs.trust_lane_repo_head.result }}"
          do
```
Add `hex_audit` and `deps_audit_advisory` to both the YAML `needs:` list and the shell heredoc's `job_result` list, in the same commit.

---

### `test/support/ci_lanes.ex` (MODIFY — Wave 2, D-05 sites 4a-4d)

**Analog:** the file's own current bucket contents (already read in full above) — this is a registry edit, not a new pattern. Add `"Hex Audit (Elixir 1.18 / OTP 27)"` and `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` to `@required_lanes` (`:80-86`); remove `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` from `@advisory_lanes_ci` (`:89-100`, keeping `"Hex Audit..."` there since it stays `mix ci`-reproduced) and from `@advisory_classified_lanes` (`:111-116`); remove `"Hex Audit (Elixir 1.18 / OTP 27)"` from `@publish_gating_lanes` (`:120-134`) since it is now required, not merely publish-gating.

Exact current bucket text (verbatim, for the diff):
```elixir
@required_lanes [
  "Support Contract Core (Elixir 1.18 / OTP 27)",
  "Support Contract Admin (Elixir 1.18 / OTP 27)",
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
  "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
  "Installer Host Smoke"
]

@advisory_lanes_ci [
  "Format Check (Elixir 1.18 / OTP 27)",
  "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
  "Credo Strict (Elixir 1.18 / OTP 27)",
  "Dialyzer (Elixir 1.18 / OTP 27)",
  "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
  "Hex Audit (Elixir 1.18 / OTP 27)",
  "Deps Audit Advisory (Elixir 1.18 / OTP 27)",
  "Mix Task Tests (Elixir 1.18 / OTP 27)",
  "Inbound Test (Elixir 1.18 / OTP 27)",
  "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)"
]

@advisory_classified_lanes [
  "Deps Audit Advisory (Elixir 1.18 / OTP 27)",
  "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)",
  "Demo Browser Evidence (Docker Compose / Chromium)",
  "Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)"
]

@publish_gating_lanes [
  "Format Check (Elixir 1.18 / OTP 27)",
  "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
  "Mix Task Tests (Elixir 1.18 / OTP 27)",
  "Inbound Test (Elixir 1.18 / OTP 27)",
  "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)",
  "Credo Strict (Elixir 1.18 / OTP 27)",
  "Design System Conformance (shell gates)",
  "Dialyzer (Elixir 1.18 / OTP 27)",
  "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
  "Hex Audit (Elixir 1.18 / OTP 27)",
  "Installer Golden Gate (Elixir 1.18 / OTP 27)",
  "Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)",
  "Branch Protection Advisory"
]
```

---

### `.github/workflows/publish-hex.yml`, `test/scripts/lane_classification_drift_test.exs`, `test/scripts/ci_parity_drift_test.exs`, `mix.exs`, `MAINTAINING.md`

No new pattern needed — these are the D-05/D-06 mechanical registry-parity edits, and CONTEXT.md's line citations were independently re-verified by the phase researcher as exact (RESEARCH §Verification, zero drift). Use CONTEXT.md's D-05 nine-site list and D-06 blast-radius list directly as the edit checklist; the `MAINTAINING.md` row text to flip (verified verbatim) is:
```
| `deps_audit_advisory` | `Deps Audit Advisory (Elixir 1.18 / OTP 27)` | advisory | promote | Recorded recommendation only; Phase 142/VULN-03 executes the promotion to merge-gating, not this phase (D-07). |
...
| `hex_audit` | `Hex Audit (Elixir 1.18 / OTP 27)` | publish-gating | promote | Recorded recommendation only; Phase 142/VULN-03 executes the promotion to merge-gating, not this phase (D-07). |
```
→ classification becomes `required`, disposition becomes `keep-with-reason`, reason text updated to describe why (e.g. "Promoted from advisory/publish-gating; the shared allowlist (Phase 142/VULN-05) makes the lane trustworthy enough to merge-gate.").

**F1's `mix.exs` `:ci` alias edit (recommended, not locked) — current audit steps to replace**:
```elixir
# Source: mix.exs:395-396 (inside the :ci alias step list)
"hex.audit",
"deps.audit",
```
RESEARCH F1 recommends replacing both with a single `"mailglass.audit"` step (or a `--kind`-parameterized pair) so `mix ci` reproduces the CI-side three-directory, allowlist-filtered scan — and updating the two `ci_parity_drift_test.exs` matcher entries (`:113-114`, MapSet at `:187-188`) from `"hex.audit"`/`"deps.audit"` substrings to `"mailglass.audit"` in the same commit, to avoid F1's "test stays green while the parity claim silently narrows" trap.

**`test/support/ci_lanes.ex` docstring precedent for "why NOT to add a lane to `@advisory_lanes_ci`"** (useful boilerplate to imitate if `mailglass.audit`'s local step needs a similar caveat comment):
```elixir
# Source: test/support/ci_lanes.ex:69-74
# `mailglass_admin/scripts/check-conformance-advisory.sh`, so this lane has no
# local-parity step. It must NOT be added to `@advisory_lanes_ci` — doing so would
# make `ci_parity_drift_test.exs` (MIXCI-03) claim a local-parity guarantee `mix ci`
# does not provide.
```

---

## Shared Patterns

### Brand-voice failure messages
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:1094-1099`
**Apply to:** `dev/mix/tasks/mailglass.audit.ex`, `lib/mailglass/supply_chain/accepted_advisories.ex` (D-10 expiry/unused-entry messages)
```elixir
"Delivery blocked: mix hex.audit reported non-accepted issues for #{ctx.package} " <>
  "(#{Enum.join(unaccepted, ", ")}). A fix is available — bump the dep. Full output:\n#{String.trim(output)}"
```
Every gate message begins `"Delivery blocked: "` and names the concrete fix. D-10 dictates the exact unused-entry wording: `"allowlist entry X matches no current finding — remove it."`

### Fail-open on network, fail-closed on data
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:1244-1295` (`osv_get/1`, `classify_osv_response/2`, `verify_osv_freshness/1`)
**Apply to:** any optional OSV `{:fixed, ...}` warn enrichment the plan chooses to ship (D-10 marks this fully optional)
```elixir
def osv_get(url) do
  :httpc.request(:get, {String.to_charlist(url), []},
    [{:timeout, 5_000}, {:connect_timeout, 5_000}], body_format: :binary)
  |> case do
    {:ok, {{_http, 200, _reason}, _headers, body}} -> {:ok, to_string(body)}
    {:ok, {{_http, status, _reason}, _headers, _body}} -> {:error, {:http_status, status}}
    {:error, reason} -> {:error, reason}
  end
rescue
  _ -> {:error, :exception}
catch
  :exit, reason -> {:error, {:exit, reason}}
end
```
Never raises, never blocks on a network error. Contrast with D-10's two NEW checks (`recheck_by` expiry, unused-entry), which ARE local/deterministic and MUST hard-block — the OSV boundary is the one place fail-open is correct; local data checks are fail-closed by design.

### Anti-vacuity guard (negative-control test) on every parser/classifier
**Source:** `test/scripts/lane_classification_drift_test.exs:162-190` (quoted in full above under the new unit-test section)
**Apply to:** `test/mailglass/supply_chain/accepted_advisories_test.exs` (`expired_entries/1`, `unused_entries/2`, and the alias-matching parsers), `test/mix/tasks/mailglass_audit_test.exs` (D-15's synthetic HIGH-with-fix vs. cowlib-only cases)

### Per-directory subprocess invocation
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:982-996` (`fetch_compile_deps!/2`) and `:1068-1104` (`verify_audit/1`)
**Apply to:** `dev/mix/tasks/mailglass.audit.ex` — `System.cmd(cmd, args, cd: dir, ...)` for `hex.audit` (needs `cd:`, no `--path`); `System.cmd("mix", ["deps.audit", "--path", dir], ...)` from root for `deps.audit` (F3 — the two mechanisms differ, do not unify them into one invocation style)

### `use Boundary, classify_to: Mailglass` on every `lib/` module
**Source:** `lib/mix/tasks/mailglass.publish.check.ex:1-2` (one of 15+ files with this exact declaration, per RESEARCH F5)
**Apply to:** `lib/mailglass/supply_chain/accepted_advisories.ex` — mandatory, not optional, even though the module is "just data" (F5 pitfall #5 explicitly warns against skipping this)

---

## No Analog Found

None. Every file in this phase's scope has a direct, load-bearing analog already identified above (the phase researcher's own conclusion: "the work is extraction and per-directory looping, not new mechanism design" — RESEARCH "Don't Hand-Roll" §Key insight). The one genuinely novel code (D-10's `Date`-based expiry comparison) is a one-line stdlib call, not infrastructure requiring its own analog.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `dev/mix/tasks/`, `test/mailglass/publish/`, `test/mix/tasks/`, `test/scripts/`, `.github/workflows/`, `test/support/ci_lanes.ex`, `mix.exs`, `MAINTAINING.md`
**Files scanned:** 13 read directly (full or targeted ranges) in this session, plus CONTEXT.md/RESEARCH.md's own prior full reads of the same set (cross-checked, zero drift found on any cited line)
**Pattern extraction date:** 2026-07-28
