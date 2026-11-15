defmodule Mailglass.Scripts.BrandStatusMarksTest do
  use ExUnit.Case, async: true

  # Hermetic by construction, the same stance as brand_pin_test.exs. The script's
  # extraction is pure over HTML and zip bytes: no test touches the network, the book HTML
  # or the pinned zip, and nothing is written under the repository tree. Fragments are
  # planted strings, zips are built in memory with :zip.create/3.
  #
  # The online re-extraction (`extract` and `verify` against the pinned zip) is advisory
  # and is recorded in the Phase 182 plan summary, like the zip byte-check of brand_pin.

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/brand_status_marks.exs")
  @marks_path Path.join(@repo_root, "brandbook/status-marks.json")
  @pin_path Path.join(@repo_root, "brandbook/brand.pin.json")

  @inner %{
    "sent" =>
      ~s|<rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-ink)" stroke-width="12"/><path d="M6 60H94V114H6Z" fill="var(--mk-ink)"/>|,
    "delivered" =>
      ~s|<rect width="100" height="120" fill="var(--mk-ok)"/><path d="M24 62L43 82L77 38" fill="none" stroke="var(--mk-surf)" stroke-width="13"/>|,
    "delayed" =>
      ~s|<rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-warn)" stroke-width="12"/><path d="M50 24V62L72 78" fill="none" stroke="var(--mk-warn)" stroke-width="12"/>|,
    "failed" =>
      ~s|<rect width="100" height="120" fill="var(--mk-bad)"/><path d="M60 0L40 48L62 68L44 120" fill="none" stroke="var(--mk-surf)" stroke-width="12"/>|,
    "not_sent" =>
      ~s|<rect x="6" y="6" width="88" height="108" fill="none" stroke="var(--mk-mute)" stroke-width="12"/><path d="M0 120L100 0" stroke="var(--mk-mute)" stroke-width="12"/>|
  }

  @sizes [{13, 16}, {37, 44}]

  @expected %{
    "sent" => [
      %{
        "tag" => "rect",
        "x" => 6,
        "y" => 6,
        "width" => 88,
        "height" => 108,
        "fill" => "none",
        "stroke" => "ink",
        "stroke_width" => 12
      },
      %{"tag" => "path", "d" => "M6 60H94V114H6Z", "fill" => "ink"}
    ],
    "delivered" => [
      %{"tag" => "rect", "width" => 100, "height" => 120, "fill" => "ok"},
      %{
        "tag" => "path",
        "d" => "M24 62L43 82L77 38",
        "fill" => "none",
        "stroke" => "surf",
        "stroke_width" => 13
      }
    ],
    "delayed" => [
      %{
        "tag" => "rect",
        "x" => 6,
        "y" => 6,
        "width" => 88,
        "height" => 108,
        "fill" => "none",
        "stroke" => "warn",
        "stroke_width" => 12
      },
      %{
        "tag" => "path",
        "d" => "M50 24V62L72 78",
        "fill" => "none",
        "stroke" => "warn",
        "stroke_width" => 12
      }
    ],
    "failed" => [
      %{"tag" => "rect", "width" => 100, "height" => 120, "fill" => "bad"},
      %{
        "tag" => "path",
        "d" => "M60 0L40 48L62 68L44 120",
        "fill" => "none",
        "stroke" => "surf",
        "stroke_width" => 12
      }
    ],
    "not_sent" => [
      %{
        "tag" => "rect",
        "x" => 6,
        "y" => 6,
        "width" => 88,
        "height" => 108,
        "fill" => "none",
        "stroke" => "mute",
        "stroke_width" => 12
      },
      %{"tag" => "path", "d" => "M0 120L100 0", "stroke" => "mute", "stroke_width" => 12}
    ]
  }

  @pin_root "mailglass-brand/"
  @member "mailglass-brand/mailglass-brand-book.html"

  setup_all do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(@script)
    :ok
  end

  defp marks(function, args), do: apply(Mailglass.BrandStatusMarks, function, args)

  # Every class at two sizes, with unrelated markup around the fragments.
  defp book(classes \\ Map.keys(@inner)) do
    fragments =
      for class <- classes, {width, height} <- @sizes do
        ~s|<svg class="stm" width="#{width}" height="#{height}" viewBox="0 0 100 120" role="img" aria-label="#{class}">#{Map.fetch!(@inner, class)}</svg>|
      end

    noise =
      ~s|<svg class="logo" width="9" height="9"><rect width="9" height="9" fill="red"/></svg><p>Sent</p>|

    "<html><body>" <> noise <> Enum.join(fragments, "\n") <> "</body></html>"
  end

  defp zip_with(entries) do
    {:ok, {_name, bin}} = :zip.create(~c"book.zip", entries, [:memory])
    bin
  end

  defp pin_for(zip_bin, overrides \\ %{}) do
    Map.merge(
      %{
        "sha256" => marks(:sha256_hex, [zip_bin]),
        "size" => byte_size(zip_bin),
        "root" => @pin_root
      },
      overrides
    )
  end

  describe "parse_marks/1" do
    test "returns the five canonical shape lists, independent of size and aria-label" do
      assert marks(:parse_marks, [book()]) == @expected
    end

    test "a fragment is identified by its shapes, never by its label or size" do
      mislabelled =
        ~s|<svg class="stm" width="99" height="99" aria-label="Failed">#{@inner["delivered"]}</svg>|

      parsed = marks(:parse_marks, [book() <> mislabelled])

      assert parsed["delivered"] == @expected["delivered"]
      assert parsed["failed"] == @expected["failed"]
    end

    test "a book missing one class raises with the class name" do
      for missing <- Map.keys(@inner) do
        html = book(Map.keys(@inner) -- [missing])

        assert_raise ArgumentError, ~r/no svg\.stm fragment for class #{missing}/, fn ->
          marks(:parse_marks, [html])
        end
      end
    end

    test "two fragments of one class that differ in shape raise" do
      drifted =
        ~s|<svg class="stm" width="17" height="20">#{String.replace(@inner["delivered"], "L77 38", "L77 39")}</svg>|

      assert_raise ArgumentError, ~r/class delivered differ in shape/, fn ->
        marks(:parse_marks, [book() <> drifted])
      end
    end

    test "an unknown colour, attribute or shape raises instead of being guessed" do
      for bad <- [
            String.replace(@inner["sent"], "var(--mk-ink)", "var(--mk-plum)"),
            String.replace(@inner["sent"], ~s|fill="none"|, ~s|fill="red"|),
            String.replace(@inner["sent"], ~s|fill="none"|, ~s|fill="none" opacity="1"|),
            ~s|<rect width="100" height="120" fill="var(--mk-ok)"/>|
          ] do
        html = ~s|<svg class="stm" width="17" height="20">#{bad}</svg>|

        assert_raise ArgumentError, fn -> marks(:parse_marks, [html]) end
      end
    end

    test "a class that uses the wrong colour role raises" do
      wrong = String.replace(@inner["failed"], "var(--mk-bad)", "var(--mk-ok)")
      html = ~s|<svg class="stm" width="17" height="20">#{wrong}</svg>|

      assert_raise ArgumentError, ~r/class failed must use the bad role/, fn ->
        marks(:parse_marks, [html])
      end
    end
  end

  describe "extract/2 refuses before it reads" do
    test "a zip whose sha256 differs from the pin is refused, with a valid book inside" do
      zip = zip_with([{String.to_charlist(@member), book()}])
      pin = pin_for(zip, %{"sha256" => String.duplicate("0", 64)})

      assert {:error, {:zip_hash_mismatch, actual}} = marks(:extract, [zip, pin])
      assert actual == marks(:sha256_hex, [zip])
    end

    test "the hash is checked before any member is read: a zip with no book still reports the hash" do
      zip = zip_with([{~c"other.txt", "x"}])
      pin = pin_for(zip, %{"sha256" => String.duplicate("f", 64)})

      assert {:error, {:zip_hash_mismatch, _}} = marks(:extract, [zip, pin])
    end

    test "a zip of the wrong size is refused" do
      zip = zip_with([{String.to_charlist(@member), book()}])

      assert {:error, {:zip_size_mismatch, size}} =
               marks(:extract, [zip, pin_for(zip, %{"size" => byte_size(zip) + 1})])

      assert size == byte_size(zip)
    end

    test "a matching zip without the book member is reported by member name" do
      zip = zip_with([{~c"other.txt", "x"}])

      assert {:error, {:zip_member_missing, @member}} = marks(:extract, [zip, pin_for(zip)])
    end

    test "a matching zip yields the marks and the member sha256, without a file written" do
      html = book()
      zip = zip_with([{String.to_charlist(@member), html}])

      assert {:ok, extraction} = marks(:extract, [zip, pin_for(zip)])
      assert extraction.marks == @expected
      assert extraction.member_sha256 == marks(:sha256_hex, [html])
      assert extraction.zip_sha256 == marks(:sha256_hex, [zip])
      assert extraction.zip_member == @member
    end

    test "a book whose marks do not parse is an error, not a crash" do
      zip = zip_with([{String.to_charlist(@member), "<html></html>"}])

      assert {:error, {:marks_unparseable, message}} = marks(:extract, [zip, pin_for(zip)])
      assert message =~ "no svg.stm fragment"
    end
  end

  describe "the pinned document" do
    test "encodes with sorted keys, two-space indentation and a trailing newline" do
      zip = zip_with([{String.to_charlist(@member), book()}])
      {:ok, extraction} = marks(:extract, [zip, pin_for(zip)])
      encoded = marks(:encode, [marks(:document, [extraction])])

      assert String.ends_with?(encoded, "}\n")
      assert String.starts_with?(encoded, "{\n  \"heights_px\"")
      assert Jason.decode!(encoded)["schema"] == "mailglass.status_marks.v1"
      assert marks(:verify, [encoded, marks(:document, [extraction])]) == :ok

      assert {:error, :status_marks_differ_from_pinned_book} =
               marks(:verify, [
                 String.replace(encoded, "M24 62", "M25 62"),
                 marks(:document, [extraction])
               ])
    end

    test "never carries the book HTML" do
      zip = zip_with([{String.to_charlist(@member), book()}])
      {:ok, extraction} = marks(:extract, [zip, pin_for(zip)])
      encoded = marks(:encode, [marks(:document, [extraction])])

      refute encoded =~ "<svg"
      refute encoded =~ "<html"
    end

    test "the script writes exactly one file, the marks JSON, and never the book" do
      source = File.read!(@script)

      assert length(Regex.scan(~r/File\.write!?\(/, source)) == 1
      assert source =~ "File.write!(Path.join(@repo_root, @marks_rel)"
    end
  end

  describe "the committed brandbook/status-marks.json" do
    setup do
      %{raw: File.read!(@marks_path), doc: @marks_path |> File.read!() |> Jason.decode!()}
    end

    test "is in canonical form: re-encoding the decoded document reproduces the bytes", %{
      raw: raw,
      doc: doc
    } do
      extraction = %{
        zip_sha256: doc["source"]["zip_sha256"],
        zip_member: doc["source"]["zip_member"],
        member_sha256: doc["source"]["member_sha256"],
        marks: Map.new(doc["marks"], fn {class, %{"shapes" => shapes}} -> {class, shapes} end)
      }

      assert marks(:encode, [marks(:document, [extraction])]) == raw
    end

    test "names the same zip the brand pin pins", %{doc: doc} do
      pin = @pin_path |> File.read!() |> Jason.decode!()

      assert doc["source"]["zip_sha256"] == pin["sha256"]
      assert doc["source"]["zip_member"] == pin["root"] <> "mailglass-brand-book.html"
      assert doc["source"]["pin"] == "brandbook/brand.pin.json"
    end

    test "sits outside every directory the brand pin owns" do
      pin = @pin_path |> File.read!() |> Jason.decode!()
      relative = Path.relative_to(@marks_path, @repo_root)

      for owned <- pin["owned_dirs"] do
        refute String.starts_with?(relative, owned <> "/"),
               "#{relative} must not live in the pin-owned directory #{owned}"
      end
    end

    test "carries the five classes with the book's words", %{doc: doc} do
      assert doc["marks"] |> Map.keys() |> Enum.sort() ==
               ~w(delayed delivered failed not_sent sent)

      assert Map.new(doc["marks"], fn {class, %{"word" => word}} -> {class, word} end) == %{
               "sent" => "Sent",
               "delivered" => "Delivered",
               "delayed" => "Delayed",
               "failed" => "Failed",
               "not_sent" => "Not sent"
             }
    end
  end
end
