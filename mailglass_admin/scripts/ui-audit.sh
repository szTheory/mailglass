#!/usr/bin/env bash
# ui-audit.sh — ad-hoc visual audit of the admin UI via the reference demo app.
#
# Walks the admin surfaces × theme and captures screenshots to a gitignored
# tmp/ui-audit/ for review (eyeball them, or hand them to a multimodal model
# with docs/design-system.md as the rubric). State is URL-driven, so each
# screen/state is reproduced by URL rather than by driving clicks — robust even
# when the LiveView socket is not connected under the screenshot tool.
#
# Prereqs: the agent-browser CLI on PATH, a Postgres reachable by the demo app,
# and the reference demo app booted on $PORT with seeded data:
#
#   cd reference/demo_app
#   mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs
#   mix phx.server   # binds the dev port (default 4015)
#
# Then, from the repo root:  mailglass_admin/scripts/ui-audit.sh
set -euo pipefail

PORT="${PORT:-4015}"
BASE="http://localhost:${PORT}"
TENANT="${TENANT:-northstar}"
OUT="${AGENT_BROWSER_SCREENSHOT_DIR:-tmp/ui-audit}"
mkdir -p "$OUT"

shot() { # url, name
  agent-browser open "$1" >/dev/null 2>&1
  sleep 1
  agent-browser screenshot --full "$OUT/$2.png" 2>&1 | tail -1
}

echo "Capturing admin UI screenshots to $OUT ..."

# Preview (dev surface) — enter at the mount root (trailing slash keeps the
# relative stylesheet resolving). Then a concrete scenario by URL.
shot "$BASE/dev/mail/" "preview-start"

# Operator surface — log in (sets the demo session), land on deliveries.
shot "$BASE/demo/login?return_to=/ops/mail/?tenant_id=${TENANT}" "operator-landing"
shot "$BASE/ops/mail/?tenant_id=${TENANT}&theme=dark" "operator-landing-dark"
shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}" "inbound"
shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}&theme=dark" "inbound-dark"

echo "Done. Review the PNGs in $OUT against docs/design-system.md."
