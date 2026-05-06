# API Stability — mailglass_admin

This document is the canonical `v1.x` stability inventory for the
`mailglass_admin` package.

For the canonical operator trust story, use
[`operator-trust.md`](operator-trust.md). This page stays focused on the
surface inventory rather than retelling the full router/auth/session/replay
contract.

For compatibility, deprecation, release-line matching, and support-matrix
policy, use
[`compatibility-and-deprecations.md`](compatibility-and-deprecations.md),
which points to the canonical core guide.

The admin package promise is intentionally narrow. It covers semantic seams
that adopters integrate with directly. It does not freeze LiveView internals,
DOM structure, CSS, or internal mount plumbing.

## Contract Posture

### `stable`

These surfaces are part of the documented `v1.x` admin contract:

- `MailglassAdmin.Router.mailglass_admin_routes/2`
- `MailglassAdmin.Router.mailglass_operator_routes/2`
- the documented options for those router macros
- `MailglassAdmin.Auth` and its `authorize/2` callback/result contract
- `MailglassAdmin.version/0`
- operator-mount semantics at the level of:
  - explicit session-key whitelist
  - adopter-owned auth module
  - mount-time authorization for operator access
  - action-time authorization for destructive actions such as replay
- operator read-model and service seams exposed through the admin package docs:
  `Mailglass.Operator.Deliveries`, `Mailglass.Operator.Timeline`,
  `Mailglass.Operator.ReplayHistory`, `Mailglass.Operator.ReplayTargets`, and
  `Mailglass.Operator.Suppressions`

### `internal`

These surfaces are implementation details, even when they are reachable:

- LiveView modules, component modules, layouts, templates, asset filenames,
  and CSS/DOM structure
- preview sidebar organization, assign-editing widgets, tab markup, and other
  rendering details
- internal mount hooks such as `MailglassAdmin.Operator.Mount`
- framework callback helpers exported only because Phoenix routing or
  `live_session` requires a public function target
- preview scanning/discovery internals and asset-serving plumbing

## Stable Inventory

### Router macros

The stable admin entrypoint is `MailglassAdmin.Router`.

#### `mailglass_admin_routes/2`

Stable promise:

- mounts the preview surface at the caller-chosen path
- accepts the documented `:mailables`, `:on_mount`, `:live_session_name`, and
  `:as` options
- keeps preview mounting adopter-controlled; the library does not decide dev
  mode on behalf of the adopter

Not promised:

- internal LiveView module names
- exact generated route structure beyond the documented macro behavior
- DOM or asset implementation details

#### `mailglass_operator_routes/2`

Stable promise:

- mounts the production operator surface at the caller-chosen path
- requires an adopter-owned `:auth` module implementing `MailglassAdmin.Auth`
- uses an explicit `:session` whitelist for `:subject_id`, `:tenant_id`,
  `:auth_method`, and `:recent_auth_at`
- supports documented `:on_mount`, `:live_session_name`,
  `:unauthorized_path`, and `:as` options
- treats operator authorization as semantic contract, not UI contract

Not promised:

- the internal `live_session` implementation details
- internal mount module names or assign keys beyond documented semantic seams
- replay confirmation UI layout, DOM selectors, or CSS classes

### Auth seam

`MailglassAdmin.Auth` is a stable adopter-owned behaviour.

Stable promise:

- `authorize(action(), context)` is the one authorization callback contract
- `:operator_access` and `:destructive_action` are the named stable action
  semantics used by the package today
- result normalization accepts the documented success and failure tuple shapes
- `recent_auth_at` is part of the stable semantic seam when adopters choose to
  enforce step-up or recent-auth policy

Not promised:

- the adopter's auth policy itself
- any hosted login/session product from `mailglass_admin`

### Operator semantics

The admin contract includes narrow operator semantics:

- an authenticated operator may inspect delivery, timeline, replay-history,
  replay-target, and suppression facts through the documented surface
- replay acts on one exact stored webhook target, not on guessed delivery-wide
  state
- destructive actions stay adopter-owned through the auth seam

The admin contract does not freeze:

- DOM structure
- LiveView event names
- component module APIs
- preview state shape
- layout markup or CSS class names
- compatibility or deprecation lifecycle policy by itself

## Relationship To Core `mailglass`

`mailglass_admin` depends on the core package's contract inventory in
`../docs/api_stability.md`.

When these packages meet, the stable boundary is semantic:

- core operator/query modules remain the data seam
- admin router/auth modules remain the mount/auth seam
- internal implementation modules on either side are not promoted to stable API
  just because the sibling package can reach them

## Maintainer Rules

- If a new admin seam is meant to be stable for adopters, add it here and add
  `@since` or deprecation metadata at the point of use.
- If a module is exported only for Phoenix wiring, keep it documented as
  internal unless the adopter is meant to call it directly.
- Do not infer stability from reachability, ExDoc visibility, or tests that
  happen to mention an internal module.
