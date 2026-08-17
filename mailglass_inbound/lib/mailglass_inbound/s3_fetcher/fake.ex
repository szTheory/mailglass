defmodule MailglassInbound.S3Fetcher.Fake do
  @moduledoc false

  # Fake-adapter-first (the design contract, the design contract): the `:test`-default `S3Fetcher`. It is
  # the merge-blocking release gate for SES inbound — every SES provider /
  # bounded-retry test drives this fetcher, never `ExAwsS3`. Dependency-free (no
  # ExAws, no network).
  #
  # State is held in the **calling process's process dictionary**, so the Fake is
  # naturally isolated across `async: true` tests: the test process calls
  # `S3Fetcher.Retry.fetch_with_retry/4`, which calls `fetch/3` synchronously in
  # that same process. No GenServer, no global ETS, no cross-test bleed. Call
  # `reset/0` in `setup`.
  #
  # Configured responses (per `{bucket, key}`):
  #
  #   * `put/3`              — canned `{:ok, body}`.
  #   * `put_error/3`        — always `{:error, reason}` (non-retryable path).
  #   * `put_error_then_ok/4`— `{:error, :s3_object_not_ready}` for the first N
  #                            calls, then `{:ok, body}` (exercises the bounded
  #                            retry, SESI-05).
  #
  # An unconfigured `{bucket, key}` returns `{:error, :s3_not_found}`. Every call
  # is counted (`call_count/2`) so tests can assert the retry budget was honored.

  @behaviour MailglassInbound.S3Fetcher

  @pd_responses {__MODULE__, :responses}
  @pd_counts {__MODULE__, :counts}
  @pd_head_responses {__MODULE__, :head_responses}
  @pd_head_counts {__MODULE__, :head_counts}

  @doc "Clears all configured responses and call counts for the current process."
  @spec reset() :: :ok
  def reset do
    Process.put(@pd_responses, %{})
    Process.put(@pd_counts, %{})
    Process.put(@pd_head_responses, %{})
    Process.put(@pd_head_counts, %{})
    :ok
  end

  @doc "Configures a canned `{:ok, body}` response for `{bucket, key}`."
  @spec put(String.t(), String.t(), binary()) :: :ok
  def put(bucket, key, body) when is_binary(body) do
    put_response({bucket, key}, {:ok_const, body})
  end

  @doc "Configures an always-failing `{:error, reason}` response for `{bucket, key}`."
  @spec put_error(String.t(), String.t(), term()) :: :ok
  def put_error(bucket, key, reason) do
    put_response({bucket, key}, {:error_const, reason})
  end

  @doc "Configures metadata with a declared content length for `{bucket, key}`."
  @spec put_head(String.t(), String.t(), non_neg_integer()) :: :ok
  def put_head(bucket, key, content_length)
      when is_integer(content_length) and content_length >= 0 do
    Process.put(@pd_head_responses, Map.put(head_responses(), {bucket, key}, {:ok, content_length}))
    :ok
  end

  @doc "Configures a metadata retrieval failure for `{bucket, key}`."
  @spec put_head_error(String.t(), String.t(), term()) :: :ok
  def put_head_error(bucket, key, reason) do
    Process.put(@pd_head_responses, Map.put(head_responses(), {bucket, key}, {:error, reason}))
    :ok
  end

  @doc """
  Configures an `{:error, :s3_object_not_ready}` response for the first `n` calls,
  then `{:ok, body}` for every call after — the bounded-retry path.
  """
  @spec put_error_then_ok(String.t(), String.t(), non_neg_integer(), binary()) :: :ok
  def put_error_then_ok(bucket, key, n, body)
      when is_integer(n) and n >= 0 and is_binary(body) do
    put_response({bucket, key}, {:error_then_ok, n, body})
  end

  @doc "Returns how many times `fetch/3` was called for `{bucket, key}`."
  @spec call_count(String.t(), String.t()) :: non_neg_integer()
  def call_count(bucket, key) do
    counts() |> Map.get({bucket, key}, 0)
  end

  @doc "Returns how many times `head/3` was called for `{bucket, key}`."
  @spec head_count(String.t(), String.t()) :: non_neg_integer()
  def head_count(bucket, key), do: head_counts() |> Map.get({bucket, key}, 0)

  @impl MailglassInbound.S3Fetcher
  def head(bucket, key, _opts) do
    addr = {bucket, key}
    bump_head_count(addr)

    case Map.get(head_responses(), addr) do
      {:ok, content_length} ->
        {:ok, %{content_length: content_length}}

      {:error, reason} ->
        {:error, reason}

      nil ->
        case Map.get(responses(), addr) do
          {:ok_const, body} -> {:ok, %{content_length: byte_size(body)}}
          {:error_then_ok, _fail_for, body} -> {:ok, %{content_length: byte_size(body)}}
          _ -> {:error, :s3_not_found}
        end
    end
  end

  @impl MailglassInbound.S3Fetcher
  def fetch(bucket, key, _opts) do
    addr = {bucket, key}
    n = bump_count(addr)

    case Map.get(responses(), addr) do
      {:ok_const, body} ->
        {:ok, body}

      {:error_const, reason} ->
        {:error, reason}

      {:error_then_ok, fail_for, body} ->
        if n <= fail_for, do: {:error, :s3_object_not_ready}, else: {:ok, body}

      nil ->
        {:error, :s3_not_found}
    end
  end

  defp put_response(addr, response) do
    Process.put(@pd_responses, Map.put(responses(), addr, response))
    :ok
  end

  defp responses, do: Process.get(@pd_responses, %{})
  defp counts, do: Process.get(@pd_counts, %{})
  defp head_responses, do: Process.get(@pd_head_responses, %{})
  defp head_counts, do: Process.get(@pd_head_counts, %{})

  defp bump_count(addr) do
    new = Map.get(counts(), addr, 0) + 1
    Process.put(@pd_counts, Map.put(counts(), addr, new))
    new
  end

  defp bump_head_count(addr) do
    new = Map.get(head_counts(), addr, 0) + 1
    Process.put(@pd_head_counts, Map.put(head_counts(), addr, new))
    new
  end
end
