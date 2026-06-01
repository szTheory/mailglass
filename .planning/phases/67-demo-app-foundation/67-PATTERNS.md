# Phase 67: Demo App Foundation - Pattern Map

## Closest Existing Analogs

### Boundary guard

- Target: `reference/host_app/SCOPE.md`, `test/reference_host/scope_lock_contract_test.exs`
- Pattern: v1.3 kept the reference host narrow through a scope document and
  explicit contract tests. Phase 67 should reuse that style rather than relying
  on convention.

### Demo dependency mode

- Target: `reference/demo_app/mix.exs`
- Pattern: existing `hex_deps?/0` function is the right place for the mode
  switch. Keep the switch demo-local and do not introduce Mailglass runtime API.

### Phoenix readiness

- Target: `reference/demo_app/lib/mailglass_demo_web/router.ex`,
  `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex`
- Pattern: add a tiny controller action or plug-backed route under the demo app
  only. It should return a simple 200 response after endpoint boot and database
  readiness if needed.

### Compose health and caches

- Target: `compose.demo.yml`
- Pattern: `demo_db` already uses `condition: service_healthy`; apply the same
  service-health dependency from `demo_e2e` to `demo`. Preserve all named cache
  volumes unless a task proves one is invalid.

### Browser dependency install

- Target: `reference/demo_app/Dockerfile`, `compose.demo.yml`,
  `reference/demo_app/assets/package-lock.json`
- Pattern: use lockfile-respecting `npm ci`. For Playwright system packages,
  prefer the official CLI `install --with-deps chromium` in the image or
  evidence setup command.

### Deterministic reset

- Target: `reference/demo_app/lib/mailglass_demo/demo_data.ex`,
  `reference/demo_app/priv/repo/seeds.exs`,
  `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex`
- Pattern: `DemoData.reset!/0` is already deterministic and destructive. The
  missing piece is a scriptable evidence path and tests around counts/id resets.

### Evidence artifact vocabulary

- Target: `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex`,
  `scripts/check_preview_capture_checkpoint.sh`,
  `.planning/milestones/v1.3-phases/59-ci-trust-lanes-checkpoint-evidence/59-CONTEXT.md`
- Pattern: bounded-claim artifact contracts are versioned and explicit. Phase 67
  should define the path and vocabulary for Phase 70 without making screenshots
  or DOM stable API.

## File Groupings

| Plan | Main files | Existing pattern |
|------|------------|------------------|
| 67-01 | `reference/demo_app/mix.exs`, `reference/demo_app/README.md`, `test/reference_host/scope_lock_contract_test.exs` | demo-local dependency switch plus host scope lock |
| 67-02 | `compose.demo.yml`, `reference/demo_app/Dockerfile`, demo router/controller | Compose health checks and lockfile installs |
| 67-03 | `DemoData`, seeds, demo controller/router, root `mix.exs` | deterministic reset plus reusable verification lane |

## PATTERN MAPPING COMPLETE
