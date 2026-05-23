# Phase 45 — Gap-Closure Research & Synthesis

**Produced:** 2026-05-23 (during `/gsd-plan-phase 45 --gaps`)
**Inputs:** `45-VERIFICATION.md` (status: gaps_found, 5/7 truths), `deferred-items.md`, four parallel research agents (Credo checks / optional-dep+CI / PII egress / doc honesty), the `prompts/` deep-research corpus, and live code.
**Status:** Ready for planning. **No VERY-impactful decision surfaced — every item is a confident "just do it."**

This document is the planner's primary input alongside `45-VERIFICATION.md`. It records WHAT to fix, the chosen approach, exact file targets, and the rationale, so plans are concrete and coherent rather than re-derived.

---

## Root concern (the through-line)

Every finding is the same defect class: **a guarantee that is claimed in code/docs/SUMMARY but is silently inert.** Two custom Credo guards do nothing for their stated target; a CLAUDE.md-mandated CI lane is absent (and would fail if added); two moduledocs assert protections the code doesn't deliver; one error path leaks the very PII the project forbids. The functional Phase-45 deliverables (4 spans, never-raising MIME parser, 1000-run convergence, post-commit broadcast) are sound — this pass closes the *enforcement/honesty* gap around them. The architecturally-coherent move is therefore not just to fix the five items but to make the enforcement **self-verifying** so this class can't recur.

---

## Scope decision (auto-resolved)

**In scope — all five findings + cheap recurrence guardrails:**

| # | Finding | Sev | Approach | Effort |
|---|---------|-----|----------|--------|
| CR-01 | `NoBareOptionalDepReference` inert for gen_smtp | 🛑 Blocker | Atom-key `gated_modules` + regression test | XS |
| WR-02 | `TelemetryEventConvention` span-blind | ⚠ Warning | Add `:telemetry.span/3` walk clause + test | S |
| WR-03 | No inbound `--no-optional-deps` lane; compile fails | ⚠ Warning | `no_warn_undefined` + dedicated CI job | XS |
| PII | `plug.ex:84` `inspect(reason)` leaks changeset PII | ⚠ Warning | Static code body + classifier; keep 500 | S |
| DOC | mime.ex + gen_smtp.ex moduledocs overclaim | ℹ Info | Relabel (keep guard) + correct `:undef` attribution | XS |
| +Guard | Recurrence backstops | — | Check-coverage meta-test + `.credo.exs` config sentinel + egress Credo check | S |

**Out of scope (correctly deferred, do NOT pull in):**
- Provider-fed MIME DoS hardening (decoder-level limits) → **Phase 46** (transport wiring). We only correct the *doc claim* here.
- Admin-side inbound subscription wiring → **Phase 48** (the broadcast surface already ships).

**Reversibility check:** every change is internal (lint config, a CI job, a moduledoc, a PII-free error body). Zero public-API or locked-decision impact. The one contract-shaped choice — HTTP status on the error path — is explicitly *unchanged* (stays 500, which is the correct retry signal for all four providers). Nothing here meets the "ask the user" bar.

---

## CR-01 — Make `NoBareOptionalDepReference` catch gen_smtp (BLOCKER)

**Why inert:** `gen_smtp` is an Erlang lib with no `GenSmtp` Elixir module. Call sites are bare atoms `:mimemail.decode/2` (`lib/mailglass/optional_deps/gen_smtp.ex:72`) and `:gen_smtp_client` (`:46`). `.credo.exs` keys `gated_modules` on the alias `GenSmtp`, so at `:mimemail.decode(raw)` the check computes `root_module → {:ok, :mimemail}`, `Map.fetch(gated_modules, :mimemail)` MISSES, the `with` short-circuits, no issue raised. The 45-01 "verified by probe" only exercised `Oban` (a real Elixir module the check *does* catch via the `{:__aliases__,...}` path) — the Erlang-atom path was never probed and has no regression test.

**Approach (config-only — no check-code change):** `root_module/1` already has `defp root_module(root) when is_atom(root), do: {:ok, root}` (line 105), and `allowed_module?/2` already keys on the enclosing `defmodule`. The only bug is missing map keys. Add the real Erlang module atoms to `.credo.exs` `gated_modules`:

```
:mimemail        => Mailglass.OptionalDeps.GenSmtp,
:gen_smtp_client => Mailglass.OptionalDeps.GenSmtp
```

Keep the existing `GenSmtp => [...]` alias key (inbound `mime.ex` reaches the gateway via `alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp` → call root resolves to `GenSmtp`; that path must keep passing). Consequence (correct): the gateway `gen_smtp.ex` is the one sanctioned bare-atom call site — `allowed_module?` recognizes its enclosing `Mailglass.OptionalDeps.GenSmtp` and passes it, while any other file calling `:mimemail.decode` now fails. **Reject** the `root_module/1` generalization alternative — it duplicates logic that already works. gen_smtp is the only Erlang-atom optional dep (`Oban`/`OpenTelemetry`/`Mjml`/`Sigra` are Elixir modules; `:telemetry` is non-optional, not gated).

**Regression test:** `test/credo_checks/no_bare_optional_dep_reference_test.exs`, `use Credo.Test.Case`.
- **Filename trap (critical):** the check is path-gated via `included_path_prefixes`, and `to_source_file/1` defaults to `test-untitledN.ex` (matches no prefix → silently inert). MUST use the 2-arity `to_source_file(source, "mailglass_inbound/lib/.../x.ex")`.
- Cases: (a) bare `:mimemail.decode/1` in a non-gateway inbound file → `assert_issue`; (b) `:mimemail.decode/1` inside `defmodule Mailglass.OptionalDeps.GenSmtp` → `refute_issues`; (c) bare `Oban.insert/1` outside its gateway → `assert_issue` (pins the path the old probe covered). Pass `gated_modules` params explicitly so the test pins *behavior* independent of `.credo.exs` drift (the config sentinel below pins the config).

---

## WR-02 — Make `TelemetryEventConvention` cover spans (WARNING)

**Why inert:** `walk/5` only matches `{{:., _, [:telemetry, :execute]}, ...}` (`credo_checks/telemetry_event_convention.ex:31`). Every inbound event is `:telemetry.span/3` (`telemetry.ex:~135`), so the widened `required_root: [:mailglass, :mailglass_inbound]` checks nothing in inbound.

**Approach:** add a second `walk/5` clause for `:telemetry.span/3`, mirroring the proven dual-clause pattern already in this repo (`no_pii_in_telemetry_meta.ex:52-60` handles both forms). **Off-by-one:** `:telemetry.span/3`'s runtime appends `:start`/`:stop`/`:exception`, so the literal *prefix* is one segment shorter than the emitted event. The span clause validates `length(prefix) >= min_segments - 1` (≥3 for the configured `min_segments: 4`) AND `hd(prefix) in required_roots` — exactly like the execute clause, just the length threshold differs. Refactor the shared root/length logic into a `validate/_` helper parameterized by the threshold. Non-literal prefixes (a var) → no issue (matches execute behavior, avoids false positives). Set `trigger: ":telemetry.span"` on the span path for accurate editor jump-to; keep the issue message reporting `min_segments` (operators think in final event names).

**Fixture test:** `test/credo_checks/telemetry_event_convention_test.exs` (NOT path-gated → default filenames fine). Cover: 3-seg span prefix → pass; 2-seg span prefix → issue; non-mailglass span root → issue; under-segmented `:telemetry.execute` → issue; 4-seg `:telemetry.execute` → pass.

---

## WR-03 — Inbound `--no-optional-deps` lane + the Oban-seam warning (WARNING)

**Root cause (real gap, NOT a toolchain artifact):** the 1.18/1.19 difference only affects *format* drift (45-01), not this compile warning. Under `--no-optional-deps`, Oban is stripped from both inbound's own dep and the path-dep core. The inbound worker module is fully compile-gated (`worker.ex:1` wraps everything in `if Code.ensure_loaded?(Oban.Worker)`), and core's `Mailglass.Oban.TenancyMiddleware` is likewise elided behind `Code.ensure_loaded?(Oban.Worker)` (`optional_deps/oban.ex:87`). So there's no *runtime* reference. The undefined-warning fires from the static xref pass because of an **asymmetry in the suppression lists**: core's `mix.exs:105` lists `Mailglass.Oban.TenancyMiddleware` in `no_warn_undefined` (and re-declares it via `@compile` in `lib/mailglass.ex:2`), but **inbound's `mix.exs:46` lists only `[Oban, Oban.Job, Oban.Worker]`** — missing the cross-package middleware module. With inbound's list incomplete, `--warnings-as-errors` → exit 1.

**Approach (mirror core, ~1 identifier):** add `Mailglass.Oban.TenancyMiddleware` to inbound's `elixirc_options` `no_warn_undefined` in `mailglass_inbound/mix.exs`. This is the purpose-built tool for a reference that is known-safe at runtime (it lives inside the `Code.ensure_loaded?` gate at both elision sites) but unresolvable to static xref across the package boundary. Keep the list tight — do **not** pre-add `Mailglass.Outbound.Worker` (no current inbound reference; add only when one appears). **Reject** the alternatives: routing through an inbound `OptionalDeps.Oban` gateway re-exposes a *core* public contract under a second name (violates one-name-per-concept); a module-level `@compile {:no_warn_undefined, ...}` inside `worker.ex` sits inside the elided `if` block and never takes effect during the failing compile — it must be project-level.

**CI lane:** add a dedicated `inbound_compile_no_optional_deps` job to `.github/workflows/ci.yml` mirroring core's `compile_no_optional_deps` plus inbound's two-step dep fetch (`mix deps.get` in root, then `working-directory: mailglass_inbound`). Pin Elixir 1.18 / OTP 27, pin all third-party actions to commit SHA (per CLAUDE.md), cache `deps` + `mailglass_inbound/deps`. **Compile-only — no Postgres service, no `MIX_ENV: test`, separate job (not a step in `inbound_test`)** so a compile-gate failure is legible in the checks list and runs in parallel. The new lane is genuinely additive coverage: core's lane uses `--only test` and never exercises the inbound→core cross-package reference.

**Scope = NOW, not deferred** (overriding deferred-items.md's "future Oban-seam plan" suggestion): the fix is one identifier + one YAML job with zero runtime impact, and a CLAUDE.md-mandated lane that is silently absent while plans report it green is exactly the claimed-but-inert defect class this whole pass exists to eliminate. Pair the fix and the lane in one commit so the lane proves the fix (red→green in one CI run).

---

## PII leak — `plug.ex:84` error response (WARNING)

**Confirmed vector:** `Persist.persist/2` returns `{:error, %Ecto.Changeset{}}` whose `changes` carry `subject`/`from`/`to`/`cc`/`bcc`/`reply_to`/`text_body`/`html_body` (built `persist.ex:118-137`). At `plug.ex:84`, `inspect(reason)` renders the whole changeset into the JSON 500 body sent to Postmark/SendGrid — recipient email contents in plaintext on a transient DB failure. This is the only leaky branch; the three `rescue` clauses (lines 96/100/105) already emit closed `Atom.to_string(e.type)` codes (PII-free, asserted by tests).

**Approach:**
- **Body:** never interpolate `reason`. Return a static closed code, e.g. `%{status: "error", reason: "persist_failed"}` (consistent with the existing rescue-clause `{status, atom}` style and the brand voice). Converge on the core webhook plug, which already does this right (`lib/mailglass/webhook/plug.ex:193` returns an empty/static body).
- **Status: keep 500.** Verified correct retry semantics for all four providers: Postmark retries any non-200 (only 403 hard-stops); SendGrid Inbound Parse retries 5xx but **drops 4xx with no retry** (downgrading would permanently lose the email); Mailgun retries non-{200,406}; SES→SNS retries non-2xx. A transient DB error is operational, not an Anymail rejection — must stay 500. Leave the existing 401/422 rescue clauses (correct hard-fails).
- **Detail goes where it's safe (adopter DX):** carry a PII-free classified atom in the telemetry stop-metadata via a private `classify_persist_error/1` (`%Ecto.Changeset{} → :changeset_invalid`, `:not_found → :not_found`, `atom → atom`, `_ → :unknown`) as `error_kind`. Do NOT pass `reason` to span exception metadata (this is an `{:error, _}` tuple, not a raise). For field-level debugging, a scrubbed `Logger.error` may log `Ecto.Changeset.traverse_errors` *keys/messages only* (never `changes` values). The durable full-fidelity record already exists in the committed `InboundEvidence` row (tenant-scoped) — the correct place to inspect what arrived.

**Recurrence guardrail (egress check):** add a Credo check (or extend `NoFullResponseInLogs`) that flags `inspect(...)` / changeset / bare error-var inside `send_resp`/`send_json`/`put_resp_body` argument heads within the webhook + ingress path prefixes — closing the "no PII in ANY egress (logs, telemetry, AND response bodies)" hole that today's checks miss. Scope it narrowly to those call heads to avoid false positives on legitimate `inspect` elsewhere. The second defense layer already exists: `@derive {Jason.Encoder, only: [...]}` whitelists on the error structs (`:cause` excluded) so PII can't serialize even if a struct slips into a body — keep that discipline.

---

## DOC — Honest moduledocs (Info; underlying threats stay deferred)

**mime.ex depth guard — KEEP, RELABEL (verified ordering):** `decode_and_build/2` calls `OptionalGenSmtp.decode(raw)` *first* (`mime.ex:128`), which fully parses to any depth (`:mimemail` has no recursion limit), THEN `collect_leaves/3` walks the already-built tree and throws `@depth_exceeded` at `depth > max_depth` (`mime.ex:173`). So the guard bounds the **internal representation walk**, not decoder recursion — it does not stop the boundary-bomb it's documented (mime.ex:100-102, contract bullet 19-22) to defend. **Keep** the guard (it gives a deterministic structured ceiling on the repr the pipeline iterates, and is the seam Phase 46's real decoder limit plugs into) but correct the docs with an ExDoc `> #### Note {: .info}` admonition stating what it does/doesn't do and that provider-fed DoS hardening is Phase 46. Fix the contract bullet ("or the deep-nesting guard tripped" → "or the representation exceeded `:max_depth`"). Rename the test `describe` at `mime_test.exs:116` to drop "boundary-bomb" (→ "representation max_depth guard"); test bodies are fine (they assert never-raise/MIME-04, which is true).

**gen_smtp.ex moduledoc — fix `:undef` attribution:** when `:mimemail` is absent, the call raises a class-`:error` `:undef` → surfaced as `UndefinedFunctionError` → caught by **`rescue`**, not `catch :exit`. Current moduledoc (lines 21-37) wrongly bundles `:undef` under `catch :exit`. Reword the three-mechanism list: `rescue` absorbs raised errors (incl. the `:undef` backstop when `decode/2` is reached without the `available?/0` gate; normal degraded path returns `:gen_smtp_unavailable` upstream); `catch :throw` absorbs thrown reasons; `catch :exit` absorbs exit signals (the `iconv` exit, itself defensive since `{:encoding, :none}` skips iconv). No test change needed.

---

## Recurrence guardrails (cohesive backstops — include)

These directly target the failure class (claimed-but-inert) and fit the project's "custom Credo checks at lint time" + self-verifying-enforcement DNA:

1. **Check-coverage meta-test** — `test/credo_checks/checks_have_tests_test.exs`: glob `credo_checks/*.ex`, assert each has a matching `*_test.exs`. Would have caught both CR-01 and WR-02 (neither had a test). ~20 lines.
2. **`.credo.exs` config sentinel** — assert the load-bearing keys exist: `gated_modules` contains `:mimemail` + `:gen_smtp_client`, and `TelemetryEventConvention` `required_root` includes `:mailglass_inbound`. Antidote to "behavior test passes against hand-passed params while real config is wrong."
3. **Egress Credo check** (the PII-egress check above) — makes "no PII in response bodies" enforceable rather than convention.
4. **Convention note** (record in `45-PATTERNS.md` / conventions): a moduledoc claim of the form "protects against / prevents X" must point at a test named for X; if none can exist yet, downgrade to "bounds Y" + a deferred-to-Phase-N note. (Convention only — no automated NLP check; that's overengineered.)

---

## Suggested plan shape (planner may refine)

Mostly independent; group by enforcement surface:
- **Credo-check correctness + meta-guardrails** (CR-01 + WR-02 + check-coverage meta-test + `.credo.exs` sentinel) — one plan; all touch `credo_checks/` + `.credo.exs` + `test/credo_checks/`.
- **Optional-dep compile lane** (WR-03: `mailglass_inbound/mix.exs` + `.github/workflows/ci.yml`) — one plan; pair fix+lane in one commit.
- **PII-safe ingress error path** (plug.ex fix + classifier + egress Credo check + its test) — one plan.
- **Doc honesty** (mime.ex moduledoc/contract + mime_test rename + gen_smtp.ex moduledoc) — one plan; doc/test-only.

All four are parallelizable (disjoint files except `.credo.exs`/`credo_checks/`, which the first and third plans share — sequence those or assign the egress check to the Credo plan). Keep `--no-optional-deps`/CI assertions and the Credo regression tests as explicit acceptance criteria so the closed gaps are themselves test-verified.

## Requirements & contracts to preserve
- No new PII anywhere (telemetry, logs, response bodies). Append-only `mailglass_events` untouched. Optional deps stay gated through `*.OptionalDeps.*`. Never-raise inbound contracts (MIME-04) hold. Errors as closed-`:type` structs, matched by struct not message. All third-party GH Actions pinned to SHA. No public-API change.
