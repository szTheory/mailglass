defmodule Mailglass.ReferenceHost.OperatorDiagnosisProof do
  @moduledoc """
  Deterministic reference-host operator diagnosis proof for a no-match route.
  """

  @compile {:no_warn_undefined,
            [
              MailglassAdmin.Components,
              MailglassAdmin.OptionalDeps.MailglassInbound,
              MailglassInbound.InboundRecords.InboundRecord,
              MailglassInbound.Router.Route
            ]}

  @recipient "nomatch@example.com"
  @subject "general question"

  defmodule NoMatchMailbox do
    @moduledoc false
  end

  defmodule NoMatchRouter do
    @moduledoc false

    @spec __mailglass_inbound_routes__() :: [struct()]
    def __mailglass_inbound_routes__ do
      route = MailglassInbound.Router.Route
      mailbox = Mailglass.ReferenceHost.OperatorDiagnosisProof.NoMatchMailbox

      [
        struct(route, mailbox: mailbox, recipient: "support@example.com", subject: nil, headers: []),
        struct(route, mailbox: mailbox, recipient: nil, subject: ~r/^\[billing\]/, headers: []),
        struct(route, mailbox: mailbox, recipient: nil, subject: nil, headers: [{"x-priority", "high"}])
      ]
    end
  end

  @spec run() :: map()
  def run do
    ensure_operator_modules_loaded!()

    record = no_match_record()
    trace = MailglassAdmin.OptionalDeps.MailglassInbound.explain_routes(NoMatchRouter, record)
    masked_recipient = MailglassAdmin.Components.mask_recipient(@recipient)
    true = masked_recipient != @recipient and String.contains?(masked_recipient, "*")

    %{
      "scenario" => "no_match",
      "outcome" => "no_match",
      "stage" => "operator_troubleshooting",
      "status_language" => "no matching mailbox route",
      "finding" => "message did not match any configured inbound route",
      "remediation" => "review recipient, subject, and header route clauses",
      "route_clause_dimensions" => route_clause_dimensions(trace),
      "trace_card_count" => length(trace),
      "recipient_masked" => true,
      "raw_payload_included" => false,
      "private_recipient_included" => false
    }
  end

  defp no_match_record do
    struct(MailglassInbound.InboundRecords.InboundRecord,
      tenant_id: "trust-tenant",
      provider: "mailgun",
      provider_message_id: "operator-no-match-001",
      envelope_recipient: @recipient,
      subject: @subject,
      headers: %{},
      received_at: ~U[2026-05-27 00:00:00Z],
      suppression_flagged: false
    )
  end

  defp route_clause_dimensions(trace) do
    trace
    |> Enum.flat_map(& &1.verdicts)
    |> Enum.flat_map(&dimension_for_verdict/1)
    |> Enum.uniq()
  end

  defp dimension_for_verdict({:recipient, nil, _actual, _pass?}), do: []
  defp dimension_for_verdict({:recipient, _matcher, _actual, _pass?}), do: ["recipient"]
  defp dimension_for_verdict({:subject, nil, _actual, _pass?}), do: []
  defp dimension_for_verdict({:subject, _matcher, _actual, _pass?}), do: ["subject"]
  defp dimension_for_verdict({:header, name, _matcher, _actual, _pass?}), do: ["header:#{name}"]

  defp ensure_operator_modules_loaded! do
    add_reference_host_code_paths(["mailglass_inbound", "mailglass_admin"])

    for module <- [
          MailglassInbound.Router.Route,
          MailglassInbound.InboundRecords.InboundRecord,
          MailglassAdmin.Components,
          MailglassAdmin.OptionalDeps.MailglassInbound
        ] do
      Code.ensure_loaded!(module)
    end
  end

  defp add_reference_host_code_paths(apps) do
    for app <- apps do
      ebin_path = Path.expand("../../../reference/host_app/_build/dev/lib/#{app}/ebin", __DIR__)

      if File.dir?(ebin_path) do
        Code.prepend_path(String.to_charlist(ebin_path))
      end
    end
  end
end
