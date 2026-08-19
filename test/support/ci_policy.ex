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

  def load! do
    {policy, _binding} = Code.eval_file(@policy_path)
    validate!(policy)
  end

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

    if Map.get(policy, :promotion_ready) == true and active_ids != target_ids do
      raise ArgumentError,
            "promotion-ready policy requires active required and target required IDs to match exactly"
    end

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

  def active_required_lanes(%{active_required: active, target_required: target}) do
    by_id = Map.new(target, &{&1.id, &1})
    Enum.map(active, &Map.fetch!(by_id, &1))
  end

  defp target_lane_ids!(target) do
    Enum.each(target, fn
      %{id: id, name: name, behavior: behavior} = lane
      when is_binary(id) and is_binary(name) and is_atom(behavior) ->
        local? = valid_local_alias?(Map.get(lane, :local_alias))
        ci_only? = is_binary(Map.get(lane, :ci_only_reason))

        if local? == ci_only? do
          raise ArgumentError,
                "target required lane must declare exactly one of local_alias or ci_only_reason: #{inspect(lane)}"
        end

        :ok

      lane ->
        raise ArgumentError, "invalid target required lane: #{inspect(lane)}"
    end)

    names = Enum.map(target, & &1.name)

    if MapSet.size(MapSet.new(names)) != length(names) do
      raise ArgumentError, "target required lane display names must be unique"
    end

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

  defp valid_local_alias?(value) when is_binary(value), do: value != ""

  defp valid_local_alias?(value) when is_list(value),
    do: value != [] and Enum.all?(value, &(is_binary(&1) and &1 != ""))

  defp valid_local_alias?(_value), do: false

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
