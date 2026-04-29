---
phase: 15-mailgun-webhook-provider
reviewed: 2026-04-29T01:17:15Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - lib/mailglass/webhook/provider.ex
  - lib/mailglass/webhook/providers/mailgun_replay_cache.ex
  - lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex
  - lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex
  - lib/mailglass/application.ex
  - lib/mailglass/webhook/providers/mailgun.ex
  - lib/mailglass/webhook/plug.ex
  - lib/mailglass/webhook/router.ex
  - lib/mailglass/config.ex
  - lib/mailglass/webhook/ingest.ex
  - lib/mailglass/installer/templates.ex
  - guides/webhooks.md
  - test/support/webhook_fixtures.ex
  - test/support/webhook_case.ex
  - test/mailglass/webhook/providers/mailgun_test.exs
  - test/mailglass/webhook/plug_mailgun_test.exs
  - test/mailglass/webhook/router_test.exs
  - test/mailglass/config_test.exs
  - test/mailglass/install/install_golden_test.exs
  - test/example/README.md
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---
# Phase 15: Code Review Report

**Reviewed:** 2026-04-29T01:17:15Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the Phase 15 Mailgun provider/runtime/docs/test surface at standard depth. The main defect is in the replay cache: duplicate-token acceptance is implemented as a non-atomic `lookup` plus `insert`, so concurrent replays can bypass the intended protection and both proceed down the verified path.

Targeted verification passed:

- `mix test test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs`

## Critical Issues

### CR-01: Mailgun replay protection is race-prone and can accept the same token twice

**File:** `/Users/jon/projects/mailglass/lib/mailglass/webhook/providers/mailgun_replay_cache.ex:12-23`
**Issue:** `check_and_put/2` performs `:ets.lookup/2` and `:ets.insert/2` as two separate operations on a public ETS table. Two concurrent requests with the same Mailgun token can both observe "no row yet" and both return `:ok`, which defeats `MAILGUN-02` under load and allows replayed requests to reach ingest twice.
**Fix:**
```elixir
def check_and_put(token, %DateTime{} = expires_at) when is_binary(token) do
  now = Mailglass.Clock.utc_now()

  case :ets.lookup(@table, token) do
    [{^token, %DateTime{} = existing_expires_at}] ->
      if DateTime.compare(existing_expires_at, now) == :lt do
        :ets.take(@table, token)
        if :ets.insert_new(@table, {token, expires_at}), do: :ok, else: {:error, :replay}
      else
        {:error, :replay}
      end

    [] ->
      if :ets.insert_new(@table, {token, expires_at}), do: :ok, else: {:error, :replay}
  end
end
```
Use an atomic claim path for fresh tokens. `:ets.insert_new/2` is the key change; if you want the expired-row replacement to be strictly serialized too, route the mutation through the table-owner process instead of exposing a public table write path.

## Warnings

### WR-01: Tests do not cover the concurrent replay path that exposes the cache race

**File:** `/Users/jon/projects/mailglass/test/mailglass/webhook/providers/mailgun_test.exs:72-79`
**Issue:** The replay suite only verifies sequential reuse of the same token. It never starts two verifications at the same time, so the current race in `MailgunReplayCache.check_and_put/2` can ship undetected.
**Fix:**
```elixir
test "only one concurrent verification can claim a fresh token" do
  body = signed_fixture("accepted", token: "mailgun-race-token")

  results =
    1..2
    |> Task.async_stream(fn -> Mailgun.verify!(body, [], @config) end,
      ordered: false,
      max_concurrency: 2
    )
    |> Enum.map(fn {:ok, result} -> result end)

  assert Enum.sort(results) == [:ok, {:ok, :replay}]
end
```

## Info

### IN-01: Webhook tenancy callback docs still omit `:mailgun` from the provider union

**File:** `/Users/jon/projects/mailglass/guides/webhooks.md:193-200`
**Issue:** The guide now documents Mailgun as a first-party webhook provider, but the callback context example still says `provider: :postmark | :sendgrid`. Adopters copying that contract into custom tenancy code will have stale docs for the new provider.
**Fix:** Update the example union to `:postmark | :sendgrid | :mailgun`.

---

_Reviewed: 2026-04-29T01:17:15Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
