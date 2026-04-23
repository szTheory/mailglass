defmodule Mailglass.Tracking.ConfigValidatorTest do
  use ExUnit.Case, async: false

  alias Mailglass.Tracking.ConfigValidator
  alias Mailglass.ConfigError

  setup do
    original_tracking = Application.get_env(:mailglass, :tracking)

    # Ensure TrackingMailer is loaded so the validator can discover it.
    # :code.all_loaded() only lists modules that have been loaded into memory;
    # compiled .beam files are loaded lazily by the BEAM.
    Code.ensure_loaded(Mailglass.FakeFixtures.TrackingMailer)

    on_exit(fn ->
      if original_tracking do
        Application.put_env(:mailglass, :tracking, original_tracking)
      else
        Application.delete_env(:mailglass, :tracking)
      end
    end)

    :ok
  end

  # Test 7: validate_at_boot!/0 raises when mailable has tracking AND host is nil
  test "raises ConfigError :tracking_host_missing when tracking mailable loaded and host missing" do
    # TrackingMailer (opens: true, clicks: true) is loaded in setup.
    # Set up config WITHOUT a tracking host.
    Application.put_env(:mailglass, :tracking, salts: ["s1"], max_age: 86_400)

    err =
      try do
        ConfigValidator.validate_at_boot!()
        nil
      rescue
        e in ConfigError -> e
      end

    assert err != nil, "Expected ConfigError to be raised but it was not"
    assert err.__struct__ == ConfigError
    assert err.type == :tracking_host_missing
  end

  # Test 8: validate_at_boot!/0 — when host IS set, no error (regardless of mailables loaded)
  test "returns :ok when tracking host is configured even with tracking mailables loaded" do
    Application.put_env(:mailglass, :tracking,
      salts: ["s1"],
      max_age: 86_400,
      host: "track.example.com"
    )

    assert :ok = ConfigValidator.validate_at_boot!()
  end

  # Test 9: tracking host set → no error raised
  test "returns :ok when tracking host is configured" do
    Application.put_env(:mailglass, :tracking,
      salts: ["s1"],
      max_age: 86_400,
      host: "track.example.com",
      scheme: "https"
    )

    assert :ok = ConfigValidator.validate_at_boot!()
  end

  # Verify the function exists and has the right arity
  test "validate_at_boot!/0 is a public function with arity 0" do
    Code.ensure_loaded(ConfigValidator)
    assert function_exported?(ConfigValidator, :validate_at_boot!, 0)
  end
end
