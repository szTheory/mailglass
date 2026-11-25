defmodule Mailglass.BrandStatusMarks do
  @moduledoc false

  # Pins the five delivery-status pane marks of the brand book (Phase 182, D-10).
  #
  # The marks are not files in the pinned brand zip. They exist only as inline
  # `<svg class="stm">` fragments inside `mailglass-brand/mailglass-brand-book.html`, and
  # the book HTML must never enter this repository (test/scripts/brand_pin_test.exs forbids
  # it). So this script reads the book HTML out of the pinned zip IN MEMORY, after checking
  # the zip's sha256 against `brandbook/brand.pin.json`, extracts the one canonical shape
  # list per class, and writes only the small derived `brandbook/status-marks.json`.
  #
  # The JSON is the committed truth. The component renders from literal data copied from
  # it (mailglass_admin never reads brandbook/ at runtime; the Hex package ships lib,
  # priv/static and docs only), and phase182_status_marks_test.exs fails when they differ.
  # `verify` re-extracts and compares; it needs the network (or --zip) and is advisory,
  # like the zip byte-check of scripts/brand_pin.exs.
  #
  # Invoke as `mix run --no-start scripts/brand_status_marks.exs <extract|verify> [--zip PATH]`
  # so Jason is loaded. A local zip is hashed identically to a downloaded one.

  @repo_root Path.expand("..", __DIR__)
  @pin_rel "brandbook/brand.pin.json"
  @marks_rel "brandbook/status-marks.json"
  @book_member "mailglass-brand-book.html"
  @extracted_by "scripts/brand_status_marks.exs"
  @schema "mailglass.status_marks.v1"
  @view_box "0 0 100 120"

  @classes ~w(sent delivered delayed failed not_sent)
  @words %{
    "sent" => "Sent",
    "delivered" => "Delivered",
    "delayed" => "Delayed",
    "failed" => "Failed",
    "not_sent" => "Not sent"
  }

  # Book colour role (`--mk-<role>`) -> the admin token it binds to. These are the
  # status pairs of mailglass_admin/test/mailglass_admin/contrast_contract_test.exs.
  @roles %{
    "ink" => "text",
    "ok" => "success-text",
    "warn" => "warning-text",
    "bad" => "error-text",
    "mute" => "text-muted",
    "surf" => "surface"
  }

  # The colour each class's frame or fill carries.
  @primary_role %{
    "sent" => "ink",
    "delivered" => "ok",
    "delayed" => "warn",
    "failed" => "bad",
    "not_sent" => "mute"
  }

  @heights_px %{"row" => 20, "detail" => 44, "minimum" => 14}

  @svg_re ~r/<svg\b[^>]*\bclass="stm"[^>]*>(.*?)<\/svg>/s
  @shape_re ~r/<(rect|path)\b([^>]*?)\/?>/s
  @attr_re ~r/([A-Za-z][A-Za-z0-9_-]*)="([^"]*)"/
  @numeric_attrs ~w(x y width height stroke-width)
  @colour_attrs ~w(fill stroke)

  @help """
  Usage: mix run --no-start scripts/brand_status_marks.exs <command> [--zip PATH]

    extract [--zip PATH]
      Read the book HTML out of the pinned brand zip in memory (after checking the zip's
      sha256 against brandbook/brand.pin.json) and write brandbook/status-marks.json.
      --zip reads a local copy instead of downloading the pinned commit URL.

    verify [--zip PATH]
      Re-extract in memory and exit non-zero when the committed JSON differs. Advisory:
      it needs the network or --zip, so it never blocks a merge.

    help
      Print this text.
  """

  # ---------------------------------------------------------------------------
  # Hashing

  def sha256_hex(binary) when is_binary(binary) do
    :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)
  end

  # ---------------------------------------------------------------------------
  # Parsing the book fragments (pure)

  @doc """
  Parses every `<svg class="stm">` fragment in `html` and returns the five canonical
  shape lists, keyed by class. Each fragment is identified by its shape signature, never
  by its size or its aria-label, and every fragment of one class must carry the same
  shapes. Raises when a class has no fragment, when a fragment matches no class, or when
  two fragments of one class differ in shape.
  """
  def parse_marks(html) when is_binary(html) do
    by_class =
      @svg_re
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.map(fn [inner] -> parse_shapes(inner) end)
      |> Enum.group_by(&classify!/1)

    Map.new(@classes, fn class ->
      case Map.get(by_class, class) do
        nil ->
          raise ArgumentError, "no svg.stm fragment for class #{class}"

        variants ->
          case Enum.uniq(variants) do
            [shapes] ->
              {class, shapes}

            _differing ->
              raise ArgumentError,
                    "svg.stm fragments for class #{class} differ in shape, not only in size"
          end
      end
    end)
  end

  defp parse_shapes(inner) do
    for [tag, attrs] <- Regex.scan(@shape_re, inner, capture: :all_but_first) do
      @attr_re
      |> Regex.scan(attrs, capture: :all_but_first)
      |> Map.new(fn [name, value] -> attribute(name, value) end)
      |> Map.put("tag", tag)
    end
  end

  defp attribute(name, value) when name in @numeric_attrs do
    case Integer.parse(value) do
      {int, ""} -> {key(name), int}
      _ -> raise ArgumentError, "attribute #{name}=#{inspect(value)} is not an integer"
    end
  end

  defp attribute(name, value) when name in @colour_attrs, do: {name, colour(value)}
  defp attribute("d", value), do: {"d", value}

  defp attribute(name, _value),
    do: raise(ArgumentError, "unsupported attribute #{inspect(name)} on a status mark shape")

  defp key("stroke-width"), do: "stroke_width"
  defp key(name), do: name

  defp colour("none"), do: "none"

  defp colour("var(--mk-" <> rest) do
    role = String.replace_suffix(rest, ")", "")

    if Map.has_key?(@roles, role),
      do: role,
      else: raise(ArgumentError, "unknown book colour role #{inspect(role)}")
  end

  defp colour(other), do: raise(ArgumentError, "unsupported colour #{inspect(other)}")

  # The structural signature of each class, independent of width and height:
  #   sent       frame + a filled lower half
  #   delivered  filled pane + a three-point check
  #   delayed    frame + a stroked clock hand (open path, fill none)
  #   failed     filled pane + a four-point crack
  #   not_sent   frame + a bare strike line (no fill attribute)
  defp classify!([%{"tag" => "rect", "fill" => "none"} = frame, %{"tag" => "path"} = mark] = shapes) do
    class =
      case Map.fetch(mark, "fill") do
        {:ok, "none"} -> "delayed"
        {:ok, _filled} -> "sent"
        :error -> "not_sent"
      end

    assert_primary_role!(class, frame, shapes)
  end

  defp classify!(
         [
           %{"tag" => "rect", "fill" => fill} = pane,
           %{"tag" => "path", "fill" => "none", "d" => d}
         ] = shapes
       )
       when fill != "none" do
    case segments(d) do
      3 -> assert_primary_role!("delivered", pane, shapes)
      4 -> assert_primary_role!("failed", pane, shapes)
      n -> raise ArgumentError, "a filled pane with #{n} path points matches no status class"
    end
  end

  defp classify!(shapes),
    do: raise(ArgumentError, "svg.stm shapes match no status class: #{inspect(shapes)}")

  defp segments(d), do: d |> String.split(~r/[A-Za-z]/, trim: true) |> length()

  defp assert_primary_role!(class, %{"fill" => fill, "stroke" => stroke}, shapes) do
    expected = Map.fetch!(@primary_role, class)

    if expected in [fill, stroke] do
      class
    else
      raise ArgumentError,
            "class #{class} must use the #{expected} role, got #{inspect(shapes)}"
    end
  end

  defp assert_primary_role!(class, %{"fill" => fill}, shapes) do
    assert_primary_role!(class, %{"fill" => fill, "stroke" => nil}, shapes)
  end

  # ---------------------------------------------------------------------------
  # Extraction from the pinned zip (pure over the zip bytes and the pin map)

  @doc """
  Checks the zip's sha256 and size against the pin BEFORE reading any member, then reads
  the book HTML in memory and parses the five marks. The member name is built from the
  pin's `root`, never taken from the archive.
  """
  def extract(zip_bin, pin) when is_binary(zip_bin) and is_map(pin) do
    actual = sha256_hex(zip_bin)

    cond do
      actual != pin["sha256"] ->
        {:error, {:zip_hash_mismatch, actual}}

      byte_size(zip_bin) != pin["size"] ->
        {:error, {:zip_size_mismatch, byte_size(zip_bin)}}

      true ->
        read_book(zip_bin, pin)
    end
  end

  defp read_book(zip_bin, pin) do
    member = pin["root"] <> @book_member

    with {:ok, html} <- read_member(zip_bin, member) do
      {:ok,
       %{
         zip_sha256: sha256_hex(zip_bin),
         zip_member: member,
         member_sha256: sha256_hex(html),
         marks: parse_marks(html)
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:marks_unparseable, Exception.message(error)}}
  end

  defp read_member(zip_bin, member) do
    case :zip.zip_open(zip_bin, [:memory]) do
      {:ok, handle} ->
        try do
          case :zip.zip_get(String.to_charlist(member), handle) do
            {:ok, {_name, data}} -> {:ok, data}
            {:error, _reason} -> {:error, {:zip_member_missing, member}}
          end
        after
          :zip.zip_close(handle)
        end

      {:error, reason} ->
        {:error, {:zip_unreadable, inspect(reason)}}
    end
  end

  # ---------------------------------------------------------------------------
  # The pinned document

  @doc "Builds the status-marks document from an extraction."
  def document(%{marks: marks} = extraction) do
    %{
      "schema" => @schema,
      "source" => %{
        "pin" => @pin_rel,
        "zip_sha256" => extraction.zip_sha256,
        "zip_member" => extraction.zip_member,
        "member_sha256" => extraction.member_sha256,
        "extracted_by" => @extracted_by
      },
      "view_box" => @view_box,
      "heights_px" => @heights_px,
      "roles" => @roles,
      "marks" =>
        Map.new(@classes, fn class ->
          {class, %{"word" => Map.fetch!(@words, class), "shapes" => Map.fetch!(marks, class)}}
        end)
    }
  end

  @doc "Encodes a document with sorted keys, two-space indentation and a trailing newline."
  def encode(document) when is_map(document) do
    document |> ordered() |> Jason.encode!(pretty: true) |> Kernel.<>("\n")
  end

  defp ordered(%{} = map) do
    map
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {key, value} -> {key, ordered(value)} end)
    |> Jason.OrderedObject.new()
  end

  defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
  defp ordered(other), do: other

  @doc "Compares a committed JSON binary with a fresh document. `:ok` or `{:error, reason}`."
  def verify(committed, document) when is_binary(committed) and is_map(document) do
    if committed == encode(document),
      do: :ok,
      else: {:error, :status_marks_differ_from_pinned_book}
  end

  # ---------------------------------------------------------------------------
  # CLI

  def cli(args, getter \\ &http_get/1)

  def cli(["extract" | rest], getter) do
    with {:ok, opts} <- parse_options(rest),
         {:ok, pin} <- read_pin(),
         {:ok, zip} <- zip_bytes(pin, opts[:zip], getter),
         {:ok, extraction} <- extract(zip, pin) do
      File.write!(Path.join(@repo_root, @marks_rel), encode(document(extraction)))
      {0, "wrote #{@marks_rel} (zip sha256 #{extraction.zip_sha256})"}
    else
      {:error, reason} -> {1, "extract refused: #{format(reason)}"}
    end
  end

  def cli(["verify" | rest], getter) do
    with {:ok, opts} <- parse_options(rest),
         {:ok, pin} <- read_pin(),
         {:ok, zip} <- zip_bytes(pin, opts[:zip], getter),
         {:ok, extraction} <- extract(zip, pin),
         {:ok, committed} <- File.read(Path.join(@repo_root, @marks_rel)),
         :ok <- verify(committed, document(extraction)) do
      {0, "status marks match the pinned book"}
    else
      {:error, reason} -> {1, "verify failed: #{format(reason)}"}
    end
  end

  def cli(["help"], _getter), do: {0, String.trim_trailing(@help)}
  def cli(_other, _getter), do: {2, String.trim_trailing(@help)}

  defp parse_options(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [zip: :string])

    if rest == [] and invalid == [],
      do: {:ok, opts},
      else: {:error, "usage: <extract|verify> [--zip PATH]"}
  end

  defp read_pin do
    path = Path.join(@repo_root, @pin_rel)

    with {:ok, contents} <- File.read(path),
         {:ok, pin} when is_map(pin) <- Jason.decode(contents) do
      {:ok, pin}
    else
      _ -> {:error, "#{@pin_rel} is missing or is not a JSON object"}
    end
  end

  defp zip_bytes(_pin, path, _getter) when is_binary(path) do
    case File.read(path) do
      {:ok, bin} -> {:ok, bin}
      {:error, reason} -> {:error, "cannot read --zip #{path}: #{inspect(reason)}"}
    end
  end

  defp zip_bytes(pin, nil, getter) do
    url = pin["url"]

    if is_binary(url) and String.starts_with?(url, "https://") do
      case getter.(url) do
        {:ok, body} -> {:ok, body}
        {:error, reason} -> {:error, "could not download #{url}: #{inspect(reason)}"}
      end
    else
      {:error, "the pin url is not an https url"}
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

  defp format({:zip_hash_mismatch, actual}),
    do: "the zip's sha256 (#{actual}) does not equal the pin's; no member was read"

  defp format({:zip_size_mismatch, size}), do: "the zip is #{size} bytes, not the pinned size"
  defp format({:zip_member_missing, member}), do: "the zip has no member #{member}"
  defp format({:zip_unreadable, detail}), do: "the zip is unreadable: #{detail}"
  defp format({:marks_unparseable, detail}), do: "the book's marks did not parse: #{detail}"
  defp format(:status_marks_differ_from_pinned_book), do: "the committed JSON differs"
  defp format(reason) when is_binary(reason), do: reason
  defp format(reason), do: inspect(reason)
end

# Fail-closed entrypoint, the same shape as scripts/brand_pin.exs: the CLI runs in every Mix
# env unless a test explicitly opts into library mode.
unless Application.get_env(:mailglass, :script_library_mode, false) do
  {status, output} = Mailglass.BrandStatusMarks.cli(System.argv())
  IO.puts(output)
  if status != 0, do: System.halt(status)
end
