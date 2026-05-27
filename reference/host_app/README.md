# Mailglass Reference Host App

Maintained trust-proof host artifact (not a fixture seed)

`reference/host_app` is the maintained adopter-facing baseline for the v1.3
trust journey. It exists to prove clean-checkout bootstrap behavior and public
Mailglass integration shape.

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
