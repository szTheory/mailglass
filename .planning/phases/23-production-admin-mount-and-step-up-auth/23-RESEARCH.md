# Phase 23: Production Admin Mount and Step-Up Auth - Research

**Researched:** 2026-05-01
**Domain:** Production-safe `mailglass_admin` mounting, LiveView auth boundaries, and future destructive-action gating for operator workflows. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from available phase artifacts)

### Locked Decisions
- Phase 23 must satisfy `ADMIN-01` and `ADMIN-05`: a production-safe operator mount inside adopter Phoenix apps, and recent-auth requirements for destructive operator actions. [VERIFIED: .planning/REQUIREMENTS.md]
- No `23-CONTEXT.md` exists; planning must use the roadmap, requirements, milestone arc, project docs, Phase 22 artifacts, and current code as the authoritative inputs. [VERIFIED: user prompt][VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/MILESTONE-ARC.md]
- Phase 22 already shipped the read-only operator UI and must remain intact; Phase 23 should harden mount/auth seams rather than redesign the operator screen or re-scope the data foundation. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/phases/22-operator-data-foundation/22-VERIFICATION.md]
- The admin package must not grow a standalone identity system; identity ownership stays with the adopter app. [VERIFIED: .planning/REQUIREMENTS.md]
- Phase 23 should ship the auth contract ahead of replay or suppression mutation flows so later destructive features can plug into a server-enforced recent-auth seam. [VERIFIED: user prompt][VERIFIED: .planning/ROADMAP.md]

### Claude's Discretion
- Exact router API shape for separating dev preview routes from production operator routes. [VERIFIED: user prompt]
- Exact module boundaries between `MailglassAdmin.Router`, `Preview.Mount`, a new operator mount hook, and any optional authorization behaviour/helper. [VERIFIED: user prompt][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]
- Exact recent-auth integration seam, provided it does not require Sigra, `phx.gen.auth`, or any other adopter auth stack. [VERIFIED: user prompt]

### Deferred Ideas (OUT OF SCOPE)
- Implementing replay actions, suppression mutations, or any other destructive operator workflow. Those belong to later phases such as Phase 24. [VERIFIED: .planning/ROADMAP.md][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs]
- Building hosted admin auth, custom user/session storage, or a mailglass-owned login UX. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/PROJECT.md]
- Reworking the Phase 22 operator data model or preview UI behavior beyond what is necessary to isolate auth/session boundaries. [VERIFIED: .planning/phases/22-operator-data-foundation/22-RESEARCH.md][VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADMIN-01 | Adopter can mount a production-safe `mailglass_admin` operator surface inside a Phoenix app. | Requires separating preview and operator mount paths, giving operator routes their own `live_session` and `on_mount` boundary, and documenting adopter-owned plug/on_mount integration for production scopes. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| ADMIN-05 | Destructive operator actions require recent authentication. | Requires a server-side authorization seam that later `handle_event/3` mutation handlers can call, plus optional integration guidance for `phx.gen.auth` sudo mode or Sigra sudo mode without taking a dependency on either. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- `mailglass_admin` mounts inside adopter Phoenix apps; operator auth must stay adopter-owned rather than introducing a library-owned auth system. [VERIFIED: CLAUDE.md][VERIFIED: .planning/REQUIREMENTS.md]
- Optional integrations should follow the repo's optional-dependency pattern and must not force hard compile-time references to optional libraries. [VERIFIED: CLAUDE.md][VERIFIED: lib/mailglass/optional_deps/sigra.ex]
- LiveView/admin work should preserve the existing package split: core logic in `mailglass`, UI and mount plumbing in `mailglass_admin`. [VERIFIED: CLAUDE.md][VERIFIED: .planning/phases/22-operator-data-foundation/22-RESEARCH.md]
- No PII should be added to telemetry or auth metadata surfaces. [VERIFIED: CLAUDE.md]

## Summary

The current `mailglass_admin_routes/2` macro is still a dev-preview macro in both docs and code: the README tells adopters to wrap it in `:dev_routes`, the moduledoc calls the surface "Dev-only", and the macro mounts preview and operator pages inside one shared `live_session` with one shared session callback and one shared `on_mount` chain. [VERIFIED: mailglass_admin/README.md][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] That shape was fine for Phase 22's read-only operator route, but it is not production-safe because preview and operator inherit the same session whitelist and mount hooks, so any operator auth policy would either leak into preview or leave operator auth too weak. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex]

Phoenix LiveView's own guidance matches the repo's next step: use distinct `live_session` boundaries when authentication requirements differ, run auth in `on_mount`, and still re-authorize destructive actions inside `handle_event/3` because UI hiding is not sufficient. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] The implementation-oriented recommendation is therefore: freeze the existing preview mount contract for compatibility, introduce a dedicated operator mount path with its own session callback and internal mount hook, and add an optional adopter-supplied authorization seam that later replay/suppression handlers can call for recent-auth enforcement. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs]

**Primary recommendation:** keep preview and operator as separate router products in Phase 23, and ship a minimal, adopter-owned recent-auth contract now so Phase 24 can add replay/mutation handlers without revisiting router/session architecture. [VERIFIED: .planning/ROADMAP.md][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

## Canonical Refs Downstream Planners Must Read

- `mailglass_admin/lib/mailglass_admin/router.ex` — current macro, current shared `live_session`, and current session whitelist. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]
- `mailglass_admin/lib/mailglass_admin/preview/mount.ex` — current always-continue preview mount contract. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex]
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current read-only operator route and future destructive-action call site. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex]
- `mailglass_admin/test/mailglass_admin/router_test.exs` — current session-isolation tests that must stay green and expand for operator-specific whitelists. [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs]
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — current read-only boundaries and explicit absence of replay/suppression mutation controls. [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs]
- `.planning/phases/22-operator-data-foundation/22-RESEARCH.md` and `22-VERIFICATION.md` — Phase 22 handoff and non-regression baseline. [VERIFIED: .planning/phases/22-operator-data-foundation/22-RESEARCH.md][VERIFIED: .planning/phases/22-operator-data-foundation/22-VERIFICATION.md]
- Phoenix LiveView router/security docs — auth/session boundary rules the implementation should follow. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- Phoenix `phx.gen.auth` docs and Sigra sudo docs — canonical examples of recent-auth UX/policy that `mailglass_admin` should integrate with, not own. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html][CITED: https://hexdocs.pm/sigra/account-lifecycle.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route gating for production operator mount | Frontend Server (SSR) | API / Backend | The adopter router and `live_session` boundary decide which auth pipeline and LiveView mount hooks run before any operator page renders. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |
| Preview discovery and preview-only session data | Frontend Server (SSR) | — | Preview currently depends only on whitelisted `"mailables"` session data and `Preview.Mount`; that contract should remain isolated from operator auth changes. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex][VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs] |
| Operator access control at mount | Frontend Server (SSR) | API / Backend | LiveView mount hooks are the standard place to hydrate actor/scope and deny access before rendering operator routes. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Destructive-action authorization and recent-auth checks | API / Backend | Frontend Server (SSR) | LiveView docs require server-side authorization in `handle_event/3`; Phase 24 replay/suppression mutations should call an explicit backend/auth adapter check even if the UI hides controls. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Audit actor context for future replay/suppression actions | API / Backend | Frontend Server (SSR) | Future destructive actions will need durable actor/reason metadata; the auth seam should expose a normalized actor descriptor without teaching `mailglass_admin` how the adopter stores users or sessions. [VERIFIED: .planning/ROADMAP.md][VERIFIED: user prompt] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `phoenix` | `1.8.5` | Router scopes, pipelines, and mount boundaries | The repo already targets Phoenix 1.8 and the official auth generators/docs used in this research are for Phoenix 1.8.5. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| `phoenix_live_view` | `1.1.28` | `live_session`, `on_mount`, and server-side event authorization model | The operator UI is already LiveView-based, and Phase 23 is fundamentally a LiveView auth-boundary phase. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| `nimble_options` | `1.1.1` | Router macro option validation | The current router macro already validates opts with NimbleOptions; Phase 23 should extend rather than replace that contract. [VERIFIED: mix.lock][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `mix phx.gen.auth` generated `UserAuth` pattern | Phoenix `1.8.5` docs | Example adopter-owned auth integration, including `require_sudo_mode` | Use in docs/examples when adopters use stock Phoenix auth. `mailglass_admin` should integrate via hooks/plugs, not depend on the generator output existing. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Sigra sudo mode | Sigra docs `0.2.0`; repo lock `0.2.5` | Optional adopter-owned recent-auth pattern for apps already using Sigra | Use only as an optional example. Do not reference Sigra modules at compile time from `mailglass_admin`. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html][CITED: https://hexdocs.pm/sigra/account-lifecycle.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate preview and operator route/session surfaces | Reuse `mailglass_admin_routes/2` as one mixed live session with more opts | Lower short-term diff, but it keeps preview and operator coupled at the exact auth/session boundary Phase 23 needs to separate. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Optional adopter auth adapter for destructive checks | Hard dependency on `phx.gen.auth` or Sigra | Faster for one stack, but violates the repo's adopter-owned-auth requirement and would block non-Phoenix-generator adopters. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: user prompt] |

**Installation:** No new hard dependency is required for Phase 23. [VERIFIED: user prompt][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

## Architecture Patterns

### System Architecture Diagram

```text
HTTP request
  -> adopter Phoenix router scope
    -> adopter plug pipeline (browser + app auth)
      -> mailglass preview live_session
        -> preview session callback whitelist
        -> Preview.Mount
        -> PreviewLive

HTTP request
  -> adopter Phoenix router scope
    -> adopter plug pipeline (browser + app auth)
      -> mailglass operator live_session
        -> operator session callback whitelist
        -> adopter operator on_mount hook(s)
        -> MailglassAdmin.Operator.Mount
        -> OperatorLive
          -> later handle_event("replay"/"remove_suppression")
            -> adopter auth adapter recent-auth check
            -> core mailglass action module
            -> audit context persisted by later phases
```

The key Phase 23 change is the split between preview and operator `live_session`s so the operator surface can enforce different mount and event authorization without perturbing preview navigation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

### Recommended Project Structure

```text
mailglass_admin/lib/mailglass_admin/
├── router.ex                     # preview macro stays compatible; operator mount gets its own path/session helpers
├── preview/mount.ex              # remains preview-only, always-cont
├── operator/mount.ex             # new operator-specific internal mount hook
├── auth.ex                       # optional behaviour/helper for destructive-action authorization
└── operator_live.ex              # still read-only in Phase 23, but prepared for future action checks

mailglass_admin/test/mailglass_admin/
├── router_test.exs               # preview + operator session whitelist coverage
└── operator_live_test.exs        # access/non-regression/read-only boundary coverage
```

### Pattern 1: Freeze Preview, Add a Distinct Operator Mount Surface

**What:** Keep the existing preview contract stable and introduce a dedicated operator route/session surface instead of making preview and operator share one auth boundary. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

**When to use:** For any production mount path such as `/ops/mail`, `/admin/mail`, or another adopter-chosen operator scope. [VERIFIED: .planning/REQUIREMENTS.md]

**Recommendation:** Prefer a new operator macro or an internal split that yields two separate `live_session`s. Do not require adopters to mount preview routes in production just to get the operator route. [VERIFIED: mailglass_admin/README.md][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

### Pattern 2: Separate Session Whitelists per Surface

**What:** Keep preview session data limited to preview concerns, and create a distinct operator session whitelist rather than extending the current `__session__/2` blindly. [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs][VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

**When to use:** Whenever data crosses from `Plug.Conn` into LiveView session state. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

**Recommendation:** Use separate callbacks such as `__preview_session__/2` and `__operator_session__/2`, or a route-type-aware equivalent, so the operator contract can add narrowly-defined keys without changing preview behavior. Keep the "never pass adopter session wholesale" rule unchanged. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs]

### Pattern 3: Mount Auth for Access, Event Auth for Mutations

**What:** Use `on_mount` to ensure the operator can access the page, and a second explicit check for each future destructive `handle_event/3` path. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

**When to use:** For replay, suppression removal, or any later action that changes state. [VERIFIED: .planning/ROADMAP.md]

**Example contract shape:**

```elixir
defmodule MailglassAdmin.Auth do
  @callback authorize(socket :: Phoenix.LiveView.Socket.t(), action :: atom(), meta :: map()) ::
              :ok | {:error, :unauthorized | :stale_auth, map()}

  @callback actor(socket :: Phoenix.LiveView.Socket.t()) :: map() | nil
end
```

This keeps identity ownership in the adopter app while giving future mutation handlers a single server-side seam. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: user prompt]

### Pattern 4: Accept Standard LiveView `on_mount` Forms for Operator Auth

**What:** Broaden router opt validation so operator auth hooks can use the forms Phoenix documents, including tuple-form hooks for stage arguments. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**When to use:** For adopter stacks such as stock `phx.gen.auth`, Sigra-generated hooks, or custom auth LiveView hooks. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.html]

### Anti-Patterns to Avoid

- Do not add production auth requirements to `Preview.Mount`; its current contract is preview-only and always-continue. [VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex]
- Do not rely on hidden buttons or route-level docs alone for destructive authorization; LiveView requires server-side checks in `handle_event/3`. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- Do not pass adopter session blobs or user structs wholesale through the LiveView session callback. Preserve the current whitelist discipline. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs]
- Do not hard-reference Sigra or Phoenix generator modules from library code. Examples are fine; compile-time dependencies are not. [VERIFIED: lib/mailglass/optional_deps/sigra.ex][VERIFIED: .planning/REQUIREMENTS.md]

## Must-Haves / Non-Goals for Phase 23

### Must-Haves

- A production-safe operator mount path that adopters can place inside an authenticated Phoenix scope without also mounting preview routes there. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: mailglass_admin/README.md]
- Separate preview and operator auth/session boundaries, implemented with distinct `live_session` behavior. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]
- An adopter-owned recent-auth seam for future destructive actions, callable from LiveView event handlers. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html][VERIFIED: user prompt]
- Preview non-regression: `/dev/mail` preview routes keep working and keep their current whitelist/discovery behavior. [VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs][VERIFIED: mailglass_admin/lib/mailglass_admin/preview/mount.ex]
- Documentation that shows both the dev preview mount and the production operator mount, with clear warnings about scope/auth ownership. [VERIFIED: mailglass_admin/README.md][VERIFIED: .planning/PROJECT.md]

### Non-Goals

- No replay buttons, no suppression removal button, no mutation handlers yet. [VERIFIED: .planning/ROADMAP.md][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs]
- No standalone login, no mailglass-owned recent-auth UI, and no built-in user/session schema. [VERIFIED: .planning/REQUIREMENTS.md]
- No broad redesign of the operator layout shipped in Phase 22. [VERIFIED: .planning/phases/22-operator-data-foundation/22-VERIFICATION.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView auth boundary semantics | custom JS/client-side gating | `live_session` + `on_mount` | Phoenix already defines the correct boundary and reload behavior for different auth regimes. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Recent-auth UX/policy in adopter apps | library-owned password/TOTP prompt flow | adopter auth stack (`phx.gen.auth` sudo mode, Sigra sudo mode, or custom) | The requirement explicitly leaves identity ownership with the adopter. [VERIFIED: .planning/REQUIREMENTS.md][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html] |
| Session transport | pass-through of `conn.private.plug_session` | explicit whitelist session callbacks | The router tests and current code already establish this as a security seam. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs] |

**Key insight:** Phase 23 is mostly architecture and contract work, not feature breadth. The expensive mistake would be letting replay/suppression actions define auth shape retroactively. [VERIFIED: user prompt][VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: Putting preview and operator back into one auth session

**What goes wrong:** A single `live_session` makes it hard to require operator auth without also changing preview behavior or documentation. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]

**How to avoid:** Split preview and operator routes into distinct `live_session`s in Phase 23, even if both remain under one outer scope path prefix. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

### Pitfall 2: Treating mount auth as sufficient for destructive actions

**What goes wrong:** A future replay or suppression event can be forged directly against the LiveView process even if the button is hidden. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

**How to avoid:** Require every destructive handler to call the recent-auth seam server-side before invoking the domain action. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

### Pitfall 3: Overfitting the library to one auth stack

**What goes wrong:** Adding direct `Sigra.*` or `MyAppWeb.UserAuth` references makes `mailglass_admin` unusable for adopters on other auth stacks. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: lib/mailglass/optional_deps/sigra.ex]

**How to avoid:** Document `phx.gen.auth` and Sigra as examples only, and keep library integration points generic. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.html]

### Pitfall 4: Weak docs that still imply operator == preview

**What goes wrong:** The README currently says the package does not ship any prod-mountable admin surface and that auth is absent; leaving that language stale after Phase 23 would directly undercut adoption. [VERIFIED: mailglass_admin/README.md]

**How to avoid:** Split docs into "dev preview mount" and "production operator mount" sections with separate examples and explicit non-goals. [VERIFIED: mailglass_admin/README.md]

## Code Examples

### LiveView Session Boundary

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
scope "/" do
  pipe_through [:browser]

  live_session :default do
    live "/feed", FeedLive, :index
  end

  live_session :admin, on_mount: MyAppWeb.AdminLiveAuth do
    live "/admin", AdminDashboardLive, :index
  end
end
```

This is the canonical pattern for giving operator routes stronger auth rules than preview routes. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

### `phx.gen.auth` Recent-Auth Reference

```text
require_sudo_mode - used for pages that contain sensitive operations and enforces recent authentication
```

Use this as an integration example only; `mailglass_admin` should not assume the adopter generated those modules. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html]

### Sigra Recent-Auth Reference

```text
Sigra.Plug.RequireSudo ... requires recent re-authentication.
```

This is a valid example for adopters already on Sigra, but not a dependency Phase 23 should take. [CITED: https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One shared LiveView session for all admin routes | Split `live_session`s when auth requirements differ | Current LiveView docs | This is the documented way to isolate operator auth from preview navigation behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Older Phoenix auth examples without recent-auth | Phoenix 1.8 `phx.gen.auth` includes `require_sudo_mode` and sudo-mode guidance | Phoenix 1.8 docs | Recent-auth is now part of the canonical Phoenix auth vocabulary, so Phase 23 should align with it conceptually. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |

## Open Questions

1. **Should Phase 23 expose a new operator-only macro or extend `mailglass_admin_routes/2` with separate preview/operator opts?**
   - What we know: the current macro is preview-first and shared-session; preview compatibility matters. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex]
   - What's unclear: whether the maintainer wants one public macro with more options or two narrower macros.
   - Recommendation: plan for a small public API decision early in the phase, but keep the internal target the same: separate preview/operator `live_session`s and separate session callbacks. [VERIFIED: user prompt][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

2. **What normalized actor metadata should the future auth adapter expose for replay audit trails?**
   - What we know: later replay work will need durable "who triggered this" context. [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: whether the audit actor should be user id only, scope/tenant + user id, or a richer map.
   - Recommendation: define a minimal opaque actor map in Phase 23 and let Phase 24 decide exact persistence fields. [VERIFIED: user prompt]

## Testing and Docs Implications

- Expand router tests to cover preview and operator separately: distinct route set, distinct session callback whitelist, and acceptance of operator auth hook forms needed by real adopter stacks. [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Keep preview regression coverage in the same verification lane as operator coverage so auth-surface edits cannot silently break `/dev/mail`. [VERIFIED: .planning/phases/22-operator-data-foundation/22-VERIFICATION.md]
- Add operator access tests that prove unauthenticated or unauthorized mounts halt/redirect via adopter hooks, while read-only Phase 22 behavior stays intact after access is granted. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs]
- Add contract tests for the future destructive-action auth seam even if no destructive action ships yet; the output can be a stubbed helper test that asserts `:stale_auth` / `:unauthorized` return shapes. [VERIFIED: user prompt]
- Update `mailglass_admin/README.md` to document two mounts: dev preview and production operator. Include examples for stock Phoenix auth and optional Sigra adopters, clearly labeled as examples. [VERIFIED: mailglass_admin/README.md][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html][CITED: https://hexdocs.pm/sigra/Sigra.html]

## Recommended Plan Split

1. **23-01 Router and session split**
   - Separate preview and operator route/session boundaries.
   - Preserve existing preview behavior and session whitelist tests.
   - Decide public API shape for the production operator mount.

2. **23-02 Operator auth seam**
   - Add operator-specific internal mount hook.
   - Broaden adopter hook support to standard LiveView `on_mount` forms.
   - Add optional destructive-action auth behaviour/helper with normalized `:unauthorized` / `:stale_auth` outcomes.

3. **23-03 Verification and docs**
   - Add route/auth regression tests.
   - Keep operator UI read-only but wire in non-breaking placeholders/helpers for future action checks.
   - Update README/install docs with production operator mount guidance and explicit non-goals.

This split is the smallest one that leaves Phase 24 free to focus on replay behavior instead of reopening routing and auth architecture. [VERIFIED: .planning/ROADMAP.md][VERIFIED: user prompt]

## Environment Availability

Step 2.6 skipped: this phase is code/config/docs work on the existing Phoenix/LiveView stack and does not require a new external runtime or service beyond the project's existing Elixir/Phoenix toolchain. [VERIFIED: user prompt][VERIFIED: mix.lock]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveView tests on Phoenix `1.8.5` / LiveView `1.1.28` [VERIFIED: mix.lock][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs] |
| Config file | `mix.exs` / test support harnesses under `mailglass_admin/test/support/` [VERIFIED: mix.exs][VERIFIED: mailglass_admin/test/support/endpoint_case.ex] |
| Quick run command | `mix test mailglass_admin/test/mailglass_admin/router_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs] |
| Full suite command | `mix test --warnings-as-errors` [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMIN-01 | operator route mounts safely in a production auth scope without preview regressions | LiveView/router integration | `mix test mailglass_admin/test/mailglass_admin/router_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs][VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs][VERIFIED: mailglass_admin/test/mailglass_admin/preview_live_test.exs] |
| ADMIN-05 | destructive-action auth seam returns recent-auth / unauthorized outcomes and is ready for later mutation handlers | unit + integration | `mix test mailglass_admin/test/mailglass_admin/router_test.exs mailglass_admin/test/mailglass_admin/operator_live_test.exs --warnings-as-errors` plus new auth seam tests | ❌ Wave 0 [VERIFIED: user prompt] |

### Wave 0 Gaps

- [ ] `mailglass_admin/test/mailglass_admin/auth_test.exs` or equivalent — covers the new destructive-action auth seam and return-shape contract. [VERIFIED: user prompt]
- [ ] router coverage for operator-only session whitelist and hook validation beyond preview-only keys. [VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | adopter-owned auth via router plugs and LiveView `on_mount`; no mailglass-owned identity stack. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html][VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | yes | explicit LiveView session whitelists; separate preview/operator session callbacks; avoid session pass-through. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs] |
| V4 Access Control | yes | mount-time authorization plus per-event destructive-action authorization. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V5 Input Validation | yes | `NimbleOptions` for router API and server-side validation of event/action params. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mix.lock] |
| V6 Cryptography | no | Phase 23 should consume adopter recent-auth outcomes, not introduce new crypto. [VERIFIED: user prompt] |

### Known Threat Patterns for Phoenix LiveView Operator Surfaces

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Operator route mounted in an unprotected production scope | Elevation of Privilege | document and test authenticated-scope mounting; provide operator-only route surface. [VERIFIED: mailglass_admin/README.md][CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Future forged replay/remove events against LiveView process | Tampering | require server-side action authorization and recent-auth checks in each destructive handler. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Session data leakage from adopter app into library LiveViews | Information Disclosure | keep explicit whitelists and avoid passing full session/user structs. [VERIFIED: mailglass_admin/lib/mailglass_admin/router.ex][VERIFIED: mailglass_admin/test/mailglass_admin/router_test.exs] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix test --warnings-as-errors` remains the appropriate full-suite command for planner defaults. | Validation Architecture | Low; planner may need to substitute a narrower suite if current CI conventions differ. |

## Sources

### Primary (HIGH confidence)
- `mailglass_admin/lib/mailglass_admin/router.ex` — current route macro, `live_session`, and session callback shape.
- `mailglass_admin/lib/mailglass_admin/preview/mount.ex` — current preview mount contract.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — current operator route behavior and future mutation boundary.
- `mailglass_admin/test/mailglass_admin/router_test.exs` — current session whitelist expectations.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — current operator non-goals and read-only guarantees.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/MILESTONE-ARC.md`, `.planning/PROJECT.md` — authoritative phase scope and milestone intent.
- `.planning/phases/22-operator-data-foundation/22-RESEARCH.md`, `22-VERIFICATION.md` — Phase 22 handoff baseline.
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html — `live_session` boundary behavior.
- https://hexdocs.pm/phoenix_live_view/security-model.html — LiveView auth and event-authorization model.
- https://hexdocs.pm/phoenix/mix_phx_gen_auth.html — current Phoenix recent-auth / sudo terminology.

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/sigra/Sigra.html — Sigra positioning as Phoenix auth library.
- https://hexdocs.pm/sigra/Sigra.Plug.RequireSudo.html — Sigra recent-auth plug semantics.
- https://hexdocs.pm/sigra/account-lifecycle.html — Sigra sudo-mode lifecycle guidance.
- https://hex.pm/packages/sigra — current package summary and ecosystem positioning.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all core libraries and current versions are verified from `mix.lock`, and auth-boundary guidance comes from official Phoenix/LiveView docs.
- Architecture: HIGH - the recommendation is directly driven by the current router/mount code plus official `live_session` security guidance.
- Pitfalls: HIGH - each pitfall maps to either current repo code/tests or official LiveView security behavior.

**Research date:** 2026-05-01
**Valid until:** 2026-05-31
