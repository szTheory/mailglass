defmodule MailglassInbound.S3Fetcher.Retry do
  @moduledoc false

  # Small bounded GetObject retry around a `MailglassInbound.S3Fetcher`
  # implementation (the design contract). S3 has had strong read-after-write consistency
  # since Dec 2020 and SES publishes the SNS notification AFTER PutObject, so the
  # real safety net is idempotency on `messageId`/`objectKey` + SNS
  # at-least-once redelivery — NOT eventual consistency. This retry is therefore
  # deliberately small (default 3 attempts, short backoff): it smooths over a
  # rare not-yet-readable window, nothing more.
  #
  # On exhaustion of a transient error it raises
  # `MailglassInbound.S3FetchError` `:s3_object_not_ready` so the SES provider
  # surfaces a non-2xx (the caller does NOT ack → SNS redelivers, and the dedupe
  # layer absorbs the duplicate). A clearly non-retryable error short-circuits
  # immediately and raises `:s3_fetch_failed`.
  #
  # Retry classification (by the `{:error, reason}` shape returned by `fetch/3`):
  #
  #   * `:s3_object_not_ready` / `{:s3_object_not_ready, _}` → TRANSIENT (retry).
  #   * `:s3_fetch_failed` / `{:s3_fetch_failed, _}`         → NON-RETRYABLE.
  #   * any other reason                                     → treated as
  #     transient (still bounded), then raised as `:s3_fetch_failed` on
  #     exhaustion since the cause is unknown.

  alias MailglassInbound.S3FetchError

  @default_attempts 3
  # 250ms -> 1s -> 2s; the head element is the wait BEFORE retry attempt 2.
  @default_backoff_ms [250, 1_000, 2_000]

  @doc """
  Fetch `key` from `bucket` via `fetcher` with a small bounded retry.

  ## Options

  - `:attempts` — maximum attempts (default `#{@default_attempts}`).
  - `:backoff_ms` — list of sleep durations between attempts (default
    `#{inspect(@default_backoff_ms)}`). Tests pass zeros to stay fast.
  - `:fetch_opts` — keyword passed through to `fetcher.fetch/3`.

  Returns `{:ok, binary()}` on success. Raises `MailglassInbound.S3FetchError`
  on exhaustion (`:s3_object_not_ready`) or a non-retryable failure
  (`:s3_fetch_failed`).
  """
  @spec fetch_with_retry(module(), String.t(), String.t(), keyword()) :: {:ok, binary()}
  def fetch_with_retry(fetcher, bucket, key, opts \\ [])
      when is_atom(fetcher) and is_binary(bucket) and is_binary(key) do
    attempts = max(Keyword.get(opts, :attempts, @default_attempts), 1)
    backoff = Keyword.get(opts, :backoff_ms, @default_backoff_ms)
    fetch_opts = Keyword.get(opts, :fetch_opts, [])

    do_attempt(fetcher, bucket, key, fetch_opts, 1, attempts, backoff, nil)
  end

  defp do_attempt(fetcher, bucket, key, fetch_opts, attempt, max_attempts, backoff, _last) do
    case fetcher.fetch(bucket, key, fetch_opts) do
      {:ok, body} when is_binary(body) ->
        {:ok, body}

      {:error, reason} ->
        if retryable?(reason) do
          if attempt < max_attempts do
            sleep_for(backoff, attempt)
            do_attempt(fetcher, bucket, key, fetch_opts, attempt + 1, max_attempts, backoff, reason)
          else
            raise s3_fetch_error(
                    :s3_object_not_ready,
                    "Inbound S3 fetch failed: object not readable after #{max_attempts} attempts",
                    reason,
                    %{bucket: bucket, attempts: max_attempts}
                  )
          end
        else
          raise s3_fetch_error(
                  :s3_fetch_failed,
                  "Inbound S3 fetch failed: a non-retryable error occurred",
                  reason,
                  %{bucket: bucket, attempts: attempt}
                )
        end
    end
  end

  # Construct the closed-type S3FetchError struct directly (it ships no `new/N`
  # builder — its public surface is the closed `__types__/0` set + the struct).
  # `:cause` carries the raw underlying reason but is excluded from the
  # struct's Jason.Encoder derivation, so it never leaks into serialized output.
  defp s3_fetch_error(type, message, cause, context) do
    %S3FetchError{type: type, message: message, cause: cause, context: context}
  end

  defp retryable?(:s3_object_not_ready), do: true
  defp retryable?({:s3_object_not_ready, _}), do: true
  defp retryable?(:s3_fetch_failed), do: false
  defp retryable?({:s3_fetch_failed, _}), do: false
  # Unknown reasons get the benefit of the bounded retry, but exhaust to
  # :s3_fetch_failed (cause unknown) rather than :s3_object_not_ready.
  defp retryable?(_other), do: true

  # backoff is the wait BEFORE the next attempt; attempt N waits backoff[N-1].
  defp sleep_for(backoff, attempt) when is_list(backoff) do
    case Enum.at(backoff, attempt - 1, 0) do
      ms when is_integer(ms) and ms > 0 -> Process.sleep(ms)
      _ -> :ok
    end
  end
end
