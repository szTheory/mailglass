defmodule Mailglass.BrandTrademarkGate do
  @moduledoc false

  # Fail-closed gate for the trademark and name search record (BRPOL-05, D-20..D-23).
  #
  # `.planning/research/brand-v2-adoption/trademark-search.json` records what was
  # searched for the name and mark and what was found. The announcement and any
  # trademark-symbol text are irreversible, so they wait on this record: the gate answers
  # "may we announce?" and defaults to no.
  #
  # Decision logic stays pure when a date is injected: `validate/2`, `decision/2` and
  # `announcement_allowed?/2` never read the clock. Their production wrappers use UTC
  # today. Public-text scanning consults the record and clock only when it finds an
  # unregistered-mark claim, so unrelated text does not become stale when a search expires.
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
  @max_validity_days 180
  @pinned_rule_path "brandbook/v2/brand.json"
  @pinned_rule_sha256 "db98e7a10c7f7873dee61139048cb788b0f7cea9ddd66e28a04a3661b0629b30"

  @public_text_extensions ~w(.md .mdx .ex .exs .heex .eex .html .css .js .json .svg .xml .yml .yaml .toml .sh)
  @public_text_prefixes [
    "docs/",
    "guides/",
    "brandbook/",
    "lib/",
    "priv/static/",
    "mailglass_admin/lib/",
    "mailglass_admin/priv/static/",
    "mailglass_inbound/lib/",
    "mailglass_inbound/priv/static/"
  ]
  @public_text_files [
    "README.md",
    "CHANGELOG.md",
    "mailglass_admin/README.md",
    "mailglass_admin/CHANGELOG.md",
    "mailglass_inbound/README.md",
    "mailglass_inbound/CHANGELOG.md",
    "mix.exs",
    "mailglass_admin/mix.exs",
    "mailglass_inbound/mix.exs"
  ]

  @registered_mark_patterns [
    ~r/®/u,
    ~r/&reg;/i,
    ~r/&#0*174;/i,
    ~r/&#x0*ae;/i,
    ~r/\\(?:0*ae)(?:[ \t\r\n])?/i,
    ~r/\\u(?:0*ae)/i,
    ~r/\\u\{0*ae\}/i
  ]
  @unregistered_mark_patterns [
    ~r/™/u,
    ~r/&trade;/i,
    ~r/&#0*8482;/i,
    ~r/&#x0*2122;/i,
    ~r/\\(?:0*2122)(?:[ \t\r\n])?/i,
    ~r/\\u(?:0*2122)/i,
    ~r/\\u\{0*2122\}/i,
    ~r/\(\s*TM\s*\)/i
  ]
  @tm_candidate_pattern ~r/\(\s*tm/i

  @help """
  brand_trademark_gate.exs - fail-closed trademark announcement gate

  Usage: mix run --no-start scripts/brand_trademark_gate.exs check [options]

    check
      Loads the trademark search record and prints the gate decision. Exit 0 when an
      announcement is allowed, 1 when it is denied (including a missing, invalid or
      expired record), 2 on a usage error.

  Options:
    --today YYYY-MM-DD   test-only: evaluate as of this date instead of today
    --path FILE          test-only: read this record instead of #{@default_path}
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
  def validate(record), do: validate(record, today())

  @doc """
  Checks a decoded record and its date bounds as of `today`.

  The injected date keeps decision tests deterministic. The one-argument `validate/1`
  wrapper uses the current UTC date for file loading and production checks.
  """
  def validate(record, %Date{} = today) when is_map(record) do
    case shape_issues(record, today) do
      [] ->
        case invariant_issues(record) do
          [] -> {:ok, record}
          issues -> {:error, issues}
        end

      issues ->
        {:error, issues}
    end
  end

  def validate(_other, _today), do: {:error, [:not_a_map]}

  defp shape_issues(record, today) do
    keys = Map.keys(record)

    key_issues =
      Enum.map(@record_keys -- keys, &{:missing_key, &1}) ++
        Enum.map(keys -- @record_keys, &{:unknown_key, &1})

    key_issues ++
      schema_issues(record) ++
      date_issues(record, today) ++
      text_issues(record) ++
      list_issues(record) ++
      closed_set_issues(record) ++
      override_issues(Map.get(record, "owner_override")) ++
      sources_issues(Map.get(record, "sources"))
  end

  defp schema_issues(record) do
    if Map.get(record, "schema") == @schema, do: [], else: [:schema_mismatch]
  end

  defp date_issues(record, today) do
    date = parse_date(Map.get(record, "date"))
    expires = parse_date(Map.get(record, "expires"))

    date_issue(date, {:invalid_date, "date"}) ++
      date_issue(expires, {:invalid_date, "expires"}) ++
      expiry_order_issue(date, expires) ++
      future_record_date_issue(date, today) ++
      validity_window_issue(date, expires)
  end

  defp date_issue({:ok, _date}, _tag), do: []
  defp date_issue(:error, tag), do: [tag]

  defp expiry_order_issue({:ok, date}, {:ok, expires}) do
    if Date.compare(expires, date) == :gt, do: [], else: [:expires_not_after_date]
  end

  defp expiry_order_issue(_date, _expires), do: []

  defp future_record_date_issue({:ok, date}, today) do
    if Date.compare(date, today) == :gt, do: [:record_date_in_future], else: []
  end

  defp future_record_date_issue(_date, _today), do: []

  defp validity_window_issue({:ok, date}, {:ok, expires}) do
    if Date.diff(expires, date) > @max_validity_days, do: [:validity_window_too_long], else: []
  end

  defp validity_window_issue(_date, _expires), do: []

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

    required_registers = Enum.filter(sources, &(&1["id"] in @required_source_ids))

    clear_issue =
      if record["overall"] == "clear" and
           (not record["register_checked"] or "not_checked" in outcomes or "blocked" in outcomes or
              Enum.any?(required_registers, &(&1["outcome"] != "clear"))),
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
    case normalize(record_or_result, today) do
      {:ok, record} -> judge(record, today)
      {:deny, reason} -> {:deny, reason}
    end
  end

  defp normalize({:error, {:missing, _path}}, _today), do: {:deny, :no_record}

  defp normalize({:error, {:invalid_record, issues}}, _today),
    do: invalid_record_reason(issues)

  defp normalize({:error, _reason}, _today), do: {:deny, :invalid_record}

  defp normalize({:ok, record}, today), do: normalize(record, today)

  defp normalize(record, today) do
    case validate(record, today) do
      {:ok, record} -> {:ok, record}
      {:error, issues} -> invalid_record_reason(issues)
    end
  end

  defp invalid_record_reason(issues) do
    if :record_date_in_future in issues, do: {:deny, :future_dated}, else: {:deny, :invalid_record}
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

  @doc """
  Finds adopter-facing trademark claims in tracked public text or explicit paths.

  Pass explicit generated-document paths to include their output in the same scan. The
  default scans only tracked project-facing sources and excludes planning and test files.
  Results are `{:ok, hits}` or `{:error, {:unreadable_public_text, path}}`.
  """
  def scan_public_text(paths \\ nil) do
    with {:ok, files} <- public_text_files(paths),
         {:ok, contents} <- read_public_text_files(files) do
      {:ok, Enum.flat_map(contents, &scan_public_file/1) |> Enum.sort_by(&hit_sort_key/1)}
    end
  end

  @doc """
  Applies the trademark decision to claims found in public text.

  Registered-mark claims are always denied. An unregistered-mark claim loads only the
  default search record unless `record_or_result` is injected by a test or verifier; when
  there are no claims, the record and clock are not consulted.
  """
  def scan_public_claims(paths \\ nil, record_or_result \\ :default, today \\ nil) do
    with {:ok, hits} <- scan_public_text(paths) do
      cond do
        Enum.any?(hits, &(&1.kind == :registered_mark)) ->
          {:deny, {:registered_mark_claim, hits}}

        Enum.any?(hits, &(&1.kind == :unregistered_mark)) ->
          record = if record_or_result == :default, do: load(), else: record_or_result
          decision_date = if match?(%Date{}, today), do: today, else: today()

          case decision(record, decision_date) do
            {:allow, basis} -> {:allow, {:unregistered_mark_claim, basis, hits}}
            {:deny, reason} -> {:deny, {:unregistered_mark_claim, reason, hits}}
          end

        true ->
          {:allow, {:no_claims, []}}
      end
    end
  end

  # --- command line --------------------------------------------------------------------

  @doc false
  def cli(["check" | rest]) do
    case OptionParser.parse(rest, strict: [today: :string, path: :string]) do
      {opts, [], []} ->
        if opts == [] or Mix.env() == :test do
          run_check(opts)
        else
          {2, "--today and --path are only available in MIX_ENV=test\n\n" <> @help}
        end

      _other ->
        {2, @help}
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

  defp public_text_files(nil) do
    case System.cmd("git", ["ls-files", "-z"], cd: @repo_root, stderr_to_stdout: true) do
      {output, 0} ->
        files =
          output
          |> String.split(<<0>>, trim: true)
          |> Enum.filter(&tracked_public_text_path?/1)
          |> Enum.map(&file_entry(Path.join(@repo_root, &1), @repo_root, &1))

        {:ok, files}

      {output, status} ->
        {:error, {:tracked_public_text_unavailable, status, output}}
    end
  end

  defp public_text_files(paths) do
    paths
    |> List.wrap()
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
      absolute = Path.expand(path, @repo_root)

      entries =
        if File.dir?(absolute) do
          absolute
          |> Path.join("**/*")
          |> Path.wildcard()
          |> Enum.filter(&(File.regular?(&1) and public_text_extension?(&1)))
          |> Enum.map(&file_entry(&1, absolute, nil))
        else
          [file_entry(absolute, Path.dirname(absolute), nil)]
        end

      case Enum.find(entries, &(not public_text_extension?(&1.path))) do
        nil -> {:cont, {:ok, acc ++ entries}}
        %{path: path} -> {:halt, {:error, {:unsupported_public_text_path, path}}}
      end
    end)
    |> case do
      {:ok, files} -> {:ok, Enum.uniq_by(files, & &1.path)}
      error -> error
    end
  end

  defp tracked_public_text_path?(path) do
    not String.starts_with?(path, [".planning/", "test/"]) and
      (path in @public_text_files or
         Path.basename(path) in ["README.md", "CHANGELOG.md"] or
         Enum.any?(@public_text_prefixes, &String.starts_with?(path, &1))) and
      public_text_extension?(path)
  end

  defp public_text_extension?(path) do
    Path.extname(path) in @public_text_extensions
  end

  defp file_entry(path, base, known_relative) do
    absolute = Path.expand(path)

    display_path =
      known_relative ||
        case Path.relative_to(absolute, base) do
          relative when is_binary(relative) and relative != "" -> relative
          _ -> Path.basename(absolute)
        end

    %{path: absolute, display_path: String.replace(display_path, "\\", "/")}
  end

  defp read_public_text_files(files) do
    Enum.reduce_while(files, {:ok, []}, fn file, {:ok, acc} ->
      case File.read(file.path) do
        {:ok, contents} when is_binary(contents) ->
          if String.valid?(contents) do
            {:cont, {:ok, [{file, contents} | acc]}}
          else
            {:halt, {:error, {:invalid_public_text_encoding, file.display_path}}}
          end

        {:error, _reason} ->
          {:halt, {:error, {:unreadable_public_text, file.display_path}}}
      end
    end)
    |> case do
      {:ok, contents} -> {:ok, Enum.reverse(contents)}
      error -> error
    end
  end

  defp scan_public_file({file, contents}) do
    contents
    |> public_text_values(file.path)
    |> Enum.flat_map(fn {text, field_path} ->
      text
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        line_claims(line)
        |> Enum.map(fn kind ->
          %{
            path: file.display_path,
            line: if(field_path == nil, do: line_number, else: nil),
            field: field_path,
            kind: kind
          }
        end)
      end)
    end)
  end

  defp public_text_values(contents, path) do
    if Path.expand(path) == Path.expand(Path.join(@repo_root, @pinned_rule_path)) and
         pinned_rule_file?(contents) do
      case Jason.decode(contents) do
        {:ok, json} -> json_public_values(json)
        {:error, _reason} -> [{contents, nil}]
      end
    else
      [{contents, nil}]
    end
  end

  defp pinned_rule_file?(contents) do
    digest = :crypto.hash(:sha256, contents) |> Base.encode16(case: :lower)
    pin_path = Path.join(@repo_root, "brandbook/brand.pin.json")

    with @pinned_rule_sha256 <- digest,
         {:ok, pin_contents} <- File.read(pin_path),
         {:ok, pin} <- Jason.decode(pin_contents),
         shipped when is_list(shipped) <- pin["shipped"],
         entry when is_map(entry) <- Enum.find(shipped, &(&1["to"] == @pinned_rule_path)),
         @pinned_rule_sha256 <- entry["sha256"],
         {:ok, json} <- Jason.decode(contents),
         legal when is_list(legal) <- json["legal"],
         rule when is_binary(rule) <- Enum.at(legal, 1) do
      String.contains?(rule, "™") and String.contains?(rule, "®")
    else
      _ -> false
    end
  end

  defp json_public_values(value, path \\ [])

  defp json_public_values(value, path) when is_map(value) do
    Enum.flat_map(value, fn {key, nested} ->
      next_path = path ++ [to_string(key)]
      if next_path == ["legal", 1], do: [], else: json_public_values(nested, next_path)
    end)
  end

  defp json_public_values(value, path) when is_list(value) do
    value
    |> Enum.with_index()
    |> Enum.flat_map(fn {nested, index} ->
      next_path = path ++ [index]
      if next_path == ["legal", 1], do: [], else: json_public_values(nested, next_path)
    end)
  end

  defp json_public_values(value, path) when is_binary(value), do: [{value, path}]
  defp json_public_values(_value, _path), do: []

  defp line_claims(line) do
    if possible_claim_text?(line) do
      decoded = decode_claim_encodings(line)
      kinds = []

      kinds =
        if Enum.any?(@registered_mark_patterns, &Regex.match?(&1, decoded)),
          do: [:registered_mark | kinds],
          else: kinds

      kinds =
        if Enum.any?(@unregistered_mark_patterns, &Regex.match?(&1, decoded)),
          do: [:unregistered_mark | kinds],
          else: kinds

      Enum.reverse(kinds)
    else
      []
    end
  end

  defp possible_claim_text?(line) do
    lowered = String.downcase(line)

    String.contains?(line, ["™", "®", "\\"]) or
      String.contains?(lowered, ["&trade", "&reg", "&#"]) or
      Regex.match?(@tm_candidate_pattern, lowered)
  end

  defp decode_claim_encodings(text) do
    text
    |> String.replace(~r/&reg(?:;|(?![[:alnum:]=]))/i, "®")
    |> String.replace(~r/&#0*174(?:;|(?![0-9]))/i, "®")
    |> String.replace(~r/&#x0*ae(?:;|(?![0-9a-f]))/i, "®")
    |> String.replace(~r/&trade(?:;|(?![[:alnum:]=]))/i, "™")
    |> String.replace(~r/&#0*8482(?:;|(?![0-9]))/i, "™")
    |> String.replace(~r/&#x0*2122(?:;|(?![0-9a-f]))/i, "™")
    |> String.replace(~r/\\(?:0*ae)(?:[ \t\r\n])?/i, "®")
    |> String.replace(~r/\\u(?:0*ae)/i, "®")
    |> String.replace(~r/\\u\{0*ae\}/i, "®")
    |> String.replace(~r/\\(?:0*2122)(?:[ \t\r\n])?/i, "™")
    |> String.replace(~r/\\u(?:0*2122)/i, "™")
    |> String.replace(~r/\\u\{0*2122\}/i, "™")
    |> String.replace(~r/\(\s*TM\s*\)/i, "™")
  end

  defp hit_sort_key(hit), do: {hit.path, hit.line || 0, hit.kind}

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

# Fail-closed entrypoint: the CLI runs in EVERY Mix env unless a test explicitly opts into
# library mode. Gating on Mix.env() made `MIX_ENV=test mix run <script>` print nothing and
# exit 0, which reads as "allowed" (CR-01). Application env is not inherited by subprocesses.
unless Application.get_env(:mailglass, :script_library_mode, false) do
  {status, output} = Mailglass.BrandTrademarkGate.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
