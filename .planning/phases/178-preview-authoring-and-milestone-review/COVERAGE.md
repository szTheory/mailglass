No external API integration: phase repairs Preview authoring UI, ledger/story/zoom evidence and candidate review using existing in-repo tooling.

## Cycle 04 machine-observable acceptance

| Requirement | Evidence | Status | Scope/result |
|---|---|---|---|
| UIQ-06 | Cycle 04 exact-SHA CI runs `41386942453` and `41388571351`; identity-bound dispatch Demo artifact; Operator Browser Gate log with 310 passed, 1 skipped, 0 failed/flaky, including inbound/delivery scroll access, five real-zoom cases, and reduced-motion evidence | verified | Candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`; run/artifact and raw-log hashes are in `178-COST-DISPOSITION.json` and `178-RECOVERY-CYCLE-04.json` |
| UIQ-07 | `178-COST-DISPOSITION.json`; deterministic regeneration byte-identical over 45 input hashes; expected/executed counts match; D-12 placement disposition preserves gates | verified_with_supported_overage | This one preapproved review cycle only; dispatch runner delta is +16.2833 min against +10 min and cold wall delta is +299531 ms against +300000 ms; warm is within limit |
| UIQ-08 | `reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json` (SHA-256 `29850312cdc0adb772d1541f9c81a9ee345f88b66e469464a2e535eb3f7cecf9`) | open | One launch, terminal failure: five of six routes returned 200; `/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar` returned 302. Marker checks were not run. Candidate resources were cleaned up. |
