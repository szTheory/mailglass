defmodule Mailglass.Deliverability.Result do
  @moduledoc """
  Shared plain-data contract for `mix mail.doctor` runtime results.

  The result shape is the single source of truth for both human and JSON
  output. Formatters must consume this data directly rather than scraping text.

  ## Status Contract

  Findings use a closed status set:

  - `:pass`
  - `:warn`
  - `:fail`
  - `:cannot_verify`

  `:cannot_verify` is a first-class outcome. Resolver uncertainty, missing
  explicit DKIM selectors, and malformed DNS answers must stay visible as data
  instead of being coerced into `:fail`.
  """

  @schema_version 1
  @statuses [:pass, :warn, :fail, :cannot_verify]
  @areas [:spf, :dkim, :dmarc, :mx, :bimi]
  @resolver_lookups [:txt, :mx, :cname]
  @finding_keys [:area, :check, :status, :title, :why_it_matters, :observed, :remediation]

  @type status :: :pass | :warn | :fail | :cannot_verify

  @type finding :: %{
          required(:area) => atom(),
          required(:check) => atom(),
          required(:status) => status(),
          required(:title) => String.t(),
          required(:why_it_matters) => String.t(),
          required(:observed) => String.t(),
          required(:remediation) => String.t(),
          optional(:evidence) => term()
        }

  @type summary :: %{
          required(:pass) => non_neg_integer(),
          required(:warn) => non_neg_integer(),
          required(:fail) => non_neg_integer(),
          required(:cannot_verify) => non_neg_integer()
        }

  @type resolver_error :: %{
          required(:lookup) => :txt | :mx | :cname,
          required(:domain) => String.t(),
          required(:reason) => atom(),
          optional(:context) => map()
        }

  @type facts :: %{
          required(:spf) => map(),
          required(:dkim) => map(),
          required(:dmarc) => map(),
          required(:mx) => map(),
          required(:bimi) => map()
        }

  @type t :: %{
          required(:schema_version) => pos_integer(),
          required(:domain) => String.t(),
          required(:dkim_selectors) => [String.t()],
          required(:summary) => summary(),
          required(:findings) => [finding()],
          required(:facts) => facts(),
          required(:resolver_errors) => [resolver_error()]
        }

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec statuses() :: [status()]
  def statuses, do: @statuses

  @spec status?(term()) :: boolean()
  def status?(status), do: status in @statuses

  @spec new(keyword() | map()) :: {:ok, t()} | {:error, term()}
  def new(opts) when is_map(opts), do: opts |> Enum.into([]) |> new()

  def new(opts) when is_list(opts) do
    with {:ok, domain} <- normalize_domain(Keyword.get(opts, :domain)),
         {:ok, dkim_selectors} <- normalize_selectors(Keyword.get(opts, :dkim_selectors, [])),
         {:ok, findings} <- normalize_findings(Keyword.get(opts, :findings, [])),
         {:ok, facts} <- normalize_facts(Keyword.get(opts, :facts, %{})),
         {:ok, resolver_errors} <-
           normalize_resolver_errors(Keyword.get(opts, :resolver_errors, [])) do
      {:ok,
       %{
         schema_version: @schema_version,
         domain: domain,
         dkim_selectors: dkim_selectors,
         summary: summary(findings),
         findings: findings,
         facts: facts,
         resolver_errors: resolver_errors
       }}
    end
  end

  @spec summary([finding()]) :: summary()
  def summary(findings) when is_list(findings) do
    Enum.reduce(findings, empty_summary(), fn finding, acc ->
      Map.update!(acc, finding.status, &(&1 + 1))
    end)
  end

  @spec empty_summary() :: summary()
  def empty_summary do
    %{pass: 0, warn: 0, fail: 0, cannot_verify: 0}
  end

  @spec empty_facts() :: facts()
  def empty_facts do
    %{spf: %{}, dkim: %{}, dmarc: %{}, mx: %{}, bimi: %{}}
  end

  defp normalize_domain(domain) when is_binary(domain) do
    domain = String.trim(domain)

    if domain == "" do
      {:error, :domain_required}
    else
      {:ok, domain}
    end
  end

  defp normalize_domain(_), do: {:error, :domain_required}

  defp normalize_selectors(selectors) when is_list(selectors) do
    selectors
    |> Enum.reduce_while({:ok, []}, fn selector, {:ok, acc} ->
      case normalize_selector(selector) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_selectors(_), do: {:error, {:invalid_dkim_selectors, :not_a_list}}

  defp normalize_selector(selector) when is_binary(selector) do
    selector = String.trim(selector)

    if selector == "" do
      {:error, {:invalid_dkim_selector, selector}}
    else
      {:ok, selector}
    end
  end

  defp normalize_selector(selector), do: {:error, {:invalid_dkim_selector, selector}}

  defp normalize_findings(findings) when is_list(findings) do
    Enum.reduce_while(findings, {:ok, []}, fn finding, {:ok, acc} ->
      case normalize_finding(finding) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_findings(_), do: {:error, {:invalid_findings, :not_a_list}}

  defp normalize_finding(finding) when is_map(finding) do
    with :ok <- validate_finding_keys(finding),
         {:ok, status} <- normalize_status(Map.get(finding, :status)),
         {:ok, area} <- normalize_atom_field(finding, :area),
         {:ok, check} <- normalize_atom_field(finding, :check),
         {:ok, title} <- normalize_string_field(finding, :title),
         {:ok, why_it_matters} <- normalize_string_field(finding, :why_it_matters),
         {:ok, observed} <- normalize_string_field(finding, :observed),
         {:ok, remediation} <- normalize_string_field(finding, :remediation) do
      normalized =
        %{
          area: area,
          check: check,
          status: status,
          title: title,
          why_it_matters: why_it_matters,
          observed: observed,
          remediation: remediation
        }
        |> maybe_put(:evidence, Map.get(finding, :evidence))

      {:ok, normalized}
    end
  end

  defp normalize_finding(_), do: {:error, {:invalid_finding, :not_a_map}}

  defp validate_finding_keys(finding) do
    missing =
      @finding_keys
      |> Enum.reject(&Map.has_key?(finding, &1))

    case missing do
      [] -> :ok
      _ -> {:error, {:invalid_finding, {:missing_keys, missing}}}
    end
  end

  defp normalize_status(status) when status in @statuses, do: {:ok, status}
  defp normalize_status(status), do: {:error, {:invalid_status, status}}

  defp normalize_atom_field(map, key) do
    case Map.get(map, key) do
      value when is_atom(value) -> {:ok, value}
      value -> {:error, {:invalid_finding, {key, value}}}
    end
  end

  defp normalize_string_field(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) ->
        value = String.trim(value)

        if value == "" do
          {:error, {:invalid_finding, {key, :blank}}}
        else
          {:ok, value}
        end

      value ->
        {:error, {:invalid_finding, {key, value}}}
    end
  end

  defp normalize_facts(facts) when is_map(facts) do
    with :ok <- validate_fact_keys(facts) do
      normalized =
        Enum.reduce(@areas, empty_facts(), fn area, acc ->
          Map.put(acc, area, normalize_fact_bucket(Map.get(facts, area)))
        end)

      {:ok, normalized}
    end
  end

  defp normalize_facts(_), do: {:error, {:invalid_facts, :not_a_map}}

  defp validate_fact_keys(facts) do
    allowed = MapSet.new(@areas)

    unknown =
      facts
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed, &1))

    case unknown do
      [] -> :ok
      _ -> {:error, {:invalid_facts, {:unknown_keys, unknown}}}
    end
  end

  defp normalize_fact_bucket(nil), do: %{}
  defp normalize_fact_bucket(bucket) when is_map(bucket), do: bucket
  defp normalize_fact_bucket(bucket), do: %{value: bucket}

  defp normalize_resolver_errors(errors) when is_list(errors) do
    Enum.reduce_while(errors, {:ok, []}, fn error, {:ok, acc} ->
      case normalize_resolver_error(error) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_resolver_errors(_), do: {:error, {:invalid_resolver_errors, :not_a_list}}

  defp normalize_resolver_error(error) when is_map(error) do
    with {:ok, lookup} <- normalize_lookup(Map.get(error, :lookup)),
         {:ok, domain} <- normalize_domain(Map.get(error, :domain)),
         {:ok, reason} <- normalize_reason(Map.get(error, :reason)),
         {:ok, context} <- normalize_context(Map.get(error, :context)) do
      {:ok, %{lookup: lookup, domain: domain, reason: reason} |> maybe_put(:context, context)}
    end
  end

  defp normalize_resolver_error(_), do: {:error, {:invalid_resolver_error, :not_a_map}}

  defp normalize_lookup(lookup) when lookup in @resolver_lookups, do: {:ok, lookup}
  defp normalize_lookup(lookup), do: {:error, {:invalid_resolver_lookup, lookup}}

  defp normalize_reason(reason) when is_atom(reason), do: {:ok, reason}
  defp normalize_reason(reason), do: {:error, {:invalid_resolver_reason, reason}}

  defp normalize_context(nil), do: {:ok, nil}
  defp normalize_context(context) when is_map(context), do: {:ok, context}
  defp normalize_context(context), do: {:error, {:invalid_resolver_context, context}}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
