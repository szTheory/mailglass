# Phase 52: Trust Scope Lock + Reference Host Baseline - Pattern Map

**Mapped:** 2026-05-27  
**Focus:** reference host scaffold, public-seam boundary proof, scope-lock docs enforcement  
**Inputs:** `52-CONTEXT.md`, `52-RESEARCH.md`, `52-VALIDATION.md`, core/admin/inbound stability docs, docs-contract tests, installer smoke proof, fixture boundary docs, docs-check task

Phase 52 should reuse existing repo conventions instead of inventing a new proof style. The strongest precedent is "explicit contract text + deterministic tests + required/forbidden token checks."

## File Classification (Proposed -> Closest Analog)

| Proposed New/Updated File | Role | Closest Analog(s) | Reuse Guidance |
|---|---|---|---|
| `reference/host_app/README.md` | maintained host bootstrap contract (`HOST-01`) | `test/example/README.md`, `README.md`, `test/mailglass/install/install_first_preview_smoke_test.exs` | Keep one canonical setup lane, but clearly mark this host as maintained trust artifact (not fixture seed). |
| `reference/host_app/mix.exs` | committed host baseline app definition | installer-generated `mix.exs` shape captured in `test/example/README.md` golden snapshot | Keep host minimal and reproducible; avoid custom internals or convenience hacks that hide true adopter setup. |
| `reference/host_app/config/runtime.exs` | runtime wiring proof for preview/webhook/public seams | runtime sentinel assertions in `install_first_preview_smoke_test.exs` and runtime snapshot in `test/example/README.md` | Reuse explicit config assertions (required/forbidden lines) for drift detection. |
| `reference/host_app/lib/*_web/router.ex` | public seam integration (`HOST-02`) | installer router snapshot in `test/example/README.md`; route assertions in `install_first_preview_smoke_test.exs`; stability docs for `MailglassAdmin.Router` and `MailglassInbound.Ingress.Plug` | Import and mount only documented seams; no internal modules from core/admin/inbound internals. |
| `reference/host_app/SCOPE.md` | allowlist + non-goals lock (`HOST-03`) | `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md` | Use explicit boundary taxonomy (stable/in-scope vs internal/out-of-scope/deferred). Keep wording testable. |
| `test/reference_host/boot_contract_test.exs` | clean-checkout boot proof (`HOST-01`) | `test/mailglass/install/install_first_preview_smoke_test.exs` | Keep deterministic install/boot assertions and explicit regression sentinels. |
| `test/reference_host/public_seams_contract_test.exs` | enforce public seam-only integration (`HOST-02`) | `test/mailglass/docs_contract_test.exs`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` | Reuse "assert required + refute forbidden" contract style for code/docs references in host app files. |
| `test/reference_host/scope_lock_contract_test.exs` | enforce scope allowlist/non-goals text (`HOST-03`) | `test/mailglass/docs_contract_test.exs`, `lib/mix/tasks/mailglass.docs.check.ex` | Reuse required/forbidden token lists so scope drift fails closed. |
| (Optional) `lib/mix/tasks/mailglass.docs.check.ex` | central docs-gate extension for host scope tokens | existing task itself | If Phase 52 chooses task-level enforcement, follow existing `@tier1_surface_rules` required/forbidden token style and `Delivery blocked:` failure messaging. |

## Reusable Code/Test Patterns

### 1) Required + forbidden contract assertions

Primary analog: docs-contract tests in core and inbound.

```elixir
# test/mailglass/docs_contract_test.exs
assert readme =~ "docs/api_stability.md"
assert readme =~ "guides/compatibility-and-deprecations.md"
refute readme =~ "v0.1 in development"
```

```elixir
# mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
assert stability =~ "stable"
assert stability =~ "internal"
assert stability =~ "deferred"
```

Phase 52 reuse:
- `public_seams_contract_test.exs`: assert allowed seams appear in host wiring/docs.
- `scope_lock_contract_test.exs`: assert required non-goals exist and forbidden expansion claims are absent.

### 2) Deterministic smoke/boot contract structure

Primary analog: installer first-preview smoke test.

```elixir
@tag timeout: 300_000
test "installer + first preview scaffold matches the release-day smoke contract" do
  fixture_root = new_fixture_root!("first-preview-smoke")
  run_install!(fixture_root, [])
  assert File.exists?(Path.join(fixture_root, "lib/example_web/components/layouts/mailglass.html.heex"))
end
```

Phase 52 reuse:
- Mirror deterministic boot checks for `reference/host_app`.
- Keep explicit timeout and explicit sentinel assertions for required files/wiring.

### 3) Token-list enforcement as fail-closed boundary guard

Primary analog: `mix mailglass.docs.check`.

```elixir
@tier1_surface_rules %{
  "README.md" => %{
    required: ["docs/api_stability.md"],
    forbidden: ["v0.1 in development"]
  }
}
```

```elixir
Mix.raise("Delivery blocked: #{length(issues)} Tier 1 docs issue(s) found.")
```

Phase 52 reuse:
- Represent scope lock as explicit required/forbidden token sets (in test module and/or docs-check task extension).
- Keep concise, deterministic failure output that points directly to drift.

### 4) Fixture-vs-maintained-host boundary language

Primary analog: `test/example/README.md`.

```markdown
This directory is the seed copied by installer integration tests into a temporary
workspace.
```

Phase 52 reuse:
- `reference/host_app/README.md` should explicitly state it is maintained trust baseline.
- Keep `test/example` documented as fixture-only to prevent contract confusion.

### 5) Public seam vocabulary lock

Primary analogs: stability inventories.

```markdown
- `Mailglass.deliver/2`, `deliver!/2`, `deliver_later/2`, ...
- `MailglassAdmin.Router.mailglass_admin_routes/2`
- `MailglassInbound.Ingress.Plug`
```

Phase 52 reuse:
- Use exact seam names in host README/router/scope docs and tests.
- Explicitly reject internal modules listed as internal in stability docs.

## Naming Conventions To Reuse

- Test file suffix: `*_contract_test.exs` for deterministic boundary/scope checks.
- Smoke/integration sentinel style: `*_smoke_test.exs` for boot-path proof.
- Module naming style:
  - core contracts: `Mailglass.*ContractTest`
  - package-local contracts: `MailglassInbound.*ContractTest`
  - Phase 52 should follow equivalent `Mailglass.ReferenceHost.*ContractTest` style (or nearest existing naming in `test/reference_host`).
- Path clarity:
  - maintained artifact: `reference/host_app/`
  - fixture-only artifact remains `test/example/`.
- Scope doc headings should be explicit and grep/test friendly (for example: `In Scope`, `Non-Goals`, `Deferred`), matching existing stability-doc boundary posture.

## Verification Conventions To Reuse

- Run ExUnit contract checks with `--warnings-as-errors`.
- Keep a quick lane plus full phase lane (already defined in `52-VALIDATION.md`):
  - quick: `mix test test/reference_host/public_seams_contract_test.exs --warnings-as-errors`
  - full: `mix test test/reference_host/boot_contract_test.exs test/reference_host/public_seams_contract_test.exs test/reference_host/scope_lock_contract_test.exs --warnings-as-errors`
- Use explicit negative grep checks for forbidden internals/scope drift (expect no matches).
- Preserve separation of concerns:
  - fast release smoke (`install_first_preview_smoke_test` and post-publish lane) stays independent
  - maintained host baseline proof is additive and phase-scoped.

## Phase 52 Recommended Mapping Summary

- `HOST-01` -> `reference/host_app/*` scaffold + `boot_contract_test.exs`, patterned after installer smoke and fixture snapshots.
- `HOST-02` -> `public_seams_contract_test.exs`, patterned after docs-contract required/forbidden assertions and stability seam vocabulary.
- `HOST-03` -> `SCOPE.md` + `scope_lock_contract_test.exs` (optionally mirrored in `mix mailglass.docs.check`), patterned after stability taxonomy and token-list drift checks.

## PATTERN MAPPING COMPLETE
