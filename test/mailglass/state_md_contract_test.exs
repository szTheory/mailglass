defmodule Mailglass.StateMdContractTest do
  use ExUnit.Case, async: true

  # Offline pin for DOCS-01: `.planning/STATE.md` must never re-assert a
  # hardcoded open-PR/open-issue snapshot, and the permanent facts it does
  # carry must stay present. This test makes no network call and does not
  # shell out to `gh` -- live checking against GitHub is
  # `scripts/check_state_md_pr_refs.sh`'s job, not CI's.

  @state_md_path Path.join(File.cwd!(), ".planning/STATE.md")

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

    test "positively points at live gh state for anything currently open", %{state_md: state_md} do
      assert state_md =~ "gh pr list"
      assert state_md =~ "gh issue list"
    end

    test "carries no hardcoded open-count sentence of the shape '<N> open PR/pull request/issue' anywhere",
         %{state_md: state_md} do
      # This is the durable pin: it forbids the *shape* of the defect (any
      # numeral directly modifying "open PR"/"open pull request"/"open
      # issue"), not just today's literal "14 open PR" instance -- a rewrite
      # to "9 open PRs" must also fail this test.
      refute Regex.match?(~r/\b\d+\s+open\s+(PR|pull request|issue)/i, state_md)
    end

    test "the permanent, closed-forever facts are positively present", %{flat: flat} do
      assert flat =~ "f733fc22"
      assert flat =~ "d65a1aa8"
      assert window_around(flat, "#222", 80) =~ ~r/\bclosed\b/i
      assert window_around(flat, "#129", 80) =~ ~r/\bclosed\b/i
    end
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
