# Phase 143: Test-Harness Truth — Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 14 (6 created, 8 modified/extended)
**Analogs found:** 13 / 14 (one genuine gap: no ExUnit formatter exists in this repo)

All paths are relative to the worktree root
`/Users/jon/projects/mailglass/.claude/worktrees/fix-release-gates`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/sandbox_ownership.ex` | test-support module (resource acquire/release + policy guards) | request-response (setup/teardown lifecycle) | `test/support/citext_probe.ex` (namespace + moduledoc + composed-raise) and `test/support/data_case.ex:34-36` (the acquire/release idiom being generalised) | exact |
| `test/support/suite_truth_formatter.ex` | ExUnit formatter (GenServer) | event-driven (`:module_finished`, `:test_finished`) | **NONE in repo.** Nearest structural: `lib/mailglass/adapters/fake/storage.ex` (GenServer skeleton + moduledoc/state conventions). Behaviour contract comes from stdlib `ExUnit.CLIFormatter`. | partial (see § No Analog Found) |
| `test/support/suite_floor.ex` | pure policy module returning a violations list | transform (report map → `[violation]`) | `test/support/ci_lanes.ex` (hardcoded constants + accessors + rationale moduledoc); violation-list shape has no exact precedent — closest is the `drift/2` two-set return in `test/scripts/lane_classification_drift_test.exs` | role-match |
| `credo_checks/no_raw_sandbox_ownership.ex` | custom Credo check (AST walk for a forbidden module call) | transform (AST → issues) | `credo_checks/no_raw_swoosh_send_in_lib.ex` | exact |
| `test/scripts/suite_floor_contract_test.exs` | meta-test with negative controls | transform (synthetic input → assertion) | `test/scripts/lane_classification_drift_test.exs:155-222` | exact |
| `test/mailglass/test_support/sandbox_ownership_test.exs` | unit test for a test-support module | request-response | `test/mailglass/test_support/citext_probe_test.exs` (same directory, same namespace) | exact |
| `Mailglass.CIYaml.expanded_matrix_job_names/1` | parser function on existing module | transform (YAML text → `MapSet`) | `Mailglass.CIYaml.matrix_job_names/1` (`test/support/ci_yaml.ex:77-104`) | exact |
| `Mailglass.CILanes` third axis | registry constants + accessors | — | `test/support/ci_lanes.ex:111-132` + `:174-198` (existing bucket + accessor pair) | exact |
| `.github/workflows/advisory-matrix.yml` (2 × `env:`) | workflow config | — | `advisory-matrix.yml:112-114` (existing `env:` block on the same step) | exact |
| `.github/workflows/gate-self-test.yml` (2 inputs) | workflow config | — | `gate-self-test.yml:19-22` (`check_name` input) + `:113-117` (`env:`-binding) | exact |
| `.github/workflows/publish-hex.yml` (`gate-ci-green`) | workflow job (github-script) | request-response (poll API) | `publish-hex.yml:142-189` (the existing ci.yml self-heal step) | exact |
| `MAINTAINING.md` new section | docs | — | `MAINTAINING.md:165` `## Required Checks` (heading + table shape) | exact |
| `test/mailglass/mailer_case_test.exs` (assertions) | test | — | itself (`:11-43`, numbered-comment test style) | exact |
| `test/scripts/lane_classification_drift_test.exs` (assertions) | meta-test | — | itself (`:54-65`, `:247-265`) | exact |

---

## Pattern Assignments

### `test/support/sandbox_ownership.ex` (test-support module, lifecycle)

**Analog A — namespace, moduledoc, and composed-raise style:** `test/support/citext_probe.ex`

Module header shape to copy (`citext_probe.ex:1-32`): `Mailglass.TestSupport.<Name>`, a moduledoc that
states background → mechanism → `## Usage` with literal call examples, then `@spec` on every public
function.

```elixir
defmodule Mailglass.TestSupport.CitextProbe do
  @moduledoc """
  Drains stale citext OIDs from the sandbox-checked-out connection.

  Background: ...

  ## Usage

      # In a CaseTemplate `setup` block:
      Mailglass.TestSupport.CitextProbe.run(repo: Mailglass.TestRepo)
  """

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
```

Composed error message construction — build the string in a private `defp *_message/n` with an arity
overload that appends the underlying cause (`citext_probe.ex:101-108`):

```elixir
defp exhausted_message(repo, attempted, nil) do
  "citext probe exhausted for #{inspect(repo)} after #{attempted} attempts"
end

defp exhausted_message(repo, attempted, error) do
  exhausted_message(repo, attempted, nil) <> "; last error: " <> Exception.message(error)
end
```

Also copy the "why we re-raise rather than mask" comment style (`citext_probe.ex:50-59`) — this repo
comments the *reasoning*, not the mechanics.

**Analog B — the acquire/release idiom being generalised:** `test/support/data_case.ex:34-36`

```elixir
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
```

This is the control (D-01.2). `checkout!/1`'s invariant is exactly this ordering, generalised — the
`on_exit` is the **next statement** after `start_owner!`, and every subsequent statement in the helper
sits below it. RESEARCH.md § "Pattern 1" has the target shape.

**Analog C — the async-policy guard raise:** `test/support/mailer_case.ex:78-91` (the existing I-12 guard;
D-11's guards copy this shape verbatim)

```elixir
setup tags do
  # I-12: Tests that set `@tag oban: :manual` must run async: false.
  # Oban.Testing mode is process-global state; concurrent async tests
  # with different :oban modes would stomp each other.
  oban_tagged? = Map.has_key?(tags, :oban)
  async? = Map.get(tags, :async, true)

  if oban_tagged? and async? do
    raise """
    Mailglass.MailerCase: tests using `@tag oban: ...` MUST run with `async: false`.
    Oban.Testing mode is a process-global setting — concurrent async tests
    would stomp each other. Set `use Mailglass.MailerCase, async: false` at the
    module level (or add `@tag async: false` to this test).
    """
  end
```

Note the microcopy jobs-to-be-done, which the new guards must match: **who raised** (module prefix), **what
rule** (MUST run with `async: false`), **why** (process-global state), **the one-line edit** (`use ...,
async: false`). Nothing else.

**The call sites being migrated (13 files)** — read `mailer_case.ex:93`, `:158`, `:185`, `:206`, `:248`;
`data_case.ex:35-36`; `webhook_idempotency_convergence_test.exs:51-69`; `deliver_many_test.exs:17,35`;
`deliver_later_test.exs:37,54`; `schema_axis_boot_order_test.exs:27`. Full 32-site inventory is in
RESEARCH.md § "D-07 (S2)".

---

### `test/support/suite_truth_formatter.ex` (ExUnit formatter, event-driven)

**No in-repo analog exists.** Verified: `grep -rn "formatters:\|ExUnit.Formatter\|module_finished" test/
mix.exs .github/` returns nothing. This repo has never written an ExUnit formatter. Do **not** invent an
analog — use the two references below.

**Behaviour contract (upstream, authoritative):** an ExUnit formatter is a plain `GenServer` registered via
`ExUnit.configure(formatters: [...])`. It receives `{event, payload}` via `handle_cast/2`. The canonical
implementation is stdlib `ExUnit.CLIFormatter` (available locally at
`:code.lib_dir(:ex_unit)`; source: `lib/ex_unit/lib/ex_unit/cli_formatter.ex` in elixir-lang/elixir).
Events this phase uses: `:suite_started`, `:module_finished` (payload `%ExUnit.TestModule{}` — carries
`.name`, `.tags[:async]`, `.state`), `:test_finished` (payload `%ExUnit.Test{}` — `.state` is
`{:failed, [{kind, reason, stacktrace}]}`), `:suite_finished`.

**GenServer skeleton conventions to copy from this repo:** `lib/mailglass/adapters/fake/storage.ex:1-56`

```elixir
defmodule Mailglass.Adapters.Fake.Storage do
  @moduledoc """
  GenServer owning the `:mailglass_fake_mailbox` ETS table. ...

  ## State

  - `:owners` — MapSet of currently-checked-out owner pids.
  - `:allowed` — map `allowed_pid => owner_pid` ...
  """

  use GenServer

  # ──────────────────────────────────────────────────────────────
  # Public API — mirrors Swoosh.Sandbox.Storage surface.
  # ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) when is_list(opts) do
```

Copy: the `## State` moduledoc section enumerating every state key with a one-line purpose, the
box-rule section separators, and the "Divergences from `<upstream>`" section (`storage.ex:21-27`) — the
formatter should carry a "Divergences from `ExUnit.CLIFormatter`" section for the same reason.

**Policy delegation (D-09):** the formatter must call `SandboxOwnership.probe/1` and `SuiteFloor`'s pure
functions rather than re-implementing judgment. Precedent for "the negative control drives the real
function": `lane_classification_drift_test.exs:155-160` comment.

**Healing-call comment (D-10):** comment the `ExUnit.Runner.async_loop/4` ordering reliance at the call
site, in the style of `citext_probe.ex:50-59` (reasoning-first block comment).

---

### `test/support/suite_floor.ex` (pure policy module, transform)

**Analog:** `test/support/ci_lanes.ex`

**Constants + rationale moduledoc** (`ci_lanes.ex:107-132`) — every hardcoded bucket carries a comment
saying what question it answers and what it is *not*:

```elixir
  # Lanes that block NEITHER a merge NOR a publish. This is the *classification*
  # axis. Distinct from @advisory_lanes_ci / @advisory_lanes_browser, which answer
  # a different question: "what does `mix ci` reproduce locally?" (MIXCI-03). A
  # lane can be locally reproduced AND publish-gating (Dialyzer is).
  @advisory_classified_lanes [
    "Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)",
    ...
  ]
```

**Accessor + `@spec` + `@doc` pattern** (`ci_lanes.ex:184-198`):

```elixir
  @doc """
  Lane display names that block a Hex publish when red but do NOT block a PR
  merge. `gate-ci-green` (`publish-hex.yml`) enumerates these; `ci_green.needs`
  (`ci.yml`) does not.
  """
  @spec publish_gating_lanes() :: [String.t()]
  def publish_gating_lanes, do: @publish_gating_lanes
```

**Moduledoc obligations to copy** (`ci_lanes.ex:2-78`): a "why the duplicate copies are NOT hoisted away"
section, an "independent axes" section, and an "intentional exclusions" list. `SuiteFloor`'s moduledoc must
carry the equivalents: why committed baseline JSON is rejected (D-15), the 1.18-vs-1.19 summary-line table
(RESEARCH.md § "Measuring The Suite Honestly"), and the **accepted gap** (D-18b: the floor does not prove
assertions are meaningful).

**Violations-list return shape has no exact precedent.** Nearest is the two-set `drift/2` return in
`lane_classification_drift_test.exs`. Use the RESEARCH.md § "Code Examples" pipeline shape
(`[] |> tag_allowlist_violation(...) |> floor_violation(...)`) — it is the phase's own design, and the
binding constraint is only that `violations/1` stay **pure** so the negative control drives it.

**Runtime-config read (never `compile_env`, per CLAUDE.md):** `System.get_env("MAILGLASS_SUITE_FLOOR")` and
`ExUnit.configuration()` inside the callback.

---

### `credo_checks/no_raw_sandbox_ownership.ex` (Credo check, AST transform)

**Analog:** `credo_checks/no_raw_swoosh_send_in_lib.ex` — copy structurally, near-verbatim. This is the
closest of the 20 checks: it is the only one that walks AST for a **forbidden call on a specific external
module**, with alias resolution and a path-prefix filter.

**Declaration + params** (`:1-20`):

```elixir
defmodule Mailglass.Credo.NoRawSwooshSendInLib do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      allowed_modules: [Mailglass.Adapters.Swoosh],
      included_path_prefixes: ["lib/mailglass/"],
      forbidden_functions: [:deliver, :deliver!, :deliver_many]
    ],
    explanations: [
      check: """
      Mailglass library code must send through `Mailglass.Outbound.*`, not
      `Swoosh.Mailer.deliver*` directly.
      """,
      params: [
        allowed_modules: "Modules explicitly allowed to call `Swoosh.Mailer.deliver*`.",
        included_path_prefixes: "Only files in these path prefixes are linted.",
        forbidden_functions: "Swoosh.Mailer function names that are disallowed."
      ]
    ]
```

New values: `allowed_modules: [Mailglass.TestSupport.SandboxOwnership]`,
`included_path_prefixes: ["test/"]`, `forbidden_functions: [:mode, :start_owner!, :stop_owner, :checkout,
:checkin]`. (Whether `:checkout` is in the list depends on RESEARCH.md Open Question 4 — recommendation is
to migrate `schema_axis_boot_order_test.exs:27` rather than allowlist it.)

**`run/2` — path gate, alias collection, traverse** (`:22-45`):

```elixir
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      allowed_modules = params |> Params.get(:allowed_modules, __MODULE__) |> MapSet.new()
      forbidden_functions = params |> Params.get(:forbidden_functions, __MODULE__) |> MapSet.new()
      ast = SourceFile.ast(source_file)
      swoosh_mailer_aliases = collect_swoosh_mailer_aliases(ast)

      {_ast, state} =
        Macro.traverse(
          ast,
          %{issues: [], module_stack: []},
          &prewalk(&1, &2, issue_meta, allowed_modules, forbidden_functions, swoosh_mailer_aliases),
          &postwalk/2
        )

      Enum.reverse(state.issues)
    else
      []
    end
  end
```

**Module-stack prewalk + issue emission** (`:47-86`):

```elixir
  defp prewalk({:defmodule, _, [module_ast, _]} = ast, state, _im, _am, _ff, _aliases) do
    {ast, %{state | module_stack: [module_name(module_ast) | state.module_stack]}}
  end

  defp prewalk({{:., _, [module_ast, function_name]}, meta, _args} = ast, state,
               issue_meta, allowed_modules, forbidden_functions, swoosh_mailer_aliases)
       when is_atom(function_name) do
    current_module = List.first(state.module_stack)

    if swoosh_mailer_module_ast?(module_ast, swoosh_mailer_aliases) and
         MapSet.member?(forbidden_functions, function_name) and
         not MapSet.member?(allowed_modules, current_module) do
      issue =
        format_issue(
          issue_meta,
          message:
            "Use `Mailglass.Outbound.*` instead of `Swoosh.Mailer.#{function_name}` in library code.",
          trigger: "Swoosh.Mailer.#{function_name}",
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, %{state | issues: [issue | state.issues]}}
    else
      {ast, state}
    end
  end
```

**Postwalk stack pop** (`:98-108`) and **path filter** (`:164-168`) copy verbatim.

**Alias resolution — the part that needs the most adaptation** (`:113-162`). The Swoosh check resolves a
**two-segment** module (`["Swoosh", "Mailer"]`). The new check must resolve a **four-segment** one,
`["Ecto", "Adapters", "SQL", "Sandbox"]`, and six of the nine `:auto` files use
`alias Ecto.Adapters.SQL.Sandbox` (bare tail `Sandbox`), plus `alias ..., as: X` forms:

```elixir
  defp collect_swoosh_mailer_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, MapSet.new(), fn
        {:alias, _, [module_ast]} = node, aliases ->
          {node, maybe_put_swoosh_mailer_alias(aliases, module_ast, [])}

        {:alias, _, [module_ast, opts]} = node, aliases when is_list(opts) ->
          {node, maybe_put_swoosh_mailer_alias(aliases, module_ast, opts)}

        node, aliases -> {node, aliases}
      end)

    aliases
  end

  defp maybe_put_swoosh_mailer_alias(aliases, module_ast, opts) do
    if module_parts_from_ast(module_ast) == ["Swoosh", "Mailer"] do
      MapSet.put(aliases, alias_name_from_opts(opts) || "Mailer")
    else
      aliases
    end
  end

  defp alias_name_from_opts(opts) when is_list(opts) do
    case Keyword.get(opts, :as) do
      {:__aliases__, _, parts} when is_list(parts) -> parts |> List.last() |> Atom.to_string()
      name when is_atom(name) -> Atom.to_string(name)
      _ -> nil
    end
  end
```

⚠️ The Swoosh check's `module_tail == "Mailer"` fallback (`:127`) is a deliberate over-match. Decide
explicitly whether a bare-tail `"Sandbox"` fallback is acceptable here; `test/` has no other `Sandbox`
module today, but record the decision rather than copying the line silently.

**Test analog for the new check:** `test/mailglass/credo/no_default_module_name_singleton_test.exs` +
`test/mailglass/credo/integration_test.exs` (existing per-check test convention).

**Config:** `.credo.exs:180` already carries `requires: ["./credo_checks/*.ex"]` and `:177`'s `included:`
already covers `"test/"` — **no `.credo.exs` structural change**, only the check entry. RESEARCH.md Open
Question 5 asks for a deliberately-violating scratch file to confirm the check actually matches before
relying on it.

---

### `test/scripts/suite_floor_contract_test.exs` (meta-test, negative controls)

**Analog:** `test/scripts/lane_classification_drift_test.exs`

**File header** (`:1-2`, `:40-48`) — `async: true`, a moduledoc naming the requirement ID and the CI lane
that runs it, module attributes for paths/registries:

```elixir
defmodule Mailglass.Scripts.LaneClassificationDriftTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Lane-contract truth seam (TRUTH-07/TRUTH-09). Wired into a real CI job via the
  `verify.ci_lane_contract` alias (`mix_task_tests`, `.github/workflows/ci.yml`) —
  per RESEARCH.md **F2**, a drift meta-test that runs nowhere in `ci.yml` enforces
  nothing, no matter how correct its assertions are.
  ...
  """

  @repo_root Path.expand("../..", __DIR__)
  @publish_hex_path Path.join(@repo_root, ".github/workflows/publish-hex.yml")
```

**The negative-control idiom to copy** (`:155-193`) — sanity first, then injected breakage, then assert
the failure is reported *and only it*, with a message that names the vacuity being excluded:

```elixir
  # A vacuously-passing drift meta-test is this milestone's originating failure
  # mode ... This test mechanically proves the fail-loud property instead of
  # trusting it by inspection — it exercises the SAME drift/2 helper the real
  # assertion above uses, not a re-implementation, so a future edit that weakens
  # drift/2 breaks this negative control too.
  test "negative control: removing one entry from the parsed REQUIRED_LANES set " <>
         "makes the drift comparison report it (fail-loud property is tested)" do
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    assert drift(required_from_js, @required_lanes) == {MapSet.new(), MapSet.new()},
           "sanity check failed: ... should agree before the injected-breakage assertion runs"

    removed_entry = "Installer Host Smoke"
    assert removed_entry in MapSet.to_list(required_from_js)

    {only_in_broken_js, only_in_registry} =
      drift(MapSet.delete(required_from_js, removed_entry), @required_lanes)

    assert only_in_registry == MapSet.new([removed_entry]),
           "a vacuous pass is exactly the failure mode this test excludes: removing " <>
             "'#{removed_entry}' from the parsed set must make drift/2 report it, and " <>
             "only it, ... — got #{inspect(MapSet.to_list(only_in_registry))}"

    assert MapSet.size(only_in_broken_js) == 0,
           "unexpected reverse-direction drift after removing only '#{removed_entry}': ..."
  end
```

**Anti-vacuity parser guard** (`:150-153`) — every parser gets a `> 0` assertion naming the parser:

```elixir
    assert MapSet.size(matrix_names) > 0,
           "Mailglass.CIYaml.matrix_job_names/1 parsed no matrix jobs — parser or file " <>
             "format changed (ci.yml has at least one strategy: job today)"
```

**Hardcoded-count guard with an explicit "update deliberately" instruction** (`:247-265`) — the shape
`SuiteFloor`'s pinned constants should be guarded with:

```elixir
    assert map_size(job_names) == 24,
           "expected exactly 24 ci.yml jobs (23 pre-existing + the conformance_gates job " <>
             "added in Phase 141 plan 03) — got #{map_size(job_names)}. A future legitimate " <>
             "job addition must update this count deliberately, not delete the guard."
```

**Highest-value test in the phase** (RESEARCH.md Pitfall 2): feed the classifier the verbatim captured
term `{:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, []}}}, []}` and assert a non-zero
tally. No repo analog for a captured-failure-term fixture — use RESEARCH.md § "Code Examples" as the source.

**Wiring:** none. `verify.ci_lane_contract` (`mix.exs:296-298`) is a `test test/scripts/` directory glob,
so this file is auto-collected. **No `mix.exs` change.**

---

### `test/mailglass/test_support/sandbox_ownership_test.exs` (unit test)

**Analog:** `test/mailglass/test_support/citext_probe_test.exs` — same directory, same namespace, same
"unit-test a `test/support/` module" job.

```elixir
defmodule Mailglass.TestSupport.CitextProbeTest do
  use ExUnit.Case, async: true

  alias Mailglass.TestSupport.CitextProbe

  test "returns :ok when the probe succeeds" do
    assert :ok =
             CitextProbe.run(
               repo: Mailglass.TestRepo,
               max_attempts: 2,
               probe_fun: fn _repo -> :ok end
             )
  end

  test "raises when the poisoned-OID probe exhausts its retries" do
    assert_raise RuntimeError,
                 ~r/^citext probe exhausted for Mailglass\.TestRepo after 3 attempts/,
                 fn -> CitextProbe.run(repo: Mailglass.TestRepo, max_attempts: 3, probe_fun: ...) end
  end
```

Copy: (a) `use ExUnit.Case, async: true` — **not** `DataCase`, so the test does not itself acquire the
sandbox; (b) the injectable-function seam (`probe_fun:`) — `SandboxOwnership` should expose an equivalent
so failure paths are testable without a real leak; (c) `assert_raise` with a regex anchored on the message
prefix; (d) `Agent.start_link` counters for multi-attempt behaviour (`:47-58`).

The mechanism-level regression test (D-04) needs a **real** `Mailglass.TestRepo` leak/heal cycle — that
part has no analog; drive it with `Ecto.Adapters.SQL.Sandbox` directly inside this file (it is the one file
the Credo check must allowlist alongside the helper, or the test cannot be written).

---

### `Mailglass.CIYaml.expanded_matrix_job_names/1` (parser function)

**Analog:** the sibling `matrix_job_names/1` in the same file (`test/support/ci_yaml.ex:69-104`) — copy
the reduce-over-lines + indent-anchored-regex shape exactly:

```elixir
  @doc """
  Returns a `MapSet` of the display names (see `job_names/1`) of every job in the raw
  `ci.yml` source string that declares a `strategy:` block (i.e. a matrix job).

  Display names, not job keys, are returned deliberately: ...
  """
  @spec matrix_job_names(String.t()) :: MapSet.t(String.t())
  def matrix_job_names(source) do
    lines = String.split(source, "\n")

    {matrix_keys, _current_key} =
      Enum.reduce(lines, {MapSet.new(), nil}, fn line, {acc, current_key} ->
        cond do
          # Top-level job key (2-space indent, identifier, colon, no trailing content)
          Regex.match?(~r/^  ([a-z_]+):$/, line) ->
            [[_, key]] = Regex.scan(~r/^  ([a-z_]+):$/, line)
            {acc, key}

          # strategy: line at job level (4-space indent)
          current_key != nil and Regex.match?(~r/^    strategy:$/, line) ->
            {MapSet.put(acc, current_key), current_key}

          true ->
            {acc, current_key}
        end
      end)

    names = job_names(source)

    matrix_keys
    |> Enum.map(fn key -> Map.get(names, key) end)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end
```

New function extends this to parse `strategy.matrix.include:` rows (8-space `include:`, 10-space
`- key: value`, 12-space `key: value` in `advisory-matrix.yml`) and substitute `${{ matrix.<key> }}` into
the `name:` template, producing 7 runtime names.

**Moduledoc obligation:** the module's existing `## The two name spaces (RESEARCH F1)` section
(`ci_yaml.ex:21-31`) states that every function returns *declared* names. Adding a function that returns
*runtime* names contradicts that paragraph — amend it in the same commit (D-21/D-25 spirit). The existing
`## Accepted debt` section (`:10-19`) is the model for recording that kind of deliberate wrinkle.

---

### `Mailglass.CILanes` third axis

**Analog:** `test/support/ci_lanes.ex:111-132` (bucket + rationale comment) and `:174-198`
(`@doc` + `@spec` + one-line accessor). Both excerpts are quoted under § `test/support/suite_floor.ex` above.

**Load-bearing non-change:** `all_classified_lanes/0` (`:200-211`) is bound by set-equality to `ci.yml`'s
24 jobs. The new accessors must **not** be folded in (D-24 / RESEARCH Pitfall 6). The hardcoded counts at
`ci_lanes.ex` and `lane_classification_drift_test.exs:252,257,455` stay unchanged.

**Moduledoc amendment (D-31):** `ci_lanes.ex:54-63`'s exclusions list calls Core Full Suite a
"cron-only / live-provider canar[y]" — factually wrong and becomes misleading once the lane gates a
publish. Amend the name and the classification claim; the *parity* exclusion itself stays.

---

### `.github/workflows/advisory-matrix.yml` (2 × `env:` addition)

**Analog:** the same step, `advisory-matrix.yml:112-114` (and the twin at `:216-217`):

```yaml
        env:
          MAILGLASS_SCHEMA: ${{ matrix.schema }}
        run: mix test --warnings-as-errors --exclude requires_workspace
```

Add `MAILGLASS_SUITE_FLOOR: "1"` to both `env:` blocks. Copy the surrounding
comment convention (`:100-111`) — a comment block that names the requirement ID (`D-06`, `Phase 138
GATE-02`) and explains why the env var exists, not what it does.

---

### `.github/workflows/gate-self-test.yml` (2 new inputs)

**Analog for the input declaration:** `:19-22`

```yaml
      check_name:
        description: "Required-check name prefix to poll. Default is 'CI Green' (the aggregate required context). Use 'Trust Lane Repo Head (' to poll a specific leaf lane."
        type: string
        default: "CI Green"
```

**Analog for safe interpolation (V5, security):** `:113-117` — bind inputs through `env:`, never inline
into the `run:` body:

```yaml
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR: ${{ steps.open-pr.outputs.pr }}
          CHECK_NAME: ${{ inputs.check_name }}
```

**The poll loop to modify** (`:118-145`) — `--required` at `:122` is the defect; `required_only: false`
must drop the flag. The `*)` arm (`:137-141`) cannot distinguish pending from never-appeared; the new
never-appeared outcome should print `gh pr checks "$PR" --json name,state` on deadline:

```bash
          DEADLINE=$((SECONDS + 1500))
          while [ $SECONDS -lt $DEADLINE ]; do
            STATUS=$(gh pr checks "$PR" --required --json name,state \
              --jq '.[] | select(.name | startswith(env.CHECK_NAME)) | .state' | head -1)
            case "$STATUS" in
              FAILURE|FAILED|CANCELLED|TIMED_OUT)
                echo "result=blocked" >> "$GITHUB_OUTPUT"; exit 0 ;;
              SUCCESS)
                echo "result=leaked" >> "$GITHUB_OUTPUT"; exit 1 ;;
              *)
                echo "${CHECK_NAME}check still running (status=${STATUS:-pending})..."
                sleep 30 ;;
            esac
          done
          echo "result=timeout" >> "$GITHUB_OUTPUT"; exit 1
```

**Summary microcopy** (`:158-176`) — already uses the canonical `Delivery blocked: …` shape; extend, don't
replace.

---

### `.github/workflows/publish-hex.yml` (`gate-ci-green`)

**Analog:** the existing ci.yml self-heal step, `publish-hex.yml:142-189` — the new advisory-matrix
self-heal is this step generalised to poll a **list** of workflows concurrently under **one** shared
30-minute deadline (D-22; never serial — RESEARCH Pitfall 4):

```javascript
            const sha = '${{ steps.resolve-sha.outputs.sha }}';
            const ref = '${{ steps.resolve-sha.outputs.ref }}';
            const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

            async function latestRun() {
              const {data} = await github.rest.actions.listWorkflowRuns({
                owner: context.repo.owner, repo: context.repo.repo,
                workflow_id: 'ci.yml', head_sha: sha, per_page: 10
              });
              return data.workflow_runs[0] || null;
            }

            let run = await latestRun();
            if (!run) {
              core.info(`No ci.yml run on ${sha}; dispatching ci.yml on ${ref} (anti-recursion self-heal).`);
              await github.rest.actions.createWorkflowDispatch({
                owner: context.repo.owner, repo: context.repo.repo,
                workflow_id: 'ci.yml', ref
              });
            }

            const deadlineMs = Date.now() + 30 * 60 * 1000;
            while (!run || run.status !== 'completed') {
              if (Date.now() > deadlineMs) {
                core.setFailed(`Delivery blocked: no completed ci.yml run for SHA ${sha} within 30 minutes.`);
                return;
              }
              await sleep(20000);
              run = await latestRun();
            }
```

Note the fail-closed idioms to preserve: query by `head_sha` (D-30's fan-out mitigation depends on it),
`core.setFailed` with the `Delivery blocked: …` shape, the pinned action SHA
`actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3`.

**Classification arrays / verdict logic:** copy the existing `REQUIRED_LANES` (`:204-212`, exact equality),
`ADVISORY_LANES` (`:230-234`, prefix), `startsWithAny`/`classify` (`:263-271`), `total_count === 0` →
`setFailed` (`:281-284`), and the `(missing)` presence loop (`:295-305`). The two new arrays mirror these
shapes; the ci.yml verdict logic itself stays byte-identical.

**Guard that binds the change:** `lane_classification_drift_test.exs:267-281` asserts both the `(missing)`
marker and the literal string `"Delivery blocked: required CI lane(s) did not pass on SHA"` still exist.
New messages must follow that shape.

---

### `MAINTAINING.md` — new `## Advisory Matrix Lanes` section

**Analog:** `MAINTAINING.md:165` `## Required Checks` (heading level + 7-column table shape).

⚠️ **Hard constraint, not a style note.** `parse_disposition_table/1`
(`lane_classification_drift_test.exs:613-626`) bounds itself with a `String.split(md, "\n## ")` on the
`Required Checks` section and `:455` asserts **exactly 24 rows**. Rows added inside `## Required Checks`
produce a 31-row failure. The 7-row advisory-matrix table MUST sit under its own top-level `## ` heading.
Existing sibling headings for placement reference: `## Tarball Allowlist Protocol` (`:77`),
`## Bus Factor & Continuity` (`:269`).

Also rewrite `:259-265` ("none gates a merge" is now half-true; its runtime-matrix-suffix claim is
factually wrong per RESEARCH § "Runtime vs Declared Job Names") and amend `:212-216`.

---

### `test/mailglass/mailer_case_test.exs` (add assertions)

**Analog:** itself — numbered-comment test style with the plan reference in the moduledoc (`:1-43`):

```elixir
defmodule Mailglass.MailerCaseTest do
  @moduledoc """
  Tests for Mailglass.MailerCase setup: default setup, tag overrides, Oban modes,
  set_mailglass_global, WebhookCase + AdminCase stubs.
  Tests 1-10 per the plan spec.
  """
  use Mailglass.MailerCase, async: true

  # Test 1: default setup — Fake checked out, tenancy stamped, PubSub subscribed
  test "defaults: Fake checked out, tenancy stamped, PubSub subscribed" do
```

New assertions prove the four S2 deletions are behaviour-preserving (`set_mailglass_global/0` semantics
unchanged). Continue the `# Test N:` numbering and update the moduledoc's summary line.

---

### `test/scripts/lane_classification_drift_test.exs` (add assertions)

**Analog:** itself — the set-equality test shape (`:54-65`) for the new registry↔YAML assertions, plus a
paired negative control per RESEARCH Pitfall 9:

```elixir
  test "REQUIRED_LANES (publish-hex.yml) set-equals Mailglass.CILanes.required_lanes/0" do
    js_source = File.read!(@publish_hex_path)
    required_from_js = parse_js_array(js_source, "REQUIRED_LANES")

    {only_in_js, only_in_registry} = drift(required_from_js, @required_lanes)

    assert MapSet.size(only_in_js) == 0 and MapSet.size(only_in_registry) == 0,
           "publish-hex.yml's REQUIRED_LANES and Mailglass.CILanes.required_lanes/0 " <>
             "have drifted:\n" <>
             "  In the JS array but missing from CILanes: #{inspect(MapSet.to_list(only_in_js))}\n" <>
             "  In CILanes but missing from the JS array: #{inspect(MapSet.to_list(only_in_registry))}"
  end
```

Add `@advisory_matrix_path` alongside `@publish_hex_path`/`@ci_yml_path` (`:40-43`) and new module
attributes reading the two new `CILanes` accessors (`:45-48` shape). Existing assertions at `:247-265` and
`:455` must stay green unchanged.

---

## Shared Patterns

### Composed maintainer-facing failure messages
**Sources:** `test/support/mailer_case.ex:84-91` (guard raise), `test/support/citext_probe.ex:101-108`
(composed message), `test/scripts/lane_classification_drift_test.exs:185-189` (assertion message),
`.github/workflows/gate-self-test.yml:174` and `publish-hex.yml:183` (`Delivery blocked: …`).
**Apply to:** every raise, violation, assertion message, and `core.setFailed` in this phase.

Shape: `<Noun> <past-tense verb>: <specific cause>` then the recovery. Every message answers, in order:
which thing did it, why, and the one edit that fixes it. Never "Oops!". CI-side messages use the literal
prefix `Delivery blocked: `.

### Anti-vacuity assertion on every parser
**Source:** `test/scripts/required_checks_test.exs:30-34`, mirrored at
`lane_classification_drift_test.exs:150-153`.
**Apply to:** `expanded_matrix_job_names/1`, `SuiteFloor.violations/1`, the signature classifier.

```elixir
    assert MapSet.size(matrix_names) > 0,
           "Mailglass.CIYaml.matrix_job_names/1 parsed no matrix jobs — parser or file " <>
             "format changed (ci.yml has at least one strategy: job today)"
```

### Negative control exercising the real function
**Source:** `test/scripts/lane_classification_drift_test.exs:155-193` (quoted in full above).
**Apply to:** `suite_floor_contract_test.exs` (every violation class), the new
`expanded_matrix_job_names/1` assertions, the signature classifier.
Rule from the comment at `:158-160`: exercise the **same** helper the real assertion uses, never a
re-implementation.

### Hardcoded constant + "update deliberately" guard
**Source:** `test/support/ci_lanes.ex:107-132` (constants + rationale) +
`lane_classification_drift_test.exs:247-265` (count guard).
**Apply to:** `SuiteFloor`'s per-schema floors, the skipped ceiling (7), the exclusion allowlist, the two
new `CILanes` buckets.

### Reasoning-first comments at load-bearing call sites
**Source:** `test/support/citext_probe.ex:50-59`, `test/support/mailer_case.ex:78-80`,
`test/support/ci_lanes.ex:19-27` ("Why the YAML/script copies are NOT hoisted away").
**Apply to:** the formatter's healing call (D-10 ordering reliance), `advisory-matrix.yml`'s concurrency
group (D-30), `SuiteFloor`'s rejection of committed baseline JSON.

### `test/support/` placement discipline
**Source:** `mix.exs:115` (`elixirc_paths(:test)`) and the `:package :files` allowlist (lists `lib`, not
`test`/`credo_checks`).
**Apply to:** all three new modules. Nothing goes to `lib/` — that incurs `docs/api_stability.md` +
`test/mailglass/stability_contract_test.exs` obligations in the **required** Support Contract Core lane.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/support/suite_truth_formatter.ex` | ExUnit formatter | event-driven | **No ExUnit formatter has ever been written in this repo.** Verified by grep for `formatters:`, `ExUnit.Formatter`, `module_finished` across `test/`, `mix.exs`, `.github/` — zero hits. Use the stdlib `ExUnit.CLIFormatter` (elixir-lang/elixir `lib/ex_unit/lib/ex_unit/cli_formatter.ex`; compiled locally under `:code.lib_dir(:ex_unit)/ebin`) for the `GenServer` + `handle_cast({event, payload}, state)` contract, and `lib/mailglass/adapters/fake/storage.ex:1-56` for this repo's GenServer moduledoc/state/section conventions. Do not invent a repo precedent. |

**Partial-analog note:** `SuiteFloor`'s violations-list return shape also has no exact precedent; the
constants/accessor/moduledoc half is a strong `CILanes` match, but the `[] |> check_a() |> check_b()`
accumulator pipeline comes from RESEARCH.md § "Code Examples", not from existing code.

---

## Metadata

**Analog search scope:** `credo_checks/`, `test/support/`, `test/scripts/`, `test/mailglass/test_support/`,
`test/mailglass/credo/`, `lib/mailglass/` (GenServers), `.github/workflows/`, `MAINTAINING.md`, `mix.exs`,
`.credo.exs`
**Files scanned:** 20 credo checks + 20 test-support modules + 5 test/scripts files + 4 workflows + 3 docs
**Files read in full or in targeted ranges:** 14
**Pattern extraction date:** 2026-07-29
