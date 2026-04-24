defmodule Mailglass.Properties.WebhookSignatureFailureTest do
  @moduledoc """
  TEST-03 D-27 #2: every webhook signature failure raises EXACTLY ONE
  of the seven `Mailglass.SignatureError.type` atoms (CONTEXT D-21), or
  a `%Mailglass.ConfigError{}` for missing-secret paths.

  Generates random mutations of a valid Postmark request and verifies:

    1. The raised exception is `%SignatureError{}` OR `%ConfigError{}`
       — never another exception class; never silent pass.
    2. When `%SignatureError{}`, the `:type` atom is in the closed set
       of 7 D-21 atoms (the 3 Phase 1 legacy atoms are not reachable
       from Postmark `verify!/3`).
    3. No partial DB writes — the verifier is pure and
       `ingest_multi/3` is never reached, so both
       `mailglass_webhook_events` + `mailglass_events` rows stay at 0.

  ## Why no SendGrid coverage here

  SendGrid `verify!/3` is already exercised by
  `test/mailglass/webhook/providers/sendgrid_test.exs` with explicit
  per-failure-mode tests. The StreamData property test's value is in
  exhausting Postmark's Basic-Auth mutation space (5 orthogonal
  variants × 200 runs = 1000 synthetic attacker requests), which is
  harder to hand-enumerate than SendGrid's crypto path.
  """

  use Mailglass.WebhookCase, async: false
  use ExUnitProperties

  alias Mailglass.{ConfigError, Repo, SignatureError, TestRepo}
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.WebhookEvent

  @moduletag :property
  @moduletag timeout: :infinity

  # Closed set of 7 D-21 atoms (the Phase 1 legacy 3 — :missing, :malformed,
  # :mismatch — are retained in SignatureError.@types for backward
  # compatibility but are not reachable from Postmark `verify!/3`).
  @valid_atoms [
    :missing_header,
    :malformed_header,
    :bad_credentials,
    :ip_disallowed,
    :bad_signature,
    :timestamp_skew,
    :malformed_key
  ]

  setup do
    # Keep DB empty — verifier is pure, no writes should happen.
    Repo.delete_all(WebhookEvent)
    Repo.delete_all(Event)

    on_exit(fn ->
      Repo.delete_all(WebhookEvent)
      Repo.delete_all(Event)
    end)

    :ok
  end

  # Mutation generator — 5 Postmark Basic-Auth failure modes.
  defp mutation_gen do
    member_of([
      :missing_auth,
      :bearer_instead_of_basic,
      :malformed_base64,
      :wrong_user,
      :wrong_pass
    ])
  end

  property "every Postmark signature failure raises exactly one of 7 atoms; no partial writes" do
    check all(mutation <- mutation_gen(), max_runs: 200) do
      # Reset count BEFORE each iteration — nothing should change
      # regardless of mutation shape.
      Repo.delete_all(WebhookEvent)
      Repo.delete_all(Event)

      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      headers = build_mutated_headers(mutation)

      config =
        %{
          basic_auth: {"test_user", "test_pass"},
          ip_allowlist: [],
          remote_ip: {127, 0, 0, 1}
        }

      raised =
        try do
          Mailglass.Webhook.Providers.Postmark.verify!(body, headers, config)
          nil
        rescue
          e in SignatureError -> {:signature, e}
          e in ConfigError -> {:config, e}
        end

      # Contract: a mutation that is supposed to fail MUST raise.
      assert raised != nil,
             "Expected verify!/3 to raise for mutation=#{inspect(mutation)} — got :ok"

      case raised do
        {:signature, e} ->
          assert e.type in @valid_atoms,
                 "Got unexpected SignatureError atom: #{inspect(e.type)} " <>
                   "(must be in #{inspect(@valid_atoms)}) for mutation=#{inspect(mutation)}"

          assert e.provider == :postmark

        {:config, e} ->
          # The only ConfigError path Postmark.verify!/3 raises is
          # :webhook_verification_key_missing — unreachable here because
          # the test fixes `basic_auth` in config. Any ConfigError is a
          # contract violation at the property level.
          flunk(
            "Unexpected ConfigError type=#{inspect(e.type)} for mutation=#{inspect(mutation)} " <>
              "— Postmark.verify!/3 should only raise ConfigError when basic_auth is missing from config"
          )
      end

      # Critical invariant: regardless of which exception raised, NO
      # partial DB writes. The verifier is pure; ingest_multi/3 never
      # runs for failed signatures. `Mailglass.Repo` is a deliberately
      # narrow 9-function facade (no `aggregate/2`); tests reach around
      # via `Mailglass.TestRepo` — same convention as Plan 04-06's
      # `ingest_test.exs`.
      assert TestRepo.aggregate(WebhookEvent, :count) == 0
      assert TestRepo.aggregate(Event, :count) == 0
    end
  end

  # Mutation → headers mapping. Each shape exercises a distinct
  # Postmark.verify!/3 code path.
  defp build_mutated_headers(:missing_auth), do: []

  defp build_mutated_headers(:bearer_instead_of_basic) do
    [{"authorization", "Bearer some-token-value"}]
  end

  defp build_mutated_headers(:malformed_base64) do
    # Basic prefix present, but the base64 payload contains non-alphabet
    # chars → Base.decode64/1 returns :error → :malformed_header.
    [{"authorization", "Basic %%%not-valid-base64%%%"}]
  end

  defp build_mutated_headers(:wrong_user) do
    {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header("wrong_user", "test_pass")
    [{h, v}]
  end

  defp build_mutated_headers(:wrong_pass) do
    {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header("test_user", "wrong_pass")
    [{h, v}]
  end
end
