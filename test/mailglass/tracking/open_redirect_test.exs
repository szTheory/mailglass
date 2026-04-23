defmodule Mailglass.Tracking.OpenRedirectTest do
  use ExUnit.Case, async: false

  use ExUnitProperties

  alias Mailglass.Tracking.Token

  @endpoint "mailglass-test-open-redirect-endpoint"

  setup do
    original = Application.get_env(:mailglass, :tracking)

    Application.put_env(:mailglass, :tracking,
      salts: ["ort-salt-1"],
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

  # Test 13 (property): verify_click NEVER returns target_url with non-http/https scheme
  property "verify_click never returns target_url with scheme outside [http, https]" do
    check all delivery_id <- binary(min_length: 1, max_length: 40),
              tenant_id <- binary(min_length: 1, max_length: 40),
              scheme <- member_of(["http", "https"]),
              host <- binary(min_length: 1, max_length: 20),
              path <- binary(min_length: 0, max_length: 40) do
      url = "#{scheme}://#{host}/#{path}"
      token = Token.sign_click(@endpoint, delivery_id, tenant_id, url)
      {:ok, %{target_url: decoded}} = Token.verify_click(@endpoint, token)
      assert URI.parse(decoded).scheme in ["http", "https"]
    end
  end

  # Verify that sign_click structurally prevents non-http/https schemes
  property "sign_click raises for non-http/https schemes at sign time" do
    check all scheme <- member_of(["javascript", "ftp", "data", "file", "vbscript", "blob"]),
              rest <- string(:printable, min_length: 1, max_length: 40) do
      url = "#{scheme}:#{rest}"

      try do
        Token.sign_click(@endpoint, "d", "t", url)
        # If sign_click didn't raise, check the scheme was accepted (should be http/https only)
        # This branch should NOT be reached for non-http/https schemes
        assert false, "Expected sign_click to raise for scheme #{scheme} but it did not"
      rescue
        _e in Mailglass.ConfigError -> :ok
        _e in FunctionClauseError -> :ok
      end
    end
  end

  # Verify tampered tokens fail HMAC check (structural impossibility of open redirect)
  test "tampered tokens are rejected by HMAC verification" do
    url = "https://example.com/click"
    token = Token.sign_click(@endpoint, "d-1", "t-1", url)

    # Tamper with the token
    tampered = token <> "TAMPERED"
    assert :error = Token.verify_click(@endpoint, tampered)

    tampered2 = "TAMPERED" <> token
    assert :error = Token.verify_click(@endpoint, tampered2)
  end
end
