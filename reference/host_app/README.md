# Mailglass Reference Host App

Maintained trust-proof host artifact (not a fixture seed)

`reference/host_app` is the maintained adopter-facing baseline for the v1.3
trust journey. It exists to prove clean-checkout bootstrap behavior and public
Mailglass integration shape.

Scope contract: see reference/host_app/SCOPE.md

`test/example remains fixture-only`

## Setup (clean checkout)

Run the canonical setup lane exactly as written:

```bash
cd reference/host_app
mix deps.get
mix ecto.create
mix ecto.migrate
mix compile --warnings-as-errors
mix phx.server
```

This host intentionally uses published package constraints for Mailglass sibling
packages and does not rely on local path dependencies.

Public seam boundary: this host does not call Mailglass internal modules or provider internals.

Stable seams used by this reference host:
- `Mailglass.deliver/2`
- `Mailglass.deliver!/2`
- `Mailglass.deliver_later/2`
- `MailglassAdmin.Router.mailglass_admin_routes/2`
- `MailglassAdmin.Router.mailglass_operator_routes/2`
- `MailglassInbound.Ingress.Plug`

## Canonical trust runner command

Use one command as the trust-journey entrypoint for local verification and CI:

```bash
mix verify.reference_host.journey
```

Phase boundary: signed-negative webhook proof (`JOUR-03`) and scripted
non-happy-path operator diagnosis (`JOUR-04`) are deferred to Phase 58.
