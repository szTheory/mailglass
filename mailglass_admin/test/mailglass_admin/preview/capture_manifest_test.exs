defmodule MailglassAdmin.Preview.CaptureManifestTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Fixtures.HappyMailer
  alias MailglassAdmin.Preview.{CaptureManifest, CaptureState}

  describe "write_from_states!/3" do
    test "writes deterministic manifest/checkpoint files with schema and claim boundary" do
      output_dir = tmp_dir("manifest")
      manifest_path = Path.join(output_dir, "manifest.json")
      checkpoint_path = Path.join(output_dir, "checkpoint.json")

      states = [
        CaptureState.new("/dev/mail", HappyMailer, :welcome_enterprise, 1024, :dark),
        CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :light)
      ]

      skipped = [%{mailable: HappyMailer, reason: :no_previews, details: nil}]

      _result =
        CaptureManifest.write_from_states!(states, skipped,
          output_dir: output_dir,
          sha_mode: :identity,
          manifest_path: manifest_path,
          checkpoint_path: checkpoint_path
        )

      assert File.exists?(manifest_path)
      assert File.exists?(checkpoint_path)

      manifest = decode!(manifest_path)
      checkpoint = decode!(checkpoint_path)

      assert manifest["schema_version"] == "preview_capture.v1"
      assert checkpoint["schema_version"] == "preview_capture.v1"

      assert manifest["claim_boundary"] ==
               "preview-pipeline confidence only; not cross-client parity"

      assert checkpoint["claim_boundary"] ==
               "preview-pipeline confidence only; not cross-client parity"

      assert checkpoint["capture_count"] == 2
      assert checkpoint["skipped_count"] == 1
    end

    test "sorts entries by deterministic identity tuple" do
      output_dir = tmp_dir("sort-order")
      manifest_path = Path.join(output_dir, "manifest.json")
      checkpoint_path = Path.join(output_dir, "checkpoint.json")

      states = [
        CaptureState.new("/dev/mail", HappyMailer, :welcome_enterprise, 1024, :dark),
        CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 768, :dark),
        CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :light)
      ]

      _result =
        CaptureManifest.write_from_states!(states, [],
          output_dir: output_dir,
          sha_mode: :identity,
          manifest_path: manifest_path,
          checkpoint_path: checkpoint_path
        )

      captures = decode!(manifest_path)["captures"]

      assert captures ==
               Enum.sort_by(captures, fn entry ->
                 {entry["mailable"], entry["scenario"], entry["width"], entry["theme"],
                  entry["path"], entry["sha256"]}
               end)
    end

    test "repeated dry-run generation produces byte-identical JSON artifacts" do
      output_dir = tmp_dir("repeatable")
      manifest_a = Path.join(output_dir, "manifest-a.json")
      checkpoint_a = Path.join(output_dir, "checkpoint-a.json")
      manifest_b = Path.join(output_dir, "manifest-b.json")
      checkpoint_b = Path.join(output_dir, "checkpoint-b.json")

      states = [
        CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 768, :dark),
        CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :light)
      ]

      skipped = [%{mailable: HappyMailer, reason: :no_previews, details: nil}]

      CaptureManifest.write_from_states!(states, skipped,
        output_dir: output_dir,
        sha_mode: :identity,
        manifest_path: manifest_a,
        checkpoint_path: checkpoint_a
      )

      CaptureManifest.write_from_states!(states, skipped,
        output_dir: output_dir,
        sha_mode: :identity,
        manifest_path: manifest_b,
        checkpoint_path: checkpoint_b
      )

      assert File.read!(manifest_a) == File.read!(manifest_b)
      assert File.read!(checkpoint_a) == File.read!(checkpoint_b)
    end

    test "actual capture hashes PNG bytes and carries candidate, route, browser, and asset provenance" do
      output_dir = tmp_dir("actual")
      manifest_path = Path.join(output_dir, "manifest.json")
      checkpoint_path = Path.join(output_dir, "checkpoint.json")
      state = CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :dark)
      png = <<137, 80, 78, 71, 13, 10, 26, 10, 0, 1, 2, 3>>
      path = CaptureManifest.screenshot_name(state)
      File.write!(Path.join(output_dir, path), png)

      provenance = actual_provenance()

      CaptureManifest.write_from_states!([state], [],
        output_dir: output_dir,
        sha_mode: :files,
        manifest_path: manifest_path,
        checkpoint_path: checkpoint_path,
        provenance: provenance
      )

      manifest = decode!(manifest_path)
      [entry] = manifest["captures"]
      assert manifest["capture_mode"] == "actual"
      assert entry["sha256"] == Base.encode16(:crypto.hash(:sha256, png), case: :lower)
      assert entry["route"] == state.url
      assert entry["candidate"] == %{"revision" => String.duplicate("a", 40), "dirty" => false}
      assert entry["browser"] == %{"name" => "Chromium", "version" => "148.0"}
      assert entry["assets"]["source"]["sha256"] == String.duplicate("b", 64)
      assert entry["assets"]["build"]["sha256"] == String.duplicate("c", 64)
      assert entry["assets"]["served"]["sha256"] == String.duplicate("d", 64)
    end

    test "actual capture rejects missing PNG files instead of using identity hashes" do
      output_dir = tmp_dir("missing-png")
      state = CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :dark)

      assert_raise ArgumentError, ~r/PNG file is unreadable/, fn ->
        CaptureManifest.build_entries([state], output_dir, :files, actual_provenance())
      end
    end

    test "actual capture rejects output paths that escape the owned directory" do
      output_dir = tmp_dir("escape")
      state = CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :dark)
      path = CaptureManifest.screenshot_name(state)
      outside = Path.join(Path.dirname(output_dir), path)
      File.write!(outside, "png")
      File.ln_s!(outside, Path.join(output_dir, path))

      assert_raise ArgumentError, ~r/inside the output directory|not a regular file/, fn ->
        CaptureManifest.build_entries([state], output_dir, :files, actual_provenance())
      end
    end

    test "actual capture requires all candidate, browser, and served-asset identity" do
      output_dir = tmp_dir("incomplete")
      state = CaptureState.new("/dev/mail", HappyMailer, :welcome_default, 375, :dark)
      File.write!(Path.join(output_dir, CaptureManifest.screenshot_name(state)), "png")
      provenance = put_in(actual_provenance(), [:assets, :served, :sha256], "")

      assert_raise ArgumentError, ~r/served asset sha256/, fn ->
        CaptureManifest.write_from_states!([state], [],
          output_dir: output_dir,
          sha_mode: :files,
          manifest_path: Path.join(output_dir, "manifest.json"),
          checkpoint_path: Path.join(output_dir, "checkpoint.json"),
          provenance: provenance
        )
      end
    end

    test "zero captures remain explicitly incomplete and dry-run entries are identity-only" do
      output_dir = tmp_dir("empty")
      manifest_path = Path.join(output_dir, "manifest.json")
      checkpoint_path = Path.join(output_dir, "checkpoint.json")

      CaptureManifest.write_from_states!([], [],
        output_dir: output_dir,
        sha_mode: :identity,
        manifest_path: manifest_path,
        checkpoint_path: checkpoint_path
      )

      manifest = decode!(manifest_path)
      assert manifest["capture_mode"] == "identity_only"
      assert manifest["captures"] == []
      assert manifest["review_complete"] == false
    end
  end

  defp actual_provenance do
    %{
      candidate: %{revision: String.duplicate("a", 40), dirty: false},
      browser: %{name: "Chromium", version: "148.0"},
      assets: %{
        source: %{path: "mailglass_admin/assets/css/app.css", sha256: String.duplicate("b", 64)},
        build: %{path: "mailglass_admin/priv/static/app.css", sha256: String.duplicate("c", 64)},
        served: %{url: "/dev/mail/css-deadbeef", sha256: String.duplicate("d", 64)}
      }
    }
  end

  defp decode!(path), do: path |> File.read!() |> Jason.decode!()

  defp tmp_dir(suffix) do
    path =
      Path.join(
        System.tmp_dir!(),
        "mailglass-admin-capture-manifest-#{suffix}-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
