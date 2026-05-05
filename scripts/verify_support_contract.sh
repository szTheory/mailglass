#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"
mix verify.support_contract.core

cd "$ROOT_DIR/mailglass_admin"
mix verify.support_contract.admin

cd "$ROOT_DIR"
mix compile --no-optional-deps --warnings-as-errors
