#!/usr/bin/env bash
# Fail-fast network reachability guard for the installer host smoke step.
#
# The installer smoke shells out to mix phx.new / hex.pm, so an offline machine
# would otherwise fail deep inside a generator with an opaque error. This probe
# runs first and prints one actionable line pointing at the offline subset.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: preflight_network.sh

Probe outbound network reachability (hex.pm) before the installer smoke step.
Exits 0 silently on success; on failure prints one actionable line and exits 1.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

HOST="hex.pm"
PORT="443"

reachable=0

if command -v curl >/dev/null 2>&1; then
  if curl -sSfI --max-time 8 "https://${HOST}" >/dev/null 2>&1; then
    reachable=1
  fi
elif command -v nc >/dev/null 2>&1; then
  if nc -z -w 8 "$HOST" "$PORT" >/dev/null 2>&1; then
    reachable=1
  fi
elif command -v timeout >/dev/null 2>&1; then
  # Bounded raw-TCP fallback so a blackholed host fails fast rather than
  # hanging on the kernel connect timeout.
  if timeout 8 bash -c "exec 3<>/dev/tcp/${HOST}/${PORT}" >/dev/null 2>&1; then
    reachable=1
  fi
fi

if [[ "$reachable" -eq 1 ]]; then
  exit 0
fi

echo "Network is unreachable (needed to generate a throwaway Phoenix app for the installer smoke). Connect, or run mix ci.fast for the offline subset." >&2
exit 1
