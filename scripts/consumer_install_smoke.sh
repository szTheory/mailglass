#!/usr/bin/env bash
#
# Consumer-install smoke — the canonical "does a fresh adopter install actually
# work" gate. Generates a fresh Phoenix host, installs mailglass, guards OPS-01,
# compiles with --warnings-as-errors, boots the endpoint, and asserts
# GET /dev/mail/ == 200.
#
# Parameterized by DEP_MODE so ONE body backs two callers:
#   * DEP_MODE=path — PR-time CI against the working tree (local path deps).
#                     Catches codegen/compile/runtime/boot regressions BEFORE
#                     merge. Requires MAILGLASS_PATH (repo root).
#   * DEP_MODE=hex  — post-publish smoke against published Hex versions.
#                     Requires VERSION; optional VERSION_INBOUND + INCLUDE_INBOUND.
#
# Optional: WORK_DIR (defaults to a fresh mktemp dir) — where `sandbox/` is built.
#
# The repo-local fast guard (test/mailglass/install/install_compile_test.exs)
# parses/compiles each generated artifact in-process; THIS script is the full
# real-compile + boot integration backstop.
set -euo pipefail

DEP_MODE="${DEP_MODE:-path}"
WORK_DIR="${WORK_DIR:-$(mktemp -d)}"
SANDBOX="${WORK_DIR}/sandbox"

mkdir -p "${WORK_DIR}"

echo "==> consumer-install smoke (DEP_MODE=${DEP_MODE}, WORK_DIR=${WORK_DIR})"

mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force

rm -rf "${SANDBOX}"
( cd "${WORK_DIR}" && mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install )

cd "${SANDBOX}"

# --- inject the mailglass deps into the generated host mix.exs -----------------
# Build the entries inside Elixir (no fragile shell \n escaping); the values come
# in via env so both modes share one regex insertion after `defp deps do\n  [`.
DEP_MODE="${DEP_MODE}" \
MAILGLASS_PATH="${MAILGLASS_PATH:-}" \
VERSION="${VERSION:-}" \
VERSION_INBOUND="${VERSION_INBOUND:-}" \
INCLUDE_INBOUND="${INCLUDE_INBOUND:-false}" \
elixir -e '
  entries =
    case System.get_env("DEP_MODE") do
      "path" ->
        mg = System.get_env("MAILGLASS_PATH") || raise "path mode requires MAILGLASS_PATH"
        ~s(      {:mailglass, path: "#{mg}", override: true},\n) <>
          ~s(      {:mailglass_admin, path: "#{mg}/mailglass_admin"},\n) <>
          ~s(      {:mailglass_inbound, path: "#{mg}/mailglass_inbound"},\n)

      "hex" ->
        v = System.get_env("VERSION") || raise "hex mode requires VERSION"
        vi = System.get_env("VERSION_INBOUND") || ""

        inbound =
          if System.get_env("INCLUDE_INBOUND") == "true" and vi != "" do
            ~s(      {:mailglass_inbound, "== #{vi}"},\n)
          else
            ""
          end

        ~s(      {:mailglass, "== #{v}"},\n) <> ~s(      {:mailglass_admin, "== #{v}"},\n) <> inbound

      other ->
        raise "unknown DEP_MODE: #{inspect(other)}"
    end

  content = File.read!("mix.exs")
  updated = String.replace(content, ~r/(defp deps do\n\s*\[\n)/, "\\1" <> entries, global: false)
  File.write!("mix.exs", updated)
'
grep -F "mailglass" mix.exs

mix deps.get

# --- install -------------------------------------------------------------------
mix mailglass.install

# --- OPS-01 guard: a fresh --no-mailer install must stay HTTP-client-agnostic --
if ! grep -F "config :swoosh, :api_client, false" config/runtime.exs; then
  echo "OPS-01 failed: generated runtime.exs is missing config :swoosh, :api_client, false."
  exit 1
fi
if grep -Eq '^[[:space:]]*config :swoosh, :api_client, Swoosh\.ApiClient\.Finch([[:space:]]|$)' config/runtime.exs; then
  echo "OPS-01 failed: generated runtime.exs contains an uncommented Swoosh.ApiClient.Finch line."
  exit 1
fi
if grep -Eq '"(hackney|finch)":' mix.lock; then
  echo "OPS-01 failed: fresh --no-mailer install resolved hackney or finch in mix.lock."
  exit 1
fi
echo "OPS-01 guard passed."

# --- compile (warnings are errors) ---------------------------------------------
mix compile --warnings-as-errors 2>&1 | tee compile.log
if grep -F "UndefinedFunctionError" compile.log; then
  echo "Smoke failed: UndefinedFunctionError detected in compile output."
  exit 1
fi

# --- boot endpoint and curl /dev/mail/ -----------------------------------------
MIX_ENV=dev mix phx.server &
SERVER_PID=$!
# shellcheck disable=SC2064
trap "kill ${SERVER_PID} 2>/dev/null || true" EXIT

DEADLINE=$(( SECONDS + 30 ))
until curl -fsI http://localhost:4000/dev/mail/ >/dev/null 2>&1; do
  if [ "${SECONDS}" -ge "${DEADLINE}" ]; then
    echo "Smoke failed: endpoint did not respond on /dev/mail/ within 30s."
    exit 1
  fi
  sleep 2
done

STATUS=$(curl -fs -o /dev/null -w "%{http_code}" http://localhost:4000/dev/mail/)
echo "GET /dev/mail/ -> HTTP ${STATUS}"
if [ "${STATUS}" != "200" ]; then
  echo "Smoke failed: /dev/mail/ returned ${STATUS}, expected 200."
  exit 1
fi
echo "Endpoint smoke passed."
