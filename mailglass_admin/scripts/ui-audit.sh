#!/usr/bin/env bash
# ui-audit.sh — ad-hoc visual audit of the admin UI via the reference demo app.
#
# Captures the full audit matrix:
#   Viewports : 390  768  1440 (px width)
#   Themes    : light  dark
#   Surfaces  : preview  deliveries  inbound
#
# Total cells: 3 viewports × 2 themes × 3 surfaces = 18 PNG files.
# PNGs are named deterministically:
#   {surface}-{viewport}-{theme}.png
#   e.g. deliveries-390-dark.png, inbound-768-light.png, preview-1440-light.png
#
# PNGs are written to a gitignored directory (tmp/ui-audit/ by default, per D-06).
# They are NEVER committed and NEVER written under priv/static/ (would trip the
# bundle gate). The matrix is the before-baseline evidence source for
# 74-GAP-REGISTER.md. Non-deterministic pixels keep this local/ad-hoc only
# (D-07) — do NOT promote to CI.
#
# State is URL-driven, so each screen/state is reproduced by URL rather than by
# driving clicks — robust even when the LiveView socket is not connected under the
# screenshot tool.
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
# agent-browser resolves screenshot paths against the browser daemon's cwd, not
# the shell's — so the output dir must be absolute or captures fail with ENOENT.
OUT="$(cd "$OUT" && pwd)"

# Viewports: 390 (mobile), 768 (tablet), 1440 (desktop). Heights are generous
# enough for --full page capture; agent-browser scrolls automatically.
VIEWPORTS="390 768 1440"
VIEWPORT_HEIGHT=900

set_viewport() { # width
  # agent-browser >=0.27: viewport is a positional `set` subcommand, not flags.
  agent-browser set viewport "$1" "$VIEWPORT_HEIGHT" >/dev/null 2>&1
}

shot() { # url, name
  agent-browser open "$1" >/dev/null 2>&1
  sleep 1
  agent-browser screenshot --full "$OUT/$2.png" 2>&1 | tail -1
}

echo "Capturing admin UI audit matrix to $OUT ..."
echo "  Viewports  : $VIEWPORTS"
echo "  Themes     : light dark"
echo "  Surfaces   : preview deliveries inbound"
echo ""

# ---------------------------------------------------------------------------
# Preview surface (dev surface) — /dev/mail/
# Trailing slash keeps relative stylesheet resolving correctly.
# Preview has no theme param in the current routing contract; capture light
# only (the theme param has no effect on this surface). Dark is included so
# the gap register can note the absence if the surface ever gains dark support.
# ---------------------------------------------------------------------------
for vp in $VIEWPORTS; do
  for theme in light dark; do
    set_viewport "$vp"
    if [ "$theme" = "dark" ]; then
      shot "$BASE/dev/mail/?theme=dark" "preview-${vp}-dark"
    else
      shot "$BASE/dev/mail/" "preview-${vp}-light"
    fi
  done
done

# ---------------------------------------------------------------------------
# Deliveries / Operator landing surface — /ops/mail/
# Enter via the demo login step to establish the demo session, then capture
# the operator landing page with tenant_id and optional theme param.
# ---------------------------------------------------------------------------

# Warm up session once (login redirect sets the demo session cookie).
agent-browser open "$BASE/demo/login?return_to=/ops/mail/?tenant_id=${TENANT}" >/dev/null 2>&1
sleep 1

for vp in $VIEWPORTS; do
  for theme in light dark; do
    set_viewport "$vp"
    if [ "$theme" = "dark" ]; then
      shot "$BASE/ops/mail/?tenant_id=${TENANT}&theme=dark" "deliveries-${vp}-dark"
    else
      shot "$BASE/ops/mail/?tenant_id=${TENANT}" "deliveries-${vp}-light"
    fi
  done
done

# ---------------------------------------------------------------------------
# Inbound surface — /ops/mail/inbound
# Session is already established from the deliveries loop above.
# ---------------------------------------------------------------------------
for vp in $VIEWPORTS; do
  for theme in light dark; do
    set_viewport "$vp"
    if [ "$theme" = "dark" ]; then
      shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}&theme=dark" "inbound-${vp}-dark"
    else
      shot "$BASE/ops/mail/inbound?tenant_id=${TENANT}" "inbound-${vp}-light"
    fi
  done
done

echo ""
echo "Done. 18 PNGs written to $OUT"
echo "Review against mailglass_admin/docs/design-system.md and 74-UI-SPEC.md."
echo "These are the before-baseline evidence for 74-GAP-REGISTER.md (gitignored, never commit)."
