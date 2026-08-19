defmodule MailglassInbound.S3Fetcher.ExAwsS3 do
  @moduledoc false

  # Real `S3Fetcher` adapter, gated behind the optional `ex_aws`/`ex_aws_s3`
  # deps (the design contract). It fetches the SES inbound message's raw MIME body from the
  # adopter's S3 bucket and extracts the `:body` binary from the ExAws response.
  #
  # CRITICAL (Pitfall 5): this module must NOT name `ExAws`/`ExAws.S3` directly.
  # All access flows through `MailglassInbound.OptionalDeps.ExAwsS3` — the only
  # sanctioned call site — so `mix compile --no-optional-deps
  # --warnings-as-errors` stays green. The gateway's `get_object/2` never raises;
  # this adapter only pattern-matches its result.

  @behaviour MailglassInbound.S3Fetcher

  alias MailglassInbound.OptionalDeps.ExAwsS3, as: Gateway

  @impl MailglassInbound.S3Fetcher
  def head(bucket, key, opts \\ []) when is_binary(bucket) and is_binary(key) do
    head_object = Keyword.get(opts, :gateway_head_object, &Gateway.head_object/2)

    case head_object.(bucket, key) do
      {:ok, response} -> extract_content_length(response)
      {:error, reason} -> {:error, reason}
    end
  end

  @impl MailglassInbound.S3Fetcher
  def fetch(bucket, key, opts \\ []) when is_binary(bucket) and is_binary(key) do
    # `:gateway_get_object` is a test seam (a 2-arity fun) so the `:body`
    # extraction is exercisable without ex_aws installed. Production passes no
    # opt and the real gateway is used.
    get_object = Keyword.get(opts, :gateway_get_object, &Gateway.get_object/2)

    case get_object.(bucket, key) do
      {:ok, %{body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %{body: other}} ->
        {:error, {:s3_fetch_failed, {:non_binary_body, other}}}

      {:ok, response} ->
        {:error, {:s3_fetch_failed, {:missing_body, response}}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_content_length(%{content_length: bytes}) when is_integer(bytes) and bytes >= 0,
    do: {:ok, %{content_length: bytes}}

  defp extract_content_length(%{headers: headers}) when is_map(headers),
    do:
      extract_content_length(
        Map.get(headers, "content-length") || Map.get(headers, :"content-length")
      )

  defp extract_content_length(%{headers: headers}) when is_list(headers) do
    extract_content_length(
      Enum.find_value(headers, fn
        {name, value} when name in ["content-length", :"content-length"] -> value
        _ -> nil
      end)
    )
  end

  defp extract_content_length(bytes) when is_binary(bytes) do
    case Integer.parse(bytes) do
      {value, ""} when value >= 0 -> {:ok, %{content_length: value}}
      _ -> {:error, {:s3_fetch_failed, :invalid_content_length}}
    end
  end

  defp extract_content_length(_), do: {:error, {:s3_fetch_failed, :missing_content_length}}
end
