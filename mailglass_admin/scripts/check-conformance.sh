#!/usr/bin/env bash
# Fail CI if any design-system violation appears in mailglass_admin/lib/*.ex files.
# Design-system conformance check — initial gate definitions committed at Phase 76-06.
# Sources: VERIF-03 (Phase 79), D-07 (single source of truth for visual decisions).
# Gate patterns from 76-06-SUMMARY.md: five greps that confirmed zero violations on
# the Phase 76 codebase. All gates scope to .ex files only (HEEx lives in LiveView modules;
# no .heex partials exist in this codebase).
#
# Footgun-6 exclusion (TYPE-GATE): text-base-content is a DaisyUI semantic color token
# (base-content text color), not a raw type-scale utility. Without the exclusion, every
# file using text-base-content produces a false failure on the text-base pattern.

set -euo pipefail

# Resolve LIB relative to this script's own location, not the caller's cwd.
# mailglass_admin is its own Hex package; its CI lane may run with cwd at the
# package root (mailglass_admin/) rather than the monorepo root. A cwd-relative
# path would resolve to a non-existent dir, grep would print to the swallowed
# stderr and exit non-zero, no error would be counted, and the script would
# print "clean" while scanning zero files (WR-02). Anchoring to BASH_SOURCE and
# asserting the dir exists makes the gate cwd-independent and fail-loud.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
errors=0
COMPONENTS="${LIB}/mailglass_admin/components.ex"
GALLERY="${LIB}/mailglass_admin/gallery_live.ex"
OPERATOR_LIVE="${LIB}/mailglass_admin/operator_live.ex"
INBOUND_LIVE="${LIB}/mailglass_admin/inbound_live.ex"
INBOUND_OVERVIEW="${LIB}/mailglass_admin/inbound/overview.ex"
DELIVERIES_LIST="${LIB}/mailglass_admin/operator/deliveries_list.ex"
RECORDS_LIST="${LIB}/mailglass_admin/inbound/records_list.ex"
HEROICONS="${SCRIPT_DIR}/../assets/vendor/heroicons-inline.js"
APP_CSS="${SCRIPT_DIR}/../assets/css/app.css"

# PRIMITIVE-DRIFT-GATE: the named Phase 110 primitives have exactly one public
# implementation in Components. Shell and GalleryLive must consume those public
# functions instead of restoring private helpers or copied HEEx bodies.
private_primitive_hits="$(
  grep -rEn 'defp[[:space:]]+(nav_link|nav_pill|tenant_chip|theme_toggle|theme_picker|stat_card)([[:space:]]|\()|def[[:space:]]+(theme_toggle)([[:space:]]|\()' "$LIB" --include="*.ex" 2>/dev/null |
    grep -vF "${COMPONENTS}:" || true
)"
if [[ -n "$private_primitive_hits" ]]; then
  echo "$private_primitive_hits"
  echo "FAIL: PRIMITIVE-DRIFT-GATE — private primitive helper found; route through MailglassAdmin.Components" >&2
  errors=$((errors + 1))
fi

if grep -rEn 'theme_toggle|component: :theme_toggle|gallery-theme_toggle' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: PRIMITIVE-DRIFT-GATE — old binary theme_toggle identity found; use theme_picker" >&2
  errors=$((errors + 1))
fi

for primitive in nav_link nav_pill tenant_chip theme_picker stat_card; do
  if ! grep -qE "^[[:space:]]*def[[:space:]]+${primitive}\\(" "$COMPONENTS" 2>/dev/null; then
    echo "FAIL: PRIMITIVE-DRIFT-GATE — Components.${primitive}/1 public definition missing" >&2
    errors=$((errors + 1))
  fi

  if ! awk -v primitive="$primitive" '
    $0 ~ ("defp render_specimen\\(%\\{component: :" primitive "\\}") { in_block=1; seen=0; next }
    in_block && $0 ~ ("Components\\." primitive) { seen=1 }
    in_block && /^  defp render_specimen/ { exit seen ? 0 : 1 }
    END { exit seen ? 0 : 1 }
  ' "$GALLERY"; then
    echo "FAIL: PRIMITIVE-DRIFT-GATE — GalleryLive ${primitive} dispatcher must call Components.${primitive}/1" >&2
    errors=$((errors + 1))
  fi
done

# card/1 is the single public thin group-surface shell (Phase 114, D-01/D-02). It is
# enforced as a PRIMITIVE-DRIFT primitive but — unlike the Phase 110 primitives — does
# NOT get the per-primitive gallery render_specimen awk assertion: composed group specimens
# (plan 02) register differently from the single-primitive gallery dispatchers above.
if ! grep -qE '^[[:space:]]*def[[:space:]]+card\(' "$COMPONENTS" 2>/dev/null; then
  echo "FAIL: PRIMITIVE-DRIFT-GATE — Components.card/1 public definition missing" >&2
  errors=$((errors + 1))
fi

old_primitive_signature_hits="$(
  grep -rEn 'mg-focus-ring flex min-h-11 items-center gap-sm rounded-field border-l-2 px-sm text-body transition-colors ease-out duration-\(--duration-fast\)|mg-focus-ring flex min-h-11 items-center rounded-field px-sm text-body transition-colors ease-out duration-\(--duration-fast\)|inline-flex min-h-11 items-center gap-xs rounded-field border border-base-300 px-sm text-label text-secondary|btn btn-ghost btn-sm btn-square min-h-11"' "$LIB" --include="*.ex" 2>/dev/null |
    grep -vF "${COMPONENTS}:" || true
)"
if [[ -n "$old_primitive_signature_hits" ]]; then
  echo "$old_primitive_signature_hits"
  echo "FAIL: PRIMITIVE-DRIFT-GATE — old copied primitive class signature found outside Components" >&2
  errors=$((errors + 1))
fi

# FORM-DRIFT-GATE: Phase 111 filter wrappers must stay thin and continue routing
# through the shared public primitives. This gate is scoped to the two wrapper
# files so legitimate forms elsewhere in the app remain allowed.
FILTER_WRAPPERS=(
  "${LIB}/mailglass_admin/operator/filters_form.ex"
  "${LIB}/mailglass_admin/inbound/filters_form.ex"
)

if ! grep -qE '^[[:space:]]*def[[:space:]]+filter_field\(' "$COMPONENTS" 2>/dev/null; then
  echo "FAIL: FORM-DRIFT-GATE — Components.filter_field/1 public definition missing" >&2
  errors=$((errors + 1))
fi
if ! grep -qE '^[[:space:]]*def[[:space:]]+filter_section\(' "$COMPONENTS" 2>/dev/null; then
  echo "FAIL: FORM-DRIFT-GATE — Components.filter_section/1 public definition missing" >&2
  errors=$((errors + 1))
fi

for wrapper in "${FILTER_WRAPPERS[@]}"; do
  if [[ ! -f "$wrapper" ]]; then
    echo "FAIL: FORM-DRIFT-GATE — wrapper file missing at $wrapper" >&2
    errors=$((errors + 1))
    continue
  fi

  if ! grep -q 'Components.filter_field' "$wrapper"; then
    echo "FAIL: FORM-DRIFT-GATE — ${wrapper##*/} must call Components.filter_field/1" >&2
    errors=$((errors + 1))
  fi
  if ! grep -q 'Components.filter_section' "$wrapper"; then
    echo "FAIL: FORM-DRIFT-GATE — ${wrapper##*/} must call Components.filter_section/1" >&2
    errors=$((errors + 1))
  fi
  if grep -En '<(label|input|select|textarea)\b|text-label font-bold text-base-content|text-label text-secondary|input input-bordered input-sm|select select-bordered select-sm|grid gap-xs|grid gap-sm md:grid-cols-2' "$wrapper" >/dev/null 2>&1; then
    echo "FAIL: FORM-DRIFT-GATE — ${wrapper##*/} contains direct filter-control markup or old class signatures" >&2
    errors=$((errors + 1))
  fi
done

# STATCARD-GATE: overview KPI/stat cards must consume Components.stat_card/1.
# This catches page-local stat helpers and the old raw card shapes that allowed
# wrapped values or bare dash placeholders.
if ! grep -q 'Components.stat_card' "$OPERATOR_LIVE" 2>/dev/null; then
  echo "FAIL: STATCARD-GATE — operator overview must use Components.stat_card/1" >&2
  errors=$((errors + 1))
fi
if ! grep -q 'Components.stat_card' "$INBOUND_OVERVIEW" 2>/dev/null; then
  echo "FAIL: STATCARD-GATE — inbound overview must use Components.stat_card/1" >&2
  errors=$((errors + 1))
fi
if grep -rEn 'defp[[:space:]]+stat\(' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: STATCARD-GATE — private defp stat helper found; route through Components.stat_card/1" >&2
  errors=$((errors + 1))
fi
if grep -En 'class="card bg-base-200 border border-base-300 rounded-box p-md">|text-display font-bold|do: "—"|break-words|<\.stat' "$OPERATOR_LIVE" "$INBOUND_OVERVIEW" 2>/dev/null; then
  echo "FAIL: STATCARD-GATE — old raw stat-card shape found in overview source" >&2
  errors=$((errors + 1))
fi

# ICON-EXISTS-GATE: every hero-* class referenced from admin lib sources must
# have a matching key in the vendored standalone Heroicons plugin.
[[ -f "$HEROICONS" ]] || { echo "FAIL: ICON-EXISTS-GATE — heroicons-inline.js missing at $HEROICONS" >&2; exit 2; }
used_icons="$(mktemp)"
available_icons="$(mktemp)"
missing_icons="$(mktemp)"
trap 'rm -f "$used_icons" "$available_icons" "$missing_icons"' EXIT

grep -rhoE 'hero-[a-z0-9-]+' "$LIB" --include="*.ex" 2>/dev/null |
  sed 's/^hero-//' |
  sort -u > "$used_icons"

# IN-03: distinguish "this lib genuinely uses zero icons" from "the scan found
# nothing because the path/cwd was wrong". grep exits non-zero on zero matches
# and the pipe masks that exit under `set -euo pipefail`, so an empty used_icons
# would otherwise read as "no missing icons" and pass vacuously. The admin lib
# always references hero-* icons, so an empty result is a scan/path error, not a
# legitimately icon-free lib — fail loud.
[[ -s "$used_icons" ]] || {
  echo "FAIL: ICON-EXISTS-GATE — zero hero-* usages scanned in $LIB (path/scan error, not an icon-free lib)" >&2
  exit 2
}

grep -E '^[[:space:]]*"[-a-z0-9]+":' "$HEROICONS" 2>/dev/null |
  sed -E 's/^[[:space:]]*"([-a-z0-9]+)".*/\1/' |
  sort -u > "$available_icons"

comm -23 "$used_icons" "$available_icons" > "$missing_icons"
if [[ -s "$missing_icons" ]]; then
  echo "Missing vendored Heroicons:"
  sed 's/^/  hero-/' "$missing_icons"
  echo "FAIL: ICON-EXISTS-GATE — admin hero-* usage is absent from heroicons-inline.js" >&2
  errors=$((errors + 1))
fi

# BADGE-GATE: defp badge_class must not exist anywhere in lib/.
# Components.status_badge/1 is the single canonical status→color definition (Phase 76-02).
# Any private badge_class helper is a divergence point and must be routed through it.
if grep -rE 'defp badge_class' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BADGE-GATE — defp badge_class found; route through Components.status_badge/1" >&2
  errors=$((errors + 1))
fi

# TYPE-GATE: raw Tailwind type-scale utilities in HEEx
# (text-sm, text-base, text-xs, text-xl, text-2xl, text-3xl).
# Use semantic tokens instead: text-label (12px), text-body (14px), text-heading (20px),
# text-display (28px) — defined in the @theme block.
# Exclusion: text-base-content is a DaisyUI semantic color class (Footgun-6), not a size
# utility. The old implementation piped through `grep -v 'text-base-content'`, which
# filters at the LINE level — so a genuine violation sharing a line with the (very common)
# base-content color class, e.g. class="text-sm text-base-content", was silently dropped
# (WR-01). Instead, anchor the size match so text-base-content can never match the pattern
# in the first place: text-sm/text-xs as whole tokens, and text-base only when NOT followed
# by a hyphen (which excludes text-base-content while still catching the raw text-base size).
if grep -rEn 'text-(sm|xs|xl|2xl|3xl)\b|text-base($|[^-])' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TYPE-GATE — raw text-scale utility found (use text-label/body/heading/display)" >&2
  errors=$((errors + 1))
fi

# BOLD-GATE: faux-bold tokens font-medium and font-semibold.
# Only weights 400 and 700 are loaded; font-medium (500) and font-semibold (600) trigger
# browser synthesis. Use font-bold or the default weight only.
if grep -rE 'font-(medium|semibold)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BOLD-GATE — faux-bold token found (use font-bold or default only)" >&2
  errors=$((errors + 1))
fi

# GAP-GATE: off-grid gap tokens gap-3, gap-4, gap-6.
# The 4px spacing grid uses semantic tokens: gap-sm (8px), gap-md (16px), gap-lg (24px).
# Bare numeric Tailwind gap utilities land off-grid and bypass the theme contract.
# The trailing boundary [^0-9a-z-]|$ is required (WR-04): without it the pattern matched
# gap-32, gap-64, and gap-3xl, all of which are valid documented spacing tokens
# (--spacing-...3xl / 32 / 48 / 64). The boundary restricts the gate to the standalone
# off-grid tokens gap-3, gap-4, gap-6.
if grep -rEn 'gap-(3|4|6)([^0-9a-z-]|$)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: GAP-GATE — off-grid gap token found (use gap-sm/md/lg)" >&2
  errors=$((errors + 1))
fi

# GROUP_SURFACES: the eight Phase 114 group-surface modules. SPACE-GATE and GROUP-GATE
# scope to THIS explicit array only — NOT a recursive $LIB grep. 17 other lib files use
# the same off-grid numerics legitimately and are out of this phase's slice (D-12;
# 114-RESEARCH Pitfall 1). Built from $LIB like FORM-DRIFT's FILTER_WRAPPERS.
GROUP_SURFACES=(
  "${LIB}/mailglass_admin/operator/support_cards.ex"
  "${LIB}/mailglass_admin/operator/suppression_card.ex"
  "${LIB}/mailglass_admin/operator/detail_header.ex"
  "${LIB}/mailglass_admin/operator/timeline.ex"
  "${LIB}/mailglass_admin/inbound/routing_trace.ex"
  "${LIB}/mailglass_admin/inbound/evidence_card.ex"
  "${LIB}/mailglass_admin/inbound/detail_header.ex"
  "${LIB}/mailglass_admin/inbound/timeline.ex"
)

# SPACE-GATE: ban raw off-grid padding/margin/space-y/gap numerics in the 8 group
# surfaces only (D-03). Word-boundary-anchored per 114-RESEARCH Pitfall 1: the leading
# (^|[^a-z-]) rejects min-h-11 / border-l-4 / h-3; the trailing [^0-9.a-z-]|$ rejects
# mt-0.5 (next char '.') and gap-3xl (next char letter) while still catching mt-1, p-6,
# space-y-1, gap-2 (the latter is a hole GAP-GATE leaves open). Closes the off-grid
# spacing escape that bypasses the xs..3xl / p-md / gap-md / space-y-sm token contract.
if grep -rEn '(^|[^a-z-])(p[trblxy]?|m[trblxy]?|space-[xy]|gap)-[0-9]+([^0-9.a-z-]|$)' "${GROUP_SURFACES[@]}" 2>/dev/null; then
  echo "FAIL: SPACE-GATE — raw off-grid spacing literal in a group surface (use xs..3xl / p-md/p-lg / gap-md / space-y-sm)" >&2
  errors=$((errors + 1))
fi

# GROUP-GATE: cheap same-tone card-in-card tripwire (D-05/D-07). Bans the
# bg-base-200 + border + border-base-300 + rounded-box signature appearing in a group
# surface — a same-tone nested shell reads as a flat box-in-box. This is a tripwire only,
# NOT the depth authority: the Floki ExUnit ancestor-depth proof (plan 04, D-07) owns
# real elevation-depth enforcement.
if grep -rEn 'bg-base-200 border border-base-300 rounded-box' "${GROUP_SURFACES[@]}" 2>/dev/null; then
  echo "FAIL: GROUP-GATE — same-tone card-in-card signature in a group surface (route the shell through Components.card/1)" >&2
  errors=$((errors + 1))
fi

# HEX-GATE: hard-coded hex color values in HEEx.
# All colors must flow through daisyUI semantic tokens or @theme CSS variables.
# A literal #RRGGBB or #RGB in a template is a design-system violation.
# The old pattern `#[0-9a-fA-F]{3,6}` was over-broad (WR-04): it matched HTML anchor
# fragments and DOM id refs (href="#abc123", phx-value-id="#deadbeef"), 4-/5-char runs that
# are not valid CSS hex, and brand-palette hexes quoted in a @moduledoc (#0D1B2A). Scope to
# a color context (require `color` before the hash) and to valid CSS hex lengths (exactly 3
# or 6 digits) with a trailing word boundary, so only genuine hard-coded color literals trip
# the gate.
if grep -rEn 'color[^#]*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: HEX-GATE — hard-coded hex color found (use semantic tokens)" >&2
  errors=$((errors + 1))
fi

# Z-INDEX-GATE: raw numeric/arbitrary z-index utilities in HEEx.
# Stacking contexts must consume the semantic .mg-layer-* utilities backed by
# --z-base/dropdown/overlay-scrim/overlay-panel/toast in app.css.
if grep -rEn '\bz-([0-9]+|\[[^]]+\])\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: Z-INDEX-GATE — raw z-index utility found (use mg-layer-* utilities)" >&2
  errors=$((errors + 1))
fi

# FOCUS-RING-GATE: pre-consolidation focus-ring idioms.
# All visible focus affordances in admin HEEx should use .mg-focus-ring or
# .mg-focus-ring-inset so width, color, offset, and timing stay centralized.
if grep -rEn 'focus-visible:ring-2 focus-visible:ring-primary|focus:outline|focus:outline-2|focus:outline-primary' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: FOCUS-RING-GATE — raw focus-ring idiom found (use mg-focus-ring utilities)" >&2
  errors=$((errors + 1))
fi

# SCOPE-GATE: host-safe admin roots.
# The operator shell and preview shell are mountable inside host apps; each
# root must own an isolated stacking context so host CSS/z-index values cannot
# accidentally interleave with admin overlays.
if ! grep -q 'mg-admin-root' "${LIB}/mailglass_admin/operator/shell.ex" 2>/dev/null; then
  echo "FAIL: SCOPE-GATE — operator shell root missing mg-admin-root isolation" >&2
  errors=$((errors + 1))
fi
if ! grep -q 'mg-admin-root' "${LIB}/mailglass_admin/preview_live.ex" 2>/dev/null; then
  echo "FAIL: SCOPE-GATE — preview shell root missing mg-admin-root isolation" >&2
  errors=$((errors + 1))
fi

# TOKEN-SCOPE-GATE: Phase 109 must not pull forward later theme-picker work.
# System theme remains CSS/root-layer behavior only: no JS storage, client hook,
# theme-controller input, matchMedia script, or explicit "system" data-theme.
if grep -rEn 'phx-hook=.*theme|localStorage|sessionStorage|document\.documentElement|window\.matchMedia|theme-controller|data-theme="system"|data-theme=\{[^}]*system|system[/-]light[/-]dark|light[/-]dark[/-]system' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: TOKEN-SCOPE-GATE — theme hook/storage/system picker creep found" >&2
  errors=$((errors + 1))
fi

# PHASE112-SHELL-GATE: tenant/theme/pagination seams must stay honest.
# Admin code consumes read-model/gateway modules; it must not grow raw Repo
# tenant listing, concrete system root themes, old tenant dead-end copy, or
# pagination totals inferred from truncated entry arrays.
admin_tenant_repo_hits="$(
  grep -rEn 'Repo\.(all|one|aggregate|get|get_by)|from\([^)]*(tenant|Tenant)|MailglassInbound\.Internal\.Operator\.Records' "$LIB/mailglass_admin" --include="*.ex" 2>/dev/null |
    grep -vF "${LIB}/mailglass_admin/optional_deps/mailglass_inbound.ex:" || true
)"
if [[ -n "$admin_tenant_repo_hits" ]]; then
  echo "$admin_tenant_repo_hits"
  echo "FAIL: PHASE112-SHELL-GATE — admin tenant access must use scoped read-model/gateway seams, not raw Repo/direct storage" >&2
  errors=$((errors + 1))
fi

if grep -En 'mailglass-system|data-theme="system"|root_theme.*system|system.*data-theme' "$OPERATOR_LIVE" "$INBOUND_LIVE" "${LIB}/mailglass_admin/layouts.ex" "${LIB}/mailglass_admin/layouts/root.html.heex" 2>/dev/null; then
  echo "FAIL: PHASE112-SHELL-GATE — system theme must remain absence of a concrete root theme" >&2
  errors=$((errors + 1))
fi

if grep -En 'No tenant selected|add (a )?tenant_id|tenant_id to the URL|\?tenant_id=…' "$OPERATOR_LIVE" "$INBOUND_LIVE" "$DELIVERIES_LIST" "$RECORDS_LIST" "${LIB}/mailglass_admin/operator/shell.ex" 2>/dev/null; then
  echo "FAIL: PHASE112-SHELL-GATE — old no-tenant dead-end copy found in shell/list source" >&2
  errors=$((errors + 1))
fi

if grep -En 'Enum\.count\(@(deliveries|records)\)|length\(@(deliveries|records)\)|Enum\.count\(assigns\.(deliveries|records)\)|length\(assigns\.(deliveries|records)\)' "$OPERATOR_LIVE" "$INBOUND_LIVE" "$DELIVERIES_LIST" "$RECORDS_LIST" 2>/dev/null; then
  echo "FAIL: PHASE112-SHELL-GATE — pagination count must come from page metadata, not entry-array length" >&2
  errors=$((errors + 1))
fi

# VOICE-GATE (FLOW-04, COPY-LD-07 / D-12): ban the "Oops"-class exclamations in
# admin copy. Scope is `.ex` ONLY — this is mandatory. The phoenix.mjs dependency
# inlines a logger no-op named "noops"; scanning JS/asset files would false-red on
# that token forever (see voice_test.exs ~32-39 and project memory "voice_test
# 'Oops' is dep-JS noise"). It lives in a JS asset, never in an .ex file, so the
# .ex-only scope sidesteps the false-positive entirely.
#
# Banned (case-insensitive, whole phrases): Oops, Whoops, Uh oh, Something went
# wrong. "Oops" is anchored on a non-word boundary ((^|[^a-z]) before it) so the
# substring "n[oops]" inside "noops" can never match even if an .ex file ever
# inlined that token. Recovery copy must cause-name (COPY-LD-07), e.g.
# "Delivery data could not be loaded. Refresh the page or adjust the filters,
# then try again." — never an "Oops"-class apology.
#
# Deliberately NOT banned here: standalone Email / Status / Notification. `Status`
# is a legitimate <th> column header (deliveries_list.ex ~106); a blanket noun ban
# goes permanently false-red. Those domain-noun rules are POSITIVE render
# assertions in voice_test.exs (Plan 01), never a ban grep (D-12).
#
# Doc-heredoc bodies are stripped before grepping: components.ex's @moduledoc
# names the banned phrases in prose to document the ban itself. Those mentions are
# documentation, not rendered copy, so an awk pass drops @doc/@moduledoc heredoc
# bodies first; the .ex-only grep then runs on the remaining (code/copy) lines.
voice_gate_hits=""
while IFS= read -r ex_file; do
  [[ -n "$ex_file" ]] || continue
  stripped="$(
    awk '
      /^[[:space:]]*@(module)?doc[[:space:]]*"""[[:space:]]*$/ { indoc=1; next }
      indoc && /^[[:space:]]*"""[[:space:]]*$/ { indoc=0; next }
      indoc { next }
      { print }
    ' "$ex_file"
  )"
  hits="$(printf '%s\n' "$stripped" | grep -nEi '(^|[^a-z])(oops|whoops|uh oh|something went wrong)' || true)"
  if [[ -n "$hits" ]]; then
    voice_gate_hits+="${ex_file}:"$'\n'"${hits}"$'\n'
  fi
done < <(grep -rl '' "$LIB" --include="*.ex" 2>/dev/null || true)
if [[ -n "$voice_gate_hits" ]]; then
  printf '%s' "$voice_gate_hits"
  echo "FAIL: VOICE-GATE — banned Oops-class phrase found in admin copy (.ex only); use cause-naming recovery copy (COPY-LD-07)" >&2
  errors=$((errors + 1))
fi

# RADIUS-GATE: raw radius scale or arbitrary radius utilities.
# Allow semantic rounded-box / rounded-field and intentional rounded-full
# indicators; reject Tailwind scale/arbitrary radius values.
if grep -rEn '\brounded-(none|sm|md|lg|xl|2xl|3xl|\[[^]]+\])\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: RADIUS-GATE — raw radius utility found (use rounded-box/field/full contract)" >&2
  errors=$((errors + 1))
fi

# SHADOW-GATE: raw shadow utilities.
# Only semantic elevation tokens are allowed: shadow-flat, shadow-raised,
# and shadow-overlay.
if grep -rEn '\bshadow($|-(sm|md|lg|xl|2xl|inner|\[[^]]+\]))' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: SHADOW-GATE — raw shadow utility found (use shadow-flat/raised/overlay)" >&2
  errors=$((errors + 1))
fi

# BORDER-GATE: raw border width/style/palette/arbitrary utilities.
# Preserve semantic default edges and semantic colors such as border-base-*,
# border-primary, border-secondary, border-error, border-warning/success, and
# border-transparent. Reject palette-scale colors and arbitrary border values.
if grep -rEn '\bborder-(0|2|4|8|\[[^]]+\]|solid|dashed|dotted|double|none|(red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose|slate|gray|zinc|neutral|stone)-[0-9]{2,3})\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BORDER-GATE — raw border utility found (use semantic border contract)" >&2
  errors=$((errors + 1))
fi

# SIZE-GATE: arbitrary size and spacing utilities.
# Fixed sizes and spacing must use the 4px grid or semantic tokens; arbitrary
# bracket utilities make the gate unable to reason about token discipline.
#
# Carve-out: viewport-relative max-height / min-height (max-h-[90vh], min-h-[…dvh],
# etc.) is the idiomatic, token-less way to cap an overlay panel against the
# viewport — there is no 4px-grid token for "90% of viewport height", and the
# cap is what gives the Phase-115 modal `overflow-y-auto` + `mg-overscroll-contain`
# scroll-chaining guard (D-04, FLOW-03) something to scroll. The exclusion is
# applied as a second pass that drops ONLY arbitrary max-h/min-h tokens whose
# value is a bare viewport unit (vh/svh/lvh/dvh/vw/svw/lvw/dvw/vmin/vmax); any
# other arbitrary size/spacing bracket on the same line still trips the gate
# because the broad first-pass match re-fires on the residual tokens. (grep here
# is ugrep in -E/POSIX mode, which rejects PCRE lookahead — hence the two-pass
# strip-then-rematch rather than a single negative-lookahead pattern.)
size_gate_raw="$(grep -rEn '\b(w|h|min-w|max-w|min-h|max-h|p[trblxy]?|m[trblxy]?|gap|space-[xy])-\[[^]]+\]' "$LIB" --include="*.ex" 2>/dev/null || true)"
# Strip the allowed viewport-relative max-h/min-h tokens, then re-check whether any
# arbitrary size/spacing bracket survives on each line.
size_gate_hits="$(
  printf '%s\n' "$size_gate_raw" |
    sed -E 's/(^|[^a-z-])(min-h|max-h)-\[[0-9.]+(vh|svh|lvh|dvh|vw|svw|lvw|dvw|vmin|vmax)\]/\1/g' |
    grep -E '\b(w|h|min-w|max-w|min-h|max-h|p[trblxy]?|m[trblxy]?|gap|space-[xy])-\[[^]]+\]' || true
)"
if [[ -n "$size_gate_hits" ]]; then
  printf '%s\n' "$size_gate_hits"
  echo "FAIL: SIZE-GATE — arbitrary size/spacing utility found (use token/grid utilities; viewport-relative max-h/min-h excepted)" >&2
  errors=$((errors + 1))
fi

# MOTION-GATE: banned animation properties and stray ease-in tokens (MOTION-LD-01/10).
#
# Part 1 — layout-property transition utilities.
# Animating height/width/padding/margin/top/left/right/bottom/max-height triggers
# layout thrash and is banned by MOTION-LD-10. Only transform/opacity (and fast-token
# color) are permitted. Ban:
#   - Named Tailwind utilities:  transition-height, transition-width, transition-padding,
#     transition-margin, transition-top, transition-left, transition-right,
#     transition-bottom, transition-max-height
#   - Arbitrary JIT utilities:   transition-[height], transition-[max-height], etc.
# Anchor with a leading non-word character or start-of-token so transition-colors,
# transition-all, transition-transform, transition-opacity are NOT matched.
#
# Part 2 — stray ease-in token (MOTION-LD-01 — ease-out only).
# Ban `ease-in` as a whole token (word boundary on both sides) while allowing:
#   - ease-in-out  (standard CSS function — boundary suffix -out means it won't match)
#   - var(--ease-symmetric)  (the one documented exception for the tab-swap crossfade;
#     the grep-E pattern (?!var\() uses a POSIX-incompatible lookahead so we instead
#     exclude the literal construction "(--ease-" with a second -v pass at the pipe)
#
# Running both greps: the first flags layout-property violations, the second flags
# ease-in violations. Each increments `errors` independently so a file with both
# defects is counted only once per gate.
if grep -rEn '(^|[^a-zA-Z0-9-])transition-(height|width|padding|margin|top|left|right|bottom|max-height)\b|transition-\[([^]]*\b(height|width|padding|margin|top|left|right|bottom|max-height)\b[^]]*)\]' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: MOTION-GATE — layout-property transition found (animate transform/opacity only, MOTION-LD-10)" >&2
  errors=$((errors + 1))
fi
if grep -rEn '\bease-in\b' "$LIB" --include="*.ex" 2>/dev/null | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out' | grep -q .; then
  grep -rEn '\bease-in\b' "$LIB" --include="*.ex" 2>/dev/null | grep -v -- '--ease-symmetric' | grep -v 'ease-in-out'
  echo "FAIL: MOTION-GATE — stray ease-in found (ease-out only except --ease-symmetric, MOTION-LD-01)" >&2
  errors=$((errors + 1))
fi
#
# Part 3 — origin-aware overlays POSITIVE check (FLOW-03 / D-07/D-09).
# The `.motion-overlay` rule in app.css must declare `transform-origin: var(--mg-origin`
# so header-anchored overlays/toasts can re-parameterize the existing scale(0.98→1)
# from an author-declared origin while centered modals fall back to `center`. This adds
# NO new animated property (MOTION-LD-04/10 compliant). Comment lines are filtered
# (drop CSS block-comment bodies: lines starting with `*` or `/*`) so the explanatory
# prose above the rule — which mentions `--mg-origin` in an inline-style example —
# cannot self-satisfy or self-invalidate the gate; only a real declaration counts.
[[ -f "$APP_CSS" ]] || { echo "FAIL: MOTION-GATE — app.css not found at $APP_CSS" >&2; exit 2; }
if ! grep -E 'transform-origin:[[:space:]]*var\(--mg-origin' "$APP_CSS" 2>/dev/null \
     | grep -vE '^[[:space:]]*(\*|/\*)' \
     | grep -q .; then
  echo "FAIL: MOTION-GATE — .motion-overlay must declare transform-origin: var(--mg-origin (origin-aware overlays, D-07)" >&2
  errors=$((errors + 1))
fi
#
# Part 4 — theme-switch-never-animates NEGATIVE check (FLOW-03 / D-08/D-09).
# Inverted default: theme-driven chrome must NOT carry an always-on color transition,
# because the LiveView theme swap is a server-side root re-render and a `transition-colors`
# there would flash an animated color change on every theme switch. Scope the grep
# NARROWLY to the theme_picker/1 function body only (extracted via awk from `def theme_picker(`
# to its matching `end`) so legitimate state-layer `transition-colors` elsewhere
# (nav_link/nav_pill hover/focus layers) are NOT flagged. The label's interactive state
# layer opts in via theme_option_class/2, not an always-on class on the label itself.
theme_picker_body="$(
  awk '
    /^[[:space:]]*def[[:space:]]+theme_picker\(/ { inblk=1 }
    inblk { print }
    inblk && /^[[:space:]]*end[[:space:]]*$/ { exit }
  ' "$COMPONENTS" 2>/dev/null || true
)"
if printf '%s\n' "$theme_picker_body" | grep -q 'transition-colors'; then
  echo "FAIL: MOTION-GATE — theme-driven chrome must not animate color (state-layer opt-in only, D-08)" >&2
  errors=$((errors + 1))
fi

# STATUS-BADGE-GATE: status/outcome badge rendering in list modules must route through
# Components.status_badge/1 only. Positive check: each list module calls status_badge.
# Negative check: no defp badge/severity helper was added inside the list modules,
# and no raw badge-* class literal appears outside a Components.status_badge context.
# grep -v '^#' suppresses gate header comments from self-matching (Comment-Text Discipline).
for list_module in "$DELIVERIES_LIST" "$RECORDS_LIST"; do
  module_name="${list_module##*/}"
  if ! grep -q 'Components.status_badge' "$list_module" 2>/dev/null; then
    echo "FAIL: STATUS-BADGE-GATE — $module_name must call Components.status_badge/1 for status rendering" >&2
    errors=$((errors + 1))
  fi
  if grep -v '^#' "$list_module" 2>/dev/null | grep -qE 'defp (badge_class|severity_class|outcome_class|badge_for)\b'; then
    echo "FAIL: STATUS-BADGE-GATE — $module_name contains a private badge/severity helper; route through Components.status_badge/1" >&2
    errors=$((errors + 1))
  fi
done

# DATA-STATE-GATE: the four data-state-* testids must each be present in the Components
# source as distinct literals (DATA-03 keeps four distinct UI states). A single merged
# generic testid is a design-system regression. Also confirm data_state/1 is the single
# public definition (no duplicate or private shadow in lib/).
for ds_kind in data-state-empty data-state-error data-state-permission-denied data-state-stale; do
  if ! grep -qF "\"${ds_kind}\"" "$COMPONENTS" 2>/dev/null; then
    echo "FAIL: DATA-STATE-GATE — Components must emit testid \"${ds_kind}\" (four distinct data states required)" >&2
    errors=$((errors + 1))
  fi
done

data_state_defs="$(grep -rEn 'def[[:space:]]+data_state[[:space:]]*(\(|$)' "$LIB" --include="*.ex" 2>/dev/null || true)"
def_count="$(echo "$data_state_defs" | grep -c 'def[[:space:]]' || true)"
if [[ "$def_count" -lt 1 ]]; then
  echo "FAIL: DATA-STATE-GATE — Components.data_state/1 public definition missing" >&2
  errors=$((errors + 1))
fi
# Only count non-Components definitions as violations (the one public def must live in Components)
non_components_defs="$(echo "$data_state_defs" | grep -vF "${COMPONENTS}:" || true)"
if [[ -n "$non_components_defs" ]]; then
  echo "$non_components_defs"
  echo "FAIL: DATA-STATE-GATE — data_state defined outside Components; must have exactly one public definition in components.ex" >&2
  errors=$((errors + 1))
fi

# TABLE-OVERUSE-GATE (A11 / RATCHET-05): count-must-not-increase floor on <table>
# element-open tags in lib/. <table> is appropriate ONLY for genuinely tabular,
# multi-column data; a <table> used as a layout device for a homogeneous list is a
# Bucket-A A11 violation. This gate is the COUNT TRIPWIRE — the per-<table>
# justification rows live in the Bucket-A coverage manifest (bucket_a_coverage_test.exs).
#
# The floor (TABLE_FLOOR) is the Phase-116-start value: 3 genuinely-tabular tables —
# operator deliveries_list.ex, inbound records_list.ex, preview tabs.ex. Adding a
# 4th <table> without bumping this floor (which requires a justification row in the
# manifest) fails the gate.
#
# Comment hygiene (Comment-Text Discipline): the match pattern is `<table` followed
# by WHITESPACE (a real element-open tag, e.g. `<table class=...`). The @moduledoc
# prose form is the backtick-wrapped `<table>` (immediate `>` after the tag name),
# which this pattern can never match — so header/doc prose mentioning a table cannot
# inflate the count. Never a bare unfiltered grep -c on the raw file.
TABLE_FLOOR=3
table_count="$(grep -rhoE '<table[[:space:]]' "$LIB" --include="*.ex" 2>/dev/null | wc -l | tr -d '[:space:]')"
if [[ "$table_count" -gt "$TABLE_FLOOR" ]]; then
  echo "Found $table_count <table> element-open tags in lib/ (floor is $TABLE_FLOOR):" >&2
  grep -rnE '<table[[:space:]]' "$LIB" --include="*.ex" 2>/dev/null >&2 || true
  echo "FAIL: TABLE-OVERUSE-GATE — <table> count rose above the $TABLE_FLOOR floor; add a per-table justification row to bucket_a_coverage_test.exs and bump TABLE_FLOOR, or use cards/lists (A11)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: design-system conformance violations found ($errors gate(s) failed)" >&2
  exit 1
fi

echo "OK: design-system conformance clean."
