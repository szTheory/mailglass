# Phase 153: Generated-Host Proof, Docs, and Release Gate - Pattern Map

**Mapped:** 2026-08-03  
**Files analyzed:** 21 proposed created/modified files  
**Analogs found:** 20 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/consumer_install_smoke.sh` | integration harness | batch / request-response | itself | exact |
| `dev/mix/tasks/mailglass.trust.run.ex` | Mix task / orchestrator | batch | itself | exact |
| `dev/mailglass/generated_host/journey.ex` (new) | proof service | event-driven / CRUD / HTTP | `dev/mailglass/reference_host/webhook_operator_proof.ex` | partial |
| `dev/mailglass/generated_host/checkpoint.ex` (new) | utility / proof manifest | transform / file-I/O | `dev/mailglass/reference_host/trust_checkpoint.ex` | role-match |
| `lib/mix/tasks/mailglass.gen.migration.ex` | generator | file-I/O | itself + `Mailglass.Migration` | exact boundary |
| `lib/mailglass/migration.ex` | public migration facade | CRUD / schema I/O | itself | exact |
| `lib/mailglass/migrations/postgres.ex` | migration dispatcher | CRUD / schema I/O | itself | exact |
| `lib/mix/tasks/mailglass.preflight.ex` (new) | production operator task | request-response / validation | `lib/mix/tasks/mailglass.publish.check.ex` | role-match |
| `lib/mailglass/config.ex` | config / readiness service | request-response | itself | exact |
| `lib/mailglass/optional_deps/oban.ex` | optional-dependency gateway | request-response | itself | exact |
| `reference/host_app/config/runtime.exs` | host config | config | itself | exact |
| `reference/host_app/lib/mailglass_reference_host/application.ex` | host supervisor | event-driven | Phoenix generated application pattern | role-match |
| `reference/host_app/lib/mailglass_reference_host_web/router.ex` | router | request-response / HTTP | itself | exact |
| `reference/host_app/lib/mailglass_reference_host_web/admin_auth.ex` | auth adapter | request-response | itself | exact |
| `reference/host_app/lib/mailglass_reference_host/capture_adapter.ex` (new) | public provider adapter | event-driven / transform | `test/mailglass/adapters/fake_test.exs` | role-match only |
| `README.md` and `guides/{getting-started,authoring-mailables,rate-limiting,production-go-live-checklist,multi-tenancy,compatibility-and-deprecations}.md` | documentation | transform | `test/mailglass/docs_contract_test.exs` | exact contract pattern |
| `mailglass_admin/README.md` / admin packaging guide | documentation | transform | `test/mailglass/docs_contract_test.exs` | exact contract pattern |
| `test/mailglass/docs_contract_test.exs` | documentation contract test | transform | itself | exact |
| `test/mailglass/shipped_migration_divergence_test.exs` | integration test | schema I/O | itself | exact |
| `.github/workflows/{release-please,publish-hex,post-publish-smoke}.yml` | protected release workflow | event-driven / batch | existing job graph | exact |
| `test/{scripts/linked_release_concurrency_test,mailglass/publish/post_publish_smoke_contract_test}.exs` | workflow contract tests | transform | themselves | exact |

`dev/mailglass/generated_host/*` has no direct generated-host analog. Keep it development-only, invoked from the existing trust task, and copy the checkpoint conventions rather than adding it to the published package.

## Pattern Assignments

### `scripts/consumer_install_smoke.sh` (integration harness, batch/request-response)

**Analog:** `scripts/consumer_install_smoke.sh` lines 20-79, 104-131.

Keep one script parameterized by dependency source. Its existing shell discipline and path/Hex switch are the required base for the local package-shaped and exact-Hex passes:

```bash
set -euo pipefail
DEP_MODE="${DEP_MODE:-path}"
WORK_DIR="${WORK_DIR:-$(mktemp -d)}"
SANDBOX="${WORK_DIR}/sandbox"

case System.get_env("DEP_MODE") do
  "path" -> ...
  "hex" ->
    v = System.get_env("VERSION") || raise "hex mode requires VERSION"
    ~s(      {:mailglass, "== #{v}"},\n)
end
```

Extend the same host after `phx.new`, rather than treating `reference/host_app` as the proof. Replace `--no-ecto` at line 35 with a stock Ecto/Postgres host and preserve explicit lifecycle cleanup (`trap` at lines 112-124). Add a `LOCAL_PACKAGE_MODE`/artifact input only if it still resolves package contents rather than repository source paths. Every negative control must query the host database/capture store before and after and fail under `set -e`.

**Verification command:** `DEP_MODE=path MAILGLASS_PATH="$PWD" bash scripts/consumer_install_smoke.sh` (plus the exact-Hex environment in post-publish CI).

---

### `dev/mix/tasks/mailglass.trust.run.ex` and new `dev/mailglass/generated_host/*` (orchestrator, batch/event-driven)

**Analog:** `dev/mix/tasks/mailglass.trust.run.ex` lines 32-65, 97-113, 184-229.

```elixir
@stage_pipeline [:install, :preview, :send, :webhook_ingest, :operator_troubleshooting]

stage_records =
  host_root
  |> build_stage_records(dry_run?)
  |> validate_stage_records!()

write_checkpoint(checkpoint_out, host_root, dry_run?, stage_records)
emit_stage_records(stage_records, checkpoint_out)
```

The new pipeline must replace shallow `require_file!/3` success conditions (lines 118-141) with executable checkpoints: install, migrate, boot/readiness, sync parity, actively-polled async parity, negative controls, signed feedback, one-click replay/enforcement, production operator mount, and package identity. Preserve strict CLI parsing (lines 38-43), deterministic stage ordering (lines 184-208), `Mix.raise("Trust runner blocked: ...")` (line 232), and JSON-only bounded checkpoint output (lines 211-218). Manifest data may include input hashes, package lock identities, command/result hashes, and sentinel IDs; never bodies, recipients, credentials, or provider secrets.

**Checkpoint analog:** `dev/mailglass/reference_host/trust_checkpoint.ex` is the closest manifest encoder. Keep generated-host proof modules under `dev/`, not `lib/`, and do not import `test/support`, `MailerCase`, `TestRepo`, fake adapters, or private Mailglass modules.

---

### `lib/mix/tasks/mailglass.gen.migration.ex`, `lib/mailglass/migration.ex`, and `lib/mailglass/migrations/postgres.ex` (generator/public schema API, schema I/O)

**Generator analog:** `lib/mix/tasks/mailglass.gen.migration.ex` lines 15-38 and 41-69.

```elixir
{opts, rest, invalid} = OptionParser.parse(argv, strict: [upgrade: :boolean])

case existing_wrapper_migration() do
  nil ->
    path = Path.join(["priv", "repo", "migrations", "#{timestamp()}_mailglass_install.exs"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, migration_body())
    Mix.shell().info("created #{path}")
  path ->
    Mix.shell().info("unchanged #{path}")
end
```

Only change `migration_body/0`; retain idempotent discovery/output and fail-closed argument handling. The emitted wrapper must call the public dispatcher, not reproduce a historical `mailglass_events` subset (current broken body is lines 58-68). Copy the documented stable form from `lib/mailglass/migration.ex` lines 8-12:

```elixir
use Ecto.Migration
def up, do: Mailglass.Migration.up()
def down, do: Mailglass.Migration.down()
```

**Schema/config pattern:** `Mailglass.Migration.up/1` injects `Mailglass.Config.schema()` with `Keyword.put_new/3` (lines 25-32); `migrated_version/1` injects both prefix and configured repo (lines 55-66). `Mailglass.Migrations.Postgres.up/1` creates non-public schemas before dispatch (lines 17-34), queries the exact prefix with a bound parameter (lines 49-74), and records the version only after all VNN modules succeed (lines 77-100, 120-142). Do not introduce `search_path` fallback.

**Test analog:** extend `test/mailglass/shipped_migration_divergence_test.exs` lines 39-93. It runs the generated-wrapper contract through `Ecto.Migrator`, uses a unique non-public prefix, and cleans schema plus version bookkeeping in `on_exit`.

**Verification commands:** `mix test test/mailglass/shipped_migration_divergence_test.exs --warnings-as-errors` and `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors`.

---

### `lib/mix/tasks/mailglass.preflight.ex` (new) and `lib/mailglass/config.ex` (operator task/config service, validation)

**Task analog:** `lib/mix/tasks/mailglass.publish.check.ex` lines 48-86 and 89-190.

```elixir
{opts, rest, invalid} = OptionParser.parse(argv, strict: [package: :string, keep: :boolean])
validate_cli!(rest, invalid)

... |> Enum.each(fn package -> execute_package(package, opts[:keep] == true) end)

Mix.shell().info(
  "Pre-publish check result for #{ctx.package}: create=#{counts.create} update=#{counts.update} ..."
)
```

Use this strict parser, ordered named checks, actionable `Mix.raise` failures, and summary shape for a callable production preflight. It must be opt-in; do not move it into ordinary library boot.

**Readiness core:** extend `Mailglass.Config.production_readiness/0` at lines 606-632 rather than creating an alternate adapter decision. It already rejects `:task_supervisor` and delegates selected durable readiness to the canonical queue:

```elixir
case Application.get_env(:mailglass, :async_adapter, :oban) do
  :task_supervisor -> {:error, production_readiness_error(:non_durable_async_adapter)}
  :oban ->
    case Mailglass.OptionalDeps.Oban.ready?(:mailglass_outbound) do
      :ok -> :ok
      {:error, reason_class} -> {:error, production_readiness_error(reason_class)}
    end
end
```

The preflight composes repo/schema accessibility and version, adapter configuration, signed-webhook configuration, this canonical queue readiness, payload maintenance schedule/manual fallback, and authenticated operator-mount configuration. Return each failure as a bounded, named check; no boolean-only success.

**Oban pattern:** `lib/mailglass/optional_deps/oban.ex` lines 56-73 and 90-106 differentiates dependency unavailable, instance unavailable, and canonical queue unavailable, and turns unavailable selected durable insertion into `Ecto.Multi.error`. The real host must configure positive queue concurrency (`queues: [mailglass_outbound: 10]`, documented at lines 198-203) and observe an actual polling completion; never call `perform/1`, `Oban.drain_queue`, or an inline worker as positive evidence.

---

### Generated host config, router, auth, and capture adapter (host-owned integration, HTTP/event-driven)

**Router/auth analogs:** `reference/host_app/lib/mailglass_reference_host_web/router.ex` lines 7-23 and 25-39; `reference/host_app/lib/mailglass_reference_host_web/admin_auth.ex` lines 1-18.

```elixir
scope "/inbound" do
  pipe_through :mailglass_webhooks
  post "/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark
end

mailglass_operator_routes "/mail-ops",
  auth: MailglassReferenceHostWeb.AdminAuth,
  session: [subject_id: "current_user_id", tenant_id: "current_tenant_id", ...],
  unauthorized_path: "/"
```

Keep the inbound request on the public Plug and send signed HTTP requests through it; no direct internal ingest/persist invocation. Move only the operator scope from the `:dev_routes` conditional (line 25) into an explicit production-shaped host configuration, retaining the `MailglassAdmin.Auth` callback result form:

```elixir
{:ok, actor}
{:error, :unauthorized, %{message: "operator access denied"}}
```

**Capture-adapter pattern:** there is no production host analog. Implement it only in generated-host code using the documented public adapter behaviour, with a host-owned deterministic store. Its recorded canonical input must support comparison of wire fields for `Mailglass.deliver/2` and `deliver_later/2`, excluding timing/provider-generated values. Do not use the repository fake adapter/test PID facility.

**One-click HTTP oracle:** copy the behavior, not the test-only fixture seam, from `test/mailglass/compliance/unsubscribe_controller_test.exs` lines 347-369: two HTTP POSTs return empty 200, yield one event and one suppression. Preserve its scoped query conditions (lines 539-558) when asserting the follow-up stream-specific suppression; add transactional/unrelated-stream sendable controls.

**Webhook oracle:** public route configuration above plus `test/mailglass/webhook/ingest_auto_suppress_test.exs` lines 103-127: verified unsubscribe feedback creates `:address_stream` suppression using the delivery stream. Assert durable state only after the HTTP response/commit.

---

### Documentation and documentation-contract tests (docs, transform)

**Analog:** `test/mailglass/docs_contract_test.exs` lines 5-103, 106-145.

```elixir
blocks = extract_code_blocks("README.md")
install_block = Enum.find(blocks, &(&1 =~ "mix mailglass.install"))
assert install_block =~ "mix ecto.migrate"

assert Enum.all?(blocks, &match?({:ok, _}, Code.string_to_quoted(&1)))
```

Add structured assertions next to the existing guide family rather than keyword-only scans. Each published command/snippet must either run in the generated host or be parsed/validated with the existing `Mailglass.DocsHelpers` extraction helpers. Preserve the dynamic package-version check at lines 16-34 (linked core/admin major-minor pins) and the `Task existence` contract (lines 106-112) when adding `mailglass.preflight` or other documented tasks.

Update the named docs as one contract set: `README.md`, getting started, authoring, rate limiting, production go-live, multi-tenancy, compatibility/deprecations, and `mailglass_admin/README.md`. Align them on single recipient, default tenant, `mailglass_outbound`, payload lifecycle/scrubbing, non-public schema migration, signed webhooks, production auth mount, linked core/admin versus independently versioned inbound. Explicitly refute stale table counts, metadata-based async reconstruction, dev-only operator availability, and prior version posture.

**Verification command:** `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`.

---

### Release-target validation, protected release workflow, and workflow contract tests (config/test, event-driven/transform)

**Release authority:** `.github/workflows/release-please.yml` lines 48-83 reads `.planning/release-target.json`, checks active `release_packages`, derives expected tags from each selected package/version, and exits nonzero on malformed authority. Extend that pattern to compute changed package surface since each package’s last published tag before trusting the target; do not use the workflow dispatch `all` input as authority.

```bash
if [ -r "$target" ] && [ "$(jq -r '.status // ""' "$target")" = "active" ]; then
  expected_tags_text=$(jq -er '
    .release_packages[] as $package
    | .packages[$package] as $version
    | if $package == "mailglass" then "mailglass-v\($version)"
      else "\($package)-v\($version)" end
  ' "$target")
fi
```

Preserve release-please linked-version ownership from `release-please-config.json`: `.` and `mailglass_admin` are the linked group; inbound is independent and is not selected merely for compatibility consumption.

**Prepublish analog:** `.github/workflows/publish-hex.yml` lines 92-137 validates target/source versions and releases only authorized linked tags; lines 164-181 run per-package `mix mailglass.publish.check`. Keep its protected job graph, credentials only on publish steps, package checks, and credential-free artifacts. Replace the Phase 148 narrow suite/artifact at lines 182-230 with Phase 153 generated-host local-package proof plus full relevant gates, binding SHA, changed package decision, lock identities, commands, and sanitized checkpoint hashes.

**Postpublish analog:** `.github/workflows/post-publish-smoke.yml` lines 376 onward runs the shared harness with `DEP_MODE=hex`; retain bounded registry/HexDocs waits and exact versions. Remove hard-coded 2.4.0/2.1.1 assumptions shown at lines 343-375 in favor of release-target/package-derived exact versions. Run the same generated-host journey after Hex availability, with no path/git dependency.

**Workflow test analogs:**

- `test/scripts/linked_release_concurrency_test.exs` lines 39-106 asserts static non-cancelling concurrency, package job idempotency, release-event core/admin-only topology, protected environment, and sanitized proof artifact.
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` should retain its targeted job-block string extraction and assert exact-Hex generated-host invocation and required success dependencies.
- `test/scripts/release_trigger_recovery_test.exs` is the source-contract pattern for fail-closed `release-please` preflight branches.

**Verification commands:**

```bash
mix test test/scripts/linked_release_concurrency_test.exs \
  test/scripts/release_trigger_recovery_test.exs \
  test/mailglass/publish/post_publish_smoke_contract_test.exs --warnings-as-errors
mix mailglass.publish.check --package mailglass
mix mailglass.publish.check --package mailglass_admin
```

## Shared Patterns

### Fail closed at the public boundary

**Sources:** `lib/mailglass/optional_deps/oban.ex` lines 56-73 and 99-106; `lib/mix/tasks/mailglass.install.ex` lines 31-63.

Validate options before work, distinguish missing dependency/instance/queue/schema states, and raise an actionable named error. The generated host negative controls must prove absence of queue/job/delivery/event/payload/capture/background work, not merely error text.

### Schema isolation

**Sources:** `lib/mailglass/migration.ex` lines 25-32 and `lib/mailglass/migrations/postgres.ex` lines 49-74, 132-142.

Thread a unique valid non-public prefix through public migration APIs; query an explicit schema with bound params; never rely on `public` through `search_path`. The proof must inspect Mailglass tables and current version in the configured schema and assert no accidental public objects.

### Real async proof

**Sources:** `lib/mailglass/outbound/worker.ex` lines 33-65; `lib/mailglass/optional_deps/oban.ex` lines 51-73.

Queue is always `:mailglass_outbound`; the worker restores tenant from job args and dispatches by delivery ID. The host may observe Oban/job and database state, but cannot manually invoke `perform/1` or drain jobs to call the positive path real polling.

### HTTP privacy and idempotency

**Sources:** `reference/host_app/.../router.ex` lines 19-23; `test/mailglass/compliance/unsubscribe_controller_test.exs` lines 347-369; `test/mailglass/webhook/ingest_auto_suppress_test.exs` lines 103-127.

Use host routes and real HTTP; assert status/body contracts plus committed durable facts. Replay must converge to one canonical event/suppression pair and reject only the intended tenant/address/stream scope.

### Bounded, credential-free release evidence

**Sources:** `.github/workflows/publish-hex.yml` lines 193-230; `dev/mix/tasks/mailglass.trust.run.ex` lines 211-229.

Write JSON to a deterministic artifact directory, upload with `if-no-files-found: error` and retention, and bind only ref/SHA/package versions/commands/outcomes/hashes. No secret, raw message body, recipient, captured provider body, or host database URL enters an artifact.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `dev/mailglass/generated_host/journey.ex` | proof service | event-driven / CRUD / HTTP | Existing trust runner is deliberately shallow and source-host based; Phase 153 needs a new generated-host journey, constrained by its task/checkpoint interfaces. |

## Metadata

**Analog search scope:** `scripts/`, `dev/`, `lib/`, `reference/`, `test/`, `.github/workflows/`, prior Phase 148 artifacts  
**Files scanned:** 38  
**Pattern extraction date:** 2026-08-03
