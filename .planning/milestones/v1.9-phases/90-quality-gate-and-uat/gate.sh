#!/usr/bin/env bash
# Phase 90 consolidated quality gate (GATE-01) for brandbook-fable/
#
# Runs ALL 9 checks per invocation (no early exit — one run reports everything),
# prints "CHECK-N PASS" or "CHECK-N FAIL: detail" per check, exits non-zero on
# any failure, and prints the sentinel GATE-PASS only when all 9 pass.
#
# Run from the repo root: bash .planning/phases/90-quality-gate-and-uat/gate.sh
#
# This script lives in the phase dir — NEVER inside brandbook-fable/.

set -u
FAIL=0
BB="brandbook-fable"

fail() { # fail <check> <detail>
  echo "CHECK-$1 FAIL: $2"
  FAIL=1
}

# ---------------------------------------------------------------------------
# CHECK 1 — SVG parse (xmllint) + folder inventory
#   Every SVG in assets/ and examples/ must XML-parse.
#   Inventory: exactly 8 files in assets/, exactly 6 in examples/ (4 SVG + 2 HTML).
# ---------------------------------------------------------------------------
c1_ok=1
for f in "$BB"/assets/*.svg "$BB"/examples/*.svg; do
  if ! /usr/bin/xmllint --noout "$f" 2>/dev/null; then
    fail 1 "xmllint parse error in $f"
    c1_ok=0
  fi
done
assets_count=$(find "$BB/assets" -type f | wc -l | tr -d ' ')
examples_count=$(find "$BB/examples" -type f | wc -l | tr -d ' ')
examples_svg=$(find "$BB/examples" -type f -name '*.svg' | wc -l | tr -d ' ')
examples_html=$(find "$BB/examples" -type f -name '*.html' | wc -l | tr -d ' ')
if [ "$assets_count" -ne 8 ]; then
  fail 1 "expected exactly 8 files in assets/, found $assets_count"
  c1_ok=0
fi
if [ "$examples_count" -ne 6 ] || [ "$examples_svg" -ne 4 ] || [ "$examples_html" -ne 2 ]; then
  fail 1 "expected 6 files in examples/ (4 SVG + 2 HTML), found $examples_count ($examples_svg SVG, $examples_html HTML)"
  c1_ok=0
fi
[ "$c1_ok" -eq 1 ] && echo "CHECK-1 PASS"

# ---------------------------------------------------------------------------
# CHECK 2 — tokens.json parses as JSON
# ---------------------------------------------------------------------------
if python3 -m json.tool "$BB/tokens.json" > /dev/null 2>&1; then
  echo "CHECK-2 PASS"
else
  fail 2 "tokens.json does not parse as JSON"
fi

# ---------------------------------------------------------------------------
# CHECK 3 — Reference integrity + zero external URLs
#   3a. Every href/src in each HTML file resolves locally against the file's
#       own directory (skip "#", "data:", "mailto:").
#   3b. Zero external URLs / url(http) / @import / fetch / script-src anywhere.
# ---------------------------------------------------------------------------
c3_ok=1
for html in index.html examples/landing-page.html examples/email-template.html; do
  file="$BB/$html"
  dir=$(dirname "$file")
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    case "$ref" in
      "#"*|data:*|mailto:*) continue ;;
    esac
    target="${ref%%#*}"   # strip any fragment
    [ -z "$target" ] && continue
    if [ ! -f "$dir/$target" ]; then
      fail 3 "$html references '$ref' which does not resolve ($dir/$target missing)"
      c3_ok=0
    fi
  done < <(grep -Eo '(href|src)="[^"]*"' "$file" | sed -E 's/^(href|src)="//; s/"$//')
done
# 3b external-URL greps — all must count 0.
# NOTE: xmlns namespace URIs are identifiers, not fetches; the patterns below
# deliberately match only href/src/xlink:href/url()/@import/fetch forms, never
# bare xmlns declarations.
ext1=$(grep -rEn '(href|src|xlink:href)="https?://' "$BB"/ | wc -l | tr -d ' ')
ext2=$(grep -rEin 'url\(["'"'"']?https?:' "$BB"/ | wc -l | tr -d ' ')
ext3=$(grep -rEin '@import' "$BB"/ | wc -l | tr -d ' ')
ext4=$(grep -rEn 'fetch\(|XMLHttpRequest|<script src' "$BB"/ --include='*.html' | wc -l | tr -d ' ')
if [ "$ext1" -ne 0 ] || [ "$ext2" -ne 0 ] || [ "$ext3" -ne 0 ] || [ "$ext4" -ne 0 ]; then
  fail 3 "external references found (href/src=$ext1 url()=$ext2 @import=$ext3 fetch/script-src=$ext4)"
  c3_ok=0
fi
[ "$c3_ok" -eq 1 ] && echo "CHECK-3 PASS"

# ---------------------------------------------------------------------------
# CHECK 4 — Process-vocabulary denylist
#   BASE regex is the Phase 88/89 denylist VERBATIM; EXTENSION appends the
#   Phase 90 CONTEXT terms under word boundaries.
#   The single grep -v filter excludes the functional CSS value
#   "align-items: baseline" (used twice in index.html) — a CSS keyword, not
#   process vocabulary; rewriting working layout CSS to dodge a denylist word
#   would be wrong (same rationale as decision [79-01] text-base-content).
#   NO other exclusions are permitted.
# ---------------------------------------------------------------------------
DENY_BASE='phase|milestone|roadmap|tournament|codex|gsd|REQ-[0-9A-Z]|BOOK-0|DIF-[0-9]|CDX-|COLL-0|COPY-0|FOUND-0|LOGO-0|GATE-0|TODO|FIXME|lorem|placeholder|draft'
DENY_EXT='\bplans?\b|checkpoint|\bTBD\b|option-|variant-|\bbaseline\b'
deny_hits=$(grep -riE "$DENY_BASE|$DENY_EXT" "$BB"/ | grep -viE 'align-items:[[:space:]]*baseline' | wc -l | tr -d ' ')
if [ "$deny_hits" -eq 0 ]; then
  echo "CHECK-4 PASS"
else
  fail 4 "$deny_hits process-vocabulary hit(s):"
  grep -riE "$DENY_BASE|$DENY_EXT" "$BB"/ | grep -viE 'align-items:[[:space:]]*baseline' | head -20
fi

# ---------------------------------------------------------------------------
# CHECK 5 — No live text / fonts in SVG assets (assets/ AND examples/ SVGs)
# ---------------------------------------------------------------------------
c5_ok=1
for f in "$BB"/assets/*.svg "$BB"/examples/*.svg; do
  text_n=$(grep -c '<text' "$f" || true)
  font_n=$(grep -ic 'font-family' "$f" || true)
  if [ "$text_n" -ne 0 ] || [ "$font_n" -ne 0 ]; then
    fail 5 "$f contains live text/fonts (<text x$text_n, font-family x$font_n)"
    c5_ok=0
  fi
done
[ "$c5_ok" -eq 1 ] && echo "CHECK-5 PASS"

# ---------------------------------------------------------------------------
# CHECK 6 — No background plate behind any mark (structural)
#   Every assets/*.svg EXCEPT social-avatar.svg / social-avatar-dark.svg must
#   contain ZERO <rect>. The two avatars must each contain EXACTLY ONE
#   <rect width="240" height="240"> — the inherently-square documented
#   exception (Phase 87 decision record).
# ---------------------------------------------------------------------------
c6_ok=1
for f in "$BB"/assets/*.svg; do
  base=$(basename "$f")
  rect_n=$(grep -o '<rect' "$f" | wc -l | tr -d ' ')
  case "$base" in
    social-avatar.svg|social-avatar-dark.svg)
      plate_n=$(grep -Eo '<rect width="240" height="240"' "$f" | wc -l | tr -d ' ')
      if [ "$rect_n" -ne 1 ] || [ "$plate_n" -ne 1 ]; then
        fail 6 "$base must have exactly one 240x240 rect (found $rect_n rect(s), $plate_n square plate(s))"
        c6_ok=0
      fi
      ;;
    *)
      if [ "$rect_n" -ne 0 ]; then
        fail 6 "$base contains $rect_n <rect> element(s) — background plates are banned"
        c6_ok=0
      fi
      ;;
  esac
done
[ "$c6_ok" -eq 1 ] && echo "CHECK-6 PASS"

# ---------------------------------------------------------------------------
# CHECK 7 — Size budgets: folder <= 500 KB, index.html <= 150 KB (153600 B),
#            no single file > 100 KB
# ---------------------------------------------------------------------------
c7_ok=1
folder_kb=$(du -sk "$BB" | awk '{print $1}')
index_bytes=$(wc -c < "$BB/index.html" | tr -d ' ')
oversize=$(find "$BB" -type f -size +100k)
if [ "$folder_kb" -gt 500 ]; then
  fail 7 "folder is ${folder_kb} KB (budget 500 KB)"
  c7_ok=0
fi
if [ "$index_bytes" -gt 153600 ]; then
  fail 7 "index.html is ${index_bytes} bytes (budget 153600)"
  c7_ok=0
fi
if [ -n "$oversize" ]; then
  fail 7 "file(s) over 100 KB: $oversize"
  c7_ok=0
fi
[ "$c7_ok" -eq 1 ] && echo "CHECK-7 PASS (folder ${folder_kb} KB, index.html ${index_bytes} B)"

# ---------------------------------------------------------------------------
# CHECK 8 — Favicon: <= 3 shape elements, viewBox="0 0 16 16"
# ---------------------------------------------------------------------------
fav="$BB/assets/favicon.svg"
shape_n=$(grep -Eo '<(path|rect|circle|ellipse|polygon|polyline|line)\b' "$fav" | wc -l | tr -d ' ')
vb_n=$(grep -c 'viewBox="0 0 16 16"' "$fav" || true)
if [ "$shape_n" -le 3 ] && [ "$vb_n" -ge 1 ]; then
  echo "CHECK-8 PASS ($shape_n shape elements, 16x16 viewBox)"
else
  fail 8 "favicon has $shape_n shape elements (max 3) / viewBox match count $vb_n (need >= 1)"
fi

# ---------------------------------------------------------------------------
# CHECK 9 — Scope / frozen baseline (commit-range check)
#   a. Working tree clean outside .planning/ (this phase's own evidence files
#      may be in flight under .planning/).
#   b. Frozen codex brandbook/ untouched since 09a84dd4.
#   c. v1.9 range clean: nothing outside brandbook-fable/ + .planning/ changed
#      in 09a84dd4..HEAD (covers phases 85-90, strictly stronger than the
#      required 88-90 window).
# ---------------------------------------------------------------------------
c9_ok=1
dirty_outside=$(git status --porcelain | grep -vE '^.. \.planning/' || true)
if [ -n "$dirty_outside" ]; then
  fail 9 "working tree dirty outside .planning/: $(echo "$dirty_outside" | head -5 | tr '\n' ' ')"
  c9_ok=0
fi
if ! git diff --quiet 09a84dd4 -- brandbook/; then
  fail 9 "frozen brandbook/ differs from 09a84dd4"
  c9_ok=0
fi
codex_dirty=$(git status --porcelain brandbook/ || true)
if [ -n "$codex_dirty" ]; then
  fail 9 "frozen brandbook/ has uncommitted changes"
  c9_ok=0
fi
range_leaks=$(git diff --name-only 09a84dd4..HEAD | grep -vE '^(brandbook-fable/|\.planning/)' | wc -l | tr -d ' ')
if [ "$range_leaks" -ne 0 ]; then
  fail 9 "$range_leaks file(s) outside brandbook-fable/ + .planning/ changed in 09a84dd4..HEAD:"
  git diff --name-only 09a84dd4..HEAD | grep -vE '^(brandbook-fable/|\.planning/)' | head -10
  c9_ok=0
fi
[ "$c9_ok" -eq 1 ] && echo "CHECK-9 PASS"

# ---------------------------------------------------------------------------
if [ "$FAIL" -eq 0 ]; then
  echo "GATE-PASS"
  exit 0
else
  echo "GATE-FAIL"
  exit 1
fi
