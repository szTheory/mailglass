#!/usr/bin/env bash
# Fail-fast Postgres reachability guard for the mix ci / ci.setup aliases.
#
# Runs BEFORE any ecto/DB task so an unreachable database produces one clear,
# actionable line instead of a raw DBConnection stacktrace. Uses the same env
# the CI/ecto tasks use so local and CI resolve the same host:port.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: preflight_postgres.sh

Probe whether Postgres is reachable before the alias reaches a DB task.
Reads POSTGRES_HOST (default localhost), POSTGRES_PORT (default 5432),
POSTGRES_USER (default postgres). Exits 0 silently on success; on failure
prints one actionable line and exits 1.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

HOST="${POSTGRES_HOST:-localhost}"
PORT="${POSTGRES_PORT:-5432}"
USER="${POSTGRES_USER:-postgres}"

reachable=0

if command -v pg_isready >/dev/null 2>&1; then
  if pg_isready -h "$HOST" -p "$PORT" -U "$USER" -t 5 >/dev/null 2>&1; then
    reachable=1
  fi
else
  # No pg_isready — fall back to a bounded TCP probe on the Postgres port.
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w 5 "$HOST" "$PORT" >/dev/null 2>&1; then
      reachable=1
    fi
  elif (exec 3<>"/dev/tcp/$HOST/$PORT") 2>/dev/null; then
    reachable=1
    exec 3>&- 3<&- 2>/dev/null || true
  fi
fi

if [[ "$reachable" -eq 1 ]]; then
  exit 0
fi

echo "Postgres isn't reachable at ${HOST}:${PORT}. Start it, or set POSTGRES_HOST / POSTGRES_PORT." >&2
exit 1
