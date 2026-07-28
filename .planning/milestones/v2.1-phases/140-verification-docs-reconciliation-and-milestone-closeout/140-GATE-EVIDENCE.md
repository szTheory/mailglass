# Phase 140 Gate Evidence

**Plan:** 140-01
**Purpose:** Focused closeout proof for v2.1 schema-prefix and admin asset gates.

## Schema-prefix focused proof

Schema-prefix proof passed: runtime paths do not depend on connection search_path.

| Field | Evidence |
|-------|----------|
| Command | `mix verify.schema_prefix` |
| Run at | 2026-07-08T17:17:16Z |
| Exit status | 0 |
| Requirements | SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04, GATE-01, GATE-02 |
| Result | PASS |

Observed output:

- Hostile no-search-path runtime tests: 4 tests, 0 failures.
- Raw repo prefix contract tests: 69 tests, 0 failures.
- Strict Credo recurrence guard: checked 480 source files, found no issues.
- Inbound schema-prefix contract tests: 5 tests, 0 failures.

Trust model:

- `mix verify.schema_prefix` is the fail-closed Phase 140 schema-prefix proof.
- The dual-schema advisory matrix remains a broad canary and is not the pass/fail definition for schema-prefix correctness.
- The canary distinction matters because the advisory matrix aligns configured schema and connection `search_path`; the focused proof exercises hostile no-search-path behavior and the raw-repo/static recurrence guard directly.

## Admin asset focused proof

Admin asset proof passed: hard refreshes and direct deep links stay styled across the verified route matrix.

| Field | Evidence |
|-------|----------|
| Run at | 2026-07-08T17:18:18Z |
| Requirements | AAU-01, AAU-02, AAU-03, AAU-04, GATE-03 |
| Result | PASS |

Command evidence:

| Command | Exit status | Observed result |
|---------|-------------|-----------------|
| `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/admin_asset_url_test.exs test/mailglass_admin/mount_path_test.exs --warnings-as-errors` | 0 | 21 tests, 0 failures |
| `cd mailglass_admin && MIX_ENV=test mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --warnings-as-errors` | 0 | 7 tests, 0 failures |
| `cd mailglass_admin && npm run test:operator-browser -- --grep "admin asset hard load"` | 0 | 12 Playwright tests, 0 failures |
| `git diff --quiet -- mailglass_admin/priv/static/app.css mailglass_admin/priv/static/fonts mailglass_admin/priv/static/mailglass-logo.svg` | 0 | No static bundle diff |

Route and trust coverage:

- AAU-01 and AAU-03: first HTML emits mount-rooted stylesheet hrefs for preview, scenario, error, gallery, operator, inbound, query deep-link, and alternate mount routes.
- AAU-02 and AAU-04: direct hard loads observe stylesheet/font responses and token-backed computed styling through the focused Playwright `admin asset hard load` matrix.
- GATE-03: both fast first-HTML ExUnit assertions and the serialized browser proof passed through existing Phase 139 lanes.
- No admin static bundle diff remained after the browser command.
