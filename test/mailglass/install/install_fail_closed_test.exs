defmodule Mailglass.Install.FailClosedTest do
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  # ---------------------------------------------------------------------------
  # Seed helper (D-11 / 104-RESEARCH.md seeding footgun)
  # ---------------------------------------------------------------------------
  # The bare `host_endpoint/0` skeleton (installer_fixture_helpers.ex:263-269)
  # emits only `use Phoenix.Endpoint, otp_app: :example` with NO plug at all.
  # We MUST overwrite it with a `plug Plug.Parsers` that has:
  #   - NO `body_reader` key   (so the conflict guard fires)
  #   - NO managed markers     (so the strip-then-check doesn't short-circuit)
  # Without this seed the preflight sees no unmanaged parser → tests pass
  # vacuously and Phase 104's footgun goes undetected.
  defp seed_unmanaged_parser!(fixture_root) do
    endpoint_path = Path.join(fixture_root, "lib/example_web/endpoint.ex")

    seed = """
    defmodule ExampleWeb.Endpoint do
      use Phoenix.Endpoint, otp_app: :example

      plug Plug.Parsers,
        parsers: [:urlencoded, :json],
        pass: ["*/*"],
        json_decoder: Jason
    end
    """

    File.write!(endpoint_path, seed)
  end

  # ---------------------------------------------------------------------------
  # INSTALL-01 — tuple-level assertion (D-12 / CLAUDE.md engineering DNA)
  # ---------------------------------------------------------------------------
  # Match the {:error, {:unmanaged_parser_conflict, _}} tuple DIRECTLY from
  # Apply.run/2. Do NOT route through run_install!/2 for this assertion —
  # that helper re-raises a RuntimeError embedding only inspect(reason) in the
  # message (installer_fixture_helpers.ex:41-43), which would force a fragile
  # message-string match (DNA-forbidden per D-12 / CLAUDE.md).
  test "INSTALL-01: unmanaged Plug.Parsers without body_reader returns tuple error (fail-closed)" do
    fixture_root = new_fixture_root!("fail-closed-tuple")
    seed_unmanaged_parser!(fixture_root)

    File.cd!(fixture_root, fn ->
      plan =
        Mailglass.Installer.Plan.build([], %{
          oban_available?: Mailglass.OptionalDeps.Oban.available?()
        })

      assert {:error, {:unmanaged_parser_conflict, _path}} =
               Mailglass.Installer.Apply.run(plan, [])
    end)
  end

  # ---------------------------------------------------------------------------
  # INSTALL-01 — task-level non-zero exit assertion
  # ---------------------------------------------------------------------------
  # run_install!/2 is acceptable here: the RuntimeError IT raises IS the
  # user-facing contract (Mix.raise → non-zero exit). One message assertion is
  # allowed because the message IS the contract surface (D-12 exception).
  # Assert it names the endpoint path so the error is actionable.
  test "INSTALL-01: install task raises and names endpoint path on unmanaged-parser conflict" do
    fixture_root = new_fixture_root!("fail-closed-task-exit")
    seed_unmanaged_parser!(fixture_root)

    err =
      assert_raise RuntimeError, fn ->
        run_install!(fixture_root, [])
      end

    assert String.contains?(err.message, "lib/example_web/endpoint.ex"),
           "Expected error message to name the endpoint path, got: #{err.message}"
  end

  # ---------------------------------------------------------------------------
  # INSTALL-02 — --force ordering (D-13 / 104-PATTERNS.md INSTALL-02)
  # ---------------------------------------------------------------------------
  # After --force, the installer INSERTS the managed Mailglass block ABOVE the
  # unmanaged plug Plug.Parsers. Assert ORDERING by byte index, not just success:
  #   managed_start_index < unmanaged_parsers_index
  # Then call assert_generated_artifacts_compile!/1 to catch a corrupted endpoint
  # (Landmine 5 / Pitfall 4 in RESEARCH.md).
  test "INSTALL-02: --force inserts managed parser block ABOVE unmanaged Plug.Parsers" do
    fixture_root = new_fixture_root!("fail-closed-force-ordering")
    seed_unmanaged_parser!(fixture_root)

    run_install!(fixture_root, ["--force"])

    endpoint_path = Path.join(fixture_root, "lib/example_web/endpoint.ex")
    contents = File.read!(endpoint_path)

    managed_marker = Mailglass.Installer.Templates.endpoint_webhook_block_start()

    # :binary.match/2 returns {byte_offset, length} or :nomatch
    {managed_start_idx, _} = :binary.match(contents, managed_marker)
    {unmanaged_idx, _} = :binary.match(contents, "plug Plug.Parsers")

    assert managed_start_idx < unmanaged_idx,
           "Expected managed block marker (at byte #{managed_start_idx}) " <>
             "to appear BEFORE unmanaged 'plug Plug.Parsers' (at byte #{unmanaged_idx}). " <>
             "Plug runs parsers in source order — the managed body_reader MUST win."

    assert_generated_artifacts_compile!(fixture_root)
  end
end
