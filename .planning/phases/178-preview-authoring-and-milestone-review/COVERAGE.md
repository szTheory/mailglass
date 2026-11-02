No external API integration: phase repairs Preview authoring UI, ledger/story/zoom evidence and candidate review using existing in-repo tooling.

## Phase 178 machine-observable acceptance

| Requirement | Evidence | Status | Scope/result |
|---|---|---|---|
| UIQ-06 | Cycle 04 exact-SHA CI runs `41386942453` and `41388571351`; identity-bound dispatch Demo artifact; Operator Browser Gate log with 310 passed, 1 skipped, 0 failed/flaky, including inbound/delivery scroll access, five real-zoom cases, and reduced-motion evidence | verified | Candidate `8e501960bc975ed44b632ba5c74522e0c5d66f8c`; run/artifact and raw-log hashes are in `178-COST-DISPOSITION.json` and `178-RECOVERY-CYCLE-04.json` |
| UIQ-07 | `178-COST-DISPOSITION.json`; deterministic regeneration byte-identical over 45 input hashes; expected/executed counts match; D-12 placement disposition preserves gates | verified_with_supported_overage | This one preapproved review cycle only; dispatch runner delta is +16.2833 min against +10 min and cold wall delta is +299531 ms against +300000 ms; warm is within limit |
| UIQ-08 | Cycle 04 record `reference/demo_app/tmp/phase178_candidate/candidate-8e501960.json`; Cycle 05 and Cycle 06 stop records; Plan 31 local lock evidence | open | Cycle 04's preview returned HTTP 302 on the login return route; Cycle 05 stopped before Compose on worktree creation; Cycle 06's one approved attempt stopped before routes/CSS/markers when Mix found the candidate's stale `nimble_options` lock. Candidate-only cleanup completed. Plan 31's local lock refresh and compile pass do not produce a working preview or renew approval; a new candidate and fresh bounded authority are required. |
