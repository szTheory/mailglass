# Stack Research — mailglass

**Domain:** Phoenix-native transactional email framework (3 sibling Hex packages)
**Researched:** 2026-04-21
**Overall confidence:** HIGH (all primary versions verified against Hex.pm in April 2026; ecosystem decisions ground in `prompts/` corpus + 4 prior shipped libs)

> **How to read this doc.** Most technology choices for mailglass are already locked by the upstream research corpus in `prompts/` and `PROJECT.md`. This file's job is to (a) pin **specific 2026 versions** to those decisions, (b) give downstream consumers (roadmap, per-phase planning) a single grep-able table, (c) flag the few places where I'm filling a genuine gap rather than re-citing prior research, and (d) say loudly what NOT to use and why.

---

## TL;DR — the locked stack

| Layer | Pick | Version (Apr 2026) | Confidence |
|---|---|---|---|
| Runtime | Elixir / OTP | 1.18+ / 27+ | HIGH (PROJECT.md D-06) |
| Web framework | Phoenix | `~> 1.8` (1.8.5) | HIGH |
| LiveView | phoenix_live_view | `~> 1.1` (1.1.28) | HIGH |
| ORM | ecto + ecto_sql | `~> 3.13` (3.13.5) | HIGH |
| DB driver | postgrex | `~> 0.22` (0.22.0) | HIGH |
| Plug | plug | `~> 1.18` (1.19.1) | HIGH |
| Mailer transport | swoosh | `~> 1.25` (1.25.0) | HIGH (PROJECT.md D-07) |
| HTML→text + parser | floki | `~> 0.38` (0.38.1) | HIGH |
| CSS inliner | premailex | `~> 0.3` (0.3.20) | MEDIUM (slow-cadence dep) |
| Option validation | nimble_options | `~> 1.1` (1.1.1) | HIGH |
| Telemetry | telemetry | `~> 1.4` (1.4.1) | HIGH |
| i18n (UI strings) | gettext | `~> 1.0` (1.0.2) | HIGH |
| Background jobs (optional) | oban | `~> 2.21` (2.21.1) | HIGH (PROJECT.md D-07) |
| MJML renderer (optional) | **mjml** (NOT `mrml`) | `~> 5.3` (5.3.1) | HIGH — see §3.4 correction |
| Tracing (optional) | opentelemetry | `~> 1.7` (1.7.0) | HIGH |
| SMTP server (optional, v0.5+ inbound) | gen_smtp | `~> 1.3` (1.3.0) | HIGH |
| Auth adapter (optional) | sigra | `~> 0.2` (0.2.0) | HIGH |
| Property tests | stream_data | `~> 1.3` (1.3.0) | HIGH |
| Behaviour mocks | mox | `~> 1.2` (1.2.0) | HIGH |
| Coverage | excoveralls | `~> 0.18` (0.18.5) | MEDIUM |
| Static type analysis | dialyxir | `~> 1.4` (1.4.7) | HIGH |
| Linter | credo | `~> 1.7` (1.7.18) | HIGH |
| Docs | ex_doc | `~> 0.40` (0.40.1) | HIGH |
| CI runtime | erlef/setup-beam | `v1.24.0` | HIGH |
| Release automation | googleapis/release-please-action | `v4.4.1` | HIGH |
| Workflow lint | rhysd/actionlint | `v1.7.12` | HIGH |
| Supply-chain check | actions/dependency-review-action | `v4.9.0` | HIGH |

**One-line summary:** Phoenix 1.8 + LiveView 1.1 + Ecto 3.13 + Postgres + Swoosh 1.25 + the `nimble_*`/`telemetry`/`gettext`/`floki`/`premailex`/`plug` standard library set, with `oban` / `opentelemetry` / `mjml` / `gen_smtp` / `sigra` as optional deps guarded by `Code.ensure_loaded?/1`. Test stack is ExUnit + StreamData + Mox + a stateful in-process Fake adapter (the release gate). CI is GitHub Actions with setup-beam, Release Please, Hex publish from a protected ref.

---

## 1. Mandatory dependencies

These ship in `mix.exs` `deps/0` without `optional: true`. Every host app gets them. CI must pass `mix compile --warnings-as-errors --no-optional-deps` against this exact set.

### 1.1 Core framework (verified Apr 2026)

| Package | Version requirement | Latest released | Last update | Why locked |
|---|---|---|---|---|
| `phoenix` | `~> 1.8` | **1.8.5** | 2026-03-05 | PROJECT.md D-06 (bleeding-edge floor). Phoenix 1.8 brings `scope`s, magic-link auth, daisyUI default, AGENTS.md generation. Hard required for `mailglass_admin` LiveView mounts. |
| `phoenix_live_view` | `~> 1.1` | **1.1.28** | 2026-03-27 | Locked by D-06. 1.1's colocated hooks (`<script :type={Phoenix.LiveView.ColocatedHook}>`) are the right answer for the dev preview dashboard's device-toggle JS — write hooks inline in the same module instead of polluting a global namespace. |
| `ecto_sql` | `~> 3.13` | **3.13.5** | 2026-03-03 | Hard required (D-06). 3.13 ships `@schema_redact` for auto-redacting recipient fields from logs/inspects — directly relevant to the "no PII in logs" telemetry rule (engineering-DNA §2.5). |
| `ecto` | `~> 3.13` | **3.13.x** | (transitive) | Pulled in by `ecto_sql`; pin both for Hex package metadata clarity. |
| `postgrex` | `~> 0.22` | **0.22.0** | 2026-01-10 | PROJECT.md "Postgres only at v0.1." MySQL/SQLite explicitly out — JSONB, partial unique indexes, and `BEFORE UPDATE OR DELETE` triggers (the immutability gate on `mailglass_events`) are load-bearing. |
| `plug` | `~> 1.18` | **1.19.1** | 2025-12-09 | Required by Phoenix; mailglass uses it directly for `Mailglass.Webhook.Plug` and `Mailglass.Webhook.CachingBodyReader`. |
| `swoosh` | `~> 1.25` | **1.25.0** | 2026-04-02 | THE foundation. mailglass composes on top of Swoosh, never replaces it (PROJECT.md "what this is", §1 of "Phoenix needs an email framework"). 1.25 was released 19 days before this research and is current. ~39k monthly downloads, 19M all-time, 15+ adapters. |
| `nimble_options` | `~> 1.1` | **1.1.1** | (last release May 2024 — feature-complete) | Validates `Mailglass.Config` schema at boot via `resolve!/1`. NimbleOptions is the ecosystem-standard option-validation library per `prompts/elixir-opensource-libs-best-practices-deep-research.md` (§2). Stable cadence reflects feature-completeness, not abandonment. |
| `telemetry` | `~> 1.4` | **1.4.1** | 2026-03-09 | The 4-level naming convention (`[:mailglass, :domain, :resource, :action, :start\|:stop\|:exception]`) is locked in engineering-DNA §2.5. Telemetry is non-negotiable infrastructure for every mailglass operation. |
| `gettext` | `~> 1.0` | **1.0.2** | 2025-11-08 | Hard required for "Gettext-first i18n with `dgettext("emails", ...)` convention" (PROJECT.md v0.1 active req). Note: gettext jumped to 1.0 in late 2025 — this is the new stable line. |
| `premailex` | `~> 0.3` | **0.3.20** | 2025-01-20 | Canonical Elixir CSS inliner for the HEEx → inline CSS → minify → plaintext pipeline (PROJECT.md v0.1, "Phoenix needs an email framework" §3 component-native rec). ⚠️ **Slow cadence** (last release ~15 months ago) — but no credible replacement exists. Mark as MEDIUM confidence on long-term maintenance. |
| `floki` | `~> 0.38` | **0.38.1** | 2026-03-17 | Used for the auto-plaintext step (HTML → text via DOM walking) and for HTML test assertions in `Mailglass.TestAssertions`. Note: LiveView 1.1 switched its internal parser from Floki to lazy_html — but Floki remains the right pick for our use case (ad-hoc transformation, not parser hot-path). |

### 1.2 Why these and not alternatives

| Alternative considered | Why we picked the recommended one |
|---|---|
| `bamboo` instead of `swoosh` | Bamboo is in maintenance mode at beam-community. Phoenix 1.7+ generators ship Swoosh as default. Swoosh is the active, growing dep with adapter network effect (15+ providers). PROJECT.md "Out of Scope" explicitly excludes Bamboo backwards-compat. |
| `vix`/`xq`/raw `Regex` instead of `floki` | Floki is the proven, telemetry-friendly default; LiveView 1.1's switch to lazy_html is for hot-path streaming diff use cases, not for one-shot HTML→text where Floki's ergonomics win. |
| `mjml`/`mjml_eex` as the **default** renderer | PROJECT.md D-18 explicitly locks HEEx + Phoenix.Component as default; MJML is opt-in via `Mailglass.TemplateEngine.MJML`. The "killer differentiator is *not needing* MJML" (D-18 rationale + "Phoenix needs an email framework" §3). |
| `mua` directly instead of `swoosh` | Swoosh now integrates `mua` internally for SMTP transport (per "Phoenix needs an email framework" prior-art table). Adopting Swoosh inherits this for free. |
| Hand-rolled HMAC verification per provider in lib code | Yes, per provider — but routed through a single `Mailglass.Webhook.SignatureVerifier` behaviour with per-provider impls. Pattern is from `lattice_stripe/lib/lattice_stripe/webhook/`. |

---

## 2. Optional dependencies (with `optional: true` + `Code.ensure_loaded?/1` guards)

CI must pass `mix compile --no-optional-deps --warnings-as-errors` to prove the lib doesn't accidentally hard-link any of these.

| Package | Version requirement | Latest released | Last update | Rationale | Confidence |
|---|---|---|---|---|---|
| `oban` | `~> 2.21` | **2.21.1** | 2026-03-26 | PROJECT.md D-07: `deliver_later/2` requires Oban; without it, falls back to `Task.Supervisor` with a one-time runtime warning. Oban Web went OSS Jan 2025 (Apache 2.0) — adopters now get a free dashboard, which makes recommending Oban frictionless. We do **not** require Oban Pro for any mailglass v0.x feature. | HIGH |
| `opentelemetry` | `~> 1.7` | **1.7.0** | 2025-10-17 | Engineering-DNA §2.5 requires conditional OTel bridge: `Code.ensure_loaded?(:opentelemetry)` gate, `@compile {:no_warn_undefined, :opentelemetry}` to silence the optional-dep warning. Adopters get distributed tracing across send → adapter → webhook lifecycle without paying the dep cost if they're not using OTel. | HIGH |
| `mjml` | `~> 5.3` | **5.3.1** | 2026-02-13 | **⚠️ CORRECTION** — PROJECT.md/research docs reference an optional `:mrml` dep. The actual Hex package is **`:mjml`** (Adopt-A-Posss / akoutmos's `mjml_nif` repo), which provides Rust NIF bindings to the underlying Rust `mrml` crate. There is no `:mrml` Hex package. Use `{:mjml, "~> 5.3", optional: true}`. Powers `Mailglass.TemplateEngine.MJML` for adopters who want MJML as the rendering pipeline. NIF ships precompiled (Rust toolchain not required by adopters). | HIGH (verified Hex.pm 404 on `mrml`, 200 on `mjml`) |
| `gen_smtp` | `~> 1.3` | **1.3.0** | 2025-05-30 | Powers the `:smtp` Swoosh adapter. We don't list it in `mailglass` v0.1 deps because Swoosh handles the dep. **`mailglass_inbound` v0.5 will require it for the SMTP relay ingress** (PROJECT.md v0.5+ inbound section). Stable, maintained. | HIGH |
| `sigra` | `~> 0.2` | **0.2.0** | 2026-04-20 | Engineering-DNA §3.3: `Mailglass.Auth.Sigra` adapter auto-wires when sigra is loaded. Currently pre-1.0 (single-developer, version 0.2.0 released yesterday). Optional. Don't gate any required behaviour on sigra. | MEDIUM (pre-1.0; bus-factor risk) |

### 2.1 Optional-dep discipline

Engineering-DNA §3.4 + `prompts/elixir-opensource-libs-best-practices-deep-research.md` §6 both prescribe the same shape:

```elixir
# mix.exs
{:oban,           "~> 2.21",  optional: true},
{:opentelemetry,  "~> 1.7",   optional: true},
{:mjml,           "~> 5.3",   optional: true},
{:gen_smtp,       "~> 1.3",   optional: true},
{:sigra,          "~> 0.2",   optional: true},
```

```elixir
# lib/mailglass/outbound/scheduler.ex
@compile {:no_warn_undefined, Oban}

def deliver_later(email, opts) do
  cond do
    Code.ensure_loaded?(Oban) ->
      Mailglass.Outbound.ObanWorker.new(%{email: email}, opts) |> Oban.insert()

    true ->
      Logger.warning(
        "[mailglass] Oban not loaded; falling back to Task.Supervisor. " <>
          "Add `{:oban, \"~> 2.21\"}` for production-grade scheduling."
      )

      Task.Supervisor.start_child(Mailglass.TaskSupervisor, fn ->
        Mailglass.Outbound.send(email, opts)
      end)
  end
end
```

Same shape for `:opentelemetry` (telemetry → OTel span bridge), `:mjml` (TemplateEngine.MJML resolved at boot if loaded), `:gen_smtp` (only relevant inside `mailglass_inbound`'s SMTP ingress).

---

## 3. Test stack

| Package | Version | Why | Confidence |
|---|---|---|---|
| `ex_unit` | stdlib (built-in) | Async-by-default, sandbox-aware. Foundation. | HIGH |
| `stream_data` | `~> 1.3` (1.3.0) | Property-based testing. PROJECT.md v0.1 explicitly requires StreamData property tests for headers, idempotency keys, signature verification. **Note:** this is a divergence from engineering-DNA §2.6 ("Property tests are absent unless the domain is genuinely algorithmic") — but headers/HMAC/idempotency-keys *are* genuinely algorithmic, so the carve-out is principled. | HIGH |
| `mox` | `~> 1.2` (1.2.0) | Behaviour-backed concurrent-safe mocking. The pattern: every public behaviour mailglass exposes (`Mailglass.Adapter`, `Mailglass.TemplateEngine`, `Mailglass.SuppressionStore`, etc.) gets a `Mox.defmock(...)` in `test_helper.exs`. Engineering-DNA §2.6 + 4-of-4 convergence. | HIGH |
| `excoveralls` | `~> 0.18` (0.18.5) | Coverage reporting. Used as a **signal not a gate** per `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` §"Coverage" — track it, don't fail PRs on a vanity percentage. | MEDIUM (Jan 2025 was last release; functional but quiet) |
| `dialyxir` | `~> 1.4` (1.4.7) | Engineering-DNA §3.9 (3-of-4 majority used Dialyzer with split PLT cache). Note: the broader 2026 trend is "drop Dialyxir, let the set-theoretic type system catch what Dialyzer used to catch" (per `prompts/The 2026 Phoenix-Elixir ecosystem map` §15) — but mailglass should **keep Dialyzer through v0.x** because (a) bleeding-edge users are exactly who hit Dialyzer-detected typing edge cases first, (b) the prior libs all kept it. Reassess at v1.0. | HIGH |
| `credo` | `~> 1.7` (1.7.18) | `mix credo --strict` is in the lint lane. Plus custom Credo checks loaded via `.credo.exs` `requires:`: `NoRawSwooshSendInLib`, `NoUnscopedTenantQueryInLib`, `RequiredListUnsubscribeHeaders`, `NoPiiInTelemetryMeta` (PROJECT.md D-17). | HIGH |

### 3.1 Why **NOT** ExMachina (engineering DNA confirmation)

PROJECT.md v0.1 active reqs say "ExMachina (DON'T use per engineering DNA — confirm rationale)." Here's the confirmation:

**Engineering-DNA §2.6:** *"Fixture modules return plain maps (no factory framework — `ExMachina` is intentionally not used). Composition at call site via `Map.merge/2`."*

**The "why":** ExMachina solved a real problem in 2014 (no good Elixir test data builders) but the cost in 2026 is real:
1. **Compile-time coupling** between test/support/factories.ex and every schema in your domain. Schema changes ripple into factory recompiles.
2. **Magic via `use ExMachina.Ecto`**. `prompts/elixir-opensource-libs-best-practices-deep-research.md` §6 ("Be conservative with `use`, macros, and DSLs") is explicit: don't expose `use` if functions suffice.
3. **Duplication of intent.** A test that says `insert(:user, email: "alice@x.com")` is one indirection away from `%User{email: "alice@x.com"} |> Repo.insert!()` — the second reads as fast and breaks more loudly when the schema drifts.
4. **The set-theoretic type system catches struct-field mistakes** at compile time in Elixir 1.18+, removing one of ExMachina's main wins.

Pattern instead (from accrue/sigra/scrypath/lattice_stripe — 4-of-4 convergence):

```elixir
# test/support/fixtures/email.ex
defmodule Mailglass.Fixtures.Email do
  def attrs(overrides \\ %{}) do
    Map.merge(
      %{
        from: {"Test", "noreply@test.example"},
        to: "alice@test.example",
        subject: "hi",
        html_body: "<p>hi</p>",
        text_body: "hi"
      },
      Map.new(overrides)
    )
  end

  def email(overrides \\ %{}), do: attrs(overrides) |> Mailglass.Email.new!()
end
```

5. **ExMachina is now at beam-community with low velocity.** Per `prompts/The 2026 Phoenix-Elixir ecosystem map` §14: "Some teams now prefer plain factory functions in `test/support` since the type system catches struct-field mistakes."

### 3.2 The Fake adapter — the actual release gate

Per PROJECT.md D-13 + engineering-DNA §3.5, the test stack's most important component is **not in `deps/0` at all** — it's `Mailglass.Adapter.Fake`, an in-memory deterministic stateful adapter shipped in `lib/mailglass/adapter/fake.ex`. This is the merge-blocking test target. Real-provider sandbox tests (Postmark/SendGrid test mode, MailHog SMTP) run on daily cron + `workflow_dispatch` and are explicitly **advisory only** (per accrue's lesson: *"Keep provider-backed checks advisory while Fake-backed host proof remains deterministic release blocker."*)

This is a discipline pattern, not a dep — but it belongs in this STACK doc because it changes how every other test stack choice fits. The Fake is the line.

---

## 4. CI tooling (GitHub Actions)

Verified versions as of April 2026. Per `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` and engineering-DNA §2.2, all third-party actions should be **pinned to a full SHA** in the actual workflow YAML; the version tags below are for CHANGELOG/upgrade tracking.

| Action | Version | Purpose | Notes |
|---|---|---|---|
| `erlef/setup-beam` | **v1.24.0** (2026-03-30) | Install Elixir/OTP at exact versions on Ubuntu runner | Use `version-type: strict` per the action's own rec; pin Elixir/OTP via `.tool-versions` for parity with local dev. v1.24.0 adds Node 24 runtime + TOML dotted-key fixes. |
| `actions/checkout` | `v4` | Repo checkout | Standard, batteries-included. Use `fetch-depth: 0` only for jobs that need full history (Release Please does). |
| `actions/cache` | `v4` | Cache `deps/`, `_build/`, dialyzer PLT, Hex registry | Engineering-DNA §2.2: split PLT cache into restore → build-on-miss → save lanes. Cache key includes `mix.lock` hash + Elixir version + OTP version. |
| `googleapis/release-please-action` | **v4.4.1** (2026-04-13) | Auto-bump version + CHANGELOG on `main` | Use `release-type: elixir`. Manifest mode (`release-please-manifest.json` + `release-please-config.json`) is recommended even for single packages — future-proofs for `mailglass_admin` sibling release with `separate-pull-requests: false` + linked-versions plugin. **PAT required** (not `GITHUB_TOKEN`) so downstream CI runs on Release Please's PRs. |
| `actions/dependency-review-action` | **v4.9.0** (2026-03-03) | Block PRs that introduce vulnerable deps | Runs only on `pull_request`. v4.9.0 adds `show_patched_versions` config — surface the fix version for any flagged dep. |
| `rhysd/actionlint` | **v1.7.12** (2026-03-30) | Lint workflow YAML for syntax + expression mistakes + shell issues | Wire in a dedicated `actionlint.yml` workflow, only triggered on `paths: .github/workflows/**`. v1.7.12 added IANA timezone validation. |
| `dependabot` | (built-in) | Auto-PR for action SHA bumps + Mix dep bumps | Two ecosystems in `dependabot.yml`: `github-actions` (weekly) and `mix` (weekly). Pair with SHA pinning so updates are explicit. |

### 4.1 Lane structure (per engineering-DNA §2.2)

| Lane | Mix command(s) | Blocks merge? |
|---|---|---|
| **Lint** | `mix format --check-formatted`, `mix compile --warnings-as-errors --no-optional-deps`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix docs --warnings-as-errors`, `mix hex.audit` | yes |
| **Test matrix** | `MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors` across {Elixir 1.18, OTP 27} (single cell at v0.1; widen if community signal warrants) | yes |
| **Dialyzer** | `mix dialyzer --halt-exit-status`, with split PLT cache | yes |
| **Golden install** | `mix mailglass.install` against fresh Phoenix host in `test/example/`, snapshot-diff via `git diff --exit-code test/fixtures/install/` | yes for paths touching the installer |
| **Admin smoke** | `mailglass_admin` Playwright/PhoenixTest against `test/example/` | yes for paths touching `mailglass_admin` |
| **Static + supply chain** | `dependency-review-action`, `actionlint` | yes |
| **Release Please** | Run on push to `main`; opens or updates a release PR | n/a (PR only) |
| **Publish-Hex** | `mix hex.publish --yes` triggered by tag from release-please merge | release-time only |
| **Post-publish verify** | Daily cron + `workflow_dispatch`: poll Hex tarball visibility, compile a throwaway consumer app, verify HexDocs reachability | not on the publishing PR |

### 4.2 Required workflow files (verified against engineering DNA + CI/CD research)

```
.github/
├── workflows/
│   ├── ci.yml                       # lint + matrix test + dialyzer + golden install + admin smoke
│   ├── dependency-review.yml        # actions/dependency-review-action on PRs
│   ├── actionlint.yml               # rhysd/actionlint on workflow file changes only
│   ├── release-please.yml           # googleapis/release-please-action on push to main
│   ├── publish-hex.yml              # workflow_dispatch fallback + publish on Release Please tag
│   └── verify-published-release.yml # daily cron + manual: poll Hex + test a fresh consumer app
└── dependabot.yml                   # github-actions weekly + mix weekly
```

`MAINTAINING.md` (per accrue/sigra precedent) documents secret setup: `HEX_API_KEY` + `RELEASE_PLEASE_TOKEN` (PAT, not `GITHUB_TOKEN`).

---

## 5. Documentation stack

| Tool | Version | Purpose | Notes |
|---|---|---|---|
| `ex_doc` | `~> 0.40` (0.40.1, 2026-01-31) | Generate HexDocs, llms.txt, EPUB, Markdown | **Confirmed 2026 capabilities:** ExDoc 0.40.x ships **automatic `llms.txt` generation** out of the box. HexDocs pages now expose a "View llms.txt" link in the footer. This is the LLM-context-friendly representation requested in the milestone context. Configure with: |

```elixir
# mix.exs
def project do
  [
    # ...
    name: "mailglass",
    source_url: @source_url,
    homepage_url: @source_url,
    docs: [
      main: "getting-started",     # PROJECT.md req — guides land first, not README
      source_ref: "v#{@version}",  # ties HexDocs source links to the published tag
      source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}",
      logo: "guides/assets/mailglass-logo.svg",
      extras: [
        "guides/getting-started.md",
        "guides/golden-path.md",
        "guides/installation.md",
        "guides/sending-transactional.md",
        "guides/templating-with-heex.md",
        "guides/templating-with-mjml.md",
        "guides/preview-dashboard.md",
        "guides/webhooks-postmark.md",
        "guides/webhooks-sendgrid.md",
        "guides/inbound-routing.md",
        "guides/deliverability-and-compliance.md",
        "guides/multi-tenancy.md",
        "guides/auth-adapters.md",
        "guides/testing.md",
        "guides/telemetry.md",
        "guides/admin-dashboard.md",
        "guides/migration-from-swoosh.md",
        "guides/api_stability.md"
      ],
      groups_for_extras: [
        "Getting Started": ~r/getting-started|golden-path|installation/,
        "Authoring": ~r/templating|preview/,
        "Operations": ~r/webhooks|telemetry|deliverability|admin/,
        "Reference": ~r/multi-tenancy|auth-adapters|api_stability|migration/,
        "Testing": ~r/testing/
      ],
      groups_for_modules: [
        "Public API": [Mailglass, Mailglass.Mailable, Mailglass.Email, Mailglass.TestAssertions],
        "Errors": ~r/Mailglass\.\w+Error/,
        "Behaviours": [Mailglass.Adapter, Mailglass.TemplateEngine, Mailglass.PreviewStore, Mailglass.SuppressionStore, Mailglass.Webhook.Handler, Mailglass.Inbound.Mailbox, Mailglass.Auth],
        "Components": ~r/Mailglass\.Components/,
        "Internals": ~r/.*/
      ]
    ]
  ]
end
```

| Tool | Version | Purpose | Notes |
|---|---|---|---|
| `makeup_elixir` | (transitive via ex_doc) | Syntax highlighting | Default. |
| `makeup_html` | (transitive via ex_doc) | Highlight `~H` HEEx blocks | Required to make email-component examples readable in docs. |
| `makeup_diff` | optional | Highlight CHANGELOG.md diff blocks | Nice-to-have. |
| **doc-contract tests** | (no dep — pure ExUnit) | Lock README + guide snippets to actual code | Engineering-DNA §2.7: highest-leverage convergent pattern across all 4 prior libs. Failing CI on doc rot prevents the silent drift that killed adoption in other ecosystems. |

### 5.1 The `mix docs --warnings-as-errors` gate

Per `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`: "Your SDK's docs are part of the product. Broken docs, broken links, or missing docs should fail CI." Wire this into the lint lane. ExDoc supports `--warnings-as-errors`.

---

## 6. What NOT to use (and why)

This list is concrete, grounded in PROJECT.md's locked decisions, the `prompts/` corpus, and the engineering-DNA file. Each "don't" has a citable reason.

| Avoid | Specific problem | Use instead | Source |
|---|---|---|---|
| **`bamboo`** | In maintenance mode at beam-community, Phoenix 1.7+ generators ship Swoosh as default. Migration from Bamboo is **explicitly out of scope** for mailglass migration guides. | `swoosh ~> 1.25` | PROJECT.md "Out of Scope" |
| **`mjml` / `mjml_eex` as default renderer** | "The killer differentiator is *not needing* MJML." HEEx + Phoenix.Component with MSO VML fallbacks composes cleanly with the rest of Phoenix; MJML's HEEx parser interop has been fragile across Phoenix upgrades (ElixirForum 69206, 73978). MJML stays as opt-in `Mailglass.TemplateEngine.MJML`. | HEEx + `Mailglass.Components` | PROJECT.md D-18, "Phoenix needs an email framework" §3 |
| **`ex_machina` (ExMachina)** | Compile-time coupling, magical `use ExMachina.Ecto`, low velocity at beam-community, set-theoretic type system supersedes its core value. | Plain map fixtures with `Map.merge/2` composition | Engineering-DNA §2.6 (4-of-4 convergence) |
| **`Application.compile_env!/3` for runtime config** | Bakes config into the release artifact; surprises adopters who change config in `runtime.exs` and don't see it take effect. The class of release-build configuration bugs that accrue paid for and learned from. | `Application.get_env/2` + `Mailglass.Config.resolve!/1` validated at boot via NimbleOptions | Engineering-DNA §6.1 (gotcha #1) |
| **`mailibex` (raw GitHub dep)** | Currently the only Elixir DKIM lib but not on Hex, not integrated with Swoosh. Vendoring or upstream-forking it is a v0.5 deliverability concern (`Mailglass.Compliance.dkim_sign/2`), not a v0.1 dep. Don't add as direct dep at v0.1. | At v0.5: vendor or fork mailibex into `lib/mailglass/compliance/dkim/`; do NOT add as upstream Hex dep | "Phoenix needs an email framework" §1, engineering-DNA §4.7 |
| **AMP for Email** | Cloudflare deprecated AMP support starting October 20, 2025 (sunset-style removal); ESPC data showed <5% sender adoption even before that. Maintenance budget would be wasted. | Plain HTML email with HEEx components + MSO fallbacks | PROJECT.md "Out of Scope", verified Apr 2026 |
| **MJML compile-step Node toolchain** | One of mailglass's brand promises is "no Node/JS toolchain ever required" (PROJECT.md cross-cutting reqs). The `mjml` Hex package solves this via Rust NIF that ships precompiled — no Node needed. | `mjml ~> 5.3` (the Rust-NIF Hex package), opt-in only | PROJECT.md cross-cutting reqs |
| **Raw `GenServer` scattering across the lib** | "Process anti-pattern docs specifically warn against scattered process interfaces: don't spread direct `GenServer.call/3` throughout the codebase. Centralize access behind one module." mailglass's only first-party long-running process is `Mailglass.TaskSupervisor` (for the Oban-fallback path); everything else is pure functions. | One module facade per process; pure functions for everything else | `prompts/elixir-opensource-libs-best-practices-deep-research.md` §3 |
| **`use Mailglass` macro on adopter modules** | "Don't expose `use MyLib` if `import` or normal calls are enough." Adopters get `use Mailglass.Mailable` (which IS a real behaviour binding + child_spec injection) but do NOT get a `use Mailglass` umbrella. | `Mailglass.deliver/2` direct calls; `use Mailglass.Mailable` only when defining a Mailable module | `prompts/elixir-opensource-libs-best-practices-deep-research.md` §6 |
| **HTTPoison / Hackney** | Out of step with 2026 conventions; questionable SSL defaults; no telemetry integration. Swoosh's adapters use Finch/Req under the hood — we inherit the modern HTTP stack for free by composing on Swoosh. Don't add HTTPoison as a direct dep. | (none — let Swoosh handle HTTP via Finch internally) | `prompts/The 2026 Phoenix-Elixir ecosystem map` §4 |
| **`Tesla`** | Mindshare gone in 2026; Req is the new ecosystem default. We don't need it because we don't make HTTP calls directly — Swoosh adapters do. | (none) | `prompts/The 2026 Phoenix-Elixir ecosystem map` §4 |
| **Custom open/click tracking ON by default** | Apple Mail Privacy Protection (~50% consumer mail) makes opens noisy; signed click rewriting is a legal liability if misconfigured; auth-carrying messages (password reset, magic link) must NEVER have rewritten links. | Tracking **off by default**; explicit per-mailable opt-in | PROJECT.md D-08 |
| **Pre-Phoenix-1.8 / pre-LiveView-1.0 support matrix** | "Bleeding edge floor … trades a slice of the long-tail user base for newest features." Conservative LTS support is **explicitly not a goal**. | Phoenix 1.8+, LiveView 1.1+, Elixir 1.18+, OTP 27+ as the floor | PROJECT.md D-06 |
| **MySQL or SQLite at v0.1** | Postgres-only because advisory locks, JSONB, partial unique indexes, and the `BEFORE UPDATE OR DELETE` trigger on `mailglass_events` are load-bearing. | Postgres via Postgrex 0.22 | PROJECT.md "Constraints" |
| **`Surface`** | LiveView's `Phoenix.Component` + `attr`/`slot` absorbed Surface's core ideas. Don't start new projects on it. | `Phoenix.Component` from LiveView 1.1 | `prompts/The 2026 Phoenix-Elixir ecosystem map` §16 |
| **Open core / paid Pro tier** | MIT pure OSS across all sibling packages. No `mailglass_pro`. | (n/a) | PROJECT.md "Out of Scope" + D-02 |

---

## 7. Email-specific 2026 considerations (the load-bearing context)

These are not stack picks per se — but they directly drive which features land in v0.1 vs v0.5 and how the libs are configured. Each is a **load-bearing reality** the roadmap must respect.

### 7.1 The 2024 Gmail/Yahoo bulk-sender rules — now Gmail+Yahoo+Microsoft (Yahooglesoft)

**Status (verified Apr 2026):**
- Gmail/Yahoo enforced from Feb 2024 onward.
- Gmail escalated to **permanent 550-class rejections** in November 2025.
- Microsoft (Outlook/Hotmail/Live) joined the requirements **May 2025** — now informally called "Yahooglesoft."
- Microsoft is "softer" — they require functional unsubscribe links but don't strictly mandate RFC 8058. Gmail and Yahoo strictly require both `List-Unsubscribe` and `List-Unsubscribe-Post`.

**For senders >5,000 msgs/day to consumer inboxes, mandatory:**
- SPF + DKIM + DMARC with alignment (≥ `p=none`)
- PTR record
- TLS
- RFC 5322 compliance (Message-ID, Date, MIME-Version, UTF-8 headers)
- One-click unsubscribe per RFC 8058: BOTH `List-Unsubscribe: <https://...>, <mailto:...>` AND `List-Unsubscribe-Post: List-Unsubscribe=One-Click` headers, signed into DKIM's `h=` tag
- Honor unsubscribes within **48 hours**
- Spam rate <0.30%

**Implication for stack:**
- v0.1 ships nothing for List-Unsubscribe (per PROJECT.md scope) — but the **adapter behaviour and event ledger schema must accommodate it** so v0.5's `Mailglass.Compliance.add_unsubscribe_headers/1` slots in cleanly.
- v0.5 is the deliverability release that satisfies these rules end-to-end (signed-token unsubscribe controller, suppression auto-add on hard-bounce/complaint/unsubscribe, message-stream separation).
- v0.1 should already write `Auto-Submitted: auto-generated` + `Precedence:` headers on transactional sends (cheap; one util function in `Mailglass.Compliance`).

**Confidence:** HIGH (verified across 5 industry sources Apr 2026).

### 7.2 RFC 8058 List-Unsubscribe-Post specifics

- Endpoint must be **HTTPS**.
- Endpoint must be **idempotent** — repeated POSTs are no-ops (return 200, don't re-process).
- Endpoint must return **200 without redirect** (no 302/303 to a confirmation page; that breaks Gmail's one-click expectation).
- The `List-Unsubscribe` URL must encode an **opaque signed token**, never the raw email address. Use `Phoenix.Token` or `Plug.Crypto.MessageVerifier` with key rotation support.
- Both URI (`<https://...>`) and `mailto:` are required for maximum compatibility — Gmail prefers HTTPS, some Yahoo accounts still use mailto.

**Implication for stack:** No new dep required (`Phoenix.Token` + `Plug.Crypto` are stdlib-equivalent). v0.5 generates the signed-token unsubscribe controller from `mix mailglass.install`.

### 7.3 BIMI (Brand Indicators for Message Identification)

- Requires DMARC `p=quarantine` or `p=reject` with `pct=100`.
- Requires a VMC (Verified Mark Certificate) from a CA — this is real money (~$1500/year from Entrust/DigiCert as of 2026).
- Requires SVG logo at a published URL.

**Implication for stack:** v0.5+ `mix mail.doctor` should detect BIMI eligibility (DMARC level + DKIM/SPF alignment) and report. **No first-party BIMI generation in v0.1.** `Mailglass.Compliance.bimi_record_for/1` is a v2 nice-to-have (PROJECT.md v2 differentiation list).

### 7.4 DMARC alignment

- `aspf=s` (strict) or `aspf=r` (relaxed) — relaxed is the default and works for most setups.
- `adkim=s` or `adkim=r` — relaxed default.
- The "From" header domain must align with at least one of {SPF-validated MAIL FROM domain, DKIM signature `d=` domain} for DMARC to pass.

**Implication for stack:** v0.5 `mix mail.doctor` should query DNS for the sending domain and report alignment status. This is just DNS lookup logic — no new dep beyond what stdlib `:inet_res` provides.

### 7.5 Apple Mail Privacy Protection (MPP) impact on opens

- Launched iOS 15 (2021); now ~50% of consumer mail.
- Apple's proxy fetches **all** images on delivery before the user sees the email — open pixels fire whether or not the user opens.
- Open rate is essentially useless as an engagement signal for ~half of consumer traffic. Treat as aggregate trend only.

**Implication for stack:** PROJECT.md D-08 ("Open/click tracking off by default") is in part a response to this. The admin LiveView (v0.5) must surface opens as "≥X opens recorded (Apple MPP inflates this)" — explicit caveat in the UI.

### 7.6 AMP for Email is dead

- Cloudflare announced AMP and Signed Exchanges deprecation **August 2025**, sunset **October 20, 2025** (per Cloudflare Community thread).
- Already <5% of senders used AMP for Email per ESPC data even before deprecation.

**Implication for stack:** PROJECT.md "Out of Scope" already excludes AMP for Email. **Do not add an MJML-AMP-Email path or an AMP component renderer ever.** Maintenance budget would burn for <5% upside that's now declining.

### 7.7 What's NOT in 2026's compliance churn but still load-bearing

- **CAN-SPAM** (US): physical address required for marketing/bulk stream. v0.5 auto-injects on `:bulk` stream sends.
- **CASL** (Canada): explicit consent + identification + unsubscribe. Suppression list satisfies the unsubscribe leg.
- **GDPR/ePrivacy** (EU): consent records; right-to-erasure for `mailglass_subscribers`; signed unsubscribe tokens minimize PII in URLs. Suppression auto-add on `:unsubscribed` event satisfies the 48h honor requirement.

---

## 8. Installation (the v0.1 mix.exs deps block)

```elixir
defp deps do
  [
    # === Core (required) ===
    {:phoenix,           "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html,      "~> 4.1"},        # transitive via phoenix; pin for clarity
    {:ecto,              "~> 3.13"},
    {:ecto_sql,          "~> 3.13"},
    {:postgrex,          "~> 0.22"},
    {:plug,              "~> 1.18"},
    {:swoosh,            "~> 1.25"},
    {:nimble_options,    "~> 1.1"},
    {:telemetry,         "~> 1.4"},
    {:gettext,           "~> 1.0"},
    {:premailex,         "~> 0.3"},
    {:floki,             "~> 0.38"},

    # === Optional (Code.ensure_loaded?/1 guards in lib code) ===
    {:oban,              "~> 2.21",  optional: true},
    {:opentelemetry,     "~> 1.7",   optional: true},
    {:mjml,              "~> 5.3",   optional: true},   # Rust NIF; ships precompiled
    {:gen_smtp,          "~> 1.3",   optional: true},   # for mailglass_inbound v0.5 SMTP relay
    {:sigra,             "~> 0.2",   optional: true},   # auth adapter auto-wires when loaded

    # === Test only ===
    {:stream_data,       "~> 1.3",   only: [:test]},
    {:mox,               "~> 1.2",   only: [:test]},
    {:excoveralls,       "~> 0.18",  only: [:test]},

    # === Dev/test ===
    {:credo,             "~> 1.7",   only: [:dev, :test], runtime: false},
    {:dialyxir,          "~> 1.4",   only: [:dev, :test], runtime: false},
    {:ex_doc,            "~> 0.40",  only: :dev, runtime: false}
  ]
end
```

**Hex package whitelist** (per engineering-DNA §2.1, never auto-include the whole repo):

```elixir
defp package do
  [
    name: "mailglass",
    description: "Phoenix-native transactional email framework — preview, normalize, audit.",
    licenses: ["MIT"],
    files: ~w(lib priv guides .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
    links: %{
      "GitHub"     => "https://github.com/jonathanjoubert/mailglass",
      "HexDocs"    => "https://hexdocs.pm/mailglass",
      "Changelog"  => "https://github.com/jonathanjoubert/mailglass/blob/main/CHANGELOG.md"
    },
    maintainers: ["Jonathan Joubert"]
  ]
end
```

Note the `files:` whitelist excludes `test/`, `test/example/`, `.planning/`, and any `*_ops/` subprojects — preventing the ~200MB-tarball failure mode (engineering-DNA §6 gotcha #8).

---

## 9. Version compatibility matrix

| Package | Compatible with | Notes |
|---|---|---|
| `phoenix ~> 1.8` | `phoenix_live_view ~> 1.1`, `phoenix_html ~> 4.1`, `plug ~> 1.18` | Phoenix 1.8 dropped support for OTP <25. |
| `ecto_sql ~> 3.13` | `postgrex ~> 0.22`, `ecto ~> 3.13` | 3.13 brings `@schema_redact`. |
| `swoosh ~> 1.25` | `phoenix ~> 1.8` (loosely; works with 1.7+), `phoenix_swoosh ~> 1.2` (we won't use phoenix_swoosh — see §6) | Swoosh ships its own templating bridge that we replace with `Mailglass.Template`. |
| `phoenix_live_view ~> 1.1` | `phoenix ~> 1.7` (1.1 supports 1.7+), but mailglass requires 1.8+ for `scope` macros | Locked floor by D-06. |
| `oban ~> 2.21` | Postgres ≥14 | Oban dropped <14 support; aligns with our Postgres floor. |
| `mjml ~> 5.3` | Rust toolchain at build time **NOT required** (precompiled NIF), but adopter's CI/build environment must support the precompiled NIF for their platform (linux/macos/windows on x86_64 + arm64 supported). | Adopters in Alpine containers may need to set `MJML_BUILD=true` and have Rust available. Document this caveat in the MJML guide. |
| `dialyxir ~> 1.4` | Elixir 1.14+, OTP 25+ | PLT churn cost: cache restore → build-on-miss → save (engineering-DNA §2.2). |
| `ex_doc ~> 0.40` | Elixir 1.13+ | 0.40 brings llms.txt generation; required for "AI-friendly docs" milestone goal. |

---

## 10. Stack patterns by variant

### 10.1 If adopter uses Oban already (the common case)

- `deliver_later/2` enqueues a `Mailglass.Outbound.ObanWorker` with idempotency-keyed args (provider_message_id is the dedupe key once known).
- Per-domain rate limiting (v0.5) is implemented as a `Mailglass.Outbound.RateLimitedQueue` with Oban's `:meta` field carrying the recipient domain.
- Use Oban's free `Oban.Web` for queue observability; don't reimplement.

### 10.2 If adopter does NOT use Oban

- `deliver_later/2` falls back to `Task.Supervisor.start_child` with a one-time runtime warning (logged, not raised).
- Rate limiting at v0.5 falls back to ETS-token-bucket (Hammer 7.x is candidate, but adding it as a dep is a v0.5 decision, not v0.1).
- Document that production sending without Oban is **strongly discouraged** in the deliverability guide.

### 10.3 If adopter uses sigra for auth

- `Mailglass.Auth.Sigra` adapter is auto-wired (per `Code.ensure_loaded?(Sigra)`).
- Admin LiveView pulls actor + tenant from `%Sigra.Scope{}` automatically.
- Step-up verification (sigra pattern) wraps destructive admin actions: bulk unsuppress, replay webhook, force-resend campaign.

### 10.4 If adopter uses `phx.gen.auth` (the other common case)

- `Mailglass.Auth.PhxGenAuth` adapter ships built-in — assumes generated `current_user` + `current_scope` plug pattern.
- No tenant scoping unless adopter opts in by implementing `Mailglass.Tenancy.scope/2` directly.

### 10.5 If adopter uses Ash Framework

- Out of scope for first-party support at v0.1. Document as a v0.x community-adapter opportunity. `Mailglass.Auth` behaviour is the seam.

---

## 11. Sources

### Verified against Hex.pm in April 2026

All entries below were checked against the package's Hex.pm page on **2026-04-21**.

- Phoenix 1.8.5 — https://hex.pm/packages/phoenix (released 2026-03-05) — HIGH
- phoenix_live_view 1.1.28 — https://hex.pm/packages/phoenix_live_view (released 2026-03-27) — HIGH
- ecto_sql 3.13.5 — https://hex.pm/packages/ecto_sql (released 2026-03-03) — HIGH
- postgrex 0.22.0 — https://hex.pm/packages/postgrex (released 2026-01-10) — HIGH
- plug 1.19.1 — https://hex.pm/packages/plug (released 2025-12-09) — HIGH
- swoosh 1.25.0 — https://hex.pm/packages/swoosh (released 2026-04-02) — HIGH
- nimble_options 1.1.1 — https://hex.pm/packages/nimble_options (last release May 2024; feature-complete) — HIGH
- telemetry 1.4.1 — https://hex.pm/packages/telemetry (released 2026-03-09) — HIGH
- gettext 1.0.2 — https://hex.pm/packages/gettext (released 2025-11-08) — HIGH
- floki 0.38.1 — https://hex.pm/packages/floki (released 2026-03-17) — HIGH
- premailex 0.3.20 — https://hex.pm/packages/premailex (released 2025-01-20) — MEDIUM (slow cadence)
- oban 2.21.1 — https://hex.pm/packages/oban (released 2026-03-26) — HIGH
- opentelemetry 1.7.0 — https://hex.pm/packages/opentelemetry (released 2025-10-17) — HIGH
- mjml 5.3.1 — https://hex.pm/packages/mjml (released 2026-02-13) — HIGH (verified `:mrml` is NOT a Hex package)
- gen_smtp 1.3.0 — https://hex.pm/packages/gen_smtp (released 2025-05-30) — HIGH
- sigra 0.2.0 — https://hex.pm/packages/sigra (released 2026-04-20) — MEDIUM (pre-1.0, single-dev)
- stream_data 1.3.0 — https://hex.pm/packages/stream_data (released 2026-03-09) — HIGH
- mox 1.2.0 — https://hex.pm/packages/mox (released 2024-08-14; stable) — HIGH
- excoveralls 0.18.5 — https://hex.pm/packages/excoveralls (released 2025-01-26) — MEDIUM
- dialyxir 1.4.7 — https://hex.pm/packages/dialyxir (released 2025-11-06) — HIGH
- credo 1.7.18 — https://hex.pm/packages/credo (released 2026-04-10) — HIGH
- ex_doc 0.40.1 — https://hex.pm/packages/ex_doc (released 2026-01-31; llms.txt confirmed) — HIGH

### CI tooling — verified against GitHub Releases in April 2026

- erlef/setup-beam v1.24.0 — https://github.com/erlef/setup-beam/releases (released 2026-03-30) — HIGH
- googleapis/release-please-action v4.4.1 — https://github.com/googleapis/release-please-action/releases (released 2026-04-13) — HIGH
- actions/dependency-review-action v4.9.0 — https://github.com/actions/dependency-review-action/releases (released 2026-03-03) — HIGH
- rhysd/actionlint v1.7.12 — https://github.com/rhysd/actionlint/releases (released 2026-03-30) — HIGH

### Compliance + ecosystem reality

- Cloudflare AMP & Signed Exchanges deprecation (Oct 20, 2025 sunset) — https://community.cloudflare.com/t/amp-and-signed-exchanges-deprecation-october-20th/831238 — HIGH (verified Apr 2026)
- 2026 Bulk email sender requirements — Red Sift guide — https://redsift.com/guides/bulk-email-sender-requirements — HIGH
- Gmail & Yahoo 2026 guide — Mailmodo — https://www.mailmodo.com/guides/email-sender-guidelines/ — HIGH
- Google sender requirements FAQ — https://support.google.com/a/answer/14229414 — HIGH
- RFC 8058 (one-click unsubscribe) — https://datatracker.ietf.org/doc/html/rfc8058 — HIGH (canonical RFC)

### Internal source-of-truth (cited extensively above)

- `/Users/jon/projects/mailglass/.planning/PROJECT.md` (Decisions D-01 through D-20, esp. D-06, D-07, D-08, D-13, D-17, D-18)
- `/Users/jon/projects/mailglass/prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` (§§1-2, 4, 11, 14, 15, 22, 26, 29 — full ecosystem map)
- `/Users/jon/projects/mailglass/prompts/Phoenix needs an email framework not another mailer.md` (§§1, 3, 4, 6 — founding thesis with Anymail taxonomy + RFC 8058 + Swoosh adapter analysis)
- `/Users/jon/projects/mailglass/prompts/mailglass-engineering-dna-from-prior-libs.md` (§§2.1-2.10, 3.4, 3.5, 3.9, 6 — convergent DNA + optional-dep discipline + Fake-as-release-gate + gotchas)
- `/Users/jon/projects/mailglass/prompts/elixir-best-practices-deep-research.md` (§§1-4 — API design, error handling, naming)
- `/Users/jon/projects/mailglass/prompts/elixir-opensource-libs-best-practices-deep-research.md` (§§1-3, 6, 7 — explicit API, runtime config, behaviours)
- `/Users/jon/projects/mailglass/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` (full document — release model, lane structure, ExDoc llms.txt, Release Please PAT vs GITHUB_TOKEN, Hex publishing)

---

## 12. Confidence summary

| Decision area | Confidence | Reason |
|---|---|---|
| Required core deps + versions | **HIGH** | All verified live on Hex.pm Apr 2026; aligned with PROJECT.md D-06 floor. |
| Optional deps (Oban, OTel, mjml, gen_smtp, sigra) | **HIGH** | Verified versions; rationale grounded in PROJECT.md decisions + engineering-DNA §3.4. One correction: `:mrml` is `:mjml` on Hex. |
| Test stack (StreamData/Mox/Fake adapter) | **HIGH** | Per PROJECT.md v0.1 reqs + engineering-DNA §3.5. ExMachina exclusion confirmed with concrete reasoning. |
| CI tooling | **HIGH** | All action versions verified Apr 2026; lane structure matches engineering-DNA §2.2 (4-of-4 convergence). |
| ExDoc + llms.txt | **HIGH** | Confirmed ExDoc 0.40.x ships llms.txt out of the box per HexDocs. |
| What NOT to use | **HIGH** | Every "don't" is grounded in a citable PROJECT.md decision, prompts/ research finding, or engineering-DNA gotcha. |
| 2026 email-compliance landscape | **HIGH** | Cross-verified against 5 industry sources Apr 2026. Gmail/Yahoo/Microsoft enforcement status, AMP for Email sunset, RFC 8058 specifics all confirmed. |
| Premailex long-term maintenance | **MEDIUM** | 15-month-old release; no credible replacement exists. Risk: contributor pickup needed if we want to influence direction. Acceptable risk for v0.1; flag as "watch this dep" in v1.0 maintenance plan. |
| sigra adapter | **MEDIUM** | sigra is pre-1.0 single-developer; treat as soft dependency, never block on it. |

---

## 13. Gaps I'm filling vs decisions already locked

**Already locked in PROJECT.md / prompts/ — I am citing, not deciding:**
- Hard required deps list (PROJECT.md "Constraints")
- Optional deps list (PROJECT.md "Constraints")
- Phoenix 1.8 / LiveView 1.1 / Ecto 3.13 / Postgres floor (D-06)
- Swoosh as transport, not replacement (PROJECT.md "what this is" + D-07)
- HEEx + Phoenix.Component as default renderer; MJML opt-in (D-18)
- Open/click tracking off by default (D-08)
- ExMachina excluded; Map.merge/2 fixtures (engineering-DNA §2.6)
- Conventional Commits + Release Please + Hex publish from protected ref (engineering-DNA §2.3 + PROJECT.md D-16)
- Telemetry naming convention (engineering-DNA §2.5)
- Custom Credo checks for domain rules (D-17)
- Anymail taxonomy verbatim for webhook normalization (D-14)
- Append-only event ledger with immutability trigger (D-15)
- Fake adapter as required release gate (D-13)
- ExDoc with `main: "getting-started"` (PROJECT.md v0.1 active reqs)

**Gaps I'm filling in this STACK.md:**
- **Specific 2026 versions** for every dep (not in PROJECT.md or prompts/)
- **`:mjml` vs `:mrml` correction** — PROJECT.md and prompts/ reference `:mrml` as the optional dep but the actual Hex package is `:mjml` (Rust NIF wrapping the underlying mrml Rust crate). No `:mrml` Hex package exists.
- **Confirmed ExDoc 0.40.x ships `llms.txt` automatically** — answers the milestone-context question affirmatively with verification.
- **Verified GitHub Action versions** for setup-beam, release-please-action, dependency-review-action, actionlint as of Apr 2026.
- **Confirmed the 2024 Yahooglesoft trio is now permanently enforcing** — Gmail Nov 2025 escalation, Microsoft May 2025 join.
- **Confirmed AMP for Email sunset** via Cloudflare community thread (Aug 2025 announce → Oct 20, 2025 deprecation).
- **The "version compatibility matrix"** (§9) — practical guidance for adopters running into mix dep conflict resolution.
- **The "stack patterns by variant"** (§10) — what changes when adopters do/don't have Oban, sigra, phx.gen.auth, Ash.

---

*Stack research for: mailglass — Phoenix-native transactional email framework*
*Researched: 2026-04-21*
*Source-of-truth files: `.planning/PROJECT.md`, `prompts/*.md`*
