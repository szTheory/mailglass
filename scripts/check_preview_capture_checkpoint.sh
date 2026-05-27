#!/usr/bin/env bash
# Validate deterministic preview-capture artifact contract before CI upload.

set -euo pipefail

MANIFEST_PATH="mailglass_admin/tmp/preview_capture_advisory/manifest.json"
CHECKPOINT_PATH="mailglass_admin/tmp/preview_capture_advisory/checkpoint.json"
SCREENSHOTS_DIR="mailglass_admin/tmp/preview_capture_advisory/screenshots"

usage() {
  cat <<'EOF'
Usage: check_preview_capture_checkpoint.sh [options]

Validate preview capture artifacts for schema + boundary + deterministic matrix dimensions.

Options:
  --manifest PATH         Path to manifest.json
  --checkpoint PATH       Path to checkpoint.json
  --screenshots-dir PATH  Path to screenshot directory
  --help                  Show this message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      MANIFEST_PATH="${2:-}"
      shift 2
      ;;
    --checkpoint)
      CHECKPOINT_PATH="${2:-}"
      shift 2
      ;;
    --screenshots-dir)
      SCREENSHOTS_DIR="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Preview capture checkpoint validation blocked: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "Preview capture checkpoint validation blocked: missing manifest at '$MANIFEST_PATH'" >&2
  exit 1
fi

if [[ ! -f "$CHECKPOINT_PATH" ]]; then
  echo "Preview capture checkpoint validation blocked: missing checkpoint at '$CHECKPOINT_PATH'" >&2
  exit 1
fi

if [[ ! -d "$SCREENSHOTS_DIR" ]]; then
  echo "Preview capture checkpoint validation blocked: missing screenshots dir '$SCREENSHOTS_DIR'" >&2
  exit 1
fi

python3 - "$MANIFEST_PATH" "$CHECKPOINT_PATH" "$SCREENSHOTS_DIR" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
checkpoint_path = pathlib.Path(sys.argv[2])
screenshots_dir = pathlib.Path(sys.argv[3])

expected_schema = "preview_capture.v1"
expected_boundary = "preview-pipeline confidence only; not cross-client parity"
allowed_widths = {375, 768, 1024}
allowed_themes = {"light", "dark"}

errors = []

try:
    manifest = json.loads(manifest_path.read_text())
except Exception as exc:  # noqa: BLE001
    errors.append(f"manifest is not valid JSON: {exc}")
    manifest = {}

try:
    checkpoint = json.loads(checkpoint_path.read_text())
except Exception as exc:  # noqa: BLE001
    errors.append(f"checkpoint is not valid JSON: {exc}")
    checkpoint = {}

if manifest.get("schema_version") != expected_schema:
    errors.append(
        f"manifest.schema_version must be '{expected_schema}' (got {manifest.get('schema_version')!r})"
    )

if checkpoint.get("schema_version") != expected_schema:
    errors.append(
        f"checkpoint.schema_version must be '{expected_schema}' (got {checkpoint.get('schema_version')!r})"
    )

if manifest.get("claim_boundary") != expected_boundary:
    errors.append(
        "manifest.claim_boundary missing expected bounded language: "
        "'preview-pipeline confidence only; not cross-client parity'"
    )

if checkpoint.get("claim_boundary") != expected_boundary:
    errors.append(
        "checkpoint.claim_boundary missing expected bounded language: "
        "'preview-pipeline confidence only; not cross-client parity'"
    )

manifest_captures = manifest.get("captures")
checkpoint_captures = checkpoint.get("captures")
matrix_count = checkpoint.get("capture_count")

if not isinstance(manifest_captures, list):
    errors.append("manifest.captures must be an array")
    manifest_captures = []

if not isinstance(checkpoint_captures, list):
    errors.append("checkpoint.captures must be an array")
    checkpoint_captures = []

if not isinstance(matrix_count, int):
    errors.append("checkpoint.capture_count must be an integer")
    matrix_count = 0

if matrix_count <= 0:
    errors.append("checkpoint.capture_count must be > 0 (non-zero matrix_count required)")

if matrix_count != len(checkpoint_captures):
    errors.append(
        f"checkpoint.capture_count ({matrix_count}) must equal len(checkpoint.captures) ({len(checkpoint_captures)})"
    )

if len(manifest_captures) != len(checkpoint_captures):
    errors.append(
        f"manifest/checkpoint capture length mismatch ({len(manifest_captures)} vs {len(checkpoint_captures)})"
    )

widths = sorted({entry.get("width") for entry in checkpoint_captures if isinstance(entry, dict)})
themes = sorted({entry.get("theme") for entry in checkpoint_captures if isinstance(entry, dict)})

if not widths:
    errors.append("checkpoint deterministic dimensions missing widths")

if not themes:
    errors.append("checkpoint deterministic dimensions missing themes")

unsupported_widths = [width for width in widths if width not in allowed_widths]
if unsupported_widths:
    errors.append(
        f"checkpoint widths must stay within {sorted(allowed_widths)}; found unsupported widths {unsupported_widths}"
    )

unsupported_themes = [theme for theme in themes if theme not in allowed_themes]
if unsupported_themes:
    errors.append(
        f"checkpoint themes must stay within {sorted(allowed_themes)}; found unsupported themes {unsupported_themes}"
    )

png_files = sorted(screenshots_dir.glob("*.png"))
if len(png_files) != matrix_count:
    errors.append(
        f"screenshots png count ({len(png_files)}) must match matrix_count ({matrix_count})"
    )

missing_paths = []
for capture in checkpoint_captures:
    if not isinstance(capture, dict):
        continue
    relative_path = capture.get("path")
    if not isinstance(relative_path, str) or relative_path.strip() == "":
        errors.append("checkpoint capture entry missing non-empty 'path'")
        continue
    full_path = screenshots_dir / relative_path
    if not full_path.exists():
        missing_paths.append(relative_path)

if missing_paths:
    errors.append(f"screenshot files missing for checkpoint paths: {missing_paths}")

if errors:
    for error in errors:
        print(f"[preview-capture-checkpoint] FAIL: {error}", file=sys.stderr)
    sys.exit(1)

print("[preview-capture-checkpoint] OK: deterministic preview capture contract verified")
print(f"[preview-capture-checkpoint] matrix_count={matrix_count}")
print(f"[preview-capture-checkpoint] widths={widths}")
print(f"[preview-capture-checkpoint] themes={themes}")
print(f"[preview-capture-checkpoint] claim_boundary={expected_boundary}")
PY
