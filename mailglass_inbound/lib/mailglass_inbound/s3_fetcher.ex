defmodule MailglassInbound.S3Fetcher do
  @moduledoc false

  # Behaviour contract for fetching a SES inbound message's raw MIME bytes from
  # S3 (the design contract). The SES receipt-rule S3 action stores the message at
  # `s3://{bucketName}/{objectKey}` (where `objectKey == mail.messageId`); the
  # fetched binary is fed into `MailglassInbound.MIME.parse/1`.
  #
  # Behaviour only — no implementation here. `MailglassInbound.S3Fetcher.Fake`
  # (the fake-adapter-first test default, the design contract) and
  # `MailglassInbound.S3Fetcher.ExAwsS3` (the real, optional-dep-gated adapter)
  # are built in this plan.

  @doc """
  Fetch the raw object bytes for `key` in `bucket`.

  Returns `{:ok, binary()}` on success or `{:error, term()}` on failure (the
  caller maps a transient failure to `MailglassInbound.S3FetchError`
  `:s3_object_not_ready` and a permanent one to `:s3_fetch_failed`).
  """
  @callback fetch(bucket :: String.t(), key :: String.t(), opts :: keyword()) ::
              {:ok, binary()} | {:error, term()}
end
