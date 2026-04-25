defmodule Mailglass.Tracking.EndpointResolutionTest do
  @moduledoc """
  Asserts that Mailglass.Tracking.endpoint/0 has a single, consistent fallback
  chain used by both Rewriter and Plug (HI-02 fix verification).
  """
  use ExUnit.Case, async: true

  alias Mailglass.Tracking

  setup do
    # Capture pre-test config to restore on exit.
    prior_tracking = Application.get_env(:mailglass, :tracking)
    prior_adapter = Application.get_env(:mailglass, :adapter_endpoint)

    on_exit(fn ->
      if prior_tracking do
        Application.put_env(:mailglass, :tracking, prior_tracking)
      else
        Application.delete_env(:mailglass, :tracking)
      end

      if prior_adapter do
        Application.put_env(:mailglass, :adapter_endpoint, prior_adapter)
      else
        Application.delete_env(:mailglass, :adapter_endpoint)
      end
    end)

    :ok
  end

  test ":tracking, endpoint: is returned when set" do
    Application.put_env(:mailglass, :tracking,
      endpoint: "tracking-endpoint",
      host: "localhost",
      salts: ["s"]
    )

    Application.delete_env(:mailglass, :adapter_endpoint)
    assert Tracking.endpoint() == "tracking-endpoint"
  end

  test ":adapter_endpoint is used when :tracking, endpoint: is nil" do
    Application.put_env(:mailglass, :tracking, host: "localhost", salts: ["s"])
    Application.put_env(:mailglass, :adapter_endpoint, "adapter-endpoint")
    assert Tracking.endpoint() == "adapter-endpoint"
  end

  test ":tracking, endpoint: takes precedence over :adapter_endpoint" do
    Application.put_env(:mailglass, :tracking,
      endpoint: "tracking-wins",
      host: "localhost",
      salts: ["s"]
    )

    Application.put_env(:mailglass, :adapter_endpoint, "adapter-endpoint")
    assert Tracking.endpoint() == "tracking-wins"
  end

  test "raises ConfigError{:tracking_endpoint_missing} when neither key is set" do
    Application.put_env(:mailglass, :tracking, host: "localhost", salts: ["s"])
    Application.delete_env(:mailglass, :adapter_endpoint)

    err = assert_raise Mailglass.ConfigError, fn -> Tracking.endpoint() end
    assert err.__struct__ == Mailglass.ConfigError
    assert err.type == :tracking_endpoint_missing
  end
end
