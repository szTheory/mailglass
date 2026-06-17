defmodule Mailglass.Install.MailglassDoctorTest do
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  # ---------------------------------------------------------------------------
  # INSTALL-03: Webhook-wiring doctor — summary→exit mapping
  #
  # These tests target the CONTRACT:
  #   Mailglass.Installer.Doctor.run(opts) ::
  #     %{summary: %{pass: n, warn: n, fail: n, cannot_diagnose: n}, findings: [...]}
  #
  # The Mailglass.Installer.Doctor module is created in Plan 02 — these tests
  # are RED on creation (UndefinedFunctionError) and turn GREEN when Plan 02 lands.
  #
  # Each test calls the runner inside File.cd!(fixture_root, fn -> ... end) so
  # that Mailglass.Installer.Plan.detect_otp_app/0 and the relative
  # lib/example_web/endpoint.ex path both resolve against the fixture (D-14).
  #
  # Summary→exit mapping (the doctor mix task's exit_code/2):
  #   cannot_diagnose > 0  → exit 2   (endpoint.ex missing / app not detectable)
  #   fail > 0             → exit 1   (CachingBodyReader absent — the CI non-zero signal)
  #   else                 → exit 0   (wired correctly)
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # INSTALL-03 wired → exit 0
  # ---------------------------------------------------------------------------
  # Run the installer against a fresh fixture (it wires the managed
  # CachingBodyReader block into endpoint.ex), then assert the doctor sees
  # no failures and no cannot_diagnose findings (maps to exit 0).
  test "INSTALL-03: wired endpoint — doctor summary maps to exit 0" do
    fixture_root = new_fixture_root!("doctor-wired")
    run_install!(fixture_root, [])

    summary =
      File.cd!(fixture_root, fn ->
        Mailglass.Installer.Doctor.run([])
      end).summary

    assert summary.fail == 0,
           "Expected no failures for a wired endpoint, got fail=#{summary.fail}"

    assert Map.get(summary, :cannot_diagnose, 0) == 0,
           "Expected cannot_diagnose=0 for a wired endpoint, got #{Map.get(summary, :cannot_diagnose, 0)}"
  end

  # ---------------------------------------------------------------------------
  # INSTALL-03 unwired → exit 1
  # ---------------------------------------------------------------------------
  # Use a fresh fixture WITHOUT running the installer (endpoint.ex exists but
  # has only `use Phoenix.Endpoint, otp_app: :example` — no managed block, no
  # body_reader). The doctor should detect that CachingBodyReader is absent and
  # report at least one :fail finding (maps to exit 1).
  test "INSTALL-03: unwired endpoint (no CachingBodyReader) — doctor summary maps to exit 1" do
    fixture_root = new_fixture_root!("doctor-unwired")
    # Do NOT run install — endpoint.ex is the bare skeleton with no parser wired

    summary =
      File.cd!(fixture_root, fn ->
        Mailglass.Installer.Doctor.run([])
      end).summary

    assert summary.fail > 0,
           "Expected at least one fail finding for an unwired endpoint, got fail=#{summary.fail}"

    assert Map.get(summary, :cannot_diagnose, 0) == 0,
           "Expected cannot_diagnose=0 when endpoint.ex exists, got #{Map.get(summary, :cannot_diagnose, 0)}"
  end

  # ---------------------------------------------------------------------------
  # INSTALL-03 cannot-diagnose → exit 2
  # ---------------------------------------------------------------------------
  # Delete lib/example_web/endpoint.ex so the static scan cannot find it.
  # The doctor should report a cannot_diagnose finding (maps to exit 2 — distinct
  # from exit 1 so CI can distinguish "wiring broken" from "can't see the file").
  test "INSTALL-03: missing endpoint.ex — doctor summary maps to exit 2 (cannot_diagnose)" do
    fixture_root = new_fixture_root!("doctor-cannot-diagnose")
    endpoint_path = Path.join(fixture_root, "lib/example_web/endpoint.ex")
    File.rm!(endpoint_path)

    summary =
      File.cd!(fixture_root, fn ->
        Mailglass.Installer.Doctor.run([])
      end).summary

    assert Map.get(summary, :cannot_diagnose, 0) > 0,
           "Expected cannot_diagnose > 0 when endpoint.ex is missing, " <>
             "got cannot_diagnose=#{Map.get(summary, :cannot_diagnose, 0)}"
  end
end
