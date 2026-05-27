# Phase 57: Deterministic Trust Runner + Fixtures - Pattern Map

**Mapped:** 2026-05-27  
**Inputs:** `57-CONTEXT.md`, `57-RESEARCH.md`, `57-VALIDATION.md`, Phase 52 host contracts, preview checkpoint analogs

Phase 57 should reuse existing repo patterns: one canonical command surface, deterministic schema-versioned checkpoints, and fail-closed contract tests for required/forbidden drift.

## File Classification (Proposed -> Closest Analog)

| Proposed New/Updated File | Role | Closest Analog(s) | Reuse Guidance |
|---|---|---|---|
| `mix.exs` (modify) | canonical trust-runner command entrypoint (`verify.*` alias + preferred env) | existing `verify.foundation`, `verify.support_contract.core`, `verify.mix_tasks` aliases | keep one command surface and explicit preferred env; avoid multiple competing runner names |
| `lib/mix/tasks/mailglass.trust.run.ex` (optional create) | concrete runner command implementation if alias delegates to task | `lib/mix/tasks/mailglass.publish.check.ex`, `lib/mix/tasks/mail.doctor.ex` | strict option parsing, deterministic stage order, actionable failure text |
| `test/reference_host/trust_runner_command_contract_test.exs` (create) | asserts single command runs full stage chain with stable stage keys | `test/reference_host/boot_contract_test.exs`, `test/reference_host/public_seams_contract_test.exs` | required token assertions for stage list and deferred-scope disclaimers |
| `test/reference_host/trust_runner_fixture_contract_test.exs` (create) | deterministic fixture ID/payload/ordering contract | `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` | pin fixture identity and ordering with repeat-run equality checks |
| `test/reference_host/trust_runner_checkpoint_contract_test.exs` (create) | checkpoint schema + claim boundary + deterministic hash contract | `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` | enforce explicit `schema_version`, `claim_boundary`, `capture_count`-style integrity fields |
| `scripts/check_trust_runner_checkpoint.sh` (create) | executable shell validator for trust checkpoint artifact | `scripts/check_preview_capture_checkpoint.sh` | validate file existence, schema fields, bounded language, stage/cardinality/order checks |
| `MAINTAINING.md` / trust docs (modify) | documents canonical command and explicit phase boundary | release gate and advisory lane docs in `MAINTAINING.md` | one copy-paste command path; state Phase 58 deferred concerns explicitly |
| `.github/workflows/ci.yml` (later phase linkage) | future required trust lane wrapper around canonical runner | existing verify aliases and advisory lane patterns | when wired in later phases, call canonical runner command directly (no duplicated inline orchestration) |

## Reusable Code/Test Patterns

### 1) Canonical one-command verify aliases

Primary analog (`mix.exs`):

```elixir
"verify.support_contract.core": [
  "test test/mailglass/docs_contract_test.exs ... --warnings-as-errors"
]
```

Phase 57 reuse:
- define one trust runner command (`mix verify.reference_host.journey`) and route wrappers through it.
- keep preferred env mapping so local and CI behavior match.

### 2) Deterministic checkpoint schema + hash envelope

Primary analog (`mailglass_admin/lib/mailglass_admin/preview/capture_manifest.ex`):

```elixir
"schema_version" => @schema_version,
"claim_boundary" => @claim_boundary,
"matrix_sha256" => matrix_sha256(normalized_entries)
```

Phase 57 reuse:
- trust checkpoint artifact includes explicit schema + bounded-claim language + deterministic aggregate hash.
- sort entries/checkpoints before hashing and writing.

### 3) Executable checkpoint validator shell gate

Primary analog (`scripts/check_preview_capture_checkpoint.sh`):

```bash
if [[ ! -f "$CHECKPOINT_PATH" ]]; then
  echo "..." >&2
  exit 1
fi
python3 - "$MANIFEST_PATH" "$CHECKPOINT_PATH" <<'PY'
...
PY
```

Phase 57 reuse:
- add trust-checkpoint validation script with deterministic required fields/stages.
- fail closed with explicit stage/schema mismatch messages.

### 4) Required + forbidden contract test vocabulary

Primary analog (`test/reference_host/public_seams_contract_test.exs`):

```elixir
Enum.each(required_tokens, fn token -> assert token_present?(...) end)
Enum.each(forbidden_tokens, fn token -> refute token_present?(...) end)
```

Phase 57 reuse:
- required stage tokens for install/preview/send/webhook/operator checkpoints.
- forbidden completion tokens that would imply Phase 58 negative-path coverage is already done.

### 5) Brand-voice failure messaging

Primary analog (`mix` tasks):

```elixir
Mix.raise("Delivery blocked: ...")
```

Phase 57 reuse:
- trust-runner failures should be precise and actionable ("Trust runner blocked: missing checkpoint stage 'webhook_ingest'").

## Naming Conventions To Reuse

- alias naming: `verify.<domain>.<surface>` for canonical command gates.
- contract tests under `test/reference_host/*_contract_test.exs`.
- checkpoint schema key naming mirrors existing deterministic contract style (`schema_version`, `claim_boundary`, stage list/count/hash).
- shell verification script naming: `scripts/check_<artifact>_checkpoint.sh`.

## Verification Conventions To Reuse

- run contract tests with `--warnings-as-errors`.
- include quick per-task gate and full command gate (defined in `57-VALIDATION.md`).
- use explicit positive/negative `rg` checks for command wiring and deferred-scope language.

## PATTERN MAPPING COMPLETE
