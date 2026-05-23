# Phase 47: Inbound Test Helpers + Generators - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 9 deliverables (4 inbound `lib/` helpers + 3 core generators + 2 packaging edits) + 7 self-test files
**Analogs found:** 9 / 9 (every deliverable has an in-repo analog; this is a ~90% extract-and-compose phase)

> Repo layout note: the two packages live in one git tree. Core `mailglass` is rooted at `/Users/jon/projects/mailglass/`; the inbound sibling at `/Users/jon/projects/mailglass/mailglass_inbound/`. Generators ship in **core** (`mailglass/lib/mix/tasks/`); the four helpers ship in **inbound** (`mailglass_inbound/lib/`). All paths below are relative to those two roots as noted.

## File Classification

| New/Modified File (pkg) | Role | Data Flow | Closest Analog | Match Quality |
|-------------------------|------|-----------|----------------|---------------|
| `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` | test utility (adopter-exported macros) | event-driven (process-mailbox `assert_received`) | `lib/mailglass/test_assertions.ex` (core) | exact |
| `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` | test case template | request-response (per-test setup/teardown) | `test/support/mailer_case.ex` (core) | role-match (adapt: no async-impl snapshot) |
| `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` | test driver / write-path seam | request-response → persist → sync-execute | `inbound_idempotency_convergence_test.exs:99-102` (inbound) | exact (generalizes the proof) |
| `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` | test fixture builder | transform (code → provider payload) | `ses_provider_test.exs:287-352` + `test/support/webhook_fixtures.ex:194-228` | exact (extract verbatim) |
| `mailglass/lib/mix/tasks/mailglass.gen.mailbox.ex` | generator (Igniter, create) | batch / file-create | `lib/mix/tasks/mailglass.gen.mailable.ex` | exact |
| `mailglass/lib/mix/tasks/mailglass.gen.inbound_router.ex` | generator (Igniter, create) | batch / file-create | `lib/mix/tasks/mailglass.gen.mailable.ex` | exact |
| `mailglass/lib/mix/tasks/mailglass.gen.inbound_route.ex` | generator (Igniter, source-edit) | transform (Sourceror-zipper AST edit) | `lib/mix/tasks/mailglass.upgrade.v0_2.ex:32-88` | role-match (zipper precedent; idiom differs — see Pattern below) |
| `mailglass_inbound/mix.exs` (`files:` + ExDoc `groups_for_modules`) | config | n/a (packaging) | `mailglass_inbound/mix.exs:105-145` (self) | exact (edit in place) |
| 7 self-test files | test | varies | `test/mix/tasks/mailglass.gen.mailable_test.exs` (generators); per-helper inbound tests | exact |

**Self-test file map** (one per deliverable; locations confirmed in RESEARCH Wave 0 Gaps):
- `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs` (ITEST-01..04)
- `mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs` (ITEST-05)
- `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` (ITEST-06)
- `mailglass_inbound/test/mailglass_inbound/fixtures_test.exs` (ITEST-07)
- `mailglass/test/mix/tasks/mailglass.gen.mailbox_test.exs` (IGEN-01)
- `mailglass/test/mix/tasks/mailglass.gen.inbound_router_test.exs` (IGEN-02)
- `mailglass/test/mix/tasks/mailglass.gen.inbound_route_test.exs` (IGEN-03 + idempotency + dry-run)

---

## Pattern Assignments

### `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` (test utility, event-driven)

**Analog:** `lib/mailglass/test_assertions.ex` (core, adopter-exported). The 4-matcher-style macro dispatch is the exact template; swap the captured tuple from `{:mail, _msg}` to `{:inbound, msg, outcome, route}`.

**Module shell + moduledoc posture** (analog lines 1-57): ships in `lib/` (not `test/support/`) because it is adopter-exported; `import ExUnit.Assertions` at the top (compiles in the package — ExUnit is a bundled OTP app, no Hex dep per D-47-02). State the PII policy (failure messages may embed caller values, adopter test output only).

**4-matcher-style macro dispatch** (analog lines 86-119) — copy the head-pattern dispatch verbatim, retargeting the captured tuple:
```elixir
# ITEST-01: bare presence
defmacro assert_inbound_received do
  quote do: assert_received {:inbound, _msg, _outcome, _route}
end

# Style 3: struct pattern (no quoting)
defmacro assert_inbound_received({:%{}, _, _} = pattern) do
  quote do: assert_received {:inbound, unquote(pattern), _outcome, _route}
end

# Style 4: predicate fn
defmacro assert_inbound_received({:fn, _, _} = fun_ast) do
  quote do
    assert_received {:inbound, msg, _outcome, _route}
    fun = unquote(fun_ast)
    assert fun.(msg), "assert_inbound_received predicate returned false for #{inspect(msg)}"
  end
end

# Style 2: keyword list → runtime matcher (mirror __match_keyword__/2)
defmacro assert_inbound_received(params) do
  quote do
    assert_received {:inbound, msg, _outcome, _route}
    MailglassInbound.TestAssertions.__match_keyword__(msg, unquote(params))
  end
end
```

**Keyword matcher fn** (analog lines 121-159, `__match_keyword__/2`) — copy the `Enum.each` + per-key `assert ... , "<field> mismatch"` shape; map keys to `%InboundMessage{}` fields (`:subject`, `:from`/`:to` against `[%{address: …}]` lists, `:tenant` → `:tenant_id`, `:provider`, `:envelope_recipient`). End with the same `flunk("Unsupported matcher key: …")` fallback (analog lines 153-157).

**ITEST-02 outcome assertions** — key off the LOCKED outcome atoms at `mailglass_inbound/lib/mailglass_inbound/mailbox.ex:22` (`:accept | :ignore | {:reject, reason} | {:bounce, reason}`). The captured `outcome` is `execute/2`'s normalized result (`execution.ex:44` `normalize_result/1`). Map: accepted→`:accept`, ignored→`:ignore`, rejected→`{:reject, _}`, bounced→`{:bounce, _}`:
```elixir
defmacro assert_inbound_accepted do
  quote do
    assert_received {:inbound, _msg, outcome, _route}
    assert match?(:accept, outcome) or match?(%{outcome: :accept}, outcome),
           "expected :accept, got #{inspect(outcome)}"
  end
end
# _rejected → {:reject, _}; _ignored → :ignore; _bounced → {:bounce, _}
```
> Planner action: confirm the exact return shape of `Execution.execute/2` (the captured outcome). `execute/2` returns `{:ok, normalized_result}` where `normalized_result` carries `:outcome` (see `execution.ex:44-60` `normalize_result/1` + `stop_metadata.outcome`). Decide whether `Test.Ingress` sends the raw outcome atom or the normalized map; keep ITEST-02 matching consistent with that choice.

**ITEST-03 routing assertions** — read the persisted route map, NOT the reflection directly. `persist.ex:281-293` `route_compatibility/2` returns `%{status: :matched, mailbox: route.mailbox}` or `%{status: :no_match}`. So:
```elixir
def assert_inbound_routed_to(expected_mailbox) do  # arity per discretion
  assert_received {:inbound, _msg, _outcome, route}
  assert match?(%{status: :matched, mailbox: ^expected_mailbox}, route),
         "expected route to #{inspect(expected_mailbox)}, got #{inspect(route)}"
end
def assert_inbound_no_match do
  assert_received {:inbound, _msg, _outcome, route}
  assert match?(%{status: :no_match}, route), "expected :no_match, got #{inspect(route)}"
end
```
> Matching source of truth: `MailglassInbound.Router.Matcher.match/2` (`matcher.ex:8`) + reflection `__mailglass_inbound_routes__/0` (`router.ex:64-72`). The route map is already computed by `Persist`; assertions just match it.

**ITEST-04 negative assertion** (analog lines 206-210, `assert_no_mail_sent`):
```elixir
defmacro assert_no_inbound_received do
  quote do: refute_received {:inbound, _msg, _outcome, _route}
end
```

---

### `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` (test driver / write-path seam, request-response)

**Module name is `MailglassInbound.Test.Ingress`; file lives at `lib/mailglass_inbound/test/ingress.ex`** (a `lib/` path despite "Test" in the name) so `files: ~w(lib …)` packages it. Do NOT place it in `test/support/`.

**Analog:** `inbound_idempotency_convergence_test.exs:99-102` — the canonical persist→sync-execute driver:
```elixir
# Source: mailglass_inbound/test/.../inbound_idempotency_convergence_test.exs:99-102
{:ok, persisted} = Persist.persist(handoff(payload), [])
_ = Execution.execute(persisted, source: :fresh)
```

**Confirmed runtime signatures (the chain Test.Ingress drives):**
- `MailglassInbound.Ingress.Persist.persist/2` — `persist.ex:19-22`:
  `persist(%{tenant_id, provider, message: %InboundMessage{}, evidence} = handoff, opts)`; `opts` reads `:repo` (default `MailglassInbound.Repo`), `:routes`, `:router`. Returns `{:ok, map()}` where the map carries `:status`, `:route` (`%{status: :matched|:no_match, …}`), etc.
- `MailglassInbound.Execution.execute/2` — `execution.ex:37-60` (SYNC): `execute(%{status: :inserted} = persisted, opts)`; reads `:inbound_records`, `:source`. Returns `{:ok, normalized_result}`. `%{status: :duplicate}` short-circuits to `{:ok, %{status: :skipped}}` (`execution.ex:62`).
- Do **NOT** call `dispatch/2` (`execution.ex:14-35`, async via `OptionalDeps.Oban.runner()` → Oban/Task.Supervisor) — non-deterministic run counts (D-47-03/04).

**The capture seam** (the novel bit; resolved in RESEARCH Pattern 1). Outbound captures because `Fake.Storage` does `send(owner, {:mail, %Message{}})` (see `lib/mailglass/test_assertions.ex:33-34`). Inbound has no such storage, so `Test.Ingress` does the `send` itself, in the test process:
```elixir
defmodule MailglassInbound.Test.Ingress do
  alias MailglassInbound.{Execution, InboundMessage}
  alias MailglassInbound.Ingress.Persist

  # ITEST-06 entry 1: takes a %InboundMessage{} (Fixtures-built) + router:/routes:/repo:
  def receive_inbound(%InboundMessage{} = message, opts \\ []) do
    handoff = %{
      tenant_id: message.tenant_id,
      provider: message.provider,
      message: message,
      evidence: Keyword.get(opts, :evidence, %{raw_payload: %{}})
    }
    persist_opts = Keyword.take(opts, [:routes, :router, :repo])

    with {:ok, persisted} <- Persist.persist(handoff, persist_opts),
         {:ok, outcome} <- Execution.execute(persisted, source: :fresh) do
      send(self(), {:inbound, message, outcome, persisted.route})   # CAPTURE SEAM
      {:ok, %{message: message, outcome: outcome, route: persisted.route, persisted: persisted}}
    end
  end
end
```
> **Why `send(self(), …)` not PubSub:** `Test.Ingress` runs synchronously in the test process, so `send(self(), …)` lands the tuple in the same mailbox `assert_received` reads — async-safe per process, no subscription. The PubSub broadcast (`plug.ex:519-527`) only carries `{record_id, %{provider, record_type}}` — insufficient for outcome/route assertions.

**ITEST-06 entry 2 — `receive_provider_payload/3`** runs the REAL provider seam before persist. Provider `verify!`/`normalize` signatures confirmed:
- behaviour: `MailglassInbound.Ingress.Provider` — `verify!/2` (`%Request{}`, config) and `verify!/3` (raw, headers, config); `normalize/1` (`%Request{}`) and `normalize/2` (raw, headers). (`ingress/provider.ex:39-56`)
- Postmark: `verify!/3` + `normalize/2` (`postmark.ex:12,24`); SendGrid: `verify!/2,3` + `normalize/1,2` (`sendgrid.ex:11,19,24,65`); Mailgun: `verify!/2` (params) + `normalize/1,2` (`mailgun.ex:27,74,84`); SES: `verify!/2` + `normalize/1,2` (`ses.ex:50,84,135`). SES verify!/normalize use a process-dict stash (`@pd_key {SES, :verified}`, `ses.ex:47,57`) — self-clearing per process; pass `config: %{s3_fetcher: S3Fetcher.Fake, cert_cache_ttl_seconds: 86_400}` (the seam from `ses_provider_test.exs:240`).
- Build the handoff the way the plug does after normalize (RESEARCH cites `plug.ex:404-434` / `:470`); then the same `Persist.persist/2` + `Execution.execute/2` + capture send.

> **Pitfall 5 (RESEARCH):** SendGrid/Mailgun/SES dedupe on `md5(raw_mime)` when `provider_message_id` is nil. `receive_inbound/2` for those providers MUST pass `evidence: %{raw_mime: …}` or replays look new. Postmark dedupes on `provider_message_id` so empty evidence masks the gap. Cross-test a SendGrid 2-replay → 1 record.

---

### `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` (test case template, request-response)

**Analog:** `test/support/mailer_case.ex` — structure of `use ExUnit.CaseTemplate` + `using do ... end` (analog lines 63-75) + `setup tags do ... end` with `Sandbox.start_owner!` + `Tenancy.put_current` + PubSub subscribe + `on_exit` teardown.

**ADAPT — three concrete divergences from the analog (the high-risk traps):**

1. **Repo resolution from app-env, NEVER `TestRepo`** (RESEARCH COLLISION 1 — CONTEXT was wrong; `TestRepo` is at `mailglass_inbound/test/support/test_repo.ex`, not `lib/`, and is NOT in the package manifest). The analog hardcodes `Mailglass.TestRepo` (analog line 93) and elsewhere falls back to it (`mailer_case.ex:151`). Inbound MUST resolve the adopter's repo and raise if unset:
```elixir
repo = Application.get_env(:mailglass_inbound, :repo) ||
         raise "config :mailglass_inbound, :repo must be set for MailglassInbound.MailboxCase"
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not tags[:async])
```
The library's own self-tests work because `config/test.exs:11` sets `:repo` to `MailglassInbound.TestRepo`. The MailboxCase **source must not contain the literal `TestRepo`** (this is the explicit self-test assertion in RESEARCH Wave 0 Gaps).

2. **Snapshot NOTHING in app-env** (D-47-12 confirmed). The analog snapshots `:async_adapter` + `:async_adapter_impl` (analog lines 123, 130-131) and restores them (analog lines 192-204) — because it *writes* those keys to force sync delivery. Inbound achieves sync execution **structurally** (`Test.Ingress` calls `execute/2` directly), so MailboxCase writes no async-mode app-env key and has nothing to restore. `:async_execution_impl` does not exist anywhere; do NOT invent it. The only teardown is `Sandbox.stop_owner(pid)` + process-global resets in the NEXT setup.

3. **Reset process-global / process-dict fixture state in setup** — the only global state the fixtures touch (the substance of D-47-12). Confirmed from `ses_provider_test.exs:26-28`:
```elixir
Mailglass.Webhook.Providers.SES.CertCache.reset()   # process-global ETS (cert_cache.ex:67)
MailglassInbound.S3Fetcher.Fake.reset()             # current-process dict (s3_fetcher/fake.ex:33)
```
`CertCache.reset/0` is cheap (`:ets.delete_all_objects`); call it even for non-SES tests to prevent cross-test bleed. SES-fixture-driven tests should be `async: false` OR Fixtures should mint a unique cert URL per call (Pitfall 2).

**Skeleton** (copy `using do` + `setup tags` shape from analog lines 63-77, 100-210; strip the Oban/Fake branching that has no inbound analog):
```elixir
defmodule MailglassInbound.MailboxCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import MailglassInbound.TestAssertions
      alias MailglassInbound.{Fixtures, Test}
    end
  end

  setup tags do
    repo = Application.get_env(:mailglass_inbound, :repo) ||
             raise "config :mailglass_inbound, :repo must be set for MailglassInbound.MailboxCase"
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, shared: not tags[:async])

    tenant_id =
      case Map.get(tags, :tenant, "test-tenant") do
        :unset -> nil
        t when is_binary(t) -> t
      end
    if tenant_id, do: Mailglass.Tenancy.put_current(tenant_id)

    Mailglass.Webhook.Providers.SES.CertCache.reset()
    MailglassInbound.S3Fetcher.Fake.reset()

    # Optional best-effort PubSub subscription — wrap in a guard (A1 unconfirmed name).
    if tenant_id do
      Phoenix.PubSub.subscribe(
        MailglassInbound.PubSub,
        MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
      )
    end

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
```
> Planner action (RESEARCH Open Q1 / Assumption A1): confirm the PubSub server name the inbound app boots (`MailglassInbound.Application` + `PubSub.Topics.inbound_record_inserted/1`) and whether the subscription should be best-effort (`try`/`Code.ensure_loaded?`). The `send`-based capture is the primary assertion path; subscription is optional.

> Tenancy tag handling mirrors analog lines 103-109 (`@tag tenant: :unset` → `nil`).

---

### `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` (test fixture builder, transform)

**Analog:** `mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs:287-352` (signed-SNS helpers) + `test/support/webhook_fixtures.ex:194-228` (outbound, identical keypair approach). Extract these private fns into public `Fixtures` functions — do NOT reinvent crypto.

**SES SNS signed-payload helpers — extract verbatim** (`ses_provider_test.exs:343-352, 330-345, 287-301`):
```elixir
# Source: ses_provider_test.exs:347-352 (also test/support/webhook_fixtures.ex:219-228)
defp generate_sns_keypair do
  private_key = :public_key.generate_key({:rsa, 2048, 65537})
  n = elem(private_key, 2)   # OTP 27 RSAPrivateKey: index 2 = modulus
  e = elem(private_key, 3)   #                       index 3 = public exponent
  {{:RSAPublicKey, n, e}, private_key}
end

# Source: ses_provider_test.exs:343-345
defp sign_canonical(canonical, private_key),
  do: :public_key.sign(canonical, :sha, private_key) |> Base.encode64()

# Source: ses_provider_test.exs:330-334 (byte-sorted; matches core build_canonical_string/2)
defp canonical_string(payload, "Notification") do
  ~w(Message MessageId Subject Timestamp TopicArn Type)
  |> Enum.filter(&Map.has_key?(payload, &1))
  |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
end
```
Then `build_ses_sns_payload/1` (composition, per D-47-10): mint keypair → build SNS envelope (`sign_notification/3` shape at `ses_provider_test.exs:287-301`) → canonical → sign → put `"Signature"` → `Jason.encode!` AND prime the real cache:
```elixir
# Prime the real ETS cert cache so SES.verify! is a cache hit (no :httpc fetch). D-47-10.
future = DateTime.add(DateTime.utc_now(), 86_400, :second)
Mailglass.Webhook.Providers.SES.CertCache.put(cert_url, public_key, future)   # cert_cache.ex:60
# For the Action:S3 body path, prime the fake fetcher:
MailglassInbound.S3Fetcher.Fake.put(bucket, key, raw_mime)                    # s3_fetcher/fake.ex:41
```
CertCache signatures confirmed: `put/3` (`cert_cache.ex:60` `put(url, public_key, %DateTime{} = expires_at)`), `reset/0` (`cert_cache.ex:67`). Inner notification shape with the S3 receipt action: `ses_provider_test.exs:247-258` (`signed_s3_notification/2`). NO `.pem` on disk, NO `CertCache.Fake` (does not exist — D-47-13).

**Canonical `%InboundMessage{}` builder** — defstruct fields confirmed at `inbound_message.ex:60-78`:
```elixir
# Defaulted list fields: from/to/cc/bcc/reply_to []; headers %{}; attachments [].
# Address shape: %{address: "a@b.test"} (per convergence test :170-177).
%MailglassInbound.InboundMessage{
  tenant_id: "test-tenant", provider: :postmark,
  provider_message_id: msg_id, message_id: msg_id,
  envelope_recipient: "support@example.com",
  from: [%{address: "sender@example.com"}], to: [%{address: "support@example.com"}],
  subject: "...", headers: %{}, text_body: "...", html_body: nil
}
```
Mirror `inbound_idempotency_convergence_test.exs:169-179` for the canonical builder.

**Other provider payloads (D-47-11, all code-built, NO `.eml`):** build Postmark JSON, SendGrid form-encoded, Mailgun multipart from code. Round-trip each through the REAL provider `verify!`/`normalize` (see signature anchors in the `Test.Ingress` section above) — `fixtures_test.exs` asserts each produces a valid `%InboundMessage{}` and the SES signed payload passes `SES.verify!`.

> **Security (RESEARCH V6/V4):** keypairs are ephemeral, in-memory, per-call; never written to disk, never shipped. Fixtures default a `tenant_id` so tests can't assert across tenants.

---

### `mailglass/lib/mix/tasks/mailglass.gen.mailbox.ex` (generator, create) & `mailglass.gen.inbound_router.ex`

**Analog:** `lib/mix/tasks/mailglass.gen.mailable.ex` (full file, 1-62) — the `use Igniter.Mix.Task` creation precedent. Both new generators copy this skeleton wholesale.

**Task shell** (analog lines 1-19): `use Boundary, classify_to: Mailglass` + `use Igniter.Mix.Task`, `@impl Igniter.Mix.Task def info/2` returning `%Igniter.Mix.Task.Info{schema: …, positional: […]}`. Do NOT add `dry_run:` to the schema — it is a free global switch (D-47-09, `info.ex` `@global_options`).

**Module resolution + creation** (analog lines 22-31, 50-61):
```elixir
app_module = Igniter.Project.Application.app_module(igniter) || Test
module_name =
  if String.contains?(arg, "."), do: Module.concat([arg]),
  else: Module.concat([app_module, "...", arg])

igniter
|> Igniter.Project.Module.create_module(module_name, module_code)   # heredoc body string
|> Igniter.create_new_file(other_path, other_code)
```

**`gen.mailbox` (IGEN-01)** scaffolds three things (D-47-07): mailbox module (behaviour + default `process/1`) + a `route/2` stub in the configured router (reuse the IGEN-03 zipper helper) + a test stub that `use MailglassInbound.MailboxCase`. Mailbox body (callback contract from `mailbox.ex:1-24`):
```elixir
@behaviour MailglassInbound.Mailbox

@impl MailglassInbound.Mailbox
def process(%MailglassInbound.InboundMessage{} = _message) do
  :accept   # neutral outcome (RESEARCH security note: no auth heuristics)
end
```
> Planner action (RESEARCH Open Q2): decide gen.mailbox behavior when the target router doesn't exist — recommended: emit an actionable Igniter notice ("run mix mailglass.gen.inbound_router first") rather than auto-create.

**`gen.inbound_router` (IGEN-02)** creates a new router via `create_module` with `use MailglassInbound.Router` + one sample `route/2`. The router DSL it scaffolds is `router.ex:39-72` (`use` injects the `@mailglass_inbound_routes` accumulator + `route/2` import + `@before_compile`; reflection is `__mailglass_inbound_routes__/0`). A valid `route/2` call shape (from `router.ex:48` + `@route_schema:21-37`): `route(MyApp.SupportMailbox, recipient: "support@example.com")`.

**Self-test analog:** `test/mix/tasks/mailglass.gen.mailable_test.exs` (full file) — `import Igniter.Test`, `test_project(app_module: Test)`, `Igniter.compose_task(…, [args]) |> apply_igniter!()`, then `assert_file_content/3` (Rewrite source read, lines 11-15). Mirror this for `gen.mailbox_test.exs` / `gen.inbound_router_test.exs`.

---

### `mailglass/lib/mix/tasks/mailglass.gen.inbound_route.ex` (generator, source-edit / Sourceror-zipper)

**Analog:** `lib/mix/tasks/mailglass.upgrade.v0_2.ex:32-88` — the ONLY existing Sourceror-zipper source-edit + dry-run precedent in the repo. **Use its task-shell + dry-run posture, but a DIFFERENT zipper idiom** (upgrade.v0_2 uses `update_all_elixir_files` + `update_all_matches`; IGEN-03 needs a single-module find + idempotent append).

**Dry-run is FREE** (D-47-09). `--dry-run` is a global Igniter switch for any `use Igniter.Mix.Task` — zero code. (The `Igniter.assign(igniter, :dry_run?, true)` force-pattern at `upgrade.v0_2.ex:34-40` is only for *defaulting* to preview; generators apply by default like `gen.mailable`, so do NOT copy the force-pattern.)

**The idempotent zipper edit** (RESEARCH Pattern 3, grounded in vendored Igniter 0.8.0 at `mailglass/deps/igniter/`; the relevant fns are byte-identical in inbound's 0.7.9):
```elixir
defmodule Mix.Tasks.Mailglass.Gen.InboundRoute do
  use Boundary, classify_to: Mailglass
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing) do
    %Igniter.Mix.Task.Info{
      schema: [router: :string, recipient: :string, subject: :string],
      positional: [:pattern, :mailbox]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    router    = Module.concat([igniter.args.options[:router] || default_router(igniter)])
    mailbox   = Module.concat([igniter.args.positional.mailbox])
    recipient = igniter.args.positional.pattern
    route_code = "route(#{inspect(mailbox)}, recipient: #{inspect(recipient)})"

    {:ok, igniter} =
      Igniter.Project.Module.find_and_update_module(igniter, router, fn zipper ->
        # find_and_update_module positions the zipper at the module DO-BLOCK (move_to_do_block).
        if route_already_present?(zipper, mailbox) do
          {:ok, zipper}                                       # IDEMPOTENT no-op on re-run
        else
          {:ok, Igniter.Code.Common.add_code(zipper, route_code, placement: :after)}
        end
      end)

    igniter
  end

  defp route_already_present?(zipper, mailbox) do
    case Igniter.Code.Function.move_to_function_call_in_current_scope(
           zipper, :route, 2,
           fn cz -> Igniter.Code.Function.argument_equals?(cz, 0, mailbox) end
         ) do
      {:ok, _} -> true
      :error -> false
    end
  end
end
```
**Igniter 0.8.0 API anchors** (verified in RESEARCH against `mailglass/deps/igniter/`):
- `Igniter.Project.Module.find_and_update_module/3` — `module.ex:201` (calls `move_to_do_block/1` internally)
- `Igniter.Code.Function.move_to_function_call_in_current_scope/4` — `function.ex:243`
- `Igniter.Code.Function.argument_equals?/3` — `function.ex:990`
- `Igniter.Code.Common.add_code/3` — `common.ex:330` (use `placement: :after` keyword; the atom 3rd-arg form is deprecated, `common.ex:334`)

> **Two HIGH-value self-test targets (RESEARCH Pattern 3 subtleties + Pitfalls 3 & 4):**
> 1. **Idempotency:** run the task twice → `assert_unchanged` on the second (RESEARCH Code Example lines 495-506). Catches `argument_equals?` failing to resolve `{:__aliases__, …}` vs module atom (Assumption A2 / Pitfall 3).
> 2. **Single-statement body:** test on a freshly-generated router whose body is only `use MailglassInbound.Router` (not a `{:__block__, …}`). `add_code` must promote the single child to a block (`common.ex:405+`, `maybe_move_to_block/1` at `common.ex:954`) and place the route after `use`, not above it (Pitfall 4).

---

### `mailglass_inbound/mix.exs` (config — packaging edit)

**Analog/target:** `mailglass_inbound/mix.exs:105-145` (self).

- **`files:` manifest** (line 113) already globs `lib` — the four helpers under `lib/` ship automatically, including `lib/mailglass_inbound/test/ingress.ex` (confirm `lib/**` glob covers the nested `test/` dir; Assumption A3 — LOW risk). No `files:` change strictly required, but verify with `mix hex.build` (RESEARCH phase gate).
- **ExDoc `groups_for_modules`** (lines 133-143) currently has `Stable:` + `Internal:`. Add a new **`Testing:`** group (D-47-02) listing the four modules:
```elixir
groups_for_modules: [
  Stable: [ MailglassInbound, MailglassInbound.InboundMessage,
            MailglassInbound.Ingress.CachingBodyReader, MailglassInbound.Ingress.Plug,
            MailglassInbound.Router, MailglassInbound.Mailbox ],
  Testing: [ MailglassInbound.TestAssertions, MailglassInbound.MailboxCase,
             MailglassInbound.Test.Ingress, MailglassInbound.Fixtures ],
  Internal: [MailglassInbound.OptionalDeps]
]
```
> The inbound docs-contract test (`mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, per CLAUDE.md) must be updated to expect the four modules under the new "Testing" group.

---

## Shared Patterns

### Igniter mix task shell (all three generators)
**Source:** `lib/mix/tasks/mailglass.gen.mailable.ex:10-19`
**Apply to:** all three generator files
```elixir
use Boundary, classify_to: Mailglass
use Igniter.Mix.Task

@impl Igniter.Mix.Task
def info(_argv, _composing_task) do
  %Igniter.Mix.Task.Info{schema: [...], positional: [...]}   # never put dry_run in schema
end

@impl Igniter.Mix.Task
def igniter(igniter) do ... end
```

### Process-mailbox capture + 4-style macro dispatch (assertions)
**Source:** `lib/mailglass/test_assertions.ex:86-119, 206-210`
**Apply to:** `MailglassInbound.TestAssertions` (all macros); `Test.Ingress` provides the `send(self(), {:inbound, …})` seam that backs every `assert_received`.

### Process-global / process-dict reset in test setup
**Source:** `mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs:26-28`
**Apply to:** `MailglassInbound.MailboxCase` setup (and any Fixtures self-test that primes the cert cache)
```elixir
Mailglass.Webhook.Providers.SES.CertCache.reset()   # cert_cache.ex:67 (process-global ETS)
MailglassInbound.S3Fetcher.Fake.reset()             # s3_fetcher/fake.ex:33 (process-dict)
```

### Code-built X.509 SNS signing (no `.pem`, no Fake)
**Source:** `ses_provider_test.exs:343-352, 330-334, 287-301` + `test/support/webhook_fixtures.ex:219-228`
**Apply to:** `MailglassInbound.Fixtures.build_ses_sns_payload/1` (+ prime real `CertCache.put/3` and `S3Fetcher.Fake.put/3`).

### Igniter.Test generator self-test harness
**Source:** `test/mix/tasks/mailglass.gen.mailable_test.exs:1-15`
**Apply to:** all three generator self-tests (`import Igniter.Test`, `test_project/1`, `compose_task/3`, `apply_igniter!/1`, `assert_file_content/3`; add `assert_unchanged/2` for IGEN-03 idempotency).

### Ecto sandbox + tenancy + on_exit teardown
**Source:** `test/support/mailer_case.ex:93, 103-118, 185-207`
**Apply to:** `MailglassInbound.MailboxCase` — BUT resolve repo from `Application.get_env(:mailglass_inbound, :repo)` (raise if unset), and snapshot/restore NOTHING in app-env (D-47-12).

---

## No Analog Found

None. Every deliverable has an in-repo analog. The two genuinely *novel* surfaces are compositions of existing pieces, not new patterns:
- The inbound **capture seam** (`send(self(), {:inbound, …})`) — resolved as the direct analog of outbound's `Fake.Storage` `{:mail, _}` send (`test_assertions.ex:33-34`), relocated into `Test.Ingress`.
- The IGEN-03 **idempotent zipper append** — composed from documented Igniter 0.8.0 functions (`find_and_update_module/3` + `move_to_function_call_in_current_scope/4` + `add_code/3`); `upgrade.v0_2.ex` is the zipper *precedent* but not the same idiom.

## Metadata

**Analog search scope:**
- `mailglass/lib/mailglass/test_assertions.ex`, `mailglass/test/support/mailer_case.ex`
- `mailglass/lib/mix/tasks/{mailglass.gen.mailable,mailglass.upgrade.v0_2}.ex`, `mailglass/test/mix/tasks/mailglass.gen.mailable_test.exs`
- `mailglass_inbound/lib/mailglass_inbound/{router,router/matcher,mailbox,execution,inbound_message,s3_fetcher/fake}.ex`, `ingress/{persist,providers/ses,providers/postmark,providers/sendgrid,providers/mailgun,provider}.ex`
- `mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs`, `.../properties/inbound_idempotency_convergence_test.exs`
- `mailglass_inbound/mix.exs`, `mailglass/lib/mailglass/webhook/providers/ses/cert_cache.ex`, `mailglass/test/support/webhook_fixtures.ex`

**Files scanned:** 18 source/test files read + targeted greps across both packages
**Pattern extraction date:** 2026-05-23
