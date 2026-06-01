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

Future artifact label: `demo_browser_evidence.v1`. This is adoption evidence
only; demo DOM, selectors, routes, and copy are not stable public API.

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

## Persona and JTBD

Northstar Ops is a B2B SaaS operations team. The demo data represents the work a
support lead needs before trusting a transactional email framework:

- inspect account invites and magic links before sending,
- confirm receipts and usage alerts reached the right people,
- diagnose bounces and suppressions,
- review inbound support replies,
- replay stored webhook/inbound truth without guessing.

`reference/host_app` remains the narrow trust-proof app. This demo app is richer
click-around evidence for maintainer and adopter validation and does not define
stable Mailglass API guarantees.
