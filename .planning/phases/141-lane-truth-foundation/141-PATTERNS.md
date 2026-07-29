# Phase 141: Lane Truth Foundation - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 11 (3 create, 8 modify)
**Analogs found:** 11 / 11

All excerpts below are verbatim from the worktree at
`/Users/jon/projects/mailglass/.claude/worktrees/fix-release-gates`. Line ranges are as-read today
and will shift once the phase's own edits land — cite behavior, not line numbers, in the plan.

## File Classification

| New/Modified File | Op | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `test/support/ci_lanes.ex` | MODIFY | test-support registry (config/data module) | static lookup | itself (`test/support/ci_lanes.ex:51-105`) | self |
| `test/support/ci_yaml.ex` | CREATE | test-support utility (parser) | file-I/O → transform | `test/support/ci_lanes.ex` (style) + `required_checks_test.exs:220-242` (algorithm) | exact (split across two) |
| `test/scripts/lane_classification_drift_test.exs` | CREATE | meta-test | file-I/O → set comparison | `test/scripts/required_checks_test.exs` | exact |
| `test/scripts/ci_parity_drift_test.exs` | MODIFY | meta-test | file-I/O → set comparison | itself (`:153-203`) | self |
| `.github/workflows/ci.yml` (job split) | MODIFY | CI config | batch/job graph | `ci.yml:394-433` (`credo_strict`), `ci.yml:1079-1082` (BEAM-free job shape) | exact |
| `.github/workflows/ci.yml` (`mix_task_tests` step) | MODIFY | CI config | batch | `ci.yml:280-284` (existing `verify.mix_tasks` step) | exact |
| `.github/workflows/publish-hex.yml` | MODIFY | CI config (gate script) | request-response (GitHub REST) | `publish-hex.yml:190-291` (itself) | self |
| `mix.exs` | MODIFY | build config | static | `mix.exs:286-288` + `mix.exs:68` | exact |
| `MAINTAINING.md` | MODIFY | docs | static | `MAINTAINING.md:132-200` (itself) + `.planning/RATCHET-GAP-REGISTER.md:105-112` (table style) | role-match |
| `CONTRIBUTING.md` | MODIFY | docs | static | `MAINTAINING.md:152-158` (the true required set) | role-match |
| `.planning/REQUIREMENTS.md` | MODIFY | planning artifact | static | `REQUIREMENTS.md:98-102` (itself) | self |
| `.planning/TOOLING-DEFECTS.md` | CREATE | planning register | static | `.planning/RATCHET-GAP-REGISTER.md:1-31` + `.planning/research/v1.14/DEFECT-REGISTER.md:1-10` | role-match |

---

## Pattern Assignments

### `test/support/ci_yaml.ex` (CREATE — test-support utility, file-I/O → transform)

**Style analog:** `test/support/ci_lanes.ex`
**Algorithm analog:** `test/scripts/required_checks_test.exs:220-242` (the `defp` to lift)

**Module shape to copy** (`test/support/ci_lanes.ex:1-3`, `:78-105`) — plain `defmodule`, long
`@moduledoc` that names its consumers and the requirement IDs, then one `@doc` + `@spec` + one-line
`def` per public function:

```elixir
defmodule Mailglass.CILanes do
  @moduledoc """
  The single Elixir-side source of truth for CI lane identity (MIXCI-03, D-LD-10).
  ...
  """

  @doc """
  The five required branch-protection leaf display names, VERBATIM as they appear as
  `name:` in `.github/workflows/ci.yml`.
  """
  @spec required_lanes() :: [String.t()]
  def required_lanes, do: @required_lanes
```

**Parser to lift verbatim** (`test/scripts/required_checks_test.exs:219-242`) — becomes
`Mailglass.CIYaml.job_names/1`. Note the `defp` → `def` change and that the accumulator carries the
current job key:

```elixir
  # Returns a map of job_key => display_name for every job defined in ci.yml.
  defp parse_ci_job_names(source) do
    lines = String.split(source, "\n")

    {result, _current_key} =
      Enum.reduce(lines, {%{}, nil}, fn line, {acc, current_key} ->
        cond do
          # Top-level job key (2-space indent, identifier, colon, no trailing content)
          Regex.match?(~r/^  ([a-z_]+):$/, line) ->
            [[_, key]] = Regex.scan(~r/^  ([a-z_]+):$/, line)
            {acc, key}

          # name: line immediately inside a job (4-space indent)
          current_key != nil and Regex.match?(~r/^    name: (.+)$/, line) ->
            [[_, name]] = Regex.scan(~r/^    name: (.+)$/, line)
            {Map.put(acc, current_key, String.trim(name)), current_key}

          true ->
            {acc, current_key}
        end
      end)

    result
  end
```

**`matrix_job_names/1` (RESEARCH F1 assertion 5) has no exact analog.** The closest structural sibling
is `parse_ci_job_ifs/1` (`required_checks_test.exs:244-267`), which is the *same* reduce skeleton with
one regex swapped:

```elixir
          # if: line at job level (4-space indent)
          current_key != nil and Regex.match?(~r/^    if: (.+)$/, line) ->
            [[_, if_expr]] = Regex.scan(~r/^    if: (.+)$/, line)
            {Map.put(acc, current_key, String.trim(if_expr)), current_key}
```

Copy that shape with `~r/^    strategy:$/` as the trigger and a `MapSet.put(acc, current_key)` body.

**Do NOT refactor `required_checks_test.exs` to delegate** (RESEARCH §Parser reuse). The `defp`s stay
duplicated; that is accepted debt.

---

### `test/scripts/lane_classification_drift_test.exs` (CREATE — meta-test, file-I/O → set comparison)

**Primary analog:** `test/scripts/required_checks_test.exs`
**Secondary analog:** `test/scripts/conformance_advisory_test.exs` (the `@repo_root` path idiom)

**Module header** (`required_checks_test.exs:1-19`) — note `use ExUnit.Case, async: true` with **no
`@moduletag` and no tags at all**, and the compile-time registry read:

```elixir
defmodule Mailglass.Scripts.RequiredChecksTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  ...
  # The canonical set of required leaf display names that ci_green.needs must cover.
  # Read from the single Elixir-side source (Mailglass.CILanes, test/support/ci_lanes.ex)
  # so the required-lane identity is defined once and shared with the MIXCI-03
  # parity-drift test (D-LD-10). test/support is in elixirc_paths(:test), so the module
  # is compiled before this test and is available at module-attribute (compile) time.
  @required_leaf_names MapSet.new(Mailglass.CILanes.required_lanes())
```

**Preferred path idiom** (`conformance_advisory_test.exs:4-6`) — the newer of the two forms; use this
one, the new test has 4+ paths:

```elixir
  @repo_root Path.expand("../..", __DIR__)
  @script_path Path.join(@repo_root, "mailglass_admin/scripts/check-conformance-advisory.sh")
  @ci_path Path.join(@repo_root, ".github/workflows/ci.yml")
```

**Anti-vacuity guard idiom — reuse this, do not invent one** (`required_checks_test.exs:27-34`):

```elixir
    # Guard against a vacuous pass: if the script's structure changes so a parser
    # returns nothing, both sets would be empty and the difference check below
    # would pass while detecting no drift at all.
    assert MapSet.size(array_set) > 0,
           "parsed no REQUIRED_CHECKS entries — parser or script format changed"

    assert MapSet.size(bullet_set) > 0,
           "parsed no print_expected_text bullets — parser or script format changed"
```

Second instance, for map-returning parsers (`required_checks_test.exs:102-107`):

```elixir
    # Anti-vacuity guards for the new parsers.
    assert MapSet.size(needs_keys) > 0,
           "parse_ci_green_needs returned empty — ci.yml format changed or ci_green job missing"

    assert map_size(job_names) > 0,
           "parse_ci_job_names returned empty — ci.yml format changed or no jobs found"
```

Third instance, the *bijection*-style guard against a stale hardcoded set
(`ci_parity_drift_test.exs:175-202`) — this is the closest analog for "the JS arrays must not name a
lane the registry does not know":

```elixir
    # ...and no matcher may reference a lane absent from ci_lanes (no stale matcher).
    known = MapSet.new(lanes)

    matcher_lanes =
      MapSet.new([
        ...
      ])

    stale = MapSet.difference(matcher_lanes, known)

    assert MapSet.size(stale) == 0,
           "matcher table references lanes not in Mailglass.CILanes (stale matcher — " <>
             "a lane was renamed/removed in ci_lanes but not here): #{inspect(MapSet.to_list(stale))}"
```

**Drift idiom — two `MapSet.difference/2` calls, one assert naming both directions**
(`required_checks_test.exs:36-42`, repeated at `:116-125`, `:51-57`):

```elixir
    only_in_array = MapSet.difference(array_set, bullet_set)
    only_in_bullets = MapSet.difference(bullet_set, array_set)

    assert MapSet.size(only_in_array) == 0 and MapSet.size(only_in_bullets) == 0,
           "REQUIRED_CHECKS and print_expected_text heredoc have drifted:\n" <>
             "  In array but missing from heredoc: #{inspect(MapSet.to_list(only_in_array))}\n" <>
             "  In heredoc but missing from array: #{inspect(MapSet.to_list(only_in_bullets))}"
```

**Text-array parser idiom** (`required_checks_test.exs:159-166`) — the exact technique the
`publish-hex.yml` JS-array parser copies (split on a unique token, `Regex.scan` for quoted strings,
`MapSet.new`). Note this one crashes on a non-match (`[_before, rest] =`); RESEARCH's recommended JS
version uses a `case` with an empty-set fallback so the anti-vacuity assert fires instead:

```elixir
  defp parse_required_checks(source) do
    [_before, rest] = String.split(source, "REQUIRED_CHECKS=(\n", parts: 2)
    [chunk | _] = String.split(rest, "\n)", parts: 2)

    Regex.scan(~r/"([^"]+)"/, chunk)
    |> Enum.map(fn [_full, name] -> name end)
    |> MapSet.new()
  end
```

**Section banner** (`required_checks_test.exs:155-157`):

```elixir
  # ---------------------------------------------------------------------------
  # Parsers
  # ---------------------------------------------------------------------------
```

**Negative-control test idiom** (criterion 1b) — `ci_parity_drift_test.exs:205-221`:

```elixir
  test "negative control: removing the installer-smoke step makes its lane report uncovered (fail-loud property is tested)" do
    lane = "Installer Host Smoke"

    # Sanity: the lane is a real ci_lanes required lane and IS covered today.
    assert lane in Mailglass.CILanes.required_lanes()
    assert uncovered_lanes(union_steps(), [lane]) == []

    # Construct a copy of the step-set with the installer-smoke step removed and
    # confirm the coverage function now reports the lane uncovered. This proves the
    # gate fails loud on drift rather than rotting into a vacuous pass.
    broken_steps =
      Enum.reject(union_steps(), &String.contains?(&1, "consumer_install_smoke.sh"))

    assert uncovered_lanes(broken_steps, [lane]) == [lane],
           "coverage function did not report '#{lane}' uncovered after removing its " <>
             "covering step — the fail-loud property is broken"
  end
```

**Long-`@moduledoc`-on-a-meta-test precedent** (`ci_parity_drift_test.exs:1-29`) — it states the
requirement ID, what is asserted by identity, the anti-vacuity contract, and "the lane list is read
from `Mailglass.CILanes` — it is NOT duplicated here." The new test's `@moduledoc` should mirror this,
and must state the F1 name-space seam (YAML `name:` vs runtime matrix-suffixed name).

---

### `test/support/ci_lanes.ex` (MODIFY — add third/fourth classification axis)

**Analog: itself.** Existing conventions to match exactly:

Attribute + trailing comment (`:59-71`):

```elixir
  # Hygiene lanes `mix ci` reproduces (verbatim ci.yml name:).
  @advisory_lanes_ci [
    "Format Check (Elixir 1.18 / OTP 27)",
    ...
  ]
```

Accessor (`:85-93`) — `@doc` heredoc, `@spec`, single-line `def`:

```elixir
  @doc """
  The advisory lane display names the `mix ci` ∪ `mix ci.browser` parity claim covers,
  VERBATIM as they appear as `name:` in `.github/workflows/ci.yml`.

  Cron-only/live canaries and Docker demo-evidence lanes are intentionally excluded —
  see the module doc for the per-lane rationale.
  """
  @spec advisory_lanes() :: [String.t()]
  def advisory_lanes, do: @advisory_lanes_ci ++ @advisory_lanes_browser
```

Moduledoc section-heading style to copy for the new "Two independent axes" section (`:19-27`, `:29-33`):

```elixir
  ## Why the YAML/script copies are NOT hoisted away
  ...
  ## Intentional exclusions from the parity claim

  `mix ci` deliberately does NOT reproduce the following CI lanes, so they are absent
  from `advisory_lanes/0` (rationale: DX-MIX-CI.md section E footgun #4 and #6):

    * `Demo Browser Evidence (Docker Compose / Chromium)` — Docker-compose demo
```

The bullet form (`` * `Name (...)` — rationale ``) is where the new `Design System Conformance`
exclusion entry goes per D-12.

**Citation to fix (F8)** — `ci_lanes.ex:15-17`:

```elixir
  All names here are VERBATIM the `name:` fields in `.github/workflows/ci.yml`. The
  authoritative required-vs-advisory split lives in `MAINTAINING.md` (lines 152-191);
  the parity-contract intent is in `.planning/research/milestone-cicd/DX-MIX-CI.md`.
```

---

### `test/scripts/ci_parity_drift_test.exs` (MODIFY — delete dead assertion)

Exact excision target (`:159-162`), keeping `:156-157` and `:164-165`:

```elixir
    assert steps != [],
           "flattened mix ci ∪ ci.browser step-set is empty — alias parse returned nothing"

    lanes = all_lanes()

    assert lanes != [],
           "Mailglass.CILanes required + advisory lanes parsed empty — ci_lanes source changed"

    assert length(Mailglass.CILanes.required_lanes()) == 5,
           "expected exactly 5 required lanes from Mailglass.CILanes"
```

`lanes` is still used at `:168` (`Enum.reject(lanes, ...)`) and `:176` (`MapSet.new(lanes)`), so the
binding `lanes = all_lanes()` at `:159` must stay — only the `assert lanes != []` (`:161-162`) is
removed. Also update the `@moduledoc` claim at `:15-16` ("if the `Mailglass.CILanes` source is empty")
so the doc does not describe a guard that no longer exists.

---

### `.github/workflows/ci.yml` — `credo_strict` split (MODIFY)

**Complete current job, verbatim (`ci.yml:394-433`):**

```yaml
  credo_strict:
    name: Credo Strict (Elixir 1.18 / OTP 27)
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
      - name: Verify suppression docs (shell gate)
        # Fails CI if any {Credo.Check..., false} entry is missing
        # a `# Reason:` + `# Tracking:` comment block (D-08-18/D-08-19).
        run: bash scripts/check_credo_suppressions.sh
      - name: Verify motion conformance (shell gate)
        # Fails CI if any banned layout-thrashing or easing token appears
        # in lib/ or app.css per UI-SPEC Motion Rules (Phase 74 FROZEN contract, GAP-19 sev 3).
        run: bash scripts/check_motion_conformance.sh
      - name: Verify design-system conformance (shell gate — hard-fail arms)
        # Wires the previously-DEAD check-conformance.sh (D-06, RATCHET-03).
        # Five hard-closed gates: BADGE / TYPE-base / BOLD / GAP / HEX.
        # Script is BASH_SOURCE-anchored — cwd-independent, run from repo root.
        run: bash mailglass_admin/scripts/check-conformance.sh
      - name: Verify design-system conformance (advisory arms — TYPE-lg/xl + TRACK)
        # Phase 99 hard-fail gate for large type-scale and arbitrary tracking regressions.
        run: bash mailglass_admin/scripts/check-conformance-advisory.sh
      - name: Run Credo strict
        run: mix credo --strict
```

There is **no `strategy:`, no `services:`, no `env:`** on this job. Steps 3 (motion), 4 (hard-fail
arms), 5 (advisory arms) move to `conformance_gates` **with their comment blocks intact** — the
`conformance_advisory_test.exs:77-82` step-block parser keys on the literal step name
`- name: Verify design-system conformance (advisory arms`, so that step's `name:` string must survive
the move byte-for-byte.

**Analog for a BEAM-free, non-matrix job inside `ci.yml`** — `branch_protection_advisory`
(`ci.yml:1079-1082`). This is the only `ci.yml` job with no `setup-beam`; it is the shape
`conformance_gates` copies (job key, `name:`, `runs-on:`, straight to `steps:`):

```yaml
  branch_protection_advisory:
    name: Branch Protection Advisory
    runs-on: ubuntu-latest
    steps:
      - name: Check for BRANCH_PROTECTION_PAT secret
```

Note it omits `needs: [changes]` / `if:` — `conformance_gates` should **not** copy that omission; per
RESEARCH F4 it keeps `needs: [changes]` + `if: needs.changes.outputs.code == 'true'` from
`credo_strict`. Whole-workflow BEAM-free precedents (for `actions/checkout`-only jobs) exist in
`.github/workflows/actionlint.yml`, `pr-title.yml`, `guard-release-trigger.yml`, `gate-self-test.yml`,
`branch-protection-drift.yml`.

---

### `.github/workflows/ci.yml` — `mix_task_tests` step addition (MODIFY)

**Analog: the job's own last step (`ci.yml:280-284`)** — comment explains *why the scope is what it
is*, then a bare `mix verify.*` call:

```yaml
      - name: Run mix-task / generator tests
        # Directory-scoped (test/mix/tasks/) so newly-added task tests can't
        # silently escape CI — closes the drift gap that left the Phase-47
        # inbound generators advisory-only. See the verify.mix_tasks alias note.
        run: mix verify.mix_tasks
```

The job already provides everything the new step needs — `services.postgres` (`ci.yml:235-248`),
`env: MIX_ENV: test` (`:249-253`), and the DB-create step (`:271-279`):

```yaml
      - name: Wait for postgres + create test DB
        # The core test_helper.exs boots Mailglass.TestRepo (runs migrations),
        # so even though the mix.gen.* generator tests run in-memory via
        # Igniter.Test and never touch the DB, the test run requires the DB.
        env:
          PGPASSWORD: postgres
        run: |
          until pg_isready -h localhost -U postgres; do sleep 1; done
          mix ecto.create -r Mailglass.TestRepo --quiet
```

---

### `.github/workflows/publish-hex.yml` — `gate-ci-green` rewrite (MODIFY)

**Analog: itself.** `actions/github-script` step scaffolding (`publish-hex.yml:190-193`):

```yaml
      - name: Verify CI is green on tagged SHA
        uses: actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3  # v9.0.0
        with:
          script: |
```

**Array-declaration + comment style to mirror for the two new arrays** (`:194-210`) — the comment
names the cross-language contract and the meta-test that enforces it:

```js
            // Required lanes: each must be present in the run's jobs AND have
            // conclusion === 'success'. A skipped, missing, failed, or cancelled
            // required lane BLOCKS publish (GATE-02, per LD-6).
            //
            // NOTE: this set must stay identical to ci_green.needs in ci.yml.
            // The canonical Elixir-side source is Mailglass.CILanes
            // (test/support/ci_lanes.ex); its required_lanes/0 is verified against
            // ci_green.needs by the GATE-03 meta-test (LD-10 shared ci_lanes seam,
            // hoisted in Phase 128 MIXCI-03). This YAML copy remains the CI-side
            // declaration that the meta-test checks — kept in lockstep, not deleted.
            const REQUIRED_LANES = [
              'Support Contract Core (Elixir 1.18 / OTP 27)',
              'Support Contract Admin (Elixir 1.18 / OTP 27)',
              'Compile No Optional Deps (Elixir 1.18 / OTP 27)',
              'Trust Lane Repo Head (Elixir 1.18 / OTP 27)',
              'Installer Host Smoke'
            ];
```

**Blocks being replaced.** The `ADVISORY_LANES` comment + array (`:212-223`) — its prose ("every other
advisory lane follows the `<name> Advisory (...)` convention") is exactly the convention D-04 deletes:

```js
            // Advisory lanes are non-blocking for publish — they are NOT
            // branch-protection required checks. "Operator Browser Gate" and
            // "Demo Browser Evidence" predate the naming convention and are
            // listed explicitly; every other advisory lane follows the
            // "<name> Advisory (...)" convention and is matched by isAdvisory()
            // below — so a red advisory lane never blocks a release.
            // Rule of thumb: if a lane is not required by branch protection,
            // it is advisory here too.
            const ADVISORY_LANES = [
              'Operator Browser Gate',
              'Demo Browser Evidence'
            ];
```

The classification predicate and the fall-through blocking branch (`:267-291`) — this is the whole
"hidden third tier" mechanism, replaced by `classify/1`:

```js
            const isAdvisory = (jobName) =>
              ADVISORY_LANES.some(lane => jobName.startsWith(lane)) ||
              / Advisory \(/.test(jobName);

            // Non-required, non-advisory failures still block (e.g. unexpected
            // new lanes that are neither in REQUIRED_LANES nor advisory).
            const blockingFailures = jobs
              .filter(j => j.conclusion !== 'success' && j.conclusion !== 'skipped')
              .filter(j => !isAdvisory(j.name))
              .filter(j => !REQUIRED_LANES.includes(j.name));

            if (blockingFailures.length > 0) {
              const detail = blockingFailures.map(j => `  - ${j.name} (${j.conclusion})`).join('\n');
              core.setFailed(`Delivery blocked: ci.yml on SHA ${sha} has non-advisory failures.\n${detail}\nRun: ${latest.html_url}`);
              return;
            }

            const advisoryFailures = jobs
              .filter(j => j.conclusion !== 'success' && j.conclusion !== 'skipped')
              .filter(j => isAdvisory(j.name));

            if (advisoryFailures.length > 0) {
              const detail = advisoryFailures.map(j => `  - ${j.name} (${j.conclusion})`).join('\n');
              core.warning(`ci.yml on SHA ${sha} passed all required lanes; advisory lanes still red:\n${detail}\nRun: ${latest.html_url}`);
            }
```

**Unchanged, keep as-is** (`:250-265`) — the exact-equality required check, and the brand-voice error
message the new `unclassified` message must match in tone ("Delivery blocked: …" + indented list +
`Run: <url>`):

```js
            // Required-lane check: every required lane must be present AND success.
            const requiredBlocking = [];
            for (const lane of REQUIRED_LANES) {
              const job = jobs.find(j => j.name === lane);
              if (!job) {
                requiredBlocking.push(`${lane} (missing)`);
              } else if (job.conclusion !== 'success') {
                requiredBlocking.push(`${lane} (${job.conclusion})`);
              }
            }

            if (requiredBlocking.length > 0) {
              const list = requiredBlocking.map(s => `  - ${s}`).join('\n');
              core.setFailed(`Delivery blocked: required CI lane(s) did not pass on SHA ${sha}:\n${list}\nRun: ${latest.html_url}`);
              return;
            }
```

---

### `mix.exs` (MODIFY — `verify.ci_lane_contract` alias + `preferred_cli_env`)

**Alias analog — `verify.mix_tasks` (`mix.exs:276-288`).** The new alias is the same
directory-scoped, anti-drift shape; copy the "directory-scoped ON PURPOSE" rationale style:

```elixir
      # Mix-task / generator CLI surface (`mix mailglass.gen.*`, doctor, reconcile,
      # suppressions.resync). Directory-scoped ON PURPOSE: a file-enumerated list
      # (as used by the contract aliases below) silently drops newly-added task
      # tests from CI — the exact drift footgun that left the Phase-47 inbound
      # generators advisory-only. A directory glob auto-includes every
      # test/mix/tasks/*_test.exs, is non-vacuous (the dir exists + has tests, so
      # it can't pass by matching zero tests), and keeps one focused concern per
      # alias per engineering-DNA. ...
      "verify.mix_tasks": [
        "test test/mix/tasks/ --warnings-as-errors"
      ],
```

Every sibling `verify.*` alias carries `--warnings-as-errors` (`mix.exs:290`, `:300`, `:303`, `:306`,
`:311`, `:314-317`) — this is the convention F5 must be fixed to preserve.

**`preferred_cli_env` analog (`mix.exs:62-84`)** — grouped under a comment, one `"verify.x": :test`
entry per line:

```elixir
        # Semantic verify aliases (REL-03)
        "verify.foundation": :test,
        ...
        "verify.mix_tasks": :test,
        ...
        "verify.schema_prefix": :test
      ]
```

Note `:83` (`"verify.schema_prefix": :test`) is the last entry — no trailing comma; adding after it
requires adding a comma to that line.

---

### `MAINTAINING.md` (MODIFY — §"Required Checks" → one disposition table)

**Current section, verbatim (`MAINTAINING.md:132-200`).** All four contradiction sites are here:

- `:134-142` — "Before merging any PR, ensure:" 8 bullets including `mix credo --strict`,
  `mix dialyzer`, `mix docs --warnings-as-errors` (D-15's first contradiction site)
- `:144-150` — the `mix verify.stability_contract` entrypoint prose
- `:152-158` — the true required set (**the only accurate registry**):

```markdown
Branch protection truth is narrower than "everything we like to run in CI".
The exact required contexts are:
- `Support Contract Core (Elixir 1.18 / OTP 27)`
- `Support Contract Admin (Elixir 1.18 / OTP 27)`
- `Compile No Optional Deps (Elixir 1.18 / OTP 27)`
- `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
- `Installer Host Smoke` (shift-left consumer-install smoke; promoted from advisory)
```

- `:160-164` — the publish-gating intent D-02 cites:

```markdown
Release trust claims also require green trust evidence beyond the required
branch-protection contexts: the clean-baseline and published-version trust
journeys must complete, and the `trust-runner-repo-head`,
`trust-runner-clean-baseline`, and `trust-runner-published` checkpoint artifacts
must be present and valid.
```

- `:180-191` — the unparenthesized advisory prose list (D-15's third site), the block that becomes
  table rows:

```markdown
The following checks are advisory signal, not branch-protection truth:
- `Format Check`
- `Compile Warnings as Errors`
- `Mix Task Tests`
...
```

**Backtick convention is universal in this section** — every check name is wrapped in `` ` ``. Keep it;
the RESEARCH parser's `trim_bt/1` depends on it being consistent.

**Markdown-table column style precedent.** `MAINTAINING.md` §Required Checks contains **no table
today** (verified — `:132-200` is prose + bullets only). Nearest in-repo precedents:

- `.planning/RATCHET-GAP-REGISTER.md:105-112` — a `| Column | Description |` schema table with a
  `|--------|-------------|` separator:

```markdown
| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID — never renumber once assigned |
| `surface` | `deliveries` / `inbound` / `preview` / `all` |
```

- `.planning/research/v1.14/DEFECT-REGISTER.md:31-38` — a `|---|---|---|---|` compact-separator row
  table with backticked identifier cells. The compact `|---|` form is what the RESEARCH-drafted
  ledger tables already use; prefer it.

Both wrap identifiers in backticks and put free-text in the last column — matching the D-05 shape
`job id | display name | classification | disposition | reason`.

---

### `CONTRIBUTING.md` (MODIFY — correct the fifth registry)

**The wrong claim, verbatim (`CONTRIBUTING.md:116-119`):**

```markdown
`main` is protected with required status checks (`Tests`, `Credo Strict`,
`Dialyzer`, `actionlint`, `PR title (semantic)`). This protection is
configured idempotently by `scripts/setup_branch_protection.sh` and
re-asserted daily by `.github/workflows/branch-protection-drift.yml`.
```

**Correct source to restate from:** `scripts/setup_branch_protection.sh:17-20`
(`REQUIRED_CHECKS=("CI Green" "Guard Release Trigger")`), asserted by
`test/scripts/required_checks_test.exs:45-58` (GATE-01):

```elixir
    expected = MapSet.new(["CI Green", "Guard Release Trigger"])
```

The corrected sentence should point at `MAINTAINING.md` § "Required Checks" rather than restating a
list that can drift again (same reasoning as F8's section-citation fix).

---

### `.planning/TOOLING-DEFECTS.md` (CREATE — planning register)

**Analog 1 — `.planning/RATCHET-GAP-REGISTER.md:1-20`.** YAML frontmatter block, then an H1 whose
title repeats the file name, then a blockquote scoping/contract note:

```markdown
---
milestone: v1.11
artifact: ratchet-gap-register
stable_ids: true
created: 2026-06-13
supersedes: .planning/milestones/v1.7-phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md
---

# RATCHET-GAP-REGISTER — v1.11 Design-System Uplift

> Fresh baseline as of Phase 95 (2026-06-13). IDs restart at GAP-01 in this new file;
> no namespace collision with the frozen v1.7 register (separate file, separate namespace).
>
> **DO NOT reopen or modify** ...
```

**Divergence to state explicitly:** both precedents are milestone-scoped (`milestone: v1.11` /
"Scope: MILESTONE"). D-18 makes `TOOLING-DEFECTS.md` deliberately milestone-**in**dependent, so the
frontmatter should carry no `milestone:` key and the blockquote should say why (it must survive a
milestone boundary — that is the whole point).

**Analog 2 — `.planning/research/v1.14/DEFECT-REGISTER.md:1-10`.** Bolded-label metadata line, then a
"How to read this register" section with a fixed severity/vocabulary legend:

```markdown
# v1.14 — DEFECT REGISTER (the prioritized, screenshot-backed hit-list)

> **Authored:** 2026-06-26 · **Method:** METHOD-01 persona-critic walkthrough (Phase 118 Plan 03).
> **Scope:** MILESTONE (sibling to `MILESTONE-SEED.md` / `STRESS-TEST-PROMPT.md`) so Phases 119–123
> consume it without reaching into an archived phase dir (D-05).
...
## How to read this register
```

Its `## Headline defects` table (`:60-62`) gives the entry-row form: `| Tag | Severity | Site |
One-liner |`. For a single-entry defect file, prefer the DEFECT-REGISTER's per-entry prose shape with a
stable ID (e.g. `TOOL-01`) plus explicit **Symptom / Evidence / Mitigations** labels — the symptom line
(`cleared: N` reported with no `milestones/<version>-phases/` directory written) is the load-bearing
content per CONTEXT `<specifics>`.

---

### `.planning/REQUIREMENTS.md` (MODIFY — amend TRUTH-09)

**Text being amended, verbatim (`REQUIREMENTS.md:98-102`):**

```markdown
- [ ] **TRUTH-09**: The hidden third gating tier is eliminated. Every `ci.yml` job is explicitly classified
  as merge-gating or advisory — no job may sit in neither and thereby block publish by accident. The 9+
  currently-unclassified jobs (Credo Strict, Dialyzer, Hex Audit, Format Check, Compile Warnings as Errors,
  Docs Warnings as Errors, Mix Task Tests, Inbound Test, Inbound Compile No Optional Deps, Installer Golden
  Gate, Trust Lane Clean Baseline) each receive a recorded decision.
```

**Format to preserve:** `- [ ] **ID**: ` prefix, two-space continuation indent, wrapped at ~110 cols.
Nearest sibling with an italic cross-reference footer to copy for noting the amendment —
`REQUIREMENTS.md:126-128` (TRUTH-05):

```markdown
- [ ] **TRUTH-05**: Every lane carries a recorded disposition — promote, keep-with-reason, or retire. No lane
  sits red or unclassified indefinitely. *(Follows TRUTH-09/07: dispositions are recorded against the
  reconciled set, not the ambiguous one.)*
```

---

## Shared Patterns

### Anti-vacuity guard (applies to: `lane_classification_drift_test.exs`, any new parser)
**Source:** `test/scripts/required_checks_test.exs:27-34`, `:102-107`; `ci_parity_drift_test.exs:175-202`
Every parser gets a `MapSet.size(x) > 0` / `map_size(x) > 0` assert whose message names *what changed*
("parser or script format changed"), plus, where a hardcoded list mirrors the registry, a
`MapSet.difference(mirror, registry) == 0` staleness assert. See the excerpts above.

### Two-direction set-difference drift assert (applies to: all four registry↔registry assertions)
**Source:** `test/scripts/required_checks_test.exs:36-42`, `:116-125`
One assert, both `MapSet.difference/2` directions in the message, each labelled by direction.

### Cross-surface declaration comment (applies to: `publish-hex.yml`, `ci_lanes.ex`, `mix.exs`)
**Source:** `publish-hex.yml:198-203`; `ci_lanes.ex:19-27`
Every duplicated copy of a lane list carries a comment saying (a) which module is canonical, (b) which
meta-test proves it has not drifted, and (c) why it is not hoisted away. New arrays must carry the
same, plus the F1 matrix-name-space warning.

### SHA-pinned third-party actions (applies to: `ci.yml` new job)
**Source:** `ci.yml:400-401`
`uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0  # v7.0.0` — copy the pin **and** the
trailing version comment verbatim; do not re-resolve the SHA.

### Brand-voice gate failure message (applies to: `publish-hex.yml`, meta-test messages)
**Source:** `publish-hex.yml:263`, `:235`
`Delivery blocked: <specific cause> on SHA <sha>:\n<indented list>\nRun: <url>` — specific, composed,
names the fix. Meta-test messages follow `ci_parity_drift_test.exs:171-173`'s form: state the drift,
state why it is dangerous ("so coverage would silently pass"), then `#{inspect(list)}`.

### `test/scripts/` module naming (applies to: new meta-test)
**Source:** `required_checks_test.exs:1`, `ci_parity_drift_test.exs:1`, `conformance_advisory_test.exs:1`
`defmodule Mailglass.Scripts.<Name>Test do` + `use ExUnit.Case, async: true`. **No tags, no
`@moduletag`, no `setup`** in any file in this directory.

---

## No Analog Found

| File / element | Role | Data Flow | Reason |
|---|---|---|---|
| `Mailglass.CIYaml.matrix_job_names/1` (`strategy:` detection) | utility | transform | No existing parser detects a `strategy:` block. Closest skeleton is `parse_ci_job_ifs/1` (`required_checks_test.exs:244-267`) — same reduce, one regex swapped. |
| The markdown-table parser (`parse_disposition_table/1`) | utility | transform | No in-repo precedent parses a markdown table. Nearest technique precedent is the heredoc-bullet parser `parse_print_expected_bullets/1` (`required_checks_test.exs:168-177`) — bound the section by splitting on unique markers, then regex the rows. RESEARCH §Parsing `MAINTAINING.md`'s table drafts it. |
| A `ci.yml` job that is BEAM-free **and** carries `needs:`/`if:` | CI config | batch | `branch_protection_advisory` (`ci.yml:1079-1082`) is BEAM-free but has neither `needs:` nor `if:`. `conformance_gates` must compose the two analogs: `branch_protection_advisory`'s minimal shape + `credo_strict`'s `needs: [changes]` / `if: needs.changes.outputs.code == 'true'` (`ci.yml:397-398`). |
| A milestone-independent `.planning/` register | planning artifact | static | Both precedents (`RATCHET-GAP-REGISTER.md`, `research/v1.14/DEFECT-REGISTER.md`) are milestone-scoped by design. `TOOLING-DEFECTS.md` deliberately breaks that — copy the structure, drop the `milestone:` frontmatter key, say why in the blockquote. |
| A markdown table inside `MAINTAINING.md` | docs | static | `MAINTAINING.md:132-200` has no table. Borrow the column style from `.planning/research/v1.14/DEFECT-REGISTER.md:31-38` (compact `|---|` separators, backticked identifiers, free text last). |

---

## Metadata

**Analog search scope:** `test/scripts/`, `test/support/`, `.github/workflows/`, `mix.exs`,
`MAINTAINING.md`, `CONTRIBUTING.md`, `.planning/*.md`, `.planning/research/v1.14/`
**Files read in full:** `test/support/ci_lanes.ex`, `test/scripts/required_checks_test.exs`,
`test/scripts/conformance_advisory_test.exs`
**Files read in targeted ranges:** `.github/workflows/ci.yml` (`:228-289`, `:392-437`, `:1079-1108`),
`.github/workflows/publish-hex.yml` (`:185-299`), `mix.exs` (`:60-89`, `:275-399`),
`MAINTAINING.md` (`:128-202`), `CONTRIBUTING.md` (`:106-131`),
`test/scripts/ci_parity_drift_test.exs` (`:1-40`, `:95-229`), `.planning/REQUIREMENTS.md` (`:85-139`),
`.planning/RATCHET-GAP-REGISTER.md` (`:1-112`), `.planning/research/v1.14/DEFECT-REGISTER.md` (`:1-60`),
`.github/workflows/repo-hygiene.yml` (`:1-60`)
**Pattern extraction date:** 2026-07-28
