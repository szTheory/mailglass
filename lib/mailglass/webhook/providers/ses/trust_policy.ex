defmodule Mailglass.Webhook.Providers.SES.TrustPolicy do
  @moduledoc """
  SNS URL trust-policy validation — SSRF guard for cert and subscribe URLs.

  Validates `SigningCertURL` and `SubscribeURL` from SNS messages before any
  network I/O. Implements the safe host pattern from the AWS PHP SDK reference
  implementation to prevent S3 namespace collision attacks (per D-06, D-09).

  All functions are pure predicates — no side effects, no network I/O, no Logger.
  Callers raise `%Mailglass.SignatureError{}` on `false`.
  """

  # Safe SNS cert host pattern from AWS PHP SDK (canonical reference).
  # Requires:
  #   - Exact "sns." prefix
  #   - Region identifier minimum 3 chars (alphanumeric + hyphen)
  #   - Exact amazonaws.com or amazonaws.com.cn suffix
  #   - No additional subdomains between sns. and amazonaws.com
  # Blocks S3 namespace collision: sns.s3-us-west-2.amazonaws.com would need
  # a region like "s3-us-west-2" — that passes the region regex but the host
  # pattern requires ONLY one region segment between sns. and amazonaws.com,
  # which s3.amazonaws.com satisfies but sns.s3.BUCKET.amazonaws.com does not.
  @cert_host_pattern ~r/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/

  @doc """
  Returns `true` if `url` is a trusted SNS signing certificate URL.

  Requirements (all must hold):
  - Scheme: https only
  - Host: matches `^sns\\.[a-zA-Z0-9\\-]{3,}\\.amazonaws\\.com(\\.cn)?$`
  - No userinfo component
  - No fragment component
  - Path ends with `.pem`
  - No query string (certs are static resources)
  """
  @spec valid_cert_url?(binary()) :: boolean()
  def valid_cert_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host, port: port, userinfo: nil, fragment: nil, path: path, query: nil}
      when is_binary(host) and is_binary(path) and port in [nil, 443] ->
        Regex.match?(@cert_host_pattern, host) and String.ends_with?(path, ".pem")

      _ ->
        false
    end
  end

  def valid_cert_url?(_), do: false

  @doc """
  Returns `true` if `url` is a trusted SNS subscribe/unsubscribe URL.

  Requirements (all must hold):
  - Scheme: https only
  - Host: matches SNS host pattern (same regex as cert URL)
  - No userinfo component
  - No fragment component

  Note: SubscribeURL validation is a consistency check per D-07. The actual
  subscription confirmation does NOT follow this URL — it constructs the
  ConfirmSubscription API request from `TopicArn` + `Token` instead.
  """
  @spec valid_subscribe_url?(binary()) :: boolean()
  def valid_subscribe_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host, port: port, userinfo: nil, fragment: nil}
      when is_binary(host) and port in [nil, 443] ->
        Regex.match?(@cert_host_pattern, host)

      _ ->
        false
    end
  end

  def valid_subscribe_url?(_), do: false
end
