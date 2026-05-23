defmodule Mailglass.Credo.IntegrationTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile

  # WR-05: the integration corpus exercises the SHIPPED .credo.exs params, sourced
  # live via Code.eval_file in setup_all — not a hand-maintained duplicate that can
  # drift. (The former hardcoded check-params literal had gone stale: a
  # singular-atom TelemetryEventConvention root, no :mimemail/:gen_smtp_client
  # gated keys, and no StreamPolicyConsistent.) @check_cases below is the real
  # fixture corpus (synthetic bad/clean sources per check) and is intentionally
  # kept; only the param SOURCE moved to the live config.

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
          Mailglass.Message.build(Swoosh.Email.new(), to: user.email, tracking: [opens: true])
        end
      end
      """,
      clean_source: """
      defmodule Mailglass.Mailers.SafeAuthMailer do
        use Mailglass.Mailable

        def password_reset(user) do
          Mailglass.Message.build(Swoosh.Email.new(), to: user.email, tracking: [])
        end
      end
      """
    }
  ]

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    {config, _binding} = Code.eval_file(".credo.exs")
    {:ok, live_checks: load_checks(config)}
  end

  test "every @check_cases module is registered in the live .credo.exs config", %{
    live_checks: live_checks
  } do
    registered =
      live_checks
      |> Enum.map(fn {mod, _params} -> mod end)
      |> MapSet.new()

    missing =
      @check_cases
      |> Enum.map(& &1.check)
      |> Enum.reject(&MapSet.member?(registered, &1))

    assert missing == [],
           "Integration corpus references checks not registered in the live " <>
             ".credo.exs (stale fixture / renamed or removed check):\n" <>
             Enum.map_join(missing, "\n", fn mod -> "  #{inspect(mod)}" end)
  end

  test "synthetic violations trigger each custom check", %{live_checks: live_checks} do
    Enum.each(@check_cases, fn check_case ->
      issues =
        run_check(
          check_case.check,
          check_case.bad_source,
          check_case.filename,
          params_for(live_checks, check_case.check)
        )

      assert issues != [],
             "#{check_case.id} (#{inspect(check_case.check)}) expected at least one issue"
    end)
  end

  test "synthetic clean code passes each custom check", %{live_checks: live_checks} do
    Enum.each(@check_cases, fn check_case ->
      issues =
        run_check(
          check_case.check,
          check_case.clean_source,
          check_case.filename,
          params_for(live_checks, check_case.check)
        )

      assert issues == [],
             "#{check_case.id} (#{inspect(check_case.check)}) expected zero issues, got #{length(issues)}"
    end)
  end

  defp params_for(live_checks, check_module) do
    case find_check(live_checks, check_module) do
      params when is_list(params) -> params
      nil -> []
    end
  end

  defp run_check(check_module, source, filename, params) do
    source
    |> SourceFile.parse(filename)
    |> check_module.run(params)
  end

  # Normalize the first config's :checks into a flat list of {module, params}
  # tuples. The value may be a flat keyword-style list or grouped under
  # :enabled / :extra / :disabled keys — handle both (mirrors
  # credo_config_sentinel_test.exs so the two cannot drift).
  defp load_checks(config) do
    config
    |> Map.fetch!(:configs)
    |> hd()
    |> Map.fetch!(:checks)
    |> flatten_checks()
  end

  defp flatten_checks(checks) when is_list(checks) do
    if Keyword.keyword?(checks) and
         Enum.all?(Keyword.keys(checks), &(&1 in [:enabled, :extra, :disabled])) and
         checks != [] do
      checks
      |> Keyword.values()
      |> List.flatten()
    else
      checks
    end
  end

  defp find_check(checks, module) do
    Enum.find_value(checks, fn
      {^module, params} -> params
      _ -> nil
    end)
  end
end
