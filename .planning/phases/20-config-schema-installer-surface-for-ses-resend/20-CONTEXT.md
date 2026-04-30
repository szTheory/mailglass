# Phase 20: Config Schema & Installer Surface for SES + Resend - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the adopter-facing contract drift around SES and Resend by making boot-time config validation, installer output, and pre-publish golden checks match the webhook provider surface that Mailglass already ships.

This phase is defensive and contract-focused. It does not add new webhook behavior, broaden the default public route surface, or introduce speculative provider knobs that runtime code does not already consume.

</domain>

<decisions>
## Implementation Decisions

### Config schema posture
- **D-20-01:** Add only the exact SES and Resend config keys that runtime code and public docs already consume today. Do not widen the public schema speculatively.
- **D-20-02:** The Phase 20 parity surface is:
  - `:ses` => `enabled`, `cert_cache_ttl_seconds`
  - `:resend` => `enabled`, `secret`, `timestamp_tolerance_seconds`
- **D-20-03:** `enabled` is a validation-parity key, not router magic. It must not imply route auto-mounting unless a later phase explicitly wires that behavior end-to-end.
- **D-20-04:** Reject the “broader provider config now” path. Mailglass should not accept undocumented or unused SES/Resend keys just to look flexible.

### Installer snippet posture
- **D-20-05:** Keep the installer-generated webhook mount snippet narrow and default-aligned with Phoenix least surprise. Do not make the generated router snippet mount every currently supported provider by default.
- **D-20-06:** The preferred installer example is `mailglass_webhook_routes "/webhooks"` or an explicit equivalent of the default provider set, with nearby guidance that adopters can opt into `:mailgun`, `:ses`, and `:resend` as needed.
- **D-20-07:** Phase 20 must still “surface SES + Resend” in the installer, but it should do so via adjacent explanatory copy or comment, not by silently broadening the generated public webhook surface.
- **D-20-08:** Reject the “full supported-provider list in the install snippet” path. That reads like a recommended default, creates unnecessary public endpoints by copy-paste, and increases future golden churn for a one-maintainer library.

### Publish-check failure contract
- **D-20-09:** Installer golden drift in `mix mailglass.publish.check` should fail through a typed mailglass exception path, not only a plain stderr string.
- **D-20-10:** The typed path must fit Mailglass's actual error architecture: a dedicated sibling exception module such as `Mailglass.PublishError` or `Mailglass.ReleaseError`, not a nonexistent parent `%Mailglass.Error{}` struct and not `Mailglass.ConfigError`.
- **D-20-11:** The error should carry a closed `:type` for this failure class (`:publish_blocked_golden_drift` or an equivalent module-scoped shorthand) and preserve actionable CLI remediation text at the Mix task boundary.
- **D-20-12:** Keep Mix UX boring and familiar. Internals may be typed and testable, but the final user-facing task failure should still read like a normal Mix failure with the exact regeneration command.

### Decision posture for downstream agents
- **D-20-13:** Downstream planning and execution should be decisive by default. Research tradeoffs, recommend the coherent default, and avoid escalating routine local choices back to the user.
- **D-20-14:** Escalate only if a decision would materially alter:
  - the public router/config contract for adopters
  - the error taxonomy promised by Mailglass as a library
  - long-term maintainer burden in a way that meaningfully changes roadmap shape
  - a user-visible workflow default the project owner is likely to care about directly
- **D-20-15:** Prefer boring, idiomatic Elixir/Phoenix library patterns over installer marketing, speculative config APIs, or clever publish-task abstractions.

### the agent's Discretion
- Exact key docstrings and wording inside `Mailglass.Config`, so long as they make `enabled` semantics explicit and do not imply route auto-mounting.
- Exact generated installer comment wording, so long as the default mount stays honest and the opt-in provider path is obvious.
- Final naming choice for the new typed publish exception module and closed `:type`, so long as it remains semantically distinct from adopter config errors and consistent with the rest of the error hierarchy.

</decisions>

<specifics>
## Specific Ideas

- The user wants the system to do the research, synthesize tradeoffs, and choose coherent defaults rather than forcing them to arbitrate routine engineering decisions.
- Great DX here means:
  - boot catches adopter typos under `:ses` and `:resend`
  - installer output is copy-paste safe and honest about defaults
  - docs and generated snippets point clearly to explicit provider opt-in
  - publish failures are typed internally and actionable externally
- Successful library posture in this ecosystem is small honest config surfaces, explicit route surfaces, and generated examples that match real defaults instead of acting as a product brochure.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and contract
- `.planning/ROADMAP.md` — Phase 20 goal, success criteria, and the contract-drift problem statement this phase closes.
- `.planning/PROJECT.md` — Maintainer constraints, Phoenix-first architecture, brand voice, and “batteries included without surprise” posture.
- `.planning/REQUIREMENTS.md` — Current SES/Resend requirement status and the defensive nature of this phase.
- `.planning/STATE.md` — Current milestone execution state and carry-forward context.

### Prior phase decisions that constrain this phase
- `.planning/phases/14-resend-webhook-provider-core-ingest/14-CONTEXT.md` — Resend verification contract and existing documented config shape.
- `.planning/phases/15-mailgun-webhook-provider/15-CONTEXT.md` — Explicit opt-in route posture and agent-led recommendation preference.
- `.planning/phases/16-ses-webhook-provider-sns-cache/16-CONTEXT.md` — SES explicit opt-in route posture, minimal-dependency design, and decisive-by-default downstream preference.
- `.planning/phases/18-ship-v0-3-0/18-CONTEXT.md` — Locked “decisive by default” posture and explicit opt-in provider documentation shape.

### Implementation seams for this phase
- `lib/mailglass/config.ex` — NimbleOptions schema; currently missing `:ses` / `:resend` top-level subtrees.
- `lib/mailglass/webhook/plug.ex` — Runtime config keys actually consumed for SES and Resend.
- `lib/mailglass/webhook/router.ex` — Default-vs-explicit provider mount contract that the installer must not misrepresent.
- `lib/mailglass/installer/templates.ex` — Generated router/runtime snippets and the installer DX seam to update.
- `guides/webhooks.md` — Public adopter config and provider opt-in contract that must stay aligned with installer and schema.
- `lib/mix/tasks/mailglass.publish.check.ex` — Current golden drift gate and failure path.
- `lib/mailglass/error.ex` — Real error-hierarchy shape; no parent `%Mailglass.Error{}` struct exists.
- `lib/mailglass/errors/config_error.ex` — Existing config-error boundary; publish hygiene should not be stuffed here.
- `test/mailglass/config_test.exs` — Current config schema coverage pattern to extend.
- `test/mailglass/install/install_golden_test.exs` — Golden refresh contract for installer changes.
- `test/example/README.md` — Installer snapshot source of truth that will drift when snippet output changes.
- `.planning/config.json` — Project workflow defaults; should move from interactive discuss mode to assumptions mode.
- `.planning/METHODOLOGY.md` — Project-level lens file that should encode the “research first, escalate only on high-impact choices” posture.

### Ecosystem priors
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` — Minimal mount-first Phoenix generator/router style.
- `https://hexdocs.pm/plug/Plug.Router.html` — Explicit consumed options and narrow route examples.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` — Honest config surface posture in core Elixir infra.
- `https://hexdocs.pm/swoosh/Swoosh.Mailer.html` — Stable shared config boundary without speculative adapter knobs.
- `https://hexdocs.pm/oban/Oban.html` — Validating real consumed config and keeping error/reporting paths explicit.
- `https://hexdocs.pm/nimble_options/NimbleOptions.html` — Schema-first validation model and anti-footgun defaults for accepted keys.
- `https://hexdocs.pm/mix/Mix.html` — Idiomatic task failure shape at the Mix boundary.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` — Publish-task ergonomics and dry-run philosophy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Config` already centralizes boot validation; Phase 20 should extend that seam rather than adding provider-local compile-env readers.
- `Mailglass.Webhook.Plug` already exposes the exact SES and Resend config keys worth validating now.
- `Mailglass.Webhook.Router` already locks the principle that non-default providers are explicit opt-in.
- `Mailglass.Install.GoldenTest` and `test/example/README.md` already provide the right drift-detection mechanism for installer output.
- `Mailglass.Error` + sibling `defexception` modules already define the house style for typed failures.

### Established Patterns
- Public route surfaces stay narrow by default and expand only through explicit adopter opt-in.
- Mailglass prefers native Elixir/OTP and minimal public API over speculative convenience surface.
- Errors are matched by module plus closed `:type`, never by message string.
- Generated examples should be copy-paste safe and should not advertise behavior that runtime defaults do not actually provide.

### Integration Points
- `Mailglass.Config`, `guides/webhooks.md`, and `Mailglass.Webhook.Plug` must agree exactly on the SES/Resend config contract after this phase.
- Installer snippet output, router docs, and golden snapshots must move together.
- The new typed publish failure path must align with `Mailglass.Error`, `docs/api_stability.md`, and any tests that lock the closed error taxonomy.
- Project-level GSD preference capture should live in `.planning/config.json` and `.planning/METHODOLOGY.md`, with this context file acting as the immediate bridge for Phase 20 planning.

</code_context>

<deferred>
## Deferred Ideas

- Any broader SES or Resend config surface beyond the keys runtime code already consumes.
- Auto-mount semantics tied to provider `enabled` keys. That would be a separate public-contract phase if ever desired.
- Turning the installer into a “supported provider matrix” or marketing surface.
- Broader release/publish taxonomy cleanup beyond the one golden-drift failure class needed here.

</deferred>

---

*Phase: 20-config-schema-installer-surface-for-ses-resend*
*Context gathered: 2026-04-30*
