# Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor - Research

**Researched:** 2026-06-16
**Domain:** Elixir/Mix installer (Igniter-style file patching) + offline static-scan doctor task
**Confidence:** HIGH (all claims verified against live source this session)

## Summary

CONTEXT.md (D-01..D-14) is exhaustively pre-settled with exact file:line evidence. This research
**verified every cited fact against the live source** — all 14 decisions stand, with only minor
line-range refinements noted in `## Source Fact Verification`. No locked decision was found to be
wrong; CONTEXT.md is safe to plan against verbatim.

The work is genuinely small and low-risk: change one discarded `Mix.shell().info(...)` warning in
`validate_preflight/1` into an `{:error, {:unmanaged_parser_conflict, endpoint_path}}` return,
thread it as the first link of `Apply.run/2`'s existing `with` chain (which already funnels every
error to `format_error/1 → Mix.raise`), add one `format_error/1` clause, and add a brand-new
`mix mailglass.doctor` task + internal runner that does a **static source scan** (not runtime
reflection) of `lib/<app>_web/endpoint.ex` with three-state exit codes (0/1/2). The inbound doctor
(`MailglassInbound.Internal.Doctor`) is a near-perfect structural template for the shell+runner+
exit-code shape — **but its detection mechanism (runtime `Code.ensure_loaded?`/`function_exported?`
+ `app.start`) must NOT be copied**; D-09 mandates a static scan precisely so the doctor runs inside
the install-fixture harness, which never boots the host endpoint.

**Primary recommendation:** Plan three tasks — (1) fail-closed `validate_preflight` + `Apply.run`
wiring + `format_error` clause (INSTALL-01/02), (2) new `mix mailglass.doctor` task + internal
runner doing a static endpoint scan (INSTALL-03), (3) tests-first across all three following the
`install_idempotency_test.exs` fixture pattern (INSTALL-04). Match errors by tuple, never message
string. Seed the conflict by overwriting the fixture endpoint AFTER `new_fixture_root!/1` with a
bare `plug Plug.Parsers` (no `body_reader`) OUTSIDE the managed markers.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INSTALL-01 | `mix mailglass.install` fails closed (Mix.raise, non-zero exit) with actionable message on unmanaged `plug Plug.Parsers` lacking `:body_reader` | `validate_preflight/1` (apply.ex:47-76) already detects this exact condition (apply.ex:64-65); today it warns-and-discards (apply.ex:66-73). Threading a `{:error, ...}` return through `Apply.run/2`'s `with` chain reaches the task's `{:error, reason} -> Mix.raise(format_error(reason))` (mailglass.install.ex:61-62), which produces the non-zero exit. |
| INSTALL-02 | `--force` escape hatch preserves today's "insert managed parser above existing one" behavior | `--force` already declared in OptionParser (mailglass.install.ex:33) and flows into `opts`, which `validate_preflight/1` already receives. The managed block is an `:ensure_block` anchored to `use Phoenix.Endpoint` (plan.ex:156-170); `insert_after_anchor/3` (apply.ex:342-371) inserts it right after that line — at the top, above any later unmanaged parser. Plug runs parsers in source order, so the managed body_reader parser wins. Zero changes to plan/templates/apply_ensure_block needed — `--force` only skips the new raise. |
| INSTALL-03 | New `mix mailglass.doctor` confirms `CachingBodyReader` is wired; exits non-zero when not | `mail.doctor` is DNS-only and hard-requires `--domain` (mail.doctor.ex:70-72) — not extensible. New task mirrors the inbound-doctor shell+runner+three-state-exit-code shape but uses a STATIC scan (D-09) reusing `Plan.detect_otp_app/0` (plan.ex:86-97) + the `templates.ex` markers. |
| INSTALL-04 | Fail-closed, `--force`, and doctor covered by tests following `install_idempotency_test.exs` | The fixture harness (`InstallerFixtureHelpers`) supports `new_fixture_root!/1`, post-creation mutation, `run_install!/2` (re-raises on `{:error,...}`, lines 41-43), and `File.cd!` scoping — all the seams the three test cases need. |
</phase_requirements>

## Source Fact Verification

Every file:line cited in CONTEXT.md / canonical_refs, checked against live source this session:

| Cited fact | Cited location | Status |
|------------|----------------|--------|
| `validate_preflight/1` body | apply.ex:47-76 | **CONFIRMED** (def at 47, ends 76) |
| `Apply.run/2` `with` chain (bare `validate_preflight(opts)` then `with {:ok, manifest} <- ...`) | apply.ex:27-45 / 32-36 | **CONFIRMED** — `validate_preflight(opts)` is a bare statement at line 32 whose return is discarded; `with` starts line 34. `@spec` `{:ok, result_map()} \| {:error, term()}` at line 27. |
| Conflict predicate (`contains "plug Plug.Parsers"` AND NOT `contains "body_reader"`) | apply.ex:64-65 | **CONFIRMED** (exactly lines 64-65) |
| `insert_after_anchor/3` | apply.ex:342-371 | **CONFIRMED** — body 342-371, `@spec` at 340-341. Inserts after the full anchor LINE (not bare substring) to avoid orphaning `, otp_app: :app` — relevant to the `--force` ordering test. |
| Today's warn-and-discard `Mix.shell().info([:yellow, ...])` | apply.ex:66-73 | **CONFIRMED** — this is the exact block D-01 replaces with a `{:error, ...}` return. |
| `run/1` | mailglass.install.ex:30-64 | **CONFIRMED** |
| `{:error, reason} -> Mix.raise(format_error(reason))` | cited 61-63 | **DRIFTED (cosmetic)** — actually lines 61-62 (clause head line 61, body line 62). Behavior identical; no plan impact. |
| `format_error/1` clauses | mailglass.install.ex:125-147 | **CONFIRMED** — catch-all `format_error(other)` at line 147. New clause inserts before it. |
| `maybe_raise_conflict_error/1` | mailglass.install.ex:108-112 | **CONFIRMED** (this is the *sidecar* conflict count path, distinct from the new preflight raise — do not conflate) |
| `--force` in OptionParser strict spec | mailglass.install.ex:33 | **CONFIRMED** (`strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean]`) |
| endpoint `:ensure_block` op + `use Phoenix.Endpoint` anchor | plan.ex:156-170 | **CONFIRMED** (`add_webhook_endpoint_parser/2`, anchor literal `"use Phoenix.Endpoint"` at line 166) |
| `Plan.detect_otp_app/0` | plan.ex (cited generally) | **CONFIRMED** — public fn at plan.ex:86-97; reads `mix.exs` in `File.cwd!()`, regex `app:\s*:([a-z_]...)`, falls back to `:my_app`. |
| Managed-block markers | templates.ex:72-95 / start marker at 73 | **CONFIRMED** — `endpoint_webhook_block_start/0` returns `"# mailglass:start endpoint_webhook_parser"` (line 73); end marker `"# mailglass:end endpoint_webhook_parser"` (line 79); `endpoint_webhook_parser_body/0` (the `body_reader:` block) at 85-95. |
| `mail.doctor` `--domain` required | mail.doctor.ex:70-72 | **CONFIRMED** — `unless is_binary(opts[:domain]) and String.trim(...) != "" -> Mix.raise("...--domain is required")`. Confirms D-07: cannot add an offline lane without relaxing this contract. |
| Inbound doctor shell | mailglass.inbound.doctor.ex | **CONFIRMED** — thin shell: `OptionParser` → `validate_cli!` → `app.start` → `Doctor.run([])` → `render_output` → `exit({:shutdown, exit_code(...)})`. Three-state `exit_code/2`: cannot_diagnose→2, fail→1, strict+warn→1, else 0 (lines 96-105). **Note: it omits `use Boundary` deliberately (inbound doesn't run the boundary compiler).** |
| Inbound doctor runner | internal/doctor.ex | **CONFIRMED** — `run/1` returns `%{summary: %{pass,warn,fail,cannot_diagnose}, findings: [...]}` with finding shape `%{check, status, title, observed, remediation, evidence}`; `cannot_diagnose` counted separately from `fail` (summarize/1, lines 409-424). Uses runtime reflection (`Code.ensure_loaded?`, `function_exported?`) — **NOT to be copied; D-09 requires static scan.** |
| `install_idempotency_test.exs` fixture pattern | test file | **CONFIRMED** — `use ExUnit.Case, async: false`; `import InstallerFixtureHelpers`; `new_fixture_root!/1` → `run_install!/2` → mutate via `File.write!` → re-run → assert. |
| `new_fixture_root!/1`, `run_install!/2`, `File.cd!` scoping | installer_fixture_helpers.ex | **CONFIRMED** — `new_fixture_root!/1` (lines 6-15), `run_install!/2` runs inside `File.cd!(fixture_root, fn -> ... end)` (line 31). |
| `run_install!/2` re-raises on `{:error, reason}` | installer_fixture_helpers.ex:41-43 | **CONFIRMED** — `{:error, reason} -> raise "installer fixture: Apply.run/2 failed with #{inspect(reason)}"`. **IMPORTANT NUANCE (see Landmines):** it re-raises a `RuntimeError` whose message embeds `inspect(reason)`; it does NOT propagate the original `{:error, tuple}`. Asserting via `assert_raise` through `run_install!/2` therefore matches a message string — contrary to engineering DNA. The struct/tuple-match path requires calling `Apply.run/2` directly (D-12 already prefers this). |
| `host_endpoint/0` bare skeleton | installer_fixture_helpers.ex:263-269 | **CONFIRMED** — emits `defmodule ExampleWeb.Endpoint do\n  use Phoenix.Endpoint, otp_app: :example\nend` with NO `plug Plug.Parsers`. Confirms D-11: the default skeleton never triggers the conflict, so tests must seed it. Fixture otp_app is `:example` → endpoint path `lib/example_web/endpoint.ex`. |

**No DRIFT of substance.** One cosmetic off-by-one (61-63 → 61-62). Every behavioral claim holds.

## Standard Stack

No new dependencies. Pure stdlib + existing project modules.

| Module / API | Purpose | Already exists |
|--------------|---------|----------------|
| `Mix.Task` / `Mix.raise` / `exit({:shutdown, code})` | Task shell + exit codes | yes |
| `OptionParser.parse/2` (strict) | CLI flag parsing | yes (pattern in every task) |
| `use Boundary, classify_to: Mailglass` | Boundary classification — **required for core tasks** (core runs the boundary compiler; inbound does not, which is why the inbound doctor omits it) | yes |
| `File.read!/1`, `File.exists?/1`, `String.contains?/2` | Static source scan | stdlib |
| `Mailglass.Installer.Plan.detect_otp_app/0` | Resolve otp_app from `mix.exs` in cwd → endpoint path | yes (plan.ex:86) |
| `Mailglass.Installer.Templates.endpoint_webhook_block_start/0` etc. | Greppable managed-block markers for the doctor scan | yes (templates.ex:73,79) |

**No `## Package Legitimacy Audit` needed** — this phase installs zero external packages.

## Architecture Patterns

### Component responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `validate_preflight/1` | Detect unmanaged-parser conflict; return `{:error, {:unmanaged_parser_conflict, endpoint_path}}` unless `--force`; return `:ok` otherwise | apply.ex (edit existing) |
| `Apply.run/2` | Thread `validate_preflight` as first `with` link; preserves `{:ok, map} \| {:error, term()}` | apply.ex (1-line edit at 32→34) |
| `format_error/1` | New clause turning `{:unmanaged_parser_conflict, path}` into the actionable message | mailglass.install.ex (insert before catch-all at 147) |
| `mix mailglass.doctor` (NEW) | Thin CLI shell: parse flags → call runner → render → `exit({:shutdown, code})` | lib/mix/tasks/mailglass.doctor.ex (new) |
| Doctor runner (NEW) | Pure fn: static-scan `endpoint.ex`, return `%{summary, findings}` | Claude's discretion on module name — see below (new) |

### Pattern 1: Fail-closed by returning instead of warning (D-01/D-02)

```elixir
# apply.ex validate_preflight/1 — replace the Mix.shell().info([:yellow, ...]) block:
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
# ...and every other branch (no endpoint file, no conflict) must also return :ok,
# so the value is threadable into `with :ok <- validate_preflight(opts), ...`.

# Apply.run/2 — change line 32 from a bare statement into the first with-link:
with :ok <- validate_preflight(opts),
     {:ok, manifest} <- Manifest.load(manifest_path),
     ...
```

### Pattern 2: Thin doctor shell over pure runner with three-state exit (D-08/D-10)

Mirror `mailglass.inbound.doctor.ex` STRUCTURE (shell → runner → `exit({:shutdown, code})`),
mirror the `%{summary: %{pass,warn,fail,cannot_diagnose}, findings: [...]}` shape and finding shape
`%{check, status, title, observed, remediation, evidence}`, and mirror `exit_code/2`
(cannot_diagnose→2, fail→1, else 0). **Add `use Boundary, classify_to: Mailglass`** (unlike inbound).

### Pattern 3: Static source scan, NOT runtime reflection (D-09 — the key divergence)

```elixir
# Doctor runner — pure, offline, no app.start, runs in fixture cwd:
otp_app = Mailglass.Installer.Plan.detect_otp_app()
endpoint_path = "lib/#{otp_app}_web/endpoint.ex"

cond do
  not File.exists?(endpoint_path) -> cannot_diagnose finding   # → exit 2
  wired?(File.read!(endpoint_path)) -> pass finding             # → exit 0
  true -> fail finding (CachingBodyReader absent)               # → exit 1
end

# wired? = contains "body_reader" AND "Mailglass.Webhook.CachingBodyReader"
#          (optionally also gated on the managed markers from Templates)
```

The inbound doctor calls `app.start` and reflects loaded modules. **Do NOT do that here** — the
install fixture never boots the host endpoint, and the whole point of the static scan is that it
runs offline inside `File.cd!(fixture_root, ...)`. The doctor mix task should therefore NOT call
`Mix.Task.run("app.start")` for the endpoint scan (it needs only `mix.exs` + `endpoint.ex` on disk).

### Anti-Patterns to Avoid

- **Copying the inbound doctor's runtime reflection** — violates D-09; breaks the fixture test.
- **Matching the `{:error, ...}` by message string** — engineering DNA forbids it; match the tuple.
- **Re-routing through `maybe_raise_conflict_error/1`** (mailglass.install.ex:108) — that's the
  sidecar-count path; the new fail-closed error rides the `{:error, reason}` → `format_error/1` rail.
- **Touching `mail.doctor`** — D-07; its `--domain`-required contract is out of scope.
- **Redesigning plan/apply** — explicitly out of scope (REQUIREMENTS.md Out-of-Scope).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Resolve host app name → endpoint path | New mix.exs parser | `Plan.detect_otp_app/0` (plan.ex:86) | Already handles cwd + fallback + tests |
| Managed-block detection | Hardcoded comment strings | `Templates.endpoint_webhook_block_start/0` etc. | Single source of truth; greppable; stable |
| Fixture install + mutation + cd scoping | New harness | `InstallerFixtureHelpers` | Already supports every seam the tests need |
| Three-state exit-code logic | New scheme | Inbound doctor's `exit_code/2` shape | Established project convention (0/1/2) |
| Non-zero exit from task | Custom error path | Existing `{:error, reason} -> Mix.raise` rail | The fail-closed return reaches it unchanged |

## Validation Architecture

> Nyquist `nyquist_validation: true` (confirmed in `.planning/config.json`). This section drives VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18, `~> 1.18`) |
| Config file | `test/test_helper.exs` (existing); new test file in `test/mailglass/install/` |
| Quick run command | `mix test test/mailglass/install/install_fail_closed_test.exs` (new file) |
| Full suite command | `mix test test/mailglass/install/` (installer lane only — avoids the ~57 unrelated Oban failures in worktrees, per MEMORY) |

**Harness note:** new tests `use ExUnit.Case, async: false` and `import Mailglass.Test.InstallerFixtureHelpers` — identical to `install_idempotency_test.exs`. Run the installer lane explicitly; do NOT gate on bare `mix test` (known unrelated flakes: Oban, `voice_test` "Oops" dep-JS noise).

### Phase Requirements → Test Map

| Req ID | Behavior (the observable) | Test seam | Automated command | File Exists? |
|--------|---------------------------|-----------|-------------------|--------------|
| INSTALL-01 | `Apply.run/2` returns exactly `{:error, {:unmanaged_parser_conflict, endpoint_path}}` when endpoint has a bare `plug Plug.Parsers` and no `--force` | **Call `Apply.run(plan, opts)` directly inside `File.cd!(fixture_root, ...)`** and pattern-match the tuple (`assert {:error, {:unmanaged_parser_conflict, _}} = ...`). NOT via `run_install!/2` (that re-raises a RuntimeError with the tuple only in the message string — DNA-forbidden to assert on). | `mix test test/mailglass/install/install_fail_closed_test.exs` | ❌ Wave 0 |
| INSTALL-01 (task level) | The mix task exits non-zero with an actionable message | `assert_raise Mix.Error` (or `Mix.Error`) around `run_install!/2` — acceptable here because INSTALL-01's task-level observable IS the raised exit, and the message is the contract surface. Assert the message names the endpoint path. | same file | ❌ Wave 0 |
| INSTALL-02 | `--force` → install SUCCEEDS **and** managed webhook block appears BEFORE the unmanaged `plug Plug.Parsers` in resulting `endpoint.ex` | `run_install!(fixture_root, ["--force"])` then read `lib/example_web/endpoint.ex`; assert ordering via byte index: `:binary.match(contents, marker_start)` index `<` `:binary.match(contents, "plug Plug.Parsers")` index of the UNMANAGED one. Also run `assert_generated_artifacts_compile!/1` so the seeded+patched endpoint still parses. **Assert ordering, not mere success** (D-13 / `<specifics>`). | same file | ❌ Wave 0 |
| INSTALL-03 | Doctor returns exit 0 when wired, exit 1 when `CachingBodyReader` absent, exit 2 when endpoint.ex missing | Install against fixture (wired case), then call the **doctor runner** directly under `File.cd!(fixture_root, fn -> Runner.run([]) end)`; assert `summary` → exit-code mapping. For the unwired case, strip the managed block (or fresh fixture without install). For exit 2, delete/omit `endpoint.ex`. Prefer asserting the runner's summary map + `exit_code/2` over spawning a real OS exit. | `mix test test/mailglass/install/mailglass_doctor_test.exs` (new) | ❌ Wave 0 |
| INSTALL-04 | All three paths covered following the idempotency fixture pattern | Coverage is satisfied by the three test files above using `new_fixture_root!/1` + post-creation `File.write!` seeding + `File.cd!` scoping. | (the above) | ❌ Wave 0 |

### The seeding footgun (MUST encode in every fail-closed/`--force`/unwired test)

Per CONTEXT.md `<specifics>` and D-11: after `new_fixture_root!/1`, overwrite
`lib/example_web/endpoint.ex` so the seeded `plug Plug.Parsers`:

1. has **NO `body_reader`** text anywhere in the file, **AND**
2. sits **OUTSIDE** the managed markers (`# mailglass:start/end endpoint_webhook_parser`).

If either condition is violated, `validate_preflight`'s guard (`contains "plug Plug.Parsers"` AND
NOT `contains "body_reader"`) is satisfied/dissatisfied wrongly and **the test passes vacuously**
(no conflict surfaced, but for the wrong reason). The default skeleton (installer_fixture_helpers.ex:263-269)
is bare — it will never trip the guard, so seeding is mandatory. Suggested seed body:

```elixir
defmodule ExampleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :example

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Jason
end
```

(No `body_reader:`, outside any managed markers — guaranteed to trip the guard before install, and
after a `--force` install the managed block lands above it.)

### Sampling Rate
- **Per task commit:** `mix test test/mailglass/install/install_fail_closed_test.exs` (and the doctor file once it exists)
- **Per wave merge:** `mix test test/mailglass/install/`
- **Phase gate:** installer lane green + `mix credo --strict` (engineering-DNA Credo checks) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/mailglass/install/install_fail_closed_test.exs` — covers INSTALL-01, INSTALL-02, INSTALL-04
- [ ] `test/mailglass/install/mailglass_doctor_test.exs` — covers INSTALL-03, INSTALL-04
- [ ] No new fixtures/conftest needed — `InstallerFixtureHelpers` + `test/support/example` cover all seams
- [ ] No framework install — ExUnit already present

## Common Pitfalls

### Pitfall 1: Asserting the fail-closed error by message string
**What goes wrong:** Using `run_install!/2` + `assert_raise` and matching the message text.
**Why it happens:** `run_install!/2` re-raises a `RuntimeError` (installer_fixture_helpers.ex:41-43)
that embeds `inspect(reason)` in its message — the original tuple is not propagated.
**How to avoid:** Assert the tuple via a direct `Apply.run/2` call (D-12). Reserve `assert_raise` for
the task-level "non-zero exit" observable only, where the raised message is itself the contract.
**Warning sign:** a test that greps the error text instead of pattern-matching `{:unmanaged_parser_conflict, _}`.

### Pitfall 2: `validate_preflight/1` not returning `:ok` on every non-conflict branch
**What goes wrong:** Threading `with :ok <- validate_preflight(opts)` fails because the
no-endpoint-file branch or the no-conflict branch returns something other than `:ok` (today the fn
returns the value of an `if` that can be `nil`).
**How to avoid:** Make EVERY branch of `validate_preflight/1` return `:ok` or `{:error, ...}`
explicitly. The current implicit `nil` returns will not match `:ok` in the `with`.
**Warning sign:** install silently succeeds in the no-conflict happy path but the `with` short-circuits unexpectedly.

### Pitfall 3: Doctor calling `app.start` / using runtime reflection
**What goes wrong:** Copying the inbound doctor's `Mix.Task.run("app.start")` + `Code.ensure_loaded?`
breaks the fixture test (the fixture host app does not compile/boot) and violates D-09.
**How to avoid:** Static `File.read!` scan only; no `app.start` for the endpoint check.
**Warning sign:** doctor test needs the fixture to be a bootable Mix project.

### Pitfall 4: `--force` ordering regression
**What goes wrong:** A future change to `insert_after_anchor/3` or the anchor could land the managed
block BELOW the adopter's parser, silently re-introducing the 401 even under `--force`.
**How to avoid:** The `--force` test asserts ORDERING (managed block index < unmanaged parser index),
not just install success (D-13).
**Warning sign:** `--force` test only asserts `run_install!` returned `:ok`.

### Pitfall 5: Boundary classification omitted on the new task
**What goes wrong:** Core runs the `:boundary` compiler; a new `Mix.Tasks.Mailglass.Doctor` without
`use Boundary, classify_to: Mailglass` will produce a boundary warning/error (the inbound doctor omits
it ONLY because inbound doesn't run the boundary compiler).
**How to avoid:** Add `use Boundary, classify_to: Mailglass` to the new core mix task (match `mail.doctor` / `mailglass.install`).
**Warning sign:** `mix compile` boundary warning about an unclassified module.

## Runtime State Inventory

Not applicable — this is a code/test phase, not a rename/refactor/migration. No stored data, live
service config, OS-registered state, secrets, or build artifacts carry phase-specific runtime state.
**None — verified by phase scope (installer source + new task + tests only).**

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | everything | ✓ | ~> 1.18 (host fixture mix.exs) | — |
| ExUnit | tests | ✓ | bundled | — |
| `Jason` | seeded endpoint `json_decoder: Jason` (text only, never invoked in static scan) | ✓ | existing dep | — |

No external services, DNS, DB, or network needed — the entire phase (including the doctor) is offline.

## Project Constraints (from CLAUDE.md)

- **Errors as a public API contract** — match `{:error, {:unmanaged_parser_conflict, _}}` by
  tuple, NEVER by message string. (Directly governs D-12 and Pitfall 1.)
- **No new public `Mailglass.Error` set changes** — the conflict is a plain internal `{:error, tuple}`
  threaded through the installer; it is NOT a new `%Mailglass.Error{}` type (scope lock: no
  public-error-set changes).
- **Boundary classification** — new core mix task uses `use Boundary, classify_to: Mailglass`.
- **No PII in telemetry** — N/A here (no telemetry emitted), but do not add any.
- **Optional-deps gating** — N/A (no optional deps touched); do not introduce bare optional refs.
- **Custom Credo checks at lint time** — run `mix credo --strict` as a phase gate (path-scope to lib/).
- **Scope lock (REQUIREMENTS.md):** confined to `lib/mailglass/installer/*`,
  `lib/mix/tasks/mailglass.install.ex`, + new doctor task/runner. No outbound/webhook/inbound
  runtime-contract, schema, or installer plan/apply redesign.

## Claude's Discretion (carried from CONTEXT.md — for the planner)

- Exact wording of the actionable fail-closed message (must name endpoint path, silent-401 risk,
  the `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` fix, and `--force`).
- Doctor internal-runner module name/location — keep in installer/webhook namespace, Boundary-classified
  to `Mailglass` (e.g. `Mailglass.Installer.Doctor` or `Mailglass.Webhook.Doctor`). Recommendation:
  `Mailglass.Installer.Doctor` — the detection logic (otp_app resolution, endpoint path, marker scan)
  is installer-domain and reuses `Plan`/`Templates`, so it co-locates most naturally there.
- Dedicated `format_error/1` clause vs catch-all — D-03 prefers a dedicated clause (the catch-all's
  `inspect(other)` would NOT produce the actionable multi-line message).
- Doctor flag surface (`--format json`, `--verbose`) — mirror the inbound doctor only as far as
  INSTALL-03 needs (a plain human-readable check + non-zero exit is sufficient); don't over-build.

## Sequencing & Landmines for the Planner

1. **Tests-first is feasible and cheap** — the harness already exists; Wave 0 is two new test files.
2. **`validate_preflight/1` must return `:ok` on ALL non-conflict branches** before the `with`
   re-wire, or the happy path breaks (Pitfall 2). Do these two edits in the same task.
3. **Two distinct "conflict" raise paths exist** — `maybe_raise_conflict_error/1` (sidecar count,
   mailglass.install.ex:108) and the NEW preflight `{:error, ...}` → `format_error/1`. Don't merge them.
4. **The fixture otp_app is `:example`** → doctor/scan target is `lib/example_web/endpoint.ex`.
5. **`assert_generated_artifacts_compile!/1`** (installer_fixture_helpers.ex:64) is available and should
   be used in the `--force` test to catch a corrupted seeded+patched endpoint.
6. **Run the installer test lane explicitly**, not bare `mix test` (unrelated Oban/voice_test flakes per MEMORY).
7. **`--force` docs split:** error-message half is in-scope (D-03/D-06); the getting-started
   troubleshooting prose is Phase 105's (DOCS) — do not write guide prose here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (none) | — | All claims verified against live source or copied from locked CONTEXT.md decisions. |

**Table empty:** Every factual claim was VERIFIED this session against the live source; the rest are
locked CONTEXT.md decisions (D-01..D-14) carried verbatim. No `[ASSUMED]` claims needing user confirmation.

## Open Questions

None blocking. One minor planner choice (already in Claude's Discretion): the runner module name —
`Mailglass.Installer.Doctor` recommended.

## Sources

### Primary (HIGH confidence)
- Live source files read this session: `lib/mailglass/installer/apply.ex`, `lib/mailglass/installer/plan.ex`,
  `lib/mailglass/installer/templates.ex`, `lib/mix/tasks/mailglass.install.ex`, `lib/mix/tasks/mail.doctor.ex`,
  `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex`,
  `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex`,
  `test/mailglass/install/install_idempotency_test.exs`, `test/support/installer_fixture_helpers.ex`
- `.planning/phases/104-installer-fail-closed-webhook-wiring-doctor/104-CONTEXT.md` (locked D-01..D-14)
- `.planning/REQUIREMENTS.md` (INSTALL-01..04), `CLAUDE.md` (engineering DNA), `.planning/config.json` (nyquist)

## Metadata

**Confidence breakdown:**
- Source fact verification: HIGH — every cited file:line opened and checked this session
- Architecture/patterns: HIGH — mechanism already exists in source; change is minimal & local
- Validation architecture: HIGH — harness verified, seeding footgun confirmed against skeleton
- Pitfalls: HIGH — derived from observed `run_install!/2` re-raise behavior and Boundary compiler split

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (stable internal code; re-verify line numbers only if installer files change)
