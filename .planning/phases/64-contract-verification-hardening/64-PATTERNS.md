# Phase 64: Contract Verification Hardening - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` | test | request-response | `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` | exact |
| `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | test | transform | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | exact |
| `mailglass_inbound/mix.exs` | config | batch | `mailglass_admin/mix.exs` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/mailglass/stability_contract_test.exs` | test | request-response | `test/mailglass/stability_contract_test.exs` | exact |
| `mailglass_inbound/docs/api_stability.md` | config | transform | `mailglass_inbound/docs/api_stability.md` | exact |

## Pattern Assignments

### `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` (test, request-response)

**Analog:** `mailglass_admin/test/mailglass_admin/stability_contract_test.exs`

**Imports + compiled-doc helper pattern** (`mailglass_admin/test/mailglass_admin/stability_contract_test.exs:1-24`):
```elixir
defmodule MailglassAdmin.StabilityContractTest do
  use ExUnit.Case, async: true

  defp docs!(module) do
    assert {:docs_v1, _, :elixir, _, _, metadata, docs} = Code.fetch_docs(module)
    %{metadata: metadata, docs: docs}
  end

  defp entry_meta!(module, kind, name, arity) do
    %{docs: docs} = docs!(module)

    case Enum.find(docs, fn
           {{^kind, ^name, ^arity}, _, _, _, _} -> true
           _ -> false
         end) do
      {{^kind, ^name, ^arity}, _, _, _, meta} -> meta
      nil -> flunk("missing #{inspect(kind)} #{inspect(module)}.#{name}/#{arity} in compiled docs")
    end
  end

  defp assert_module_since(module, since) do
    %{metadata: metadata} = docs!(module)
    assert metadata[:since] == since, "#{inspect(module)} missing moduledoc since metadata"
  end
```

**Core metadata assertion style** (`mailglass_admin/test/mailglass_admin/stability_contract_test.exs:33-47`):
```elixir
test "router macros are annotated" do
  assert entry_meta!(MailglassAdmin, :function, :version, 0)[:since] == "0.1.0"
  assert entry_meta!(MailglassAdmin.Router, :macro, :mailglass_admin_routes, 2)[:since] == "0.1.0"
  assert entry_meta!(MailglassAdmin.Router, :macro, :mailglass_operator_routes, 2)[:since] == "0.1.0"
end

test "auth callback, helper functions, and public types are annotated" do
  assert entry_meta!(MailglassAdmin.Auth, :callback, :authorize, 2)[:since] == "0.1.0"
  assert entry_meta!(MailglassAdmin.Auth, :function, :authorize, 3)[:since] == "0.1.0"
end
```

**Apply to new inbound file:** same `Code.fetch_docs/1` helper trio, then assert stable module `@moduledoc since` and selected `:function | :macro | :callback` entry metadata only.

---

### `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (test, transform)

**Analog:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` (extend in place)

**Contract section parser pattern** (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:357-365`):
```elixir
defp contract_section!(document, section_name) do
  escaped = Regex.escape(section_name)
  pattern = ~r/^### `#{escaped}`\n([\s\S]*?)(?=^### `|^## |\z)/m

  case Regex.run(pattern, document) do
    [_, section] -> section
    _ -> flunk("Missing #{section_name} contract section")
  end
end
```

**Version-pin truth pattern** (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:342-355`):
```elixir
[_, major_minor] =
  Regex.run(~r/\{:mailglass_inbound,\s*"~>\s*(\d+\.\d+)/, readme) ||
    flunk("README is missing a `{:mailglass_inbound, \"~> X.Y\"}` dep pin")

version = Mix.Project.config()[:version]
[major, minor | _] = String.split(version, ".")

assert major_minor == "#{major}.#{minor}"
```

**Root wiring assertion currently used (to update for new alias target)** (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:323-330`):
```elixir
assert root_mix =~
         "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"
```

**Apply in Phase 64:** reuse section parser to extract each error-module section and assert `Closed :type set` bullets exactly match `module.__types__/0` rendered as ```:atom``` tokens in order.

---

### `mailglass_inbound/mix.exs` (config, batch)

**Analog:** `mailglass_admin/mix.exs`

**`cli/0` preferred env pattern** (`mailglass_admin/mix.exs:33-41`):
```elixir
def cli do
  [
    preferred_envs: [
      "verify.preview": :test,
      "verify.phase_05": :test,
      "verify.support_contract.admin": :test
    ]
  ]
end
```

**Support-contract alias pattern** (`mailglass_admin/mix.exs:187-189`):
```elixir
"verify.support_contract.admin": [
  "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs --warnings-as-errors"
]
```

**Current inbound alias baseline** (`mailglass_inbound/mix.exs:34-38`):
```elixir
defp aliases do
  [
    test: [&configure_test_swoosh/1, "test"]
  ]
end
```

**Apply in Phase 64:** add inbound `cli/0 preferred_envs` entry for `verify.support_contract.inbound`; add `verify.support_contract.inbound` alias aggregating docs-contract + compiled-doc stability test (+ closed-set test if split out).

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs` (existing root aggregate lane)

**Root stability aggregate alias pattern** (`mix.exs:276-282`):
```elixir
"verify.stability_contract": [
  "verify.support_contract.core",
  "cmd --cd mailglass_admin mix verify.support_contract.admin",
  "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors",
  "mailglass.docs.check",
  "compile --no-optional-deps --warnings-as-errors"
]
```

**Root `cli/0` preferred env pattern** (`mix.exs:65-70`):
```elixir
"verify.support_contract.core": :test,
"verify.stability_contract": :test,
"verify.provider_compatibility": :test,
"verify.docs.contract": :test,
"verify.docs.contract.inbound": :test
```

**Apply in Phase 64:** keep root as wiring-only aggregate; swap inbound command string to package-owned `cmd --cd mailglass_inbound mix verify.support_contract.inbound`.

---

### `test/mailglass/stability_contract_test.exs` (test, request-response)

**Analog:** `test/mailglass/stability_contract_test.exs`

**Root wiring assertion pattern** (`test/mailglass/stability_contract_test.exs:52-64`):
```elixir
test "mix.exs exposes verify.stability_contract as the semantic proof entrypoint" do
  mixfile = File.read!("mix.exs")

  assert mixfile =~ "\"verify.stability_contract\""
  assert mixfile =~ "\"verify.support_contract.core\""
  assert mixfile =~ "cmd --cd mailglass_admin mix verify.support_contract.admin"
  assert mixfile =~
           "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors"
  assert mixfile =~ "compile --no-optional-deps --warnings-as-errors"
end
```

**Apply in Phase 64:** preserve string-assertion style; update expected inbound command to delegated alias (`verify.support_contract.inbound`) instead of direct test file invocation.

---

### `mailglass_inbound/docs/api_stability.md` (config, transform)

**Analog:** `mailglass_inbound/docs/api_stability.md`

**Closed-set contract phrasing anchor** (`mailglass_inbound/docs/api_stability.md:59`):
```markdown
- closed `:type` sets for the stable inbound error structs documented below
```

**Stable error list anchor** (`mailglass_inbound/docs/api_stability.md:36-37`):
```markdown
- stable structured errors `MailglassInbound.MIMEError`,
  `MailglassInbound.SignatureError`, and `MailglassInbound.S3FetchError`
```

**Apply in Phase 64:** ensure MIME section contains explicit `Closed :type set` bullet list matching module `__types__/0` exactly and in deterministic order for docs-contract parsing.

## Shared Patterns

### Compiled-doc metadata proof helpers
**Source:** `test/mailglass/stability_contract_test.exs:4-24`, `mailglass_admin/test/mailglass_admin/stability_contract_test.exs:4-24`  
**Apply to:** `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs`
```elixir
defp docs!(module) do
  assert {:docs_v1, _, :elixir, _, _, metadata, docs} = Code.fetch_docs(module)
  %{metadata: metadata, docs: docs}
end
```

### Docs contract section extraction
**Source:** `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs:357-365`  
**Apply to:** centralized inbound `Closed :type set` docs/code lock assertions
```elixir
pattern = ~r/^### `#{escaped}`\n([\s\S]*?)(?=^### `|^## |\z)/m
```

### Package-owned support lane + root aggregation
**Source:** `mailglass_admin/mix.exs:33-41`, `mailglass_admin/mix.exs:187-189`, `mix.exs:276-282`  
**Apply to:** inbound `verify.support_contract.inbound` + root `verify.stability_contract`
```elixir
"cmd --cd <package> mix verify.support_contract.<package>"
```

### Root stability wiring assertions
**Source:** `test/mailglass/stability_contract_test.exs:53-64`  
**Apply to:** root proof remains wiring-only; update expected delegated inbound command string
```elixir
assert mixfile =~ "\"verify.stability_contract\""
assert mixfile =~ "cmd --cd mailglass_inbound mix verify.support_contract.inbound"
```

## No Analog Found

None. All Phase 64 target files have strong analogs in root/admin/inbound tests and Mix alias wiring.

## Metadata

**Analog search scope:** `test/`, `mailglass_admin/test/`, `mailglass_inbound/test/`, root `mix.exs`, `mailglass_admin/mix.exs`, `mailglass_inbound/mix.exs`, `mailglass_inbound/docs/`  
**Files scanned:** 12  
**Pattern extraction date:** 2026-05-31
