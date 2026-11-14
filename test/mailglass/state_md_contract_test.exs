defmodule Mailglass.StateMdContractTest do
  use ExUnit.Case, async: true

  # Offline pin for DOCS-01. Two halves, both offline (no network call, no `gh`
  # shell-out -- live checking against GitHub is
  # `scripts/check_state_md_pr_refs.sh`'s job, not CI's):
  #
  #   1. PROHIBITIONS stay on `.planning/STATE.md`: it must never re-assert a
  #      hardcoded open-PR/open-issue snapshot, an `<N> open PR/issue` count
  #      shape, or #222 as open. These guard content the GSD state tool writes.
  #
  #   2. PERMANENT FACTS moved to the DOCS-01 entry of
  #      `.planning/milestones/v2.8-REQUIREMENTS.md`. STATE.md is written by the
  #      GSD state tool and CLAUDE.md forbids hand edits, so the committed v2.10
  #      format dropped the facts (`gh issue list`, `f733fc22`) and asserting
  #      them there could only go red. The DOCS-01 entry is the requirement of
  #      record that declared them permanent, and archived milestone files are
  #      not rewritten by the tool. The assertions are scoped to that entry
  #      (from `**DOCS-01**` to `**DOCS-02**`), and a missing entry raises
  #      rather than passing vacuously.

  @state_md_path Path.join(File.cwd!(), ".planning/STATE.md")
  @durable_record_path Path.join(File.cwd!(), ".planning/milestones/v2.8-REQUIREMENTS.md")

  setup do
    state_md = File.read!(@state_md_path)
    # Markdown line-wraps sentences (including inside blockquotes), so a
    # sentence-level proximity check needs the unwrapped text -- fold all
    # whitespace runs (including embedded newlines) to a single space.
    {:ok, state_md: state_md, flat: String.replace(state_md, ~r/\s+/, " ")}
  end

  describe ".planning/STATE.md contract" do
    test "does not contain the stale '14 open PR' snapshot", %{state_md: state_md} do
      refute state_md =~ "14 open PR"
    end

    test "does not describe #222 as open, and does not claim the InboundLiveTest reds are undiagnosed",
         %{state_md: state_md, flat: flat} do
      refute state_md =~ "are undiagnosed"

      # A window around #222 that mentions "open" without also mentioning
      # "closed"/"merged" is a genuine false claim; a window mentioning both
      # (in either order) is a self-correcting sentence, not a defect.
      window = window_around(flat, "#222", 80)
      mentions_open? = window =~ ~r/\bopen\b/i
      mentions_resolved? = window =~ ~r/\b(closed|merged)\b/i
      refute mentions_open? and not mentions_resolved?
    end

    test "carries no hardcoded open-count sentence of the shape '<N> open PR/pull request/issue' anywhere",
         %{state_md: state_md} do
      # This is the durable pin: it forbids the *shape* of the defect (any
      # numeral directly modifying "open PR"/"open pull request"/"open
      # issue"), not just today's literal "14 open PR" instance -- a rewrite
      # to "9 open PRs" must also fail this test.
      refute Regex.match?(~r/\b\d+\s+open\s+(PR|pull request|issue)/i, state_md)
    end
  end

  describe "permanent facts live in the v2.8 DOCS-01 record" do
    test "the real DOCS-01 entry carries every permanent fact and live-state pointer" do
      assert durable_fact_violations(docs01_section(File.read!(@durable_record_path))) == []
    end

    for fact <- ["f733fc22", "d65a1aa8", "gh pr list", "gh issue list"] do
      test "teeth: removing #{fact} from the DOCS-01 entry is named as a violation" do
        section = docs01_section(File.read!(@durable_record_path))
        mutated = String.replace(section, unquote(fact), "")

        refute mutated == section
        assert unquote(fact) in durable_fact_violations(mutated)
      end
    end

    for {fact, label} <- [{"#222", "#222 closed"}, {"#129", "#129 closed"}] do
      test "teeth: reopening #{fact} in the DOCS-01 entry is named as a violation" do
        section = docs01_section(File.read!(@durable_record_path))
        mutated = String.replace(section, "closed", "open")

        refute mutated == section
        assert unquote(label) in durable_fact_violations(mutated)
      end
    end

    test "a record with no DOCS-01 entry raises a named error instead of passing vacuously" do
      error =
        assert_raise ArgumentError, fn ->
          docs01_section("# v2.8 requirements\n\n- [x] **DOCS-02**: unrelated\n")
        end

      assert error.message =~ "DOCS-01"
    end

    test "a record whose DOCS-01 entry has no closing DOCS-02 marker raises a named error" do
      error =
        assert_raise ArgumentError, fn ->
          docs01_section("- [x] **DOCS-01**: STATE.md contains no claim contradicted by HEAD.\n")
        end

      assert error.message =~ "DOCS-02"
    end
  end

  # The DOCS-01 entry of the v2.8 requirements record: the text from the
  # `**DOCS-01**` marker up to the `**DOCS-02**` marker, whitespace folded.
  # Raises (rather than returning "") when either marker is missing, so a
  # moved or renamed entry fails loudly instead of passing vacuously.
  defp docs01_section(record) do
    flat = String.replace(record, ~r/\s+/, " ")

    start =
      case :binary.match(flat, "**DOCS-01**") do
        {pos, _len} ->
          pos

        :nomatch ->
          raise ArgumentError,
                "the v2.8 requirements record has no **DOCS-01** entry (#{@durable_record_path})"
      end

    rest = binary_part(flat, start, byte_size(flat) - start)

    case :binary.match(rest, "**DOCS-02**") do
      {stop, _len} ->
        binary_part(rest, 0, stop)

      :nomatch ->
        raise ArgumentError,
              "the v2.8 DOCS-01 entry has no closing **DOCS-02** marker (#{@durable_record_path})"
    end
  end

  # Names every permanent fact or live-state pointer the DOCS-01 section lacks.
  defp durable_fact_violations(section) do
    literals = ["f733fc22", "d65a1aa8", "gh pr list", "gh issue list"]

    missing_literals = Enum.reject(literals, &String.contains?(section, &1))

    missing_closures =
      for {needle, name} <- [{"#222", "#222 closed"}, {"#129", "#129 closed"}],
          not (window_around(section, needle, 80) =~ ~r/\bclosed\b/i),
          do: name

    missing_literals ++ missing_closures
  end

  defp window_around(text, needle, radius) do
    case :binary.match(text, needle) do
      {start, len} ->
        window_start = max(start - radius, 0)
        window_end = min(start + len + radius, byte_size(text))
        binary_part(text, window_start, window_end - window_start)

      :nomatch ->
        ""
    end
  end
end
