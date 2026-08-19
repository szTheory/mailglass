defmodule Mailglass.Scripts.ReleasePolicyHexReleaseStateTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/release_policy_hex_release_state.sh", __DIR__)
  @checksum String.duplicate("a", 64)

  setup do
    root = Path.join(System.tmp_dir!(), "mailglass-hex-state-#{System.unique_integer([:positive])}")
    bin = Path.join(root, "bin")
    File.mkdir_p!(bin)

    curl = Path.join(bin, "curl")

    File.write!(curl, """
    #!/bin/sh
    set -eu
    [ "${FAKE_TRANSPORT_FAIL:-false}" != true ] || exit 7
    output=''
    while [ "$#" -gt 0 ]; do
      if [ "$1" = --output ]; then
        output=$2
        shift 2
      else
        shift
      fi
    done
    [ -n "$output" ]
    printf '%s' "${FAKE_BODY:-}" > "$output"
    printf '%s' "${FAKE_HTTP_STATUS:-500}"
    """)

    File.chmod!(curl, 0o755)
    on_exit(fn -> File.rm_rf!(root) end)

    {:ok, bin: bin, root: root}
  end

  test "accepts only an active exact-checksum 200 response", %{bin: bin} do
    body =
      Jason.encode!(%{
        "version" => "9.8.7",
        "retirement" => nil,
        "checksum" => @checksum
      })

    assert {"exists\n", 0} = run(bin, "200", body)
  end

  test "treats an authoritative 404 as absent", %{bin: bin} do
    assert {"absent\n", 0} = run(bin, "404", ~s({"message":"not found"}))
  end

  test "fails closed on transport errors and ambiguous HTTP responses", %{bin: bin} do
    assert {transport, transport_status} = run(bin, "000", "", transport_fail: true)
    assert transport_status != 0
    assert transport =~ "transport failed"

    assert {server, server_status} = run(bin, "500", ~s({"message":"unavailable"}))
    assert server_status != 0
    assert server =~ "HTTP 500"
  end

  test "fails closed on malformed, retired, or checksum-mismatched 200 responses", %{bin: bin} do
    hostile_bodies = [
      "not-json",
      Jason.encode!(%{
        "version" => "9.8.7",
        "retirement" => %{"reason" => "deprecated"},
        "checksum" => @checksum
      }),
      Jason.encode!(%{
        "version" => "9.8.7",
        "retirement" => nil,
        "checksum" => String.duplicate("b", 64)
      }),
      Jason.encode!(%{"version" => "9.8.6", "retirement" => nil, "checksum" => @checksum})
    ]

    Enum.each(hostile_bodies, fn body ->
      assert {output, status} = run(bin, "200", body)
      assert status != 0
      assert output =~ "retired, malformed, or checksum-mismatched"
      refute output =~ "exists\n"
    end)
  end

  test "rejects a malformed expected candidate checksum before the lookup", %{bin: bin} do
    env = [{"PATH", bin <> ":" <> System.get_env("PATH", "")}]

    assert {output, status} =
             System.cmd("bash", [@script, "mailglass", "9.8.7", "not-a-checksum"],
               env: env,
               stderr_to_stdout: true
             )

    assert status != 0
    assert output =~ "expected package checksum is malformed"
  end

  test "registry checksum is the outer package archive digest, not its CHECKSUM member", %{
    bin: bin,
    root: root
  } do
    package_root = Path.join(root, "package")
    File.mkdir_p!(package_root)
    inner = String.duplicate("c", 64)
    File.write!(Path.join(package_root, "CHECKSUM"), inner)
    archive = Path.join(root, "mailglass-9.8.7.tar")

    assert {_output, 0} =
             System.cmd("tar", ["-cf", archive, "-C", package_root, "CHECKSUM"],
               stderr_to_stdout: true
             )

    outer =
      archive |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

    refute outer == inner

    body = Jason.encode!(%{"version" => "9.8.7", "retirement" => nil, "checksum" => outer})
    assert {"exists\n", 0} = run(bin, "200", body, checksum: outer)

    assert {output, status} = run(bin, "200", body, checksum: inner)
    assert status != 0
    assert output =~ "checksum-mismatched"
  end

  defp run(bin, status, body, opts \\ []) do
    env = [
      {"PATH", bin <> ":" <> System.get_env("PATH", "")},
      {"FAKE_HTTP_STATUS", status},
      {"FAKE_BODY", body},
      {"FAKE_TRANSPORT_FAIL", to_string(Keyword.get(opts, :transport_fail, false))}
    ]

    checksum = Keyword.get(opts, :checksum, @checksum)

    System.cmd("bash", [@script, "mailglass", "9.8.7", checksum],
      env: env,
      stderr_to_stdout: true
    )
  end
end
