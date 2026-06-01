# Mailglass Demo App

Realistic B2B SaaS Ops click-around demo for Mailglass adoption evidence.

## Quickstart

From the repo root:

```bash
DEMO_EVIDENCE_RESET_TOKEN=$(openssl rand -hex 24) docker compose -f compose.demo.yml up demo
```

Then open:

- Demo dashboard: http://localhost:4015
- Preview: http://localhost:4015/dev/mail
- Outbound operator: http://localhost:4015/demo/login?return_to=/ops/mail?tenant_id=northstar
- Inbound operator: http://localhost:4015/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar

Reset deterministic data:

```bash
DEMO_EVIDENCE_RESET_TOKEN=<same-token> docker compose -f compose.demo.yml exec demo mix demo.reset
```

Destructive note: this reset truncates seeded demo tables before reseeding
preview, delivery, suppression, inbound record, evidence, routing trace, and
replay data for tenant `northstar`.

Run browser evidence against the running demo:

```bash
DEMO_EVIDENCE_RESET_TOKEN=<same-token> docker compose -f compose.demo.yml run --rm demo_e2e
```

Future artifact label: `demo_browser_evidence.v1`.

## Persona and JTBD

Northstar Ops is the B2B SaaS operations team persona for this demo. The job to
be done is to inspect preview mailables, confirm deliveries and suppressions,
review inbound records and routing trace evidence, and replay stored truth
without guessing.

## Seeded data

Deterministic preview stories:

- invite admin
- magic link
- receipt paid
- payment failed
- usage alert
- incident update

Deterministic outbound operator stories:

- receipt delivery
- payment failure bounce
- usage alert bounce
- manual suppression

Deterministic inbound operator stories:

- support reply
- refund request
- spam reject
- no-match route
- stored-truth replay

## What to click

1. Open `http://localhost:4015`.
2. Open `http://localhost:4015/dev/mail`.
3. Open `http://localhost:4015/demo/login?return_to=/ops/mail?tenant_id=northstar`.
4. Open `http://localhost:4015/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar`.
5. Use `mix demo.reset` or the dashboard reset button to restore the deterministic baseline.

Destructive note: this reset truncates seeded demo tables before reseeding preview, delivery, suppression, inbound record, evidence, routing trace, and replay data for tenant `northstar`.

## Dependency Mode

Default mode uses local path dependencies for fast maintainer iteration:

```bash
cd reference/demo_app
mix setup
mix phx.server
```

Published Hex mode is available for published-package smoke checks:

```bash
MAILGLASS_DEMO_DEPS=hex mix deps.get --only prod
```

`reference/host_app` remains the narrow trust-proof app.

This demo app is richer click-around evidence for maintainer and adopter validation. It does not define stable Mailglass API guarantees, and demo DOM, selectors, routes, and copy are not stable public API.
