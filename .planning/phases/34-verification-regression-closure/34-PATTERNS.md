# Phase 34: Verification & Regression Closure - Pattern Map

**Mapped:** 2026-05-05
**Scope:** verification and CI patterns relevant to `MAT-03`

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.github/workflows/advisory-matrix.yml` | config | batch | `.github/workflows/advisory-matrix.yml` | exact |
| `.github/workflows/provider-live.yml` | config | batch | `.github/workflows/provider-live.yml` | exact |
| `test/test_helper.exs` | test | bootstrap | `test/test_helper.exs` | exact |
| `mailglass_admin/test/test_helper.exs` | test | bootstrap | `mailglass_admin/test/test_helper.exs` | exact |
| `test/support/citext_probe.ex` | utility | bootstrap | `test/support/citext_probe.ex` | exact |
| `mailglass_admin/test/support/citext_probe.ex` | utility | bootstrap | `mailglass_admin/test/support/citext_probe.ex` | exact |
| `test/support/data_case.ex` | test | CRUD | `test/support/data_case.ex` | exact |
| `test/support/mailer_case.ex` | test | event-driven | `test/support/mailer_case.ex` | exact |
| `mailglass_admin/test/support/live_view_case.ex` | test | request-response | `mailglass_admin/test/support/live_view_case.ex` | exact |
| `test/mailglass/docs_contract_test.exs` | test | contract | `test/mailglass/docs_contract_test.exs` | exact |
| `test/mailglass/docs/operator_incident_support_guide_test.exs` | test | contract | `test/mailglass/docs/operator_incident_support_guide_test.exs` | exact |
| `test/mailglass/operator/support_summary_test.exs` | test | CRUD | `test/mailglass/operator/support_summary_test.exs` | exact |
| `test/mailglass/webhook/telemetry_test.exs` | test | event-driven | `test/mailglass/webhook/telemetry_test.exs` | exact |
| `test/mailglass/telemetry_test.exs` | test | event-driven | `test/mailglass/telemetry_test.exs` | exact |
| `test/mailglass/webhook/replay_test.exs` | test | event-driven | `test/mailglass/webhook/replay_test.exs` | exact |
| `test/mailglass/webhook/reconciler_test.exs` | test | batch | `test/mailglass/webhook/reconciler_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test | request-response | `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs` | test | smoke | `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs` | exact |

## Pattern Assignments

### Required vs Advisory Workflow Split

**Required core lanes stay in `ci.yml` and are explicit jobs, not conditional tags.**

**Source:** `.github/workflows/ci.yml:79-105`
```yaml
compile_no_optional_deps:
  name: Compile No Optional Deps (Elixir 1.18 / OTP 27)
  ...
  - name: Compile without optional deps
    run: mix compile --no-optional-deps --warnings-as-errors
```

**Source:** `.github/workflows/ci.yml:107-163`
```yaml
tests:
  name: Tests (Elixir 1.18 / OTP 27)
  ...
  - name: Wait for postgres + create test DB
    run: |
      until pg_isready -h localhost -U postgres; do sleep 1; done
      mix ecto.create -r Mailglass.TestRepo --quiet
  - name: Run tests (halt-on-failure)
    run: mix test --warnings-as-errors
```

**Existing repo pattern:** root `mix test` is the authoritative core `mailglass` gate, and compile-without-optional-deps is already a required consumer-shape lane.

**Admin required coverage is split into its own package-local job, not folded into root `mix test`.**

**Source:** `.github/workflows/ci.yml:366-417`
```yaml
admin_smoke_gate:
  name: Admin Smoke Gate (Elixir 1.18 / OTP 27)
  ...
  - name: Install admin deps
    working-directory: mailglass_admin
    run: mix deps.get
  - name: Run admin smoke gate
    run: cd mailglass_admin && mix test --only admin_smoke --warnings-as-errors
```

**Advisory matrix currently duplicates required root compile/test signal.**

**Source:** `.github/workflows/advisory-matrix.yml:20-78`
```yaml
advisory_compile_and_test:
  ...
  - name: Compile
    run: mix compile --warnings-as-errors
  - name: Run advisory tests
    run: mix test --warnings-as-errors --exclude provider_live
```

**Planner guidance:** reuse the explicit required/advisory naming split, but avoid keeping an advisory lane that only reruns the same root compile/test contract with little extra signal.

**Provider-live is already correctly advisory-only.**

**Source:** `.github/workflows/provider-live.yml:3-6, 17-18, 49-57`
```yaml
on:
  schedule:
    - cron: "33 6 * * *"
  workflow_dispatch:

provider_live:
  name: Provider Live Advisory (Elixir 1.18 / OTP 27)
  ...
  - name: Run provider-live tests
    run: mix test --only provider_live --warnings-as-errors

notify_provider_live_failure:
  needs: [provider_live]
  if: failure()
  continue-on-error: true
```

**Planner guidance:** reuse this canary posture for true networked/provider-secret coverage. Do not promote it into PR-required truth.

### Package-Local Test Ownership Boundaries

**Core package owns its own DB/bootstrap lifecycle.**

**Source:** `test/test_helper.exs:29-48, 55-77`
```elixir
migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

Application.put_env(
  :mailglass,
  Mailglass.TestRepo,
  Keyword.put(test_repo_config, :pool, DBConnection.ConnectionPool)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(Mailglass.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

{:ok, _pid} = Mailglass.TestRepo.start_link()
Mailglass.TestSupport.CitextProbe.run([])
Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)
```

**Admin package owns a separate helper and repo bootstrap.**

**Source:** `mailglass_admin/test/test_helper.exs:3-24`
```elixir
migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

{:ok, _, _} =
  Ecto.Migrator.with_repo(MailglassAdmin.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

{:ok, _pid} = MailglassAdmin.TestRepo.start_link()
MailglassAdmin.TestSupport.CitextProbe.run([])
Ecto.Adapters.SQL.Sandbox.mode(MailglassAdmin.TestRepo, :manual)
```

**Planner guidance:** keep these authorities local. Reuse a thin repo-root orchestrator if needed, but avoid a shared opaque bootstrap that collapses `mailglass` and `mailglass_admin` ownership.

### Non-Vacuous Smoke and Support-Contract Bundles

**Admin smoke gate has an explicit anti-vacuity precedent.**

**Source:** `mailglass_admin/test/mailglass_admin/post_installer_smoke_test.exs:2-19, 24-47`
```elixir
@moduledoc """
Closes audit blocker G-4 — `admin_smoke_gate` CI job previously matched
zero `@tag :admin_smoke` tests, so the gate passed vacuously...
"""

@tag :admin_smoke
test "post-installer compile path: GET /dev/mail/ resolves without UndefinedFunctionError", %{conn: conn} do
  conn = get(conn, "/dev/mail/")
  assert conn.status in [200, 302]
end

@tag :admin_smoke
test "post-installer route table: mailglass_admin_routes macro produces expected GET routes" do
  routes = MailglassAdmin.TestAdopter.Router.__routes__()
  assert Enum.any?(routes, fn r -> r.verb == :get and r.path == "/dev/mail" end)
end
```

**Core support-contract bundle already exists across docs, support summary, telemetry, replay, and reconcile semantics.**

**Source:** `test/mailglass/docs_contract_test.exs:86-118`
```elixir
test "Phase 33 support docs use the shipped telemetry and repair vocabulary" do
  assert telemetry =~ "[:mailglass, :webhook, :reconcile"
  assert troubleshooting =~ "replay facts"
  assert troubleshooting =~ "reconcile facts"
  assert webhooks =~ "Replay acts on one exact stored webhook row"
  assert admin =~ "mix mailglass.reconcile"
end
```

**Source:** `test/mailglass/docs/operator_incident_support_guide_test.exs:16-40`
```elixir
test "separates provider lifecycle facts, replay facts, and reconcile facts in each stage" do
  assert guide =~ "## Orphan backlog and reconcile facts"
  assert guide =~ "### Replay facts"
  assert guide =~ "### Reconcile facts"
end

test "includes honesty notes and current telemetry vocabulary" do
  assert guide =~ "Mailglass can tell you this"
  assert guide =~ "Mailglass cannot tell you this"
  refute guide =~ "raw_payload"
end
```

**Source:** `test/mailglass/operator/support_summary_test.exs:10-36, 119-134`
```elixir
test "returns four explicit support buckets" do
  assert Map.keys(summary) == [
           :failed_ingest,
           :orphan_backlog,
           :replay_outcomes,
           :reconcile_facts
         ]
end

test "keeps replay outcomes distinct from reconcile facts" do
  assert summary.replay_outcomes.latest.outcome == "replayed"
  assert summary.reconcile_facts.latest_reconciled.reconciled_from_event_id ==
           reconciled.orphan.id
  refute summary.reconcile_facts.latest_reconciled.event_id == replay.replayed.id
end
```

**Source:** `mailglass_admin/test/mailglass_admin/operator_live_test.exs:168-197, 199-254`
```elixir
test "renders support cards, masks overview recipients, and distinguishes replay audit from reconcile facts", %{conn: conn} do
  assert html =~ "Replay audit"
  assert html =~ "Reconcile fact"
  assert list_html =~ "s*******@e******.com"
  refute list_html =~ selected_delivery.recipient
end

test "support card drilldowns reveal concrete webhook, replay audit, orphan, and reconcile exemplars", %{conn: conn} do
  assert replay_html =~ "Showing replay audit fact"
  assert reconcile_html =~ "Showing reconcile fact"
  assert detail_html =~ ~s(pm-support-linked)
end
```

**Planner guidance:** Phase 34 should compose required gates from these explicit, non-vacuous contracts rather than from broad suite labels or tag filters that can silently match nothing.

### Bootstrap and CITEXT Reliability Patterns

**Core CITEXT probe is semantic and repo-aware.**

**Source:** `test/support/citext_probe.ex:29-43, 47-73`
```elixir
def run(opts \\ []) do
  repo = Keyword.get(opts, :repo, Mailglass.TestRepo)

  max_attempts =
    Keyword.get_lazy(opts, :max_attempts, fn ->
      pool_size = repo.config() |> Keyword.get(:pool_size, 5)
      max(pool_size + 1, 5)
    end)

  do_probe(repo, max_attempts)
end

defp do_probe(repo, remaining) do
  try do
    case SuppressionStore.check(%{tenant_id: "__probe__", address: "probe@example.test"}) do
      :not_suppressed -> :ok
      {:suppressed, _entry} -> :ok
      {:error, _reason} -> :ok
    end
    ...
  rescue
    Postgrex.Error -> do_probe(repo, remaining - 1)
  end
end
```

**Admin CITEXT probe is simpler raw-SQL bootstrap coverage.**

**Source:** `mailglass_admin/test/support/citext_probe.ex:4-7, 12-35`
```elixir
def run(opts \\ []) do
  repo = Keyword.get(opts, :repo, MailglassAdmin.TestRepo)
  max_attempts = Keyword.get(opts, :max_attempts, 5)
  do_probe(repo, max_attempts)
end

defp do_probe(repo, remaining) do
  try do
    repo.query!("SELECT id FROM mailglass_suppressions WHERE tenant_id = $1 LIMIT 1", ["__probe__"])
    repo.query!(... INSERT INTO mailglass_suppressions ...)
    repo.query!("DELETE FROM mailglass_suppressions WHERE tenant_id = $1", ["__probe__"])
    :ok
  rescue
    Postgrex.Error -> do_probe(repo, remaining - 1)
  end
end
```

**Per-test templates re-run the probe after sandbox checkout.**

**Source:** `test/support/data_case.ex:34-73`
```elixir
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

  Mailglass.TestSupport.CitextProbe.run([])
  tenant_id = Map.get(tags, :tenant, "test-tenant")
  unless tenant_id == :unset do
    Mailglass.Tenancy.put_current(tenant_id)
  end
end
```

**Source:** `test/support/mailer_case.ex:88-106`
```elixir
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mailglass.TestRepo, shared: not async?)
Mailglass.TestSupport.CitextProbe.run([])
:ok = Mailglass.Adapters.Fake.checkout()
if tenant_id, do: Mailglass.Tenancy.put_current(tenant_id)
```

**Source:** `mailglass_admin/test/support/live_view_case.ex:29-40`
```elixir
setup_all do
  MailglassAdmin.TestSupport.AdminBootstrap.setup_all()
end

setup do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MailglassAdmin.TestRepo, shared: true)
  MailglassAdmin.TestSupport.CitextProbe.run(repo: MailglassAdmin.TestRepo)
  Mailglass.Tenancy.put_current("test-tenant")
  {:ok, conn: MailglassAdmin.TestSupport.AdminBootstrap.build_conn()}
end
```

**Likely failure seams to plan around:**
- helper-level migration/bootstrap changes can invalidate trust for an entire package suite
- CITEXT retry loops are tolerated only as bootstrap honesty machinery, not as broad failure masking
- admin LiveView tests depend on `shared: true` sandbox + synthetic endpoint bootstrap; do not treat them as interchangeable with root DataCase tests

### High-Signal Regression Contracts to Reuse

**Telemetry truth is asserted structurally, not by vague snapshot text.**

**Source:** `test/mailglass/webhook/telemetry_test.exs:29-75, 230-260`
```elixir
test "emits :start and :stop events with whitelist-conformant metadata" do
  ...
  refute_pii(start_meta)
  refute_pii(stop_meta)
end

test "emits :start and :stop events with reconcile metadata" do
  meta = %{
    tenant_id: "t1",
    scanned_count: 5,
    linked_count: 3,
    remaining_orphan_count: 2,
    status: :ok
  }
```

**Source:** `test/mailglass/telemetry_test.exs:84-116, 151-203`
```elixir
test "telemetry handler that raises does NOT crash the caller" do
  result =
    capture_log(fn ->
      Mailglass.Telemetry.render_span(%{tenant_id: "t1", mailable: TestMailer}, fn -> :pipeline_result end)
    end)
  |> tap(fn log -> assert log =~ "has failed and has been detached" end)
end

property "stop event metadata keys are a subset of the whitelist across many renders" do
  ...
  assert MapSet.subset?(MapSet.new(user_keys), MapSet.new(@whitelisted_keys))
end
```

**Replay/reconcile contracts prove support truth semantics, not just code execution.**

**Source:** `test/mailglass/webhook/replay_test.exs:12-37, 64-92, 95-137`
```elixir
test "successfully replays one stored webhook target and records requested and completed audit facts" do
  assert result.status == :replayed
  [requested] = replay_events_for(webhook_event.id, :webhook_replay_requested)
  [succeeded] = replay_events_for(webhook_event.id, :webhook_replay_succeeded)
end

test "returns a noop outcome when replay converges on existing ledger rows" do
  assert result.status == :noop
  assert result.new_event_count == 0
end

test "records a failed audit fact when replay cannot resolve a provider module" do
  assert {:error, :unknown_provider} = Replay.execute(...)
  [failed] = replay_events_for(webhook_event.id, :webhook_replay_failed)
end
```

**Source:** `test/mailglass/webhook/reconciler_test.exs:47-110, 139-221`
```elixir
test "APPENDS a new :reconciled event; orphan row is unchanged" do
  assert reconciled.metadata["reconciled_from_event_id"] == orphan.id
  assert orphan_after.delivery_id == nil
  assert orphan_after.needs_reconciliation == true
end

test "skips orphans younger than 60 seconds" do
  assert scanned == 0
  assert linked == 0
end

test "always exports reconcile/2 and gates worker entrypoints behind available?/0" do
  assert function_exported?(Reconciler, :reconcile, 2)
  assert Reconciler.available?() in [true, false]
end
```

## Shared Patterns

### Required Gate Construction
- Reuse explicit job names and separate package-local commands.
- Prefer direct test file lists or dedicated mix aliases over tag-only required gates unless the suite contains a non-vacuity guard like `post_installer_smoke_test.exs`.

### Trust Semantics
- Reuse structural assertions about what the product can and cannot claim: telemetry whitelist, replay audit vs reconcile fact separation, tenant/window scoping, masked overview recipients.
- Avoid “green because skipped” or “green because broad root suite happened not to cover admin/support surfaces.”

### Bootstrap Ownership
- Root helpers own `Mailglass.TestRepo` migration/startup/CITEXT behavior.
- Admin helpers own `MailglassAdmin.TestRepo` migration/startup/CITEXT behavior and LiveView bootstrap.
- Avoid introducing one global repo-root test helper that hides which package bootstrap failed.

## Concrete Recommendations for the Planner

- Reuse `ci.yml` as the required contract source of truth and add any new Phase 34 required support-contract gate there, alongside `compile_no_optional_deps` and `admin_smoke_gate`.
- Reuse package-local authorities underneath any repo-root entrypoint: root `mix test` for core, `cd mailglass_admin && ...` for admin.
- Reuse the existing support-contract files as the nucleus of the required regression bundle: docs contract, operator incident guide contract, support summary, webhook telemetry, replay, reconciler, and admin operator LiveView.
- Reuse the anti-vacuity lesson from `post_installer_smoke_test.exs`; avoid required jobs whose selector can match zero tests.
- Avoid treating `advisory-matrix.yml` as meaningful unless it is repurposed to carry deterministic signal beyond the required jobs.
- Avoid changing CITEXT/bootstrap helpers casually; these are trust-critical seams and likely the first place a “gate says green but suite is lying” failure emerges.

## Metadata

**Analog search scope:** `.github/workflows`, `test/`, `mailglass_admin/test/`
**Pattern extraction date:** 2026-05-05
