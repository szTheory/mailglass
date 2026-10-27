# Deferred Items — Phase 174

- The broader Demo formatter check reports pre-existing formatting drift in `mailglass_admin/lib/mailglass_admin/admin_auth.ex`, a migration, `reference/demo_app/lib/mailglass_demo_web/page_controller_security_test.exs`, and `reference/demo_app/lib/mailglass_demo/repo.ex`. These files are outside Plan 174-01 and were left unchanged. The `mailglass_admin` formatter check is also blocked by its existing lockfile mismatch for `boundary`, `premailex`, and `phoenix`; no dependency changes were made.
