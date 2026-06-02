# Phase 72 Deferred Items

## Discovered During Plan 03

### Duplicate migration causes verify.stability_contract failure

**File:** `mailglass_inbound/priv/repo/migrations/20260508130000_add_suppression_flagged_to_inbound_records.exs`

**Status:** Untracked file in the development tree (never committed). Confirmed pre-existing before Plan 03.

**Symptom:** `mix verify.stability_contract` fails with:
```
** (Postgrex.Error) ERROR 42701 (duplicate_column) column "suppression_flagged" of relation "mailglass_inbound_records" already exists
```

**Root cause:** This untracked migration duplicates the committed migration at `priv/repo/migrations/20260525000000_add_suppression_flagged_to_inbound_records.exs`. The `test_helper.exs` in `mailglass_inbound/` runs all migrations via `Ecto.Migrator.run/4` with `all: true`, which picks up both files, causing the duplicate column error.

**Resolution path:** Determine the origin of the duplicate untracked file (likely a development artifact from a parallel branch or prior phase). Either delete the duplicate untracked migration or investigate whether the committed 20260525 migration should instead replace it.

**Impact:** `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` passes 6/6. Only `mix verify.stability_contract` (which chains through `cmd --cd mailglass_inbound mix verify.support_contract.inbound`) is affected.
