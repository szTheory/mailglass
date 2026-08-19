defmodule Mailglass.ReferenceHost.WebhookOperatorProof do
  @moduledoc """
  Deterministic reference-host route proof for the Postmark webhook path.
  """

  @compile {:no_warn_undefined,
            [MailglassReferenceHostWeb.Router, MailglassInbound.RateLimiter.TableOwner]}

  defstruct [
    :provider,
    :route,
    :positive_status,
    :positive_body,
    :positive_tenant_resolved,
    :negative_status,
    :negative_body,
    :negative_reason,
    :verified_before_tenant,
    :tenant_resolution_marker,
    :persistence_marker,
    :execution_marker
  ]

  @tenant_id "tenant-123"
  @package_mode_env "MAILGLASS_REFERENCE_HOST_PACKAGE_MODE"
  @workspace_core_ebin_env "MAILGLASS_CORE_WORKSPACE_EBIN"
  @workspace_ebin_env "MAILGLASS_INBOUND_WORKSPACE_EBIN"
  @route "/inbound/:tenant_id/postmark"
  @path "/inbound/#{@tenant_id}/postmark"
  @marker_keys [
    :mailglass_inbound_tenant_resolved,
    :mailglass_inbound_last_handoff,
    :mailglass_inbound_last_execution_result
  ]

  defmodule TenantResolver do
    @moduledoc false
    @behaviour Mailglass.Tenancy

    def scope(query, _context), do: query
    def resolve_outbound_adapter_ref(_context), do: :default

    def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tenant_id}})
        when is_binary(tenant_id) and tenant_id != "" do
      Process.put(:mailglass_inbound_tenant_resolved, true)
      {:ok, tenant_id}
    end

    def resolve_webhook_tenant(_context), do: {:error, :missing_path_param}
  end

  defmodule FakePersistence do
    @moduledoc false

    def persist(handoff, _opts) do
      Process.put(:mailglass_inbound_last_handoff, handoff)

      {:ok,
       %{
         status: :inserted,
         message: handoff.message,
         inbound_record: %{id: "record-123", tenant_id: handoff.tenant_id},
         inbound_evidence: %{id: "evidence-123"},
         route: %{status: :matched, mailbox: __MODULE__}
       }}
    end
  end

  defmodule FakeExecution do
    @moduledoc false

    def dispatch(result, _opts \\ []) do
      Process.put(:mailglass_inbound_last_execution_result, result)
      {:ok, %{status: :queued, mode: :proof}}
    end
  end

  @spec run() :: %__MODULE__{}
  def run do
    with_saved_env(fn ->
      configure_proof_env()
      clear_markers()
      ensure_router_loaded!()
      ensure_rate_limit_owner!()

      signed = call_signed_route()
      positive_body = Jason.decode!(signed.resp_body)
      positive_tenant_resolved = Process.get(:mailglass_inbound_tenant_resolved)

      clear_markers()

      forged = call_forged_route()
      negative_body = Jason.decode!(forged.resp_body)

      tenant_resolution_marker = Process.get(:mailglass_inbound_tenant_resolved)
      persistence_marker = Process.get(:mailglass_inbound_last_handoff)
      execution_marker = Process.get(:mailglass_inbound_last_execution_result)

      %__MODULE__{
        provider: "postmark",
        route: @route,
        positive_status: signed.status,
        positive_body: positive_body,
        positive_tenant_resolved: positive_tenant_resolved,
        negative_status: forged.status,
        negative_body: negative_body,
        negative_reason: negative_body["reason"],
        verified_before_tenant:
          is_nil(tenant_resolution_marker) and is_nil(persistence_marker) and
            is_nil(execution_marker),
        tenant_resolution_marker: tenant_resolution_marker,
        persistence_marker: persistence_marker,
        execution_marker: execution_marker
      }
    end)
  end

  defp call_signed_route do
    conn =
      Plug.Test.conn(:post, @path, postmark_payload())
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", basic_auth("postmark", "secret"))
      |> Plug.Conn.put_private(:raw_body, postmark_payload())

    MailglassReferenceHostWeb.Router.call(conn, [])
  end

  defp call_forged_route do
    conn =
      Plug.Test.conn(:post, @path, postmark_payload())
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", basic_auth("wrong", "secret"))
      |> Plug.Conn.put_private(:raw_body, postmark_payload())

    MailglassReferenceHostWeb.Router.call(conn, [])
  end

  defp ensure_router_loaded! do
    case reference_host_package_mode!() do
      :prepublication ->
        # Admin remains the established published compatibility gate. Core and
        # inbound are both verified workspace builds; exact all-published
        # package-family certification belongs to Phase 160 Plan 06.
        add_reference_host_code_paths(["mailglass_admin"])
        add_workspace_core_code_path!()
        add_workspace_inbound_code_path!()

      :published_siblings ->
        # The root runner remains repo-head while the reference host supplies
        # both sibling packages from its Hex-only lockfile.
        add_reference_host_code_paths(["mailglass_admin", "mailglass_inbound"])
    end

    add_reference_host_code_paths(["mailglass_reference_host"])

    case Code.ensure_loaded(MailglassReferenceHostWeb.Router) do
      {:module, MailglassReferenceHostWeb.Router} ->
        :ok

      {:error, _reason} ->
        admin_router_path =
          Path.expand("../../../mailglass_admin/lib/mailglass_admin/router.ex", __DIR__)

        router_path =
          Path.expand(
            "../../../reference/host_app/lib/mailglass_reference_host_web/router.ex",
            __DIR__
          )

        Code.require_file(admin_router_path)
        Code.require_file(router_path)
        :ok
    end
  end

  defp reference_host_package_mode! do
    case System.get_env(@package_mode_env) do
      "prepublication" ->
        :prepublication

      "published_siblings" ->
        :published_siblings

      nil ->
        raise ArgumentError,
              "#{@package_mode_env} must explicitly select package provenance"

      "published" ->
        raise ArgumentError,
              "exact all-published trust proof is reserved for Phase 160 Plan 06"

      value ->
        raise ArgumentError, "unsupported #{@package_mode_env}=#{inspect(value)}"
    end
  end

  defp add_reference_host_code_paths(apps) do
    for app <- apps do
      ebin_path = Path.expand("../../../reference/host_app/_build/dev/lib/#{app}/ebin", __DIR__)

      if File.dir?(ebin_path) do
        Code.prepend_path(String.to_charlist(ebin_path))
      end
    end
  end

  defp add_workspace_inbound_code_path! do
    add_workspace_code_path!(@workspace_ebin_env, "inbound", [
      MailglassInbound.Ingress.Plug,
      MailglassInbound.Ingress.VerifiedRequest,
      MailglassInbound.Ingress.Pipeline,
      MailglassInbound.Ports.Core,
      MailglassInbound.RateLimiter.TableOwner
    ])
  end

  defp add_workspace_core_code_path! do
    add_workspace_code_path!(@workspace_core_ebin_env, "core", [
      Mailglass.Tenancy,
      Mailglass.Ports.PubSub,
      Mailglass.Ports.Suppression
    ])
  end

  defp add_workspace_code_path!(env_name, package, required_modules) do
    ebin_path = env_name |> System.fetch_env!() |> Path.expand()

    unless File.dir?(ebin_path) do
      raise ArgumentError, "workspace #{package} ebin does not exist: #{ebin_path}"
    end

    Enum.each(required_modules, fn module ->
      beam = Path.join(ebin_path, Atom.to_string(module) <> ".beam")

      unless File.regular?(beam),
        do: raise(ArgumentError, "workspace #{package} beam missing for #{inspect(module)}")
    end)

    Code.prepend_path(String.to_charlist(ebin_path))

    Enum.each(required_modules, fn module ->
      Code.ensure_loaded!(module)
      loaded_path = module |> :code.which() |> List.to_string() |> Path.expand()

      unless Path.dirname(loaded_path) == ebin_path do
        raise ArgumentError,
              "workspace #{package} module provenance mismatch for #{inspect(module)}"
      end
    end)
  end

  defp configure_proof_env do
    Code.ensure_loaded!(TenantResolver)
    Code.ensure_loaded!(FakePersistence)
    Code.ensure_loaded!(FakeExecution)

    Application.put_env(:mailglass, :tenancy, TenantResolver)

    Application.put_env(:mailglass_inbound, :postmark,
      basic_auth: {"postmark", "secret"},
      ip_allowlist: []
    )

    Application.put_env(:mailglass_inbound, :ingress_persistence, FakePersistence)
    Application.put_env(:mailglass_inbound, :ingress_execution, FakeExecution)
  end

  defp with_saved_env(fun) do
    saved = %{
      tenancy: Application.get_env(:mailglass, :tenancy),
      # Reference-host proof snapshots the inbound sibling's env to restore it after the run.
      # credo:disable-for-lines:3 Mailglass.Credo.NoOtherAppEnvReads
      postmark: Application.get_env(:mailglass_inbound, :postmark),
      persistence: Application.get_env(:mailglass_inbound, :ingress_persistence),
      execution: Application.get_env(:mailglass_inbound, :ingress_execution),
      rate_limit_owner: Process.whereis(MailglassInbound.RateLimiter.TableOwner)
    }

    try do
      fun.()
    after
      restore_env(:mailglass, :tenancy, saved.tenancy)
      restore_env(:mailglass_inbound, :postmark, saved.postmark)
      restore_env(:mailglass_inbound, :ingress_persistence, saved.persistence)
      restore_env(:mailglass_inbound, :ingress_execution, saved.execution)

      if is_nil(saved.rate_limit_owner) do
        case Process.whereis(MailglassInbound.RateLimiter.TableOwner) do
          nil -> :ok
          pid -> GenServer.stop(pid)
        end
      end

      clear_markers()
    end
  end

  defp ensure_rate_limit_owner! do
    case Process.whereis(MailglassInbound.RateLimiter.TableOwner) do
      nil ->
        case :ets.whereis(:mailglass_inbound_rate_limit) do
          :undefined -> :ok
          table -> :ets.delete(table)
        end

        {:ok, pid} = apply(MailglassInbound.RateLimiter.TableOwner, :start_link, [])
        Process.unlink(pid)
        :ok

      _pid ->
        :ets.delete_all_objects(:mailglass_inbound_rate_limit)
        :ok
    end
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)

  defp clear_markers do
    Enum.each(@marker_keys, &Process.delete/1)
  end

  defp basic_auth(user, pass) do
    "Basic " <> Base.encode64("#{user}:#{pass}")
  end

  defp postmark_payload do
    Jason.encode!(%{
      "FromFull" => [%{"Email" => "sender@example.com", "Name" => "Sender"}],
      "ToFull" => [%{"Email" => "support@example.com", "Name" => "Support"}],
      "ReplyToFull" => [%{"Email" => "reply@example.com", "Name" => "Reply"}],
      "Subject" => "Support request",
      "MessageID" => "pm-message-123",
      "OriginalRecipient" => "support@example.com",
      "TextBody" => "Plain body",
      "HtmlBody" => "<p>HTML body</p>",
      "Headers" => [
        %{"Name" => "Message-Id", "Value" => "<rfc-message@example.com>"},
        %{"Name" => "Date", "Value" => "2026-05-06T12:00:00Z"}
      ],
      "Attachments" => []
    })
  end
end
