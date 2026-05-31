# Phase 65: Compatibility, Docs, and DX Lock - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 11  
**Analogs found:** 10 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/README.md` | config | request-response | `mailglass_inbound/README.md` | exact |
| `mailglass_inbound/docs/inbound-install.md` | config | request-response | `mailglass_inbound/docs/inbound-install.md` | exact |
| `mailglass_inbound/docs/api_stability.md` | config | transform | `mailglass_inbound/docs/api_stability.md` | exact |
| `mailglass_inbound/docs/inbound-operator.md` | config | request-response | `mailglass_inbound/docs/inbound-operator.md` | exact |
| `mailglass_inbound/docs/inbound-testing.md` | config | request-response | `mailglass_inbound/docs/inbound-testing.md` | exact |
| `mailglass_inbound/docs/inbound-routing-debug.md` | config | request-response | `mailglass_inbound/docs/inbound-operator.md` | role-match |
| `mailglass_admin/docs/operator-trust.md` | config | request-response | `mailglass_admin/docs/operator-trust.md` | exact |
| `guides/compatibility-and-deprecations.md` | config | transform | `guides/compatibility-and-deprecations.md` | exact |
| `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | test | transform | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | exact |
| `lib/mix/tasks/mailglass.docs.check.ex` | utility | batch | `lib/mix/tasks/mailglass.docs.check.ex` | exact |
| `docs/compatibility-and-deprecations.md` | config | transform | `guides/compatibility-and-deprecations.md` | partial |

## Pattern Assignments

### `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (test, transform)

**Analog:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`

**Imports/module setup pattern** (lines 1-12):
```elixir
defmodule MailglassInbound.DocsContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @install_path Path.expand("../../docs/inbound-install.md", __DIR__)
  @stability_path Path.expand("../../docs/api_stability.md", __DIR__)
  @operator_trust_path Path.expand("../../../mailglass_admin/docs/operator-trust.md", __DIR__)
```

**Core docs-contract assertion pattern** (lines 13-32):
```elixir
test "docs inventory names the stable public modules for the inbound slice" do
  readme = File.read!(@readme_path)
  stability = File.read!(@stability_path)
  stable = contract_section!(stability, "stable")

  for module_name <- ["MailglassInbound.InboundMessage", ...] do
    assert readme =~ module_name
    assert stable =~ module_name
  end
end
```

**Required + forbidden phrase pattern** (lines 128-143):
```elixir
assert readme =~ "mix deps.get"
assert readme =~ "mix ecto.migrate"
...
refute readme =~ "mix mailglass.install"
refute readme =~ "installer"
```

### `lib/mix/tasks/mailglass.docs.check.ex` (utility, batch)

**Analog:** `lib/mix/tasks/mailglass.docs.check.ex`

**Task/module pattern** (lines 1-22):
```elixir
defmodule Mix.Tasks.Mailglass.Docs.Check do
  use Boundary, classify_to: Mailglass
  @shortdoc "Checks Tier 1 docs for stability-contract drift"
  use Mix.Task
```

**Tier-1 path registry pattern** (lines 24-53):
```elixir
@tier1_paths [
  "README.md",
  "mailglass_inbound/README.md",
  "mailglass_admin/docs/operator-trust.md",
  "mailglass_inbound/docs/api_stability.md",
  "guides/compatibility-and-deprecations.md",
  "mailglass_inbound/docs/inbound-install.md",
  "mailglass_inbound/docs/inbound-testing.md",
  "mailglass_inbound/docs/inbound-operator.md"
]
```

**Per-file required/forbidden rules pattern** (lines 70-122, 243-251):
```elixir
@tier1_surface_rules %{
  "mailglass_inbound/README.md" => %{required: [...], forbidden: [...]},
  "mailglass_admin/docs/operator-trust.md" => %{required: [...], forbidden: []},
  "guides/compatibility-and-deprecations.md" => %{required: [...], forbidden: [...]}
}
```

### `mailglass_inbound/README.md` (config, request-response)

**Analog:** `mailglass_inbound/README.md`

**Canonical adoption-lane framing pattern** (lines 3-7):
```markdown
... canonical adoption lane ... install manually ... wire endpoint/body-reader ...
mount provider plugs ... choose async mode ... verify contract with package test lanes.
```

**Setup sequence pattern** (lines 59-107, 139-153, 173-190):
```markdown
## Manual Setup
### 1. Add the dependency and fetch deps
...
### 3. Wire `Plug.Parsers` with the package body reader
...
### 5. Mount the provider ingress paths
...
### 7. Choose the async execution mode
```

**Replay/trust boundary wording pattern** (lines 219-221):
```markdown
Replay ... is not a fresh provider receive, it does not silently reroute ...
and it is not a public API in this phase.
```

### `mailglass_inbound/docs/inbound-install.md` (config, request-response)

**Analog:** `mailglass_inbound/docs/inbound-install.md`

**Step-by-step numbered structure pattern** (lines 13-203):
```markdown
## 1. Add the dependency
## 2. Run the migrations
...
## 9. Choose the async execution mode
## 10. Write a sandboxed test
```

**Testing-DX warning pattern** (lines 227-229, 244-246):
```markdown
ONE assertion per drive ... assert_received ... CONSUMES it ...
`async: false` is required ...
```

### `mailglass_inbound/docs/inbound-operator.md` (config, request-response)

**Analog:** `mailglass_inbound/docs/inbound-operator.md`

**Command-per-section operator pattern** (lines 8, 77, 153):
```markdown
## mix mailglass.inbound.doctor
## mix mailglass.inbound.replay
## mix mailglass.inbound.prune
```

**Exit code + flags table pattern** (lines 35-53, 120-129, 196-202):
```markdown
| Code | Meaning |
...
| Flag | Effect |
```

**Guardrail wording pattern** (lines 100-118, 173-188):
```markdown
`--tenant <id>` is required ... cross-tenant replay guard ...
Type 'yes' to continue ... aborts without deleting otherwise.
```

### `mailglass_inbound/docs/inbound-testing.md` (config, request-response)

**Analog:** `mailglass_inbound/docs/inbound-testing.md`

**MailboxCase default harness pattern** (lines 11-21, 24-33):
```markdown
`MailglassInbound.MailboxCase` ... `use ... async: false`
The rule is absolute: always ... async: false.
```

**One-assertion-per-drive contract pattern** (lines 117-150):
```markdown
Each `assert_inbound_*` ... **consumes** the tuple ...
drive a second message for a second assertion.
```

### `mailglass_inbound/docs/api_stability.md` (config, transform)

**Analog:** `mailglass_inbound/docs/api_stability.md`

**Semantics-first contract framing pattern** (lines 6-9, 19-24):
```markdown
stability is semantics-first ... reachability does not define the contract ...
explicit inventory in this file defines stable/internal/deferred.
```

**Taxonomy sections pattern** (lines 21, 61, 81, 124):
```markdown
### `stable`
### `testing`
### `internal`
### `deferred`
```

### `mailglass_admin/docs/operator-trust.md` (config, request-response)

**Analog:** `mailglass_admin/docs/operator-trust.md`

**Stable seams / internal seams split pattern** (lines 14-30, 94-107):
```markdown
## Stable seams
...
## Intentionally internal
```

**Replay semantics boundary wording pattern** (lines 58-80):
```markdown
Replay ... stored inbound receive truth ... not a fresh provider receipt ...
does not silently reroute ...
```

### `guides/compatibility-and-deprecations.md` (config, transform)

**Analog:** `guides/compatibility-and-deprecations.md`

**Two-lane compatibility framing pattern** (lines 22-33):
```markdown
- `stable lane`
- `compatibility lane`
```

**Warnings-as-errors + support-horizon wording pattern** (lines 129-145):
```markdown
... `--warnings-as-errors` posture ...
... replacement, warning behavior, and support horizon ...
```

### `mailglass_inbound/docs/inbound-routing-debug.md` (config, request-response)

**Analog:** `mailglass_inbound/docs/inbound-operator.md` (role-match)

**Troubleshooting doc pattern to copy:** command-oriented sections, explicit flags, and explicit non-overclaim wording (see operator analog lines 8-22, 120-129, 135-143).

### `docs/compatibility-and-deprecations.md` (config, transform)

**Analog:** `guides/compatibility-and-deprecations.md` (partial)

**Mirror pattern to copy:** same two-lane framing and release-guarantee structure (guide lines 20-127), with package-local links adjusted.

## Shared Patterns

### Docs Contract Enforcement
**Source:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (lines 13-32, 128-143)  
**Apply to:** inbound docs edits (`README`, install/operator/testing/api-stability docs)
```elixir
assert doc =~ "required phrase"
refute doc =~ "forbidden phrase"
```

### Tier-1 Drift Guard
**Source:** `lib/mix/tasks/mailglass.docs.check.ex` (lines 24-53, 70-122, 243-251)  
**Apply to:** root and cross-package docs touched in this phase
```elixir
@tier1_paths [...]
@tier1_surface_rules %{path => %{required: [...], forbidden: [...]}}
```

### Operator Trust Boundary
**Source:** `mailglass_inbound/docs/inbound-operator.md` (lines 100-118, 135-143, 173-188) and `mailglass_admin/docs/operator-trust.md` (lines 58-80, 94-107)  
**Apply to:** inbound operator + admin trust docs
```markdown
Require tenant guards and confirmation semantics.
State replay is stored-truth recovery, not fresh receive/reroute/public API.
Keep UI internals explicitly non-contractual.
```

### Testing DX Boundary
**Source:** `mailglass_inbound/docs/inbound-testing.md` (lines 24-33, 117-150) and `mailglass_inbound/README.md` (lines 50-54)  
**Apply to:** README/install/testing guides
```markdown
Use `MailglassInbound.MailboxCase, async: false`.
One assertion per drive; each `assert_inbound_*` consumes capture.
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `docs/compatibility-and-deprecations.md` | config | transform | File is not present in repo; closest current pattern is `guides/compatibility-and-deprecations.md`. |

## Metadata

**Analog search scope:** `mailglass_inbound/`, `mailglass_admin/`, `guides/`, `docs/`, `lib/mix/tasks/`  
**Files scanned:** 9 analog/source files + 2 phase input files  
**Pattern extraction date:** 2026-05-31
