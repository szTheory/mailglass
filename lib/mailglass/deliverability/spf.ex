defmodule Mailglass.Deliverability.SPF do
  @moduledoc """
  Standards-aware SPF analyzer for one organizational domain.
  """

  alias Mailglass.Deliverability.Resolver

  @near_lookup_limit 8
  @lookup_limit 10
  @lookup_mechanisms [:include, :a, :mx, :ptr, :exists]

  @type analysis_result :: %{
          required(:findings) => [map()],
          required(:facts) => map()
        }

  @spec analyze(map(), keyword()) :: analysis_result()
  def analyze(spf_facts, opts \\ []) when is_map(spf_facts) and is_list(opts) do
    resolver = Keyword.get(opts, :resolver, Resolver)
    domain = Map.get(spf_facts, :domain)
    txt_records = Map.get(spf_facts, :txt_records, [])
    spf_records = Enum.filter(txt_records, &spf_record?/1)

    case spf_records do
      [] ->
        issue_result(
          spf_facts,
          [
            finding(
              :fail,
              :missing_record,
              "SPF record is missing",
              "Mailbox providers expect one SPF policy for the sending domain.",
              "Found no TXT record that starts with v=spf1.",
              "Publish exactly one SPF TXT record for this domain."
            )
          ]
        )

      [_first, _second | _rest] = records ->
        issue_result(
          spf_facts,
          [
            finding(
              :fail,
              :multiple_records,
              "Multiple SPF records were published",
              "SPF permits exactly one policy record. Multiple records turn evaluation into a permanent error.",
              "Found #{length(records)} SPF TXT records for #{domain}.",
              "Merge the mechanisms into one v=spf1 record."
            )
            |> with_evidence(%{spf_records: records})
          ]
        )

      [record] ->
        analyze_record(spf_facts, record, resolver)
    end
  end

  defp analyze_record(spf_facts, record, resolver) do
    case parse_spf_record(record) do
      {:error, reason} ->
        issue_result(
          spf_facts,
          [
            finding(
              :fail,
              :malformed_record,
              "SPF record syntax is malformed",
              "Malformed SPF syntax can make the domain fail authentication even when the intent was correct.",
              "Could not parse #{inspect(record)}: #{format_parse_error(reason)}.",
              "Fix the SPF syntax so every mechanism and modifier is valid."
            )
          ]
        )

      {:ok, parsed} ->
        analysis =
          parsed
          |> new_analysis()
          |> walk_record(spf_facts[:domain], resolver, MapSet.new([spf_facts[:domain]]))

        facts =
          spf_facts
          |> Map.put(:record, record)
          |> Map.put(:lookup_count, analysis.lookup_count)
          |> Map.put(:void_lookup_count, analysis.void_lookup_count)
          |> Map.put(:visited_includes, Enum.reverse(analysis.visited_includes))
          |> Map.put(:visited_redirects, Enum.reverse(analysis.visited_redirects))
          |> Map.put(:terminal_policy, terminal_policy(parsed))

        findings =
          []
          |> maybe_add_terminal_policy(parsed)
          |> maybe_add_lookup_pressure(analysis)
          |> maybe_add_void_lookup_warning(analysis)
          |> maybe_add_structural_failures(analysis)
          |> maybe_add_uncertainty(analysis)
          |> maybe_add_pass(facts)

        %{findings: findings, facts: facts}
    end
  end

  defp issue_result(spf_facts, findings), do: %{findings: findings, facts: spf_facts}

  defp maybe_add_terminal_policy(findings, parsed) do
    case terminal_policy(parsed) do
      "-all" ->
        findings

      policy ->
        [
          finding(
            :warn,
            :weak_terminal_policy,
            "SPF terminal policy is not strict",
            "A record without a terminal -all can leave room for unintended hosts or ambiguous operator intent.",
            observed_terminal_policy(policy),
            "End the SPF record with -all once you have confirmed every legitimate sender is listed."
          )
          | findings
        ]
    end
  end

  defp maybe_add_lookup_pressure(findings, analysis) when analysis.lookup_count >= @lookup_limit do
    [
      finding(
        :fail,
        :lookup_limit_exceeded,
        "SPF lookup pressure reached the RFC 7208 ceiling",
        "SPF evaluation stops with a permanent error when DNS lookup pressure reaches the 10-term limit.",
        "Computed #{analysis.lookup_count} lookup-causing terms across includes, redirects, and lookup mechanisms.",
        "Flatten the SPF policy so it stays below 10 DNS lookups."
      )
      |> with_evidence(lookup_evidence(analysis))
      | findings
    ]
  end

  defp maybe_add_lookup_pressure(findings, analysis)
       when analysis.lookup_count >= @near_lookup_limit do
    [
      finding(
        :warn,
        :lookup_limit_near,
        "SPF lookup pressure is close to the RFC 7208 ceiling",
        "Records near the 10-term lookup limit are fragile and can break after future provider changes.",
        "Computed #{analysis.lookup_count} lookup-causing terms across includes, redirects, and lookup mechanisms.",
        "Remove unnecessary includes or flatten the SPF policy before it reaches 10 DNS lookups."
      )
      |> with_evidence(lookup_evidence(analysis))
      | findings
    ]
  end

  defp maybe_add_lookup_pressure(findings, _analysis), do: findings

  defp maybe_add_void_lookup_warning(findings, analysis) when analysis.void_lookup_count > 0 do
    [
      finding(
        :warn,
        :void_lookup_pressure,
        "SPF evaluation hit empty include or MX lookups",
        "Repeated empty lookups make the policy fragile and can push real mailbox-provider evaluation toward failure.",
        "Detected #{analysis.void_lookup_count} empty include or MX lookups while walking the SPF policy.",
        "Remove dead include targets and fix empty MX references inside the SPF tree."
      )
      |> with_evidence(%{
        void_lookup_count: analysis.void_lookup_count,
        void_domains: Enum.reverse(analysis.void_domains)
      })
      | findings
    ]
  end

  defp maybe_add_void_lookup_warning(findings, _analysis), do: findings

  defp maybe_add_structural_failures(findings, %{structural_failures: []}), do: findings

  defp maybe_add_structural_failures(findings, analysis) do
    observed =
      analysis.structural_failures
      |> Enum.reverse()
      |> Enum.map_join("; ", &format_structural_failure/1)

    [
      finding(
        :fail,
        :invalid_spf_tree,
        "Nested SPF includes or redirects are structurally invalid",
        "An include or redirect that points to missing, malformed, or looping SPF data can invalidate the whole SPF evaluation.",
        observed,
        "Repair or remove the broken include and redirect targets in the SPF tree."
      )
      |> with_evidence(%{failures: Enum.reverse(analysis.structural_failures)})
      | findings
    ]
  end

  defp maybe_add_uncertainty(findings, %{uncertainties: []}), do: findings

  defp maybe_add_uncertainty(findings, analysis) do
    observed =
      analysis.uncertainties
      |> Enum.reverse()
      |> Enum.map_join("; ", &format_uncertainty/1)

    [
      finding(
        :cannot_verify,
        :resolver_uncertainty,
        "SPF tree could not be fully verified from DNS",
        "Resolver failures or malformed nested answers prevent the doctor from making a trustworthy SPF claim.",
        observed,
        "Retry the lookup, inspect the delegated SPF hosts directly, and fix the resolver-side errors before trusting the result."
      )
      |> with_evidence(%{uncertainties: Enum.reverse(analysis.uncertainties)})
      | findings
    ]
  end

  defp maybe_add_pass(findings, facts) when findings == [] do
    [
      finding(
        :pass,
        :record_valid,
        "SPF record structure looks healthy",
        "A single well-formed SPF record with controlled lookup pressure is the safest DNS posture Mailglass can confirm.",
        "Found one SPF record with terminal -all and #{facts.lookup_count} lookup-causing terms.",
        "No action required unless your sender inventory changes."
      )
      |> with_evidence(%{
        lookup_count: facts.lookup_count,
        void_lookup_count: facts.void_lookup_count,
        visited_includes: facts.visited_includes,
        visited_redirects: facts.visited_redirects
      })
    ]
  end

  defp maybe_add_pass(findings, _facts), do: Enum.reverse(findings)

  defp new_analysis(parsed) do
    %{
      parsed: parsed,
      lookup_count: 0,
      void_lookup_count: 0,
      visited_includes: [],
      visited_redirects: [],
      void_domains: [],
      structural_failures: [],
      uncertainties: []
    }
  end

  defp walk_record(analysis, domain, resolver, visited_domains) do
    analysis
    |> walk_terms(domain, resolver, visited_domains, analysis.parsed.terms)
    |> maybe_follow_redirect(domain, resolver, visited_domains, analysis.parsed.redirect)
  end

  defp walk_terms(analysis, _domain, _resolver, _visited_domains, []), do: analysis

  defp walk_terms(analysis, domain, resolver, visited_domains, [term | rest]) do
    analysis =
      analysis
      |> increment_lookup(term)
      |> maybe_follow_include(term, resolver, visited_domains)
      |> maybe_check_mx(term, domain, resolver)

    walk_terms(analysis, domain, resolver, visited_domains, rest)
  end

  defp maybe_follow_include(
         analysis,
         %{kind: :include, value: include_domain},
         resolver,
         visited_domains
       ) do
    analysis =
      %{analysis | visited_includes: [include_domain | analysis.visited_includes]}

    cond do
      MapSet.member?(visited_domains, include_domain) ->
        add_structural_failure(analysis, {:loop, :include, include_domain})

      true ->
        resolve_nested_spf(
          analysis,
          include_domain,
          resolver,
          MapSet.put(visited_domains, include_domain)
        )
    end
  end

  defp maybe_follow_include(analysis, _term, _resolver, _visited_domains), do: analysis

  defp maybe_follow_redirect(analysis, _domain, _resolver, _visited_domains, nil), do: analysis

  defp maybe_follow_redirect(analysis, _domain, resolver, visited_domains, redirect_domain) do
    analysis =
      %{
        analysis
        | visited_redirects: [redirect_domain | analysis.visited_redirects],
          lookup_count: analysis.lookup_count + 1
      }

    cond do
      MapSet.member?(visited_domains, redirect_domain) ->
        add_structural_failure(analysis, {:loop, :redirect, redirect_domain})

      true ->
        resolve_nested_spf(
          analysis,
          redirect_domain,
          resolver,
          MapSet.put(visited_domains, redirect_domain)
        )
    end
  end

  defp maybe_check_mx(analysis, %{kind: :mx, value: nil}, domain, resolver) do
    case resolver.lookup_mx(domain) do
      {:ok, []} ->
        add_void_lookup(analysis, domain)

      {:ok, _records} ->
        analysis

      {:error, reason} when reason in [:nxdomain, :not_found] ->
        add_void_lookup(analysis, domain)

      {:error, reason} ->
        add_uncertainty(analysis, {:mx, domain, reason})
    end
  end

  defp maybe_check_mx(analysis, %{kind: :mx, value: mx_domain}, _domain, resolver) do
    case resolver.lookup_mx(mx_domain) do
      {:ok, []} ->
        add_void_lookup(analysis, mx_domain)

      {:ok, _records} ->
        analysis

      {:error, reason} when reason in [:nxdomain, :not_found] ->
        add_void_lookup(analysis, mx_domain)

      {:error, reason} ->
        add_uncertainty(analysis, {:mx, mx_domain, reason})
    end
  end

  defp maybe_check_mx(analysis, _term, _domain, _resolver), do: analysis

  defp resolve_nested_spf(analysis, domain, resolver, visited_domains) do
    case resolver.lookup_txt(domain) do
      {:ok, records} ->
        nested_records = Enum.filter(records, &spf_record?/1)

        case nested_records do
          [] ->
            analysis
            |> add_void_lookup(domain)
            |> add_structural_failure({:missing_nested_record, domain})

          [_first, _second | _rest] ->
            add_structural_failure(analysis, {:multiple_nested_records, domain})

          [record] ->
            case parse_spf_record(record) do
              {:ok, parsed} ->
                nested_analysis = %{analysis | parsed: parsed}
                walk_record(nested_analysis, domain, resolver, visited_domains)

              {:error, reason} ->
                add_structural_failure(analysis, {:malformed_nested_record, domain, reason})
            end
        end

      {:error, reason} when reason in [:nxdomain, :not_found] ->
        analysis
        |> add_void_lookup(domain)
        |> add_structural_failure({:missing_nested_record, domain})

      {:error, reason} ->
        add_uncertainty(analysis, {:txt, domain, reason})
    end
  end

  defp increment_lookup(analysis, %{kind: kind})
       when kind in @lookup_mechanisms,
       do: %{analysis | lookup_count: analysis.lookup_count + 1}

  defp increment_lookup(analysis, _term), do: analysis

  defp add_void_lookup(analysis, domain) do
    %{
      analysis
      | void_lookup_count: analysis.void_lookup_count + 1,
        void_domains: [domain | analysis.void_domains]
    }
  end

  defp add_structural_failure(analysis, failure) do
    %{analysis | structural_failures: [failure | analysis.structural_failures]}
  end

  defp add_uncertainty(analysis, uncertainty) do
    %{analysis | uncertainties: [uncertainty | analysis.uncertainties]}
  end

  defp parse_spf_record(record) when is_binary(record) do
    trimmed = String.trim(record)

    with true <- spf_record?(trimmed),
         terms <- String.split(trimmed, ~r/\s+/, trim: true) |> Enum.drop(1),
         {:ok, parsed_terms} <- parse_terms(terms, [], nil) do
      {:ok, parsed_terms}
    else
      false -> {:error, :missing_prefix}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_terms([], acc, redirect), do: {:ok, %{terms: Enum.reverse(acc), redirect: redirect}}

  defp parse_terms([token | rest], acc, redirect) do
    case parse_term(token) do
      {:ok, {:redirect, domain}} ->
        if redirect do
          {:error, :multiple_redirect_modifiers}
        else
          parse_terms(rest, acc, domain)
        end

      {:ok, term} ->
        parse_terms(rest, [term | acc], redirect)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_term(""), do: {:error, :blank_term}

  defp parse_term(token) do
    {qualifier, remainder} = split_qualifier(token)

    cond do
      remainder == "all" ->
        {:ok, %{kind: :all, qualifier: qualifier, value: nil}}

      String.starts_with?(remainder, "include:") ->
        parse_lookup_value(:include, qualifier, String.trim_leading(remainder, "include:"))

      String.starts_with?(remainder, "exists:") ->
        parse_lookup_value(:exists, qualifier, String.trim_leading(remainder, "exists:"))

      remainder == "a" ->
        {:ok, %{kind: :a, qualifier: qualifier, value: nil}}

      String.starts_with?(remainder, "a:") ->
        parse_lookup_value(:a, qualifier, String.trim_leading(remainder, "a:"))

      remainder == "mx" ->
        {:ok, %{kind: :mx, qualifier: qualifier, value: nil}}

      String.starts_with?(remainder, "mx:") ->
        parse_lookup_value(:mx, qualifier, String.trim_leading(remainder, "mx:"))

      remainder == "ptr" ->
        {:ok, %{kind: :ptr, qualifier: qualifier, value: nil}}

      String.starts_with?(remainder, "ptr:") ->
        parse_lookup_value(:ptr, qualifier, String.trim_leading(remainder, "ptr:"))

      String.starts_with?(remainder, "redirect=") ->
        parse_redirect(String.trim_leading(remainder, "redirect="))

      String.starts_with?(remainder, "ip4:") or String.starts_with?(remainder, "ip6:") ->
        {:ok, %{kind: :ip, qualifier: qualifier, value: remainder}}

      String.starts_with?(remainder, "exp=") ->
        {:ok, %{kind: :exp, qualifier: qualifier, value: remainder}}

      true ->
        {:error, {:unknown_term, token}}
    end
  end

  defp parse_lookup_value(_kind, _qualifier, ""), do: {:error, :blank_lookup_target}

  defp parse_lookup_value(kind, qualifier, value) do
    {:ok, %{kind: kind, qualifier: qualifier, value: value}}
  end

  defp parse_redirect(""), do: {:error, :blank_redirect_target}
  defp parse_redirect(domain), do: {:ok, {:redirect, domain}}

  defp split_qualifier(<<qualifier::binary-size(1), rest::binary>>)
       when qualifier in ["+", "-", "~", "?"] do
    {qualifier, rest}
  end

  defp split_qualifier(token), do: {"+", token}

  defp terminal_policy(parsed) do
    case List.last(parsed.terms) do
      %{kind: :all, qualifier: qualifier} -> qualifier <> "all"
      _ -> "absent"
    end
  end

  defp observed_terminal_policy("absent"), do: "The SPF record does not end with an all mechanism."
  defp observed_terminal_policy(policy), do: "The SPF record ends with #{policy}."

  defp lookup_evidence(analysis) do
    %{
      lookup_count: analysis.lookup_count,
      void_lookup_count: analysis.void_lookup_count,
      visited_includes: Enum.reverse(analysis.visited_includes),
      visited_redirects: Enum.reverse(analysis.visited_redirects)
    }
  end

  defp spf_record?(record) when is_binary(record) do
    String.match?(String.trim(record), ~r/^v=spf1(?:\s|$)/i)
  end

  defp spf_record?(_record), do: false

  defp format_parse_error(:missing_prefix), do: "missing v=spf1 prefix"
  defp format_parse_error(:multiple_redirect_modifiers), do: "multiple redirect modifiers"
  defp format_parse_error(:blank_lookup_target), do: "blank lookup target"
  defp format_parse_error(:blank_redirect_target), do: "blank redirect target"
  defp format_parse_error({:unknown_term, token}), do: "unknown term #{inspect(token)}"
  defp format_parse_error(other), do: inspect(other)

  defp format_structural_failure({:loop, kind, domain}),
    do: "#{kind} target #{domain} loops back into an already-visited SPF domain"

  defp format_structural_failure({:missing_nested_record, domain}),
    do: "nested SPF target #{domain} published no SPF record"

  defp format_structural_failure({:multiple_nested_records, domain}),
    do: "nested SPF target #{domain} published multiple SPF records"

  defp format_structural_failure({:malformed_nested_record, domain, reason}),
    do: "nested SPF target #{domain} is malformed (#{format_parse_error(reason)})"

  defp format_uncertainty({lookup, domain, reason}),
    do: "#{lookup} lookup for #{domain} returned #{reason}"

  defp finding(status, check, title, why_it_matters, observed, remediation) do
    %{
      area: :spf,
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
