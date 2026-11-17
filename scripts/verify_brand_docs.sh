#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
browser=false
started_all=$SECONDS

if [[ $# -gt 1 ]]; then
  printf 'usage: bash scripts/verify_brand_docs.sh [--browser]\n' >&2
  exit 2
fi

case "${1:-}" in
  "") ;;
  --browser) browser=true ;;
  *)
    printf 'usage: bash scripts/verify_brand_docs.sh [--browser]\n' >&2
    exit 2
    ;;
esac

if [[ "$browser" == true ]]; then
  if [[ -z "${PLAYWRIGHT_BROWSERS_PATH:-}" || ! -d "$PLAYWRIGHT_BROWSERS_PATH" ]]; then
    printf 'PLAYWRIGHT_BROWSERS_PATH must point to the existing installed browser directory\n' >&2
    exit 2
  fi
fi

cd "$repo_root"
output_root="$(mktemp -d "${TMPDIR:-/tmp}/mailglass-brand-docs.XXXXXXXX")"
cleanup() {
  if [[ -n "$output_root" && -d "$output_root" ]]; then
    rm -rf -- "$output_root"
  fi
}
trap cleanup EXIT

printf '[verify_brand_docs] temporary output: %s\n' "$output_root"

started=$SECONDS
MIX_ENV=dev mix docs --warnings-as-errors --output "$output_root/core"
printf '[verify_brand_docs] core docs build: %ss\n' "$((SECONDS - started))"

started=$SECONDS
(cd mailglass_admin && MIX_ENV=dev mix docs --output "$output_root/admin")
printf '[verify_brand_docs] admin docs build: %ss\n' "$((SECONDS - started))"

started=$SECONDS
(cd mailglass_inbound && MIX_ENV=dev mix docs --output "$output_root/inbound")
printf '[verify_brand_docs] inbound docs build: %ss\n' "$((SECONDS - started))"

started=$SECONDS
MAILGLASS_DOCS_OUTPUT_ROOT="$output_root" MIX_ENV=dev mix run --no-start ci/contracts/brand_docs_output_test.exs
printf '[verify_brand_docs] output contract: %ss\n' "$((SECONDS - started))"

if [[ "$browser" == true ]]; then
  started=$SECONDS
  if node mailglass_admin/e2e/docs-theme-contract.cjs --all --output-root "$output_root"; then
    printf '[verify_brand_docs] browser contract: %ss\n' "$((SECONDS - started))"
  else
    browser_exit=$?
    printf '[verify_brand_docs] browser contract failed: %ss (exit %s)\n' "$((SECONDS - started))" "$browser_exit" >&2
    exit "$browser_exit"
  fi
fi

printf '[verify_brand_docs] all requested checks passed in %ss; owned output will be removed\n' "$((SECONDS - started_all))"
