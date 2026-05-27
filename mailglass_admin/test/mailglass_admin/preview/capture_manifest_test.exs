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
      assert manifest["claim_boundary"] == "preview-pipeline confidence only; not cross-client parity"
      assert checkpoint["claim_boundary"] == "preview-pipeline confidence only; not cross-client parity"
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
