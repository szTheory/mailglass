# Phase 6: Custom Credo + Boundary — Validation Map

**Created:** 2026-04-24

## Success Criteria → Plan Mapping

| # | Success Criterion | Plan | Check |
|---|-------------------|------|-------|
| 1 | PR adding raw `Swoosh.Mailer.deliver/1` in lib fails CI | 06-02, 06-05 | LINT-01 |
| 2 | PR adding `tracking: [opens: true]` to `password_reset/1` fails CI | 06-03, 06-05 | TRACK-02 |
| 3 | PR adding PII keys to telemetry metadata fails CI | 06-01, 06-05 | LINT-02 |
| 4 | PR calling `Repo.all(Delivery)` without scope fails CI | 06-03, 06-05 | LINT-03 |
| 5 | PR calling `Oban.insert/2` outside gateway fails CI | 06-01, 06-05 | LINT-04 |
| 6 | PR broadcasting topic without `mailglass:` prefix fails CI | 06-01, 06-05 | LINT-06 |
| 7 | PR calling `DateTime.utc_now/0` outside Clock fails CI | 06-01, 06-05 | LINT-12 |
| 8 | Multi-tenant property test passes | 06-03 | TENANT-03 |
| 9 | Boundary contract test passes | 06-04 | CORE-07 |

## Requirement → Test File Mapping

| Requirement | Test File | Status |
|-------------|-----------|--------|
| LINT-01 | `test/mailglass/credo/no_raw_swoosh_send_in_lib_test.exs` | Planned (Plan 02) |
| LINT-02 | `test/mailglass/credo/no_pii_in_telemetry_meta_test.exs` | Planned (Plan 01) |
| LINT-03 | `test/mailglass/credo/no_unscoped_tenant_query_in_lib_test.exs` | Planned (Plan 03) |
| LINT-04 | `test/mailglass/credo/no_bare_optional_dep_reference_test.exs` | Planned (Plan 01) |
| LINT-05 | `test/mailglass/credo/no_oversized_use_injection_test.exs` | Planned (Plan 02) |
| LINT-06 | `test/mailglass/credo/prefixed_pub_sub_topics_test.exs` | Planned (Plan 01) |
| LINT-07 | `test/mailglass/credo/no_default_module_name_singleton_test.exs` | Planned (Plan 02) |
| LINT-08 | `test/mailglass/credo/no_compile_env_outside_config_test.exs` | Planned (Plan 02) |
| LINT-09 | `test/mailglass/credo/no_other_app_env_reads_test.exs` | Planned (Plan 02) |
| LINT-10 | `test/mailglass/credo/telemetry_event_convention_test.exs` | Planned (Plan 01) |
| LINT-11 | `test/mailglass/credo/no_full_response_in_logs_test.exs` | Planned (Plan 02) |
| LINT-12 | `test/mailglass/credo/no_direct_date_time_now_test.exs` | Planned (Plan 01) |
| TRACK-02 | `test/mailglass/credo/no_tracking_on_auth_stream_test.exs` | Planned (Plan 03) |
| CORE-07 | `test/mailglass/boundary_test.exs` | Planned (Plan 04) |
| All 13 | `test/mailglass/credo/integration_test.exs` | Planned (Plan 05) |

## Plan Dependency Graph

```
Plan 01 (wave 0) ─── Proven-convention checks (LINT-02, 04, 06, 10, 12)
   │
   ├──► Plan 02 (wave 1) ─── Fresh-implementation checks (LINT-01, 05, 07, 08, 09, 11)
   │
   └──► Plan 03 (wave 1) ─── Domain-critical checks (LINT-03, TRACK-02)
            │
            └──► Plan 04 (wave 2) ─── Boundary enforcement extension (CORE-07)
                     │
                     └──► Plan 05 (wave 3) ─── CI integration + .credo.exs + integration test
```

Plans 02 and 03 can execute in parallel (wave 1). Plan 04 depends on all checks being written (needs to know the full module graph). Plan 05 is the capstone.
