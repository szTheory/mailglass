defmodule Mailglass.Deliverability do
  @moduledoc """
  Runtime entrypoint for one-domain deliverability doctor runs.

  Runs the full DNS-only deliverability analyzer suite for one domain.
  """

  alias Mailglass.Deliverability.{BIMI, DKIM, DMARC, MX, Resolver, Result, SPF}

  @type result :: Result.t()

  @spec run(keyword()) :: {:ok, result()} | {:error, term()}
  def run(opts) when is_list(opts) do
    with {:ok, domain} <- fetch_domain(opts),
         {:ok, dkim_selectors} <- fetch_dkim_selectors(opts),
         {:ok, resolver} <- fetch_resolver(opts) do
      collected = collect_facts(domain, dkim_selectors, resolver)
      analyses = analyze_all(collected.facts, resolver)
      facts = Enum.into(analyses, %{}, fn {area, analysis} -> {area, analysis.facts} end)
      findings = Enum.flat_map(ordered_areas(), fn area -> analyses[area].findings end)

      Result.new(
        domain: domain,
        dkim_selectors: dkim_selectors,
        facts: facts,
        findings: findings,
        resolver_errors: collected.resolver_errors
      )
    end
  end

  defp fetch_domain(opts) do
    case Keyword.get(opts, :domain) do
      domain when is_binary(domain) ->
        domain = domain |> String.trim() |> String.downcase()

        if domain == "" do
          {:error, :blank_domain}
        else
          {:ok, domain}
        end

      _ ->
        {:error, :blank_domain}
    end
  end

  defp fetch_dkim_selectors(opts) do
    case Keyword.get(opts, :dkim_selectors, []) do
      selectors when is_list(selectors) ->
        selectors
        |> Enum.reduce_while({:ok, []}, fn selector, {:ok, acc} ->
          case normalize_selector(selector) do
            {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _ ->
        {:error, {:invalid_dkim_selectors, :not_a_list}}
    end
  end

  defp fetch_resolver(opts) do
    resolver = Keyword.get(opts, :resolver, Resolver)

    if is_atom(resolver) and function_exported?(resolver, :lookup_txt, 1) and
         function_exported?(resolver, :lookup_mx, 1) and
         function_exported?(resolver, :lookup_cname, 1) do
      {:ok, resolver}
    else
      {:error, {:invalid_resolver, resolver}}
    end
  end

  defp normalize_selector(selector) when is_binary(selector) do
    selector = String.trim(selector)

    if selector == "" do
      {:error, {:invalid_dkim_selector, selector}}
    else
      {:ok, selector}
    end
  end

  defp normalize_selector(selector), do: {:error, {:invalid_dkim_selector, selector}}

  defp collect_facts(domain, dkim_selectors, resolver) do
    spf_domain = domain
    dmarc_domain = "_dmarc." <> domain
    bimi_domain = "default._bimi." <> domain

    initial = %{facts: Result.empty_facts(), resolver_errors: []}

    initial
    |> put_txt_bucket(:spf, :txt_records, spf_domain, resolver)
    |> put_dkim_bucket(domain, dkim_selectors, resolver)
    |> put_txt_bucket(:dmarc, :txt_records, dmarc_domain, resolver)
    |> put_mx_bucket(domain, resolver)
    |> put_txt_bucket(:bimi, :txt_records, bimi_domain, resolver)
  end

  defp analyze_all(facts, resolver) do
    spf = SPF.analyze(facts.spf, resolver: resolver)
    dkim = DKIM.analyze(facts.dkim)
    dmarc = DMARC.analyze(facts.dmarc)
    mx = MX.analyze(facts.mx)

    bimi =
      BIMI.analyze(
        facts.bimi,
        dmarc_posture: Map.get(dmarc.facts, :posture)
      )

    %{spf: spf, dkim: dkim, dmarc: dmarc, mx: mx, bimi: bimi}
  end

  defp ordered_areas, do: [:spf, :dkim, :dmarc, :mx, :bimi]

  defp put_txt_bucket(state, area, key, domain, resolver) do
    case resolver.lookup_txt(domain) do
      {:ok, records} ->
        update_fact(state, area, %{key => records, domain: domain})

      {:error, reason} ->
        state
        |> update_fact(area, %{key => [], domain: domain})
        |> add_resolver_error(:txt, domain, reason, %{area: area})
    end
  end

  defp put_dkim_bucket(state, _domain, [], _resolver) do
    update_fact(state, :dkim, %{selectors: []})
  end

  defp put_dkim_bucket(state, domain, dkim_selectors, resolver) do
    {selector_entries, selector_errors} =
      Enum.reduce(dkim_selectors, {[], []}, fn selector, {entries, errors} ->
        selector_domain = "#{selector}._domainkey." <> domain

        {selector_entry, txt_errors} =
          case resolver.lookup_txt(selector_domain) do
            {:ok, records} ->
              {%{selector: selector, domain: selector_domain, txt_records: records}, []}

            {:error, reason} ->
              { %{selector: selector, domain: selector_domain, txt_records: []},
                [resolver_error(:txt, selector_domain, reason, %{area: :dkim, selector: selector})] }
          end

        {selector_entry, cname_errors} =
          case resolver.lookup_cname(selector_domain) do
            {:ok, target} ->
              {Map.put(selector_entry, :cname, target), []}

            {:error, reason} ->
              { selector_entry,
                [resolver_error(:cname, selector_domain, reason, %{area: :dkim, selector: selector})] }
          end

        {
          entries ++ [selector_entry],
          errors ++ txt_errors ++ cname_errors
        }
      end)

    state
    |> update_fact(:dkim, %{selectors: selector_entries})
    |> Map.update!(:resolver_errors, &(&1 ++ selector_errors))
  end

  defp put_mx_bucket(state, domain, resolver) do
    case resolver.lookup_mx(domain) do
      {:ok, records} ->
        update_fact(state, :mx, %{domain: domain, records: records})

      {:error, reason} ->
        state
        |> update_fact(:mx, %{domain: domain, records: []})
        |> add_resolver_error(:mx, domain, reason, %{area: :mx})
    end
  end

  defp update_fact(state, area, attrs) do
    put_in(state, [:facts, area], Map.merge(state.facts[area], attrs))
  end

  defp add_resolver_error(state, lookup, domain, reason, context) do
    Map.update!(state, :resolver_errors, &(&1 ++ [resolver_error(lookup, domain, reason, context)]))
  end

  defp resolver_error(lookup, domain, reason, context) do
    %{lookup: lookup, domain: domain, reason: reason, context: context}
  end
end
