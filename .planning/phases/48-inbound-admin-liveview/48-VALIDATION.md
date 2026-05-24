---
phase: 48
slug: inbound-admin-liveview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `48-RESEARCH.md` → "## Validation Architecture" (6 core invariants V1–V6 + supporting V7–V11).
> Task IDs in the verification map are assigned by the planner; rows below are keyed to invariants until then.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18) + Phoenix.LiveViewTest (lazy_html DOM) |
| **Config file** | `mailglass_admin/config/test.exs` (needs the inbound-repo addition — Wave 0) |
| **Quick run command (admin)** | `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` |
| **Quick run command (reflection)** | `cd mailglass_inbound && mix test test/mailglass_inbound/router/matcher_test.exs --seed 0` |
| **Full suite command (admin gate)** | `cd mailglass_admin && mix verify.preview` (compile --no-optional-deps + test + assets.build + bundle-drift) |
| **No-optional-deps lane** | `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` (MUST pass with inbound stripped) |
| **Estimated runtime** | ~30–60s admin quick run; full `verify.preview` ~2–4 min |

> Inbound-suite flake note: the full `mailglass_inbound` suite intermittently fails (DB pool `tcp recv: closed`) via a phase-45 1000-iter property test. Use `--seed 0` or scope per-file for deterministic green.

---

## Sampling Rate

- **After every task commit:** Run the relevant quick-run file (`inbound_live_test.exs` for admin tasks; `matcher_test.exs --seed 0` for the reflection task).
- **After every plan wave:** `cd mailglass_admin && mix verify.preview` (full admin gate incl. no-optional-deps lane + bundle-drift) AND `cd mailglass_inbound && mix test --seed 0`.
- **Before `/gsd:verify-work`:** Both suites green + `mix credo --strict` (LINT-06).
- **Max feedback latency:** ~60 seconds (admin quick run).

---

## Per-Task Verification Map

> Task IDs (`48-NN-NN`) are assigned during planning; the planner maps each row to a concrete task and sets `File Exists`. Invariant rows below define the highest-signal assertion each task must satisfy.

| Inv | Requirement | Layer | Highest-signal assertion | Automated Command | File Exists | Status |
|-----|-------------|-------|--------------------------|-------------------|-------------|--------|
| V1 | IADM-01 | LiveView + unit | Blank tenant → empty-state copy, `[]`, NO other-tenant id/recipient leak; read-model unit: tenant A query never returns tenant B rows | `mix test .../inbound_live_test.exs` + `cd mailglass_inbound && mix test .../internal/operator/records_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| V2 | IADM-03 | integration | Replay a *matched* record → NEW `ExecutionRun` `source: :replay` appended; count +1, no UPDATE, prior row byte-identical | `cd mailglass_inbound && mix test .../internal/replay_test.exs --seed 0` + admin modal integration | ❌ W0 | ⬜ pending |
| V3 | IADM-04 | unit (property) | `Enum.all?(explain(route,msg), &last) == matches_route?(route,msg)` for all route×message combos (3 matcher kinds × {present,absent,nil} × header AND) | `cd mailglass_inbound && mix test .../router/matcher_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| V4 | IADM-07 / arch | compile | `mix compile --no-optional-deps --warnings-as-errors` green with inbound stripped; InboundLive/route/nav no-op; no bare `MailglassInbound.*` escapes the `apply/3` seam | `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` | ✅ | ⬜ pending |
| V5 | IADM-02 | LiveView + voice | Evidence default-redacted (raw bytes ABSENT until `:reveal_raw`); recipient masked by default; no PII in LiveView telemetry | `mix test .../inbound_live_test.exs` (`refute html =~ raw_recipient`) | ❌ W0 | ⬜ pending |
| V6 | IADM-03 / IADM-02 | LiveView | `:replay_inbound` denied → composed flash, no run appended; `:reveal_raw` denied → placeholder stays; both ride `Auth.authorize/3` `atom()`, NO new auth module | `mix test .../inbound_live_test.exs` (stub `Auth` returns `{:error, :unauthorized, ...}`) | ❌ W0 | ⬜ pending |
| V7 | IADM-05 | LiveView | Broadcast `{:inbound_record_inserted, id, meta}` → list prepends tenant-scoped re-fetched record; selection + filter params UNCHANGED | `mix test .../inbound_live_test.exs` | ❌ W0 | ⬜ pending |
| V8 | IADM-05 | unit | `MailglassAdmin.PubSub.Topics.inbound_record_inserted(t) == MailglassInbound.PubSub.Topics.inbound_record_inserted(t)` | `mix test .../pub_sub/topics_test.exs` | ❌ W0 | ⬜ pending |
| V9 | IADM-05 | credo | Both topic builders pass `Mailglass.Credo.PrefixedPubSubTopics` (LINT-06) — no literal topic strings at call sites | `mix credo --strict` | ✅ | ⬜ pending |
| V10 | IADM-06 | voice | Rendered HTML for every error/empty/blocked state matches locked UI-SPEC copy; no "Oops/Whoops/Something went wrong" | `mix test .../inbound_live_test.exs` (voice greps) | ❌ W0 | ⬜ pending |
| V11 | IADM-04 / IADM-06 | LiveView | Replaying a `:no_match` record surfaces `Replay blocked: mailbox module not found.` (maps `{:replay_mailbox_missing, ...}`); no run appended | `mix test .../inbound_live_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · `❌ W0` = blocked on Wave 0 test infra*

---

## Wave 0 Requirements

Test-infrastructure gaps that MUST land before implementation tests can pass (from RESEARCH Pitfall 3 + Wave 0 Gaps):

- [ ] `mailglass_admin/mix.exs` `deps/0` — floating `{:mailglass_inbound, path: "../mailglass_inbound", optional: true}` (publish branch: `"~> 0.2"`) so inbound modules + `MailglassInbound.Fixtures` are available in `:test`
- [ ] `mailglass_admin/config/test.exs` — add `config :mailglass_inbound, :repo, MailglassAdmin.TestRepo`
- [ ] `mailglass_admin/test/test_helper.exs` — run inbound migrations against the admin test DB (`:code.priv_dir(:mailglass_inbound)/repo/migrations`; same pool-override dance as the core `with_repo` block)
- [ ] Admin inbound fixtures helper (or reuse `MailglassInbound.Fixtures` + `InboundRecords.insert_*`) to seed `InboundRecord` + `InboundEvidence` + `ExecutionRun` rows (matched / no_match / replay)
- [ ] `mailglass_inbound/test/mailglass_inbound/router/matcher_test.exs` — add `explain/2` property + example tests (StreamData already a test dep)
- [ ] Synthetic adopter router (`test/support/endpoint_case.ex`) — add `inbound_router:` opt to the `mailglass_operator_routes` invocation so the routing-trace card has routes to render

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual fidelity of routing-trace card (clause table layout, first-failing-clause emphasis) | IADM-04 | Pixel/layout judgement not assertable in DOM tests | Render a `:no_match` record in dev preview; confirm per-route bordered cards, 3-column clause table, check/x markers, left-border emphasis on first failing clause |
| Responsive collapse to single column < `lg` | IADM-01 | Viewport rendering | Resize browser below `lg`; confirm filters → list → detail stack |

*Automated coverage exists for all correctness/security invariants; manual rows are visual-only.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (inbound repo config + migrations + fixtures + reflection test)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter (after planner maps task IDs)

**Approval:** pending
