defmodule MailglassAdmin.Phase182LocalizerRuntimeTest do
  @moduledoc """
  BRADM-02 required-lane runtime proof (lane `support_contract_admin`): the browser localizer
  keeps a zone on every time it rewrites.

  `phase182_time_status_contract_test.exs` scans the localizer source (`FMT` keeps
  `timeZoneName`, the locale is fixed) but never runs it, so a localizer that wrote
  `zone.textContent = ""`, or wrote the time without its zone through another branch, would
  pass that scan and show a bare time in every browser. This file executes the real served
  block, extracted from `Assets.js_body/0`, in Node under three IANA zones and reads what a
  reader would see afterwards:

    * the visible text is the localized time plus its zone (`UTC`, `EST`, `GMT+13`), exactly;
    * the zone sits in its own `[data-time-zone]` node, the layout the server renders;
    * the time keeps no `aria-label` that omits the visible text, and the copy control's
      name contains the visible text and the exact UTC value (WCAG 2.5.3 Label in Name);
    * a value that does not split is written whole and still ends in its zone;
    * an unparseable or empty `datetime` leaves the server's UTC time untouched.

  The fake DOM is built from the real `Components.timestamp/1` output, so the selectors the
  localizer queries (`[data-time-text]`, `[data-time-zone]`, `[data-timestamp-copy]`) must
  exist in the server markup or this file fails. Mutants of the served source, applied in
  memory only, prove each assertion can fail ("the harness has teeth").

  Node is the one external tool. It is preinstalled on GitHub's Ubuntu runners; where it is
  missing this module is skipped locally and fails closed when `CI` is set, so the required
  lane can never go green without having run the localizer.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias MailglassAdmin.Components
  alias MailglassAdmin.Controllers.Assets

  @at ~U[2026-11-15 14:05:09.123456Z]

  # IANA zone, the localized date-time text, and the zone token the browser must keep.
  # 14:05 UTC is 9:05 AM on 15 Nov in New York (standard time) and 3:05 AM on 16 Nov in
  # Auckland (daylight time, which en-US short names GMT+13).
  @zones [
    {"UTC", "Nov 15, 2026, 2:05 PM", "UTC"},
    {"America/New_York", "Nov 15, 2026, 9:05 AM", "EST"},
    {"Pacific/Auckland", "Nov 16, 2026, 3:05 AM", "GMT+13"}
  ]

  # One decision, made once at compile time: node present, absent locally (skip), or absent
  # in CI (fail closed). `@node_cmd` is a harmless string when node is absent because no test
  # then runs.
  @node_path System.find_executable("node")
  @node_cmd @node_path || "node"
  @node_state (cond do
                 @node_path != nil -> :present
                 System.get_env("CI") in ["true", "1"] -> :missing_in_ci
                 true -> :missing
               end)

  if @node_state == :missing do
    @moduletag skip: "node is not on PATH; this runtime proof fails closed when CI is set"
  end

  if @node_state == :missing_in_ci do
    setup_all do
      flunk(
        "node is not on PATH in CI: the localizer runtime proof cannot run, so the required " <>
          "lane would pass without exercising the browser localizer. Install Node on the runner."
      )
    end
  end

  # The harness gets the localizer source and the cases through the environment, builds fake
  # nodes that implement only what `localize/1` calls, and prints one JSON array of what a
  # reader would see afterwards. `Intl` reports the zone the process really ran in.
  @harness ~S"""
  const localize = new Function(process.env.LOCALIZER_SRC + "\nreturn localize")()
  const cases = JSON.parse(process.env.LOCALIZER_CASES)
  const out = cases.map((c) => {
    const attrs = { datetime: c.datetime }
    const text = { textContent: c.text }
    const zone = { textContent: c.zone }
    const copy = c.copy
      ? {
          attrs: { "aria-label": c.copy.label },
          dataset: { copyValue: c.copy.value },
          setAttribute(k, v) { this.attrs[k] = v }
        }
      : null
    const el = {
      dataset: {},
      textContent: c.text + c.zone,
      getAttribute: (k) => (k in attrs ? attrs[k] : null),
      removeAttribute: (k) => { delete attrs[k] },
      querySelector: (sel) => {
        if (c.twoPart && sel === "[data-time-text]") return text
        if (c.twoPart && sel === "[data-time-zone]") return zone
        return null
      },
      closest: (sel) => (sel === "[data-timestamp-copy]" ? copy : null)
    }
    localize(el)
    return {
      id: c.id,
      tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
      visible: c.twoPart ? text.textContent + zone.textContent : el.textContent,
      zoneNode: c.twoPart ? zone.textContent : null,
      ariaLabel: "aria-label" in attrs ? attrs["aria-label"] : null,
      copyLabel: copy ? copy.attrs["aria-label"] : null,
      localized: el.dataset.localized === undefined ? null : el.dataset.localized
    }
  })
  console.log(JSON.stringify(out))
  """

  setup_all do
    js = Assets.js_body()
    source = extract_localizer(js)

    {:ok, js: js, source: source, ssr: ssr_fixture()}
  end

  describe "the served localizer keeps a zone on every time it rewrites" do
    for {tz, when_text, zone} <- @zones do
      test "two-part markup under #{tz} reads #{when_text} #{zone}", ctx do
        expected = %{tz: unquote(tz), when_text: unquote(when_text), zone: unquote(zone)}
        [result] = run_localizer(ctx.source, unquote(tz), [two_part_case(ctx.ssr)])

        assert failures(result, expected, ctx.ssr, :two_part) == []
        # The zone is the zone node's own text: the line the server gives it below `sm`.
        assert result["zoneNode"] == unquote(zone)
      end

      test "a time without the two spans is written whole and still ends in #{zone} under #{tz}",
           ctx do
        expected = %{tz: unquote(tz), when_text: unquote(when_text), zone: unquote(zone)}
        [result] = run_localizer(ctx.source, unquote(tz), [whole_text_case(ctx.ssr)])

        assert failures(result, expected, ctx.ssr, :whole_text) == []
        assert result["zoneNode"] == nil
      end
    end

    test "an unparseable or empty datetime leaves the server's UTC time untouched", ctx do
      cases = [
        ctx.ssr |> two_part_case() |> Map.merge(%{id: "garbage", datetime: "not-a-time"}),
        ctx.ssr |> two_part_case() |> Map.merge(%{id: "empty", datetime: ""})
      ]

      results = run_localizer(ctx.source, "America/New_York", cases)
      assert [_, _] = results

      for result <- results do
        assert untouched_failures(result, ctx.ssr) == [],
               "#{result["id"]}: " <> inspect(untouched_failures(result, ctx.ssr))
      end
    end
  end

  describe "the harness has teeth (mutants of the served localizer, in memory only)" do
    # Each mutant is a one-line change a refactor could plausibly make. The harness must
    # report a failure for it, under a zone where the real localizer passes.
    mutants = [
      {"the zone node is emptied", ~s|zone.textContent = split[2]|, ~s|zone.textContent = ""|,
       :two_part, "zone node reads"},
      {"the FMT drops its zone name", ~s|, timeZoneName: "short"|, "", :two_part,
       "does not end in the zone EST"},
      {"the FMT drops its zone name on the whole-text branch", ~s|, timeZoneName: "short"|, "",
       :whole_text, "does not end in the zone EST"},
      {"the copy control keeps its stale UTC name", "if (copy) copy.setAttribute",
       "if (false) copy.setAttribute", :two_part, "omits the visible text"},
      {"an invalid date is written over the server time", "if (isNaN(d.getTime())) return", "",
       :untouched, "the server time"}
    ]

    for {name, from, to, kind, reason} <- mutants do
      test "#{name} is caught", ctx do
        assert_mutant_caught(ctx, unquote(from), unquote(to), unquote(kind), unquote(reason))
      end
    end

    test "the unmutated source passes the same checks in the same zone", ctx do
      {tz, when_text, zone} = Enum.find(@zones, &(elem(&1, 0) == "America/New_York"))
      expected = %{tz: tz, when_text: when_text, zone: zone}

      for kind <- [:two_part, :whole_text] do
        [result] = run_localizer(ctx.source, tz, [case_for(ctx.ssr, kind)])
        assert failures(result, expected, ctx.ssr, kind) == []
      end
    end
  end

  describe "extraction and fixture" do
    test "the server markup carries every selector the localizer queries", ctx do
      assert ctx.ssr.datetime == DateTime.to_iso8601(@at)
      assert ctx.ssr.text == "Nov 15, 2026, 2:05 PM "
      assert ctx.ssr.zone == "UTC"
      assert ctx.ssr.copy_value == Components.timestamp_value(@at)
      assert ctx.ssr.copy_label =~ "Nov 15, 2026, 2:05 PM UTC"
      assert ctx.ssr.copy_label =~ ctx.ssr.copy_value
    end

    test "the extracted block is exactly FMT plus the one localize function", ctx do
      assert ctx.source =~ "const FMT = {"
      assert ctx.source =~ "timeZoneName"
      assert ctx.source =~ "function localize(el) {"
      assert ctx.source =~ ~s|toLocaleString("en-US", FMT)|
      assert length(:binary.matches(ctx.js, "function localize(el) {")) == 1
      assert byte_size(ctx.source) < 4_000, "the extraction swallowed more than the function"
    end
  end

  # -- cases ---------------------------------------------------------------------------

  # The mutated source must fail the same checks the real source passes, in New York.
  defp assert_mutant_caught(ctx, from, to, kind, reason) do
    mutated = String.replace(ctx.source, from, to)

    # Non-vacuity: the mutation really changed the source under test.
    refute mutated == ctx.source, "mutation target #{inspect(from)} not found"

    {tz, when_text, zone} = Enum.find(@zones, &(elem(&1, 0) == "America/New_York"))
    expected = %{tz: tz, when_text: when_text, zone: zone}

    case kind do
      :untouched ->
        bad = ctx.ssr |> two_part_case() |> Map.merge(%{id: "garbage", datetime: "not-a-time"})
        [result] = run_localizer(mutated, tz, [bad])
        assert_caught_for(untouched_failures(result, ctx.ssr), reason)

      kind ->
        [result] = run_localizer(mutated, tz, [case_for(ctx.ssr, kind)])
        assert_caught_for(failures(result, expected, ctx.ssr, kind), reason)
    end
  end

  # Caught for the stated reason, not by an incidental failure such as a zone that did not
  # take effect, which would make the teeth check vacuous.
  defp assert_caught_for(messages, reason) do
    assert Enum.any?(messages, &String.contains?(&1, reason)),
           "no failure mentions #{inspect(reason)}; got #{inspect(messages)}"
  end

  defp case_for(ssr, :two_part), do: two_part_case(ssr)
  defp case_for(ssr, :whole_text), do: whole_text_case(ssr)

  # The fake time element starts as the server renders it: UTC text, UTC zone, the copy
  # control named for the UTC value.
  defp two_part_case(ssr) do
    %{
      id: "two-part",
      twoPart: true,
      datetime: ssr.datetime,
      text: ssr.text,
      zone: ssr.zone,
      copy: %{label: ssr.copy_label, value: ssr.copy_value}
    }
  end

  # The same element with the spans absent, so `localize/1` takes its write-whole branch.
  defp whole_text_case(ssr), do: %{two_part_case(ssr) | id: "whole-text", twoPart: false}

  # -- checks --------------------------------------------------------------------------

  defp failures(result, expected, ssr, kind) do
    visible = normalize(result["visible"])
    want = expected.when_text <> " " <> expected.zone
    copy_label = normalize(result["copyLabel"] || "")

    checks = [
      {result["tz"] == expected.tz,
       "ran under #{inspect(result["tz"])}, not #{expected.tz}: the zone did not take effect"},
      {visible == want, "reads #{inspect(visible)}, not #{inspect(want)}"},
      {String.ends_with?(visible, " " <> expected.zone),
       "#{inspect(visible)} does not end in the zone #{expected.zone}"},
      {result["localized"] == "1", "was not marked localized"},
      {result["ariaLabel"] == nil,
       "kept an aria-label that does not contain the visible text: #{inspect(result["ariaLabel"])}"},
      {String.contains?(copy_label, want),
       "copy control name #{inspect(copy_label)} omits the visible text #{inspect(want)}"},
      {String.contains?(copy_label, ssr.copy_value),
       "copy control name #{inspect(copy_label)} omits the exact UTC value"},
      {kind != :two_part or result["zoneNode"] == expected.zone,
       "zone node reads #{inspect(result["zoneNode"])}, not #{expected.zone}"}
    ]

    for {false, message} <- checks, do: message
  end

  defp untouched_failures(result, ssr) do
    original = ssr.text <> ssr.zone

    checks = [
      {normalize(result["visible"]) == normalize(original),
       "the server time #{inspect(original)} became #{inspect(result["visible"])}"},
      {String.ends_with?(normalize(result["visible"]), " UTC"), "the server time lost its zone"},
      {result["localized"] == nil, "was marked localized"},
      {result["copyLabel"] == ssr.copy_label, "the copy control name changed"}
    ]

    for {false, message} <- checks, do: message
  end

  # Some ICU builds put a narrow no-break space before AM/PM. It is formatting whitespace,
  # not part of what is asserted, so every comparison reads one ordinary space.
  defp normalize(text), do: Regex.replace(~r/[\s\x{00A0}\x{202F}]+/u, text, " ") |> String.trim()

  # -- running the served block ----------------------------------------------------------

  defp run_localizer(source, tz, cases) do
    {output, status} =
      System.cmd(@node_cmd, ["-e", @harness],
        env: [
          {"TZ", tz},
          {"LOCALIZER_SRC", source},
          {"LOCALIZER_CASES", Jason.encode!(cases)}
        ],
        stderr_to_stdout: true
      )

    assert status == 0, "node exited #{status}: #{output}"

    output
    |> String.split("\n", trim: true)
    |> List.last()
    |> Jason.decode!()
  end

  # `FMT` plus the `localize` function, copied out of the one JS string the admin serves.
  defp extract_localizer(js) do
    fmt =
      case Regex.run(~r/const FMT = \{[^}]*\}/, js) do
        [block] -> block
        _ -> flunk("no `const FMT = {...}` in Assets.js_body/0")
      end

    marker = "function localize(el) {"

    start =
      case :binary.matches(js, marker) do
        [{at, _}] -> at
        other -> flunk("expected one #{marker} in Assets.js_body/0, found #{length(other)}")
      end

    rest = binary_part(js, start, byte_size(js) - start)
    {open, _} = :binary.match(rest, "{")
    body_end = block_end(rest, open + 1, 1)

    fmt <> "\n" <> binary_part(rest, 0, body_end)
  end

  # Index just past the brace that closes the block opened before `index`. The function holds
  # no brace inside a string except the balanced `${...}` of its template literals.
  defp block_end(bin, index, depth) when index < byte_size(bin) do
    case :binary.at(bin, index) do
      ?{ -> block_end(bin, index + 1, depth + 1)
      ?} when depth == 1 -> index + 1
      ?} -> block_end(bin, index + 1, depth - 1)
      _ -> block_end(bin, index + 1, depth)
    end
  end

  defp block_end(_bin, _index, _depth), do: flunk("unbalanced braces in the localize function")

  # The server's own timestamp, parsed back into the three things the localizer reads.
  defp ssr_fixture do
    html = render_component(&Components.timestamp/1, at: @at, copyable: true)
    doc = Floki.parse_document!(html)

    one = fn selector ->
      case Floki.find(doc, selector) do
        [node] -> node
        other -> flunk("expected one #{selector} in timestamp/1, found #{length(other)}")
      end
    end

    time = one.("time[data-local-time]")
    button = one.("button[data-timestamp-copy]")
    text = one.("time [data-time-text]")
    zone = one.("time [data-time-zone]")

    %{
      datetime: time |> Floki.attribute("datetime") |> hd(),
      text: Floki.text(text, deep: true),
      zone: zone |> Floki.text() |> String.trim(),
      copy_label: button |> Floki.attribute("aria-label") |> hd(),
      copy_value: button |> Floki.attribute("data-copy-value") |> hd()
    }
  end
end
