---
status: issues_found
phase: 57-deterministic-trust-runner-fixtures
reviewed_commits:
  - 293cd74
  - 9d995e2
  - 589e7e1
  - 8ed47eb
  - 7030022
  - 662938f
  - 82a607d
reviewed_at: 2026-05-27
reviewer: codex
---

## Findings

1. **Low - Missing argument handling for `--checkpoint` exits without actionable error**
   - **File:** `scripts/check_trust_runner_checkpoint.sh`
   - **Detail:** When invoked as `bash scripts/check_trust_runner_checkpoint.sh --checkpoint` (no value), the parser executes `shift 2` with only one token available under `set -euo pipefail`, causing an immediate non-descriptive exit. This is fail-closed, but not operator-friendly and can slow CI/debug triage.
   - **Impact:** Poor diagnosability for misconfigured calls; no explicit message indicating that `--checkpoint` requires a value.
   - **Suggested fix:** Guard `--checkpoint` with `[[ $# -lt 2 || -z "${2:-}" ]]` and emit a clear blocking error plus usage text before exiting.

## Recommendation

- **Status:** `issues_found`
- Address the CLI argument UX bug above before treating Phase 57 as fully clean.  
- After patching, re-run:
  - `mix test test/reference_host/trust_runner_command_contract_test.exs test/reference_host/trust_runner_fixture_contract_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors`
  - `mix verify.reference_host.journey --dry-run`
  - `bash scripts/check_trust_runner_checkpoint.sh --checkpoint`
