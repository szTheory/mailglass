defmodule MailglassAdmin.TestSupport.CatalogValidators do
  @moduledoc """
  Pure validators shared by the catalog manifest tests (Phase 182, BRADM-07).

  Compiled from `test/support` through `elixirc_paths(:test)`, so it never ships in the Hex
  tarball. Every function is a pure function of its arguments: nothing here shells out, reads
  the network or creates an atom from file contents. A validator returns a list of failure
  strings (empty means clean), so a caller can concatenate several and print them all.

  These are the helpers `before_catalog_manifest_test.exs` keeps as private functions
  (`sha256/1`, `git_blob_sha/1`, `read_json/1`, `exact_keys/3`, `png_header_failures/3`,
  `unreserved_emails/1`), copied with the same inputs and outputs, plus `binding_state/4`,
  which folds that test's LIVE/SUPERSEDED decision and its `superseded.json` marker check into
  one answer. The before test is left untouched (a later cleanup may switch it to these).
  """

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>
  @bundle_rel "mailglass_admin/priv/static/app.css"
  @layout_rel "mailglass_admin/lib/mailglass_admin/layouts/root.html.heex"
  @superseded_keys ~w(schema catalog_id superseded_by superseded_in reason)
  @superseded_by_keys ~w(bundle_sha256 root_layout_git_blob_sha)
  @reserved_domains ~w(example.com example.net example.org)
  @reserved_suffixes ~w(.example.com .example .local .test .invalid .localhost)

  @doc "Repo-relative path of the admin bundle every catalog is bound to."
  def bundle_rel, do: @bundle_rel

  @doc "Repo-relative path of the root layout every catalog is bound to."
  def layout_rel, do: @layout_rel

  # -- small helpers ----------------------------------------------------------------------

  @doc "One failure message when the condition is false or nil, none when it is true."
  def check(true, _message), do: []
  def check(false, message), do: [message]
  def check(nil, message), do: [message]

  @doc "Failures for a map whose key set must be exactly `keys` (the schemas are closed)."
  def exact_keys(map, keys, label) when is_map(map) do
    actual = Map.keys(map)
    unknown = actual -- keys
    missing = keys -- actual

    check(
      unknown == [],
      "#{label}: unknown key(s) #{inspect(Enum.sort(unknown))} (the schema is closed)"
    ) ++
      check(missing == [], "#{label}: missing key(s) #{inspect(Enum.sort(missing))}")
  end

  def exact_keys(_other, _keys, label), do: ["#{label} must be an object"]

  @doc "True when `value` is a lowercase hex string of exactly `length` characters."
  def hex?(value, length),
    do: is_binary(value) and Regex.match?(~r/\A[0-9a-f]{#{length}}\z/, value)

  def pos_int?(value), do: is_integer(value) and value > 0
  def non_empty?(value), do: is_binary(value) and String.trim(value) != ""
  def list(value) when is_list(value), do: value
  def list(_), do: []

  def parse_time(value) when is_binary(value), do: DateTime.from_iso8601(value)
  def parse_time(_), do: :error

  @doc "Lowercase hex sha256 of the bytes."
  def sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

  @doc """
  The blob hash `git hash-object` computes: sha1(\"blob <size>\\0\" <> bytes).
  """
  def git_blob_sha(bytes) do
    Base.encode16(:crypto.hash(:sha, ["blob ", Integer.to_string(byte_size(bytes)), 0, bytes]),
      case: :lower
    )
  end

  @doc "Reads and decodes a JSON file: `{:ok, value}` or `{:error, reason}`."
  def read_json(path) do
    case File.read(path) do
      {:ok, bytes} ->
        case Jason.decode(bytes) do
          {:ok, value} -> {:ok, value}
          {:error, error} -> {:error, {:invalid_json, Exception.message(error)}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # -- files ------------------------------------------------------------------------------

  @doc "Every non-directory entry under `dir`, as a path relative to `dir` (symlinks included)."
  def files_under(dir) do
    dir
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(fn path ->
      match?({:ok, %File.Stat{type: :directory}}, File.lstat(path))
    end)
    |> Enum.map(&Path.relative_to(&1, dir))
    |> Enum.sort()
  end

  @doc "`:ok` when `path` resolves inside `dir`, `:error` otherwise (traversal)."
  def confined(path, dir) do
    expanded = Path.expand(path)
    root = Path.expand(dir)
    if String.starts_with?(expanded, root <> "/"), do: :ok, else: :error
  end

  @doc """
  Failures for a PNG's header: signature, IHDR fields and CRC, and the width and height the
  manifest recorded (`capture` is the manifest entry with `"w"` and `"h"`).
  """
  def png_header_failures(file, bytes, capture) do
    case bytes do
      <<signature::binary-size(8), 13::unsigned-big-32, "IHDR", width::unsigned-big-32,
        height::unsigned-big-32, bit_depth, color_type, compression, filter, interlace,
        ihdr_crc::unsigned-big-32, _rest::binary>> ->
        ihdr = binary_part(bytes, 12, 17)

        check(signature == @png_signature, "#{file}: bad PNG signature") ++
          check(
            width > 0 and height > 0 and compression == 0 and filter == 0 and interlace in [0, 1] and
              bit_depth in [1, 2, 4, 8, 16] and color_type in [0, 2, 3, 4, 6],
            "#{file}: invalid PNG IHDR fields"
          ) ++
          check(:erlang.crc32(ihdr) == ihdr_crc, "#{file}: PNG IHDR checksum mismatch") ++
          check(
            width == capture["w"] and height == capture["h"],
            "#{file}: PNG IHDR is #{width}x#{height} but the manifest records #{capture["w"]}x#{capture["h"]}"
          )

      _ ->
        ["#{file}: not a PNG (invalid or incomplete IHDR header)"]
    end
  end

  # -- privacy ----------------------------------------------------------------------------

  @doc """
  Email addresses in `text` whose domain is not a reserved example domain. Screenshots and
  aria sidecars show recipient addresses, so only `example.*`, `.example`, `.test` and the like
  may appear in committed evidence.
  """
  def unreserved_emails(text) do
    ~r/[\p{L}\p{N}._%+\-]+@([\p{L}\p{N}\-]+(?:\.[\p{L}\p{N}\-]+)+)/u
    |> Regex.scan(text)
    |> Enum.reject(fn [_email, domain] ->
      domain = String.downcase(domain)
      domain in @reserved_domains or Enum.any?(@reserved_suffixes, &String.ends_with?(domain, &1))
    end)
    |> Enum.map(&hd/1)
    |> Enum.uniq()
  end

  # -- source binding ---------------------------------------------------------------------

  @doc """
  Whether a catalog manifest is bound to the checkout's current bytes (D-21, 180 D-24).

  Recomputes the sha256 of `mailglass_admin/priv/static/app.css` and the git blob sha of the root
  layout under `repo_root`, and compares them with the values the manifest recorded:

    * `:live`: both equal. The catalog describes the bytes the checkout serves.
    * `{:superseded, marker}`: either differs, and `<dir>/superseded.json` is a valid marker
      (`schema`, `catalog_id`, `superseded_by.bundle_sha256` and
      `superseded_by.root_layout_git_blob_sha` equal to the checkout's CURRENT values,
      `superseded_in`, `reason`). A marker made stale by a further change is not valid.
    * `{:unbound, reason}`: either differs and there is no valid marker, or the bundle and layout
      cannot be read. `reason` is a human-readable message naming the fix.

  Option `:superseded_schema` (default `"mailglass.after_catalog.superseded.v1"`) is the marker's
  `schema` value.
  """
  def binding_state(manifest, dir, repo_root, opts \\ []) do
    schema = Keyword.get(opts, :superseded_schema, "mailglass.after_catalog.superseded.v1")
    id = Path.basename(dir)

    with {:ok, css} <- File.read(Path.join(repo_root, @bundle_rel)),
         {:ok, layout} <- File.read(Path.join(repo_root, @layout_rel)) do
      current = %{
        bundle_sha256: sha256(css),
        bundle_blob: git_blob_sha(css),
        layout_blob: git_blob_sha(layout)
      }

      recorded_bundle = get_in(manifest, ["source", "bundle", "sha256"])
      recorded_layout = get_in(manifest, ["source", "root_layout", "git_blob_sha"])

      if current.bundle_sha256 == recorded_bundle and current.layout_blob == recorded_layout do
        {:live, current}
      else
        case marker_failures(dir, id, current, schema) do
          {:ok, marker} -> {:superseded, marker}
          {:error, reason} -> {:unbound, reason}
        end
      end
    else
      {:error, reason} ->
        {:unbound,
         "the checkout's bundle or root layout is unreadable under #{repo_root}: #{inspect(reason)}"}
    end
  end

  @doc """
  Failures for the binding of a catalog manifest to the checkout: a live catalog must agree with
  the bytes whose sha256 it records and must carry no `superseded.json`; a superseded one needs a
  current marker.
  """
  def binding_failures(manifest, dir, repo_root, opts \\ []) do
    id = Path.basename(dir)

    case binding_state(manifest, dir, repo_root, opts) do
      {:live, current} ->
        check(
          get_in(manifest, ["source", "bundle", "git_blob_sha"]) == current.bundle_blob,
          "#{id}: source.bundle.git_blob_sha disagrees with the checkout bytes whose sha256 it records"
        ) ++
          if File.exists?(Path.join(dir, "superseded.json")) do
            [
              "#{id}: superseded.json is present but the bundle and root layout equal the recorded values. Remove superseded.json: a marker on a live catalog is a false claim."
            ]
          else
            []
          end

      {:superseded, _marker} ->
        []

      {:unbound, reason} ->
        [reason]
    end
  end

  defp marker_failures(dir, id, current, schema) do
    hint =
      "Fix, either: (1) recapture under a new catalog_id with " <>
        "reference/demo_app/assets/catalog/capture-before-catalog.cjs --mode after, or (2) add or update " <>
        "#{id}/superseded.json with superseded_by " <>
        ~s|{"bundle_sha256": "#{current.bundle_sha256}", "root_layout_git_blob_sha": "#{current.layout_blob}"}| <>
        " in the same change (the catalog PNGs, cases.json, manifest.json and review stay unchanged)."

    label = "#{id}/superseded.json"

    case read_json(Path.join(dir, "superseded.json")) do
      {:error, :enoent} ->
        {:error,
         "#{id}: the admin bundle or the root layout changed since this catalog was captured " <>
           "(checkout app.css sha256 #{current.bundle_sha256}, root layout blob #{current.layout_blob}) " <>
           "and there is no superseded.json. #{hint}"}

      {:error, reason} ->
        {:error, "#{label} is unreadable (#{inspect(reason)}). #{hint}"}

      {:ok, marker} when is_map(marker) ->
        by = marker["superseded_by"]

        failures =
          exact_keys(marker, @superseded_keys, label) ++
            check(marker["schema"] == schema, "#{label}: schema must be #{schema}") ++
            check(
              marker["catalog_id"] == id,
              "#{label}: catalog_id must equal the directory name #{id}"
            ) ++
            check(
              non_empty?(marker["superseded_in"]),
              "#{label}: superseded_in must name the change that moved the bytes"
            ) ++
            check(non_empty?(marker["reason"]), "#{label}: reason must be a non-empty string") ++
            exact_keys(by, @superseded_by_keys, "#{label} superseded_by") ++
            check(
              is_map(by) and by["bundle_sha256"] == current.bundle_sha256,
              "#{label}: superseded_by.bundle_sha256 is not the checkout's current app.css sha256 #{current.bundle_sha256}"
            ) ++
            check(
              is_map(by) and by["root_layout_git_blob_sha"] == current.layout_blob,
              "#{label}: superseded_by.root_layout_git_blob_sha is not the checkout's current root layout blob #{current.layout_blob}"
            )

        if failures == [],
          do: {:ok, marker},
          else: {:error, Enum.join(failures, "; ") <> ". " <> hint}

      {:ok, _other} ->
        {:error, "#{label} must be a JSON object. #{hint}"}
    end
  end
end
