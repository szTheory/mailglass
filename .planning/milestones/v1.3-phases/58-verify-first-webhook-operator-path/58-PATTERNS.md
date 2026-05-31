# Phase 58: verify-first-webhook-operator-path - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/mailglass.trust.run.ex` | task/service | batch, request-response proof | `lib/mix/tasks/mailglass.trust.run.ex` | exact |
| `lib/mailglass/reference_host/trust_checkpoint.ex` | utility/encoder | transform | `lib/mailglass/reference_host/trust_checkpoint.ex` | exact |
| `test/support/reference_host/trust_runner_fixtures.ex` | test fixture | batch, transform | `test/support/reference_host/trust_runner_fixtures.ex` | exact |
| `scripts/check_trust_runner_checkpoint.sh` | script/config validator | batch, file-I/O | `scripts/check_trust_runner_checkpoint.sh` | exact |
| `test/reference_host/trust_runner_command_contract_test.exs` | test | batch, contract | `test/reference_host/trust_runner_command_contract_test.exs` | exact |
| `test/reference_host/trust_runner_checkpoint_contract_test.exs` | test | batch, file-I/O | `test/reference_host/trust_runner_checkpoint_contract_test.exs` | exact |
| `test/reference_host/webhook_operator_path_test.exs` | test | request-response, CRUD side-effect proof | `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` | role-match |
| `reference/host_app/lib/mailglass_reference_host_web/router.ex` | route | request-response | `reference/host_app/lib/mailglass_reference_host_web/router.ex` | exact |
| `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` | test | request-response, verify-first | `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` | exact |
| `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | test | request-response, operator diagnosis | `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | exact |

## Pattern Assignments

### `lib/mix/tasks/mailglass.trust.run.ex` (task/service, batch)

**Analog:** `lib/mix/tasks/mailglass.trust.run.ex`

**Imports and task shape** (lines 1-7):
```elixir
defmodule Mix.Tasks.Mailglass.Trust.Run do
  use Boundary, classify_to: Mailglass

  use Mix.Task
  alias Mailglass.ReferenceHost.TrustCheckpoint

  @shortdoc "Run deterministic reference-host trust stages"
```

**CLI and stage pipeline pattern** (lines 30-63):
```elixir
@default_checkpoint_out "tmp/mailglass_trust_runner/checkpoint.json"
@stage_pipeline [:install, :preview, :send, :webhook_ingest, :operator_troubleshooting]
@allowed_statuses ["completed", "dry_run"]

@impl Mix.Task
def run(argv) do
  {opts, rest, invalid} =
    OptionParser.parse(argv,
      strict: [checkpoint_out: :string, host_root: :string, dry_run: :boolean]
    )

  validate_cli!(opts, rest, invalid)

  host_root =
    opts
    |> Keyword.get(:host_root, "reference/host_app")
    |> Path.expand(File.cwd!())

  checkpoint_out =
    opts
    |> Keyword.get(:checkpoint_out, @default_checkpoint_out)
    |> Path.expand(File.cwd!())

  dry_run? = opts[:dry_run] == true

  ensure_host_root!(host_root)

  stage_records =
    host_root
    |> build_stage_records(dry_run?)
    |> validate_stage_records!()

  write_checkpoint(checkpoint_out, host_root, dry_run?, stage_records)
  emit_stage_records(stage_records, checkpoint_out)
end
```

**Stage-record construction pattern** (lines 95-110):
```elixir
defp build_stage_records(host_root, dry_run?) do
  Enum.map(@stage_pipeline, fn stage_key ->
    signal = stage_signal(stage_key, host_root, dry_run?)

    if is_nil(signal) do
      runner_error!("missing required stage signal #{inspect(stage_key)}")
    end

    stage_name = Atom.to_string(stage_key)

    %{
      "stage_key" => stage_name,
      "status" => signal_to_status(signal),
      "fixture_id" => "trust.#{stage_name}.001"
    }
  end)
end
```

**Validation and checkpoint write pattern** (lines 156-190):
```elixir
defp validate_stage_records!(stage_records) do
  expected_stage_keys = Enum.map(@stage_pipeline, &Atom.to_string/1)
  actual_stage_keys = Enum.map(stage_records, &Map.fetch!(&1, "stage_key"))

  if actual_stage_keys != expected_stage_keys do
    runner_error!(
      "deterministic stage order drifted. expected #{inspect(expected_stage_keys)}, got #{inspect(actual_stage_keys)}"
    )
  end

  case Enum.find(stage_records, &(&1["status"] not in @allowed_statuses)) do
    nil -> stage_records
    stage_record ->
      runner_error!(
        "invalid stage status #{inspect(stage_record["status"])} for #{inspect(stage_record["stage_key"])}"
      )
  end
end

defp write_checkpoint(checkpoint_out, _host_root, _dry_run?, stage_records) do
  payload = TrustCheckpoint.encode(stage_records)
  checkpoint_out |> Path.dirname() |> File.mkdir_p!()
  File.write!(checkpoint_out, Jason.encode_to_iodata!(payload, pretty: true))
end
```

**Planner note:** Keep `@stage_pipeline` keys unchanged. Add Phase 58 evidence under `webhook_ingest` and `operator_troubleshooting`; do not add a new Mix task or rename the alias.

---

### `lib/mailglass/reference_host/trust_checkpoint.ex` (utility, transform)

**Analog:** `lib/mailglass/reference_host/trust_checkpoint.ex`

**Schema, boundary, and stage order pattern** (lines 6-16):
```elixir
@schema_version "trust_runner.v1"

@claim_boundary "reference-host trust-journey confidence only; signed-negative webhook and non-happy-path diagnosis are deferred to Phase 58"

@stage_order %{
  "install" => 1,
  "preview" => 2,
  "send" => 3,
  "webhook_ingest" => 4,
  "operator_troubleshooting" => 5
}
```

**Encoder pattern** (lines 24-37):
```elixir
@spec encode([map()]) :: map()
def encode(checkpoints) when is_list(checkpoints) do
  normalized_rows =
    checkpoints
    |> Enum.map(&normalize_row/1)
    |> Enum.sort_by(&row_sort_key/1)

  %{
    "schema_version" => @schema_version,
    "claim_boundary" => @claim_boundary,
    "checkpoint_count" => Enum.count(normalized_rows),
    "checkpoint_sha256" => checkpoint_sha256(normalized_rows),
    "checkpoints" => normalized_rows
  }
end
```

**Normalization and hash pattern** (lines 40-64):
```elixir
defp normalize_row(row) when is_map(row) do
  stage = row["stage"] || row[:stage] || row["stage_key"] || row[:stage_key]
  status = row["status"] || row[:status] || "completed"
  fixture_id = row["fixture_id"] || row[:fixture_id] || "#{stage}.fixture"

  %{
    "stage" => to_string(stage),
    "status" => to_string(status),
    "fixture_id" => to_string(fixture_id)
  }
end

defp checkpoint_sha256(rows) do
  rows
  |> Enum.map(fn row -> "#{row["stage"]}|#{row["status"]}|#{row["fixture_id"]}" end)
  |> Enum.join("\n")
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

**Planner note:** If evidence becomes part of each checkpoint row, preserve deterministic canonicalization. Either keep the SHA on the existing `stage|status|fixture_id` triple or update encoder, validator, and tests together.

---

### `test/support/reference_host/trust_runner_fixtures.ex` (test fixture, transform)

**Analog:** `test/support/reference_host/trust_runner_fixtures.ex`

**Stable fixture catalog pattern** (lines 6-24):
```elixir
@stage_rows [
  %{fixture_id: "trust.install.001", stage: "install", order: 1},
  %{fixture_id: "trust.preview.001", stage: "preview", order: 2},
  %{fixture_id: "trust.send.001", stage: "send", order: 3},
  %{fixture_id: "trust.webhook_ingest.001", stage: "webhook_ingest", order: 4},
  %{fixture_id: "trust.operator_troubleshooting.001", stage: "operator_troubleshooting", order: 5}
]

@spec stage_fixtures() :: [map()]
def stage_fixtures do
  @stage_rows
  |> Enum.map(fn row ->
    %{"fixture_id" => row.fixture_id, "stage" => row.stage, "order" => row.order}
  end)
  |> Enum.sort_by(fn row -> {row["order"], row["stage"], row["fixture_id"]} end)
end
```

**Lookup pattern** (lines 27-38):
```elixir
@spec stage_names() :: [String.t()]
def stage_names do
  stage_fixtures()
  |> Enum.map(& &1["stage"])
end

@spec fixture_for_stage(String.t() | atom()) :: map() | nil
def fixture_for_stage(stage) when is_atom(stage), do: fixture_for_stage(Atom.to_string(stage))

def fixture_for_stage(stage) when is_binary(stage) do
  Enum.find(stage_fixtures(), &(&1["stage"] == stage))
end
```

**Planner note:** Add deterministic proof fixture helpers here only if they are reusable by runner and tests. Keep fixture IDs stable.

---

### `scripts/check_trust_runner_checkpoint.sh` (script/config validator, file-I/O)

**Analog:** `scripts/check_trust_runner_checkpoint.sh`

**Shell wrapper pattern** (lines 1-6, 21-44):
```bash
#!/usr/bin/env bash
# Validate deterministic trust-runner checkpoint contract artifacts.

set -euo pipefail

CHECKPOINT_PATH="tmp/mailglass_trust_runner/checkpoint.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      CHECKPOINT_PATH="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Trust runner checkpoint validation blocked: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

python3 - "$CHECKPOINT_PATH" <<'PY'
```

**Schema and stage validation pattern** (lines 50-62, 72-90, 128-132):
```python
expected_schema = "trust_runner.v1"
expected_boundary = (
    "reference-host trust-journey confidence only; signed-negative webhook and "
    "non-happy-path diagnosis are deferred to Phase 58"
)
required_stages = [
    "install",
    "preview",
    "send",
    "webhook_ingest",
    "operator_troubleshooting",
]

required_keys = [
    "schema_version",
    "claim_boundary",
    "checkpoint_count",
    "checkpoint_sha256",
    "checkpoints",
]

if stages != required_stages:
    errors.append(f"stage order mismatch: expected {required_stages}, got {stages}")
```

**Hash validation pattern** (lines 134-150):
```python
hash_rows = []
for row in checkpoints:
    if not isinstance(row, dict):
        continue

    stage = row.get("stage")
    status = row.get("status")
    fixture_id = row.get("fixture_id")

    if isinstance(stage, str) and isinstance(status, str) and isinstance(fixture_id, str):
        hash_rows.append(f"{stage}|{status}|{fixture_id}")

computed_sha = hashlib.sha256("\n".join(hash_rows).encode()).hexdigest()
if checkpoint.get("checkpoint_sha256") != computed_sha:
    errors.append(
        "checkpoint_sha256 mismatch: expected deterministic SHA from ordered checkpoint rows"
    )
```

**Planner note:** Extend validation for Phase 58 evidence fields with type/closed-value checks. Keep Python deterministic and avoid parsing raw payload bodies.

---

### `test/reference_host/trust_runner_command_contract_test.exs` (test, contract)

**Analog:** `test/reference_host/trust_runner_command_contract_test.exs`

**Token contract pattern** (lines 8-27):
```elixir
test "JOUR-01 canonical command and deterministic stages are pinned" do
  files_with_content = [
    {@mix_path, File.read!(@mix_path)},
    {@task_path, File.read!(@task_path)}
  ]

  required_tokens = [
    "verify.reference_host.journey",
    "mailglass.trust.run",
    "install",
    "preview",
    "send",
    "webhook_ingest",
    "operator_troubleshooting"
  ]

  Enum.each(required_tokens, fn token ->
    assert token_present?(files_with_content, token),
           "JOUR-01 command drift: required token missing #{inspect(token)}"
  end)
end
```

**Deferred-boundary pattern to retire/update** (lines 30-47):
```elixir
test "JOUR-03 and JOUR-04 remain explicitly deferred to Phase 58" do
  readme = File.read!(@readme_path)

  required_tokens = [
    "mix verify.reference_host.journey",
    "signed-negative webhook proof",
    "non-happy-path operator diagnosis",
    "JOUR-03",
    "JOUR-04",
    "deferred to Phase 58",
    "Phase 58"
  ]

  Enum.each(required_tokens, fn token ->
    assert String.contains?(readme, token),
           "Phase boundary drift: required token missing #{inspect(token)}"
  end)
end
```

**Planner note:** Phase 58 should replace the "deferred" assertion with proof-complete wording while keeping the canonical command and stage tokens pinned.

---

### `test/reference_host/trust_runner_checkpoint_contract_test.exs` (test, file-I/O)

**Analog:** `test/reference_host/trust_runner_checkpoint_contract_test.exs`

**Dry-run deterministic checkpoint pattern** (lines 6-39):
```elixir
test "two dry runs emit deterministic equivalent checkpoints with stable hash" do
  checkpoint_dir = Path.join(@project_root, "tmp/mailglass_trust_runner")
  checkpoint_1 = Path.join(checkpoint_dir, "checkpoint-1.json")
  checkpoint_2 = Path.join(checkpoint_dir, "checkpoint-2.json")

  File.rm_rf!(checkpoint_dir)
  File.mkdir_p!(checkpoint_dir)

  assert {_, 0} =
           System.cmd(
             "mix",
             ["verify.reference_host.journey", "--dry-run", "--checkpoint-out", checkpoint_1],
             cd: @project_root,
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           )

  assert {_, 0} =
           System.cmd(
             "mix",
             ["verify.reference_host.journey", "--dry-run", "--checkpoint-out", checkpoint_2],
             cd: @project_root,
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           )

  payload_1 = decode!(checkpoint_1)
  payload_2 = decode!(checkpoint_2)

  assert normalize(payload_1) == normalize(payload_2)
  assert payload_1["checkpoint_sha256"] == payload_2["checkpoint_sha256"]
  assert payload_1["schema_version"] == "trust_runner.v1"
  assert payload_1["claim_boundary"] =~ "deferred to Phase 58"
end
```

**Normalizer pattern** (lines 41-51):
```elixir
defp normalize(payload) do
  %{
    "schema_version" => payload["schema_version"],
    "claim_boundary" => payload["claim_boundary"],
    "checkpoint_count" => payload["checkpoint_count"],
    "checkpoint_sha256" => payload["checkpoint_sha256"],
    "checkpoints" => payload["checkpoints"]
  }
end
```

**Planner note:** Add assertions for Phase 58 evidence determinism here after the encoder/validator shape is chosen.

---

### `test/reference_host/webhook_operator_path_test.exs` (test, request-response)

**Analog:** `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`

**Test double setup pattern for verify-first side effects** (lines 6-18, 32-60):
```elixir
defmodule TenantResolver do
  @behaviour Mailglass.Tenancy

  def scope(query, _context), do: query
  def resolve_outbound_adapter_ref(_context), do: :default

  def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tenant_id}})
      when is_binary(tenant_id) and tenant_id != "" do
    Process.put(:mailglass_inbound_tenant_resolved, true)
    {:ok, tenant_id}
  end

  def resolve_webhook_tenant(_context), do: {:error, :missing_path_param}
end

defmodule FakePersistence do
  def persist(handoff, opts) do
    Process.put(:mailglass_inbound_last_handoff, handoff)
    Process.put(:mailglass_inbound_last_persist_opts, opts)
    Process.put(:mailglass_inbound_execution_order, [:persist | Process.get(:mailglass_inbound_execution_order, [])])
    ...
  end
end

defmodule FakeExecution do
  def dispatch(result, _opts \\ []) do
    Process.put(:mailglass_inbound_last_execution_result, result)
    Process.put(:mailglass_inbound_execution_order, [:dispatch | Process.get(:mailglass_inbound_execution_order, [])])
    ...
  end
end
```

**Application env cleanup pattern** (lines 133-170):
```elixir
setup do
  prior_tenancy = Application.get_env(:mailglass, :tenancy)
  prior_postmark = Application.get_env(:mailglass_inbound, :postmark)

  Application.put_env(:mailglass, :tenancy, TenantResolver)

  Application.put_env(:mailglass_inbound, :postmark,
    basic_auth: {"postmark", "secret"},
    ip_allowlist: []
  )

  Process.delete(:mailglass_inbound_last_handoff)
  Process.delete(:mailglass_inbound_tenant_resolved)
  Process.delete(:mailglass_inbound_last_execution_result)

  on_exit(fn ->
    if is_nil(prior_tenancy), do: Application.delete_env(:mailglass, :tenancy), else: Application.put_env(:mailglass, :tenancy, prior_tenancy)
    if is_nil(prior_postmark), do: Application.delete_env(:mailglass_inbound, :postmark), else: Application.put_env(:mailglass_inbound, :postmark, prior_postmark)
  end)
end
```

**Postmark negative signature pattern** (lines 305-317):
```elixir
test "returns 401 on auth failure" do
  conn =
    Plug.Test.conn(:post, "/inbound/tenant-123/postmark", postmark_payload())
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("authorization", basic_auth("wrong", "secret"))
    |> Plug.Conn.put_private(:raw_body, postmark_payload())
    |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

  conn = IngressPlug.call(conn, IngressPlug.init(provider: :postmark, persistence: FakePersistence))

  assert conn.status == 401
  assert Jason.decode!(conn.resp_body)["reason"] == "bad_credentials"
end
```

**Verify-first negative assertion pattern** (lines 395-407):
```elixir
test "returns 401 on sendgrid auth failure without resolving tenant" do
  conn =
    Plug.Test.conn(:post, "/inbound/tenant-123/sendgrid", sendgrid_params())
    |> Plug.Conn.put_req_header("authorization", basic_auth("wrong", "secret"))
    |> Plug.Conn.put_req_header("content-type", "multipart/form-data; boundary=boundary42")
    |> Map.put(:params, sendgrid_params())
    |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

  conn = IngressPlug.call(conn, IngressPlug.init(provider: :sendgrid, persistence: FakePersistence))

  assert conn.status == 401
  assert Jason.decode!(conn.resp_body)["reason"] == "bad_credentials"
  refute Process.get(:mailglass_inbound_tenant_resolved)
end
```

**Payload helper pattern** (lines 809-835):
```elixir
defp conn_with_auth(body) do
  Plug.Test.conn(:post, "/inbound/tenant-123/postmark", body)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> Plug.Conn.put_req_header("authorization", basic_auth("postmark", "secret"))
  |> Plug.Conn.put_private(:raw_body, body)
end

defp basic_auth(user, pass) do
  "Basic " <> Base.encode64("#{user}:#{pass}")
end

defp postmark_payload do
  Jason.encode!(%{
    "FromFull" => [%{"Email" => "sender@example.com", "Name" => "Sender"}],
    "ToFull" => [%{"Email" => "support@example.com", "Name" => "Support"}],
    "Subject" => "Support request",
    "MessageID" => "pm-message-123",
    "OriginalRecipient" => "support@example.com",
    "Attachments" => []
  })
end
```

**Planner note:** For the new reference-host route proof, call `MailglassReferenceHostWeb.Router.call/2` on `/inbound/tenant-123/postmark`, not `IngressPlug.call/2` directly. Still copy the auth/body/setup/side-effect assertions from this analog.

---

### `reference/host_app/lib/mailglass_reference_host_web/router.ex` (route, request-response)

**Analog:** `reference/host_app/lib/mailglass_reference_host_web/router.ex`

**Imports and public route seam pattern** (lines 1-22):
```elixir
defmodule MailglassReferenceHostWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router
  import MailglassAdmin.Router

  pipeline :mailglass_webhooks do
    plug :accepts, ["json"]
  end

  # HOST-02 stable seam references:
  # - MailglassAdmin.Router.mailglass_admin_routes/2
  # - MailglassAdmin.Router.mailglass_operator_routes/2
  # - MailglassInbound.Ingress.Plug
  scope "/inbound" do
    pipe_through :mailglass_webhooks
    post "/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark
    post "/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid
  end
end
```

**Public seam contract test pattern** (from `test/reference_host/public_seams_contract_test.exs`, lines 13-31):
```elixir
required_tokens = [
  "Mailglass.deliver/2",
  "Mailglass.deliver!/2",
  "Mailglass.deliver_later/2",
  "mailglass_admin_routes/2",
  "mailglass_operator_routes/2",
  "MailglassInbound.Ingress.Plug",
  "Public seam boundary: this host does not call Mailglass internal modules or provider internals."
]

forbidden_tokens = [
  "Mailglass.Repo",
  "Mailglass.Outbound.Projector",
  "Mailglass.OptionalDeps",
  "MailglassAdmin.Operator.Mount",
  "MailglassInbound.Ingress.Providers",
  "defmodule MailglassInbound.Ingress.Providers",
  "copied provider internals"
]
```

**Planner note:** The route already exists. Tests should prove this router path works; implementation should not couple the host to provider internals.

---

### `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` (test, verify-first)

**Analog:** `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`

**Positive provider path pattern** (lines 340-368):
```elixir
test "supports sendgrid through the shared ingress seam and verifies before tenant resolution" do
  conn =
    sendgrid_conn(sendgrid_params())
    |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

  conn =
    IngressPlug.call(
      conn,
      IngressPlug.init(
        provider: :sendgrid,
        router: TestRouter,
        persistence: FakePersistence,
        execution: FakeExecution
      )
    )

  body = Jason.decode!(conn.resp_body)
  handoff = Process.get(:mailglass_inbound_last_handoff)

  assert conn.status == 200
  assert body["status"] == "inserted"
  assert body["route"] == "matched"
  assert Process.get(:mailglass_inbound_tenant_resolved) == true
  assert handoff.message.provider == :sendgrid
  assert handoff.evidence.verification_facts.auth == :basic_auth
end
```

**Ingress plug implementation invariant** (from `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`, lines 68-132):
```elixir
defp do_call(conn, provider, opts) do
  try do
    request = build_request!(provider, conn)
    config = resolve_config!(provider, conn, opts)

    # Verify signature before tenant lookup to fail closed on spoofed payloads.
    case verify_request!(provider, request, config, opts) do
      {:ok, facts} when is_map(facts) ->
        persist_and_respond(conn, provider, request, facts, opts)

      facts when is_map(facts) ->
        persist_and_respond(conn, provider, request, facts, opts)
    end
  rescue
    e in [SignatureError, InboundSignatureError] ->
      resp = send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})
      {resp, %{provider: provider, status: :rejected}}
  end
end
```

**Postmark real verifier pattern** (from `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex`, lines 12-21, 76-100):
```elixir
def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
  {user, pass} = fetch_basic_auth!(config)
  verify_basic_auth!(headers, user, pass)
  ip_status = verify_ip_allowlist!(config)

  %{auth: :basic_auth, ip_allowlist: ip_status}
end

defp verify_basic_auth!(headers, user, pass) do
  case List.keyfind(headers, "authorization", 0) do
    nil -> raise SignatureError.new(:missing_header, provider: :postmark)
    {"authorization", "Basic " <> b64} ->
      with {:ok, decoded} <- Base.decode64(b64),
           [decoded_user, decoded_pass] <- String.split(decoded, ":", parts: 2),
           true <- Plug.Crypto.secure_compare(decoded_user, user),
           true <- Plug.Crypto.secure_compare(decoded_pass, pass) do
        :ok
      else
        false -> raise SignatureError.new(:bad_credentials, provider: :postmark)
        _ -> raise SignatureError.new(:malformed_header, provider: :postmark)
      end
  end
end
```

**Planner note:** Prefer Postmark for the representative route-level proof because JSON payload + Basic Auth is already deterministic and still uses real provider verification.

---

### `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` (test, operator diagnosis)

**Analog:** `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`

**No-match-only routing trace rendering pattern** (from `mailglass_admin/lib/mailglass_admin/inbound_live.ex`, lines 316-323 and 357-371):
```elixir
<RoutingTrace.routing_trace
  :if={@detail[:outcome] == :no_match}
  trace={@routing_trace}
/>

defp routing_trace_for(_inbound_router, nil), do: []

defp routing_trace_for(inbound_router, %{outcome: :no_match, record: record}) do
  if gateway_available?() do
    apply(@gateway, :explain_routes, [inbound_router, record])
  else
    []
  end
end

defp routing_trace_for(_inbound_router, _detail), do: []
```

**Fixture pattern for `:no_match` operator evidence** (from `mailglass_admin/test/support/inbound_fixtures.ex`, lines 107-123):
```elixir
@doc """
Seeds a record whose only fresh run is `:no_match` (routing-trace eligible).
Returns `%{record: record, evidence: evidence, run: run}`.
"""
def seed_no_match!(tenant_id, opts \\ []) do
  record = insert_record!(tenant_id, opts)
  evidence = insert_evidence!(tenant_id, record.id, Keyword.get(opts, :evidence, []))

  run =
    insert_run!(tenant_id, record.id, evidence.id,
      source: :fresh,
      outcome: :no_match,
      executed_at: hours_ago(1)
    )

  %{record: record, evidence: evidence, run: run}
end
```

**Routing-trace assertion pattern** (lines 351-389):
```elixir
test "renders per-route clause diffs from explain/2 for a :no_match record", %{conn: conn} do
  conn = operator_conn(conn)

  %{record: record} =
    InboundFixtures.seed_no_match!(@tenant_id,
      recipient: "nobody@example.com",
      subject: "general question",
      headers: %{}
    )

  {:ok, _view, html} =
    live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

  assert html =~ ~s(data-testid="inbound-routing-trace")
  assert html =~ "Routing trace"
  assert html =~ "Why this message did not match"

  trace_cards =
    html
    |> String.split(~s(data-testid="inbound-route-card"))
    |> length()
    |> Kernel.-(1)

  assert trace_cards == 3
  assert html =~ "Recipient"
  assert html =~ "Subject"
  assert html =~ "Header: x-priority"
end
```

**PII masking assertion pattern** (lines 391-415):
```elixir
test "renders matcher kinds — nil → any, exact verbatim, regex → ~r/, and masks recipient actual",
     %{conn: conn} do
  conn = operator_conn(conn)

  %{record: record} =
    InboundFixtures.seed_no_match!(@tenant_id,
      recipient: "nomatch@example.com",
      subject: "general question",
      headers: %{}
    )

  {:ok, _view, html} =
    live(conn, inbound_path(%{"tenant_id" => @tenant_id, "inbound_id" => record.id}))

  assert html =~ "support@example.com"
  assert html =~ "~r/"
  assert html =~ ">any<"
  assert html =~ "n******@e******.com"
  refute html =~ "nomatch@example.com"
  assert html =~ "border-l-4 border-error"
end
```

**Planner note:** The runner checkpoint should store deterministic machine-readable facts derived from no-match/routing trace semantics, not raw rendered HTML.

## Shared Patterns

### Public-Seam Boundary

**Source:** `reference/host_app/lib/mailglass_reference_host_web/router.ex` lines 15-22 and `test/reference_host/public_seams_contract_test.exs` lines 23-31

**Apply to:** Reference-host route proof, trust runner webhook stage

```elixir
# HOST-02 stable seam references:
# - MailglassAdmin.Router.mailglass_admin_routes/2
# - MailglassAdmin.Router.mailglass_operator_routes/2
# - MailglassInbound.Ingress.Plug
scope "/inbound" do
  pipe_through :mailglass_webhooks
  post "/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark
  post "/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid
end
```

Avoid `MailglassInbound.Ingress.Providers` in reference-host files.

### Verify-First Failure Handling

**Source:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` lines 68-132

**Apply to:** `webhook_ingest` proof tests and runner evidence

```elixir
request = build_request!(provider, conn)
config = resolve_config!(provider, conn, opts)

# Verify signature before tenant lookup to fail closed on spoofed payloads.
case verify_request!(provider, request, config, opts) do
  {:ok, facts} when is_map(facts) ->
    persist_and_respond(conn, provider, request, facts, opts)
end
```

Bad signatures must assert `401`, `status: "rejected"`, a closed reason such as `"bad_credentials"`, and no tenant/persistence/execution markers.

### Deterministic Checkpoint Contract

**Source:** `lib/mailglass/reference_host/trust_checkpoint.ex` lines 24-64 and `scripts/check_trust_runner_checkpoint.sh` lines 128-150

**Apply to:** Checkpoint encoder, shell validator, checkpoint tests

```elixir
normalized_rows =
  checkpoints
  |> Enum.map(&normalize_row/1)
  |> Enum.sort_by(&row_sort_key/1)

checkpoint_sha256(normalized_rows)
```

If evidence is added, canonicalize it deliberately and test repeatability.

### Operator Evidence Shape

**Source:** `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` lines 18-25 and `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` lines 7-9

**Apply to:** `operator_troubleshooting` checkpoint evidence

```elixir
@type finding :: %{
        required(:check) => atom(),
        required(:status) => :pass | :warn | :fail,
        required(:title) => String.t(),
        required(:observed) => String.t(),
        required(:remediation) => String.t(),
        optional(:evidence) => map()
      }
```

Use bounded observed facts, remediation, and machine-readable evidence. Do not include raw inbound payload bodies or unmasked recipient values.

## No Analog Found

No likely Phase 58 file lacks an analog. The only caution is that `test/reference_host/webhook_operator_path_test.exs` is new, so it must combine two existing analog families: reference-host public-route contracts plus inbound plug verify-first tests.

## Metadata

**Analog search scope:** `lib/`, `test/`, `scripts/`, `reference/`, `mailglass_inbound/`, `mailglass_admin/`
**Files scanned:** 24 candidate files from `rg --files` plus targeted analog reads
**Pattern extraction date:** 2026-05-27
