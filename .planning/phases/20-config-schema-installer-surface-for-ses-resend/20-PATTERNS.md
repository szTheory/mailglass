# Phase 20: Config Schema & Installer Surface for SES + Resend — Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/config.ex` | config | boot-time validation | existing `mailgun` / `sendgrid` subtrees in the same file | exact |
| `test/mailglass/config_test.exs` | test | unit | existing Mailgun subtree tests in the same file | exact |
| `lib/mailglass/installer/templates.ex` | codegen | string transform | existing `webhook_mount_snippet/1` in the same file | exact |
| `guides/webhooks.md` | docs | installer/runtime contract | existing SES + Resend opt-in sections | exact |
| `test/mailglass/install/install_golden_test.exs` | test | snapshot | existing snapshot harness in the same file | exact |
| `test/example/README.md` | snapshot artifact | file I/O | existing `GOLDEN_FRESH` / `GOLDEN_NO_ADMIN` blocks | exact |
| `lib/mailglass/errors/publish_error.ex` | error contract | typed exception | `lib/mailglass/errors/config_error.ex` / `stream_policy_error.ex` | exact |
| `lib/mailglass/error.ex` | error registry | type union | existing sibling error registration pattern | exact |
| `docs/api_stability.md` | public contract docs | error taxonomy | existing error sections | exact |
| `lib/mix/tasks/mailglass.publish.check.ex` | release gate | CLI task | existing installer-golden subprocess seam | exact |

## Pattern Assignments

### `lib/mailglass/config.ex`

**Analog:** existing `mailgun` and `sendgrid` keyword-list subtrees.

```elixir
mailgun: [
  type: :keyword_list,
  default: [],
  doc: "Mailgun webhook configuration.",
  keys: [
    enabled: [type: :boolean, default: true, doc: "..."],
    signing_key: [type: {:or, [:string, nil]}, default: nil, doc: "..."],
    timestamp_tolerance_seconds: [type: :pos_integer, default: 28_800, doc: "..."]
  ]
]
```

**Apply in Phase 20:** add `:ses` and `:resend` using the same `type: :keyword_list`, `default: []`, `keys:` pattern. Keep the accepted keys closed to the runtime-consumed surface only.

### `test/mailglass/config_test.exs`

**Analog:** Mailgun acceptance/rejection tests.

```elixir
test "accepts a valid mailgun subtree" do
  config =
    Mailglass.Config.new!(
      mailgun: [
        enabled: true,
        signing_key: "mailgun-signing-key",
        timestamp_tolerance_seconds: 28_800
      ]
    )

  mailgun = Keyword.fetch!(config, :mailgun)
  assert Keyword.fetch!(mailgun, :signing_key) == "mailgun-signing-key"
end

test "rejects unknown keys in the mailgun subtree" do
  assert_raise NimbleOptions.ValidationError, fn ->
    Mailglass.Config.new!(mailgun: [unknown_key: true])
  end
end
```

**Apply in Phase 20:** mirror this structure for SES and Resend positive/negative cases.

### `lib/mailglass/installer/templates.ex`

**Analog:** current `webhook_mount_snippet/1`.

```elixir
scope "/" do
  pipe_through :mailglass_webhooks
  mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :mailgun]
end
```

**Apply in Phase 20:** replace the explicit provider list with the zero-arg default call, then add adjacent comment lines showing the opt-in route example for `:mailgun`, `:ses`, and `:resend`.

### `guides/webhooks.md`

**Analog:** existing provider-specific opt-in guidance.

```elixir
mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :ses]
config :mailglass, :ses,
  cert_cache_ttl_seconds: 86_400
```

**Apply in Phase 20:** keep docs aligned with the installer’s default-vs-opt-in posture. Do not broaden the documented default mount.

### `lib/mailglass/errors/publish_error.ex`

**Analogs:** `lib/mailglass/errors/config_error.ex`, `lib/mailglass/errors/stream_policy_error.ex`.

```elixir
@behaviour Mailglass.Error
@types [:stream_policy_violated]
@derive {Jason.Encoder, only: [:type, :message, :context, :detail]}
defexception [:type, :message, :cause, :context, :detail]

@doc false
def __types__, do: @types

@impl Mailglass.Error
def retryable?(%__MODULE__{}), do: false
```

**Apply in Phase 20:** create a sibling `Mailglass.PublishError` with a one-atom closed type set, non-retryable behavior, and message formatting that preserves the exact golden refresh command.

### `lib/mailglass/error.ex`

**Analog:** existing `@type t` union and `@error_modules` list.

```elixir
@type t ::
  Mailglass.SendError.t()
  | Mailglass.TemplateError.t()
  | Mailglass.ConfigError.t()

@error_modules [
  Mailglass.SendError,
  Mailglass.TemplateError,
  Mailglass.ConfigError
]
```

**Apply in Phase 20:** add `Mailglass.PublishError.t()` and `Mailglass.PublishError` in both places so helper APIs recognize the new sibling.

### `lib/mix/tasks/mailglass.publish.check.ex`

**Analog:** current installer-golden subprocess seam and `fail_step/2`.

```elixir
{output, status} = System.cmd(..., stderr_to_stdout: true)

if status == 0 do
  ctx
else
  fail_step(
    "run installer goldens for mailglass",
    "Delivery blocked: installer goldens drifted.\n\n#{output}"
  )
end
```

**Apply in Phase 20:** keep the subprocess seam, but convert the drift branch into a typed `Mailglass.PublishError` path before the final Mix failure boundary prints the remediation text.

## Sequencing Constraint

1. Update config + installer + snapshots first.
2. Regenerate / verify the installer golden snapshot.
3. Only then add the typed publish error and wire publish-check to that seam.

This order keeps the release-gate work testing a corrected installer contract instead of mixing template churn with taxonomy churn.
