---
phase: 15-mailgun-webhook-provider
reviewed: 2026-04-29T01:25:56Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .planning/phases/15-mailgun-webhook-provider/15-01-SUMMARY.md
  - .planning/phases/15-mailgun-webhook-provider/15-02-SUMMARY.md
  - .planning/phases/15-mailgun-webhook-provider/15-03-SUMMARY.md
  - .planning/phases/15-mailgun-webhook-provider/15-04-SUMMARY.md
  - lib/mailglass/webhook/providers/mailgun_replay_cache.ex
  - lib/mailglass/webhook/providers/mailgun.ex
  - lib/mailglass/webhook/plug.ex
  - lib/mailglass/webhook/router.ex
  - lib/mailglass/config.ex
  - lib/mailglass/webhook/ingest.ex
  - guides/webhooks.md
  - test/mailglass/webhook/providers/mailgun_test.exs
  - test/mailglass/webhook/plug_mailgun_test.exs
  - test/mailglass/webhook/router_test.exs
  - test/mailglass/config_test.exs
  - test/mailglass/install/install_golden_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---
# Phase 15: Code Review Report

**Reviewed:** 2026-04-29T01:25:56Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Re-reviewed the final Phase 15 state at commit `31e5a85` (`HEAD`) across the Mailgun provider, replay cache, plug/router/config wiring, docs, and targeted tests.

The prior replay-window finding is resolved. [`lib/mailglass/config.ex`](/Users/jon/projects/mailglass/lib/mailglass/config.ex:595) now rejects `replay_cache_ttl_seconds < timestamp_tolerance_seconds`, and [`test/mailglass/config_test.exs`](/Users/jon/projects/mailglass/test/mailglass/config_test.exs:76) covers that validation. The targeted verification evidence supplied for this review is consistent with the current tree: `mix test test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs --warnings-as-errors` passed with `46 tests, 0 failures`.

One warning remains: the newly documented Mailgun `enabled` flag is still only schema metadata. Explicitly mounted Mailgun routes stay reachable even when `config :mailglass, :mailgun, enabled: false` is set, so the public config contract is misleading and can leave a supposedly disabled endpoint live.

## Warnings

### WR-01: Mailgun `enabled: false` does not disable an explicitly mounted route

**File:** `/Users/jon/projects/mailglass/lib/mailglass/config.ex:288-299`
**Issue:** The Mailgun config schema and guide present `enabled` as a real disable switch (`"Enable the Mailgun webhook route when explicitly mounted."` in [`lib/mailglass/config.ex`](/Users/jon/projects/mailglass/lib/mailglass/config.ex:288) and the runtime example in [`guides/webhooks.md`](/Users/jon/projects/mailglass/guides/webhooks.md:97)). But the generated route path is determined solely by the caller-provided `providers:` list in [`lib/mailglass/webhook/router.ex`](/Users/jon/projects/mailglass/lib/mailglass/webhook/router.ex:89), and `Mailglass.Webhook.Plug` reads only `signing_key` and timing knobs from Mailgun config in [`lib/mailglass/webhook/plug.ex`](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:238). No runtime path consults `enabled`. An adopter can therefore set `enabled: false`, leave `mailglass_webhook_routes "/webhooks", providers: [:mailgun]` in place, and still expose a live `/webhooks/mailgun` endpoint. That is a correctness bug because the documented "disabled" state does not actually disable traffic.
**Fix:**
```elixir
defmacro mailglass_webhook_routes(path, opts \\ []) do
  providers =
    Keyword.get(opts, :providers, @default_providers)
    |> Enum.reject(fn provider -> provider_disabled?(provider) end)

  # ...
end

defp provider_disabled?(:mailgun) do
  Application.get_env(:mailglass, :mailgun, [])[:enabled] == false
end

defp provider_disabled?(_provider), do: false
```

If compile-time env lookup in the router is undesirable, remove `enabled` from the public Mailgun docs/schema and treat explicit route mounting as the only enable/disable mechanism. In either case, add a regression test showing the chosen behavior.

---

_Reviewed: 2026-04-29T01:25:56Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
