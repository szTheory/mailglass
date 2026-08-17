defmodule Mailglass.RuntimeConfigOwnershipTest do
  use ExUnit.Case, async: true

  @schema_keys MapSet.new(Mailglass.Runtime.Schema.known_keys())

  # These are implementation/test hooks, not validated adopter configuration.
  # Each exception is path-scoped so a new consumer or key fails closed.
  @operational_reads %{
    adapter_endpoint: ["lib/mailglass/tracking.ex"],
    async_adapter_impl: ["lib/mailglass/outbound/async_adapter.ex"],
    deliverability_resolver: ["lib/mix/tasks/mail.doctor.ex"],
    mailgun_replay_cache: ["lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex"],
    oban_multi_insert_all: ["lib/mailglass/optional_deps/oban.ex"],
    rate_limit_clock: ["lib/mailglass/rate_limiter.ex"],
    rate_limit_table_owner: ["lib/mailglass/rate_limiter/table_owner.ex"],
    ses_cert_cache: ["lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex"],
    soft_bounce_escalation: ["lib/mailglass/suppression/escalation.ex"],
    suppression_resync_page_size: ["lib/mailglass/suppression/resync.ex"],
    suppression_store_batch_size: ["lib/mailglass/suppression_store.ex"],
    tracking_event_ledger: ["lib/mailglass/tracking/plug.ex"],
    webhook_reconciler: ["lib/mix/tasks/mailglass.reconcile.ex"]
  }

  test "schema-backed production reads are owned by Runtime" do
    violations =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(&(&1 == "lib/mailglass/runtime.ex"))
      |> Enum.flat_map(fn path -> violations(File.read!(path), path) end)

    assert violations == []
  end

  test "rejects a synthetic schema-backed read outside Runtime" do
    source = "Application.get_env(:mailglass, :tracking, [])"

    assert [{"lib/mailglass/example.ex", 1, :tracking, :schema_backed}] =
             violations(source, "lib/mailglass/example.ex")
  end

  test "rejects an undeclared operational hook and path drift" do
    assert [{_, 1, :new_hook, :undeclared_operational}] =
             violations(
               "Application.fetch_env!(:mailglass, :new_hook)",
               "lib/mailglass/example.ex"
             )

    assert [{_, 1, :rate_limit_clock, :wrong_owner}] =
             violations(
               "Application.get_env(:mailglass, :rate_limit_clock)",
               "lib/mailglass/example.ex"
             )
  end

  test "permits a declared operational hook only in its named owner" do
    assert [] ==
             violations(
               "Application.get_env(:mailglass, :rate_limit_clock)",
               "lib/mailglass/rate_limiter.ex"
             )
  end

  defp violations(source, path) do
    {:ok, ast} = Code.string_to_quoted(source, file: path, columns: true)

    {_ast, violations} =
      Macro.prewalk(ast, [], fn
        {{:., _, [{:__aliases__, _, [:Application]}, function]}, meta, args} = node, acc
        when function in [:get_env, :fetch_env, :fetch_env!, :get_all_env] ->
          {node, maybe_violation(function, args, path, meta[:line] || 1, acc)}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(violations)
  end

  defp maybe_violation(:get_all_env, [:mailglass], path, line, acc),
    do: [{path, line, :all, :schema_backed} | acc]

  defp maybe_violation(_function, [:mailglass, key | _], path, line, acc) when is_atom(key) do
    reason =
      cond do
        MapSet.member?(@schema_keys, key) -> :schema_backed
        path in Map.get(@operational_reads, key, []) -> nil
        Map.has_key?(@operational_reads, key) -> :wrong_owner
        true -> :undeclared_operational
      end

    if reason, do: [{path, line, key, reason} | acc], else: acc
  end

  defp maybe_violation(_function, [:mailglass | _], path, line, acc),
    do: [{path, line, :dynamic, :unclassified} | acc]

  defp maybe_violation(_function, _args, _path, _line, acc), do: acc
end
