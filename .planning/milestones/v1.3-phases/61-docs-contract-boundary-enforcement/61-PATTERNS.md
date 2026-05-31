# Phase 61: docs-contract-boundary-enforcement - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/mailglass.docs.check.ex` | config | request-response | `lib/mix/tasks/mailglass.docs.check.ex` | exact |
| `test/mailglass/docs_contract_test.exs` | test | batch | `test/mailglass/docs_contract_test.exs` | exact |
| `test/mailglass/docs_check_task_test.exs` | test | request-response | `test/mailglass/docs_check_task_test.exs` | exact |
| `test/reference_host/trust_runner_command_contract_test.exs` | test | request-response | `test/reference_host/trust_runner_command_contract_test.exs` | exact |
| `test/reference_host/trust_runner_checkpoint_contract_test.exs` | test | batch | `test/reference_host/trust_runner_checkpoint_contract_test.exs` | exact |
| `reference/host_app/README.md` | component | request-response | `reference/host_app/README.md` | exact |
| `reference/host_app/SCOPE.md` | component | request-response | `reference/host_app/SCOPE.md` | exact |
| `MAINTAINING.md` | component | request-response | `MAINTAINING.md` | exact |
| `guides/webhooks.md` | component | request-response | `guides/webhooks.md` | exact |
| `guides/webhook-troubleshooting.md` | component | request-response | `guides/webhook-troubleshooting.md` | exact |
| `mailglass_admin/docs/operator-trust.md` | component | request-response | `mailglass_admin/docs/operator-trust.md` | exact |

## Pattern Assignments

### `lib/mix/tasks/mailglass.docs.check.ex` (config, request-response)
**Analog:** `lib/mix/tasks/mailglass.docs.check.ex`

**Deterministic token registry pattern** (lines 54-317):
```elixir
@tier1_surface_rules %{
  "README.md" => %{required: [...], forbidden: [...]},
  "mailglass_admin/README.md" => %{required: [...], forbidden: [...]},
  ...
}
```

**Execution and fail-closed pattern** (lines 320-337):
```elixir
issues =
  leak_issues(paths)
  |> Kernel.++(tier1_surface_issues())
  |> Kernel.++(preview_boundary_issues())

if issues == [] do
  Mix.shell().info("[mailglass.docs.check] OK — Tier 1 docs match the stability contract.")
else
  Enum.each(issues, &emit_issue/1)
  Mix.raise("Delivery blocked: #{length(issues)} Tier 1 docs issue(s) found.")
end
```

**Forbidden wording + boundary regex pattern** (lines 389-415):
```elixir
if Regex.match?(@preview_confidence_regex, content), do: [], else: [{:missing_boundary, path, ...}]
...
if Regex.match?(@cross_client_parity_regex, line) and
     not Regex.match?(@allowed_cross_client_parity_regex, line) do
  [{:parity_overreach, path, line_number, String.trim(line)}]
end
```

### `test/mailglass/docs_contract_test.exs` (test, batch)
**Analog:** `test/mailglass/docs_contract_test.exs`

**Imports and helper usage pattern** (lines 1-4):
```elixir
use ExUnit.Case, async: true
import Mailglass.DocsHelpers
```

**Required/forbidden token assertion pattern** (lines 36-42, 209-223):
```elixir
assert readme =~ "docs/api_stability.md"
...
refute readme =~ "v0.3 public surface"
```

**Boundary-language regex assertion pattern** (lines 186-199):
```elixir
assert Regex.match?(~r/preview-pipeline confidence\s+only/i, preview_guide)
assert Regex.match?(~r/(?:does(?:\s+\*\*not\*\*|\s+not)\s+claim|not)\s+cross-client parity/i, preview_guide)
```

### `test/mailglass/docs_check_task_test.exs` (test, request-response)
**Analog:** `test/mailglass/docs_check_task_test.exs`

**Mutable-doc test harness pattern** (lines 11-24):
```elixir
setup do
  originals = Map.new(@tracked_paths, fn path -> {path, File.read!(path)} end)
  on_exit(fn -> Enum.each(originals, fn {path, content} -> File.write!(path, content) end) end)
  :ok
end
```

**Task error assertion pattern** (lines 30-34, 45-49):
```elixir
assert_raise Mix.Error, ~r/Delivery blocked/, fn ->
  capture_io(:stderr, fn -> Mix.Tasks.Mailglass.Docs.Check.run([]) end)
end
```

### `test/reference_host/trust_runner_command_contract_test.exs` (test, request-response)
**Analog:** `test/reference_host/trust_runner_command_contract_test.exs`

**Pinned claim-boundary constant pattern** (lines 7-8):
```elixir
@claim_boundary "reference-host trust-journey confidence only; ... deterministic runner evidence"
```

**Token loop assertion pattern** (lines 34-46):
```elixir
Enum.each(required_tokens, fn token ->
  assert String.contains?(readme, token),
         "Phase boundary drift: required token missing #{inspect(token)}"
end)
```

### `test/reference_host/trust_runner_checkpoint_contract_test.exs` (test, batch)
**Analog:** `test/reference_host/trust_runner_checkpoint_contract_test.exs`

**Canonical boundary + schema assertion pattern** (lines 43-46):
```elixir
assert payload_1["schema_version"] == "trust_runner.v1"
assert payload_1["claim_boundary"] == @claim_boundary
assert Enum.map(payload_1["checkpoints"], & &1["stage"]) == @stage_order
```

**Deterministic hash contract pattern** (lines 176-182):
```elixir
rows
|> Enum.map(fn row -> "#{row["stage"]}|#{row["status"]}|#{row["fixture_id"]}" end)
|> Enum.join("\n")
|> then(&:crypto.hash(:sha256, &1))
```

### `reference/host_app/README.md` (component, request-response)
**Analog:** `reference/host_app/README.md`

**Usage-proof framing pattern** (lines 3-7, 29-31):
```markdown
Maintained trust-proof host artifact (not a fixture seed)
...
Public seam boundary: this host does not call Mailglass internal modules or provider internals.
Stable seams used by this reference host:
```

**Canonical trust-command + bounded claim pattern** (lines 41-50):
```markdown
mix verify.reference_host.journey
...
Trust claim: reference-host trust-journey confidence only; ...
```

### `reference/host_app/SCOPE.md` (component, request-response)
**Analog:** `reference/host_app/SCOPE.md`

**In-scope/non-goals/deferred pattern** (lines 1-19):
```markdown
## In Scope
...
## Non-Goals
...
## Deferred
```

### `MAINTAINING.md` (component, request-response)
**Analog:** `MAINTAINING.md`

**Canonical command + checkpoint key contract pattern** (lines 30-43):
```markdown
Use `mix verify.reference_host.journey` as the canonical trust-runner command.
...
Checkpoint consumers should require these keys exactly:
```

**Required-vs-advisory wording pattern** (lines 145-185):
```markdown
Branch protection truth is narrower than "everything we like to run in CI".
...
`Provider Live Advisory` ... is not a merge blocker.
```

### `guides/webhooks.md` (component, request-response)
**Analog:** `guides/webhooks.md`

**Provider facts + public seam wording pattern** (lines 3-8, 58-66):
```markdown
Mailglass ships first-party verifiers ...
...
Mailgun, SES, and Resend stay off the default zero-arg mount. Opt in explicitly:
```

### `guides/webhook-troubleshooting.md` (component, request-response)
**Analog:** `guides/webhook-troubleshooting.md`

**Entry-shim + canonical redirect pattern** (lines 3-5, 25-35):
```markdown
... canonical incident guide. This page is only the webhook-specific entry shim.
...
If you need the full ... checklists, use the canonical incident guide instead of this shim.
```

### `mailglass_admin/docs/operator-trust.md` (component, request-response)
**Analog:** `mailglass_admin/docs/operator-trust.md`

**Semantic seams, not implementation freeze pattern** (lines 3-6, 21-23):
```markdown
... stable operator surface ...
... without treating LiveView, component, or DOM details as stable.
...
They do not freeze the implementation that renders the UI.
```

**Intentional-internal boundary section pattern** (lines 87-100):
```markdown
## Intentionally internal
...
Adopters should not depend on those details even if they are visible in source, tests, or generated docs.
```

## Shared Patterns

### Deterministic Required/Forbidden Token Enforcement
**Source:** `lib/mix/tasks/mailglass.docs.check.ex` (lines 54-387)  
**Apply to:** New/expanded trust-entry docs boundary checks
```elixir
required_issues =
  Enum.flat_map(rules.required, fn token ->
    if String.contains?(content, token), do: [], else: [{:missing, path, token}]
  end)

forbidden_issues =
  Enum.flat_map(rules.forbidden, fn token ->
    if String.contains?(content, token), do: [{:stale, path, token}], else: []
  end)
```

### Forbidden Overreach Wording (Regex Gate)
**Source:** `lib/mix/tasks/mailglass.docs.check.ex` (lines 400-411)  
**Apply to:** “internals-as-public-contract” wording and unqualified guarantee claims
```elixir
if Regex.match?(@cross_client_parity_regex, line) and
     not Regex.match?(@allowed_cross_client_parity_regex, line) do
  [{:parity_overreach, path, line_number, String.trim(line)}]
end
```

### Contract Test Pinning for Canonical Boundary Claims
**Source:** `test/reference_host/trust_runner_command_contract_test.exs` (lines 31-46)  
**Apply to:** reference-host boundary and canonical-link assertions in trust docs
```elixir
required_tokens = [...]
Enum.each(required_tokens, fn token ->
  assert String.contains?(readme, token),
         "Phase boundary drift: required token missing #{inspect(token)}"
end)
```

### Canonical Stability Source Routing
**Source:** `docs/api_stability.md` (lines 3-8, 16-23), `mailglass_admin/docs/api_stability.md` (lines 6-15), `mailglass_inbound/docs/api_stability.md` (lines 12-14)  
**Apply to:** all trust-facing docs that make guarantee claims
```markdown
Generated docs reachability is not the contract by itself.
The contract is the explicit inventory in this file.
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/mix/tasks`, `test/mailglass`, `test/reference_host`, `reference/host_app`, `guides`, `docs`, `mailglass_admin/docs`, `mailglass_inbound/docs`  
**Files scanned:** 11  
**Pattern extraction date:** 2026-05-31
