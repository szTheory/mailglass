# Phase 20: Config Schema & Installer Surface for SES + Resend - Research

**Researched:** 2026-04-30  
**Domain:** Mailglass config-schema parity, installer template contract, publish-check drift enforcement  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Config schema posture
- **D-20-01:** Add only the exact SES and Resend config keys that runtime code and public docs already consume today. Do not widen the public schema speculatively.
- **D-20-02:** The Phase 20 parity surface is:
  - `:ses` => `enabled`, `cert_cache_ttl_seconds`
  - `:resend` => `enabled`, `secret`, `timestamp_tolerance_seconds`
- **D-20-03:** `enabled` is a validation-parity key, not router magic. It must not imply route auto-mounting unless a later phase explicitly wires that behavior end-to-end.
- **D-20-04:** Reject the “broader provider config now” path. Mailglass should not accept undocumented or unused SES/Resend keys just to look flexible.

### Installer snippet posture
- **D-20-05:** Keep the installer-generated webhook mount snippet narrow and default-aligned with Phoenix least surprise. Do not make the generated router snippet mount every currently supported provider by default.
- **D-20-06:** The preferred installer example is `mailglass_webhook_routes "/webhooks"` or an explicit equivalent of the default provider set, with nearby guidance that adopters can opt into `:mailgun`, `:ses`, and `:resend` as needed.
- **D-20-07:** Phase 20 must still “surface SES + Resend” in the installer, but it should do so via adjacent explanatory copy or comment, not by silently broadening the generated public webhook surface.
- **D-20-08:** Reject the “full supported-provider list in the install snippet” path. That reads like a recommended default, creates unnecessary public endpoints by copy-paste, and increases future golden churn for a one-maintainer library.

### Publish-check failure contract
- **D-20-09:** Installer golden drift in `mix mailglass.publish.check` should fail through a typed mailglass exception path, not only a plain stderr string.
- **D-20-10:** The typed path must fit Mailglass's actual error architecture: a dedicated sibling exception module such as `Mailglass.PublishError` or `Mailglass.ReleaseError`, not a nonexistent parent `%Mailglass.Error{}` struct and not `Mailglass.ConfigError`.
- **D-20-11:** The error should carry a closed `:type` for this failure class (`:publish_blocked_golden_drift` or an equivalent module-scoped shorthand) and preserve actionable CLI remediation text at the Mix task boundary.
- **D-20-12:** Keep Mix UX boring and familiar. Internals may be typed and testable, but the final user-facing task failure should still read like a normal Mix failure with the exact regeneration command.

### Decision posture for downstream agents
- **D-20-13:** Downstream planning and execution should be decisive by default. Research tradeoffs, recommend the coherent default, and avoid escalating routine local choices back to the user.
- **D-20-14:** Escalate only if a decision would materially alter:
  - the public router/config contract for adopters
  - the error taxonomy promised by Mailglass as a library
  - long-term maintainer burden in a way that meaningfully changes roadmap shape
  - a user-visible workflow default the project owner is likely to care about directly
- **D-20-15:** Prefer boring, idiomatic Elixir/Phoenix library patterns over installer marketing, speculative config APIs, or clever publish-task abstractions.

### the agent's Discretion
- Exact key docstrings and wording inside `Mailglass.Config`, so long as they make `enabled` semantics explicit and do not imply route auto-mounting.
- Exact generated installer comment wording, so long as the default mount stays honest and the opt-in provider path is obvious.
- Final naming choice for the new typed publish exception module and closed `:type`, so long as it remains semantically distinct from adopter config errors and consistent with the rest of the error hierarchy.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Any broader SES or Resend config surface beyond the keys runtime code already consumes.
- Auto-mount semantics tied to provider `enabled` keys. That would be a separate public-contract phase if ever desired.
- Turning the installer into a “supported provider matrix” or marketing surface.
- Broader release/publish taxonomy cleanup beyond the one golden-drift failure class needed here.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Only `Mailglass.Config` may own compile-time config reads; Phase 20 should extend that schema seam instead of adding new `Application.compile_env*` usage elsewhere. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/config.ex]
- Errors are a public API contract and must be matched by struct plus closed `:type`; message strings are presentation only. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md]
- Mailglass prefers narrow explicit surfaces over magic, especially for webhook routing. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/webhook/router.ex]
- Default route surfaces should remain unsurprising; non-default providers stay explicit opt-in. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: guides/webhooks.md]
- Documentation, generated snippets, and error messages should stay clear and specific rather than promotional. [VERIFIED: CLAUDE.md]

## Summary

Phase 20 is a contract-alignment phase, not a provider-behavior phase. The existing runtime and docs already consume a narrow SES surface (`enabled`, `cert_cache_ttl_seconds`) and a narrow Resend surface (`enabled`, `secret`, `timestamp_tolerance_seconds`), but `Mailglass.Config` currently validates only Postmark, SendGrid, and Mailgun subtrees, so adopter typos under `:ses` and `:resend` are silently dropped at boot because `validate_at_boot!/0` takes only top-level known keys and then validates against `@schema`. [VERIFIED: lib/mailglass/config.ex][VERIFIED: lib/mailglass/webhook/plug.ex][VERIFIED: guides/webhooks.md]

The router contract is already correct: the default zero-arg macro mount stays `[:postmark, :sendgrid]`, while Mailgun, SES, and Resend require explicit opt-in. The installer is the drift seam: today it generates `providers: [:postmark, :sendgrid, :mailgun]`, which is broader than the router default and still omits SES and Resend. Phase 20 should narrow the snippet back to the zero-arg default call and surface SES/Resend through nearby comment text so the generated snippet remains copy-paste safe. [VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: guides/webhooks.md]

The publish-check seam already runs installer tests in a subprocess before tarball build, but it fails through stderr text plus `exit({:shutdown, 1})`. The project’s error architecture uses sibling `defexception` modules with closed `:type` sets documented in `docs/api_stability.md`, so Phase 20 should add a dedicated publish/release error sibling and raise it from the drift path, then keep the final Mix boundary message actionable with the exact regeneration command. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]

**Primary recommendation:** Split Phase 20 into two plans: `20-01` for config schema + installer/doc/golden parity, then `20-02` for typed publish-check failure + error-contract tests + validation artifact support. [VERIFIED: .planning/ROADMAP.md][VERIFIED: test/mailglass/config_test.exs][VERIFIED: test/mailglass/install/install_golden_test.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SES/Resend adopter config validation | API / Backend | — | `Mailglass.Config.validate_at_boot!/0` is the central boot-time validation seam for application env. [VERIFIED: lib/mailglass/config.ex] |
| Webhook route default surface | Frontend Server (SSR) | API / Backend | The Phoenix router macro owns which webhook paths become reachable, while `Mailglass.Webhook.Plug` consumes provider opts at request time. [VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: lib/mailglass/webhook/plug.ex] |
| Installer snippet generation | API / Backend | — | `Mailglass.Installer.Templates` produces source text for adopter files; this is a codegen contract, not runtime routing logic. [VERIFIED: lib/mailglass/installer/templates.ex] |
| Pre-publish golden drift enforcement | API / Backend | — | `Mix.Tasks.Mailglass.Publish.Check` is a build-time guard in the core package. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] |
| Golden snapshot verification | API / Backend | — | ExUnit snapshot tests plus `test/example/README.md` own the installer output contract. [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Mailglass.Config` | local module | Boot-time schema validation and normalization. [VERIFIED: lib/mailglass/config.ex] | The repo already centralizes config validation here; Phase 20 should extend this seam instead of adding provider-local readers. [VERIFIED: lib/mailglass/config.ex][VERIFIED: CLAUDE.md] |
| `NimbleOptions` | `~> 1.1` in repo, docs page `v1.1.1`. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] | Closed keyword-list subtrees with explicit accepted keys. [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] | `:keys` on `:keyword_list` is the standard way to reject unknown nested provider keys. [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| `Mailglass.Installer.Templates` | local module | Generates router/runtime snippets that installer tests snapshot. [VERIFIED: lib/mailglass/installer/templates.ex] | Existing installer integration already snapshots this output; changing a different seam would bypass the golden guard. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: test/mailglass/install/install_golden_test.exs] |
| `Mix.Tasks.Mailglass.Publish.Check` | local module | Pre-publish package gate. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] | The task already runs installer goldens first, so typed drift failure belongs here rather than a new release pipeline. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex] |
| Sibling `Mailglass.*Error` modules | local pattern | Typed exception contract with closed `:type`. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md] | The repo already treats error modules as public API surface; Phase 20 should follow that house style. [VERIFIED: lib/mailglass/error.ex][VERIFIED: test/mailglass/error_test.exs] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `ExUnit` / `mix test` | Elixir `1.19.5` / Mix `1.19.5` locally. [VERIFIED: elixir --version][VERIFIED: mix --version] | Config schema tests, golden snapshot tests, and new error-contract tests. [VERIFIED: test/mailglass/config_test.exs][VERIFIED: test/mailglass/install/install_golden_test.exs] | Use for all Phase 20 validation because the existing seams are already unit and fixture based. [VERIFIED: test/mailglass/config_test.exs][VERIFIED: test/mailglass/install/install_golden_test.exs][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| `test/example/README.md` snapshots | local artifact | Golden storage for installer fixture output. [VERIFIED: test/example/README.md] | Refresh when installer template output changes. [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `Mailglass.Config.@schema` | Ad hoc provider-specific runtime lookups | Rejected because it breaks the “single config seam” rule and would keep typo detection inconsistent across providers. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/config.ex] |
| Narrow installer snippet plus comment | Mount every provider in generated router snippet | Rejected by locked decisions because it broadens public endpoints by copy-paste and misstates the default contract. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md][VERIFIED: lib/mailglass/webhook/router.ex] |
| Dedicated publish error sibling | Reusing `Mailglass.ConfigError` | Rejected because golden drift is release hygiene, not adopter config misconfiguration. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md][VERIFIED: lib/mailglass/errors/config_error.ex] |

## Architecture Patterns

### System Architecture Diagram

```text
Adopter config/runtime.exs
  -> Mailglass.Config.validate_at_boot!/0
  -> NimbleOptions nested provider schema
  -> boot succeeds or raises typed validation error

Installer template edit
  -> Mailglass.Installer.Templates.webhook_mount_snippet/1
  -> mix mailglass.install fixture run
  -> test/mailglass/install/install_golden_test.exs
  -> test/example/README.md snapshot

mix mailglass.publish.check
  -> verify_installer_goldens/1 subprocess
  -> golden mismatch detected
  -> typed Mailglass publish error
  -> Mix task failure with exact regen command
```

### Recommended Project Structure

```text
lib/
├── mailglass/config.ex                         # Extend SES + Resend schema only
├── mailglass/installer/templates.ex           # Narrow default snippet; add opt-in comment
├── mix/tasks/mailglass.publish.check.ex       # Raise typed publish drift error
├── mailglass/error.ex                         # Add new sibling module to type union if needed
└── mailglass/errors/publish_error.ex          # New defexception module for release/publish drift

test/
├── mailglass/config_test.exs                  # SES + Resend subtree acceptance/rejection tests
├── mailglass/install/install_golden_test.exs  # Existing snapshot harness; no new file needed
├── mailglass/error_test.exs                   # Closed type set / Mailglass.Error union assertions
└── mailglass/errors/publish_error_test.exs    # New focused tests for new error module

guides/
└── webhooks.md                                # Keep installer wording aligned with router default
```

### Pattern 1: Exact Runtime-Parity Config Subtrees

**What:** Add only the SES and Resend keys that existing runtime/docs already consume, and reject unknown nested keys. [VERIFIED: lib/mailglass/webhook/plug.ex][VERIFIED: guides/webhooks.md][CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]

**When to use:** When Phase 20 needs boot-time typo detection without widening provider APIs. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]

**Example:**

```elixir
# Source: lib/mailglass/config.ex pattern + NimbleOptions nested keys docs
ses: [
  type: :keyword_list,
  default: [],
  keys: [
    enabled: [type: :boolean, default: true],
    cert_cache_ttl_seconds: [type: :pos_integer, default: 86_400]
  ]
],
resend: [
  type: :keyword_list,
  default: [],
  keys: [
    enabled: [type: :boolean, default: true],
    secret: [type: {:or, [:string, nil]}, default: nil],
    timestamp_tolerance_seconds: [type: :pos_integer, default: 300]
  ]
]
```

### Pattern 2: Narrow Default Installer Surface with Adjacent Opt-In Guidance

**What:** Generate `mailglass_webhook_routes "/webhooks"` and add a nearby comment showing how to opt into `:mailgun`, `:ses`, and `:resend`. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: guides/webhooks.md]

**When to use:** When the installer must mention supported providers without changing the recommended public endpoint surface. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]

### Pattern 3: Typed Internal Exception, Familiar Mix Boundary

**What:** Build a dedicated sibling `defexception` with a single closed `:type` for golden drift, then rescue/raise through a normal Mix failure path that preserves the exact remediation command. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md][VERIFIED: lib/mix/tasks/mailglass.publish.check.ex]

**When to use:** When a failure needs testable typing internally but should still present as a normal CLI failure externally. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]

### Anti-Patterns to Avoid

- **Speculative provider keys:** Do not add unused SES/Resend knobs just because provider modules may grow later. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]
- **Installer route broadening by example:** Do not generate `providers: [:postmark, :sendgrid, :mailgun, :ses, :resend]` as the default snippet. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md][VERIFIED: lib/mailglass/webhook/router.ex]
- **Using `Mailglass.ConfigError` for publish drift:** That conflates adopter boot config with maintainer release hygiene. [VERIFIED: lib/mailglass/errors/config_error.ex][VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]
- **String-only publish failure detection:** Do not rely only on stderr text if the library promises typed errors elsewhere. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][VERIFIED: lib/mailglass/error.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Nested provider-key validation | Custom recursive key filtering | `NimbleOptions` `:keyword_list` with `:keys` | Unknown-key rejection and docs generation are already first-class in NimbleOptions. [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| Installer drift detection | New manifest format or bespoke diff engine | Existing snapshot flow in `install_golden_test.exs` + `test/example/README.md` | The repo already has a stable refresh flow and actionable mismatch text. [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md] |
| Publish error taxonomy | Generic `RuntimeError` or bare `Mix.raise` strings only | Sibling `Mailglass.*Error` module with closed `:type` | The repo already documents and tests typed errors as public API. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md][VERIFIED: test/mailglass/error_test.exs] |

**Key insight:** Phase 20 should reuse existing seams end-to-end: `Mailglass.Config` for schema, `Mailglass.Installer.Templates` for generated copy, installer golden tests for drift, and the sibling error pattern for typed failures. Every custom side path would create a second contract to maintain. [VERIFIED: lib/mailglass/config.ex][VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: lib/mailglass/error.ex][VERIFIED: test/mailglass/install/install_golden_test.exs]

## Common Pitfalls

### Pitfall 1: Adding schema keys without matching `normalize_optional_keyword_subtrees/1`

**What goes wrong:** `new!/1` would validate direct calls, but boot-time `validate_at_boot!/0` could still treat `nil` keyword-list subtrees inconsistently if the new subtree is not normalized the same way as other optional keyword lists. [VERIFIED: lib/mailglass/config.ex]

**How to avoid:** Add `:ses` and `:resend` to the normalization list if the project wants `config :mailglass, ses: nil` or `resend: nil` to collapse to `[]` like the other optional keyword-list subtrees. Decide this explicitly in planning; do not leave boot and direct validation with different behavior. [VERIFIED: lib/mailglass/config.ex]

### Pitfall 2: Updating the installer snippet without refreshing the golden source

**What goes wrong:** Template changes drift immediately because snapshots live in `test/example/README.md`. [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md]

**How to avoid:** Sequence snippet edit before golden refresh, then update the README snapshots via `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors`. [VERIFIED: test/mailglass/install/install_golden_test.exs]

### Pitfall 3: Raising a new typed error without updating the public error inventory

**What goes wrong:** `Mailglass.Error.t()`, `Mailglass.Error.is_error?/1`, and `docs/api_stability.md` drift apart from the new module. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md][VERIFIED: test/mailglass/error_test.exs]

**How to avoid:** Treat the new publish error like every other sibling error: new module file, union update, `@error_modules` update, docs update, and closed-type tests. [VERIFIED: lib/mailglass/error.ex][VERIFIED: test/mailglass/error_test.exs]

### Pitfall 4: Losing the exact remediation command at the Mix boundary

**What goes wrong:** A purely typed exception can become technically correct but less helpful than the current failure string if it omits the regenerate command. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][VERIFIED: test/mailglass/install/install_golden_test.exs]

**How to avoid:** Preserve the exact command in the exception message or in the `Mix.raise`/`fail_step` boundary text. The current project-standard refresh command is `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors`. [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md]

## Code Examples

### Existing installer-golden subprocess seam

```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex
{output, status} =
  System.cmd(
    "mix",
    ["test", "test/mailglass/install", "--warnings-as-errors", "--exclude", "flaky"],
    cd: ctx.repo_root,
    env: [{"MIX_ENV", "test"}],
    stderr_to_stdout: true
  )
```

This is already the correct execution seam for Phase 20; only the failure typing needs to change. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex]

### Existing router default contract

```elixir
# Source: lib/mailglass/webhook/router.ex
@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]
@default_providers [:postmark, :sendgrid]
```

This is why the installer should show the zero-arg mount or an explicit equivalent of the default pair, not the full provider list. [VERIFIED: lib/mailglass/webhook/router.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Installer snippet hard-codes `[:postmark, :sendgrid, :mailgun]` | Installer should reflect the router’s zero-arg default and move SES/Resend into opt-in guidance | Phase 20 target state. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: lib/mailglass/webhook/router.ex] | Keeps generated routes honest and reduces unnecessary public endpoints. [VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md] |
| Publish-check drift failure is stderr text + process exit | Publish-check should use a typed Mailglass sibling exception plus the same actionable CLI remediation | Phase 20 target state. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md] | Makes release failures pattern-testable without changing CLI ergonomics. [VERIFIED: lib/mailglass/error.ex] |

## Concrete File Targets

- `lib/mailglass/config.ex`: add `:ses` and `:resend` keyword-list schemas with only the locked keys; review `normalize_optional_keyword_subtrees/1` for parity behavior. [VERIFIED: lib/mailglass/config.ex][VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md]
- `lib/mailglass/installer/templates.ex`: change `webhook_mount_snippet/1` to use the narrow default mount and add comment text for optional `:mailgun`, `:ses`, and `:resend`. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: lib/mailglass/webhook/router.ex]
- `guides/webhooks.md`: ensure generated snippet wording remains aligned with the documented default-vs-opt-in router contract. [VERIFIED: guides/webhooks.md]
- `test/mailglass/config_test.exs`: add positive and negative tests for `:ses` and `:resend` subtrees, mirroring the current Mailgun pattern. [VERIFIED: test/mailglass/config_test.exs]
- `test/example/README.md`: refresh both `GOLDEN_FRESH` and `GOLDEN_NO_ADMIN` snapshots after installer changes. [VERIFIED: test/example/README.md][VERIFIED: test/mailglass/install/install_golden_test.exs]
- `lib/mailglass/errors/publish_error.ex`: add a new sibling exception module with a closed type set containing only the Phase 20 drift atom. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md]
- `lib/mailglass/error.ex`: add the new module to `@type t` and `@error_modules`. [VERIFIED: lib/mailglass/error.ex]
- `docs/api_stability.md`: document the new error sibling and its closed `:type` set. [VERIFIED: docs/api_stability.md]
- `lib/mix/tasks/mailglass.publish.check.ex`: route installer golden drift through the new typed error while preserving the exact remediation command in the Mix-facing failure. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex]
- `test/mailglass/error_test.exs`: extend union/type assertions to include the new publish error. [VERIFIED: test/mailglass/error_test.exs]
- `test/mailglass/errors/publish_error_test.exs`: add focused tests for `__types__/0`, message content, and retryability. [VERIFIED: lib/mailglass/errors/config_error.ex][VERIFIED: test/mailglass/errors/config_error_test.exs]

## Recommended Plan Split

### Plan 20-01: Config + Installer Contract Parity

**Scope:** `lib/mailglass/config.ex`, `lib/mailglass/installer/templates.ex`, `guides/webhooks.md`, `test/mailglass/config_test.exs`, `test/example/README.md`, `test/mailglass/install/install_golden_test.exs`. [VERIFIED: listed files]

**Reasoning:** These edits move together and produce the golden diff; they should land before publish-check typing so the new publish gate can validate the already-correct installer surface. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: test/mailglass/install/install_golden_test.exs]

### Plan 20-02: Typed Publish Drift Failure

**Scope:** `lib/mailglass/errors/publish_error.ex`, `lib/mailglass/error.ex`, `docs/api_stability.md`, `lib/mix/tasks/mailglass.publish.check.ex`, `test/mailglass/error_test.exs`, `test/mailglass/errors/publish_error_test.exs`. [VERIFIED: lib/mailglass/error.ex][VERIFIED: docs/api_stability.md]

**Reasoning:** This is a separate public-error-contract slice with its own tests and docs. Keeping it second avoids mixing golden refresh churn with error-taxonomy churn in one plan. [VERIFIED: lib/mailglass/error.ex][VERIFIED: test/mailglass/error_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Tests, Mix tasks, compilation | ✓ | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Installer golden tests and publish check | ✓ | `1.19.5` [VERIFIED: mix --version] | — |

**Missing dependencies with no fallback:** None for Phase 20’s scoped work. [VERIFIED: elixir --version][VERIFIED: mix --version]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via `mix test`. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Config file | `test/test_helper.exs` is implied by `mix test`; no separate framework config file is required for the listed commands. [VERIFIED: mix.exs][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| Quick run command | `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs --warnings-as-errors` ran successfully in this session. [VERIFIED: local command run 2026-04-30] |
| Full phase command | `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs --warnings-as-errors` after the new error test file exists. [VERIFIED: existing test layout][ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PH20-SC1 | `Mailglass.Config` accepts exact SES/Resend keys and rejects unknown nested keys | unit | `mix test test/mailglass/config_test.exs --warnings-as-errors` | ✅ [VERIFIED: test/mailglass/config_test.exs] |
| PH20-SC2 | Installer snippet keeps narrow default mount while mentioning SES/Resend opt-in | golden | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ [VERIFIED: test/mailglass/install/install_golden_test.exs] |
| PH20-SC3 | README golden snapshots match new installer output | golden | `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` for refresh, then rerun without env var | ✅ [VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: test/example/README.md] |
| PH20-SC4 | Publish-check raises typed golden-drift error and preserves remediation text | unit | `mix test test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs --warnings-as-errors` | ❌ Wave 0 for new focused test file [VERIFIED: test/mailglass/error_test.exs] |
| PH20-SC5 | Publish-check subprocess still exits clean when goldens are in sync | integration-lite | `MIX_PUBLISH=true mix mailglass.publish.check --package mailglass` | ✅ existing task, but Phase 20 should add/assert the typed path under failure conditions [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][ASSUMED] |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs --warnings-as-errors` for Plan 20-01, then `mix test test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs --warnings-as-errors` for Plan 20-02. [VERIFIED: existing tests][ASSUMED]
- **Per wave merge:** `mix test test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs test/mailglass/error_test.exs test/mailglass/errors/publish_error_test.exs --warnings-as-errors`. [VERIFIED: existing tests][ASSUMED]
- **Phase gate:** `MIX_PUBLISH=true mix mailglass.publish.check --package mailglass` after goldens are refreshed and committed. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][ASSUMED]

### Wave 0 Gaps

- [ ] `test/mailglass/errors/publish_error_test.exs` — new focused error-module coverage for the Phase 20 typed failure. [VERIFIED: file absent by provided file list]
- [ ] Failure-path test seam for `Mix.Tasks.Mailglass.Publish.Check` may need a small extracted helper or injectable runner to assert typed drift behavior without mutating committed snapshots. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 20 does not change auth flows. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Installer snippet explicitly keeps webhook pipeline session-free. [VERIFIED: lib/mailglass/installer/templates.ex][VERIFIED: lib/mailglass/webhook/router.ex] |
| V4 Access Control | yes | Keep non-default webhook providers off the default public route surface. [VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md] |
| V5 Input Validation | yes | `Mailglass.Config` + `NimbleOptions` enforce exact SES/Resend accepted keys. [VERIFIED: lib/mailglass/config.ex][CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| V6 Cryptography | no | Phase 20 does not change signature verification algorithms or key handling logic. [VERIFIED: lib/mailglass/webhook/plug.ex][VERIFIED: .planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent acceptance of mistyped provider config | Tampering | Validate exact nested keys at boot so bad config never reaches runtime. [VERIFIED: lib/mailglass/config.ex][CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| Unnecessary public webhook endpoints by generated copy-paste | Elevation of Privilege | Keep installer default mount narrow and require explicit provider opt-in. [VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: lib/mailglass/installer/templates.ex] |
| Shipping stale installer output | Repudiation | Fail publish check before tarball build when goldens drift. [VERIFIED: lib/mix/tasks/mailglass.publish.check.ex][VERIFIED: test/mailglass/install/install_golden_test.exs] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The final full-phase command will include `test/mailglass/errors/publish_error_test.exs` after that file is added. | Validation Architecture | Low; planner can adjust the exact command once the file lands. |
| A2 | The best way to make publish-check failure testable may require extracting a helper or runner seam. | Validation Architecture | Low; execution can still test via subprocess if a smaller seam is unnecessary. |
| A3 | `MIX_PUBLISH=true mix mailglass.publish.check --package mailglass` should remain the phase gate once the typed path lands. | Validation Architecture | Low; the task already exists, but final gate wording may evolve slightly. |

## Open Questions

1. **Should `normalize_optional_keyword_subtrees/1` include `:ses` and `:resend`?**
   - What we know: Existing optional keyword-list subtrees are normalized from `nil` to `[]` before validation, but `:ses` and `:resend` are not present yet. [VERIFIED: lib/mailglass/config.ex]
   - What's unclear: Whether project policy wants `config :mailglass, ses: nil` to behave like other optional subtrees or to raise. [VERIFIED: lib/mailglass/config.ex]
   - Recommendation: Planner should make this an explicit subtask under Plan 20-01 and lock one behavior with tests. [VERIFIED: lib/mailglass/config.ex]

## Sources

### Primary (HIGH confidence)

- `lib/mailglass/config.ex` - current schema, boot validation flow, optional-subtree normalization.
- `lib/mailglass/webhook/router.ex` - default and valid provider route surface.
- `lib/mailglass/webhook/plug.ex` - runtime provider config consumption boundary.
- `lib/mailglass/installer/templates.ex` - current generated webhook snippet.
- `lib/mix/tasks/mailglass.publish.check.ex` - current installer-golden gate and failure path.
- `lib/mailglass/error.ex` - error union and sibling-module house style.
- `lib/mailglass/errors/config_error.ex` - config-error scope boundary.
- `docs/api_stability.md` - public error-contract documentation.
- `test/mailglass/config_test.exs` - existing config test pattern.
- `test/mailglass/install/install_golden_test.exs` - existing golden refresh/test pattern.
- `test/example/README.md` - golden snapshot storage.
- `.planning/phases/20-config-schema-installer-surface-for-ses-resend/20-CONTEXT.md` - locked phase decisions.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `CLAUDE.md`, `.planning/config.json` - planning and project constraints.

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/nimble_options/NimbleOptions.html` - nested `:keyword_list` `:keys` validation and generated docs support.
- `https://hexdocs.pm/mix/Mix.Tasks.Test.html` - `mix test --warnings-as-errors` semantics and test-task behavior.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended seams already exist in repo code and docs. [VERIFIED: listed primary sources]
- Architecture: HIGH - route default, config validation, and publish-check ownership are explicit in current modules. [VERIFIED: lib/mailglass/config.ex][VERIFIED: lib/mailglass/webhook/router.ex][VERIFIED: lib/mix/tasks/mailglass.publish.check.ex]
- Pitfalls: HIGH - each listed pitfall comes from a current local seam that would drift during these edits. [VERIFIED: lib/mailglass/config.ex][VERIFIED: test/mailglass/install/install_golden_test.exs][VERIFIED: lib/mailglass/error.ex]

**Research date:** 2026-04-30  
**Valid until:** 2026-05-30
