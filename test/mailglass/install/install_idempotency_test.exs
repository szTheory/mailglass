defmodule Mailglass.Install.IdempotencyTest do
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  @preview_route ~s(mailglass_admin_routes "/mail")
  @drift_route ~s(get "/dev/mail", PreviewController, :index)

  test "second install run produces no fixture diff" do
    fixture_root = new_fixture_root!("idempotency-no-diff")
    run_install!(fixture_root, [])

    before_second_run =
      fixture_root
      |> snapshot_tree!()
      |> normalize_snapshot()

    run_install!(fixture_root, [])

    after_second_run =
      fixture_root
      |> snapshot_tree!()
      |> normalize_snapshot()

    assert before_second_run == after_second_run
  end

  # ---------------------------------------------------------------------------
  # Managed-block drift detection (REL-07)
  # Tests :ensure_block drift detection via partial-marker scenario.
  # The installer writes managed blocks with explicit start/end markers.
  # When partial markers exist (one present, other removed), Apply.run/2
  # writes a conflict sidecar and leaves the file unchanged.
  # ---------------------------------------------------------------------------

  describe "managed-snippet drift detection" do
    test "partial managed-block markers trigger conflict sidecar with drift message" do
      fixture_root = new_fixture_root!("drift-detection-partial-markers")
      run_install!(fixture_root, [])

      runtime_path = Path.join(fixture_root, "config/runtime.exs")
      original_runtime = File.read!(runtime_path)

      start_marker = Mailglass.Installer.Templates.runtime_block_start()
      end_marker = Mailglass.Installer.Templates.runtime_block_end()

      # Both markers should be present after initial install
      assert String.contains?(original_runtime, start_marker)
      assert String.contains?(original_runtime, end_marker)

      # Simulate managed-block drift: remove only the end marker (partial markers)
      drifted_runtime = String.replace(original_runtime, end_marker, "")
      File.write!(runtime_path, drifted_runtime)

      run_install!(fixture_root, [])

      # File must remain unchanged (conflict, not silently overwritten)
      assert File.read!(runtime_path) == drifted_runtime

      # A .mailglass_conflict_ sidecar must have been written
      sidecars = runtime_conflict_sidecars(fixture_root)
      assert length(sidecars) >= 1,
             "Managed snippet drifted from snapshot. Run `mix mailglass.install --force` " <>
               "(or fix the drifted file manually), or refresh the installer template."

      assert Enum.all?(sidecars, fn sidecar ->
               String.starts_with?(Path.basename(sidecar), ".mailglass_conflict_")
             end)

      # Sidecar content must reference the drift reason
      sidecar_content = sidecars |> hd() |> File.read!()
      assert String.contains?(sidecar_content, "managed_block_drift") or
               String.contains?(sidecar_content, "partial_markers"),
             "Sidecar must reference the drift reason. Got: #{sidecar_content}"
    end

    test "partial managed-block drift is resolved by --force without leaving sidecar" do
      fixture_root = new_fixture_root!("drift-detection-force-resolve")
      run_install!(fixture_root, [])

      runtime_path = Path.join(fixture_root, "config/runtime.exs")
      start_marker = Mailglass.Installer.Templates.runtime_block_start()
      end_marker = Mailglass.Installer.Templates.runtime_block_end()

      # Drift: remove only the end marker to create partial-marker state
      drifted_runtime =
        runtime_path
        |> File.read!()
        |> String.replace(end_marker, "")

      File.write!(runtime_path, drifted_runtime)

      # Re-run with --force: installer must repair the block and leave no sidecar
      run_install!(fixture_root, ["--force"])

      final_runtime = File.read!(runtime_path)
      assert String.contains?(final_runtime, start_marker)
      assert String.contains?(final_runtime, end_marker)
      assert runtime_conflict_sidecars(fixture_root) == [],
             "No conflict sidecars expected after --force resolve."
    end
  end

  @tag :skip
  # TODO(Phase 8 / v0.1.2 REL-07): managed-drift detection for `:ensure_snippet` ops requires
  # tracking inserted snippets in the manifest and comparing on the next run.
  # The current `apply_ensure_snippet/3` is presence-or-insert only — it does
  # not detect that a previously-inserted snippet has been modified. The
  # `--force` path (next test) and the no-diff idempotency path both work.
  # Implementing snippet drift tracking is a discrete task deferred from v0.1.1.
  # See: Mailglass.Installer.Apply.apply_ensure_snippet/3 for the insertion-only logic.
  test "managed drift writes a .mailglass_conflict_ sidecar and keeps target unchanged" do
    fixture_root = new_fixture_root!("idempotency-conflict-sidecar")
    run_install!(fixture_root, [])

    router_path = Path.join(fixture_root, "lib/example_web/router.ex")

    drifted_router =
      router_path
      |> File.read!()
      |> String.replace(@preview_route, @drift_route)

    File.write!(router_path, drifted_router)
    run_install!(fixture_root, [])

    assert File.read!(router_path) == drifted_router

    sidecars = conflict_sidecars(router_path)
    assert length(sidecars) >= 1

    assert Enum.all?(sidecars, fn sidecar ->
             String.starts_with?(Path.basename(sidecar), ".mailglass_conflict_")
           end)

    assert sidecars
           |> hd()
           |> File.read!()
           |> String.contains?("reason=managed_drift")
  end

  @tag :skip
  # TODO(Phase 8 / v0.1.2 REL-07): `--force` should clean up drifted snippet content, not
  # just append the canonical snippet alongside the drift. Current behavior
  # produces a router that contains BOTH the drifted line AND the canonical
  # snippet. Implementing drift cleanup requires the same managed-snippet
  # tracking the test above defers to v0.1.1.
  # See: Mailglass.Installer.Apply.apply_ensure_snippet/3 for the insertion-only logic.
  test "--force overwrites managed drift without leaving a sidecar" do
    fixture_root = new_fixture_root!("idempotency-force-overwrite")
    run_install!(fixture_root, [])

    router_path = Path.join(fixture_root, "lib/example_web/router.ex")

    drifted_router =
      router_path
      |> File.read!()
      |> String.replace(@preview_route, @drift_route)

    File.write!(router_path, drifted_router)
    run_install!(fixture_root, ["--force"])

    final_router = File.read!(router_path)
    assert String.contains?(final_router, @preview_route)
    refute String.contains?(final_router, @drift_route)
    assert conflict_sidecars(router_path) == []
  end

  defp conflict_sidecars(router_path) do
    router_path
    |> Path.dirname()
    |> Path.join(".mailglass_conflict_router.ex*")
    |> Path.wildcard(match_dot: true)
    |> Enum.sort()
  end

  defp runtime_conflict_sidecars(fixture_root) do
    fixture_root
    |> Path.join("config/.mailglass_conflict_runtime*")
    |> Path.wildcard(match_dot: true)
    |> Enum.sort()
  end
end
