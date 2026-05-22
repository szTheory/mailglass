defmodule MailglassInbound.Properties.InboundIdempotencyConvergenceTest do
  @moduledoc """
  TELE-08: replaying an arbitrary inbound payload N times through the REAL
  persist + execute write path converges to exactly one `InboundRecord` per
  unique `(tenant_id, provider, provider_message_id)` and exactly one fresh
  `ExecutionRun` per inserted record.

  This is the inbound mirror of `Mailglass.Properties.WebhookIdempotencyConvergenceTest`
  (the shipped outbound HOOK-07 proof). It generates 1000 random scenarios and
  drives them against a real Postgres database via `MailglassInbound.TestRepo`
  (stood up in Plan 45-01) — the dedupe is anchored on the Postgres unique index
  `mailglass_inbound_records_postmark_idempotency_idx`, so only a real DB can
  prove the invariant.

  ## Structural invariant

  Let `U` be the set of unique `MessageID` values across the generated payloads
  (each maps to a distinct `(tenant_id, provider, provider_message_id)` because
  tenant and provider are fixed). For any replay_count:

      aggregate(InboundRecord, :count) == |U|
      aggregate(ExecutionRun where source == :fresh, :count) == |U|

  The unique index enforces the record count at the DB level; `Execution.execute/2`
  on a `:duplicate` persist result returns `{:ok, %{status: :skipped}}` inserting
  zero `ExecutionRun` rows, which enforces the fresh-run count.

  ## Shared-table caveat (RESEARCH Pitfall 4)

  `ExecutionRun` and `ReplayRun` BOTH map to `mailglass_inbound_replay_runs`,
  distinguished by the `source` enum (`:fresh` | `:replay`). The fresh-run
  assertion MUST filter `where: r.source == :fresh` — a naive
  `aggregate(ExecutionRun, :count)` would also count any `ReplayRun` rows.

  ## Test sandbox discipline

  Mirrors the outbound convergence proof (D-45-09):

    * `use ExUnit.Case, async: false` + `use ExUnitProperties` — NOT `DataCase`
      (its per-test transaction wrapper deadlocks against the inter-iteration
      `TRUNCATE`).
    * `Sandbox.start_owner!/2` with `shared: true` and an extended ownership
      timeout so a 1000-iteration run does not lose the connection mid-property.
    * `TRUNCATE ... CASCADE` between iterations — the append-only trigger blocks
      UPDATE/DELETE (SQLSTATE 45A01), so TRUNCATE is the only bulk-wipe path.

  Drives `Execution.execute/2` synchronously (NOT `dispatch/2`, D-45-10):
  `dispatch/2` may enqueue Oban jobs or spawn detached `Task.Supervisor`
  children, producing non-deterministic ExecutionRun counts.
  """

  use ExUnit.Case, async: false
  use ExUnitProperties

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.InboundRecords.ExecutionRun
  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.TestRepo

  @moduletag :property
  @moduletag timeout: :infinity

  @tenant_id "prop-test-tenant"
  @provider "postmark"

  setup do
    owner =
      Sandbox.start_owner!(TestRepo,
        shared: true,
        ownership_timeout: 10 * 60_000
      )

    truncate_all()

    on_exit(fn ->
      Sandbox.stop_owner(owner)
    end)

    :ok
  end

  property "1000-replay convergence: one InboundRecord + one fresh ExecutionRun per unique payload" do
    check all(
            payloads <- list_of(payload_gen(), min_length: 1, max_length: 10),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      # Wipe between iterations — the append-only trigger forbids UPDATE/DELETE,
      # so TRUNCATE CASCADE is the only bulk-reset path.
      truncate_all()

      # Replay each payload `replay_count` times through the REAL write path:
      # persist (DB unique-index dedupe) then execute/2 (sync — NOT dispatch/2).
      for payload <- payloads, _ <- 1..replay_count do
        {:ok, persisted} = Persist.persist(handoff(payload), [])
        _ = Execution.execute(persisted, source: :fresh)
      end

      unique_ids =
        payloads
        |> Enum.map(& &1["MessageID"])
        |> Enum.uniq()

      unique_count = length(unique_ids)

      record_count = TestRepo.aggregate(InboundRecord, :count)

      assert record_count == unique_count,
             """
             InboundRecord convergence failed!
             payloads: #{length(payloads)}
             unique MessageIDs: #{unique_count}
             InboundRecord count: #{record_count}
             replay_count: #{replay_count}
             """

      # Pitfall 4: count ONLY :fresh ExecutionRun rows — the table is shared
      # with ReplayRun, so a naive aggregate over-counts.
      fresh_run_count =
        TestRepo.aggregate(
          from(r in ExecutionRun, where: r.source == :fresh),
          :count
        )

      assert fresh_run_count == unique_count,
             """
             Fresh ExecutionRun convergence failed!
             unique MessageIDs: #{unique_count}
             fresh ExecutionRun count: #{fresh_run_count}
             replay_count: #{replay_count}
             """
    end
  end

  # Wipe both inbound tables. The append-only trigger forbids UPDATE/DELETE;
  # TRUNCATE CASCADE is the only bulk-reset path. inbound_records CASCADE clears
  # evidence + execution rows that FK back to it, but TRUNCATE the run table too
  # in case any orphan-source rows exist.
  defp truncate_all do
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])
  end

  # D-45-12: a small member_of pool so collisions occur across list elements.
  # Postmark-style string-keyed payload with MessageID as the dedupe key.
  defp payload_gen do
    gen all(
          msg_id <- member_of(["m1", "m2", "m3", "m4"]),
          record_type <- member_of(["Inbound"])
        ) do
      %{
        "MessageID" => msg_id,
        "RecordType" => record_type,
        "From" => "a@b.test",
        "To" => "x@y.test"
      }
    end
  end

  # Build the canonical %InboundMessage{} + handoff directly from the payload
  # with a fixed tenant_id + provider "postmark". MessageID is the dedupe key
  # (provider_message_id). Evidence is required by Persist.persist/2's evidence
  # insert; supply a minimal raw_payload echoing the source.
  defp handoff(%{"MessageID" => msg_id} = payload) do
    message = %InboundMessage{
      tenant_id: @tenant_id,
      provider: @provider,
      provider_message_id: msg_id,
      message_id: msg_id,
      envelope_recipient: payload["To"],
      from: [%{address: payload["From"]}],
      to: [%{address: payload["To"]}],
      subject: "Subject #{msg_id}",
      headers: %{},
      received_at: DateTime.utc_now()
    }

    %{
      tenant_id: @tenant_id,
      provider: @provider,
      message: message,
      evidence: %{raw_payload: payload}
    }
  end
end
