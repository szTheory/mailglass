# Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor - Context

**Gathered:** 2026-06-16 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `mix mailglass.install` fail closed (`Mix.raise`, non-zero exit) with an actionable
error — plus a `--force` escape hatch — when it can't safely wire the webhook body_reader,
so the already-detected unmanaged `Plug.Parsers` conflict can no longer warn-then-continue
into a silent production webhook 401. Add a verifiable post-install webhook-wiring check that
confirms `Mailglass.Webhook.CachingBodyReader` is wired into the endpoint parser and exits
non-zero when it isn't. Tests-first (INSTALL-01..04).

**Confined to:** `lib/mailglass/installer/*`, `lib/mix/tasks/mailglass.install.ex`, and a new
doctor mix task (+ internal runner). NO outbound/webhook/inbound runtime-contract, schema, or
public-error-set changes. Installer's plan/apply architecture is NOT redesigned — this is the
minimal fail-closed routing of one already-detected conflict.
</domain>

<decisions>
## Implementation Decisions

### Fail-Closed Mechanism (INSTALL-01)
- **D-01:** `validate_preflight/1` (`lib/mailglass/installer/apply.ex:47-76`) returns
  `{:error, {:unmanaged_parser_conflict, endpoint_path}}` instead of calling
  `Mix.shell().info([:yellow, ...])` and discarding the result. The conflict condition is
  unchanged: stripped endpoint contains `plug Plug.Parsers` AND lacks `body_reader`
  (`apply.ex:64-65`).
- **D-02:** The error is threaded as the FIRST step of `Apply.run/2`'s `with` chain
  (`apply.ex:32-36`) — change the bare `validate_preflight(opts)` statement to
  `with :ok <- validate_preflight(opts), {:ok, manifest} <- Manifest.load(...), ...`. This
  preserves `Apply.run/2`'s existing `{:ok, map} | {:error, term()}` contract (`apply.ex:27`).
- **D-03:** The mix task needs only a new `format_error/1` clause carrying the actionable
  message; the existing `{:error, reason} -> Mix.raise(format_error(reason))` at
  `lib/mix/tasks/mailglass.install.ex:61-63` already produces the non-zero exit. The actionable
  message names the endpoint path, explains the silent-401 risk, and documents both remediation
  paths (add `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` to your parser,
  OR re-run with `--force`).
- **D-04:** `--force` is checked INSIDE `validate_preflight/1` (it already receives `opts`) so
  force returns `:ok` and skips the error.

### `--force` Semantics (INSTALL-02)
- **D-05:** `--force` ONLY skips the new preflight error — today's "managed parser inserted
  ABOVE the existing one" behavior already happens automatically and is unchanged. The endpoint
  parser is an `:ensure_block` op anchored to `use Phoenix.Endpoint` (`plan.ex:156-170`);
  `insert_after_anchor/3` (`apply.ex:342-371`) inserts the managed block right after that line
  (top of the endpoint, hence above any later unmanaged `plug Plug.Parsers`), and Plug runs
  parsers in source order so the managed body_reader parser wins. NO change to
  `plan.ex`/`templates.ex`/`apply_ensure_block` is required for `--force`.
- **D-06:** `--force` is documented in BOTH the fail-closed error message (D-03) AND the
  getting-started troubleshooting section (the docs touch lands here or is handed to Phase 105 —
  the error-message half is in-scope for 104; coordinate the guide half with 105's docs work).

### Doctor Task Shape + Detection (INSTALL-03)
- **D-07:** Add a NEW dedicated `mix mailglass.doctor` task (CONFIRMED by user over a
  `mail.doctor` lane). Rationale: `mix mail.doctor` is hard-bound to DNS deliverability and
  REQUIRES `--domain` (`lib/mix/tasks/mail.doctor.ex:70-72`); adding an offline webhook lane
  would force an unrelated `--domain` and relax the DNS task's CLI contract — a scope-lock
  violation.
- **D-08:** Back the task with an internal runner module (pure function returning a
  findings/summary map), mirroring the established
  `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` → `MailglassInbound.Internal.Doctor`
  precedent. Keep the mix task a thin CLI shell over the runner.
- **D-09:** Detection is a STATIC SOURCE SCAN of `lib/<app>_web/endpoint.ex` (reuse the
  app-detection + endpoint-path derivation already in `validate_preflight`/`Plan.detect_otp_app`),
  checking for `body_reader` / `Mailglass.Webhook.CachingBodyReader` / the managed-block markers
  (`# mailglass:start endpoint_webhook_parser`, `templates.ex:73`). NOT runtime plug-pipeline
  reflection — static scan is offline, deterministic, and runnable inside the install-fixture
  harness (which never boots the host endpoint).
- **D-10:** Three-state exit codes mirroring the inbound doctor: `0` wired correctly / `1`
  CachingBodyReader absent (the non-zero CI signal INSTALL-03 requires) / `2` cannot diagnose
  (endpoint.ex not found / app not detectable).

### Test Approach (INSTALL-04)
- **D-11:** Tests follow the `test/mailglass/install/install_idempotency_test.exs` +
  `Mailglass.Test.InstallerFixtureHelpers` fixture pattern. Seed the conflict by `File.write!`-
  overwriting the fixture's `lib/example_web/endpoint.ex` AFTER `new_fixture_root!/1` to add a
  bare `plug Plug.Parsers` (NO `:body_reader`) OUTSIDE the managed markers — the default skeleton
  endpoint (`installer_fixture_helpers.ex:263-269`) is bare and never triggers the conflict.
- **D-12:** Fail-closed test asserts the conflict is surfaced. Prefer calling
  `Mailglass.Installer.Apply.run/2` directly to assert the exact
  `{:error, {:unmanaged_parser_conflict, _}}` tuple (struct/tuple match, no message-string
  matching — per engineering DNA); the fixture helper already re-raises on `{:error, reason}`
  (`installer_fixture_helpers.ex:41-43`) so an `assert_raise` path through `run_install!/2` is
  also available for the task-level assertion.
- **D-13:** `--force` test passes `["--force"]`, asserts install succeeds AND asserts ORDERING
  (managed webhook block appears BEFORE the unmanaged `plug Plug.Parsers` in the resulting
  endpoint.ex) — not merely that install completed.
- **D-14:** Doctor test runs install against the fixture then invokes the new doctor runner
  against the fixture root (via `File.cd!(fixture_root, ...)` so the static scan resolves the
  relative endpoint path), asserting the wired case returns 0 and an unwired/stripped case
  returns non-zero (1).

### Claude's Discretion
- Exact wording of the actionable fail-closed message (must name the endpoint path, the
  silent-401 risk, the `body_reader` fix, and `--force`).
- Exact module name/location of the doctor internal runner (e.g.
  `Mailglass.Installer.Doctor` or `Mailglass.Webhook.Doctor`) — keep it in the installer/webhook
  namespace and Boundary-classified to `Mailglass`.
- Whether to add a dedicated `format_error/1` clause vs. relying on the catch-all (D-03 prefers
  a dedicated clause for the actionable message).
- `mix mailglass.doctor` flag surface (`--format json`, `--verbose`) — mirror the inbound
  doctor only as far as INSTALL-03 needs; don't over-build.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/mailglass/installer/apply.ex` — `validate_preflight/1` (47-76), `Apply.run/2` (27-45),
  `insert_after_anchor/3` (342-371), conflict/error plumbing
- `lib/mix/tasks/mailglass.install.ex` — `run/1` (30-64), `format_error/1` (125-147),
  `maybe_raise_conflict_error/1` (108-112)
- `lib/mailglass/installer/plan.ex` — endpoint `:ensure_block` op + anchor (`use Phoenix.Endpoint`)
- `lib/mailglass/installer/templates.ex` — managed-block markers (72-95), `Plug.Parsers`
  body_reader block, `CachingBodyReader` wiring
- `lib/mix/tasks/mail.doctor.ex` — DNS-only, `--domain`-required contract (the task NOT to touch)
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` +
  `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` — the dedicated-doctor +
  three-state-exit-code precedent to mirror
- `test/mailglass/install/install_idempotency_test.exs` — fixture test pattern to follow
- `test/support/installer_fixture_helpers.ex` — `new_fixture_root!/1`, `run_install!/2`,
  `host_endpoint/0` skeleton (263-269), `{:error, reason}` re-raise (41-43)
- `.planning/REQUIREMENTS.md` — INSTALL-01..04 acceptance criteria
- `CLAUDE.md` — engineering DNA (errors as struct contract, pattern-match by struct never message)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The conflict-detection predicate already exists in `validate_preflight/1` (strip managed
  block, then `contains "plug Plug.Parsers"` AND `not contains "body_reader"`) — reuse verbatim
  for both the fail-closed gate and the doctor scan.
- `Plan.detect_otp_app/0` + the `lib/<app>_web/endpoint.ex` path derivation give the doctor its
  target file with no new discovery logic.
- The managed-block markers in `templates.ex` are stable, greppable anchors for both the
  installer and the doctor.
- `InstallerFixtureHelpers` already supports post-creation mutation, `run_install!/2`, and
  `File.cd!` scoping — everything the new tests need.

### Established Patterns
- `Apply.run/2` returns `{:ok, map} | {:error, term()}`; the task funnels every error through
  `format_error/1 → Mix.raise` for a uniform non-zero exit. The fail-closed path rides this rail.
- Doctor tasks in this project are thin mix shells over a pure internal runner returning
  `%{summary, findings}`, with three-state exit codes (0/1/2). Mirror it.
- Errors are matched by struct/tuple, never message string (engineering DNA) — tests assert the
  `{:error, {:unmanaged_parser_conflict, _}}` tuple.

### Integration Points
- `validate_preflight/1` return value → `Apply.run/2` `with` chain → `mailglass.install.ex`
  `{:error, reason}` clause → `format_error/1` → `Mix.raise` (non-zero exit).
- New `mix mailglass.doctor` → internal runner → static scan of derived `endpoint.ex` path →
  three-state exit code.
- `--force` opt flows from `OptionParser` (already declared, `mailglass.install.ex:33`) into
  `opts` → read inside `validate_preflight/1`.
</code_context>

<specifics>
## Specific Ideas

- The `--force` "preserve today's behavior" requirement is satisfied with zero changes to the
  insertion logic — it is purely "skip the raise." The risk to guard against is the managed block
  landing BELOW the adopter's parser; the `--force` test must assert ordering, not just success.
- Seed-correctness footgun for tests: the seeded `plug Plug.Parsers` must have NO `body_reader`
  text and must sit OUTSIDE the managed markers, or `validate_preflight`'s guard is satisfied and
  the test passes vacuously.
</specifics>

<deferred>
## Deferred Ideas

- Broader installer plan/apply refactor — explicitly out of scope (REQUIREMENTS.md
  Out-of-Scope): the fix is minimal fail-closed routing of one detected conflict.
- The getting-started troubleshooting GUIDE prose for `--force` (DOCS work) is owned by
  Phase 105; Phase 104 owns only the in-error-message documentation of `--force`.

### Reviewed Todos (not folded)
None — no pending todos matched this phase's scope.
</deferred>
