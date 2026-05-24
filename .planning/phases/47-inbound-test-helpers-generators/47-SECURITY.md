---
phase: 47
slug: inbound-test-helpers-generators
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 47 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
>
> **Audit type:** Threat-mitigation verification — STRIDE register authored at PLAN time (`register_authored_at_plan_time: true`), so each declared mitigation was verified present in shipped code rather than re-discovered.
> **Stance:** Adversarial — each mitigation assumed absent until proven present. Implementation files READ-ONLY (verified, never modified).
> **Scope:** First-party test tooling for `mailglass_inbound`. The only externally-fed surface is generator CLI args (T-47-05/06/07).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Fixture test code → real SES verifier + real CertCache ETS | Fixtures mint an ephemeral keypair and prime the process-global cert cache the real verifier reads | RSA-2048 private key (in-memory, per-call) |
| Fixtures output → git working tree | Any disk write risks committing a key/cert or real-PII sample | Sample payloads (code-built, never persisted) |
| Generator CLI args → adopter source tree | Untrusted CLI args become module names, route opts, and inserted AST in the adopter's router (Sourceror/Igniter edit) | Module names, recipient strings |
| `Test.Ingress` (lib/) → real Persist + Execution write path | Drives the production DB write + mailbox execution synchronously in the test process | Inbound message records (sandboxed test DB) |
| Adopter matcher values → assertion failure messages | Caller values embedded in ExUnit output (adopter's own test logs) | Caller-supplied matcher values |
| MailboxCase setup → process-global CertCache ETS + per-process sandbox | Resets shared ETS and owns a sandbox checkout per test | None (reset/teardown only) |
| Packaged helpers → Hex artifact | Four lib/ modules become the public adopter-facing surface | Public API surface |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation (verified evidence) | Status |
|-----------|----------|-----------|-------------|--------------------------------|--------|
| T-47-01 | Information Disclosure | Minted RSA private key/cert in `build_ses_sns_payload/1` | mitigate (HIGH) | `fixtures.ex:459-464` `generate_sns_keypair/0` mints RSA-2048 in-process via `:public_key.generate_key`, used by `sign_canonical/2` (`:454`), discarded per call. No `File.write`/`File.open`; the only `.pem` hits are docstring (`:21`), comment (`:467`), URL string (`:472`) — never a path. No `CertCache.Fake` literal. Forged-sig self-test `fixtures_test.exs:154` proves the key is real. | closed |
| T-47-02 | Information Disclosure | Fixtures sample data | mitigate (HIGH) | All payload builders construct binaries/maps in code (`fixtures.ex:127,189,265,371`); defaults are `example.com`/`.test` addresses (`:46-49`). No `.eml` on disk, no on-disk fixture path, no real PII. | closed |
| T-47-03 | Tampering (test pollution) | Shared `:public` CertCache ETS across async tests | mitigate (MEDIUM) | `unique_cert_url/0` `fixtures.ex:470-473` appends `strong_rand_bytes(8)` suffix per call so concurrent primes never collide (`cert_url` per-call at `:391`). MailboxCase resets CertCache in setup `mailbox_case.ex:114`. Self-test `fixtures_test.exs:141-152` asserts distinct URLs. | closed |
| T-47-04 | Elevation / Access Control | Cross-tenant assertion via shared fixtures | mitigate (LOW) | `build_inbound_message/1` defaults `tenant_id` (`fixtures.ex:98`, const `:45`); every builder accepts `:tenant_id`. Self-test `fixtures_test.exs:16-23` asserts non-nil/non-empty default. | closed |
| T-47-05 | Tampering (code injection) | `gen.inbound_route` appending arbitrary code to a router | mitigate (HIGH) | `add_route/4` `inbound_route.ex:84-93` inserts via `Common.add_code(zipper, route_code, placement: :after)` — structured AST, no eval. `route_code/2` `:128-135` builds `route(Mod, k: v)` via `inspect/1`; mailbox arg flows through `parse_module/1` `:142-156` which regex-validates `^[A-Z]\w*(\.[A-Z]\w*)*$` and `Mix.raise`s otherwise, then `Module.concat/1`. No `Code.eval`/`eval_string`/`String.to_atom`. | closed |
| T-47-06 | Tampering (corruption) | Re-running `gen.inbound_route` double-inserts/corrupts router | mitigate (HIGH) | `route_already_present?/2` `inbound_route.ex:117-124` dup-scans via `move_to_function_call_in_current_scope(:route, 2, …)` + `argument_equals?(…, 0, mailbox)`; on match `add_route/4` is a `{:ok, zipper}` no-op (`:88-90`). Run-twice `assert_unchanged` self-test `inbound_route_test.exs:67-92`. | closed |
| T-47-07 | Tampering (malformed AST) | Malformed AST on single-statement router body | mitigate (MEDIUM) | `Common.add_code/3` with `placement: :after` (`inbound_route.ex:92`) promotes a single-statement `do`-block. Self-test `inbound_route_test.exs:46-61` asserts the route lands after `use MailglassInbound.Router` and compiles. | closed |
| T-47-08 | Tampering (unsafe defaults) | Generated mailbox enabling unsafe defaults | **accept (LOW)** | Generated `process/1` `gen.mailbox.ex:103-108` returns neutral `:accept`, no side effects. Grep-clean of `track`/`open`/`click`/`magic_link`/`password_reset`/`verify_email`/`confirm_account`. Inbound has no open/click tracking surface. **Accepted-risk justification verified present in code.** | closed |
| T-47-09 | Information Disclosure | Assertion failure messages embedding PII | mitigate (MEDIUM) | Messages embed only caller-supplied matcher values (`test_assertions.ex:162,166,170,185,189,193,269,292,310`), surfaced in the adopter's own ExUnit output. No `:telemetry` call in the file; PII posture moduledoc `:61-66`. | closed |
| T-47-10 | Tampering (test pollution) | `Test.Ingress` writing real records | **accept (LOW)** | `drive/3` `ingress.ex:216-228` calls only `Persist.persist/2` + `Execution.execute/2` + `send/2`. No `update`/`delete`/`truncate` (sole `Map.update` at `:202` is on the in-memory `normalized.evidence` map). Writes land in the adopter sandbox, rolled back via `Sandbox.stop_owner` (`mailbox_case.ex:134`); append-only `mailglass_events` never UPDATE/DELETEd. **Accepted-risk justification verified.** | closed |
| T-47-11 | Spoofing | Bypassing the real provider `verify!` seam | mitigate (LOW) | `receive_provider_payload/3` `ingress.ex:192` → `verify_request!/3` dispatches to the REAL provider modules (`Postmark.verify!` `:291`, `Sendgrid.verify!` `:295`, `Mailgun.verify!` `:298`, `SES.verify!` `:301`) — no weakened copy. Forged-sig self-test `fixtures_test.exs:154-164` confirms rejection. | closed |
| T-47-12 | Elevation / Access Control | Cross-tenant capture/assertion | mitigate (LOW) | Captured tuple carries the message's own `tenant_id`: `send(self(), {:inbound, message, outcome, persisted.route})` `ingress.ex:224`, where `message` carries `:tenant_id` (`:196-198`/`:131`). Assertions read the captured message (`test_assertions.ex:184`). Fixtures default a tenant (T-47-04). | closed |
| T-47-13 | Tampering (app-env leak) | MailboxCase leaking a global app-env value across tests | mitigate (HIGH) | `mailbox_case.ex` setup `:90-137` writes NO `Application.put_env`; sync execution is structural. Grep finds no `async_`/`put_env`/`Application.put`. Teardown is `Sandbox.stop_owner/1` (`:134`) + ETS/process-dict reset (`:114-115`). Self-test `mailbox_case_test.exs:55-79` asserts no `:async_*` key and env unchanged. | closed |
| T-47-14 | Tampering | Wrong repo / cross-app sandbox checkout | mitigate (HIGH) | Repo resolved from `Application.get_env(:mailglass_inbound, :repo)` with raise-if-unset `mailbox_case.ex:96-98`. `TestRepo` literal absent from `mailbox_case.ex` (grep clean); the one `lib/` hit (`ingress.ex:114`) is a `@doc` option-default mention, not code. Self-test `mailbox_case_test.exs:46-51` greps source: `refute content =~ "TestRepo"` + asserts app-env lookup. | closed |
| T-47-15 | Information Disclosure | Shipping internal-only helpers / real PII to Hex | mitigate (MEDIUM) | ExDoc Testing group lists exactly the four adopter-facing helpers `mix.exs:142-147` (`TestAssertions`, `MailboxCase`, `Test.Ingress`, `Fixtures`). `files:` manifest `:113` = `~w(lib docs priv .formatter.exs mix.exs README* CHANGELOG* LICENSE*)` — NO `test` path, so `test/support` `TestRepo` (`:62`) is excluded. SUMMARY 47-04 records `mix hex.build` confirmation. | closed |
| T-47-16 | Tampering | Shared CertCache ETS race under async | mitigate (MEDIUM) | MailboxCase resets `CertCache` in setup `mailbox_case.ex:114`; SES fixtures use per-call unique cert URLs (`fixtures.ex:470-473`) and SES self-tests run `async: false` (`fixtures_test.exs:6`). | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-47-01 | T-47-08 | Generated mailbox could ship unsafe defaults. **Verified:** inbound has no open/click tracking surface; generated `process/1` returns neutral `:accept` with no auth heuristics emitted (`gen.mailbox.ex:103-108`, grep-clean of tracking/auth-heuristic tokens). | gsd-security-auditor | 2026-05-24 |
| AR-47-02 | T-47-10 | `Test.Ingress` writes real records. **Verified:** writes go to the adopter's sandboxed test DB, rolled back per test by `Sandbox.stop_owner` (`mailbox_case.ex:134`); the driver performs no UPDATE/DELETE on the append-only `mailglass_events` ledger (`ingress.ex:216-228`). | gsd-security-auditor | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 16 | 16 | 0 | gsd-security-auditor (verify-mitigations mode) |

**Process observation (non-blocking):** SUMMARY `47-02` (generators) omits the `## Threat Flags` heading present in 47-01/03/04. No security impact — the generator surface is fully covered by T-47-05/06/07/08 in the PLAN register, all CLOSED. Noted only as a documentation-consistency gap for future SUMMARY hygiene.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
