# Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 6 (2 modify, 4 create)
**Analogs found:** 6 / 6 (all exact or in-repo role-match)

All file:line facts below are verified against live source this session and corroborate RESEARCH.md `## Source Fact Verification`. Per the locked decisions (D-01..D-14), this map proposes NO alternatives — it pins each new/modified file to its analog and the exact insertion/modification site.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/installer/apply.ex` (MODIFY) | service (installer core) | transform / request-response | itself — `validate_preflight/1` + `Apply.run/2` (in-file) | exact (edit in place) |
| `lib/mix/tasks/mailglass.install.ex` (MODIFY) | mix task (CLI shell) | request-response | itself — existing `format_error/1` clause family | exact (clause-add) |
| `lib/mix/tasks/mailglass.doctor.ex` (CREATE) | mix task (CLI shell) | request-response (static scan) | `mailglass_inbound/.../mailglass.inbound.doctor.ex` (shell shape) + `lib/mix/tasks/mail.doctor.ex` (Boundary) | exact composite |
| `lib/mailglass/installer/doctor.ex` (CREATE) | service (pure runner) | file-I/O / transform | `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` (shape only) + `apply.ex` `validate_preflight/1` (scan logic) | exact composite |
| `test/mailglass/install/install_fail_closed_test.exs` (CREATE) | test | transform | `test/mailglass/install/install_idempotency_test.exs` | exact |
| `test/mailglass/install/mailglass_doctor_test.exs` (CREATE) | test | transform | `test/mailglass/install/install_idempotency_test.exs` | exact |

**Critical divergence baked into D-09 (do not miss):** the inbound doctor is the structural template ONLY. Its detection mechanism (`Mix.Task.run("app.start")` + `Code.ensure_loaded?` / `function_exported?` runtime reflection) MUST NOT be copied. The new doctor is a STATIC SOURCE SCAN (`File.read!` + `String.contains?`) so it runs offline inside the install-fixture harness, which never boots the host endpoint.

## Pattern Assignments

### `lib/mailglass/installer/apply.ex` (MODIFY — service, transform)

**Analog:** itself (edit in place). Two edits in ONE task (Pitfall 2 — they must land together).

**EDIT 1 — `validate_preflight/1` returns a tuple instead of warning-and-discarding.**
Current site (apply.ex:47-76), the exact block D-01 replaces is apply.ex:64-73:

```elixir
# CURRENT (apply.ex:64-73) — warns then discards the result:
if String.contains?(stripped_contents, "plug Plug.Parsers") and
     not String.contains?(stripped_contents, "body_reader") do
  Mix.shell().info([
    :yellow,
    "![warning] Found an existing `plug Plug.Parsers` in #{endpoint_path} without a `:body_reader`.\n",
    :reset,
    ...
  ])
end
```

Replace with the fail-closed shape from RESEARCH.md Pattern 1 (D-01/D-04). **Every branch must return `:ok` or `{:error, ...}` explicitly** — the current implicit `nil` returns (no-endpoint-file branch at `if File.exists?(endpoint_path)` line 52, and the no-conflict `else`) will NOT match `with :ok <-` (Pitfall 2):

```elixir
# TARGET shape (D-01/D-04) — note --force is read from opts the fn already receives:
if File.exists?(endpoint_path) do
  contents = File.read!(endpoint_path)
  # ... existing strip-managed-block logic (apply.ex:55-62) is UNCHANGED ...
  if String.contains?(stripped_contents, "plug Plug.Parsers") and
       not String.contains?(stripped_contents, "body_reader") do
    if Keyword.get(opts, :force, false) do
      :ok
    else
      {:error, {:unmanaged_parser_conflict, endpoint_path}}
    end
  else
    :ok
  end
else
  :ok                       # no-endpoint-file branch MUST return :ok
end
```

The conflict predicate (apply.ex:64-65), the otp_app/endpoint-path derivation (apply.ex:48-50, reuses `Plan.detect_otp_app()`), and the managed-block strip (apply.ex:55-62 via `Templates.endpoint_webhook_block_start/end`) are all REUSED VERBATIM. Do not redesign them.

**EDIT 2 — thread into `Apply.run/2`'s `with` chain (D-02).** Current site apply.ex:32-36:

```elixir
# CURRENT (apply.ex:32-36) — bare statement, return discarded:
    validate_preflight(opts)

    with {:ok, manifest} <- Manifest.load(manifest_path),
         {:ok, operations, next_manifest} <- apply_operations(plan, manifest, opts),
         :ok <- maybe_write_manifest(next_manifest, manifest_path, dry_run?) do
```

```elixir
# TARGET (D-02) — first link of the with; preserves the @spec at apply.ex:27
#   {:ok, result_map()} | {:error, term()}:
    with :ok <- validate_preflight(opts),
         {:ok, manifest} <- Manifest.load(manifest_path),
         {:ok, operations, next_manifest} <- apply_operations(plan, manifest, opts),
         :ok <- maybe_write_manifest(next_manifest, manifest_path, dry_run?) do
```

No `@spec` change needed — `{:error, {:unmanaged_parser_conflict, _}}` is already covered by `{:error, term()}` (apply.ex:27).

---

### `lib/mix/tasks/mailglass.install.ex` (MODIFY — mix task, request-response)

**Analog:** itself — the existing `format_error/1` clause family (mailglass.install.ex:125-147).

**Single edit (D-03):** add one `format_error/1` clause for the actionable message, inserted BEFORE the catch-all at line 147. The error already reaches `Mix.raise` via the existing rail at mailglass.install.ex:61-62 (no change there) — that produces the non-zero exit:

```elixir
# EXISTING RAIL (mailglass.install.ex:61-62) — UNCHANGED, already yields non-zero exit:
      {:error, reason} ->
        Mix.raise(format_error(reason))

# EXISTING clause family to mirror (mailglass.install.ex:126-147), e.g.:
  defp format_error({:manifest_read_failed, path, reason}),
    do: "Installation blocked: cannot read manifest #{path} (#{inspect(reason)})"
  ...
  defp format_error(other), do: "Installation blocked: #{inspect(other)}"   # line 147 — catch-all
```

```elixir
# NEW clause (insert before the line-147 catch-all). Wording is Claude's Discretion but
# MUST name: the endpoint path, the silent-401 risk, the body_reader fix, and --force:
  defp format_error({:unmanaged_parser_conflict, endpoint_path}) do
    """
    Installation blocked: #{endpoint_path} has a `plug Plug.Parsers` without a `:body_reader`.

    Mailglass needs to read the raw request body to verify webhook signatures. With an
    unmanaged parser ahead of it, the body is consumed before Mailglass sees it and every
    inbound webhook silently returns 401 in production.

    Fix one of these, then re-run `mix mailglass.install`:
      1. Add `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` to your
         `plug Plug.Parsers` in #{endpoint_path}, OR
      2. Re-run with `--force` to let Mailglass insert its managed parser block ABOVE yours
         (Plug runs parsers in source order, so the managed body_reader wins).
    """
  end
```

**Do NOT** route through `maybe_raise_conflict_error/1` (mailglass.install.ex:108-112) — that is the distinct sidecar-conflict-count path (RESEARCH.md Anti-Pattern; Landmine 3). The new error rides the `{:error, reason}` → `format_error/1` rail only.

The task already declares `--force` in the OptionParser strict spec (mailglass.install.ex:33: `strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean]`) and already carries `use Boundary, classify_to: Mailglass` (line 2) — no change to either.

---

### `lib/mix/tasks/mailglass.doctor.ex` (CREATE — mix task, request-response/static scan)

**Analog (composite):** `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` for the shell/exit-code shape, AND `lib/mix/tasks/mail.doctor.ex` for the Boundary classification the inbound task deliberately omits.

**Boundary header — copy from `mail.doctor.ex:1-4` (NOT the inbound doctor, which omits it):**
```elixir
defmodule Mix.Tasks.Mailglass.Doctor do
  use Boundary, classify_to: Mailglass    # mail.doctor.ex:2 — REQUIRED; core runs the :boundary compiler (Pitfall 5)
  use Mix.Task
```
The inbound doctor's header comment (mailglass.inbound.doctor.ex:1-7) explains exactly WHY it omits `use Boundary` (inbound doesn't run the boundary compiler) — that reasoning does NOT apply to core, so the new task MUST classify.

**Shell + exit-code shape — copy STRUCTURE from `mailglass.inbound.doctor.ex:39-105`, but DROP the `app.start`:**
```elixir
# inbound run/1 (mailglass.inbound.doctor.ex:40-62) — mirror EXCEPT lines 51-53:
  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} =
      OptionParser.parse(argv, strict: [format: :string, verbose: :boolean])  # trim to INSTALL-03 needs
    validate_cli!(opts, rest, invalid)

    # DO NOT COPY inbound lines 51-53 (`Mix.Task.run("app.start")`). D-09: static scan, no boot.
    result = Mailglass.Installer.Doctor.run([])

    result |> render_output(opts) |> Mix.shell().info()
    exit({:shutdown, exit_code(result.summary, opts)})
  end
```

**Three-state exit-code mapping — copy `exit_code/2` from inbound (mailglass.inbound.doctor.ex:96-105), D-10 (0/1/2):**
```elixir
  defp exit_code(summary, _opts) do
    cond do
      Map.get(summary, :cannot_diagnose, 0) > 0 -> 2   # endpoint.ex missing / app not detectable
      Map.get(summary, :fail, 0) > 0 -> 1              # CachingBodyReader absent — the CI non-zero signal
      true -> 0                                        # wired correctly
    end
  end
```

**CLI-misuse validation — mirror `validate_cli!/3` (mailglass.inbound.doctor.ex:67-84).** `Mix.raise` is reserved for bad flags/positional/format ONLY; check findings flow through the exit code, never `Mix.raise` (inbound lines 64-66 comment — otherwise exit 2 is unreachable).

**Flag surface (Claude's Discretion / D's discretion note):** a plain human-readable check + non-zero exit satisfies INSTALL-03. Mirror inbound's `--format json` / `--verbose` only if cheap; do NOT over-build. `--strict` is unnecessary here (there are no warn-state findings in a binary wired/unwired/cannot-diagnose scan).

---

### `lib/mailglass/installer/doctor.ex` (CREATE — service, file-I/O/transform)

**Module name:** `Mailglass.Installer.Doctor` (RESEARCH.md recommendation — the scan reuses `Plan`/`Templates`, so it co-locates in the installer namespace; Boundary-classified to `Mailglass` automatically via the namespace).

**Analog (composite):** `MailglassInbound.Internal.Doctor` for the RESULT SHAPE only; `apply.ex` `validate_preflight/1` for the SCAN LOGIC.

**Result + finding shape — copy the contract from inbound (internal/doctor.ex:41-50):**
```elixir
  @type finding :: %{
          check: atom(), status: :pass | :warn | :fail, title: String.t(),
          observed: String.t(), remediation: String.t(), evidence: map()
        }
  @type result :: %{summary: map(), findings: [finding()]}
  # run/1 returns %{summary: %{pass, warn, fail, cannot_diagnose}, findings: [...]}
```

**Summarize — copy the cannot_diagnose-counted-separately pattern (internal/doctor.ex:409-424).** A cannot-diagnose finding is counted under `:cannot_diagnose`, NOT `:fail`, so exit 2 stays distinct from exit 1:
```elixir
  defp summarize(findings) do
    base = %{pass: 0, warn: 0, fail: 0, cannot_diagnose: 0}
    Enum.reduce(findings, base, fn finding, acc ->
      if Map.get(finding[:evidence] || %{}, :cannot_diagnose) do
        Map.update!(acc, :cannot_diagnose, &(&1 + 1))
      else
        Map.update!(acc, finding.status, &(&1 + 1))
      end
    end)
  end
```

**Scan logic — STATIC, copy the path-derivation + predicate from `apply.ex validate_preflight/1` (apply.ex:48-65), NOT inbound's runtime reflection.** RESEARCH.md Pattern 3:
```elixir
  # reuse the EXACT app/endpoint derivation from apply.ex:48-50:
  otp_app = Mailglass.Installer.Plan.detect_otp_app()           # plan.ex:86-97 (cwd mix.exs regex, falls back :my_app)
  endpoint_path = "lib/#{otp_app}_web/endpoint.ex"

  cond do
    not File.exists?(endpoint_path) -> cannot_diagnose finding  # -> summary.cannot_diagnose -> exit 2
    wired?(File.read!(endpoint_path)) -> pass finding           # -> exit 0
    true -> fail finding (CachingBodyReader absent)             # -> exit 1
  end

  # wired? = contains "body_reader" AND "Mailglass.Webhook.CachingBodyReader",
  #          optionally gated on the managed markers (see below).
```

**Greppable anchors — use `Templates` accessors, never hardcoded strings (RESEARCH.md Don't-Hand-Roll):**
```elixir
  Mailglass.Installer.Templates.endpoint_webhook_block_start()  # templates.ex:73 -> "# mailglass:start endpoint_webhook_parser"
  Mailglass.Installer.Templates.endpoint_webhook_block_end()    # templates.ex:79 -> "# mailglass:end endpoint_webhook_parser"
  # the managed body block (templates.ex:86-94) contains the literal
  # `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` to match against.
```

**MUST NOT copy from inbound (internal/doctor.ex):** the runtime reflection (`Code.ensure_loaded?`, `function_exported?`), the router/mailbox/signing-key checks, and any `Application.get_env`-driven boot dependency (Pitfall 3 / D-09). This runner reads only `mix.exs` (via `detect_otp_app`) + `endpoint.ex` off disk.

---

### `test/mailglass/install/install_fail_closed_test.exs` (CREATE — test)

**Analog:** `test/mailglass/install/install_idempotency_test.exs`. Header copies idempotency_test.exs:1-4:
```elixir
defmodule Mailglass.Install.FailClosedTest do
  use ExUnit.Case, async: false                        # idempotency_test.exs:2
  import Mailglass.Test.InstallerFixtureHelpers          # idempotency_test.exs:4
```

**Seeding (D-11, mandatory — RESEARCH.md "seeding footgun"):** after `new_fixture_root!/1` the default endpoint is bare (`host_endpoint/0`, installer_fixture_helpers.ex:263-269 emits only `use Phoenix.Endpoint, otp_app: :example`, NO parser). Overwrite `lib/example_web/endpoint.ex` via `File.write!` with a `plug Plug.Parsers` that has NO `body_reader` AND sits OUTSIDE the managed markers (seed body in RESEARCH.md lines 207-216). Otp_app is `:example` → path `lib/example_web/endpoint.ex`.

**INSTALL-01 (tuple-level, D-12 — match the struct/tuple, NEVER the message string):** call `Apply.run/2` DIRECTLY inside `File.cd!(fixture_root, fn -> ... end)` (mirror the helper's own `File.cd!` + `Plan.build` + `Apply.run` at installer_fixture_helpers.ex:31-44) and pattern-match:
```elixir
    File.cd!(fixture_root, fn ->
      plan = Mailglass.Installer.Plan.build([], %{oban_available?: ...})
      assert {:error, {:unmanaged_parser_conflict, _path}} = Mailglass.Installer.Apply.run(plan, [])
    end)
```
Do NOT assert through `run_install!/2` for the tuple — it re-raises a `RuntimeError` embedding `inspect(reason)` in its MESSAGE (installer_fixture_helpers.ex:41-43), so an `assert_raise` there matches a string (DNA-forbidden; Pitfall 1).

**INSTALL-01 (task-level non-zero exit):** `assert_raise` around `run_install!(fixture_root, [])` IS acceptable here — the raised exit is the contract surface — and assert the message names the endpoint path.

**INSTALL-02 (`--force`, D-13 — assert ORDERING not mere success):** `run_install!(fixture_root, ["--force"])`, read `lib/example_web/endpoint.ex`, assert the managed start-marker byte index `<` the unmanaged `plug Plug.Parsers` index (e.g. via `:binary.match/2`). Then call `assert_generated_artifacts_compile!(fixture_root)` (installer_fixture_helpers.ex:64) to catch a corrupted seeded+patched endpoint (Landmine 5; Pitfall 4).

---

### `test/mailglass/install/mailglass_doctor_test.exs` (CREATE — test)

**Analog:** `install_idempotency_test.exs` (same header/fixture pattern). Covers INSTALL-03/INSTALL-04.

**INSTALL-03 wired case (exit 0):** `run_install!(fixture_root, [])` against a fresh fixture (the installer wires the managed block), then call the runner under fixture cwd and assert the summary maps to 0:
```elixir
    summary = File.cd!(fixture_root, fn -> Mailglass.Installer.Doctor.run([]) end).summary
    assert summary.fail == 0 and Map.get(summary, :cannot_diagnose, 0) == 0   # -> exit 0
```
(`File.cd!` is required so `detect_otp_app` + the relative `lib/example_web/endpoint.ex` path resolve against the fixture — D-14.)

**INSTALL-03 unwired case (exit 1):** strip the managed block from the installed endpoint (or use a fresh fixture without install), assert `summary.fail > 0`.

**INSTALL-03 cannot-diagnose case (exit 2):** delete/omit `lib/example_web/endpoint.ex`, assert `summary.cannot_diagnose > 0`.

Prefer asserting the runner's summary map (and optionally the task's `exit_code/2` mapping) over spawning a real OS exit.

## Shared Patterns

### Boundary classification (core mix tasks)
**Source:** `lib/mix/tasks/mail.doctor.ex:2` (and `mailglass.install.ex:2`)
**Apply to:** `lib/mix/tasks/mailglass.doctor.ex` (the runner `Mailglass.Installer.Doctor` inherits via namespace)
```elixir
use Boundary, classify_to: Mailglass
```
The inbound doctor's OMISSION of this is repo-specific (inbound doesn't run the boundary compiler) and must not be carried into core (Pitfall 5).

### CLI-misuse validation (`validate_cli!/N` + `Mix.raise`)
**Source:** `mailglass.inbound.doctor.ex:67-84`, `mail.doctor.ex:54-81`, `mailglass.install.ex:67-82`
**Apply to:** `lib/mix/tasks/mailglass.doctor.ex`
`Mix.raise` only for bad flags / positional args / bad `--format`. Check findings → exit code, never `Mix.raise` (or exit 2 becomes unreachable).

### Errors matched by tuple, never message string (engineering DNA)
**Source:** CLAUDE.md "Errors as a public API contract"; the existing `format_error/1` clause family (`mailglass.install.ex:126-147`) dispatches on tuple shape
**Apply to:** the new `format_error/1` clause AND `install_fail_closed_test.exs` (`assert {:error, {:unmanaged_parser_conflict, _}} = ...`).

### Install-fixture harness (cd-scoped Plan.build + Apply.run)
**Source:** `test/support/installer_fixture_helpers.ex` — `new_fixture_root!/1` (6-15), `run_install!/2` cd-scoped (17-47), `assert_generated_artifacts_compile!/1` (64), `host_endpoint/0` bare skeleton (263-269)
**Apply to:** both new test files. Note the `{:error, reason}` re-raise at lines 41-43 produces a string-only message — use a direct `Apply.run/2` call for tuple assertions.

### Path / app-name resolution (no hand-rolled mix.exs parsing)
**Source:** `Mailglass.Installer.Plan.detect_otp_app/0` (plan.ex:86-97), reused in `apply.ex:48`
**Apply to:** `Mailglass.Installer.Doctor` target-file resolution and the `validate_preflight/1` edit (both reuse it verbatim).

### Managed-block markers (greppable anchors, single source of truth)
**Source:** `Mailglass.Installer.Templates.endpoint_webhook_block_start/0` (templates.ex:73) + `endpoint_webhook_block_end/0` (templates.ex:79) + body block (templates.ex:86-94)
**Apply to:** `Mailglass.Installer.Doctor.wired?/1` and (verbatim, unchanged) the existing `validate_preflight/1` strip.

## No Analog Found

None. Every new/modified file has an exact or strong in-repo analog. The only construct without a direct precedent — a static (non-reflection) doctor — is explicitly a composite of the inbound doctor's SHAPE and `validate_preflight/1`'s SCAN, as mandated by D-08/D-09.

## Metadata

**Analog search scope:** `lib/mailglass/installer/`, `lib/mix/tasks/`, `mailglass_inbound/lib/mix/tasks/`, `mailglass_inbound/lib/mailglass_inbound/internal/`, `test/mailglass/install/`, `test/support/`
**Files scanned (read this session):** apply.ex, mailglass.install.ex, mailglass.inbound.doctor.ex, internal/doctor.ex, mail.doctor.ex, templates.ex, plan.ex, install_idempotency_test.exs, installer_fixture_helpers.ex
**Pattern extraction date:** 2026-06-16
