# mailglass_admin

Mountable LiveView surfaces for mailglass. Today that means:

- a dev-preview dashboard for mailable iteration
- a production operator dashboard for delivery inspection and targeted webhook replay inside an adopter-owned auth boundary

The operator surface is delivery-centric. It helps an authenticated operator
inspect provider lifecycle facts, replay facts, and reconcile facts for one
selected delivery. The canonical support runbook lives in
`guides/operator-incident-support.md`.

## API Stability

The canonical operator trust contract lives in
[`docs/operator-trust.md`](docs/operator-trust.md).

The canonical `v1.x` admin surface inventory lives in
[`docs/api_stability.md`](docs/api_stability.md).

The canonical matched-sibling compatibility and deprecation policy lives in the
core repo guide
[`../guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md)
and is re-exposed here through
[`docs/compatibility-and-deprecations.md`](docs/compatibility-and-deprecations.md).

The trust contract is intentionally narrow:

- stable: router macros, their documented options, the `MailglassAdmin.Auth`
  behaviour, and the operator auth/session/replay semantics
- internal: LiveView modules, component modules, DOM/CSS shape, preview assigns
  plumbing, layouts, and internal mount wiring

Do not treat ExDoc visibility, public function reachability, or framework
callback exports as the contract by themselves.

Use `docs/operator-trust.md` for the stable router/auth/session/replay
semantics. Use the compatibility guide for release-line matching,
support-matrix truth, retained compatibility bridges, and upgrade posture. Use
the admin stability page only for the package surface inventory.

## Current package compatibility

Choose the dependency shape that matches the surface your app mounts.

### Preview-only installation

If the app uses only the development preview, scope `mailglass_admin` to dev:

    def deps do
      [
        {:mailglass, "~> 2.5"},
        {:mailglass_admin, "~> 2.5", only: :dev}
      ]
    end

### Production operator installation

If the app mounts the production operator, omit `only:` so the router helpers and
operator modules are compiled and available in production:

    def deps do
      [
        {:mailglass, "~> 2.5"},
        {:mailglass_admin, "~> 2.5"}
      ]
    end

Then run `mix deps.get`.

## Mount the dev preview

Add four lines to `lib/my_app_web/router.ex`:

    import MailglassAdmin.Router

    if Application.compile_env(:my_app, :dev_routes) do
      scope "/dev" do
        pipe_through :browser
        mailglass_admin_routes "/mail"
      end
    end

Restart `mix phx.server`, visit `/dev/mail`. Done.

The `if Application.compile_env(:my_app, :dev_routes) do ... end` wrapper is
the Phoenix 1.8 convention (same gate that protects `live_dashboard` and
`Plug.Swoosh.MailboxPreview`). `mailglass_admin` does not check `Mix.env()`
itself — dev-only is the adopter's responsibility.

## Deterministic preview capture

Maintainers can capture deterministic preview screenshots with one command:

    cd mailglass_admin
    mix mailglass_admin.preview.capture \
      --base-url http://localhost:4000/dev/mail \
      --output-dir tmp/mailglass_admin_preview_capture

Use `--dry-run` to inspect the matrix before rendering:

    cd mailglass_admin
    mix mailglass_admin.preview.capture --dry-run

Matrix dimensions are intentionally bounded in v1:

- scenario: each mailable's `preview_props/0`
- width: `375`, `768`, `1024`
- theme: `light`, `dark`

Output contract:

- screenshots under `tmp/mailglass_admin_preview_capture/*.png`
- deterministic `manifest.json` and `checkpoint.json`
- schema version `preview_capture.v1`

Bounded trust statement: this workflow provides **preview-pipeline confidence
only** and does **not** claim cross-client parity.

## Mount the production operator surface

Import the same router helpers, but mount the operator surface inside your
normal authenticated browser scope:

    import MailglassAdmin.Router

    scope "/ops" do
      pipe_through [:browser, :require_authenticated_user]

      mailglass_operator_routes "/mail",
        auth: MyApp.MailglassAdminAuth,
        session: [
          subject_id: "current_user_id",
          tenant_id: "current_tenant_id",
          auth_method: "auth_method",
          recent_auth_at: "recent_auth_at"
        ],
        on_mount: [{MyAppWeb.UserAuth, :require_authenticated_user}],
        unauthorized_path: "/users/log-in"
    end

`auth:` stays adopter-owned. `mailglass_admin` does not ship a login system,
session schema, or recent-auth prompt. It expects your app to decide who may
enter the operator surface and how "recent authentication" is satisfied.

## Operator replay contract

The operator surface now supports targeted webhook replay from the selected
delivery detail pane.

- Replay starts from one selected delivery, but the server resolves that UI
  selection to one exact stored `mailglass_webhook_events` row before any
  side effect runs.
- When exactly one raw webhook target is safe, the confirmation modal
  preselects it. When multiple targets are safe, the operator must choose
  one explicitly. When no exact target is safe, the modal explains why replay
  is unavailable instead of guessing.
- Confirming replay calls your adopter-owned `auth:` module with
  `:destructive_action` at action time. Mount-time authorization is not
  enough for replay.
- Replay reuses mailglass's existing webhook normalization and idempotency
  semantics. A replay can honestly result in either new work or a duplicate
  / no-op convergence outcome.
- Every replay attempt is ledger-audited with requested, succeeded, or failed
  facts that stay visible in the delivery timeline.

## Operator support boundary

- Provider lifecycle facts come from the delivery timeline, matched webhook
  events, and the shipped telemetry families documented in `guides/telemetry.md`.
- Replay facts are operator-triggered audit facts for one exact stored webhook
  target.
- Reconcile facts come from the background-first orphan sweep and
  `mix mailglass.reconcile`.
- `mailglass_admin` does not ship a separate observability dashboard,
  cross-tenant incident console, or unauthenticated support route.

## LiveReload setup (optional)

When your adopter app runs under `:phoenix_live_reload`, mailglass_admin can
refresh the preview automatically on file save. Add a `live_reload.notify`
entry to your endpoint:

    config :my_app, MyAppWeb.Endpoint,
      live_reload: [
        notify: [
          "mailglass:admin:reload": [~r"lib/.*mailer.*\.ex$"]
        ]
      ]

The topic is prefixed `mailglass:admin:reload` (not bare `mailglass_admin_reload`)
to match the package's `mailglass:`-prefixed PubSub naming convention. When
LiveReload is not configured the preview still works — the adopter just
refreshes the browser manually.

## `preview_props/0` contract

Each `Mailglass.Mailable` module can declare preview scenarios by defining
`preview_props/0`:

    defmodule MyApp.UserMailer do
      use Mailglass.Mailable, stream: :transactional

      def preview_props do
        [
          welcome_default: %{user: %User{name: "Ada"}, team: %Team{name: "Analytical Engines"}},
          welcome_enterprise: %{user: %User{name: "Ada"}, team: %Team{name: "Analytical Engines"}, plan: :enterprise}
        ]
      end

      def welcome(assigns), do: ...
    end

Each tuple is a discrete scenario; the sidebar nests scenarios under the
mailable module name (`MyApp.UserMailer -> welcome_default`). Scenarios
appear in insertion order. Mailables without `preview_props/0` still show
up in the sidebar as `No previews defined` — they remain discoverable even
before you write any scenarios.

## What this ships

- Auto-discovered mailable sidebar (collapsible scenario groups)
- Four tabs per scenario: HTML, Text, Raw (RFC 5322 envelope), Headers
- Type-inferred assigns form — edit any top-level assign inline and
  re-render
- Device toggle (375 / 768 / 1024) + chrome dark toggle
- Graceful failure badges for mailables whose `preview_props/0` raises
- A production operator mount with a separate `live_session`, explicit
  session whitelist, and adopter-owned auth seam
- Delivery, timeline, and suppression visibility in the operator UI
- Targeted webhook replay from the selected delivery detail view with
  action-time auth checks, exact-target confirmation, and durable timeline
  audit visibility

## What this does NOT ship

- Hosted authentication, user storage, or a recent-auth UX. Keep auth and
  step-up ownership in the adopter app.
- Bulk replay, "replay latest", or delivery-wide replay guessing. The operator
  surface replays one exact stored webhook target at a time.
- Suppression removal flows. The recent-auth seam exists, but suppression
  reversal remains a later phase.
- Search, filter, or pagination over mailables. v0.5.
- A synthetic inbound development console. The shipped inbound operator view
  inspects stored inbound records, evidence, routing traces, and replay lineage
  from `mailglass_inbound`; it does not fabricate new inbound messages.
- Stable DOM/component/LiveView implementation APIs. Those remain internal even
  when they are visible in generated docs or reachable in source.

## License

MIT. Released alongside `mailglass` via coordinated linked-version Release
Please tags.
