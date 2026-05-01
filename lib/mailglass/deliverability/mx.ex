defmodule Mailglass.Deliverability.MX do
  @moduledoc """
  MX and Null MX analyzer for one organizational domain.
  """

  @type analysis_result :: %{
          required(:findings) => [map()],
          required(:facts) => map()
        }

  @spec analyze(map(), keyword()) :: analysis_result()
  def analyze(mx_facts, _opts \\ []) when is_map(mx_facts) do
    domain = Map.get(mx_facts, :domain)
    records = Map.get(mx_facts, :records, [])

    cond do
      malformed_records?(records) ->
        %{
          findings: [
            finding(
              :cannot_verify,
              :malformed_records,
              "MX answers could not be trusted",
              "Malformed MX data makes it unsafe to claim whether the domain can receive mail.",
              "Observed MX answers for #{domain} but at least one record was missing a valid exchange or preference.",
              "Inspect the DNS answer directly and republish complete MX records before trusting this result."
            )
            |> with_evidence(%{records: records})
          ],
          facts: Map.put(mx_facts, :posture, :cannot_verify)
        }

      records == [] ->
        %{
          findings: [
            finding(
              :warn,
              :missing_records,
              "MX records are absent",
              "No MX answer can mean inbound mail is misconfigured or that the domain is intentionally send-only.",
              "Found no MX records for #{domain}.",
              "If this domain should receive mail, publish MX records. If it is send-only, publish Null MX (`0 .`) so receivers can tell that posture is intentional."
            )
          ],
          facts: Map.put(mx_facts, :posture, :no_mx)
        }

      null_mx?(records) ->
        %{
          findings: [
            finding(
              :pass,
              :null_mx,
              "Null MX marks the domain as send-only",
              "Null MX is the standards-based way to say the domain does not accept inbound mail.",
              "Found explicit Null MX `0 .` for #{domain}.",
              "No change is required if the domain is intentionally send-only. If it should receive mail, replace Null MX with real MX hosts."
            )
            |> with_evidence(%{records: records})
          ],
          facts: Map.put(mx_facts, :posture, :null_mx)
        }

      mixed_null_mx?(records) ->
        %{
          findings: [
            finding(
              :fail,
              :mixed_null_mx,
              "Null MX conflicts with other MX hosts",
              "A Null MX record must stand alone. Mixing `0 .` with other MX records creates contradictory inbound posture.",
              "Found Null MX alongside other MX records for #{domain}.",
              "Publish either one standalone Null MX record for a send-only domain or only real MX hosts for a receiving domain."
            )
            |> with_evidence(%{records: records})
          ],
          facts: Map.put(mx_facts, :posture, :invalid_null_mx)
        }

      true ->
        %{
          findings: [
            finding(
              :pass,
              :mx_present,
              "MX records are published",
              "Published MX hosts give receivers a routable inbound destination for this domain.",
              "Found #{length(records)} MX record(s) for #{domain}.",
              "No change is required unless the listed MX hosts are no longer the intended inbound path."
            )
            |> with_evidence(%{records: records})
          ],
          facts: Map.put(mx_facts, :posture, :mx_present)
        }
    end
  end

  defp null_mx?(records) do
    length(records) == 1 and Enum.all?(records, &null_mx_record?/1)
  end

  defp mixed_null_mx?(records) do
    Enum.any?(records, &null_mx_record?/1) and length(records) > 1
  end

  defp null_mx_record?(%{exchange: exchange, preference: 0}) when is_binary(exchange) do
    String.trim(exchange) == "."
  end

  defp null_mx_record?(_record), do: false

  defp malformed_records?(records) do
    not is_list(records) or Enum.any?(records, &(not valid_mx_record?(&1)))
  end

  defp valid_mx_record?(%{exchange: exchange, preference: preference})
       when is_binary(exchange) and is_integer(preference) do
    String.trim(exchange) != ""
  end

  defp valid_mx_record?(_record), do: false

  defp finding(status, check, title, why_it_matters, observed, remediation) do
    %{
      area: :mx,
      check: check,
      status: status,
      title: title,
      why_it_matters: why_it_matters,
      observed: observed,
      remediation: remediation
    }
  end

  defp with_evidence(finding, evidence), do: Map.put(finding, :evidence, evidence)
end
