# Deferred Items

## 2026-08-02 — unrelated full-suite property flake

- `mix test --warnings-as-errors` failed in
  `test/mailglass/properties/idempotency_convergence_test.exs` at the
  `property convergence: apply_all(events) == apply_all(replays_shuffled)`
  assertion after the plan's documentation and focused regression checks had
  passed. The generated event snapshot contained keys from other concurrent
  work, so this does not involve the six documentation files or the first-send
  contract. It is outside Plan 149-04 scope and needs isolated property-suite
  investigation.
