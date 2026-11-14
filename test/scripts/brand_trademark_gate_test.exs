defmodule Mailglass.Scripts.BrandTrademarkGateTest do
  @moduledoc """
  Shape and invariant checks for the trademark search record and the announcement gate.

  This file never reads the clock: every call passes an explicit date, and the one-argument
  `announcement_allowed?` (which reads today) is asserted to exist but is never called, so
  the always-run lane cannot start failing when the record's `expires` date passes. Expiry
  is judged by the announcement phase, which calls the gate at announcement time.

  Override control: an `owner_override` in the record is the one way a file can allow an
  announcement without a clear register search, so it must be mirrored by an identical
  `@acknowledged_override` in this file, in the same reviewed commit. The test cannot see
  who authored a commit; the review rule (only the owner writes `owner_override`) is in
  `.planning/research/brand-v2-adoption/TRADEMARK-SEARCH.md`.
  """

  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/brand_trademark_gate.exs")
  @record_rel ".planning/research/brand-v2-adoption/trademark-search.json"
  @record_path Path.join(@repo_root, @record_rel)

  # Mirrors the record's owner_override. nil while no owner override is committed. Change it
  # only together with the record, in one commit the owner authors and reviews.
  @acknowledged_override nil

  @agent_by ~r/automated|agent|claude/i

  # The prose surfaces that must stay free of trademark symbols until an announcement is
  # allowed.
  @symbol_globs [
    "README.md",
    "CHANGELOG.md",
    "mailglass_admin/README.md",
    "mailglass_admin/CHANGELOG.md",
    "mailglass_inbound/README.md",
    "mailglass_inbound/CHANGELOG.md",
    "docs/**/*.md",
    "guides/**/*.md",
    "mailglass_admin/docs/**/*.md",
    "mailglass_inbound/docs/**/*.md",
    "brandbook/**/*.md"
  ]
  @symbols ["™", "®"]

  setup_all do
    Code.require_file(@script)
    :ok
  end

  describe "the committed record" do
    test "loads and validates" do
      assert {:ok, record} = gate(:load, [@record_path])
      assert {:ok, ^record} = gate(:validate, [record])
      assert record["schema"] == gate(:schema, [])
      assert record["classes"] == [9, 38, 42]
    end

    test "is the record the gate reads by default" do
      assert gate(:load, []) == gate(:load, [@record_path])
    end

    test "sits under .planning/research, where a milestone archive does not move it" do
      assert String.starts_with?(@record_rel, ".planning/research/")
      refute String.contains?(@record_rel, ".planning/phases/")
      assert File.regular?(@record_path)
    end

    test "decision and announcement_allowed? agree on an injected date" do
      record = committed_record()
      today = Date.from_iso8601!(record["date"])

      decision = gate(:decision, [record, today])
      assert match?({:allow, _basis}, decision) or match?({:deny, _reason}, decision)
      assert allowed?(record, today) == match?({:allow, _basis}, decision)
    end

    test "the command line reports a deny for the committed record and exits non-zero" do
      record = committed_record()

      if allowed?(record, Date.from_iso8601!(record["date"])) do
        # An allowed record is the owner's recorded outcome; nothing to deny.
        assert {0, _output} = gate(:cli, [["check", "--today", record["date"]]])
      else
        assert {1, output} = gate(:cli, [["check", "--today", record["date"]]])
        assert output =~ "deny"
      end
    end

    test "committed owner_override is owner-acknowledged" do
      record = committed_record()

      case override_control(record, @acknowledged_override) do
        :ok -> assert record["owner_override"] == @acknowledged_override
        {:error, message} -> flunk(message)
      end
    end

    test "no trademark symbol appears in markdown while the record does not allow an announcement" do
      record = committed_record()
      today = Date.from_iso8601!(record["date"])

      case gate(:decision, [record, today]) do
        {:deny, reason} ->
          hits = symbol_hits(@repo_root)

          assert hits == [],
                 "the trademark record denies announcement (#{reason}), so no trademark or " <>
                   "registered-mark symbol (U+2122, U+00AE) may appear in README, CHANGELOG, " <>
                   "docs, guides or brandbook markdown. Found:\n" <>
                   Enum.join(hits, "\n")

        {:allow, _basis} ->
          :ok
      end
    end
  end

  describe "the gate entry points" do
    test "announcement_allowed? exists at the arity the announcement phase calls and the pure arity" do
      assert Code.ensure_loaded?(Mailglass.BrandTrademarkGate)
      assert function_exported?(Mailglass.BrandTrademarkGate, :announcement_allowed?, 1)
      assert function_exported?(Mailglass.BrandTrademarkGate, :announcement_allowed?, 2)
    end
  end

  # --- helpers -------------------------------------------------------------------------

  defp gate(function, args), do: apply(Mailglass.BrandTrademarkGate, function, args)

  # The gate module is loaded in setup_all, so calls go through apply/3 rather than a
  # compile-time remote call (which would warn under --warnings-as-errors).
  defp allowed?(record, today), do: gate(:announcement_allowed?, [record, today])

  defp committed_record, do: @record_path |> File.read!() |> Jason.decode!()

  # Returns :ok, or {:error, message} when an override is unacknowledged or agent-named.
  defp override_control(record, acknowledged) do
    override = record["owner_override"]

    cond do
      override != acknowledged ->
        {:error,
         "owner_override in #{@record_rel} is not mirrored by @acknowledged_override in " <>
           "#{Path.relative_to(__ENV__.file, @repo_root)}. An owner_override may be added only " <>
           "in a reviewed commit authored by the owner that also updates @acknowledged_override " <>
           "to the identical map. Agents never write it."}

      agent_override?(record, override) ->
        {:error,
         "owner_override.by #{inspect(override["by"])} names the record's searcher or an " <>
           "automated agent. Only the owner writes owner_override, and agents never do."}

      true ->
        :ok
    end
  end

  defp agent_override?(_record, nil), do: false

  defp agent_override?(record, %{"by" => by}) when is_binary(by) do
    by == record["searcher"] or Regex.match?(@agent_by, by)
  end

  defp agent_override?(_record, _override), do: true

  # "relative/path:line" for every line in the scanned markdown that holds a symbol.
  defp symbol_hits(root) do
    for glob <- @symbol_globs,
        file <- Path.wildcard(Path.join(root, glob)),
        {line, number} <- file |> File.read!() |> String.split("\n") |> Enum.with_index(1),
        String.contains?(line, @symbols) do
      "#{Path.relative_to(file, root)}:#{number}"
    end
  end
end
