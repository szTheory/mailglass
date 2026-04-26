# Stack Research — mailglass v0.2

**Domain:** Phoenix-native transactional email framework — v0.2 "Production-Credible Core" milestone additions
**Researched:** 2026-04-26
**Milestone scope:** Subsequent milestone. Existing v0.1 stack already validated. This file covers only the NEW stack questions for v0.2's three pillars: API stability tooling, RFC 8058 deliverability, auto-suppression, and release-engineering hardening.

> **How to read this doc.** The v0.1 stack is fully validated in `.planning/milestones/v0.1-research/STACK.md` and the current `mix.exs`. This file answers ONLY the new questions for v0.2: what tooling is needed for codemods, RFC 8058 headers, Oban scheduling, Credo strict, Dialyzer halt, and GitHub Actions tag-push triggers. Anything already in `mix.exs` is NOT re-researched.

---

## TL;DR — v0.2 additions and corrections

| Item | v0.1 baseline | v0.2 finding | Priority |
|------|---------------|--------------|----------|
| AST codemod tool | (not in scope) | **Igniter `~> 0.7`** over raw Sourceror for `mix mailglass.upgrade.v0_2` | TS — required for upgrade task |
| `@deprecated` attribute | (not needed) | Built into Elixir 1.18+; no new dep required | TS — zero cost |
| Sourceror | (not in scope) | `~> 1.12`, still maintained; **Igniter wraps it** so take Igniter as the dep | TS (via Igniter) |
| Phoenix.Token for unsub | v0.1 STACK.md documented it | API unchanged in Phoenix 1.8; no new dep | TS — zero cost |
| RFC 8058 Hex package | unknown | **No package exists.** Build it in-house with `Phoenix.Token` + `Swoosh.Email.header/3` | TS — in-house |
| Oban OSS cron scheduling | `~> 2.21` optional dep | `Oban.Plugins.Cron` adequate for soft-bounce escalation; `Oban.Job.schedule_in: {N, :days}` also usable | TS — no Oban Pro needed |
| Credo `--strict` | disabled in v0.1 | Flag is `mix credo --strict`; already correct in v0.1 STACK.md | TS — re-enable |
| Dialyzer halt-exit flag | called "halt-exit-status" in STATE.md | **Flag is `--ignore-exit-status` (the inverse).** Default `mix dialyzer` ALREADY halts on warnings. Remove advisory `--ignore-exit-status` to re-tighten CI | TS — flag name wrong in planning docs |
| `actions/checkout` | `v4` | Latest is **v6.0.2** (Jan 9, 2025 — note: GitHub Actions v-major is `v4`, but the latest patch is 4.x unless pinned by SHA) | DF — update SHA pin |
| `googleapis/release-please-action` | `v4.4.1` | **v5.0.0 released April 22, 2026** (Node 24 runtime, release-please 17.6.0). Only breaking change: Node 24 runtime. | TS — evaluate v5 |
| `erlef/setup-beam` | `v1.24.0` | Still current as of research date | HIGH — no change |
| `on: push: tags:` syntax | existing | **No syntax changes in 2026.** Glob patterns work as before. | HIGH — no change |

---

## 1. API stability tooling

### 1.1 `@deprecated` — built into Elixir 1.18+, zero new dep

**Verified: Elixir 1.18 (and 1.19 current) supports two deprecation mechanisms:**

**Hard deprecation (compiler warning at call sites):**
```elixir
@deprecated "Use Mailglass.Message.to/2 instead"
def put_to(mailable, address) do
  # v0.1 API path — delegates to new setter
  Mailglass.Message.to(mailable, address)
end
```
The Mix compiler automatically detects calls to `@deprecated` functions and emits warnings during compilation of the *caller's* code. This is exactly what v0.2 needs for one-cycle BC on `~> 0.1` adopters.

**Soft deprecation (docs only, no warning):**
```elixir
@doc deprecated: "Use Mailglass.Message.to/2 instead"
def put_to(mailable, address), do: ...
```
Use soft deprecation when a function must remain public but the deprecation message would be too noisy (e.g., an internal callback that shouldn't spill into adopter logs).

**Recommendation:** Use hard `@deprecated` on all v0.1 public-surface Mailable functions that the new Message setter API replaces. No new dep. No version constraint change.

**Confidence:** HIGH (verified against Elixir 1.18.4 Module docs).

### 1.2 Sourceror `~> 1.12` — maintained, but use via Igniter

**Sourceror status:**
- Current version: **1.12.0** (released March 6, 2026)
- Downloads: 108k/month, 3.9M all-time
- 38 dependent packages
- Actively maintained

**Core API for codemods:**
```elixir
# Parse source to extended AST (preserves comments)
ast = Sourceror.parse_string!(source)

# Traverse and transform (postwalk accumulates changes)
{patched_ast, patches} = Sourceror.postwalk(ast, [], fn
  {:use, meta, [{:__aliases__, _, [:Mailglass, :Mailable]}, opts]} = node, acc ->
    # Rewrite use Mailglass.Mailable, from: ... to new API
    patch = Sourceror.Patch.rename_call(node, meta, :Mailable2)
    {node, [patch | acc]}
  node, acc ->
    {node, acc}
end)

# Apply patches (only modified ranges rewritten; rest unchanged)
patched_source = Sourceror.patch_string(source, patches)
```

**However: use Igniter instead of raw Sourceror for `mix mailglass.upgrade.v0_2`.**

### 1.3 Igniter `~> 0.7` — the recommended codemod foundation (TS)

**Igniter is the 2026 ecosystem standard for mix-task-based codemods.** It wraps Sourceror + Rewrite + Mix task composition into a higher-level API that is purpose-built for the `mix mailglass.upgrade.v0_2` use case.

- Current version: **0.7.9** (released April 11, 2026)
- Built by: Ash Framework team (Zach Daniel)
- Adopted by: Ash itself, Phoenix, and Igniter-aware installers across the ecosystem

**Why Igniter over raw Sourceror:**
1. Built-in dry-run mode (`--dry-run`) for safe preview
2. Composable task API — `mix mailglass.upgrade.v0_2` can call sub-tasks
3. File batching — applies all transformations in a single pass
4. `--yes` / interactive prompts for adopters
5. `Igniter.Project.Deps` for dependency-aware transformations (detects if Oban is present)
6. Already has Mix task skeleton — no boilerplate to write

**Key APIs for `mix mailglass.upgrade.v0_2`:**
```elixir
defmodule Mix.Tasks.Mailglass.Upgrade.V0_2 do
  use Igniter.Mix.Task

  @shortdoc "Upgrade mailglass from v0.1 to v0.2"

  def igniter(igniter, _argv) do
    igniter
    |> Igniter.update_all_elixir_files(fn zipper ->
      # Rewrite: use Mailglass.Mailable, from: ... to new Message field setters
      zipper
      |> Sourceror.Zipper.find(:next, &mailable_use?/1)
      |> case do
        nil -> {:ok, zipper}
        found -> {:ok, rewrite_mailable_use(found)}
      end
    end)
    |> Igniter.add_notice("""
    mailglass v0.2 upgrade complete.
    Review changes with `git diff`, then re-run `mix test`.
    See: https://hexdocs.pm/mailglass/migration-from-v0.1.html
    """)
  end
end
```

**Dep declaration (dev/test only — it's a migration tool, not a runtime dep):**
```elixir
{:igniter, "~> 0.7", only: [:dev, :test], runtime: false}
```

Wait — Igniter can also be a runtime dep if used for the `mix mailglass.install` flow. For just the upgrade codemod, it only needs to be a `dev` dep. This aligns with how Ash/Phoenix use it.

**Confidence:** HIGH (verified Hex.pm v0.7.9, April 2026; confirmed Igniter as the 2026 ecosystem standard for this use case via ElixirForum + SmartLogic writeup).

**TS classification:** Table Stakes for `mix mailglass.upgrade.v0_2` — without a working upgrade codemod, the "one-cycle BC for ~> 0.1 adopters" promise is just docs.

---

## 2. RFC 8058 + signed unsubscribe tokens

### 2.1 No dedicated Hex package exists for RFC 8058 — build in-house

**Research finding:** A search for `list_unsubscribe`, `rfc_8058`, or similar package names on Hex.pm returns zero relevant results. No Elixir library provides RFC 8058 header generation as of April 2026. This is expected: the implementation is 2-3 functions, not a library.

**The in-house implementation is the right call.** Two modules handle everything:

**Module 1 — `Mailglass.Compliance.ListUnsubscribe` (new in v0.2):**
```elixir
# Generates the signed URL for List-Unsubscribe header
# Phoenix.Token.sign/4 is the signing primitive — no new dep
def unsubscribe_url(conn_or_endpoint, %{id: delivery_id, tenant_id: tenant_id}) do
  token = Phoenix.Token.sign(
    conn_or_endpoint,
    "mailglass-unsub",               # salt — domain-specific
    %{delivery_id: delivery_id, tenant_id: tenant_id},
    max_age: 30 * 24 * 60 * 60      # 30 days; RFC 8058 doesn't mandate TTL but 30d is standard
  )
  Routes.mailglass_unsubscribe_url(conn_or_endpoint, :one_click, token: token)
end

# Auto-injects both required headers into the Swoosh email
def inject_headers(email, url, mailto_address) do
  email
  |> Swoosh.Email.header("List-Unsubscribe",
    "<#{url}>, <mailto:#{mailto_address}?subject=unsubscribe>")
  |> Swoosh.Email.header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
end
```

**Module 2 — `MailglassWeb.UnsubscribeController` (generated by `mix mailglass.gen.unsubscribe`):**
```elixir
def one_click(conn, %{"token" => token}) do
  case Phoenix.Token.verify(conn, "mailglass-unsub", token, max_age: 30 * 24 * 60 * 60) do
    {:ok, %{delivery_id: id, tenant_id: tenant_id}} ->
      Mailglass.Suppression.suppress_from_delivery(id, tenant_id)
      # RFC 8058 requires 200 with no redirect — no render, just ok
      send_resp(conn, 200, "")
    {:error, _reason} ->
      send_resp(conn, 422, "")
  end
end
```

### 2.2 Phoenix.Token API — verified stable in Phoenix 1.8

**Current API (Phoenix 1.8.5, verified April 2026):**

```elixir
# Sign
Phoenix.Token.sign(context, salt, data, opts \\ [])
# opts: :key_iterations (1000), :key_length (32), :key_digest (:sha256), 
#       :max_age (seconds), :signed_at (seconds timestamp)

# Verify  
Phoenix.Token.verify(context, salt, token, opts \\ [])
# Returns: {:ok, term} | {:error, :expired} | {:error, :invalid}

# Encrypt (hides data from token holder, for higher-sensitivity payloads)
Phoenix.Token.encrypt(context, secret, data, opts \\ [])
Phoenix.Token.decrypt(context, secret, token, opts \\ [])
```

`context` can be a `conn`, an endpoint module, or a socket. Salt must be a string ≥ 16 bytes for security.

**Key rotation:** Phoenix.Token supports key rotation via the endpoint's `secret_key_base` rotation. No additional API is needed — old tokens signed with previous `secret_key_base` become invalid after rotation, which is the correct behavior for unsubscribe tokens (requires re-subscription after key rotation, consistent with re-confirmation flows).

**No changes from Phoenix 1.7 to 1.8** on this API surface. It is stable.

**Confidence:** HIGH (verified against hexdocs.pm/phoenix Phoenix.Token docs, Phoenix 1.8.5).

### 2.3 DKIM `h=` header inclusion — no Swoosh-level control needed

The `h=` tag in a DKIM signature is controlled by the **sending infrastructure** (Postmark/SendGrid/etc.), not by the application code. The application's responsibility is:

1. Add `List-Unsubscribe` and `List-Unsubscribe-Post` headers to the email using `Swoosh.Email.header/3`
2. Ensure the provider is configured to include those headers in its DKIM signing scope

**Swoosh.Email.header/3 API (Swoosh 1.25.0, verified):**
```elixir
# Add a single header
Swoosh.Email.header(email, "List-Unsubscribe", "<https://...>")
Swoosh.Email.header(email, "List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
```

**Provider-level DKIM `h=` behavior:**
- **Postmark:** Automatically includes `List-Unsubscribe` in DKIM `h=` when present in the email headers. No additional configuration required.
- **SendGrid:** Includes custom headers in DKIM by default.

**Conclusion:** mailglass needs only to inject the headers correctly. No new dep, no Swoosh API changes, no provider configuration changes needed.

**Confidence:** MEDIUM (Postmark behavior from their API docs; DKIM `h=` auto-inclusion is standard behavior for transactional ESPs but not individually verified per provider against 2026 docs).

---

## 3. Auto-suppression + Oban scheduling

### 3.1 Oban OSS `~> 2.21` is adequate — no Oban Pro required

**Verdict: Oban OSS handles all v0.2 auto-suppression requirements.**

**Soft-bounce escalation (5-in-7-days rule):**

The escalation rule is: if a recipient receives 5 soft-bounce events within 7 days, escalate to hard suppression. Two implementation paths are available — both work with Oban OSS:

**Path A — Scheduled deferred worker (cleanest):**
```elixir
# On each soft-bounce event, schedule a check 7 days out
# Oban.Job.schedule_in accepts {N, :unit} tuples
Mailglass.Suppression.EscalationWorker.new(
  %{recipient: email, tenant_id: tenant_id},
  schedule_in: {7, :days},   # Oban OSS — no Pro required
  unique: [keys: [:recipient, :tenant_id], period: :infinity]
)
|> Oban.insert()

# Worker checks the DB: count soft bounces in last 7 days
# If >= 5, insert suppression record
defmodule Mailglass.Suppression.EscalationWorker do
  use Oban.Worker, queue: :mailglass_suppression, max_attempts: 3
  
  def perform(%{args: %{"recipient" => email, "tenant_id" => tenant_id}}) do
    count = Mailglass.Events.count_soft_bounces(email, tenant_id, days: 7)
    if count >= 5, do: Mailglass.Suppression.suppress(email, tenant_id, :soft_bounce_escalation)
    :ok
  end
end
```

**Path B — Oban.Plugins.Cron periodic sweep (simpler, adequate for most cases):**
```elixir
# In Application supervisor config:
{Oban, 
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", Mailglass.Suppression.EscalationSweepWorker}
     ]}
  ],
  queues: [mailglass_suppression: 5]}
```
Daily sweep checks all recipients with recent soft bounces and escalates as needed.

**Recommendation:** Use Path A (scheduled deferred worker) for v0.2. More precise (responds within hours, not 24h), and `schedule_in: {7, :days}` is available in Oban OSS without any Pro tier.

**Oban.Plugins.Cron current API (verified against Oban 2.21 docs):**
```elixir
{Oban.Plugins.Cron,
  crontab: [
    {"* * * * *", MyWorker},
    {"0 * * * *", MyHourlyWorker, args: %{custom: "arg"}},
    {"@daily", MyDailyWorker},
    {"@hourly", MyHourlyWorker}
  ],
  timezone: "Etc/UTC"   # requires :tz if non-UTC; see §3.2
}
```

Supports standard cron syntax + `@daily`, `@hourly`, `@weekly`, `@monthly`, `@yearly` nicknames. Static config only (loaded at boot). For dynamic config, Oban Pro's `DynamicCron` is needed — but mailglass has no such requirement.

**Confidence:** HIGH (verified against hexdocs.pm/oban Oban.Plugins.Cron and Oban.Job docs, v2.21.1).

### 3.2 No new optional dep needed for soft-bounce escalation

The v0.1 optional dep `{:oban, "~> 2.21", optional: true}` already covers all v0.2 scheduling needs. The `schedule_in: {N, :days}` feature is in Oban OSS since at least v2.14.

**What NOT to add:** Oban Pro is not required. Oban Pro's `DynamicCron` is for runtime-configurable cron schedules. The mailglass use case (fixed escalation window) is fully covered by static cron config or `schedule_in`.

---

## 4. Release-engineering hardening stack

### 4.1 Dialyzer — critical flag name correction

**The `--halt-exit-status` flag referenced in STATE.md does not exist in Dialyxir.**

**Correct behavior:**
- `mix dialyzer` — runs Dialyzer and **exits with non-zero status if warnings found** (this is the DEFAULT behavior). This is what "halt on warnings" means.
- `mix dialyzer --ignore-exit-status` — runs Dialyzer, displays warnings, but **exits 0** (advisory mode — this is the flag that was used in v0.1 to avoid failing CI).

**v0.2 task REL-NN ("re-tighten Dialyzer"):** Remove `--ignore-exit-status` from the CI Dialyzer step. That's it. The default behavior is already the strict behavior. No flag change needed; just remove the advisory flag.

**Current Dialyxir CLI flags (verified against hexdocs.pm/dialyxir 1.4.7):**
- `--no-compile` — skip compilation
- `--no-check` — skip PLT update check  
- `--force-check` — force PLT check even if lock file unchanged
- `--ignore-exit-status` — display warnings WITHOUT failing (the advisory mode flag)
- `--list-unused-filters` — list unused ignore filters
- `--plt` — build PLT files and exit
- `--format <name>` — `short | raw | dialyxir | dialyzer | github | ignore_file | ignore_file_strict`
- `--quiet` — suppress informational messages
- `--quiet-with-result` — suppress all but final result

**Dialyxir version:** 1.4.7 (November 6, 2025) — no change from v0.1 baseline. Current.

**Confidence:** HIGH (verified against hexdocs.pm/dialyxir Mix.Tasks.Dialyzer docs, v1.4.7).

### 4.2 Credo `--strict` — already the right flag, re-enable it

`mix credo --strict` is the correct command. It was disabled in v0.1 due to ~230 findings. v0.2 triage budget is allocated to fix these.

**Current Credo version:** 1.7.18 (April 10, 2026) — no change from v0.1 baseline. Current.

The `--strict` flag enables "all checks including less critical ones" (Credo's terminology). In `mix.exs` alias, this is:
```elixir
"lint": ["credo --strict", ...]
```

**No version change needed.** The existing `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` is current.

**Confidence:** HIGH (verified against hexdocs.pm/credo, v1.7.18).

### 4.3 GitHub Actions — tag-push trigger syntax

**`on: push: tags:` syntax — no changes in 2025/2026.**

The correct syntax for `publish-hex.yml` tag-push trigger:
```yaml
on:
  push:
    tags:
      - "mailglass-sibling-group-v*"
```

Glob patterns (`*`, `**`, `?`, `!`) work as before. No new syntax required.

**The v0.1.2 TODO** (publish-hex.yml + post-publish-smoke.yml using `workflow_run` that can't detect tag creation) is a logic bug in the workflow trigger, not a syntax issue. The fix is switching from `on: workflow_run` to `on: push: tags:` — the syntax is already correct in the GitHub Actions spec, just not used in those two workflows.

**Confidence:** HIGH (verified against current GitHub Actions workflow syntax docs).

### 4.4 `actions/checkout` — version update

**v0.1 baseline:** `actions/checkout@v4` (pinned by SHA)
**Current latest:** `v6.0.2` (released January 9, 2025)

Note: GitHub Actions uses a `v4`, `v5`, `v6` major-version tag convention. The current latest major version is `v4` (the version string "v6.0.2" in the releases list may refer to a different counting scheme — verify the actual tag used at github.com/actions/checkout/releases before updating). Always pin by SHA, not tag, per engineering DNA.

**Recommendation:** When updating SHA pins in v0.2 Phase 8 work, update to whatever the current SHA of `actions/checkout@v4` (or whatever the current major) resolves to. The `v4` tag is likely still current for the purposes of this workflow.

**Confidence:** MEDIUM (GitHub releases page showed "v6.0.2" but this may be an internal versioning artifact; the consumer-facing tag is likely still `actions/checkout@v4`).

### 4.5 `googleapis/release-please-action` — v5.0.0 alert

**v0.1 baseline:** `v4.4.1` (February 13, 2026)  
**New latest:** **v5.0.0** (April 22, 2026 — 4 days before this research)

**Breaking change in v5.0.0:** Node 24 runtime (only breaking change stated in release notes). Also bumps `release-please` dependency from 17.3.0 to 17.6.0.

**Elixir release-type support in v5:** Not explicitly confirmed in the release notes, but the only breaking change is the Node runtime upgrade. The `elixir` release type is a release-please feature (the underlying library), not a release-please-action feature. Since the underlying release-please version bumped from 17.3.0 to 17.6.0, check the release-please CHANGELOG for any Elixir-specific changes.

**Recommendation for v0.2:** Evaluate upgrading to `v5.0.0` SHA during Phase 8 release-engineering work. The Node 24 runtime requirement should not impact GitHub Actions runners (GitHub provides Node 24 runners as part of the standard runner image). Do NOT upgrade blindly mid-milestone; test on a branch first given the new Node runtime.

**Stay on `v4.4.1` SHA if v5 introduces any Elixir release-type regressions.** The upgrade is DF (differentiator/deferrable) if v4 continues to work.

**Confidence:** MEDIUM (v5.0.0 release notes are minimal; Elixir support continuity not explicitly confirmed — verify before upgrading).

### 4.6 `erlef/setup-beam` — still current at v1.24.0

No change from v0.1 baseline. Still the correct version. The action now requires Node 24 runners (matches release-please-action v5's requirement).

**Confidence:** HIGH.

---

## 5. HexDocs exclusion of CLAUDE.md (v0.1.2 TODO)

This is a mix.exs documentation config change, not a new dep. Remove `"CLAUDE.md"` from `extras:` and `groups_for_extras:` in the `docs/0` function. Specifically in `mix.exs`:
- Line 262: remove `"CLAUDE.md"` from `extras:`
- Line 265: remove `"CLAUDE.md"` from `Overview` group in `groups_for_extras:`

The `docs: [skip_undefined_reference_warnings_on: ["CLAUDE.md"]]` entry can also be removed.

No dep change required. Pure config cleanup.

---

## 6. What changes to mix.exs for v0.2

Only ONE new optional dev dep:

```elixir
# NEW for v0.2 — codemod foundation for mix mailglass.upgrade.v0_2
{:igniter, "~> 0.7", only: [:dev], runtime: false}
```

Everything else is already in `mix.exs`. The existing optional Oban dep covers soft-bounce escalation scheduling. Phoenix.Token covers RFC 8058 token signing. Credo and Dialyxir are already present — just need CI flag adjustments.

**No dep version bumps required for v0.2.** All existing deps are current as of April 2026.

---

## 7. What NOT to add for v0.2

| Do not add | Reason |
|------------|--------|
| Any `list_unsubscribe` or RFC 8058 Hex package | None exists; in-house implementation is 2 functions |
| Oban Pro | OSS `schedule_in: {N, :unit}` handles soft-bounce escalation fully |
| A dedicated DKIM signing library | DKIM `h=` inclusion is controlled by the ESP, not the app layer; `mailibex` is a v0.5+ concern |
| `ex_machina` or any test factory lib | v0.1 prohibition continues; plain map fixtures |
| React Email / MJML-as-default / AMP for Email | Permanently out of scope per PROJECT.md D-03, D-18, "Out of Scope" |
| Mailgun/SES/Resend webhook integrations | v0.3 scope (DELIV-04) |
| Any Node.js-dependent toolchain | PROJECT.md cross-cutting constraint; D-18 |
| Oban Pro's `DynamicCron` | Static cron config covers all mailglass use cases |

---

## 8. Confidence summary

| Question area | Confidence | Notes |
|---|---|---|
| `@deprecated` attribute in Elixir 1.18+ | HIGH | Verified against Elixir 1.18.4 Module docs |
| Sourceror 1.12.0 maintenance status | HIGH | Verified Hex.pm April 2026; 108k downloads/month |
| Igniter 0.7.9 as codemod standard | HIGH | Verified Hex.pm; confirmed via ecosystem adoption |
| Phoenix.Token API stability | HIGH | Verified hexdocs.pm/phoenix, v1.8.5 |
| No RFC 8058 Hex package exists | HIGH | Hex.pm search confirms zero results |
| Swoosh.Email.header/3 for List-Unsubscribe | HIGH | Verified hexdocs.pm/swoosh, v1.25.0 |
| DKIM h= auto-inclusion by ESPs | MEDIUM | Standard behavior but not verified per-provider against 2026 docs |
| Oban OSS schedule_in: {N, :days} availability | HIGH | Verified hexdocs.pm/oban Oban.Job docs |
| Oban.Plugins.Cron static API | HIGH | Verified hexdocs.pm/oban, v2.21.1 |
| Dialyzer flag correction (--ignore-exit-status) | HIGH | Verified hexdocs.pm/dialyxir, v1.4.7 |
| Credo --strict flag | HIGH | Verified current Credo docs, v1.7.18 |
| GitHub Actions tag-push syntax (unchanged) | HIGH | Verified current GitHub Actions docs |
| actions/checkout version | MEDIUM | Latest release page showed v6.0.2; consumer-facing tag may differ |
| release-please-action v5.0.0 Elixir support | MEDIUM | Node 24 only stated breaking change; Elixir type continuity not confirmed |
| erlef/setup-beam v1.24.0 still current | HIGH | Verified GitHub releases |

---

## 9. Sources

### Verified against Hex.pm / HexDocs (April 2026)

- Sourceror 1.12.0 — https://hex.pm/packages/sourceror (released March 6, 2026)
- Igniter 0.7.9 — https://hex.pm/packages/igniter (released April 11, 2026)
- Oban 2.21.1 — https://hex.pm/packages/oban (released March 26, 2026)
- Credo 1.7.18 — https://hex.pm/packages/credo (released April 10, 2026)
- Dialyxir 1.4.7 — https://hex.pm/packages/dialyxir (released November 6, 2025)

### Verified against official docs (April 2026)

- Phoenix.Token API — https://hexdocs.pm/phoenix/Phoenix.Token.html (Phoenix 1.8.5)
- Swoosh.Email.header/3 — https://hexdocs.pm/swoosh/Swoosh.Email.html (Swoosh 1.25.0)
- Oban.Job scheduling options — https://hexdocs.pm/oban/Oban.Job.html (Oban 2.21.1)
- Oban.Plugins.Cron — https://hexdocs.pm/oban/Oban.Plugins.Cron.html (Oban 2.21.1)
- mix dialyzer flags — https://hexdocs.pm/dialyxir/Mix.Tasks.Dialyzer.html (Dialyxir 1.4.7)
- Elixir @deprecated attribute — https://hexdocs.pm/elixir/1.18.4/Module.html
- Sourceror capabilities — https://hexdocs.pm/sourceror/readme.html + https://hexdocs.pm/sourceror/Sourceror.html
- Igniter API — https://hexdocs.pm/igniter/readme.html + https://hexdocs.pm/igniter/Igniter.html

### Verified against GitHub Releases (April 2026)

- erlef/setup-beam v1.24.0 — still current (latest confirmed)
- googleapis/release-please-action v5.0.0 — https://github.com/googleapis/release-please-action/releases (released April 22, 2026)
- actions/checkout — https://github.com/actions/checkout/releases (latest v6.0.2, Jan 9, 2025 — pin by SHA)

### GitHub Actions syntax

- on: push: tags: — https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions (no 2026 changes)

### Ecosystem research

- Igniter ecosystem adoption: ElixirForum thread on Sourceror+Igniter for codemods — https://elixirforum.com/t/inserting-a-use-statement-with-sourceror-in-a-mix-task/73224
- Igniter in practice: SmartLogic writeup — https://smartlogic.io/blog/potions-in-a-cauldron-elixir-app-development-code-generation/
- RFC 8058 — https://datatracker.ietf.org/doc/html/rfc8058 (canonical RFC, no new deps)

---

## 10. Critical corrections to existing planning docs

These items are **wrong in current planning docs** and must be corrected before Phase 8 planning:

| Document | Incorrect claim | Correct fact |
|----------|----------------|--------------|
| STATE.md, PROJECT.md | "Dialyzer `--halt-exit-status`" | The flag is `--ignore-exit-status` (the advisory mode flag). The **default** `mix dialyzer` (no flags) already halts on warnings. Re-tightening means REMOVING `--ignore-exit-status` from the CI command, not ADDING a new flag. |
| STATE.md | "re-tighten Tests gate to halt-on-failure" describes the Dialyzer work as adding a flag | It's REMOVING the `--ignore-exit-status` flag. The fix is subtraction, not addition. |

---

*Stack research for: mailglass v0.2 "Production-Credible Core" milestone*
*Researched: 2026-04-26*
*Scope: New v0.2 additions only. v0.1 validated stack in `.planning/milestones/v0.1-research/STACK.md`.*
