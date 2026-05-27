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

  @doc "Clears all configured responses and call counts for the current process."
  @spec reset() :: :ok
  def reset do
    Process.put(@pd_responses, %{})
    Process.put(@pd_counts, %{})
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

  @doc """
  Configures an `{:error, :s3_object_not_ready}` response for the first `n` calls,
  then `{:ok, body}` for every call after — the SESI-05 bounded-retry path.
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

  defp bump_count(addr) do
    new = Map.get(counts(), addr, 0) + 1
    Process.put(@pd_counts, Map.put(counts(), addr, new))
    new
  end
end
