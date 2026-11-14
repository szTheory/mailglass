defmodule Mailglass.BrandTrademarkGate do
  @moduledoc false

  # Fail-closed gate for the trademark and name search record (BRPOL-05, D-20..D-23).
  #
  # `.planning/research/brand-v2-adoption/trademark-search.json` records what was
  # searched for the name and mark and what was found. The announcement and any
  # trademark-symbol text are irreversible, so they wait on this record: the gate answers
  # "may we announce?" and defaults to no.
  #
  # Decision logic is pure. `validate/1`, `decision/2` and `announcement_allowed?/2` take
  # the date as an argument and never read the clock, which is what lets the always-run
  # test suite exercise them without a time bomb at the record's expiry. The only clock
  # read in this module is the private `today/0`, used by the one-line
  # `announcement_allowed?/1` wrapper (the entry point the announcement phase calls) and
  # by the command line when `--today` is absent.
  #
  # Invoke the command line as
  #
  #     mix run --no-start scripts/brand_trademark_gate.exs check [--today YYYY-MM-DD] [--path FILE]
  #
  # so Jason is loaded. Exit 0 means an announcement is allowed, 1 means denied.

  @repo_root Path.expand("..", __DIR__)

  @schema "mailglass.trademark-search/1"
  @default_path ".planning/research/brand-v2-adoption/trademark-search.json"

  @record_keys ~w(schema date searcher mark variants classes overall register_checked
                  owner_override expires sources)
  @source_keys ~w(id url outcome tier retrieved note)
  @override_keys ~w(by date rationale)

  @required_source_ids ["uspto", "tmview", "wipo"]
  @classes [9, 38, 42]
  @outcomes ["clear", "caution", "blocked", "not_checked"]
  @overall_values ["clear", "caution", "blocked"]
  @tiers ["primary", "secondary"]

  @iso_date ~r/\A\d{4}-\d{2}-\d{2}\z/

  @help """
  brand_trademark_gate.exs - fail-closed trademark announcement gate

  Usage: mix run --no-start scripts/brand_trademark_gate.exs check [options]

    check
      Loads the trademark search record and prints the gate decision. Exit 0 when an
      announcement is allowed, 1 when it is denied (including a missing, invalid or
      expired record), 2 on a usage error.

  Options:
    --today YYYY-MM-DD   evaluate as of this date instead of today
    --path FILE          read this record instead of #{@default_path}
  """

  @doc false
  def schema, do: @schema

  @doc false
  def required_source_ids, do: @required_source_ids

  # --- loading -------------------------------------------------------------------------

  @doc """
  Reads and validates the record at `path`.

  Returns `{:ok, record}` or `{:error, reason}` where reason is `{:missing, path}` (the
  file cannot be read), `{:malformed_json, message}` (empty or unparseable) or
  `{:invalid_record, issues}` (parsed but failing `validate/1`, including a JSON null).
  A relative `path` is resolved against the repository root.
  """
  def load(path \\ @default_path) do
    with {:ok, contents} <- read(path),
         {:ok, term} <- decode(contents),
         {:ok, record} <- validate_loaded(term) do
      {:ok, record}
    end
  end

  defp read(path) do
    case File.read(Path.expand(path, @repo_root)) do
      {:ok, contents} -> {:ok, contents}
      {:error, _reason} -> {:error, {:missing, path}}
    end
  end

  defp decode(contents) do
    case Jason.decode(contents) do
      {:ok, term} ->
        {:ok, term}

      {:error, %Jason.DecodeError{} = error} ->
        {:error, {:malformed_json, Exception.message(error)}}
    end
  end

  defp validate_loaded(term) do
    case validate(term) do
      {:ok, record} -> {:ok, record}
      {:error, issues} -> {:error, {:invalid_record, issues}}
    end
  end

  # --- validation ----------------------------------------------------------------------

  @doc """
  Checks the shape and the evidence invariants of a decoded record.

  Returns `{:ok, record}` or `{:error, issues}`. Each issue is an atom or a
  `{tag, detail}` tuple so callers can match the specific cause. Shape issues are
  reported first; the evidence invariants are checked only on a well-shaped record:

    * `:register_claim_without_evidence` - `register_checked` is true while a required
      register (USPTO, TMview or WIPO) is still `not_checked`
    * `:clear_without_evidence` - `overall` is `clear` without `register_checked` or with
      a `not_checked` or `blocked` source
    * `:blocked_source_not_reflected` - a source is `blocked` while `overall` is not
  """
  def validate(record) when is_map(record) do
    case shape_issues(record) do
      [] ->
        case invariant_issues(record) do
          [] -> {:ok, record}
          issues -> {:error, issues}
        end

      issues ->
        {:error, issues}
    end
  end

  def validate(_other), do: {:error, [:not_a_map]}

  defp shape_issues(record) do
    keys = Map.keys(record)

    key_issues =
      Enum.map(@record_keys -- keys, &{:missing_key, &1}) ++
        Enum.map(keys -- @record_keys, &{:unknown_key, &1})

    key_issues ++
      schema_issues(record) ++
      date_issues(record) ++
      text_issues(record) ++
      list_issues(record) ++
      closed_set_issues(record) ++
      override_issues(Map.get(record, "owner_override")) ++
      sources_issues(Map.get(record, "sources"))
  end

  defp schema_issues(record) do
    if Map.get(record, "schema") == @schema, do: [], else: [:schema_mismatch]
  end

  defp date_issues(record) do
    date = parse_date(Map.get(record, "date"))
    expires = parse_date(Map.get(record, "expires"))

    date_issue(date, {:invalid_date, "date"}) ++
      date_issue(expires, {:invalid_date, "expires"}) ++
      expiry_order_issue(date, expires)
  end

  defp date_issue({:ok, _date}, _tag), do: []
  defp date_issue(:error, tag), do: [tag]

  defp expiry_order_issue({:ok, date}, {:ok, expires}) do
    if Date.compare(expires, date) == :gt, do: [], else: [:expires_not_after_date]
  end

  defp expiry_order_issue(_date, _expires), do: []

  defp text_issues(record) do
    for field <- ["searcher", "mark"],
        not text?(Map.get(record, field)),
        do: {:invalid_field, field}
  end

  defp list_issues(record) do
    variants = Map.get(record, "variants")

    variants_issue =
      if is_list(variants) and variants != [] and Enum.all?(variants, &text?/1),
        do: [],
        else: [{:invalid_field, "variants"}]

    classes_issue =
      if Map.get(record, "classes") == @classes, do: [], else: [{:invalid_field, "classes"}]

    variants_issue ++ classes_issue
  end

  defp closed_set_issues(record) do
    overall_issue =
      if Map.get(record, "overall") in @overall_values, do: [], else: [{:invalid_field, "overall"}]

    register_issue =
      if is_boolean(Map.get(record, "register_checked")),
        do: [],
        else: [{:invalid_field, "register_checked"}]

    overall_issue ++ register_issue
  end

  defp override_issues(nil), do: []

  defp override_issues(override) when is_map(override) do
    keys = Map.keys(override)

    key_issues =
      if Enum.sort(keys) == Enum.sort(@override_keys), do: [], else: [{:invalid_override, :keys}]

    text_issues =
      for field <- ["by", "rationale"], not text?(Map.get(override, field)) do
        {:invalid_override, String.to_atom(field)}
      end

    date_issues =
      case parse_date(Map.get(override, "date")) do
        {:ok, _date} -> []
        :error -> [{:invalid_override, :date}]
      end

    key_issues ++ text_issues ++ date_issues
  end

  defp override_issues(_other), do: [{:invalid_override, :not_a_map}]

  defp sources_issues([_ | _] = sources) do
    entry_issues =
      sources
      |> Enum.with_index()
      |> Enum.flat_map(fn {source, index} -> source_issues(source, index) end)

    ids = for %{"id" => id} <- Enum.filter(sources, &is_map/1), is_binary(id), do: id

    duplicate_issues =
      for {id, count} <- Enum.frequencies(ids), count > 1, do: {:duplicate_source, id}

    missing_issues =
      for id <- @required_source_ids, id not in ids, do: {:missing_required_source, id}

    entry_issues ++ duplicate_issues ++ missing_issues
  end

  defp sources_issues(_other), do: [:sources_empty]

  defp source_issues(source, index) when is_map(source) do
    keys = Map.keys(source)
    label = source_label(source, index)

    key_issues =
      Enum.map(@source_keys -- keys, &{:source_missing_key, label, &1}) ++
        Enum.map(keys -- @source_keys, &{:source_unknown_key, label, &1})

    checks = [
      {text?(Map.get(source, "id")), :id},
      {https_url?(Map.get(source, "url")), :url},
      {Map.get(source, "outcome") in @outcomes, :outcome},
      {Map.get(source, "tier") in @tiers, :tier},
      {match?({:ok, _}, parse_date(Map.get(source, "retrieved"))), :retrieved},
      {text?(Map.get(source, "note")), :note}
    ]

    key_issues ++ for {false, field} <- checks, do: {:invalid_source, label, field}
  end

  defp source_issues(_source, index), do: [{:invalid_source, "##{index}", :not_a_map}]

  defp source_label(%{"id" => id}, _index) when is_binary(id) and id != "", do: id
  defp source_label(_source, index), do: "##{index}"

  defp invariant_issues(record) do
    sources = Map.fetch!(record, "sources")
    outcomes = Enum.map(sources, & &1["outcome"])

    required_outcomes =
      for source <- sources, source["id"] in @required_source_ids, do: source["outcome"]

    register_claim_issue =
      if record["register_checked"] and "not_checked" in required_outcomes,
        do: [:register_claim_without_evidence],
        else: []

    clear_issue =
      if record["overall"] == "clear" and
           (not record["register_checked"] or "not_checked" in outcomes or "blocked" in outcomes),
         do: [:clear_without_evidence],
         else: []

    blocked_issue =
      if "blocked" in outcomes and record["overall"] != "blocked",
        do: [:blocked_source_not_reflected],
        else: []

    register_claim_issue ++ clear_issue ++ blocked_issue
  end

  # --- decision ------------------------------------------------------------------------

  @doc """
  Decides whether an announcement is allowed as of `today` (a `%Date{}`).

  Takes a record map, `{:ok, record}` or `{:error, reason}` (a `load/1` result) and
  returns `{:allow, :clear}`, `{:allow, :owner_override}` or `{:deny, reason}` with
  reason `:no_record`, `:invalid_record`, `:blocked`, `:expired` or `:not_clear`.

  Evaluation order: a missing or invalid record denies, then `blocked` denies (a file can
  never override it), then a record that is not strictly before `expires` denies, then
  the allow paths: `clear` with `register_checked`, or a populated `owner_override`.
  Pure: the date is an argument and nothing is read or written.
  """
  def decision(record_or_result, %Date{} = today) do
    case normalize(record_or_result) do
      {:ok, record} -> judge(record, today)
      {:deny, reason} -> {:deny, reason}
    end
  end

  defp normalize({:error, {:missing, _path}}), do: {:deny, :no_record}
  defp normalize({:error, _reason}), do: {:deny, :invalid_record}

  defp normalize({:ok, record}), do: normalize(record)

  defp normalize(record) do
    case validate(record) do
      {:ok, record} -> {:ok, record}
      {:error, _issues} -> {:deny, :invalid_record}
    end
  end

  defp judge(%{"overall" => "blocked"}, _today), do: {:deny, :blocked}

  defp judge(record, today) do
    {:ok, expires} = parse_date(record["expires"])

    cond do
      Date.compare(today, expires) != :lt -> {:deny, :expired}
      record["overall"] == "clear" and record["register_checked"] == true -> {:allow, :clear}
      is_map(record["owner_override"]) -> {:allow, :owner_override}
      true -> {:deny, :not_clear}
    end
  end

  @doc """
  True exactly when `decision/2` allows. Pure: `today` is a `%Date{}` argument.
  """
  def announcement_allowed?(record_or_result, %Date{} = today) do
    match?({:allow, _basis}, decision(record_or_result, today))
  end

  @doc """
  The entry point the announcement phase calls: the same answer as
  `announcement_allowed?/2`, evaluated as of today's date.
  """
  def announcement_allowed?(record_or_result) do
    announcement_allowed?(record_or_result, today())
  end

  # The module's only clock read.
  defp today, do: Date.utc_today()

  # --- command line --------------------------------------------------------------------

  @doc false
  def cli(["check" | rest]) do
    case OptionParser.parse(rest, strict: [today: :string, path: :string]) do
      {opts, [], []} -> run_check(opts)
      _other -> {2, @help}
    end
  end

  def cli(_other), do: {2, @help}

  defp run_check(opts) do
    path = Keyword.get(opts, :path, @default_path)

    with {:ok, today} <- cli_today(Keyword.get(opts, :today)) do
      result = load(path)

      case decision(result, today) do
        {:allow, basis} ->
          {0, "allow (#{basis}): #{describe(result)}; as of #{today}"}

        {:deny, reason} ->
          {1, "deny (#{reason}): #{describe(result)}; as of #{today}"}
      end
    else
      :error -> {2, "invalid --today (expected YYYY-MM-DD)\n\n" <> @help}
    end
  end

  defp cli_today(nil), do: {:ok, today()}

  defp cli_today(value) do
    case parse_date(value) do
      {:ok, date} -> {:ok, date}
      :error -> :error
    end
  end

  defp describe({:ok, record}) do
    "overall=#{record["overall"]} register_checked=#{record["register_checked"]} " <>
      "expires=#{record["expires"]}"
  end

  defp describe({:error, {:missing, path}}), do: "no record at #{path}"
  defp describe({:error, {:malformed_json, message}}), do: "malformed JSON (#{message})"

  defp describe({:error, {:invalid_record, issues}}),
    do: "invalid record " <> inspect(issues, limit: 5)

  # --- helpers -------------------------------------------------------------------------

  defp text?(value), do: is_binary(value) and String.trim(value) != ""

  defp https_url?(value) when is_binary(value) do
    match?(%URI{scheme: "https", host: host} when is_binary(host) and host != "", URI.parse(value))
  end

  defp https_url?(_value), do: false

  # Extended ISO 8601 calendar dates only: Date.from_iso8601/1 also accepts the basic
  # form (20261113), which a hand-edited record should not drift into.
  defp parse_date(value) when is_binary(value) do
    with true <- Regex.match?(@iso_date, value),
         {:ok, date} <- Date.from_iso8601(value) do
      {:ok, date}
    else
      _ -> :error
    end
  end

  defp parse_date(_value), do: :error
end

if Mix.env() != :test do
  {status, output} = Mailglass.BrandTrademarkGate.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
