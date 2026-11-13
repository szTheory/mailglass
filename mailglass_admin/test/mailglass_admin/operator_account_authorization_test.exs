defmodule MailglassAdmin.OperatorAccountAuthorizationTest do
  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.InboundFixtures

  @moduletag :account_authorization

  setup do
    subject_id = "account-auth-#{System.unique_integer([:positive])}"
    MailglassAdmin.TestOperatorAuth.reset_operator_access_calls!(subject_id)

    on_exit(fn -> MailglassAdmin.TestOperatorAuth.clear_operator_access_calls!(subject_id) end)

    {:ok, subject_id: subject_id}
  end

  @tag :account_auth_tracer
  test "denied Deliveries Account patch redirects before issuing a repository query",
       %{conn: conn, subject_id: subject_id} do
    allowed_tenant = "account-auth-start-#{System.unique_integer([:positive])}"
    switched_tenant = "account-auth-allowed-#{System.unique_integer([:positive])}"

    InboundFixtures.seed_matched!(allowed_tenant)
    InboundFixtures.seed_matched!(switched_tenant)

    conn = operator_conn(conn, subject_id)

    {:ok, view, _html} =
      live(conn, operator_path(%{"tenant_id" => allowed_tenant, "view" => "deliveries"}))

    {handler_id, ref} = attach_query_observer(view)

    try do
      render_patch(
        view,
        operator_path(%{"tenant_id" => switched_tenant, "view" => "deliveries"})
      )

      assert_receive {^ref, :query, _metadata},
                     1_000,
                     "the allowed patch must prove the query observer is active"

      flush_query_messages(ref)

      result =
        render_patch(
          view,
          operator_path(%{"tenant_id" => "forbidden-account", "view" => "deliveries"})
        )

      assert {:error, {:redirect, %{to: "/login"}}} = result
      assert assert_redirect(view, "/login") == %{"error" => "Operator access denied."}

      refute_receive {^ref, :query, _metadata},
                     100,
                     "a denied Account patch must be stopped before repository reads"
    after
      :telemetry.detach(handler_id)
    end
  end

  test "denied Inbound Account patch with a selected record redirects before reads",
       %{conn: conn, subject_id: subject_id} do
    initial_tenant = "account-auth-inbound-start-#{System.unique_integer([:positive])}"
    switched_tenant = "account-auth-inbound-allowed-#{System.unique_integer([:positive])}"
    %{record: initial_record} = InboundFixtures.seed_matched!(initial_tenant)
    %{record: switched_record} = InboundFixtures.seed_matched!(switched_tenant)

    {:ok, view, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(inbound_path(%{"tenant_id" => initial_tenant, "inbound_id" => initial_record.id}))

    {handler_id, ref} = attach_query_observer(view)

    try do
      render_patch(
        view,
        inbound_path(%{"tenant_id" => switched_tenant, "inbound_id" => switched_record.id})
      )

      assert_receive {^ref, :query, _metadata},
                     1_000,
                     "the allowed Inbound patch must prove the query observer is active"

      flush_query_messages(ref)

      result =
        render_patch(
          view,
          inbound_path(%{
            "tenant_id" => "forbidden-account",
            "inbound_id" => switched_record.id,
            "full" => "1"
          })
        )

      assert {:error, {:redirect, %{to: "/login"}}} = result
      assert assert_redirect(view, "/login") == %{"error" => "Operator access denied."}

      refute_receive {^ref, :query, _metadata},
                     100,
                     "a denied Inbound patch must be stopped before selection or full-detail reads"
    after
      :telemetry.detach(handler_id)
    end
  end

  test "the hook checks only tenant-key changes and preserves trusted callback context",
       %{conn: conn, subject_id: subject_id} do
    initial_tenant = "account-auth-context-start-#{System.unique_integer([:positive])}"
    second_tenant = "account-auth-context-second-#{System.unique_integer([:positive])}"
    InboundFixtures.seed_matched!(initial_tenant)
    InboundFixtures.seed_matched!(second_tenant)

    trusted_recent_auth =
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    trusted_session = %{
      "current_user_id" => subject_id,
      "tenant_id" => "account-auth-session",
      "auth_method" => "password",
      "recent_auth_at" => trusted_recent_auth
    }

    {:ok, view, _html} =
      conn
      |> operator_conn(subject_id, trusted_session)
      |> live(operator_path(%{"tenant_id" => initial_tenant, "view" => "deliveries"}))

    initial_calls = MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)
    assert length(initial_calls) == 2

    assert Enum.map(initial_calls, & &1.params["tenant_id"]) |> Enum.sort() ==
             Enum.sort([nil, initial_tenant])

    assert Enum.count(initial_calls, & &1.connected?) == 1

    Enum.each(initial_calls, fn call ->
      assert call.action == :operator_access
      assert call.actor.subject_id == subject_id
      assert call.actor.tenant_id == "account-auth-session"
      assert call.session["subject_id"] == subject_id
      assert call.session["tenant_id"] == "account-auth-session"
      assert call.session["auth_method"] == "password"
      assert call.session["recent_auth_at"] == trusted_recent_auth
    end)

    render_patch(
      view,
      operator_path(%{
        "tenant_id" => initial_tenant,
        "view" => "deliveries",
        "page" => "2",
        "delivery_id" => "00000000-0000-0000-0000-000000000001",
        "full" => "1"
      })
    )

    assert length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)) == 2

    activity_free_tenant = "activity-free-permitted-#{System.unique_integer([:positive])}"

    render_patch(
      view,
      operator_path(%{"tenant_id" => activity_free_tenant, "view" => "deliveries"})
    )

    calls = MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)
    assert length(calls) == 3
    switch_call = List.last(calls)
    assert switch_call.connected?
    assert switch_call.params["tenant_id"] == activity_free_tenant
    assert switch_call.session["subject_id"] == subject_id
    assert switch_call.session["tenant_id"] == "account-auth-session"
    assert switch_call.session["recent_auth_at"] == trusted_recent_auth
    assert switch_call.actor.subject_id == subject_id
    assert switch_call.actor.tenant_id == "account-auth-session"

    %{socket: %{assigns: assigns}} = :sys.get_state(view.pid)
    assert assigns.selected_tenant_id == activity_free_tenant
    refute Enum.any?(assigns.tenant_options, &(&1.id == activity_free_tenant))

    render_patch(view, operator_path(%{"view" => "deliveries"}))
    calls = MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)
    assert length(calls) == 4
    absent_call = List.last(calls)
    assert absent_call.connected?
    refute Map.has_key?(absent_call.params, "tenant_id")

    render_patch(view, operator_path(%{"tenant_id" => "", "view" => "deliveries"}))
    calls = MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)
    assert length(calls) == 5
    blank_call = List.last(calls)
    assert blank_call.connected?
    assert Map.has_key?(blank_call.params, "tenant_id")
    assert blank_call.params["tenant_id"] == ""

    render_patch(view, operator_path(%{"tenant_id" => "", "view" => "deliveries", "page" => "2"}))
    assert length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)) == 5
  end

  test "both LiveViews accept the two normalized host success forms for activity-free Accounts",
       %{conn: conn, subject_id: subject_id} do
    initial_tenant = "account-auth-success-start-#{System.unique_integer([:positive])}"
    InboundFixtures.seed_matched!(initial_tenant)

    {:ok, deliveries, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(operator_path(%{"tenant_id" => initial_tenant, "view" => "deliveries"}))

    render_patch(
      deliveries,
      operator_path(%{"tenant_id" => "normalized-actor-account", "view" => "deliveries"})
    )

    %{socket: %{assigns: delivery_assigns}} = :sys.get_state(deliveries.pid)
    assert delivery_assigns.selected_tenant_id == "normalized-actor-account"
    refute Enum.any?(delivery_assigns.tenant_options, &(&1.id == "normalized-actor-account"))
    assert delivery_assigns.operator_actor.subject_id == subject_id
    assert %DateTime{} = delivery_assigns.operator_actor.recent_auth_at
    assert delivery_assigns.operator_auth.recent_auth?
    assert delivery_assigns.operator_account_auth_probe?

    inbound_tenant = "account-auth-inbound-success-start-#{System.unique_integer([:positive])}"
    %{record: inbound_record} = InboundFixtures.seed_matched!(inbound_tenant)

    calls_before_inbound =
      length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id))

    {:ok, inbound, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(inbound_path(%{"tenant_id" => inbound_tenant}))

    assert length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)) ==
             calls_before_inbound + 2

    render_patch(
      inbound,
      inbound_path(%{"tenant_id" => inbound_tenant, "inbound_id" => inbound_record.id})
    )

    assert length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)) ==
             calls_before_inbound + 2

    render_patch(inbound, inbound_path(%{"tenant_id" => "plain-actor-account"}))

    assert length(MailglassAdmin.TestOperatorAuth.operator_access_calls(subject_id)) ==
             calls_before_inbound + 3

    %{socket: %{assigns: inbound_assigns}} = :sys.get_state(inbound.pid)
    assert inbound_assigns.selected_tenant_id == "plain-actor-account"
    refute Enum.any?(inbound_assigns.tenant_options, &(&1.id == "plain-actor-account"))
    assert inbound_assigns.operator_actor.subject_id == subject_id
    assert inbound_assigns.operator_actor.auth_method == "host-session"
  end

  test "custom mount denial and stale-auth defaults keep existing redirect behavior",
       %{conn: conn, subject_id: subject_id} do
    initial_tenant = "account-auth-custom-start-#{System.unique_integer([:positive])}"
    %{record: inbound_record} = InboundFixtures.seed_matched!(initial_tenant)

    {:ok, custom_mount, _html} =
      conn
      |> operator_conn(subject_id)
      |> live("/secure/console?" <> URI.encode_query(%{"tenant_id" => initial_tenant}))

    assert {:error, {:redirect, %{to: "/host-account-denied"}}} =
             render_patch(custom_mount, "/secure/console?tenant_id=custom-denied-account")

    assert assert_redirect(custom_mount, "/host-account-denied") == %{
             "error" => "The host denied this Account."
           }

    {:ok, custom_inbound, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(
        "/secure/console/inbound?" <>
          URI.encode_query(%{"tenant_id" => initial_tenant, "inbound_id" => inbound_record.id})
      )

    assert {:error, {:redirect, %{to: "/host-account-denied"}}} =
             render_patch(
               custom_inbound,
               "/secure/console/inbound?" <>
                 URI.encode_query(%{
                   "tenant_id" => "custom-denied-account",
                   "inbound_id" => inbound_record.id,
                   "full" => "1"
                 })
             )

    assert assert_redirect(custom_inbound, "/host-account-denied") == %{
             "error" => "The host denied this Account."
           }

    {:ok, default_denial, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(operator_path(%{"tenant_id" => initial_tenant, "view" => "deliveries"}))

    assert {:error, {:redirect, %{to: "/login"}}} =
             render_patch(
               default_denial,
               operator_path(%{"tenant_id" => "default-denied-account", "view" => "deliveries"})
             )

    assert assert_redirect(default_denial, "/login") == %{
             "error" => "You are not authorized to access mailglass."
           }

    {:ok, stale_view, _html} =
      conn
      |> operator_conn(subject_id)
      |> live(operator_path(%{"tenant_id" => initial_tenant, "view" => "deliveries"}))

    assert {:error, {:redirect, %{to: "/login"}}} =
             render_patch(
               stale_view,
               operator_path(%{"tenant_id" => "stale-account", "view" => "deliveries"})
             )

    assert assert_redirect(stale_view, "/login") == %{
             "error" => "Recent authentication is required."
           }
  end

  defp attach_query_observer(view) do
    ref = make_ref()
    test_pid = self()
    view_pid = view.pid
    handler_id = "account-auth-query-#{inspect(ref)}"
    event = TestRepo.config()[:telemetry_prefix] ++ [:query]

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, _config ->
        if self() == view_pid do
          send(test_pid, {ref, :query, metadata})
        end
      end,
      nil
    )

    {handler_id, ref}
  end

  defp flush_query_messages(ref) do
    receive do
      {^ref, :query, _metadata} -> flush_query_messages(ref)
    after
      0 -> :ok
    end
  end

  defp operator_path(params) do
    case URI.encode_query(params) do
      "" -> "/ops/mail"
      query -> "/ops/mail?" <> query
    end
  end

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> "/ops/mail/inbound"
      query -> "/ops/mail/inbound?" <> query
    end
  end

  defp operator_conn(conn, subject_id, overrides \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    conn
    |> Plug.Test.init_test_session(
      Map.merge(
        %{
          "current_user_id" => subject_id,
          "tenant_id" => "account-auth-session",
          "auth_method" => "password",
          "recent_auth_at" => now
        },
        overrides
      )
    )
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
  end
end
