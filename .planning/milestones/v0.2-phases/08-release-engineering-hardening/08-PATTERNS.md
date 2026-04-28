# Phase 8: Release-Engineering Hardening - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 18 (5 new, 13 modified)
**Analogs found:** 16 / 18

## File Classification

### New Files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/mailglass/outbound/async_adapter.ex` | behaviour (namespace) | request-response | `lib/mailglass/optional_deps.ex` | exact (namespace + 5th first-class behaviour) |
| `lib/mailglass/outbound/async_adapter/task_supervisor.ex` | behaviour-impl (prod) | request-response | `lib/mailglass/clock.ex` (System impl pattern) + `lib/mailglass/outbound.ex:437,607` (callsite shape) | exact |
| `lib/mailglass/outbound/async_adapter/inline.ex` | behaviour-impl (test) | request-response | `lib/mailglass/clock.ex` (System impl pattern) | exact |
| `test/support/citext_probe.ex` | test-support utility | request-response | `test/support/data_case.ex:62-69` + `test/mailglass/persistence_integration_test.exs:60-73` | exact (extraction) |
| `lib/mix/tasks/mailglass.docs.check.ex` | mix-task | batch (grep over `guides/*.md`) | `lib/mix/tasks/mailglass.publish.check.ex` | role-match |
| `scripts/check_dialyzer_ignore.sh` | shell-gate (CI) | batch (grep over `.dialyzer_ignore.exs`) | none in codebase — first shell-script gate | no analog |
| `scripts/check_credo_suppressions.sh` | shell-gate (CI) | batch (grep over `.credo.exs`) | paired with `check_dialyzer_ignore.sh` | same shape as sibling |

### Modified Files

| Modified File | Role | Data Flow | Closest Analog (within file) | Match Quality |
|----------|------|-----------|------------------------------|---------------|
| `mix.exs` (root) | config | n/a | existing `aliases/0` + `docs/0` blocks (lines 130, 222) | self-edit |
| `mailglass_admin/mix.exs` | config | n/a | mirrors root `mix.exs` `:dialyzer` + `:extras` | self-edit |
| `.credo.exs` | config | n/a | existing `extra_checks` + Oban prior art | self-edit |
| `.dialyzer_ignore.exs` (root, new file) | config | n/a | none (first creation) | no analog |
| `mailglass_admin/.dialyzer_ignore.exs` (new file) | config | n/a | sibling root file | mirrors sibling |
| `.github/workflows/ci.yml` | CI workflow | event-driven | existing Tests/Credo/Dialyzer steps (lines 155-260) | self-edit |
| `.github/workflows/publish-hex.yml` | CI workflow | event-driven | existing job (lines 1-60) | self-edit (trigger swap) |
| `.github/workflows/post-publish-smoke.yml` | CI workflow | event-driven | sibling `publish-hex.yml` (same trigger swap) | mirrors sibling |
| `.github/workflows/release-please.yml` | CI workflow | event-driven | existing sed step (lines 38-77) | self-edit (harden) |
| `.github/workflows/advisory-matrix.yml` | CI workflow | event-driven | `ci.yml` Tests job (DB setup pattern at lines 116-156) | role-match |
| `lib/mailglass/outbound.ex` | service | request-response | own callsites at lines 437, 607 (swap to AsyncAdapter) | self-edit |
| `test/support/{mailer,data,webhook,admin}_case.ex` | test-support | request-response | `test/support/mailer_case.ex:94-101` + `data_case.ex:62-69` (probe loops to extract) | self-edit (extract probe) |
| `mailglass_admin/test/mailglass_admin/mix_config_test.exs` | test | batch | existing `evaluate_mailglass_dep/0` + `extract_function_body/3` (lines 68-102) | self-edit (add regex anchor test) |
| `CONTRIBUTING.md` | docs | n/a | existing scaffold (32 lines) | self-edit (append REL-05 section) |
| `guides/*.md` | docs | n/a | n/a — strip-pass over D-NN/LINT-NN tokens | mechanical |

---

## Pattern Assignments

### `lib/mailglass/outbound/async_adapter.ex` (behaviour namespace)

**Analog:** `lib/mailglass/optional_deps.ex` (namespace module pattern + `# Pattern (CORE-06)` documentation block)

**Namespace + documentation pattern** (`lib/mailglass/optional_deps.ex:1-41`):
```elixir
defmodule Mailglass.OptionalDeps do
  @moduledoc """
  Namespace for optional dependency gateway modules.

  Each submodule gates one optional dependency behind a `Code.ensure_loaded?/1`
  check and exposes `available?/0`. ...

  ## Pattern (CORE-06)

  - **Compile-time:** ...
  - **Runtime:** ...

  ## Gateway Modules

  - `Mailglass.OptionalDeps.Oban` — gates `{:oban, "~> 2.21"}`. ...
  ...

  ## Lint Enforcement
  ...
  """
end
```

**What to copy:** the empty-body namespace module style with sectioned moduledoc enumerating implementations. AsyncAdapter mirrors this exactly: `## Implementations`, `## Pattern (D-08-11)`, `## Configuration`. Per D-08-29 Phase-9-firewall and the `<specifics>` block, AsyncAdapter ships internal — add `@moduledoc false` OR keep moduledoc and tag `## Internal — may move to public surface in Phase 9`.

**Behaviour callback shape** (per D-08-11 + integration with `outbound.ex:437,607`):
```elixir
@callback dispatch(fun :: (-> any()), opts :: keyword()) :: {:ok, pid()} | :ok
```
The two existing callsites both call `Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn -> ... end)`. The behaviour replaces that call with `AsyncAdapter.dispatch(fn -> ... end, [])`.

**Configuration resolution** (mirror `lib/mailglass/clock.ex:32-37`):
```elixir
defp impl do
  case Application.get_env(:mailglass, :async_adapter) do
    nil -> Mailglass.Outbound.AsyncAdapter.TaskSupervisor
    mod when is_atom(mod) -> mod
  end
end
```
**Critical:** the existing `outbound.ex:362-364` already reads `:async_adapter` as either `:task_supervisor | :oban` atoms. The new behaviour resolution must coexist — recommended: continue reading the atom for adapter-selection in `enqueue_via_async_adapter/2`, and have `AsyncAdapter.dispatch/2` resolve the *behaviour module* via `Application.get_env(:mailglass, :async_adapter_impl, TaskSupervisor)`. Disambiguating the env keys (or repurposing `:async_adapter`) is a planner decision (CONTEXT.md flagged "confirm name in plan").

---

### `lib/mailglass/outbound/async_adapter/task_supervisor.ex` (behaviour impl, prod default)

**Analog:** `lib/mailglass/clock.ex` (impl-side pattern) + `lib/mailglass/outbound.ex:437-449` (extracted body)

**Existing prod callsite to wrap** (`lib/mailglass/outbound.ex:435-447`):
```elixir
case Repo.multi(multi) do
  {:ok, %{delivery: d}} ->
    # Spawn non-linked task under Mailglass.TaskSupervisor.
    # Tenancy process-dict MUST be re-stamped (not inherited) — D-21.
    Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
      Mailglass.Tenancy.with_tenant(tenant_id, fn ->
        try do
          case dispatch_by_id(d.id) do
            {:ok, _} ->
              :ok

            {:error, err} ->
```

**Pattern to extract** — the `Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn -> ... end)` invocation moves into `TaskSupervisor.dispatch/2`. The `Mailglass.Tenancy.with_tenant(tenant_id, fn -> ... end)` re-stamping stays at the callsite (it's a per-call tenant_id, not adapter-level concern), so the behaviour callback signature stays narrow: `dispatch(fun, opts)`.

**Implementation skeleton:**
```elixir
defmodule Mailglass.Outbound.AsyncAdapter.TaskSupervisor do
  @moduledoc false
  @behaviour Mailglass.Outbound.AsyncAdapter

  @impl true
  def dispatch(fun, _opts) when is_function(fun, 0) do
    Task.Supervisor.start_child(Mailglass.TaskSupervisor, fun)
  end
end
```

**Sibling Application.start/2 supervision** (`lib/mailglass/application.ex:23`) — already supervises `{Task.Supervisor, name: Mailglass.TaskSupervisor}`. **No change needed.**

---

### `lib/mailglass/outbound/async_adapter/inline.ex` (behaviour impl, test default)

**Analog:** `lib/mailglass/clock.ex` (System impl pattern: trivial single-fn module behind a behaviour)

**Pattern (test-default behaviour, runs synchronously under caller):**
```elixir
defmodule Mailglass.Outbound.AsyncAdapter.Inline do
  @moduledoc false
  @behaviour Mailglass.Outbound.AsyncAdapter

  @impl true
  def dispatch(fun, _opts) when is_function(fun, 0) do
    fun.()
    :ok
  end
end
```

**Critical: D-08-15 tenancy parity.** The Inline impl runs in the *caller's* process — its tenancy is whatever the test process currently has stamped. The callsite in `outbound.ex` already wraps in `Mailglass.Tenancy.with_tenant/2` (lines 438, 608), so re-stamping happens at the callsite, not the adapter — confirming the narrow `dispatch(fun, opts)` callback signature is correct.

**Why caller-side re-stamping works for both impls:** both prod and test paths execute `with_tenant(tenant_id, fn -> ... end)` *inside* the supplied closure (line 438 and 608 in current `outbound.ex`). Inline runs the closure synchronously — `with_tenant` re-stamps then restores prior tenant on return. TaskSupervisor runs the closure in a fresh process — `with_tenant` stamps the fresh process. Same semantics.

---

### `test/support/citext_probe.ex` (test-support utility)

**Analog:** `test/support/data_case.ex:62-69` + `test/mailglass/persistence_integration_test.exs:60-73`

**Existing probe in `data_case.ex:62-69`:**
```elixir
for _ <- 1..5 do
  try do
    Mailglass.TestRepo.query!("SELECT 'probe'::citext")
  rescue
    # disconnect_on_error_codes fires; ownership auto-reconnects
    Postgrex.Error -> :ok
  end
end
```

**Existing probe in `persistence_integration_test.exs:60-73` (recursive form):**
```elixir
defp probe_until_clean(0), do: :ok

defp probe_until_clean(remaining) do
  try do
    Mailglass.TestRepo.query!(
      "SELECT address FROM mailglass_suppressions LIMIT 1",
      []
    )

    :ok
  rescue
    _ -> probe_until_clean(remaining - 1)
  end
end
```

**Existing probe in `mailer_case.ex:94-101`:**
```elixir
# Probe the checked-out connection for a stale citext OID.
# Same rationale and pattern as DataCase.setup — see that module for the
# full explanation. MailerCase does not inherit DataCase, so the probe is
# duplicated here.
for _ <- 1..5 do
  try do
    Mailglass.TestRepo.query!("SELECT 'probe'::citext")
  rescue
    # disconnect_on_error_codes fires; ownership auto-reconnects
    Postgrex.Error -> :ok
  end
end
```

**Extraction target — `Mailglass.TestSupport.CitextProbe` skeleton:**
```elixir
defmodule Mailglass.TestSupport.CitextProbe do
  @moduledoc """
  Drains stale citext OIDs from the sandbox-checked-out connection.

  Background: `migration_test.exs` drops + recreates the citext extension to
  prove the down/up round-trip. Postgres assigns a fresh OID on recreate; pool
  workers retain the pre-drop OID and surface `Postgrex.Error XX000 (internal_error)
  cache lookup failed for type NNNNNN` on the next citext query.

  `disconnect_on_error_codes: [:internal_error]` in `config/test.exs` converts
  the error into a pool reconnect; the reconnected worker re-bootstraps its
  type cache. This module loops the probe up to `max_attempts` times to handle
  the worst case where successive workers were also poisoned.

  ## Usage

      # In a CaseTemplate `setup` block:
      Mailglass.TestSupport.CitextProbe.run(repo: Mailglass.TestRepo)

      # In `test_helper.exs` after migrations:
      Mailglass.TestSupport.CitextProbe.run([])
  """

  @default_max_attempts 5

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    do_probe(repo, max_attempts)
  end

  defp do_probe(_repo, 0), do: :ok

  defp do_probe(repo, remaining) do
    try do
      repo.query!("SELECT 'probe'::citext")
      :ok
    rescue
      Postgrex.Error -> do_probe(repo, remaining - 1)
    end
  end
end
```

**Replacement sites** (per D-08-10):
- `test/support/data_case.ex:62-69` → `Mailglass.TestSupport.CitextProbe.run([])`
- `test/support/mailer_case.ex:94-101` → `Mailglass.TestSupport.CitextProbe.run([])`
- `test/support/webhook_case.ex` setup block (after `start_owner!`) → `Mailglass.TestSupport.CitextProbe.run([])`
- `test/support/admin_case.ex` → inherits via `use Mailglass.MailerCase`, **no direct change**
- `test/test_helper.exs` (cold-start, after migrations) → `Mailglass.TestSupport.CitextProbe.run([])`
- `test/mailglass/persistence_integration_test.exs:56,60-73` → `Mailglass.TestSupport.CitextProbe.run(repo: Mailglass.TestRepo)`; delete the local `probe_until_clean/1` defp pair

---

### `lib/mix/tasks/mailglass.docs.check.ex` (mix-task)

**Analog:** `lib/mix/tasks/mailglass.publish.check.ex` (existing in-tree mix task)

**Module skeleton pattern from `publish.check.ex:1-39`:**
```elixir
defmodule Mix.Tasks.Mailglass.Publish.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Run the pre-publish Hex package checks"

  @moduledoc """
  Verify the published tarball before Hex.pm release.

  ## Usage

      mix mailglass.publish.check
      ...
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [package: :string, keep: :boolean])

    validate_cli!(rest, invalid)
    ...
  end
```

**What to copy:**
- `use Boundary, classify_to: Mailglass` first declaration
- `@shortdoc` + `@moduledoc` + `## Usage` block
- `use Mix.Task` + `@impl Mix.Task def run(argv)`
- `OptionParser.parse(argv, strict: [...])` + `validate_cli!/2` (lines 52-60) for unknown-arg / unknown-flag rejection with `Mix.raise("Delivery blocked: ...")` brand-voice errors

**Mix-task-specific behaviour for `mailglass.docs.check` (REL-02):**
```elixir
@impl Mix.Task
def run(argv) do
  {opts, rest, invalid} = OptionParser.parse(argv, strict: [path: :string])
  validate_cli!(rest, invalid)

  paths = Path.wildcard(opts[:path] || "guides/**/*.md")
  banned_patterns = [~r/\bD-\d{2,3}\b/, ~r/\bLINT-\d{2}\b/]

  leaks =
    Enum.flat_map(paths, fn path ->
      content = File.read!(path)

      Enum.flat_map(banned_patterns, fn re ->
        Regex.scan(re, content) |> Enum.map(&{path, hd(&1)})
      end)
    end)

  if leaks == [] do
    Mix.shell().info("[mailglass.docs.check] OK — no internal IDs leaked into public guides.")
    :ok
  else
    Enum.each(leaks, fn {path, token} ->
      Mix.shell().error("[mailglass.docs.check] internal ID #{inspect(token)} found in #{path}")
    end)

    Mix.raise("Delivery blocked: #{length(leaks)} internal ID(s) leaked into guides/*.md")
  end
end
```

**Brand voice for errors** (`publish.check.ex:46-49,53-54`):
```elixir
defp packages(other) do
  Mix.raise(
    "Delivery blocked: unknown package #{inspect(other)}. Use mailglass or mailglass_admin."
  )
end
```
Copy the **"Delivery blocked: ..."** prefix verbatim — already established as the project's `Mix.raise/1` voice.

---

### `scripts/check_dialyzer_ignore.sh` (CI shell-gate, NEW)

**Analog:** none in codebase. Per CONTEXT `<established_patterns>` D-08-19, the same shape applies to both this script and `check_credo_suppressions.sh`. The only existing ecosystem reference is the comment-convention idea from `Mailglass.OptionalDeps` moduledoc.

**Comment-convention shape (from `lib/mailglass/optional_deps.ex:22-33`):**
```elixir
## Gateway Modules

- `Mailglass.OptionalDeps.Oban` — gates `{:oban, "~> 2.21"}`. Fallback for
  `deliver_later/2` is `Task.Supervisor` (lands Phase 3).
- `Mailglass.OptionalDeps.OpenTelemetry` — gates `{:opentelemetry, "~> 1.7"}`.
  Adopter-owned bridge via `opentelemetry_telemetry` (D-32).
```

**Skeleton (per D-08-05 + D-08-27 — `# Reason:` immediately above each tuple entry):**
```bash
#!/usr/bin/env bash
# Fail CI if any `.dialyzer_ignore.exs` entry is missing a `# Reason: ...`
# comment on the immediately-preceding non-blank line.
#
# Convention (D-08-27): every suppression is a documented decision, not a
# silent suppression. Paired with scripts/check_credo_suppressions.sh.

set -euo pipefail

FILES=(".dialyzer_ignore.exs" "mailglass_admin/.dialyzer_ignore.exs")
errors=0

for file in "${FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  awk '
    /^\s*\{/ {
      if (prev !~ /^\s*#\s*Reason:/) {
        printf "%s:%d  missing # Reason: comment above tuple\n", FILENAME, NR
        rc = 1
      }
    }
    /^\s*[^[:space:]]/ { prev = $0 }
    END { exit rc + 0 }
  ' "$file" || errors=$((errors + 1))
done

if [[ $errors -gt 0 ]]; then
  echo "FAIL: dialyzer ignore entries missing # Reason: comments" >&2
  exit 1
fi

echo "OK: all dialyzer ignore entries are documented."
```

**CI integration shape** — runs as a step in the `dialyzer` job (`ci.yml:251-260`) BEFORE `mix dialyzer`. Add `shellcheck` of this script in the same job (D-08-23 enforces shellcheck on workflow shell blocks; reuse here).

---

### `scripts/check_credo_suppressions.sh` (CI shell-gate, NEW)

**Analog:** sibling `scripts/check_dialyzer_ignore.sh` (same shape, different file + extra `# Tracking:` requirement).

**Skeleton (per D-08-19 — both `# Reason:` AND `# Tracking:` required):**
```bash
#!/usr/bin/env bash
# Fail CI if any `false`-tuple entry in `.credo.exs` :disabled_checks
# is missing BOTH a `# Reason: ...` line AND a `# Tracking: ...` line
# in the comment block immediately above it.
#
# Convention (D-08-27): paired with scripts/check_dialyzer_ignore.sh.

set -euo pipefail

FILE=".credo.exs"
errors=0

# Find every `{Credo.Check..., false}` tuple line; assert the preceding
# comment block contains BOTH "# Reason:" AND "# Tracking:".
awk '
  /\{Credo\.Check\.[^,]+,\s*false\}/ {
    has_reason = 0
    has_tracking = 0
    # Walk backwards through comment-prefixed lines until first blank or non-comment.
    for (i = NR - 1; i >= 1 && lines[i] ~ /^\s*#/; i--) {
      if (lines[i] ~ /^\s*#\s*Reason:/)   has_reason = 1
      if (lines[i] ~ /^\s*#\s*Tracking:/) has_tracking = 1
    }
    if (!has_reason || !has_tracking) {
      printf "%s:%d  missing %s%s comment\n", FILENAME, NR,
        (has_reason ? "" : "# Reason: "),
        (has_tracking ? "" : "# Tracking: ")
      rc = 1
    }
  }
  { lines[NR] = $0 }
  END { exit rc + 0 }
' "$FILE" || errors=$((errors + 1))

if [[ $errors -gt 0 ]]; then
  echo "FAIL: credo disabled-check entries missing # Reason: or # Tracking: comments" >&2
  exit 1
fi

echo "OK: all credo suppressions are documented."
```

**CI integration shape** — runs as a step in the `credo_strict` job (`ci.yml:170-204`) BEFORE `mix credo --strict`. **Difference from dialyzer twin:** requires BOTH comments (D-08-19), not just `# Reason:` — the dual gate distinguishes permanent-house-style disables (Tracking: permanent) from Phase-9-tracking disables (Tracking: Phase 9 rename).

---

### `mailglass_admin/test/mailglass_admin/mix_config_test.exs` (test, modify)

**Analog (within file):** existing `evaluate_mailglass_dep/0` + `extract_function_body/3` helpers (lines 68-102). The REL-05 dep-pin regex anchor assertion (D-08-24) extends, not replaces, the existing tests.

**Existing helper to reuse** (`mix_config_test.exs:68-85`):
```elixir
defp evaluate_mailglass_dep do
  source = File.read!(@mix_exs)
  # Extract and eval the mailglass_dep/0 function body.
  # Plan 02 ships the function per 05-PATTERNS.md §mix.exs.
  {:ok, quoted} = Code.string_to_quoted(source)
  dep_fn_body = extract_function_body(quoted, :mailglass_dep, 0)

  assert dep_fn_body, "mailglass_dep/0 not found in #{@mix_exs}"

  {result, _binding} =
    Code.eval_quoted(dep_fn_body, [],
      requires: [],
      aliases: [],
      functions: [{Kernel, [==: 2]}]
    )

  result
end
```

**New test to add (D-08-24 — anchors the sed regex in `release-please.yml:62`):**
```elixir
describe "release-please sed-anchor regex stability (REL-05)" do
  # The sed step in .github/workflows/release-please.yml:62 anchors on the
  # literal `{:mailglass, "== <semver>"}` shape. Renaming the dep tuple, or
  # changing the version-pin format, would silently break the no-op fix
  # documented in CONTRIBUTING.md "Why we sed mix.exs after release-please runs".
  # This test fails LOUDLY before the workflow silently becomes a no-op again.
  test "MIX_PUBLISH=true emits dep tuple matching the sed regex literal" do
    System.put_env("MIX_PUBLISH", "true")
    source = File.read!(@mix_exs)

    # Same regex shape as `sed -E 's/\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}/.../'`
    sed_anchor = ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/
    assert Regex.match?(sed_anchor, source),
           """
           release-please.yml:62 sed step anchors on the literal
           `{:mailglass, "== <semver>"}` form. The current mix.exs no longer
           emits this form. Either update the sed regex (and CONTRIBUTING.md
           REL-05 section) or restore the literal pin shape.
           """
  end
end
```

**Why the test belongs here, not as a Credo check (D-08-24):** "Prefer the test path (lower friction; `mix_config_test.exs` already exists)." The test imports `@mix_exs` already (line 14) and follows the existing describe/setup pattern.

---

### `lib/mailglass/outbound.ex` (modify — swap callsites to AsyncAdapter)

**Analog (within file):** the current `Task.Supervisor.start_child` callsites at lines 437 and 607.

**Site 1 — `enqueue_task_supervisor/2`** (`outbound.ex:435-447`):
```elixir
case Repo.multi(multi) do
  {:ok, %{delivery: d}} ->
    # Spawn non-linked task under Mailglass.TaskSupervisor.
    # Tenancy process-dict MUST be re-stamped (not inherited) — D-21.
    Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
      Mailglass.Tenancy.with_tenant(tenant_id, fn ->
        try do
          case dispatch_by_id(d.id) do
```

**Replacement:**
```elixir
case Repo.multi(multi) do
  {:ok, %{delivery: d}} ->
    # AsyncAdapter dispatch (D-08-11). TaskSupervisor impl is prod default;
    # Inline impl is test default. Tenancy re-stamp inside the closure works
    # for both paths (D-08-15) — Inline runs sync under caller, TaskSupervisor
    # runs in fresh process; with_tenant/2 stamps the executing process
    # either way.
    Mailglass.Outbound.AsyncAdapter.dispatch(fn ->
      Mailglass.Tenancy.with_tenant(tenant_id, fn ->
        try do
          case dispatch_by_id(d.id) do
```

**Site 2 — `enqueue_batch_jobs/1`** (`outbound.ex:606-628`): identical swap. The `Enum.each(deliveries, fn %Delivery{...} -> Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn -> ... end) end)` becomes `Enum.each(deliveries, fn %Delivery{...} -> Mailglass.Outbound.AsyncAdapter.dispatch(fn -> ... end, []) end)`.

**Verify in plan:** post-publish line drift may have shifted the line numbers — search by callsite signature `Task.Supervisor.start_child(Mailglass.TaskSupervisor`. There are exactly 2 call sites in `lib/` per `grep` confirmation.

---

### `test/support/{mailer,data,webhook,admin}_case.ex` (modify — extract probe + AsyncAdapter inline default)

**Analog (within `mailer_case.ex`):** existing `cond do oban_tagged? ... -> ... ; true -> ... end` block at lines 142-177 (governs which async-dispatch posture the test gets).

**MailerCase changes** (per D-08-12):
1. Replace the duplicated probe block at `mailer_case.ex:94-101` with `Mailglass.TestSupport.CitextProbe.run([])`
2. Default test posture: `Application.put_env(:mailglass, :async_adapter_impl, Mailglass.Outbound.AsyncAdapter.Inline)` (or whatever final env-key disambiguation lands per D-08-11 confirmation)
3. `set_mailglass_global` opt-in flips to `:task_supervisor` impl + `Sandbox.mode(repo, {:shared, self()})` + forces `async: false`
4. Update moduledoc (`mailer_case.ex:30-39`) — replace the "## Async tests and deliver_later/2" section with the new AsyncAdapter rule per D-08-12

**Existing snapshot/restore pattern to follow** (`mailer_case.ex:122-125, 179-191`):
```elixir
# Snapshot the pre-setup :async_adapter value for faithful restore in on_exit (HI-01 fix).
# If we unconditionally wrote :oban on restore, adopters who boot with :task_supervisor
# would have it silently overwritten after every test. Snapshot before any mutation below.
prior_async_adapter = Application.get_env(:mailglass, :async_adapter)
...
on_exit(fn ->
  ...
  if prior_async_adapter != nil do
    Application.put_env(:mailglass, :async_adapter, prior_async_adapter)
  else
    Application.delete_env(:mailglass, :async_adapter)
  end
  ...
end)
```
Apply the **identical snapshot/restore pattern** to whatever new env-key the AsyncAdapter resolution lands on (D-08-11 + HI-01). The snapshot-before-mutate / restore-on-exit posture is non-negotiable.

**DataCase changes** (per D-08-10):
- Replace `data_case.ex:62-69` probe loop with `Mailglass.TestSupport.CitextProbe.run([])`. Keep the surrounding moduledoc/comment (lines 38-61) — it documents *why* the probe exists; that documentation is still load-bearing.

**WebhookCase changes** (per D-08-10):
- Add `Mailglass.TestSupport.CitextProbe.run([])` to the `setup` block immediately after `start_owner!` (currently no probe in this file; the implicit assumption was inheritance from `MailerCase`, which DOES probe, but `WebhookCase.setup tags` runs its own setup ahead of MailerCase's).

**AdminCase changes** (per D-08-10):
- Inherits via `use Mailglass.MailerCase` (`admin_case.ex:29`) — **no direct change required** since MailerCase will run the probe. Verify by tracing the `using opts do ... use Mailglass.MailerCase, unquote(opts) ... end` macro expansion at plan time.

---

### `.credo.exs` (modify — strict + disabled_checks baseline)

**Analog (within file):** existing `extra_checks` list (lines 1-58) shows the comment+config tuple shape. The Oban-pattern disable list is new but mirrors the shape.

**Existing `strict: false` block** (`.credo.exs:60-83`):
```elixir
%{
  configs: [
    %{
      name: "default",
      # `strict: true` would fail the build on ~169 lower-priority software
      # design / readability / refactoring suggestions that pre-date Phase
      # 07.1 — out of scope for v0.1.0. Custom Credo checks (12 in
      # credo_checks/) remain mandatory at default priority. Re-enable
      # strict in a post-publish cleanup phase.
      strict: false,
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      requires: ["./credo_checks/*.ex"],
      ...
      checks: extra_checks ++ [{Credo.Check.Consistency.ExceptionNames, false}],
      extra_checks: extra_checks
    }
  ]
}
```

**Replacement (per D-08-16, D-08-18, D-08-21):**
```elixir
strict: true,
files: %{
  # D-08-21: included stays ["lib/", "test/"]; do NOT add credo_checks/
  # (Credo would lint its own checks, producing false positives).
  included: ["lib/", "test/"],
  excluded: []
},
requires: ["./credo_checks/*.ex"],
checks:
  extra_checks ++
    [
      {Credo.Check.Consistency.ExceptionNames, false},

      # Reason: stylistic; conflicts with deliberate `apply/3` use in adapter dispatch.
      # Tracking: permanent.
      {Credo.Check.Refactor.Apply, false},

      # Reason: macro-heavy library; `quote do` blocks in `Mailable`/`MailglassAdmin.Router`
      # are intentionally long for `use` injection.
      # Tracking: permanent.
      {Credo.Check.Refactor.LongQuoteBlocks, false},

      # Reason: low signal in a 33k-LOC codebase with mixed nesting depth.
      # Tracking: permanent (Oban posture).
      {Credo.Check.Readability.AliasOrder, false},

      # Reason: 102 findings, 99% in test files where nested-module-aliases are
      # deliberate scoping.
      # Tracking: permanent.
      {Credo.Check.Design.AliasUsage, false},

      # Reason: explicit `try`/`rescue` in `webhook/providers/sendgrid.ex` and
      # `webhook/plug.ex` documents the rescue-and-rewrap contract for
      # `Mailglass.SignatureError`.
      # Tracking: permanent (house style).
      {Credo.Check.Readability.PreferImplicitTry, false}
    ]
```

**Comment-convention contract (D-08-19):** every disabled-check tuple MUST be preceded by `# Reason:` AND `# Tracking:` lines. `scripts/check_credo_suppressions.sh` validates this.

**Inline suppression for `is_error?/1` (D-08-20):**
```elixir
# In the source file — NOT in .credo.exs:
# credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames -- Tracking: Phase 9 rename to error?/1
def is_error?(...)
```

---

### `mix.exs` + `mailglass_admin/mix.exs` (modify — add :dialyzer config + remove CLAUDE.md from docs)

**Analog (within file):** existing `docs/0` block at `mix.exs:222-263` for `:extras` + `:groups_for_extras` patterns. No existing `:dialyzer` config block in `mix.exs` — the dialyzer dep is declared at line 123 but no `:dialyzer` project-config block exists.

**`docs/0` extras list change** (`mix.exs:247-263`):
```elixir
extras: [
  "README.md",
  "guides/getting-started.md",
  ...
  "CODE_OF_CONDUCT.md",
  "CLAUDE.md"          # REMOVE this line (REL-02)
],
groups_for_extras: [
  Overview: ["README.md", "CLAUDE.md"],   # change to: ["README.md"]
  ...
]
```

Also drop `"CLAUDE.md"` from `skip_undefined_reference_warnings_on:` (`mix.exs:228-233`) once it's no longer in `extras:`.

**`:dialyzer` config block to ADD to project keyword list (per D-08-01, D-08-04, D-08-06):**
```elixir
def project do
  [
    app: :mailglass,
    ...
    aliases: aliases(),
    dialyzer: dialyzer(),
    ...
  ]
end

defp dialyzer do
  [
    # D-08-01: :no_opaque + :no_match kill the Elixir 1.18 opaque-type
    # cascade (elixir-lang/elixir#14837). :error_handling, :missing_return,
    # :underspecs deferred to v0.3 per D-08-07.
    flags: [:error_handling, :missing_return, :no_opaque, :no_match, :underspecs],
    # D-08-03: ignore_file_strict pins to {file, short_description} tuples
    # (stable across line-number drift). D-08-04: list_unused_filters fails
    # CI loudly when a future fix invalidates an existing ignore (prevents
    # silent drift).
    ignore_file: ".dialyzer_ignore.exs",
    list_unused_filters: true
  ]
end
```

**Apply identical block to `mailglass_admin/mix.exs`** (per D-08-02 — separate ignore file, separate PLT). Same `:extras` / `:groups_for_extras` change too — `CLAUDE.md` removed.

**Aliases rename (REL-03)** (`mix.exs:130-186, 42-51`):
```elixir
# Existing:
"verify.phase_02": [...]
# New (REL-03):
"verify.persistence": [<same body>],
"verify.phase_02": [<same body>],  # deprecated pass-through, one cycle
```
Apply to all `verify.phase_NN` aliases per REL-03 mapping. Update `preferred_cli_env` (lines 42-51) to include both old and new keys for one cycle.

---

### `.github/workflows/ci.yml` (modify — Tests/Credo/Dialyzer hardening)

**Analog (within file):** existing Tests step (lines 155-168), Credo step (lines 195-204), Dialyzer step (lines 251-260) — all currently advisory.

**Tests gate flip (D-08-13 — 3-PR rollout, PR-A → PR-B → PR-C):**

PR-A (`ci.yml:157-168` unchanged) — keeps `continue-on-error: true`, ships AsyncAdapter + CitextProbe + CaseTemplate fixes.

PR-B — adds NEW `tests-strict` lane next to existing Tests lane:
```yaml
tests_strict:
  name: Tests Strict (advisory, ~1 week soak)
  runs-on: ubuntu-latest
  ...
  steps:
    ...
    - name: Run tests strict (advisory)
      # PR-B: NOT marked required. Runs in parallel with the existing Tests
      # lane during the ~1 week soak (≥5 random-seed runs) before PR-C
      # flips the existing lane to halt-on-failure.
      run: mix test --warnings-as-errors
```

PR-C — flip existing lane (`ci.yml:167`): `continue-on-error: true` → `continue-on-error: false`; delete the advisory `tests_strict` lane; **branch-protection update is `szTheory`-only — flag in plan output**.

**Credo step transform** (`ci.yml:195-204`):
```yaml
# BEFORE:
- name: Run Credo (advisory until post-publish cleanup)
  run: mix credo --mute-exit-status

# AFTER (D-08-16, D-08-19):
- name: Validate credo suppressions documented
  run: bash scripts/check_credo_suppressions.sh
- name: Run Credo (strict)
  run: mix credo --strict
```
And `continue-on-error: false` (which is the default — drop any lingering true).

**Dialyzer step transform** (`ci.yml:251-260`):
```yaml
# BEFORE:
- name: Run Dialyzer (advisory until post-publish cleanup)
  continue-on-error: true
  run: mix dialyzer --halt-exit-status

# AFTER (D-08-09 + D-08-05):
- name: Validate dialyzer ignore-file documented
  run: bash scripts/check_dialyzer_ignore.sh
- name: Run Dialyzer
  # Default mix dialyzer halts on warnings (Dialyxir 1.4.7 verified — D-08-09).
  # --halt-exit-status does NOT exist as a Dialyxir flag.
  # --ignore-exit-status was the advisory flag, REMOVED here.
  run: mix dialyzer
```

**PLT cache key fix** (per D-08-06) — locate the existing cache step in the dialyzer job and ensure key includes `${{ matrix.otp }}`:
```yaml
# BEFORE (likely):
key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}

# AFTER:
key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('**/mix.lock') }}
```

---

### `.github/workflows/publish-hex.yml` + `post-publish-smoke.yml` (modify — trigger swap)

**Analog (within file):** existing `on: workflow_run:` block (`publish-hex.yml:3-7`) and the matching `if:` gate at lines 38-43.

**Existing trigger** (`publish-hex.yml:3-28`):
```yaml
on:
  workflow_run:
    workflows: ["release-please"]
    types:
      - completed
  workflow_dispatch:
    inputs:
      tag: ...
```

**Replacement (per REL-01):**
```yaml
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag: ...
```

And drop the `workflow_run` `if:` gate at lines 38-43 (the new trigger fires on actual release publication, not workflow completion). Add `mix hex.info` pre-check inside the publish job as an additional idempotency guard:
```yaml
- name: Skip if version already on Hex
  run: |
    if mix hex.info "$PACKAGE" "$VERSION" 2>/dev/null | grep -q "Released:"; then
      echo "Version $VERSION already on Hex — skipping (idempotency guard)."
      exit 0
    fi
```

**Apply identical trigger swap to `post-publish-smoke.yml`** (REL-01 sibling).

---

### `.github/workflows/release-please.yml` (modify — sed-step hardening)

**Analog (within file):** existing sed block at lines 38-77.

**Existing sed step** (`release-please.yml:60-62`):
```bash
# Rewrite the strict pin literal. Match `== <semver>` inside the
# {:mailglass, "..."} tuple body. Multi-line .exs is fine — sed -E
# handles the regex on a per-line basis.
sed -i -E 's/\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}/{:mailglass, "== '"$NEW_VERSION"'"}/' mailglass_admin/mix.exs
```

**Hardening additions (D-08-23):**

1. **shellcheck step** before the sed runs (in same workflow):
```yaml
- name: Shellcheck the sync block
  run: shellcheck .github/workflows/release-please.yml
  # Or extract the run-block to scripts/sync_mailglass_dep_pin.sh and shellcheck that.
```

2. **exit-1 guard** if regex matches zero lines:
```bash
# Replace the existing sed line with:
matches=$(grep -cE '\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}' mailglass_admin/mix.exs || true)
if [ "$matches" -eq 0 ]; then
  echo "ERROR: sed anchor regex matched zero lines in mailglass_admin/mix.exs." >&2
  echo "The dep tuple shape may have been renamed — see CONTRIBUTING.md REL-05 section." >&2
  exit 1
fi
sed -i -E 's/\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}/{:mailglass, "== '"$NEW_VERSION"'"}/' mailglass_admin/mix.exs
```

3. **Bash-loop generalization** (D-08-23 fourth point — pre-stage for v0.5+ `mailglass_inbound`):
```bash
# Future-proofs adding mailglass_inbound at v0.5 — one-line config change.
PINS=(
  "mailglass_admin/mix.exs:mailglass"
  # "mailglass_inbound/mix.exs:mailglass"   # uncomment at v0.5
)

for entry in "${PINS[@]}"; do
  path="${entry%:*}"
  dep="${entry##*:}"
  matches=$(grep -cE "\{:${dep}, \"== [0-9]+\.[0-9]+\.[0-9]+\"\}" "$path" || true)
  ...
done
```

4. **Fixture test** (D-08-23 second point) — `test/fixtures/release_please_sed_test.sh` runs the same sed against a fixture mix.exs and asserts the diff. Skeleton:
```bash
#!/usr/bin/env bash
# Regression test for the release-please sed step.
set -euo pipefail
TMP=$(mktemp -d)
cp test/fixtures/mix.exs.before "$TMP/mix.exs"
NEW_VERSION="0.99.99"
sed -i -E "s/\{:mailglass, \"== [0-9]+\.[0-9]+\.[0-9]+\"\}/{:mailglass, \"== $NEW_VERSION\"}/" "$TMP/mix.exs"
diff -u test/fixtures/mix.exs.after "$TMP/mix.exs"
```

---

### `.github/workflows/advisory-matrix.yml` (modify — DB setup + 1.17 compile fixes)

**Analog (within other workflow):** `ci.yml:117-156` Tests-job DB setup pattern.

**DB setup pattern from `ci.yml:130-156`:**
```yaml
services:
  postgres:
    image: postgres:16-alpine
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
env:
  MIX_ENV: test
  POSTGRES_HOST: localhost
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
steps:
  ...
  - name: Wait for postgres + create test DB
    env:
      PGPASSWORD: postgres
    run: |
      until pg_isready -h localhost -U postgres; do sleep 1; done
      mix ecto.create -r Mailglass.TestRepo --quiet
```

**Apply this exact services + env + wait-for-postgres pattern to `advisory-matrix.yml`** (REL-06). For the 1.17 compile fix — flag in plan: locate the failing compile error from latest advisory-matrix run logs; the fix is likely a `Code.ensure_loaded?/1` guard around a 1.18-only stdlib call (e.g., `Macro.Env.lookup_aliases/1` — was 1.18+).

---

### `CONTRIBUTING.md` (modify — append REL-05 section)

**Analog (within file):** existing 32-line scaffold sections (`Local Setup`, `Development Workflow`, `Commit Guidelines`, `PR Expectations`).

**Existing structure** (`CONTRIBUTING.md:1-32`):
```markdown
# Contributing to Mailglass

We welcome contributions! Mailglass is developed using a phase-based roadmap...

## Local Setup
1. Clone the repo.
...

## Development Workflow
...

## Commit Guidelines
...

## PR Expectations
...
```

**New section to append (per D-08-25):**
```markdown
## Why we sed mix.exs after release-please runs

Release Please's `extra-files` generic updater silently no-ops on a `mix.exs`
already managed by the `elixir` release-type. The `{:mailglass, "== <ver>"}`
pin in `mailglass_admin/mix.exs` therefore never gets rewritten by the action
itself.

`.github/workflows/release-please.yml` syncs the pin via a `sed` step on the
release-please PR branch after the action runs. This is the **steady-state
mitigation** (decided in Phase 8, REL-05) rather than authoring a TypeScript
plugin (which would violate the "no Node toolchain anywhere" engineering DNA)
or refactoring to `version.exs` (which adds Hex tarball + `Code.eval_file`
load-order risk).

**Recursion-safety guarantee:** the sync push uses `GITHUB_TOKEN`, which by
GitHub's anti-recursion guarantee does NOT trigger further workflow runs.

**Sed-anchor stability:** `mailglass_admin/test/mailglass_admin/mix_config_test.exs`
asserts the dep tuple in `mailglass_admin/mix.exs` matches the literal
`{:mailglass, "== <semver>"}` shape the sed regex anchors on. Any future
rename of the dep tuple form will fail this test loudly — update the sed
regex (in `release-please.yml:62`) and this section together.

**Pointer:** see `.planning/todos/done/2026-04-26-release-please-extra-files-no-op-on-managed-mix-exs.md`
for the empirical observation history.
```

---

### `guides/*.md` (mechanical strip pass)

**No analog needed** — strip every `D-NN`/`LINT-NN` token from public guides; the new `mix mailglass.docs.check` task gates against future leaks. List of files to scan: every `.md` file in `mix.exs:247-263` `:extras` list except `CLAUDE.md` (removed), `MAINTAINING.md` (internal), `CODE_OF_CONDUCT.md` (no IDs).

---

## Shared Patterns

### Brand-voice errors

**Source:** `lib/mix/tasks/mailglass.publish.check.ex:46-49,53-54`
**Apply to:** `lib/mix/tasks/mailglass.docs.check.ex` and any new `Mix.raise/1` callsites.

```elixir
Mix.raise("Delivery blocked: <specific reason>")
```

The `"Delivery blocked: ..."` prefix is established mailglass-Mix-task voice. Per CLAUDE.md "Brand & Voice" — errors are specific and composed: "Delivery blocked: recipient is on the suppression list" — never "Oops!".

---

### Comment-convention enforcement (D-08-27)

**Source:** `lib/mailglass/optional_deps.ex:21-33` (`## Gateway Modules` enumeration shape)
**Apply to:** `.dialyzer_ignore.exs` (`# Reason: ...`), `.credo.exs` `:disabled_checks` entries (`# Reason: ...` + `# Tracking: ...`)

Each suppression is a public commitment about a known-unfixable type/style signature, just as `Mailglass.Error{:type}` is a public commitment about a closed atom set ("Errors as a public API contract"). Validated by the paired shell scripts.

---

### Snapshot-then-restore for Application env mutations (HI-01)

**Source:** `test/support/mailer_case.ex:122-125, 179-191`
**Apply to:** every CaseTemplate that mutates `Application.put_env(:mailglass, :async_adapter*, ...)` for the new AsyncAdapter behaviour.

```elixir
# 1. Snapshot pre-setup value BEFORE any mutation
prior = Application.get_env(:mailglass, :KEY)

# 2. Mutate as needed for this test
Application.put_env(:mailglass, :KEY, value)

# 3. on_exit: restore to prior (or delete if prior was nil)
on_exit(fn ->
  if prior != nil do
    Application.put_env(:mailglass, :KEY, prior)
  else
    Application.delete_env(:mailglass, :KEY)
  end
end)
```
Adopters who boot with custom env values must not have those silently overwritten by `on_exit` cleanup.

---

### `use Boundary, classify_to: Mailglass` for new Mix tasks

**Source:** `lib/mix/tasks/mailglass.publish.check.ex:1-2`
**Apply to:** `lib/mix/tasks/mailglass.docs.check.ex`

```elixir
defmodule Mix.Tasks.Mailglass.Docs.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "..."
  @moduledoc """
  ...
  """

  use Mix.Task
  ...
end
```
Boundary classification keeps Mix tasks attached to the `Mailglass` boundary so the existing boundary check picks them up.

---

### Behaviour + impl-pair file layout

**Source:** `lib/mailglass/clock.ex` (single-file pattern with `Mailglass.Clock.System` + `Mailglass.Clock.Frozen` co-located OR split — verify which the project actually uses).
**Apply to:** `lib/mailglass/outbound/async_adapter.ex` + `lib/mailglass/outbound/async_adapter/task_supervisor.ex` + `lib/mailglass/outbound/async_adapter/inline.ex`.

The user's `<established_patterns>` list in CONTEXT.md confirms `Mailglass.Clock` is the exact template. Recommend matching whichever layout (single-file vs split-file) Clock uses — **verify in plan** by listing `lib/mailglass/clock*` (single file at `clock.ex` confirmed during analysis; impls likely live alongside or in `lib/mailglass/clock/`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `scripts/check_dialyzer_ignore.sh` | shell-gate (CI) | batch | First shell-script gate in repo. Use the skeleton above + reference Oban's `.formatter.exs`-validation scripts as ecosystem prior art (cited in CONTEXT.md). The paired sibling script (`check_credo_suppressions.sh`) shares the shape. |
| `scripts/check_credo_suppressions.sh` | shell-gate (CI) | batch | Same as sibling — first of its kind. |
| `.dialyzer_ignore.exs` (root, NEW) | config | n/a | First creation. Format per Dialyxir 1.4.7 `--format ignore_file_strict` (D-08-03) — `[{file, short_description}]` tuples. Each tuple preceded by a `# Reason: <one-line>` comment per D-08-05. Initial cap of ≤15 entries per D-08-07. |
| `mailglass_admin/.dialyzer_ignore.exs` (NEW) | config | n/a | Mirrors root sibling per D-08-02 (separate PLT). |

For all four files, **pull from the ecosystem prior art** cited in CONTEXT.md `<canonical_refs>`:
- Oban `mix.exs` + `.credo.exs` (Dialyzer flags + strict-with-disables Credo)
- Ash Framework `mix.exs` (`:no_opaque, :no_match` flag)
- Dialyxir 1.4.7 docs (flag verification, ignore-file format)

---

## Metadata

**Analog search scope:** `lib/`, `test/support/`, `test/mailglass/`, `mailglass_admin/test/`, `lib/mix/tasks/`, `.github/workflows/`, `.credo.exs`, `mix.exs`
**Files scanned:** ~30 directly read; ~80 traversed via `find` + `grep`
**Pattern extraction date:** 2026-04-26
