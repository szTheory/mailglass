defmodule Mailglass.Credo.IntegrationTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile

  @extra_checks [
    {Mailglass.Credo.NoRawSwooshSendInLib,
     [
       allowed_modules: [Mailglass.Adapters.Swoosh]
     ]},
    {Mailglass.Credo.NoPiiInTelemetryMeta,
     [
       blocked_keys: ~w(to from cc bcc body html_body text_body subject headers recipient email)a
     ]},
    {Mailglass.Credo.NoUnscopedTenantQueryInLib,
     [
       tenanted_schemas: [
         Mailglass.Outbound.Delivery,
         Mailglass.Events.Event,
         Mailglass.Suppression.Entry,
         Mailglass.Webhook.WebhookEvent
       ],
       repo_functions: [:all, :one, :get, :get!, :get_by, :get_by!],
       unscoped_audit_helpers: [{Mailglass.Tenancy, :audit_unscoped_bypass}]
     ]},
    {Mailglass.Credo.NoBareOptionalDepReference,
     [
       gated_modules: %{
         Oban => Mailglass.OptionalDeps.Oban,
         OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
         Mjml => Mailglass.OptionalDeps.Mjml,
         GenSmtp => Mailglass.OptionalDeps.GenSmtp,
         Sigra => Mailglass.OptionalDeps.Sigra
       },
       included_path_prefixes: ["lib/mailglass/"]
     ]},
    {Mailglass.Credo.NoOversizedUseInjection, [max_lines: 20]},
    {Mailglass.Credo.PrefixedPubSubTopics, [required_prefix: "mailglass:"]},
    {Mailglass.Credo.NoDefaultModuleNameSingleton,
     [
       watched_modules: [GenServer, Agent, Registry, Supervisor]
     ]},
    {Mailglass.Credo.NoCompileEnvOutsideConfig,
     [
       allowed_modules: [Mailglass.Config]
     ]},
    {Mailglass.Credo.NoOtherAppEnvReads, [allowed_apps: [:mailglass]]},
    {Mailglass.Credo.TelemetryEventConvention, [required_root: :mailglass, min_segments: 4]},
    {Mailglass.Credo.NoFullResponseInLogs,
     [
       suspicious_fragments: ~w(response resp body payload)
     ]},
    {Mailglass.Credo.NoDirectDateTimeNow,
     [
       allowed_modules: [Mailglass.Clock, Mailglass.Clock.System, Mailglass.Clock.Frozen],
       included_path_prefixes: ["lib/mailglass/"]
     ]},
    {Mailglass.Credo.NoTrackingOnAuthStream,
     [
       auth_name_heuristics:
         ~w(magic_link password_reset verify_email confirm_account reset_token verification_token confirm_email two_factor 2fa)
     ]}
  ]

  @check_cases [
    %{
      id: "LINT-01",
      check: Mailglass.Credo.NoRawSwooshSendInLib,
      filename: "lib/mailglass/outbound/no_raw_swoosh_send_in_lib_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadSend do
        def run(email), do: Swoosh.Mailer.deliver(email)
      end
      """,
      clean_source: """
      defmodule Mailglass.Adapters.Swoosh do
        def run(email), do: Swoosh.Mailer.deliver(email)
      end
      """
    },
    %{
      id: "LINT-02",
      check: Mailglass.Credo.NoPiiInTelemetryMeta,
      filename: "lib/mailglass/telemetry/no_pii_in_telemetry_meta_bad.ex",
      bad_source: """
      defmodule Mailglass.Telemetry.BadMeta do
        def emit do
          :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{to: "user@example.com"})
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Telemetry.GoodMeta do
        def emit do
          :telemetry.execute([:mailglass, :outbound, :send, :stop], %{latency_ms: 1}, %{tenant_id: "t_123"})
        end
      end
      """
    },
    %{
      id: "LINT-03",
      check: Mailglass.Credo.NoUnscopedTenantQueryInLib,
      filename: "lib/mailglass/outbound/no_unscoped_tenant_query_in_lib_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadTenantScope do
        import Ecto.Query
        alias Mailglass.Outbound.Delivery
        alias Mailglass.Repo

        def list do
          Repo.all(from(d in Delivery, select: d.id))
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Outbound.GoodTenantScope do
        import Ecto.Query
        alias Mailglass.Outbound.Delivery
        alias Mailglass.Repo

        def list(tenant_context) do
          query = from(d in Delivery, select: d.id)
          scoped_query = Mailglass.Tenancy.scope(query, tenant_context)
          Repo.all(scoped_query)
        end
      end
      """
    },
    %{
      id: "LINT-04",
      check: Mailglass.Credo.NoBareOptionalDepReference,
      filename: "lib/mailglass/outbound/no_bare_optional_dep_reference_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadOptionalDeps do
        def insert(job), do: Oban.insert(job)
      end
      """,
      clean_source: """
      defmodule Mailglass.Outbound.GoodOptionalDeps do
        def available?, do: Mailglass.OptionalDeps.Oban.available?()
      end
      """
    },
    %{
      id: "LINT-05",
      check: Mailglass.Credo.NoOversizedUseInjection,
      filename: "lib/mailglass/credo/no_oversized_use_injection_bad.ex",
      bad_source: """
      defmodule Mailglass.BigMacro do
        defmacro __using__(_opts) do
          quote do
            @behaviour Mailglass.Mailable
            import Swoosh.Email
            def f1, do: :ok
            def f2, do: :ok
            def f3, do: :ok
            def f4, do: :ok
            def f5, do: :ok
            def f6, do: :ok
            def f7, do: :ok
            def f8, do: :ok
            def f9, do: :ok
            def f10, do: :ok
            def f11, do: :ok
            def f12, do: :ok
            def f13, do: :ok
            def f14, do: :ok
            def f15, do: :ok
            def f16, do: :ok
            def f17, do: :ok
            def f18, do: :ok
            def f19, do: :ok
            def f20, do: :ok
          end
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.CompactMacro do
        defmacro __using__(_opts) do
          quote do
            @behaviour Mailglass.Mailable
            def f1, do: :ok
            def f2, do: :ok
          end
        end
      end
      """
    },
    %{
      id: "LINT-06",
      check: Mailglass.Credo.PrefixedPubSubTopics,
      filename: "lib/mailglass/pubsub/prefixed_pub_sub_topics_bad.ex",
      bad_source: """
      defmodule Mailglass.PubSub.BadTopic do
        def broadcast(payload) do
          Phoenix.PubSub.broadcast(Mailglass.PubSub, "events:delivery", payload)
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.PubSub.GoodTopic do
        def broadcast(payload) do
          Phoenix.PubSub.broadcast(Mailglass.PubSub, "mailglass:events:delivery", payload)
        end
      end
      """
    },
    %{
      id: "LINT-07",
      check: Mailglass.Credo.NoDefaultModuleNameSingleton,
      filename: "lib/mailglass/runtime/no_default_module_name_singleton_bad.ex",
      bad_source: """
      defmodule Mailglass.Runtime.BadSingleton do
        def start_link(opts) do
          GenServer.start_link(__MODULE__, opts, name: __MODULE__)
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Runtime.GoodSingleton do
        def start_link(opts) do
          name = Keyword.get(opts, :name)
          GenServer.start_link(__MODULE__, opts, name: name)
        end
      end
      """
    },
    %{
      id: "LINT-08",
      check: Mailglass.Credo.NoCompileEnvOutsideConfig,
      filename: "lib/mailglass/config/no_compile_env_outside_config_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadCompileEnv do
        def adapter, do: Application.compile_env(:mailglass, :adapter)
      end
      """,
      clean_source: """
      defmodule Mailglass.Config.Runtime do
        def adapter, do: Application.compile_env(:mailglass, :adapter)
      end
      """
    },
    %{
      id: "LINT-09",
      check: Mailglass.Credo.NoOtherAppEnvReads,
      filename: "lib/mailglass/config/no_other_app_env_reads_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadAppEnvRead do
        def client, do: Application.get_env(:swoosh, :api_client)
      end
      """,
      clean_source: """
      defmodule Mailglass.Outbound.GoodAppEnvRead do
        def adapter, do: Application.get_env(:mailglass, :adapter)
      end
      """
    },
    %{
      id: "LINT-10",
      check: Mailglass.Credo.TelemetryEventConvention,
      filename: "lib/mailglass/telemetry/telemetry_event_convention_bad.ex",
      bad_source: """
      defmodule Mailglass.Telemetry.BadEvent do
        def emit do
          :telemetry.execute([:mailglass, :outbound, :send], %{count: 1}, %{})
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Telemetry.GoodEvent do
        def emit do
          :telemetry.execute([:mailglass, :outbound, :send, :stop], %{count: 1}, %{})
        end
      end
      """
    },
    %{
      id: "LINT-11",
      check: Mailglass.Credo.NoFullResponseInLogs,
      filename: "lib/mailglass/logging/no_full_response_in_logs_bad.ex",
      bad_source: """
      defmodule Mailglass.Logging.BadResponseLog do
        def log(response_payload) do
          Logger.error("provider response=\#{inspect(response_payload)}")
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Logging.GoodResponseLog do
        def log(message_id) do
          Logger.info("provider message_id=\#{message_id}")
        end
      end
      """
    },
    %{
      id: "LINT-12",
      check: Mailglass.Credo.NoDirectDateTimeNow,
      filename: "lib/mailglass/clock/no_direct_date_time_now_bad.ex",
      bad_source: """
      defmodule Mailglass.Outbound.BadClockUsage do
        def now, do: DateTime.utc_now()
      end
      """,
      clean_source: """
      defmodule Mailglass.Clock.System do
        def utc_now, do: DateTime.utc_now()
      end
      """
    },
    %{
      id: "TRACK-02",
      check: Mailglass.Credo.NoTrackingOnAuthStream,
      filename: "lib/mailglass/mailers/no_tracking_on_auth_stream_bad.ex",
      bad_source: """
      defmodule Mailglass.Mailers.AuthMailer do
        use Mailglass.Mailable

        def password_reset(user) do
          Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [opens: true])
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Mailers.SafeAuthMailer do
        use Mailglass.Mailable

        def password_reset(user) do
          Mailglass.Message.new(Swoosh.Email.new(), to: user.email, tracking: [])
        end
      end
      """
    }
  ]

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  test "integration fixture includes all 13 custom checks" do
    assert length(@extra_checks) == 13
    assert length(@check_cases) == 13
  end

  test "synthetic violations trigger each custom check" do
    Enum.each(@check_cases, fn check_case ->
      issues =
        run_check(
          check_case.check,
          check_case.bad_source,
          check_case.filename,
          params_for(check_case.check)
        )

      assert issues != [],
             "#{check_case.id} (#{inspect(check_case.check)}) expected at least one issue"
    end)
  end

  test "synthetic clean code passes each custom check" do
    Enum.each(@check_cases, fn check_case ->
      issues =
        run_check(
          check_case.check,
          check_case.clean_source,
          check_case.filename,
          params_for(check_case.check)
        )

      assert issues == [],
             "#{check_case.id} (#{inspect(check_case.check)}) expected zero issues, got #{length(issues)}"
    end)
  end

  defp params_for(check_module) do
    case Enum.find(@extra_checks, fn {module, _params} -> module == check_module end) do
      {_module, params} -> params
      nil -> []
    end
  end

  defp run_check(check_module, source, filename, params) do
    source
    |> SourceFile.parse(filename)
    |> check_module.run(params)
  end
end
