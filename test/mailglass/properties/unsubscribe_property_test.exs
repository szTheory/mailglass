defmodule Mailglass.Properties.UnsubscribePropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.ConfigError
  alias Mailglass.Message

  @moduletag :property

  defmodule OperationalOptInMailer do
    def __mailglass_unsubscribe__, do: [enabled: true]
  end

  defmodule OperationalOptOutMailer do
  end

  defmodule UnsafeTenancy do
    @behaviour Mailglass.Tenancy

    import Ecto.Query

    @impl true
    def scope(queryable, _context), do: from(row in queryable, as: :scoped)

    @impl true
    def compliance_host(%{host: host}), do: {:ok, host}
  end

  setup do
    prior_mailglass = Application.get_all_env(:mailglass)

    Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint-secret")

    Application.put_env(:mailglass, :compliance,
      endpoint: "current-secret-key-base-123",
      host: "unsubscribe.example.com",
      scheme: "https",
      mount_path: "/mailglass/unsubscribe",
      previous_secrets: [],
      redirect: nil,
      max_age: 60,
      lifecycle: Mailglass.Lifecycle.Noop
    )

    on_exit(fn ->
      Application.put_all_env(mailglass: prior_mailglass)
      Application.delete_env(:mailglass, :tenancy)
    end)

    :ok
  end

  property "verify_token succeeds across current-secret rotation when legacy secret remains configured" do
    check all(
            delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            legacy_secret <- string(:alphanumeric, min_length: 20, max_length: 48),
            rotated_secret <- string(:alphanumeric, min_length: 20, max_length: 48),
            max_runs: 50
          ) do
      Application.put_env(:mailglass, :compliance,
        endpoint: legacy_secret,
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60,
        lifecycle: Mailglass.Lifecycle.Noop
      )

      token = Unsubscribe.sign_token(delivery_id)

      Application.put_env(:mailglass, :compliance,
        endpoint: rotated_secret,
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [legacy_secret],
        redirect: nil,
        max_age: 60,
        lifecycle: Mailglass.Lifecycle.Noop
      )

      assert {:ok, %{delivery_id: ^delivery_id}} = Unsubscribe.verify_token(token)
    end
  end

  property "expired tokens fail with the structured controller outcome" do
    check all(
            delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            max_runs: 25
          ) do
      now = System.system_time(:second)

      token =
        Phoenix.Token.sign(
          "current-secret-key-base-123",
          "mailglass_unsubscribe_v1",
          delivery_id,
          signed_at: now - 10,
          key_iterations: 1000,
          key_length: 32,
          key_digest: :sha256
        )

      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 1,
        lifecycle: Mailglass.Lifecycle.Noop
      )

      assert {:error, :expired} = Unsubscribe.verify_token(token)
    end
  end

  property "unsubscribe_url rejects unsafe hosts and raises before emitting oversized links" do
    check all(
            host <-
              member_of([
                "http://evil.test",
                "https://evil.test",
                "evil.test/path",
                "evil.test?next=https://attacker.test",
                "evil.test#fragment",
                "user:pass@evil.test",
                "localhost",
                "127.0.0.1",
                "169.254.169.254",
                "[::1]",
                "evil.test\nx"
              ]),
            delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            max_runs: 40
          ) do
      Application.put_env(:mailglass, :tenancy, UnsafeTenancy)

      assert_raise ConfigError, fn ->
        Unsubscribe.unsubscribe_url(delivery_id, %{tenant_id: "tenant-1", host: host})
      end
    end
  end

  property "unsubscribe_url raises once the generated link would exceed 900 bytes" do
    check all(
            oversized_host_prefix <- string(:alphanumeric, min_length: 860, max_length: 900),
            delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            max_runs: 20
          ) do
      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: oversized_host_prefix <> ".example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60,
        lifecycle: Mailglass.Lifecycle.Noop
      )

      assert_raise ConfigError, fn ->
        Unsubscribe.unsubscribe_url(delivery_id, %{})
      end
    end
  end

  property "stream rules atomically control unsubscribe header presence" do
    check all(
            delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            max_runs: 50
          ) do
      bulk =
        %Swoosh.Email{}
        |> Message.build(stream: :bulk, tenant_id: "tenant-1", metadata: %{delivery_id: delivery_id})
        |> Mailglass.Compliance.apply_outbound_headers()

      transactional =
        %Swoosh.Email{}
        |> Message.build(
          stream: :transactional,
          tenant_id: "tenant-1",
          metadata: %{delivery_id: delivery_id}
        )
        |> Mailglass.Compliance.apply_outbound_headers()

      operational_opt_in =
        %Swoosh.Email{}
        |> Message.build(
          stream: :operational,
          tenant_id: "tenant-1",
          mailable: OperationalOptInMailer,
          metadata: %{delivery_id: delivery_id}
        )
        |> Mailglass.Compliance.apply_outbound_headers()

      operational_opt_out =
        %Swoosh.Email{}
        |> Message.build(
          stream: :operational,
          tenant_id: "tenant-1",
          mailable: OperationalOptOutMailer,
          metadata: %{delivery_id: delivery_id}
        )
        |> Mailglass.Compliance.apply_outbound_headers()

      assert bulk.swoosh_email.headers["List-Unsubscribe"] =~ "https://"
      assert bulk.swoosh_email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"

      refute Map.has_key?(transactional.swoosh_email.headers, "List-Unsubscribe")
      refute Map.has_key?(transactional.swoosh_email.headers, "List-Unsubscribe-Post")

      assert operational_opt_in.swoosh_email.headers["List-Unsubscribe"] =~ "https://"

      assert operational_opt_in.swoosh_email.headers["List-Unsubscribe-Post"] ==
               "List-Unsubscribe=One-Click"

      refute Map.has_key?(operational_opt_out.swoosh_email.headers, "List-Unsubscribe")
      refute Map.has_key?(operational_opt_out.swoosh_email.headers, "List-Unsubscribe-Post")
    end
  end
end
