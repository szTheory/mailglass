defmodule MailglassAdmin.TestSupport.InboundFixtures do
  @moduledoc """
  Seed helpers for the `MailglassAdmin.InboundLive` test suite.

  Inserts `InboundRecord` + `InboundEvidence` + `ExecutionRun` chains through the
  package-local `MailglassInbound.InboundRecords` boundary. In the admin test env
  `config :mailglass_inbound, :repo, MailglassAdmin.TestRepo` (config/test.exs), so
  these inserts land in the same DB the LiveView reads through the gateway.

  Seeds all three execution outcomes the plan requires — matched (`:accept`),
  `:no_match`, and a `:replay`-source run — so the suite exercises the matched
  detail header, the routing-trace-eligible no-match path, and the replay-source
  timeline badge.
  """

  alias MailglassInbound.InboundRecords

  # Key `MailglassInbound.Execution` stores the durable route binding under.
  @route_binding_key "mailglass_execution_route"
  @fixture_mailbox MyApp.Mailboxes.SupportMailbox

  @doc """
  Inserts a canonical inbound record. Returns the inserted `%InboundRecord{}`.
  """
  def insert_record!(tenant_id, opts \\ []) do
    {:ok, record} =
      InboundRecords.insert_inbound_record(%{
        tenant_id: tenant_id,
        provider: Keyword.get(opts, :provider, "mailgun"),
        provider_message_id: Keyword.get(opts, :provider_message_id, unique("pmid")),
        envelope_recipient: Keyword.get(opts, :recipient, "support@example.com"),
        subject: Keyword.get(opts, :subject, "Inbound fixture"),
        headers: Keyword.get(opts, :headers, %{}),
        received_at: Keyword.get(opts, :received_at, DateTime.utc_now())
      })

    record
  end

  @doc """
  Inserts an evidence row for a record. Returns the inserted `%InboundEvidence{}`.

  `route_binding:` seeds the DURABLE execution route binding the ingress path
  persists on every real evidence row (see `MailglassInbound.Execution`). Pass
  `{:matched, mailbox_module}` or `:no_match`; omit it to model a pre-binding
  (legacy) row. Replay resolves its mailbox from this binding ONLY — the legacy
  "resolve the persisted mailbox string" path was deliberately closed, so a
  matched fixture WITHOUT a binding can never replay.
  """
  def insert_evidence!(tenant_id, record_id, opts \\ []) do
    verification_facts =
      opts
      |> Keyword.get(:verification_facts, %{})
      |> put_route_binding(Keyword.get(opts, :route_binding))

    {:ok, evidence} =
      InboundRecords.insert_inbound_evidence(%{
        tenant_id: tenant_id,
        inbound_record_id: record_id,
        provider: Keyword.get(opts, :provider, "mailgun"),
        raw_payload: Keyword.get(opts, :raw_payload, %{"ok" => true}),
        raw_headers: Keyword.get(opts, :raw_headers, %{}),
        verification_facts: verification_facts,
        parse_warnings: Keyword.get(opts, :parse_warnings, %{})
      })

    evidence
  end

  # Mirrors the shape `MailglassInbound.Execution` reads back out of
  # `verification_facts["mailglass_execution_route"]`. The router key is omitted:
  # the fixture mailbox is not declared on the synthetic test router, and the
  # mailbox-only form resolves against loaded modules carrying the Mailbox
  # behaviour — which `MyApp.Mailboxes.SupportMailbox` does.
  defp put_route_binding(facts, nil), do: facts

  defp put_route_binding(facts, :no_match),
    do: Map.put(facts, @route_binding_key, %{"status" => "no_match"})

  defp put_route_binding(facts, {:matched, mailbox}) when is_atom(mailbox) do
    Code.ensure_loaded!(mailbox)

    Map.put(facts, @route_binding_key, %{
      "status" => "matched",
      "mailbox" => Atom.to_string(mailbox)
    })
  end

  @doc """
  Inserts an execution run. `outcome:` is required; the helper supplies the
  mailbox/outcome_reason the changeset's `validate_outcome_shape/1` requires per
  outcome (`:no_match` takes nil mailbox; matched outcomes need a mailbox; reject/
  bounce need a reason). Returns the inserted `%ExecutionRun{}`.
  """
  def insert_run!(tenant_id, record_id, evidence_id, opts) do
    outcome = Keyword.fetch!(opts, :outcome)

    base = %{
      tenant_id: tenant_id,
      inbound_record_id: record_id,
      inbound_evidence_id: evidence_id,
      source: Keyword.get(opts, :source, :fresh),
      outcome: outcome,
      executed_at: Keyword.get(opts, :executed_at, DateTime.utc_now())
    }

    attrs =
      base
      |> maybe_put(:mailbox, Keyword.get(opts, :mailbox, default_mailbox(outcome)))
      |> maybe_put(:outcome_reason, Keyword.get(opts, :outcome_reason, default_reason(outcome)))

    {:ok, run} = InboundRecords.insert_execution_run(attrs)
    run
  end

  @doc """
  Seeds a full matched record: record + evidence + a fresh `:accept` run AND a
  later `:replay` `:accept` run (so the timeline shows both source badges).
  Returns `%{record: record, evidence: evidence, fresh_run: fresh, replay_run: replay}`.
  """
  def seed_matched!(tenant_id, opts \\ []) do
    record = insert_record!(tenant_id, opts)

    evidence =
      insert_evidence!(
        tenant_id,
        record.id,
        opts
        |> Keyword.get(:evidence, [])
        |> Keyword.put_new(:route_binding, {:matched, @fixture_mailbox})
      )

    fresh =
      insert_run!(tenant_id, record.id, evidence.id,
        source: :fresh,
        mailbox: mailbox_name(),
        outcome: :accept,
        executed_at: hours_ago(2)
      )

    replay =
      insert_run!(tenant_id, record.id, evidence.id,
        source: :replay,
        mailbox: mailbox_name(),
        outcome: :accept,
        executed_at: hours_ago(1)
      )

    %{record: record, evidence: evidence, fresh_run: fresh, replay_run: replay}
  end

  @doc """
  Seeds a record whose only fresh run is `:no_match` (routing-trace eligible).
  Returns `%{record: record, evidence: evidence, run: run}`.
  """
  def seed_no_match!(tenant_id, opts \\ []) do
    record = insert_record!(tenant_id, opts)

    evidence =
      insert_evidence!(
        tenant_id,
        record.id,
        opts
        |> Keyword.get(:evidence, [])
        |> Keyword.put_new(:route_binding, :no_match)
      )

    run =
      insert_run!(tenant_id, record.id, evidence.id,
        source: :fresh,
        outcome: :no_match,
        executed_at: hours_ago(1)
      )

    %{record: record, evidence: evidence, run: run}
  end

  defp default_mailbox(:no_match), do: nil
  defp default_mailbox(_outcome), do: mailbox_name()

  defp mailbox_name, do: Atom.to_string(@fixture_mailbox)

  defp default_reason(outcome) when outcome in [:reject, :bounce], do: "fixture reason"
  defp default_reason(_outcome), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp hours_ago(hours), do: DateTime.add(DateTime.utc_now(), -hours, :hour)

  defp unique(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"
end
