defmodule MailglassAdmin.TestSupport.ReviewGate do
  @moduledoc """
  The pure rejection gate for the after-catalog review (Phase 182 D-21, BRADM-07).

  Independent reviewers (fresh agents, never the author) judge each screenshot against
  `phase182-rubric.md` and write one JSON verdict each. LLM judges can invent evidence,
  favour the first image they see and reject for taste, so nothing they say is trusted until
  this module has checked it. Everything here is a pure function of its arguments: no file is
  read, no process is started, and the outcome never depends on the order of a verdict list.

  ## The verdict

  A decoded JSON map with exactly the keys `scenario_id`, `judge`, `order`, `verdict`, `rules`
  and `reasons`. `order` is `"after_first"`, `"before_first"` or `"after_only"` (the judge saw
  only the new screenshot). `verdict` is `"pass"` or `"reject"`. `rules` is a list of maps with
  exactly `id`, `ok`, `evidence_quote` and `screenshot_region`. The schema is closed: there is no
  override field, so a verdict cannot carry its own exemption.

  `validate_verdict/2` checks the schema and that every `evidence_quote` is a literal substring
  of the scenario's aria sidecar (the text the judge was given). A quote that is not there is a
  hallucinated quote. A pass must cite at least one rule and none of them failed; a reject must
  cite at least one failed rule.

  ## The gate rule (the one rule)

  `gate/1` takes `%{scenarios: [...], calibration: [...]}`. A scenario is
  `%{id, paired, aria, verdicts}` (`paired` is true when a before screenshot was shown); a
  calibration item is the same plus `kind` and `expect`.

    1. Every verdict goes through `validate_verdict/2`. A reject whose ONLY failures are
       evidence-quote substring misses is unverifiable and is DROPPED. Any other invalid verdict
       (schema, unknown key, a pass with a failed quote, a pass citing no rule, a non-reserved
       email, a verdict about another scenario, an order that contradicts whether a before
       screenshot was shown) makes the gate red.
    2. After dropping, each item needs valid verdicts from at least two distinct judges, and the
       first two (judges sorted by name) must have been shown the images in different orders
       (`after_only` items are exempt). Fewer is red: a replacement judge is spawned for a
       dropped reject.
    3. Zero valid rejects: the item passes. Exactly one valid reject: it passes only if that
       reject came from one of the first two judges and a THIRD judge passed; otherwise the
       reject stands. Two or more valid rejects: the item is rejected.
    4. Calibration: a known-bad item (`expect: "reject"`) with any valid pass is red and one whose
       judges did not all reject is red; the known-good item must pass under rule 3. The set must
       hold a `before_as_after`, an `injected_defect` and a `known_good` item.
    5. Zero scenarios is red.

  The implementer may rebut a reject only with a new deterministic test, never by argument or by
  editing a verdict: there is no bypass in this module.
  """

  alias MailglassAdmin.TestSupport.CatalogValidators, as: V

  @rule_ids ~w(R-TIME-1 R-STATUS-1 R-VOICE-1 R-WORDS-1 R-HIER-1 R-TRUTH-1)
  @verdict_keys ~w(scenario_id judge order verdict rules reasons)
  @rule_keys ~w(id ok evidence_quote screenshot_region)
  @orders ~w(after_first before_first after_only)
  @paired_orders ~w(after_first before_first)
  @verdicts ~w(pass reject)
  @kinds ~w(before_as_after injected_defect known_good)

  @doc "The rule ids a verdict may cite."
  def rule_ids, do: @rule_ids

  @doc "The calibration kinds a catalog must hold."
  def kinds, do: @kinds

  @doc "The closed key set of a verdict."
  def verdict_keys, do: @verdict_keys

  @doc """
  The A/B orders of the first two judges of a paired scenario, from the review's recorded seed.

  Deterministic (`:erlang.phash2/2` is stable across OTP versions and platforms), so a test can
  recompute it from `rng_seed` in `review-manifest.json`. The two judges always differ.
  """
  def assign_orders(rng_seed, scenario_id) when is_integer(rng_seed) and is_binary(scenario_id) do
    if :erlang.phash2({rng_seed, scenario_id}, 2) == 0,
      do: {"after_first", "before_first"},
      else: {"before_first", "after_first"}
  end

  # ---------------------------------------------------------------------------------------
  # Verdict validation
  # ---------------------------------------------------------------------------------------

  @doc """
  Every failure of one verdict against the aria sidecar text it was judged with
  (schema failures and evidence-quote substring misses together).
  """
  @spec validate_verdict(term(), String.t()) :: [String.t()]
  def validate_verdict(verdict, aria_text) do
    %{schema: schema, quotes: quotes} = verdict_failures(verdict, aria_text)
    schema ++ quotes
  end

  @doc """
  The same failures, split: `:schema` (shape, consistency, privacy) and `:quotes` (an
  `evidence_quote` that is not a substring of the aria text). The gate needs the split to drop
  an unverifiable reject but never an invalid pass.
  """
  def verdict_failures(verdict, aria_text) when is_map(verdict) and is_binary(aria_text) do
    label = "verdict #{inspect(verdict["scenario_id"])} by #{inspect(verdict["judge"])}"
    rules = verdict["rules"]
    rule_maps = if is_list(rules), do: Enum.filter(rules, &is_map/1), else: []

    schema =
      V.exact_keys(verdict, @verdict_keys, label) ++
        V.check(V.non_empty?(verdict["scenario_id"]), "#{label}: scenario_id must be a string") ++
        V.check(
          is_binary(verdict["judge"]) and Regex.match?(~r/\A[a-z0-9-]{1,32}\z/, verdict["judge"]),
          "#{label}: judge must be a short lowercase name"
        ) ++
        V.check(verdict["order"] in @orders, "#{label}: order must be one of #{inspect(@orders)}") ++
        V.check(
          verdict["verdict"] in @verdicts,
          "#{label}: verdict must be \"pass\" or \"reject\""
        ) ++
        V.check(V.non_empty?(verdict["reasons"]), "#{label}: reasons must be a non-empty string") ++
        V.check(is_list(rules), "#{label}: rules must be a list") ++
        Enum.flat_map(Enum.with_index(rule_maps), fn {rule, index} ->
          rule_schema_failures(rule, "#{label} rules[#{index}]")
        end) ++
        V.check(
          is_list(rules) and Enum.all?(rules, &is_map/1),
          "#{label}: every rule must be an object"
        ) ++
        consistency_failures(verdict["verdict"], rules, label) ++
        privacy_failures(verdict, label)

    quotes =
      for %{"evidence_quote" => quote_text} = rule <- rule_maps,
          is_binary(quote_text),
          String.trim(quote_text) != "",
          not String.contains?(aria_text, quote_text) do
        "#{label}: rule #{inspect(rule["id"])} evidence_quote #{inspect(quote_text)} is not a literal substring of the aria sidecar (hallucinated evidence)"
      end

    %{schema: schema, quotes: quotes}
  end

  def verdict_failures(_verdict, _aria_text) do
    %{schema: ["a verdict must be a JSON object and the aria text a string"], quotes: []}
  end

  defp rule_schema_failures(rule, label) do
    V.exact_keys(rule, @rule_keys, label) ++
      V.check(rule["id"] in @rule_ids, "#{label}: id must be one of #{inspect(@rule_ids)}") ++
      V.check(is_boolean(rule["ok"]), "#{label}: ok must be true or false") ++
      V.check(
        V.non_empty?(rule["evidence_quote"]),
        "#{label}: evidence_quote must be a non-empty string copied from the aria sidecar"
      ) ++
      V.check(
        V.non_empty?(rule["screenshot_region"]),
        "#{label}: screenshot_region must be a non-empty string"
      )
  end

  defp consistency_failures("pass", rules, label) when is_list(rules) do
    maps = Enum.filter(rules, &is_map/1)

    V.check(maps != [], "#{label}: a pass must cite at least one rule") ++
      V.check(
        Enum.all?(maps, &(&1["ok"] == true)),
        "#{label}: a pass must not cite a failed rule (ok false)"
      )
  end

  defp consistency_failures("reject", rules, label) when is_list(rules) do
    V.check(
      Enum.any?(rules, &(is_map(&1) and &1["ok"] == false)),
      "#{label}: a reject must cite at least one failed rule (ok false)"
    )
  end

  defp consistency_failures(_verdict, _rules, _label), do: []

  defp privacy_failures(verdict, label) do
    quotes =
      case verdict["rules"] do
        rules when is_list(rules) ->
          for %{"evidence_quote" => text} <- Enum.filter(rules, &is_map/1),
              is_binary(text),
              do: text

        _ ->
          []
      end

    texts = quotes ++ if(is_binary(verdict["reasons"]), do: [verdict["reasons"]], else: [])

    for text <- texts, email <- V.unreserved_emails(text) do
      "#{label}: names an email address outside the reserved example domains: #{email}"
    end
  end

  # ---------------------------------------------------------------------------------------
  # The gate
  # ---------------------------------------------------------------------------------------

  @doc """
  Applies the gate rule to a whole catalog. `{:pass, []}` only when every scenario passes and the
  calibration proves the reviewer can reject; otherwise `{:reject, messages}` where each message
  names the item, the judge and the rule, and starts with `[red]` (the evidence is missing or
  invalid) or `[reject]` (a valid reject stands).
  """
  @spec gate(%{scenarios: [map()], calibration: [map()]}) :: {:pass, []} | {:reject, [String.t()]}
  def gate(input) do
    case input do
      %{scenarios: scenarios, calibration: calibration}
      when is_list(scenarios) and is_list(calibration) ->
        messages =
          V.check(scenarios != [], "[red] the catalog holds zero scenarios") ++
            Enum.flat_map(scenarios, &scenario_messages/1) ++ calibration_messages(calibration)

        if messages == [], do: {:pass, []}, else: {:reject, messages}

      _other ->
        {:reject, ["[red] gate/1 needs %{scenarios: [...], calibration: [...]}"]}
    end
  end

  defp scenario_messages(item) do
    case outcome(item) do
      {:pass, _valid} -> []
      {:reject, messages} -> messages
      {:red, messages} -> messages
    end
  end

  defp calibration_messages(items) do
    kinds_present = items |> Enum.map(&Map.get(&1, :kind)) |> Enum.uniq()

    presence =
      for kind <- @kinds, kind not in kinds_present do
        "[red] calibration holds no #{kind} item: the reviewer's power to reject is unproven"
      end

    presence ++ Enum.flat_map(items, &calibration_item_messages/1)
  end

  defp calibration_item_messages(%{kind: kind, expect: expect} = item)
       when kind in @kinds and expect in ["reject", "pass"] do
    expected = if kind == "known_good", do: "pass", else: "reject"
    label = "calibration #{inspect(item.id)} (#{kind})"

    if expect != expected do
      ["[red] #{label}: a #{kind} item must expect #{inspect(expected)}, not #{inspect(expect)}"]
    else
      case {expect, outcome(item)} do
        {_, {:red, messages}} ->
          messages

        {"reject", {:pass, valid}} ->
          passers = valid |> Enum.filter(&(&1["verdict"] == "pass")) |> Enum.map(& &1["judge"])

          [
            "[red] #{label}: a known-bad passed (judge #{Enum.join(passers, ", ")}): the reviewer cannot reject a defect"
          ]

        {"reject", {:reject, _messages}} ->
          # A reject outcome can still hide a pass (one pass + one valid reject stands as a reject).
          known_bad_pass_messages(item, label)

        {"pass", {:pass, _valid}} ->
          []

        {"pass", {:reject, messages}} ->
          ["[red] #{label}: the known-good was rejected, so the reviewer rejects reflexively"] ++
            messages
      end
    end
  end

  defp calibration_item_messages(item) do
    [
      "[red] calibration #{inspect(Map.get(item, :id))}: kind must be one of #{inspect(@kinds)} and expect \"pass\" or \"reject\""
    ]
  end

  # `outcome/1` already ran; recompute the valid verdicts to see whether any judge passed the defect.
  defp known_bad_pass_messages(item, label) do
    case classify(item) do
      {:ok, valid, _dropped} ->
        case Enum.filter(valid, &(&1["verdict"] == "pass")) do
          [] ->
            []

          passers ->
            [
              "[red] #{label}: a known-bad was passed by judge #{Enum.map_join(passers, ", ", & &1["judge"])}"
            ]
        end

      {:red, _messages} ->
        []
    end
  end

  # Returns {:pass, valid_verdicts} | {:reject, messages} | {:red, messages}.
  defp outcome(%{id: id, verdicts: verdicts} = item) when is_list(verdicts) do
    case classify(item) do
      {:red, messages} ->
        {:red, messages}

      {:ok, valid, _dropped} ->
        distinct = valid |> Enum.map(& &1["judge"]) |> Enum.uniq()

        cond do
          length(distinct) != length(valid) ->
            {:red,
             [
               "[red] #{id}: a judge appears twice among the valid verdicts; each judge counts once"
             ]}

          length(valid) < 2 ->
            {:red,
             [
               "[red] #{id}: needs valid verdicts from at least two distinct judges, has #{length(valid)} " <>
                 "(an unverifiable reject is dropped: spawn a replacement judge)"
             ]}

          true ->
            sorted = Enum.sort_by(valid, & &1["judge"])
            decide(id, Map.get(item, :paired, false), sorted)
        end
    end
  end

  defp outcome(%{id: id}), do: {:red, ["[red] #{id}: the item has no verdict list"]}

  defp decide(id, paired, sorted) do
    [first, second | rest] = sorted

    order_failures =
      if paired do
        V.check(
          first["order"] in @paired_orders and second["order"] in @paired_orders and
            first["order"] != second["order"],
          "[red] #{id}: the first two judges (#{first["judge"]}, #{second["judge"]}) must have seen the images in different orders (got #{inspect(first["order"])} and #{inspect(second["order"])})"
        )
      else
        []
      end

    if order_failures != [] do
      {:red, order_failures}
    else
      rejects = Enum.filter(sorted, &(&1["verdict"] == "reject"))

      case rejects do
        [] ->
          {:pass, sorted}

        [reject] ->
          third_passed? = Enum.any?(rest, &(&1["verdict"] == "pass"))

          if reject in [first, second] and third_passed? do
            {:pass, sorted}
          else
            {:reject,
             [
               reject_message(
                 id,
                 reject,
                 "the only reject stands: no third independent judge passed it"
               )
             ]}
          end

        many ->
          {:reject,
           Enum.map(many, &reject_message(id, &1, "two or more valid rejects block the item"))}
      end
    end
  end

  defp reject_message(id, verdict, why) do
    failed =
      verdict["rules"]
      |> Enum.filter(&(&1["ok"] == false))
      |> Enum.map_join(", ", & &1["id"])

    "[reject] #{id}: judge #{verdict["judge"]} rejected on #{failed} (#{why}): #{verdict["reasons"]}"
  end

  # Splits an item's verdicts into valid ones, dropped unverifiable rejects, and red messages.
  defp classify(%{id: id, aria: aria, verdicts: verdicts} = item) do
    paired = Map.get(item, :paired, false)

    {valid, dropped, red} =
      Enum.reduce(verdicts, {[], [], []}, fn verdict, {valid, dropped, red} ->
        failures = verdict_failures(verdict, aria)
        extra = binding_failures(verdict, id, paired)

        cond do
          failures.schema != [] or extra != [] ->
            {valid, dropped, red ++ Enum.map(failures.schema ++ extra, &"[red] #{id}: #{&1}")}

          failures.quotes != [] and verdict["verdict"] == "reject" ->
            {valid, [verdict | dropped], red}

          failures.quotes != [] ->
            {valid, dropped, red ++ Enum.map(failures.quotes, &"[red] #{id}: #{&1}")}

          true ->
            {[verdict | valid], dropped, red}
        end
      end)

    if red == [], do: {:ok, valid, dropped}, else: {:red, red}
  end

  # A verdict must be about the item it is filed under, and its order must say whether a before
  # screenshot was shown.
  defp binding_failures(verdict, id, paired) when is_map(verdict) do
    V.check(
      verdict["scenario_id"] == id,
      "verdict names scenario #{inspect(verdict["scenario_id"])} but is filed under #{inspect(id)}"
    ) ++
      cond do
        paired ->
          V.check(
            verdict["order"] in @paired_orders,
            "verdict order #{inspect(verdict["order"])} contradicts a scenario shown with a before screenshot (expected after_first or before_first)"
          )

        true ->
          V.check(
            verdict["order"] == "after_only",
            "verdict order #{inspect(verdict["order"])} contradicts a scenario with no before screenshot (expected after_only)"
          )
      end
  end

  defp binding_failures(_verdict, _id, _paired), do: []
end
