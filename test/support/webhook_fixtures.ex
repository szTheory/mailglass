defmodule Mailglass.WebhookFixtures do
  @moduledoc """
  Test helpers for webhook fixtures (Phase 4 TEST-03 / Wave 0).

  Mints fresh ECDSA P-256 keypairs per test process, signs SendGrid-shaped
  payloads against them, and builds Postmark Basic Auth headers — all at
  test runtime so fixture JSON files on disk stay payload-only (Pitfall 10
  in `04-RESEARCH.md`). No production provider private keys ever enter the
  repo.

  Two signing paths matter:

    * **SendGrid** ships a base64-encoded SPKI DER of a P-256 public key in
      its dashboard — no PEM framing — and verifies every payload with an
      ECDSA signature over `timestamp <> raw_body`. Verifier path (Plan 03)
      will call `:public_key.der_decode(:SubjectPublicKeyInfo, _)` on the
      decoded bytes. This module generates the exact shape.

    * **Postmark** uses per-tenant HTTP Basic Auth on the webhook URL —
      no HMAC. Timing-safe comparison via `Plug.Crypto.secure_compare/2`
      (Plan 02) is what the production verifier runs. Test helpers build
      the matching Authorization header.

  ## Fixture file convention

  JSON payloads live at `test/support/fixtures/webhooks/{provider}/*.json`
  and are PAYLOAD-ONLY (no baked-in signatures). Callers load via
  `load_postmark_fixture/1` + `load_sendgrid_fixture/1`, then ask
  `Mailglass.WebhookCase` to attach the signature at conn-build time.

  ## Crypto choice

  Signing uses `:crypto.sign/4` (direct ECDSA via the raw curve) rather
  than `:public_key.sign/3` — the former avoids the `{:ECPrivateKey, _, _,
  _, _, _}` record-shape incantation required by OTP 27 `:public_key`.
  Verification runs `:public_key.verify/4` with the `{{:ECPoint, bits},
  params}` tuple, which is the canonical OTP surface and matches the
  production verifier contract verbatim (D-03).

  All helpers are safe for `async: true` tests — no global mutable state.
  """

  @fixture_root Path.expand("fixtures/webhooks", __DIR__)

  # secp256r1 / P-256 / prime256v1 — SendGrid's documented curve. OID
  # 1.2.840.10045.3.1.7 from RFC 5480 §2.1.1.1.
  @secp256r1_params {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}}

  # ---- SendGrid ECDSA P-256 keypair + signing -------------------------

  @doc """
  Generates a fresh ECDSA P-256 keypair.

  Returns `{spki_der_base64, private_key_bytes}`:

    * The first element is the base64-encoded SubjectPublicKeyInfo DER
      — the exact format SendGrid publishes in its dashboard UI. Production
      `Mailglass.Webhook.Providers.SendGrid.verify!/3` (Plan 03) will
      `Base.decode64!/1` then `:public_key.der_decode(:SubjectPublicKeyInfo,
      _)` on this blob.

    * The second element is the raw 32-byte P-256 private key scalar —
      consumed directly by `sign_sendgrid_payload/3` via `:crypto.sign/4`.

  Fresh per call (random). Tests that want deterministic keys across
  setup/teardown should generate once in `setup_all` and pass the
  keypair through context.
  """
  @spec generate_sendgrid_keypair() :: {String.t(), binary()}
  def generate_sendgrid_keypair do
    {pub, priv} = :crypto.generate_key(:ecdh, :secp256r1)
    # `pem_entry_encode/2` returns a `{type, der, :not_encrypted}` 3-tuple.
    # We grab the DER and base64-encode it to match SendGrid's dashboard
    # format. Round-trip verified in the `t:sign_and_verify` doctest below.
    {:SubjectPublicKeyInfo, der, :not_encrypted} =
      :public_key.pem_entry_encode(
        :SubjectPublicKeyInfo,
        {{:ECPoint, pub}, @secp256r1_params}
      )

    {Base.encode64(der), priv}
  end

  @doc """
  Signs `timestamp <> raw_body` with the given P-256 private key.

  Returns the base64-encoded ECDSA signature — the exact format SendGrid
  puts in its `X-Twilio-Email-Event-Webhook-Signature` header.

  ## Example

      iex> {b64_der, priv} = Mailglass.WebhookFixtures.generate_sendgrid_keypair()
      iex> sig = Mailglass.WebhookFixtures.sign_sendgrid_payload("1234567890", "{}", priv)
      iex> is_binary(sig) and byte_size(sig) > 0
      true
  """
  @spec sign_sendgrid_payload(String.t(), binary(), binary()) :: String.t()
  def sign_sendgrid_payload(timestamp, raw_body, priv_key)
      when is_binary(timestamp) and is_binary(raw_body) and is_binary(priv_key) do
    payload = timestamp <> raw_body
    sig = :crypto.sign(:ecdsa, :sha256, payload, [priv_key, :secp256r1])
    Base.encode64(sig)
  end

  @doc """
  Returns the SPKI DER base64 string decoded back to the raw SPKI DER
  bytes. Useful in property tests that assert `:public_key.der_decode/2`
  round-trips without raising.
  """
  @spec decode_sendgrid_spki_der!(String.t()) ::
          {:SubjectPublicKeyInfo, binary(), binary()}
  def decode_sendgrid_spki_der!(b64_der) when is_binary(b64_der) do
    b64_der
    |> Base.decode64!()
    |> then(&:public_key.der_decode(:SubjectPublicKeyInfo, &1))
  end

  # ---- Postmark Basic Auth -------------------------------------------

  @doc """
  Builds a `{"authorization", "Basic " <> encoded}` Plug header tuple.

  Matches the exact wire format Postmark sends when per-webhook Basic Auth
  is configured in its dashboard (user+password colon-joined, Base64-
  encoded, `"Basic "` prefix). The production verifier (Plan 02) runs
  `Plug.Crypto.secure_compare/2` against this string.
  """
  @spec postmark_basic_auth_header(String.t(), String.t()) :: {String.t(), String.t()}
  def postmark_basic_auth_header(user, pass) when is_binary(user) and is_binary(pass) do
    encoded = Base.encode64("#{user}:#{pass}")
    {"authorization", "Basic " <> encoded}
  end

  # ---- Fixture loading -----------------------------------------------

  @doc """
  Loads `test/support/fixtures/webhooks/postmark/\#{name}.json` as raw bytes.

  Callers pass the bytes to `sign_sendgrid_payload/3` (nope — Postmark
  uses Basic Auth, not ECDSA) or just hand them to `Plug.Test.conn/3` as
  the body. Returns the file bytes unmodified — no JSON parsing, no
  whitespace normalization.
  """
  @spec load_postmark_fixture(String.t()) :: binary()
  def load_postmark_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "postmark", name <> ".json"]))
  end

  @doc """
  Loads `test/support/fixtures/webhooks/sendgrid/\#{name}.json` as raw bytes.

  Preserves byte-exact content so signature verification works against
  the loaded body — any re-encoding (e.g. `Jason.decode!/1 |> Jason.encode!/1`)
  would silently mutate whitespace and break the signature.
  """
  @spec load_sendgrid_fixture(String.t()) :: binary()
  def load_sendgrid_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "sendgrid", name <> ".json"]))
  end

  @doc """
  Signs `svix_id.svix_timestamp.raw_body` with the given secret.

  Returns the base64-encoded HMAC-SHA256 signature that Resend's
  Svix-backed webhooks expect in the `svix-signature` header.
  """
  @spec sign_resend_payload(String.t(), String.t(), binary(), binary()) :: String.t()
  def sign_resend_payload(svix_id, svix_timestamp, raw_body, secret)
      when is_binary(svix_id) and is_binary(svix_timestamp) and is_binary(raw_body) and
             is_binary(secret) do
    signed_content = "#{svix_id}.#{svix_timestamp}.#{raw_body}"

    :crypto.mac(:hmac, :sha256, secret, signed_content)
    |> Base.encode64()
  end

  @doc """
  Loads `test/support/fixtures/webhooks/resend/\#{name}.json` as raw bytes.
  """
  @spec load_resend_fixture(String.t()) :: binary()
  def load_resend_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "resend", name <> ".json"]))
  end

  @doc """
  Loads `test/support/fixtures/webhooks/mailgun/\#{name}.json` as raw bytes.
  """
  @spec load_mailgun_fixture(String.t()) :: binary()
  def load_mailgun_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "mailgun", name <> ".json"]))
  end

  @doc """
  Generates a fresh RSA 2048-bit keypair for SNS signature testing.

  Returns `{public_key_term, private_key_record}`:

    * `public_key_term` — an `{:RSAPublicKey, n, e}` record for use with
      `CertCache.put/3`. This is the term `CertCache` stores and passes to
      `:public_key.verify/4`.
    * `private_key_record` — the RSA private key for signing canonical strings
      via `sign_sns_canonical_string/3`.

  Fresh per call (random). Tests that need a stable keypair across multiple
  `verify!/3` calls should generate once in `setup` and reuse.

  ## Test usage pattern

  Since tests stub the CertCache directly (no `:httpc` call needed):

      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(cert_url, public_key, future)
      raw = sign_fixture(raw_fixture_json, private_key)
      assert :ok = SES.verify!(raw, [], config)
  """
  @spec generate_sns_keypair() :: {term(), term()}
  def generate_sns_keypair do
    private_key = :public_key.generate_key({:rsa, 2048, 65537})
    # RSAPrivateKey record layout (OTP 27):
    # {:RSAPrivateKey, :two-prime, n, e, d, p, q, dp, dq, qi, other_prime_infos}
    # Index 2 = n (modulus), Index 3 = e (public exponent)
    n = elem(private_key, 2)
    e = elem(private_key, 3)
    public_key = {:RSAPublicKey, n, e}
    {public_key, private_key}
  end

  @doc """
  Signs an SNS canonical string with the given RSA private key.

  The canonical string must be pre-built by the caller using the field-sorted
  `"key\\nvalue\\n"` algorithm from AWS docs. Returns the base64-encoded RSA-SHA1
  signature (SignatureVersion 1) — or SHA256 for SignatureVersion 2 when
  `digest: :sha256` is passed in opts.

  Use this in tests to inject a valid `"Signature"` field into a fixture
  before calling `verify!/3`.

  ## Example

      {_public_key, private_key} = generate_sns_keypair()
      canonical = "Message\\nhello world\\nType\\nNotification\\n"
      sig = sign_sns_canonical_string(canonical, private_key)
      # => base64-encoded RSA-SHA1 signature
  """
  @spec sign_sns_canonical_string(binary(), term(), keyword()) :: String.t()
  def sign_sns_canonical_string(canonical_string, private_key, opts \\ [])
      when is_binary(canonical_string) do
    digest = Keyword.get(opts, :digest, :sha)
    sig = :public_key.sign(canonical_string, digest, private_key)
    Base.encode64(sig)
  end

  @doc """
  Loads `test/support/fixtures/webhooks/ses/\#{name}.json` as raw bytes.
  """
  @spec load_ses_fixture(String.t()) :: binary()
  def load_ses_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "ses", name <> ".json"]))
  end

  @doc """
  Injects a Mailgun `signature` object into a raw payload-only fixture.

  Options:

    * `:timestamp` - Unix timestamp string or integer. Defaults to current time.
    * `:token` - webhook token used for both signature replay identity and HMAC payload.
  """
  @spec sign_mailgun_payload(binary(), binary(), keyword()) :: binary()
  def sign_mailgun_payload(raw_body, signing_key, opts)
      when is_binary(raw_body) and is_binary(signing_key) and is_list(opts) do
    timestamp =
      case Keyword.get(opts, :timestamp, System.system_time(:second)) do
        value when is_integer(value) -> Integer.to_string(value)
        value when is_binary(value) -> value
      end

    token =
      Keyword.get_lazy(opts, :token, fn ->
        "mailgun-token-" <> Integer.to_string(System.unique_integer([:positive]))
      end)

    signature =
      :crypto.mac(:hmac, :sha256, signing_key, timestamp <> token)
      |> Base.encode16(case: :lower)

    raw_body
    |> Jason.decode!()
    |> Map.put("signature", %{
      "timestamp" => timestamp,
      "token" => token,
      "signature" => signature
    })
    |> Jason.encode!()
  end

  @doc "Absolute path to the webhook fixtures root (for `File.ls!/1` in tests)."
  @spec fixture_root() :: String.t()
  def fixture_root, do: @fixture_root
end
