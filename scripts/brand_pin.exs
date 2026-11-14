defmodule Mailglass.BrandPin do
  @moduledoc false

  # Commit- and hash-pinned brand book (BRPOL-04, D-16..D-19).
  #
  # `brandbook/brand.pin.json` names one immutable commit of the brand repository plus the
  # sha256 and size of its zip, and a manifest of the few assets copied into
  # `brandbook/v2/`. The full book (the zip, an unzipped tree, the book's HTML and
  # markdown) never enters this repository.
  #
  # `verify/3` is the merge-blocking check: pure, offline, no network and no zip.
  # `check_zip/2` and the `check` command are the advisory online check.
  #
  # Invoke as `mix run --no-start scripts/brand_pin.exs <command>` so Jason is loaded.

  @repo_root Path.expand("..", __DIR__)
  @pin_rel "brandbook/brand.pin.json"
  @default_repo "szTheory/mailglass-brand"
  @book_meta_member "brand.json"

  @sha1 ~r/\A[0-9a-f]{40}\z/
  @sha256 ~r/\A[0-9a-f]{64}\z/
  @repo_name ~r/\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/
  @iso_date ~r/\A\d{4}-\d{2}-\d{2}\z/
  @book_date ~r/\A([A-Za-z]+) (\d{1,2}), (\d{4})\z/

  @licenses ["MIT", "OFL-1.1"]

  @pin_keys ~w(repo commit url sha256 size book root owned_dirs shipped note)
  @book_keys ~w(version date)
  @shipped_keys ~w(from to sha256 bytes license)

  # {zip member (relative to the zip root), repo path, license}. Phases 180 and 181 extend
  # the pin's `shipped` list; this phase copies only assets that exist and ship now (D-17).
  @initial_manifest [
    {"brand.json", "brandbook/v2/brand.json", "MIT"},
    {"assets/fonts/OFL-FunnelDisplay.txt", "brandbook/v2/OFL-FunnelDisplay.txt", "OFL-1.1"},
    {"assets/fonts/OFL-AtkinsonHyperlegibleNext.txt",
     "brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt", "OFL-1.1"},
    {"assets/fonts/OFL-AtkinsonHyperlegibleMono.txt",
     "brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt", "OFL-1.1"}
  ]
  @required_assets for {_from, to, _license} <- @initial_manifest, do: to

  @months %{
    "january" => 1,
    "february" => 2,
    "march" => 3,
    "april" => 4,
    "may" => 5,
    "june" => 6,
    "july" => 7,
    "august" => 8,
    "september" => 9,
    "october" => 10,
    "november" => 11,
    "december" => 12
  }

  @note "Offline verification (test/scripts/brand_pin_test.exs) is merge-blocking. " <>
          "The online check (mix run --no-start scripts/brand_pin.exs check) is advisory. " <>
          "Update with: mix run --no-start scripts/brand_pin.exs update --commit <sha> " <>
          "--expect-sha256 <hex>, and bump @expected_zip_sha256 in the same chore(brand) " <>
          "commit; never hand-edit."

  @help """
  brand_pin.exs - commit- and hash-pinned brand book (brandbook/brand.pin.json)

  Usage: mix run --no-start scripts/brand_pin.exs <command>

    verify
      Offline, merge-blocking check. Reads brandbook/brand.pin.json and brandbook/v2/ and
      confirms every shipped asset matches its recorded size and sha256 and that no
      unlisted file sits in an owned directory. This is what the test suite runs.

    check
      ADVISORY online check. Downloads the pinned zip over TLS with peer verification,
      confirms its sha256 and size, confirms every shipped member inside it, then runs
      verify. It never blocks a merge.

    init --commit <sha> --expect-sha256 <hex>
      Create the pin from a reviewed commit. Refuses when a pin already exists, and
      refuses a zip whose sha256 differs from --expect-sha256.

    update --commit <sha> --expect-sha256 <hex>
      Move the pin to a reviewed commit. Refuses a zip whose sha256 differs from
      --expect-sha256, rewrites the pin and the copied assets, and writes nothing on a
      refusal. Bump @expected_zip_sha256 in test/scripts/brand_pin_test.exs in the same
      chore(brand) commit. Never hand-edit the pin.

    help
      Print this text.
  """

  # ---------------------------------------------------------------------------
  # Hashing and URLs

  def sha256_hex(binary) when is_binary(binary) do
    :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
  end

  def zip_url(repo, commit) when is_binary(repo) and is_binary(commit) do
    repo_name = repo |> String.split("/") |> List.last()
    "https://raw.githubusercontent.com/" <> repo <> "/" <> commit <> "/" <> repo_name <> ".zip"
  end

  @doc false
  # The one detector both the real-pin test and tamper case (b) call, so a pin-only edit of
  # the zip hash fails through the same code path.
  def check_expected_sha256(pin_map, expected) when is_map(pin_map) do
    if pin_map["sha256"] == expected do
      :ok
    else
      {:error, [{:zip_hash_unexpected, pin_map["sha256"]}]}
    end
  end

  # ---------------------------------------------------------------------------
  # Parsing (pure). Returns {:ok, pin} or {:error, [{tag, detail}]}.

  def parse(map) when is_map(map) do
    if Enum.sort(Map.keys(map)) != Enum.sort(@pin_keys) do
      {:error, [{:pin_malformed, "keys"}]}
    else
      issues =
        repo_issues(map) ++
          commit_issues(map) ++
          sha256_issues(map) ++
          size_issues(map) ++
          url_issues(map) ++
          book_issues(map) ++
          root_issues(map) ++
          owned_dirs_issues(map) ++
          note_issues(map) ++
          shipped_issues(map)

      case issues do
        [] -> {:ok, map}
        _ -> {:error, issues}
      end
    end
  end

  def parse(_other), do: {:error, [{:pin_malformed, "not an object"}]}

  defp repo_issues(%{"repo" => repo}) do
    if valid_repo?(repo), do: [], else: [{:pin_malformed, "repo"}]
  end

  defp commit_issues(%{"commit" => commit}) do
    if is_binary(commit) and Regex.match?(@sha1, commit), do: [], else: [{:pin_malformed, "commit"}]
  end

  defp sha256_issues(%{"sha256" => sha}) do
    if is_binary(sha) and Regex.match?(@sha256, sha), do: [], else: [{:pin_malformed, "sha256"}]
  end

  defp size_issues(%{"size" => size}) do
    if is_integer(size) and size > 0, do: [], else: [{:pin_malformed, "size"}]
  end

  defp url_issues(%{"repo" => repo, "commit" => commit, "url" => url}) do
    cond do
      not is_binary(url) ->
        [{:pin_malformed, "url"}]

      valid_repo?(repo) and is_binary(commit) and url != zip_url(repo, commit) ->
        [{:url_not_derived, url}]

      true ->
        []
    end
  end

  defp book_issues(%{"book" => %{} = book}) do
    cond do
      Enum.sort(Map.keys(book)) != Enum.sort(@book_keys) ->
        [{:pin_malformed, "book"}]

      not (is_binary(book["version"]) and book["version"] != "") ->
        [{:pin_malformed, "book.version"}]

      not valid_iso_date?(book["date"]) ->
        [{:pin_malformed, "book.date"}]

      true ->
        []
    end
  end

  defp book_issues(_), do: [{:pin_malformed, "book"}]

  defp root_issues(%{"repo" => repo, "root" => root}) do
    if valid_repo?(repo) and root == List.last(String.split(repo, "/")) <> "/" do
      []
    else
      [{:pin_malformed, "root"}]
    end
  end

  defp owned_dirs_issues(%{"owned_dirs" => [_ | _] = dirs}) do
    for dir <- dirs, not safe_path?(dir), do: {:path_unsafe, describe(dir)}
  end

  defp owned_dirs_issues(_), do: [{:pin_malformed, "owned_dirs"}]

  defp note_issues(%{"note" => note}) do
    if is_binary(note), do: [], else: [{:pin_malformed, "note"}]
  end

  defp shipped_issues(%{"shipped" => []}), do: [{:manifest_empty, "shipped"}]

  defp shipped_issues(%{"shipped" => shipped} = pin) when is_list(shipped) do
    owned =
      if is_list(pin["owned_dirs"]), do: Enum.filter(pin["owned_dirs"], &safe_path?/1), else: []

    tos = for %{"to" => to} <- shipped, is_binary(to), do: to

    duplicates =
      for {to, count} <- Enum.frequencies(tos),
          count > 1,
          do: {:pin_malformed, "duplicate to #{to}"}

    required = for to <- @required_assets, to not in tos, do: {:required_asset_absent, to}

    Enum.flat_map(shipped, &entry_issues(&1, owned)) ++ duplicates ++ required
  end

  defp shipped_issues(_), do: [{:pin_malformed, "shipped"}]

  defp entry_issues(%{} = entry, owned) do
    if Enum.sort(Map.keys(entry)) != Enum.sort(@shipped_keys) do
      [{:pin_malformed, "shipped entry keys"}]
    else
      label = describe(entry["to"])

      from_issues =
        if safe_path?(entry["from"]), do: [], else: [{:path_unsafe, describe(entry["from"])}]

      to_issues =
        cond do
          not safe_path?(entry["to"]) -> [{:path_unsafe, label}]
          Enum.any?(owned, &String.starts_with?(entry["to"], &1 <> "/")) -> []
          true -> [{:path_unsafe, label}]
        end

      sha_issues =
        if is_binary(entry["sha256"]) and Regex.match?(@sha256, entry["sha256"]),
          do: [],
          else: [{:pin_malformed, "shipped sha256 #{label}"}]

      bytes_issues =
        if is_integer(entry["bytes"]) and entry["bytes"] > 0,
          do: [],
          else: [{:pin_malformed, "shipped bytes #{label}"}]

      license_issues =
        if entry["license"] in @licenses,
          do: [],
          else: [{:pin_malformed, "shipped license #{label}"}]

      from_issues ++ to_issues ++ sha_issues ++ bytes_issues ++ license_issues
    end
  end

  defp entry_issues(_other, _owned), do: [{:pin_malformed, "shipped entry"}]

  defp valid_repo?(repo), do: is_binary(repo) and Regex.match?(@repo_name, repo)

  defp valid_iso_date?(date) do
    is_binary(date) and Regex.match?(@iso_date, date) and match?({:ok, _}, Date.from_iso8601(date))
  end

  # A safe relative path: non-empty, not absolute, no backslash, no NUL byte, and no empty,
  # "." or ".." segment.
  defp safe_path?(path) when is_binary(path) do
    path != "" and
      not String.starts_with?(path, "/") and
      not String.contains?(path, ["\\", <<0>>]) and
      Enum.all?(String.split(path, "/"), &(&1 not in ["", ".", ".."]))
  end

  defp safe_path?(_other), do: false

  defp describe(value) when is_binary(value), do: value
  defp describe(value), do: inspect(value)

  # ---------------------------------------------------------------------------
  # Offline verification (pure over injected closures). The merge-blocking check.

  def tree_read_file(root \\ @repo_root) do
    fn rel ->
      path = Path.join(root, rel)

      case File.lstat(path) do
        {:ok, %File.Stat{type: :regular}} -> File.read(path)
        {:ok, %File.Stat{}} -> {:error, :not_regular_file}
        {:error, _reason} = error -> error
      end
    end
  end

  # Every non-directory entry under `dir`, hidden files included, repo-relative and sorted.
  def tree_list_dir(root \\ @repo_root) do
    fn dir -> root |> Path.join(dir) |> walk() |> Enum.map(&Path.relative_to(&1, root)) end
  end

  defp walk(abs_dir) do
    case File.ls(abs_dir) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.flat_map(fn name ->
          path = Path.join(abs_dir, name)

          case File.lstat(path) do
            {:ok, %File.Stat{type: :directory}} -> walk(path)
            {:ok, %File.Stat{}} -> [path]
            {:error, _reason} -> []
          end
        end)

      {:error, _reason} ->
        []
    end
  end

  def verify(pin_map, read_file \\ tree_read_file(), list_dir \\ tree_list_dir())
      when is_function(read_file, 1) and is_function(list_dir, 1) do
    case parse(pin_map) do
      {:error, issues} ->
        {:error, issues}

      {:ok, pin} ->
        asset_issues = Enum.flat_map(pin["shipped"], &asset_issues(&1, read_file))
        listed = MapSet.new(pin["shipped"], & &1["to"])

        unlisted =
          for dir <- pin["owned_dirs"],
              path <- list_dir.(dir),
              not MapSet.member?(listed, path),
              uniq: true,
              do: {:asset_unlisted, path}

        case asset_issues ++ unlisted do
          [] -> :ok
          issues -> {:error, issues}
        end
    end
  end

  defp asset_issues(%{"to" => to, "sha256" => want, "bytes" => bytes}, read_file) do
    case read_file.(to) do
      {:ok, data} when byte_size(data) != bytes -> [{:asset_size_mismatch, to}]
      {:ok, data} -> if sha256_hex(data) == want, do: [], else: [{:asset_hash_mismatch, to}]
      {:error, _reason} -> [{:asset_missing, to}]
    end
  end

  # ---------------------------------------------------------------------------
  # Zip handling (advisory check, init and update). Members are read in memory by names the
  # pin lists (`root <> from`), never by names the archive supplies.

  def check_zip(pin_map, zip_bin) when is_binary(zip_bin) do
    case parse(pin_map) do
      {:error, issues} ->
        {:error, issues}

      {:ok, pin} ->
        actual_sha = sha256_hex(zip_bin)

        top =
          if(actual_sha == pin["sha256"], do: [], else: [{:zip_hash_mismatch, actual_sha}]) ++
            if byte_size(zip_bin) == pin["size"],
              do: [],
              else: [{:zip_size_mismatch, byte_size(zip_bin)}]

        froms = Enum.map(pin["shipped"], & &1["from"])

        member_issues =
          case read_members(zip_bin, pin["root"], froms) do
            {:ok, members} ->
              for %{"from" => from, "sha256" => want, "bytes" => bytes} <- pin["shipped"] do
                case Map.fetch!(members, from) do
                  :missing -> {:zip_member_missing, from}
                  data when byte_size(data) != bytes -> {:zip_member_mismatch, from}
                  data -> if sha256_hex(data) == want, do: nil, else: {:zip_member_mismatch, from}
                end
              end
              |> Enum.reject(&is_nil/1)

            {:error, reason} ->
              [{:zip_unreadable, inspect(reason)}]
          end

        case top ++ member_issues do
          [] -> :ok
          issues -> {:error, issues}
        end
    end
  end

  # Returns {:ok, %{from => binary | :missing}}. Opens the exact bytes it was given and
  # always closes the handle.
  defp read_members(zip_bin, root, froms) do
    case :zip.zip_open(zip_bin, [:memory]) do
      {:ok, handle} ->
        try do
          members =
            Map.new(froms, fn from ->
              case :zip.zip_get(String.to_charlist(root <> from), handle) do
                {:ok, {_name, data}} -> {from, data}
                {:error, _reason} -> {from, :missing}
              end
            end)

          {:ok, members}
        after
          :zip.zip_close(handle)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Download (TLS with peer verification; the getter is injected so tests never touch the
  # network).

  def fetch(url, getter \\ &http_get/1) when is_binary(url) and is_function(getter, 1) do
    if String.starts_with?(url, "https://") do
      getter.(url)
    else
      {:error, :url_not_https}
    end
  end

  defp http_get(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    ssl = [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
    ]

    case :httpc.request(:get, {String.to_charlist(url), []}, [ssl: ssl, timeout: 60_000],
           body_format: :binary
         ) do
      {:ok, {{_version, 200, _phrase}, _headers, body}} -> {:ok, body}
      {:ok, {{_version, status, _phrase}, _headers, _body}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, {:http_error, reason}}
    end
  rescue
    error -> {:error, {:http_error, Exception.message(error)}}
  end

  # ---------------------------------------------------------------------------
  # init and update. Every refusal happens before any write.

  def init(opts, getter \\ &http_get/1) do
    target = Keyword.get(opts, :target_dir, @repo_root)
    repo = Keyword.get(opts, :repo, @default_repo)
    commit = Keyword.get(opts, :commit)
    expect = Keyword.get(opts, :expect_sha256)

    with :ok <- check_options(commit, expect),
         :ok <- check_no_pin(target),
         {:ok, zip_bin} <- download(repo, commit, expect, getter),
         {:ok, members} <- read_initial_members(zip_bin, repo),
         {:ok, book} <- book_meta(members),
         pin = build_pin(repo, commit, zip_bin, book, initial_entries(members)),
         :ok <- ensure_parses(pin),
         :ok <- write_all(target, pin, members) do
      {:ok, pin}
    end
  end

  def update(pin_map, opts, getter \\ &http_get/1) do
    target = Keyword.get(opts, :target_dir, @repo_root)
    commit = Keyword.get(opts, :commit)
    expect = Keyword.get(opts, :expect_sha256)

    with {:ok, current} <- parse_current(pin_map),
         :ok <- check_options(commit, expect),
         {:ok, zip_bin} <- download(current["repo"], commit, expect, getter),
         {:ok, members} <- read_pin_members(zip_bin, current),
         {:ok, book} <- book_meta(members),
         pin = rewrite_pin(current, commit, zip_bin, book, members),
         :ok <- ensure_parses(pin),
         :ok <- write_all(target, pin, members) do
      {:ok, pin}
    end
  end

  defp parse_current(pin_map) do
    case parse(pin_map) do
      {:ok, pin} -> {:ok, pin}
      {:error, issues} -> {:error, {:pin_invalid, issues}}
    end
  end

  defp check_options(commit, expect) do
    cond do
      not (is_binary(commit) and Regex.match?(@sha1, commit)) ->
        {:error, {:bad_option, "--commit must be a full 40-character lowercase commit sha"}}

      not (is_binary(expect) and Regex.match?(@sha256, expect)) ->
        {:error, {:bad_option, "--expect-sha256 must be 64 lowercase hex characters"}}

      true ->
        :ok
    end
  end

  defp check_no_pin(target) do
    if File.exists?(Path.join(target, @pin_rel)), do: {:error, :pin_exists}, else: :ok
  end

  defp download(repo, commit, expect, getter) do
    case fetch(zip_url(repo, commit), getter) do
      {:ok, body} when is_binary(body) ->
        # Hash the exact downloaded bytes before reading anything from them.
        if sha256_hex(body) == expect, do: {:ok, body}, else: {:error, :zip_hash_mismatch}

      {:error, reason} ->
        {:error, {:fetch_failed, reason}}
    end
  end

  # Members are fetched by names this module lists, never by names from the archive.
  defp read_initial_members(zip_bin, repo) do
    root = List.last(String.split(repo, "/")) <> "/"
    froms = Enum.map(@initial_manifest, fn {from, _to, _license} -> from end)
    collect_members(zip_bin, root, froms)
  end

  defp read_pin_members(zip_bin, current) do
    froms = Enum.map(current["shipped"], & &1["from"])
    collect_members(zip_bin, current["root"], Enum.uniq([@book_meta_member | froms]))
  end

  defp collect_members(zip_bin, root, froms) do
    case read_members(zip_bin, root, froms) do
      {:ok, members} ->
        case Enum.find(froms, &(Map.fetch!(members, &1) == :missing)) do
          nil -> {:ok, members}
          missing -> {:error, {:zip_member_missing, missing}}
        end

      {:error, reason} ->
        {:error, {:zip_unreadable, reason}}
    end
  end

  defp book_meta(members) do
    with {:ok, json} <- Map.fetch(members, @book_meta_member) |> member_or_missing(),
         {:ok, %{"version" => version, "date" => date}} when is_binary(version) <-
           Jason.decode(json),
         {:ok, iso} <- iso_date(date) do
      {:ok, %{"version" => version, "date" => iso}}
    else
      {:error, {:zip_member_missing, _} = reason} -> {:error, reason}
      _other -> {:error, :book_meta_unreadable}
    end
  end

  defp member_or_missing({:ok, :missing}), do: {:error, {:zip_member_missing, @book_meta_member}}
  defp member_or_missing({:ok, data}), do: {:ok, data}
  defp member_or_missing(:error), do: {:error, {:zip_member_missing, @book_meta_member}}

  # Accepts ISO-8601 or the book's "November 13, 2026" style.
  defp iso_date(date) when is_binary(date) do
    cond do
      valid_iso_date?(date) ->
        {:ok, date}

      match = Regex.run(@book_date, date) ->
        [_all, month, day, year] = match

        with {:ok, month_number} <- Map.fetch(@months, String.downcase(month)),
             {:ok, parsed} <-
               Date.new(String.to_integer(year), month_number, String.to_integer(day)) do
          {:ok, Date.to_iso8601(parsed)}
        else
          _ -> {:error, {:book_date_unparseable, date}}
        end

      true ->
        {:error, {:book_date_unparseable, date}}
    end
  end

  defp iso_date(other), do: {:error, {:book_date_unparseable, inspect(other)}}

  defp initial_entries(members) do
    for {from, to, license} <- @initial_manifest do
      data = Map.fetch!(members, from)

      %{
        "from" => from,
        "to" => to,
        "sha256" => sha256_hex(data),
        "bytes" => byte_size(data),
        "license" => license
      }
    end
  end

  defp build_pin(repo, commit, zip_bin, book, shipped) do
    %{
      "repo" => repo,
      "commit" => commit,
      "url" => zip_url(repo, commit),
      "sha256" => sha256_hex(zip_bin),
      "size" => byte_size(zip_bin),
      "book" => book,
      "root" => List.last(String.split(repo, "/")) <> "/",
      "owned_dirs" => ["brandbook/v2"],
      "shipped" => shipped,
      "note" => @note
    }
  end

  defp rewrite_pin(current, commit, zip_bin, book, members) do
    shipped =
      for entry <- current["shipped"] do
        data = Map.fetch!(members, entry["from"])
        %{entry | "sha256" => sha256_hex(data), "bytes" => byte_size(data)}
      end

    %{
      current
      | "commit" => commit,
        "url" => zip_url(current["repo"], commit),
        "sha256" => sha256_hex(zip_bin),
        "size" => byte_size(zip_bin),
        "book" => book,
        "shipped" => shipped
    }
  end

  # Never write a pin we would refuse to read.
  defp ensure_parses(pin) do
    case parse(pin) do
      {:ok, _pin} -> :ok
      {:error, issues} -> {:error, {:pin_invalid, issues}}
    end
  end

  # Assets first, then the pin (atomically), so an interrupted write never leaves a pin that
  # points at assets that were not copied.
  defp write_all(target, pin, members) do
    with :ok <- write_assets(target, pin, members) do
      write_pin(target, pin)
    end
  end

  defp write_assets(target, pin, members) do
    Enum.reduce_while(pin["shipped"], :ok, fn %{"from" => from, "to" => to}, :ok ->
      dest = Path.join(target, to)

      with :ok <- File.mkdir_p(Path.dirname(dest)),
           :ok <- File.write(dest, Map.fetch!(members, from)) do
        {:cont, :ok}
      else
        {:error, reason} -> {:halt, {:error, {:write_failed, to, reason}}}
      end
    end)
  end

  defp write_pin(target, pin) do
    path = Path.join(target, @pin_rel)
    temporary = path <> ".tmp"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(temporary, serialize(pin)),
         :ok <- File.rename(temporary, path) do
      :ok
    else
      {:error, reason} -> {:error, {:write_failed, @pin_rel, reason}}
    end
  end

  # Stable key order and a trailing newline.
  def serialize(pin) do
    ordered =
      Jason.OrderedObject.new([
        {"repo", pin["repo"]},
        {"commit", pin["commit"]},
        {"url", pin["url"]},
        {"sha256", pin["sha256"]},
        {"size", pin["size"]},
        {"book",
         Jason.OrderedObject.new([
           {"version", pin["book"]["version"]},
           {"date", pin["book"]["date"]}
         ])},
        {"root", pin["root"]},
        {"owned_dirs", pin["owned_dirs"]},
        {"shipped",
         for entry <- pin["shipped"] do
           Jason.OrderedObject.new(for key <- @shipped_keys, do: {key, entry[key]})
         end},
        {"note", pin["note"]}
      ])

    IO.iodata_to_binary([Jason.encode_to_iodata!(ordered, pretty: true), "\n"])
  end

  # ---------------------------------------------------------------------------
  # CLI

  def cli(args, getter \\ &http_get/1)

  def cli(["verify"], _getter) do
    with {:ok, pin_map} <- read_pin() do
      case verify(pin_map) do
        :ok -> {0, "brand pin ok"}
        {:error, issues} -> {1, render_issues("brand pin verify failed", issues)}
      end
    else
      {:error, message} -> {1, message}
    end
  end

  def cli(["check"], getter) do
    with {:ok, pin_map} <- read_pin(),
         {:ok, pin} <- parse_for_cli(pin_map),
         {:ok, zip_bin} <- fetch_for_cli(pin, getter) do
      zip_issues =
        case check_zip(pin, zip_bin) do
          :ok -> []
          {:error, issues} -> issues
        end

      tree_issues =
        case verify(pin) do
          :ok -> []
          {:error, issues} -> issues
        end

      case zip_issues ++ tree_issues do
        [] -> {0, "advisory check ok"}
        issues -> {1, render_issues("advisory check found issues", issues)}
      end
    else
      {:error, message} -> {1, message}
    end
  end

  def cli(["init" | rest], getter) do
    case parse_options(rest) do
      {:ok, opts} ->
        case init(opts, getter) do
          {:ok, pin} -> {0, "pin written: #{pin["repo"]}@#{pin["commit"]}"}
          {:error, reason} -> {1, "init refused: #{format_reason(reason)}"}
        end

      {:error, message} ->
        {2, message}
    end
  end

  def cli(["update" | rest], getter) do
    with {:ok, opts} <- parse_options(rest),
         {:ok, pin_map} <- read_pin() do
      case update(pin_map, opts, getter) do
        {:ok, pin} ->
          {0,
           "pin updated: #{pin["repo"]}@#{pin["commit"]}\nbump @expected_zip_sha256 to #{pin["sha256"]}"}

        {:error, reason} ->
          {1, "update refused: #{format_reason(reason)}"}
      end
    else
      {:error, message} -> {2, message}
    end
  end

  def cli(["help"], _getter), do: {0, String.trim_trailing(@help)}
  def cli(_other, _getter), do: {2, String.trim_trailing(@help)}

  defp read_pin do
    path = Path.join(@repo_root, @pin_rel)

    with {:ok, contents} <- File.read(path),
         {:ok, value} <- Jason.decode(contents) do
      {:ok, value}
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, "#{@pin_rel} is not valid JSON: #{Exception.message(error)}"}

      {:error, reason} ->
        {:error, "#{@pin_rel} unreadable: #{inspect(reason)}"}
    end
  end

  defp parse_for_cli(pin_map) do
    case parse(pin_map) do
      {:ok, pin} -> {:ok, pin}
      {:error, issues} -> {:error, render_issues("brand pin malformed", issues)}
    end
  end

  defp fetch_for_cli(pin, getter) do
    case fetch(pin["url"], getter) do
      {:ok, body} ->
        {:ok, body}

      {:error, reason} ->
        {:error, "advisory check could not download #{pin["url"]}: #{inspect(reason)}"}
    end
  end

  defp parse_options(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [commit: :string, expect_sha256: :string])

    if (rest == [] and invalid == [] and opts[:commit]) && opts[:expect_sha256] do
      {:ok, opts}
    else
      {:error, "usage: <command> --commit <40-hex sha> --expect-sha256 <64-hex>"}
    end
  end

  defp render_issues(heading, issues) do
    lines = for {tag, detail} <- issues, do: "  #{tag}: #{detail}"
    Enum.join([heading <> ":" | lines], "\n")
  end

  defp format_reason({:pin_invalid, issues}), do: render_issues("pin would be invalid", issues)
  defp format_reason(reason), do: inspect(reason)
end

if Mix.env() != :test do
  {status, output} = Mailglass.BrandPin.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
