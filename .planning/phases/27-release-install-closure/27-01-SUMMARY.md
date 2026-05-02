# Phase 27 Plan 01: Change installer generated config default Summary

---
phase: 27-release-install-closure
plan: 01
subsystem: installer
tags:
  - installer
  - config
  - swoosh
dependency_graph:
  requires: []
  provides:
    - REL-17
  affects:
    - lib/mailglass/installer/templates.ex
    - test/mailglass/install/install_first_preview_smoke_test.exs
    - test/example/README.md
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - lib/mailglass/installer/templates.ex
    - test/mailglass/install/install_first_preview_smoke_test.exs
    - test/example/README.md
decisions:
  - "D-27-01: Switched default Swoosh `:api_client` in `mix mailglass.install` from `Swoosh.ApiClient.Finch` to `false`, eliminating boot failure on fresh `mix phx.new --no-mailer` applications without Finch."
metrics:
  duration_minutes: 5
  completed_date: "2026-05-02"
---

## Summary

The installer default was transitioned to set `config :swoosh, :api_client, false` instead of `Swoosh.ApiClient.Finch`. This ensures an honest, package-level stance, aligning with the core package and the admin interface's configurations. A regression sentinel was added to `install_first_preview_smoke_test.exs` ensuring that a fresh host will boot successfully without unexpected HTTP client dependencies. Both `GOLDEN_FRESH` and `GOLDEN_NO_ADMIN` installation test snapshots were successfully regenerated with matching digests.

### Final `runtime_config_body/0`
```elixir
  @doc """
  Returns the managed block body inserted into `runtime.exs`.

  Sets Swoosh's `:api_client` to `false`, matching mailglass's own
  `config/config.exs` and `mailglass_admin/config/config.exs`. Mailglass
  does not pin a specific HTTP client at the package level: API-based
  Swoosh adapters (Postmark, SendGrid, Mailgun, SES, Resend) require an
  HTTP client, but the choice belongs to the adopter. With
  `:api_client` set to `false`, `Swoosh.ApiClient.init/0` no-ops cleanly
  so a fresh `mix phx.new --no-mailer` host boots without needing
  `:finch`, `:hackney`, or `:req` in deps. Adopters using an API-based
  Swoosh adapter must opt in explicitly — the commented examples below
  show how.
  """
  @spec runtime_config_body() :: String.t()
  def runtime_config_body do
    """
    config :mailglass,
      telemetry_prefix: [:mailglass],
      enable_preview: true

    # Swoosh ships three HTTP clients; mailglass does not pin one. Pick the
    # one matching your `:swoosh` adapter dep and uncomment the line below.
    # config :swoosh, :api_client, Swoosh.ApiClient.Finch
    # config :swoosh, :api_client, Swoosh.ApiClient.Hackney
    # config :swoosh, :api_client, Swoosh.ApiClient.Req
    config :swoosh, :api_client, false
    """
  end
```

### Validation
- Both snapshots' digests changed accurately.
- `mix test test/mailglass/install/ --warnings-as-errors` passed (8 tests green).

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
FOUND: test/example/README.md
FOUND: lib/mailglass/installer/templates.ex
FOUND: test/mailglass/install/install_first_preview_smoke_test.exs
