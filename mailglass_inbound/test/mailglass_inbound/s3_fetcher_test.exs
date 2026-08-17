defmodule MailglassInbound.S3FetcherTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.{S3FetchError, S3Fetcher}
  alias MailglassInbound.OptionalDeps.ExAwsS3, as: ExAwsS3Gateway

  # The S3 fetcher seam (D-46-13): a fake-first test default
  # (`S3Fetcher.Fake`), a real optional-dep-gated adapter
  # (`S3Fetcher.ExAwsS3`), and a small bounded retry around `fetch/3`
  # (`S3Fetcher.Retry`, D-46-16) that the SES provider drives. Tests inject
  # zero backoff so the suite stays fast.

  setup do
    S3Fetcher.Fake.reset()
    :ok
  end

  describe "S3Fetcher.Fake (test default)" do
    test "returns configured metadata independently of the object body" do
      S3Fetcher.Fake.put("inbound-bucket", "msg-key-1", "raw mime body")

      assert {:ok, %{content_length: 13}} =
               S3Fetcher.Fake.head("inbound-bucket", "msg-key-1", [])
    end

    test "returns a configured {:ok, binary} for a canned bucket/key" do
      S3Fetcher.Fake.put("inbound-bucket", "msg-key-1", "raw mime body")

      assert {:ok, "raw mime body"} = S3Fetcher.Fake.fetch("inbound-bucket", "msg-key-1", [])
    end

    test "returns {:error, :not_configured} when no canned response exists" do
      assert {:error, :s3_not_found} = S3Fetcher.Fake.fetch("inbound-bucket", "missing", [])
    end

    test "can be configured to fail the first N calls then succeed (retry path)" do
      S3Fetcher.Fake.put_error_then_ok("b", "k", 2, "eventually here")

      assert {:error, :s3_object_not_ready} = S3Fetcher.Fake.fetch("b", "k", [])
      assert {:error, :s3_object_not_ready} = S3Fetcher.Fake.fetch("b", "k", [])
      assert {:ok, "eventually here"} = S3Fetcher.Fake.fetch("b", "k", [])
    end

    test "can be configured to always fail (non-retryable path)" do
      S3Fetcher.Fake.put_error("b", "k", :access_denied)

      assert {:error, :access_denied} = S3Fetcher.Fake.fetch("b", "k", [])
      assert {:error, :access_denied} = S3Fetcher.Fake.fetch("b", "k", [])
    end
  end

  describe "S3Fetcher.ExAwsS3 (real adapter, gated)" do
    test "extracts ContentLength from a metadata-only gateway response" do
      stub = fn _bucket, _key -> {:ok, %{content_length: 42, body: "must not be used"}} end

      assert {:ok, %{content_length: 42}} =
               S3Fetcher.ExAwsS3.head("bucket", "key", gateway_head_object: stub)
    end

    test "extracts :body from the gateway's {:ok, %{body: binary}} (D-46-15)" do
      # Inject a stub gateway via opts so we exercise the :body extraction
      # without ExAws being installed.
      stub = fn _bucket, _key -> {:ok, %{body: "s3 object bytes", status_code: 200}} end

      assert {:ok, "s3 object bytes"} =
               S3Fetcher.ExAwsS3.fetch("bucket", "key", gateway_get_object: stub)
    end

    test "surfaces {:error, reason} unchanged" do
      stub = fn _bucket, _key -> {:error, {:exit, :timeout}} end

      assert {:error, {:exit, :timeout}} =
               S3Fetcher.ExAwsS3.fetch("bucket", "key", gateway_get_object: stub)
    end

    test "treats a non-binary body as a fetch error rather than crashing" do
      stub = fn _bucket, _key -> {:ok, %{body: nil}} end

      assert {:error, _} = S3Fetcher.ExAwsS3.fetch("bucket", "key", gateway_get_object: stub)
    end
  end

  describe "MailglassInbound.OptionalDeps.ExAwsS3 gateway" do
    # SESI-04: the gateway is the single gating point for ex_aws. `available?/0`
    # MUST track `Code.ensure_loaded?(ExAws.S3)` exactly — false when the
    # optional dep is absent (the CI `--no-optional-deps` lane), true otherwise.
    # Asserting the *contract* rather than a hardcoded boolean keeps this test
    # correct regardless of whether the dev worktree happens to have ex_aws in
    # `_build`; the `mix compile --no-optional-deps --warnings-as-errors` lane is
    # the real proof that the gateway compiles with the dep stripped.
    test "available?/0 tracks Code.ensure_loaded?(ExAws.S3)" do
      assert ExAwsS3Gateway.available?() == Code.ensure_loaded?(ExAws.S3)
    end

    test "get_object/2 never raises — returns a tuple even when ExAws/HTTP client is unavailable" do
      # No AWS creds, no HTTP client wired in :test, so this exercises the
      # never-raise wrapper's degraded path. It must NOT raise.
      result = ExAwsS3Gateway.get_object("bucket", "key")
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "S3Fetcher.Retry.fetch_with_retry/4 (bounded, D-46-16)" do
    @opts [attempts: 3, backoff_ms: [0, 0, 0]]

    test "returns {:ok, body} on the first success" do
      S3Fetcher.Fake.put("b", "k", "first try")

      assert {:ok, "first try"} =
               S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", "k", @opts)
    end

    test "retries a transient error then succeeds within the attempt budget" do
      S3Fetcher.Fake.put_error_then_ok("b", "k", 2, "after retries")

      assert {:ok, "after retries"} =
               S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", "k", @opts)
    end

    test "runs at most :attempts attempts and raises S3FetchError :s3_object_not_ready on exhaustion" do
      # Always fails -> never resolves within 3 attempts.
      S3Fetcher.Fake.put_error_then_ok("b", "k", 99, "never reached")

      err =
        assert_raise S3FetchError, fn ->
          S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", "k", @opts)
        end

      assert err.type == :s3_object_not_ready
      # exactly 3 attempts were made (the Fake counts calls)
      assert S3Fetcher.Fake.call_count("b", "k") == 3
    end

    test "does not retry a clearly non-retryable failure and raises :s3_fetch_failed" do
      S3Fetcher.Fake.put_error("b", "k", {:s3_fetch_failed, :access_denied})

      err =
        assert_raise S3FetchError, fn ->
          S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", "k", @opts)
        end

      assert err.type == :s3_fetch_failed
      # only ONE attempt — the non-retryable error short-circuits
      assert S3Fetcher.Fake.call_count("b", "k") == 1
    end

    test "retries only the closed transient S3 outcome matrix" do
      transient_reasons = [
        :s3_object_not_ready,
        {:s3_object_not_ready, :replica_lag},
        :timeout,
        {:error, :timeout},
        {:exit, :timeout},
        :throttled,
        {:http_error, 503}
      ]

      for {reason, index} <- Enum.with_index(transient_reasons) do
        key = "transient-#{index}"
        S3Fetcher.Fake.put_error("b", key, reason)

        err =
          assert_raise S3FetchError, fn ->
            S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", key, @opts)
          end

        assert err.type == :s3_object_not_ready
        assert S3Fetcher.Fake.call_count("b", key) == 3
      end
    end

    test "does not retry permanent or unknown S3 outcomes" do
      permanent_reasons = [
        :access_denied,
        :s3_not_found,
        :s3_object_too_large,
        :invalid_content_length,
        {:http_error, 403},
        {:unexpected, :adapter_shape}
      ]

      for {reason, index} <- Enum.with_index(permanent_reasons) do
        key = "permanent-#{index}"
        S3Fetcher.Fake.put_error("b", key, reason)

        err =
          assert_raise S3FetchError, fn ->
            S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", key, @opts)
          end

        assert err.type == :s3_fetch_failed
        assert S3Fetcher.Fake.call_count("b", key) == 1
      end
    end

    # WR-06: an absent-ex_aws deployment must NOT burn the full retry budget +
    # backoff sleeps on a config error. The gateway tags the absent dep as
    # {:s3_fetch_failed, :ex_aws_unavailable}; the ExAwsS3 adapter passes that
    # through unchanged, and the retry layer classifies it as non-retryable, so
    # exactly ONE attempt is made before raising :s3_fetch_failed.
    test "absent-dep {:s3_fetch_failed, :ex_aws_unavailable} is non-retryable (single attempt)" do
      S3Fetcher.Fake.put_error("b", "k", {:s3_fetch_failed, :ex_aws_unavailable})

      err =
        assert_raise S3FetchError, fn ->
          S3Fetcher.Retry.fetch_with_retry(S3Fetcher.Fake, "b", "k", @opts)
        end

      assert err.type == :s3_fetch_failed
      assert S3Fetcher.Fake.call_count("b", "k") == 1
    end
  end

  describe "ExAwsS3 gateway absent-dep classification (WR-06)" do
    test "ExAwsS3 adapter passes the absent-dep tag through unchanged" do
      # Simulate the gateway returning the absent-dep tag (what get_object/2
      # returns when available?/0 is false). The adapter must surface it verbatim
      # so the retry layer can classify it as non-retryable.
      stub = fn _bucket, _key -> {:error, {:s3_fetch_failed, :ex_aws_unavailable}} end

      assert {:error, {:s3_fetch_failed, :ex_aws_unavailable}} =
               S3Fetcher.ExAwsS3.fetch("bucket", "key", gateway_get_object: stub)
    end
  end
end
