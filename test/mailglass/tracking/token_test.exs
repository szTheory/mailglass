defmodule Mailglass.Tracking.TokenTest do
  use ExUnit.Case, async: false

  alias Mailglass.Tracking.Token
  alias Mailglass.ConfigError

  @endpoint "mailglass-test-endpoint-secret"

  setup do
    original = Application.get_env(:mailglass, :tracking)

    Application.put_env(:mailglass, :tracking,
      salts: ["test-salt-1"],
      max_age: 86_400,
      host: "track.test",
      scheme: "https"
    )

    on_exit(fn ->
      if original do
        Application.put_env(:mailglass, :tracking, original)
      else
        Application.delete_env(:mailglass, :tracking)
      end
    end)

    :ok
  end

  describe "sign_open/3 + verify_open/2" do
    # Test 1: sign_open returns an opaque binary
    test "sign_open returns a binary token" do
      token = Token.sign_open(@endpoint, "delivery-uuid", "tenant-acme")
      assert is_binary(token)
      assert byte_size(token) > 0
    end

    # Test 2: round-trip verify_open
    test "verify_open decodes what sign_open signed" do
      token = Token.sign_open(@endpoint, "delivery-uuid", "tenant-acme")
      assert {:ok, %{delivery_id: "delivery-uuid", tenant_id: "tenant-acme"}} =
               Token.verify_open(@endpoint, token)
    end
  end

  describe "sign_click/4 + verify_click/2" do
    # Test 3: sign_click returns an opaque binary
    test "sign_click returns a binary token" do
      token = Token.sign_click(@endpoint, "delivery-uuid", "tenant-acme", "https://example.com/post/123")
      assert is_binary(token)
    end

    # Test 4: round-trip verify_click
    test "verify_click decodes what sign_click signed" do
      token = Token.sign_click(@endpoint, "delivery-uuid", "tenant-acme", "https://example.com/post/123")

      assert {:ok, %{delivery_id: "delivery-uuid", tenant_id: "tenant-acme", target_url: "https://example.com/post/123"}} =
               Token.verify_click(@endpoint, token)
    end

    # Test 5: javascript: scheme raises at sign time
    test "sign_click with javascript: scheme raises ConfigError" do
      assert_raise ConfigError, fn ->
        Token.sign_click(@endpoint, "d-id", "t-id", "javascript:alert(1)")
      end

      err =
        try do
          Token.sign_click(@endpoint, "d-id", "t-id", "javascript:alert(1)")
        rescue
          e in ConfigError -> e
        end

      assert err.__struct__ == ConfigError
      assert err.type == :invalid
      assert err.context[:rejected_url] == "javascript:alert(1)"
      assert err.context[:reason] == :scheme
    end

    # Test 6: ftp: scheme raises same error
    test "sign_click with ftp: scheme raises ConfigError with :invalid type" do
      assert_raise ConfigError, fn ->
        Token.sign_click(@endpoint, "d-id", "t-id", "ftp://files.example.com/secret.pdf")
      end

      err =
        try do
          Token.sign_click(@endpoint, "d-id", "t-id", "ftp://files.example.com/secret.pdf")
        rescue
          e in ConfigError -> e
        end

      assert err.type == :invalid
      assert err.context[:reason] == :scheme
    end
  end

  describe "invalid/expired tokens" do
    # Test 10: random garbage returns :error from verify_open
    test "verify_open returns :error for invalid token binary" do
      assert :error = Token.verify_open(@endpoint, "garbage-token-xyz")
    end

    # Test 10b: random garbage returns :error from verify_click
    test "verify_click returns :error for invalid token binary" do
      assert :error = Token.verify_click(@endpoint, "definitely-not-a-token")
    end
  end

  describe "tenant_id in payload (D-39)" do
    # Test 11: tenant_id is in the signed payload, not the token string
    test "tenant_id is encoded in the signed token payload, not as plaintext" do
      tenant = "super-secret-tenant"
      token = Token.sign_open(@endpoint, "d-123", tenant)

      # The raw token binary should NOT contain the tenant_id as UTF-8 plaintext
      # (Phoenix.Token encodes payload as opaque Base64-encoded binary)
      refute String.contains?(token, tenant)

      # But verify decodes it correctly
      {:ok, %{tenant_id: decoded}} = Token.verify_open(@endpoint, token)
      assert decoded == tenant
    end
  end

  describe "property: StreamData round-trips" do
    use ExUnitProperties

    # Test 12: 100 round-trips with random valid inputs
    property "sign_click + verify_click round-trips for http/https schemes" do
      check all delivery_id <- string(:alphanumeric, min_length: 5, max_length: 40),
                tenant_id <- string(:alphanumeric, min_length: 5, max_length: 40),
                scheme <- member_of(["http", "https"]),
                host <- string(:alphanumeric, min_length: 5, max_length: 20),
                path <- string(:alphanumeric, min_length: 0, max_length: 40) do
        url = "#{scheme}://#{host}/#{path}"
        token = Token.sign_click(@endpoint, delivery_id, tenant_id, url)

        assert is_binary(token)
        assert {:ok, result} = Token.verify_click(@endpoint, token)
        assert result.delivery_id == delivery_id
        assert result.tenant_id == tenant_id
        assert result.target_url == url

        # Payload is opaque — tenant_id (>= 5 chars) should not appear verbatim
        # in the Base64 token binary (Phoenix.Token uses term_to_binary encoding,
        # not JSON serialization). Short strings can collide by chance in Base64;
        # 5+ character minimum ensures we're testing the encoding property.
        refute String.contains?(token, tenant_id),
               "tenant_id #{inspect(tenant_id)} found verbatim in token (encoding should be opaque)"
      end
    end
  end
end
