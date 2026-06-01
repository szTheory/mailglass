# Phase 63: inbound-contract-inventory-reconciliation - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 2  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/docs/api_stability.md` | config | transform | `mailglass_admin/docs/api_stability.md` | exact |
| `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | test | transform | `test/mailglass/docs_contract_test.exs` | role-match |

## Pattern Assignments

### `mailglass_inbound/docs/api_stability.md` (config, transform)

**Analog:** `mailglass_admin/docs/api_stability.md`  
**Secondary analog:** `docs/api_stability.md`

**Contract posture pattern** (`mailglass_admin/docs/api_stability.md` lines 20-43):
```markdown
## Contract Posture

### `stable`
These surfaces are part of the documented `v1.x` admin contract:
...

### `internal`
These surfaces are implementation details, even when they are reachable:
```

**Semantic-not-reachability guardrail** (`mailglass_admin/docs/api_stability.md` lines 145-150):
```markdown
- If a new admin seam is meant to be stable for adopters, add it here...
- If a module is exported only for Phoenix wiring, keep it documented as internal...
- Do not infer stability from reachability, ExDoc visibility, or tests...
```

**Core taxonomy language to mirror** (`docs/api_stability.md` lines 10-19, 62-79):
```markdown
It answers two distinct questions:
1. What adopters may treat as stable...
2. What is merely reachable or exported...

`Boundary` exports, generated docs visibility, and module reachability are not
the contract by themselves...

### `internal`
These surfaces may be exported... but they are not promised as stable adopter API...
```

**Inbound provider/internal split anchor** (`mailglass_inbound/docs/api_stability.md` lines 53-75):
```markdown
- `MailglassInbound.Ingress.Provider`
- `MailglassInbound.Ingress.Providers.Postmark`
- `MailglassInbound.Ingress.Providers.Sendgrid`
...
Replay orchestration is also internal...
```

### `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (test, transform)

**Analog:** `test/mailglass/docs_contract_test.exs`

**Test module shape and docs reads** (`test/mailglass/docs_contract_test.exs` lines 1-5, 14-16):
```elixir
defmodule Mailglass.DocsContractTest do
  use ExUnit.Case, async: true
  import Mailglass.DocsHelpers
  ...
  readme = File.read!("README.md")
```

**Assertion style: positive + negative contract checks** (`test/mailglass/docs_contract_test.exs` lines 36-41):
```elixir
assert readme =~ "docs/api_stability.md"
...
refute readme =~ "v0.1 in development"
```

**Inbound test pattern already follows this style** (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` lines 25-28, 127-137):
```elixir
assert stability =~ "stable"
assert stability =~ "internal"
assert stability =~ "deferred"

assert stability =~ "MailglassInbound.Execution.Worker"
...
refute stability =~ "stable public replay API"
```

**Verification-lane assertion pattern** (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` lines 188-201):
```elixir
assert root_mix =~
  "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"
```

## Shared Patterns

### Stability Taxonomy Canon
**Source:** `docs/api_stability.md` lines 10-19, 62-79; `mailglass_admin/docs/api_stability.md` lines 20-43, 145-150  
**Apply to:** `mailglass_inbound/docs/api_stability.md`
```markdown
Use explicit buckets (`stable`, `internal`, plus package-specific sections) and
state that reachability/ExDoc visibility does not define contract stability.
```

### Provider Surface Guardrail
**Source:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` lines 1-6, 51-54; `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` lines 1-3  
**Apply to:** `mailglass_inbound/docs/api_stability.md`, inbound docs contract tests
```elixir
# Plug is public ingress seam
defmodule MailglassInbound.Ingress.Plug do
...
unless provider in [:postmark, :sendgrid, :mailgun, :ses] do
  raise ArgumentError, ...
end

# Provider behaviour module is internal
defmodule MailglassInbound.Ingress.Provider do
  @moduledoc false
end
```

### Operator Command Semantics vs Internal Implementations
**Source:** `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` lines 12-37; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` lines 13-39; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` lines 10-41  
**Apply to:** `mailglass_inbound/docs/api_stability.md`
```elixir
@shortdoc "...doctor/replay/prune..."
@moduledoc "...usage + safety semantics..."
alias MailglassInbound.Internal.Doctor
alias MailglassInbound.Internal.Replay
alias MailglassInbound.Internal.Prune
```

### Contract Verification Wiring
**Source:** `mix.exs` lines 276-282, 286-293  
**Apply to:** inbound docs contract assertions and wording claims
```elixir
"verify.stability_contract": [
  "verify.support_contract.core",
  "cmd --cd mailglass_admin mix verify.support_contract.admin",
  "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors",
  "mailglass.docs.check",
  "compile --no-optional-deps --warnings-as-errors"
]
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `docs/`, `mailglass_admin/docs/`, `mailglass_inbound/docs/`, `test/`, `mailglass_inbound/test/`, `mailglass_inbound/lib/`, root `mix.exs`  
**Files scanned:** 10  
**Pattern extraction date:** 2026-05-31
