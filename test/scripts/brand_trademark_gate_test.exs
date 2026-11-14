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
    Application.put_env(:mailglass, :script_library_mode, true)
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

  describe "evidence invariants" do
    test "clear without a register search is invalid and denies" do
      record = %{clear_record() | "register_checked" => false}

      assert issues(record) == [:clear_without_evidence]
      assert gate(:decision, [record, before_expiry(record)]) == {:deny, :invalid_record}
      refute allowed?(record, before_expiry(record))
    end

    test "register_checked while a required register is not_checked is invalid" do
      record =
        committed_record()
        |> Map.put("register_checked", true)
        |> set_outcome(["uspto"], "not_checked")

      assert :register_claim_without_evidence in issues(record)
      assert gate(:decision, [record, before_expiry(record)]) == {:deny, :invalid_record}
    end

    test "clear with a not_checked source is invalid even when the registers are checked" do
      record = clear_record() |> set_outcome(["image_search"], "not_checked")

      assert issues(record) == [:clear_without_evidence]
    end

    test "clear with a blocked source is invalid" do
      record = clear_record() |> set_outcome(["github"], "blocked")

      assert :clear_without_evidence in issues(record)
      assert :blocked_source_not_reflected in issues(record)
    end

    test "a blocked source under caution is invalid" do
      record = committed_record() |> set_outcome(["github"], "blocked")

      assert record["overall"] == "caution"
      assert issues(record) == [:blocked_source_not_reflected]
      assert gate(:decision, [record, before_expiry(record)]) == {:deny, :invalid_record}
    end

    test "every register id must be present" do
      for id <- gate(:required_source_ids, []) do
        record = drop_source(committed_record(), id)

        assert {:missing_required_source, id} in issues(record)
        assert gate(:decision, [record, before_expiry(record)]) == {:deny, :invalid_record}
      end
    end
  end

  describe "decision: the allow and deny paths" do
    test "clear with a register search and an unexpired record allows" do
      record = clear_record()
      today = before_expiry(record)

      assert {:ok, ^record} = gate(:validate, [record])
      assert gate(:decision, [record, today]) == {:allow, :clear}
      assert allowed?(record, today)
      assert allowed?({:ok, record}, today)
    end

    test "today equal to expires counts as expired, and so does any later day" do
      record = clear_record()
      expires = Date.from_iso8601!(record["expires"])

      assert gate(:decision, [record, expires]) == {:deny, :expired}
      assert gate(:decision, [record, Date.add(expires, 1)]) == {:deny, :expired}
      assert gate(:decision, [record, Date.add(expires, -1)]) == {:allow, :clear}
      refute allowed?(record, expires)
    end

    test "blocked is never overridable by the file" do
      blocked =
        committed_record() |> Map.put("overall", "blocked") |> set_outcome(["github"], "blocked")

      overridden = Map.put(blocked, "owner_override", owner_override())

      assert {:ok, ^overridden} = gate(:validate, [overridden])
      assert gate(:decision, [blocked, before_expiry(blocked)]) == {:deny, :blocked}
      assert gate(:decision, [overridden, before_expiry(overridden)]) == {:deny, :blocked}
      refute allowed?(overridden, before_expiry(overridden))
    end

    test "a populated owner_override on a caution record allows until the record expires" do
      record = Map.put(committed_record(), "owner_override", owner_override())
      expires = Date.from_iso8601!(record["expires"])

      assert {:ok, ^record} = gate(:validate, [record])
      assert gate(:decision, [record, before_expiry(record)]) == {:allow, :owner_override}
      assert allowed?(record, before_expiry(record))
      assert gate(:decision, [record, expires]) == {:deny, :expired}
    end

    test "a caution record without an override denies as not clear" do
      record = committed_record()

      assert record["overall"] == "caution"
      assert gate(:decision, [record, before_expiry(record)]) == {:deny, :not_clear}
    end

    test "an incomplete owner_override is invalid and denies" do
      base = committed_record()

      cases = [
        {:rationale, %{owner_override() | "rationale" => ""}},
        {:by, %{owner_override() | "by" => "  "}},
        {:date, %{owner_override() | "date" => "November 20, 2026"}},
        {:keys, Map.delete(owner_override(), "rationale")},
        {:not_a_map, "owner"}
      ]

      for {field, override} <- cases do
        record = Map.put(base, "owner_override", override)

        assert {:invalid_override, field} in issues(record)
        assert gate(:decision, [record, before_expiry(record)]) == {:deny, :invalid_record}
      end
    end
  end

  describe "fail closed on an unreadable or malformed record" do
    @describetag :tmp_dir

    test "a missing, empty, null, array or malformed file denies", %{tmp_dir: tmp_dir} do
      today = ~D[2026-11-14]
      missing = Path.join(tmp_dir, "missing.json")

      assert gate(:load, [missing]) == {:error, {:missing, missing}}
      assert gate(:decision, [gate(:load, [missing]), today]) == {:deny, :no_record}
      refute allowed?(gate(:load, [missing]), today)

      for {name, body} <- [{"empty.json", ""}, {"malformed.json", ~s({"schema": )}] do
        result = gate(:load, [write!(tmp_dir, name, body)])

        assert {:error, {:malformed_json, _message}} = result
        assert gate(:decision, [result, today]) == {:deny, :invalid_record}
        refute allowed?(result, today)
      end

      for {name, body} <- [{"null.json", "null"}, {"array.json", "[]"}, {"string.json", ~s("x")}] do
        result = gate(:load, [write!(tmp_dir, name, body)])

        assert result == {:error, {:invalid_record, [:not_a_map]}}
        assert gate(:decision, [result, today]) == {:deny, :invalid_record}
        refute allowed?(result, today)
      end
    end

    test "a wrong schema, an empty sources list and any missing key deny", %{tmp_dir: tmp_dir} do
      record = clear_record()
      today = before_expiry(record)

      wrong_schema = Map.put(record, "schema", "mailglass.trademark-search/2")
      assert :schema_mismatch in issues(wrong_schema)
      assert gate(:decision, [wrong_schema, today]) == {:deny, :invalid_record}

      no_sources = Map.put(record, "sources", [])
      assert :sources_empty in issues(no_sources)
      assert gate(:decision, [no_sources, today]) == {:deny, :invalid_record}

      for key <- Map.keys(record) do
        planted = Map.delete(record, key)
        path = write!(tmp_dir, "missing-#{key}.json", Jason.encode!(planted))

        assert {:missing_key, key} in issues(planted)
        assert {:error, {:invalid_record, _issues}} = gate(:load, [path])
        assert gate(:decision, [gate(:load, [path]), today]) == {:deny, :invalid_record}
      end

      extra = Map.put(record, "open", true)
      assert {:unknown_key, "open"} in issues(extra)
      assert gate(:decision, [extra, today]) == {:deny, :invalid_record}
    end

    test "dates are parsed as ISO dates, never compared as strings" do
      record = clear_record()
      today = before_expiry(record)

      for bad <- ["November 13, 2026", "2026-13-01", "20261113", "2026-11-13T00:00:00Z", 20_261_113] do
        for field <- ["date", "expires"] do
          planted = Map.put(record, field, bad)

          assert {:invalid_date, field} in issues(planted)
          assert gate(:decision, [planted, today]) == {:deny, :invalid_record}
        end
      end

      source_date = update_in(record["sources"], &[%{hd(&1) | "retrieved" => "yesterday"} | tl(&1)])
      assert {:invalid_source, hd(record["sources"])["id"], :retrieved} in issues(source_date)

      backwards = Map.put(record, "expires", record["date"])
      assert issues(backwards) == [:expires_not_after_date]
    end

    test "source entries are checked key by key" do
      record = clear_record()

      cases = [
        {fn s -> Map.delete(s, "note") end, {:source_missing_key, "hex", "note"}},
        {fn s -> Map.put(s, "extra", 1) end, {:source_unknown_key, "hex", "extra"}},
        {fn s -> %{s | "url" => "http://hex.pm/api"} end, {:invalid_source, "hex", :url}},
        {fn s -> %{s | "url" => "https://"} end, {:invalid_source, "hex", :url}},
        {fn s -> %{s | "outcome" => "ok"} end, {:invalid_source, "hex", :outcome}},
        {fn s -> %{s | "tier" => "tertiary"} end, {:invalid_source, "hex", :tier}},
        {fn s -> %{s | "note" => ""} end, {:invalid_source, "hex", :note}}
      ]

      for {mutate, issue} <- cases do
        planted = update_in(record["sources"], &replace_source(&1, "hex", mutate))

        assert issue in issues(planted)
        assert gate(:decision, [planted, before_expiry(planted)]) == {:deny, :invalid_record}
      end

      duplicate =
        update_in(record["sources"], fn sources ->
          sources ++ [Enum.find(sources, &(&1["id"] == "hex"))]
        end)

      assert {:duplicate_source, "hex"} in issues(duplicate)

      assert {:invalid_source, "#0", :not_a_map} in issues(Map.put(record, "sources", ["hex"]))
      assert {:invalid_field, "classes"} in issues(Map.put(record, "classes", [9, 42]))
      assert {:invalid_field, "variants"} in issues(Map.put(record, "variants", []))
      assert {:invalid_field, "overall"} in issues(Map.put(record, "overall", "open"))

      assert {:invalid_field, "register_checked"} in issues(
               Map.put(record, "register_checked", "yes")
             )
    end
  end

  describe "purity" do
    @describetag :tmp_dir

    test "load and decision return identical results on a second call and write nothing", %{
      tmp_dir: tmp_dir
    } do
      record = clear_record()
      path = write!(tmp_dir, "record.json", Jason.encode!(record))
      before = {File.ls!(tmp_dir), File.read!(path), File.stat!(path).mtime}
      today = before_expiry(record)

      assert gate(:load, [path]) == gate(:load, [path])
      assert gate(:validate, [record]) == gate(:validate, [record])
      assert gate(:decision, [record, today]) == gate(:decision, [record, today])
      assert gate(:decision, [gate(:load, [path]), today]) == {:allow, :clear}
      assert allowed?(record, today) == allowed?(record, today)

      denied = Map.put(record, "register_checked", false)
      assert gate(:decision, [denied, today]) == gate(:decision, [denied, today])

      assert {File.ls!(tmp_dir), File.read!(path), File.stat!(path).mtime} == before
    end

    test "the command line judges an injected date and exits 0 only when allowed", %{
      tmp_dir: tmp_dir
    } do
      record = clear_record()
      path = write!(tmp_dir, "record.json", Jason.encode!(record))

      assert {0, allow} = gate(:cli, [["check", "--today", "2026-11-14", "--path", path]])
      assert allow =~ "allow (clear)"

      assert {1, expired} = gate(:cli, [["check", "--today", record["expires"], "--path", path]])
      assert expired =~ "deny (expired)"

      assert {1, missing} =
               gate(:cli, [["check", "--today", "2026-11-14", "--path", Path.join(tmp_dir, "x")]])

      assert missing =~ "deny (no_record)"

      assert {2, usage} = gate(:cli, [["check", "--today", "soon", "--path", path]])
      assert usage =~ "invalid --today"
      assert {2, _usage} = gate(:cli, [["unknown"]])
    end
  end

  describe "override control" do
    test "an override the test does not acknowledge is rejected" do
      planted = Map.put(committed_record(), "owner_override", owner_override())

      assert {:error, message} = override_control(planted, @acknowledged_override)
      assert message =~ "@acknowledged_override"
      assert message =~ "authored by the owner"
      assert message =~ "Agents never write it"

      # The gate itself still honours a valid override: the control is the acknowledgement.
      assert gate(:decision, [planted, before_expiry(planted)]) == {:allow, :owner_override}
    end

    test "an owner-named override is accepted only when mirrored exactly" do
      planted = Map.put(committed_record(), "owner_override", owner_override())

      assert override_control(planted, owner_override()) == :ok

      assert {:error, _message} =
               override_control(planted, %{owner_override() | "date" => "2026-11-21"})

      assert override_control(Map.put(committed_record(), "owner_override", nil), nil) == :ok
    end

    test "an agent-named override is rejected even when acknowledged" do
      for by <- [
            "automated agent (Claude Code)",
            "Claude",
            "a code AGENT",
            "Automated",
            committed_record()["searcher"]
          ] do
        planted = Map.put(committed_record(), "owner_override", %{owner_override() | "by" => by})
        override = planted["owner_override"]

        assert agent_override?(planted, override)
        assert {:error, message} = override_control(planted, override)
        assert message =~ "names the record's searcher or an automated agent"
      end

      refute agent_override?(committed_record(), owner_override())
      refute agent_override?(committed_record(), nil)
    end
  end

  describe "trademark-symbol scan has teeth" do
    @describetag :tmp_dir

    test "names the file and line of a symbol and passes clean prose", %{tmp_dir: tmp_dir} do
      File.mkdir_p!(Path.join(tmp_dir, "docs/sub"))
      File.mkdir_p!(Path.join(tmp_dir, "brandbook"))
      File.write!(Path.join(tmp_dir, "README.md"), "mailglass is plain text.\n")
      File.write!(Path.join(tmp_dir, "docs/sub/a.md"), "line one\nmailglass™ line two\n")
      File.write!(Path.join(tmp_dir, "brandbook/b.md"), "Mailglass®\n")
      File.write!(Path.join(tmp_dir, "docs/notes.txt"), "mailglass™ outside the scanned set\n")

      assert Enum.sort(symbol_hits(tmp_dir)) == ["brandbook/b.md:1", "docs/sub/a.md:2"]

      File.write!(Path.join(tmp_dir, "docs/sub/a.md"), "clean\n")
      File.write!(Path.join(tmp_dir, "brandbook/b.md"), "clean\n")
      assert symbol_hits(tmp_dir) == []
    end
  end

  # --- helpers -------------------------------------------------------------------------

  defp gate(function, args), do: apply(Mailglass.BrandTrademarkGate, function, args)

  # The gate module is loaded in setup_all, so calls go through apply/3 rather than a
  # compile-time remote call (which would warn under --warnings-as-errors).
  defp allowed?(record, today), do: gate(:announcement_allowed?, [record, today])

  defp committed_record, do: @record_path |> File.read!() |> Jason.decode!()

  # The committed record with every register searched and no source left unchecked: the
  # state an owner pass would record. Built from the committed record so it tracks its shape.
  defp clear_record do
    committed_record()
    |> Map.merge(%{"overall" => "clear", "register_checked" => true})
    |> set_outcome(["uspto", "tmview", "wipo", "image_search"], "clear")
  end

  defp owner_override do
    %{
      "by" => "szTheory",
      "date" => "2026-11-20",
      "rationale" => "Planted by the test to exercise the owner-override branch."
    }
  end

  defp before_expiry(record), do: record["expires"] |> Date.from_iso8601!() |> Date.add(-1)

  defp issues(record) do
    assert {:error, issues} = gate(:validate, [record])
    issues
  end

  defp set_outcome(record, ids, outcome) do
    update_in(record["sources"], fn sources ->
      Enum.map(sources, fn source ->
        if source["id"] in ids, do: %{source | "outcome" => outcome}, else: source
      end)
    end)
  end

  defp drop_source(record, id) do
    update_in(record["sources"], fn sources -> Enum.reject(sources, &(&1["id"] == id)) end)
  end

  defp replace_source(sources, id, mutate) do
    Enum.map(sources, fn source -> if source["id"] == id, do: mutate.(source), else: source end)
  end

  defp write!(dir, name, body) do
    path = Path.join(dir, name)
    File.write!(path, body)
    path
  end

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

  describe "CLI entrypoint under MIX_ENV=test (CR-01)" do
    @tag timeout: 300_000
    test "denies and exits 1 instead of printing nothing and exiting 0" do
      {output, status} =
        System.cmd("mix", ["run", "--no-start", @script, "check"],
          env: [{"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert output =~ "deny"
      assert status == 1
    end
  end
end
