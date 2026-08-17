defmodule Mailglass.CIPolicy do
  @moduledoc false

  @policy_path Path.expand("../../config/quality/ci_policy.exs", __DIR__)

  @required_behaviors MapSet.new([
                        :formatting,
                        :warning_and_no_optional_builds,
                        :deterministic_core_suite,
                        :deterministic_inbound_suite,
                        :support_contracts,
                        :mix_tasks,
                        :credo_and_conformance,
                        :core_dialyzer,
                        :inbound_dialyzer,
                        :docs,
                        :audits,
                        :trust,
                        :installer_proofs
                      ])

  @spec load!() :: map()
  def load! do
    {policy, _binding} = Code.eval_file(@policy_path)
    validate!(policy)
  end

  @spec validate!(map()) :: map()
  def validate!(%{active_required: active, target_required: target, advisory: advisory} = policy)
      when is_list(active) and is_list(target) and is_list(advisory) do
    target_ids = target_lane_ids!(target)
    active_ids = ids!(active, "active required")
    advisory_ids = ids!(advisory, "advisory")

    ensure_subset!(
      active_ids,
      target_ids,
      "active required lane IDs must be present in target required"
    )

    ensure_disjoint!(target_ids, advisory_ids, "target required and advisory lane IDs overlap")

    behaviors =
      target
      |> Enum.map(&Map.fetch!(&1, :behavior))
      |> MapSet.new()

    missing_behaviors = MapSet.difference(@required_behaviors, behaviors)

    if MapSet.size(missing_behaviors) > 0 do
      raise ArgumentError,
            "missing target required behavior(s): #{inspect(MapSet.to_list(missing_behaviors))}"
    end

    policy
  end

  def validate!(policy), do: raise(ArgumentError, "invalid CI policy: #{inspect(policy)}")

  @spec active_required_ids(map()) :: MapSet.t(String.t())
  def active_required_ids(%{active_required: active}), do: MapSet.new(active)

  @spec target_behaviors(map()) :: MapSet.t(atom())
  def target_behaviors(%{target_required: target}),
    do: target |> Enum.map(& &1.behavior) |> MapSet.new()

  defp target_lane_ids!(target) do
    Enum.each(target, fn
      %{id: id, behavior: behavior} when is_binary(id) and is_atom(behavior) -> :ok
      lane -> raise ArgumentError, "invalid target required lane: #{inspect(lane)}"
    end)

    ids!(Enum.map(target, & &1.id), "target required")
  end

  defp ids!(ids, label) do
    unless Enum.all?(ids, &Regex.match?(~r/^[a-z][a-z0-9_]*$/, &1)) do
      raise ArgumentError, "#{label} lane IDs must be non-empty snake_case strings"
    end

    set = MapSet.new(ids)

    if MapSet.size(set) != length(ids) do
      raise ArgumentError, "#{label} lane IDs must be unique"
    end

    set
  end

  defp ensure_subset!(left, right, message) do
    unless MapSet.subset?(left, right) do
      raise ArgumentError, "#{message}: #{inspect(MapSet.to_list(MapSet.difference(left, right)))}"
    end
  end

  defp ensure_disjoint!(left, right, message) do
    overlap = MapSet.intersection(left, right)

    if MapSet.size(overlap) > 0 do
      raise ArgumentError, "#{message}: #{inspect(MapSet.to_list(overlap))}"
    end
  end
end
