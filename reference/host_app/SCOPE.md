## In Scope

The reference host remains a trust-proof baseline for v1.3. It covers only:
- install
- preview
- send
- webhook ingest
- operator troubleshooting

## Non-Goals

- Provider-matrix broadening
- SEED-003-ecosystem-integrations promotion
- gen_smtp listener expansion
- second product surface

Boundary posture: this maintained reference host is usage-proof evidence only,
not API-contract truth.

It is not a second product surface and not a fixture seed.

Stable guarantee semantics route to `docs/api_stability.md`,
`mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md`,
and `mix verify.stability_contract`.

## Deferred

- OPS-01/OPS-02 smoke reliability closure remains outside Phase 52
