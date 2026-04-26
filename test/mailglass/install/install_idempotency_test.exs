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
end
