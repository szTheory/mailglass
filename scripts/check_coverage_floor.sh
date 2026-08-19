#!/usr/bin/env bash
set -euo pipefail

baseline="${1:?baseline JSON path required}"
report="${2:?ExCoveralls JSON report path required}"
expected_toolchain="${3:?exact Elixir/OTP toolchain required}"

test -r "$baseline" || { echo "coverage baseline missing: $baseline" >&2; exit 1; }
test -r "$report" || { echo "coverage report missing: $report" >&2; exit 1; }

actual="$(elixir -e 'IO.write(System.version() <> "/" <> to_string(:erlang.system_info(:otp_release)))')"
test "$actual" = "$expected_toolchain" || {
  echo "coverage toolchain mismatch: expected $expected_toolchain, got $actual" >&2
  exit 1
}

node -e '
const fs = require("fs");
const [basePath, reportPath] = process.argv.slice(1);
const base = JSON.parse(fs.readFileSync(basePath, "utf8"));
const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));
const files = report.source_files;
if (!Array.isArray(files) || files.length === 0) throw new Error("coverage report has no source_files");
let covered = 0, relevant = 0;
for (const file of files) for (const hit of Object.values(file.coverage || {})) {
  if (hit !== null) { relevant++; if (hit > 0) covered++; }
}
if (!Number.isInteger(base.covered_lines) || !Number.isInteger(base.relevant_lines) || typeof base.percentage !== "number") throw new Error("baseline lacks measured coverage counts");
const percentage = covered / relevant * 100;
if (covered < base.covered_lines || relevant < base.relevant_lines || percentage < base.percentage) throw new Error(`coverage regression: ${covered}/${relevant} (${percentage}), baseline ${base.covered_lines}/${base.relevant_lines} (${base.percentage})`);
' "$baseline" "$report"
