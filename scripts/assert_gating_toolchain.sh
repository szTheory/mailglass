#!/bin/sh
# Assert the interpreter running this script IS the toolchain `.tool-versions`
# declares — the toolchain every gating CI lane pins.
#
# Run inside the `make toolchain` container, before the command under test.
# Without it, a future `.tool-versions` bump would leave dev/toolchain/Dockerfile
# pinned to the old line and `make toolchain` would keep reporting green for a
# toolchain nothing gates on any more: a check that cannot observe its subject
# reporting success. This fails the run instead, naming both versions and the
# one file to edit.
#
# Elixir is compared exactly (`.tool-versions` pins a patch, and CI's
# setup-beam resolves `elixir-version: "1.18"` to that same latest patch).
# Erlang is compared on the MAJOR only, because CI pins `otp-version: "27"` and
# lets setup-beam pick the patch — asserting more than CI itself pins would
# fail on a patch difference that no gating lane would ever notice.
# POSIX sh, not bash: the toolchain image's /bin/sh is dash, which has no
# `pipefail`. There are no pipelines here, so `set -eu` is the full contract.
set -eu

tool_versions="${1:-.tool-versions}"

if [ ! -f "$tool_versions" ]; then
  echo "assert_gating_toolchain: ${tool_versions} not found (run from the repo root)." >&2
  exit 1
fi

expected_elixir="$(awk '$1 == "elixir" { print $2 }' "$tool_versions")"
expected_otp_major="$(awk '$1 == "erlang" { split($2, p, "."); print p[1] }' "$tool_versions")"

if [ -z "$expected_elixir" ] || [ -z "$expected_otp_major" ]; then
  echo "assert_gating_toolchain: could not read an elixir + erlang pin from ${tool_versions}." >&2
  exit 1
fi

actual_elixir="$(elixir -e 'IO.write(System.version())')"
actual_otp_major="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')"

if [ "$actual_elixir" != "$expected_elixir" ] || [ "$actual_otp_major" != "$expected_otp_major" ]; then
  cat >&2 <<EOF
assert_gating_toolchain: this container is NOT the gating toolchain.

  declared by ${tool_versions} : Elixir ${expected_elixir} / OTP ${expected_otp_major}.x
  actually running here        : Elixir ${actual_elixir} / OTP ${actual_otp_major}.x

Refusing to run: a green result here would be evidence about a toolchain
nothing gates on. Update the FROM line in dev/toolchain/Dockerfile (and
reference/demo_app/Dockerfile, which shares the pin), then
\`make toolchain-clean\` to drop the stale build volumes.
EOF
  exit 1
fi

echo "gating toolchain confirmed: Elixir ${actual_elixir} / OTP ${actual_otp_major}.x"
