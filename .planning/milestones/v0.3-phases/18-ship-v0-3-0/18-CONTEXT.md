# Phase 18: Ship v0.3.0 - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish `mailglass` `0.3.0` and `mailglass_admin` `0.3.0` to Hex.pm with a complete adopter-facing release story for webhook coverage completion. Scope includes the curated changelog narrative, the public webhook guide updates required for Resend, and the release ceremony / proof path needed to publish with low surprise and high trust.

This phase does not deliver new provider behavior, release-platform rewrites, or broad documentation redesign beyond what is needed to ship the `0.3.0` contract cleanly.

</domain>

<decisions>
## Implementation Decisions

### Release narrative and changelog shape
- **D-18-01:** `CHANGELOG.md` should use a curated maintainer-written `0.3.0` entry, not a generated commit ledger with a brief intro.
- **D-18-02:** The `mailglass` `0.3.0` entry should frame the release as an additive webhook-coverage release: Mailgun, SES, and Resend now complete the public provider-coverage story under the existing normalized webhook ingest contract.
- **D-18-03:** The top of the `mailglass` `0.3.0` entry should answer three adopter questions directly: what changed, who should care, and whether any migration / codemod / urgent action is required.
- **D-18-04:** The changelog should explicitly state that this is not a `0.2.0`-style migration release. No codemod or special rollback flow should be implied.
- **D-18-05:** The changelog may include a concise provider-coverage summary, but it must not turn into a feature-matrix marketing page or duplicate the full provider-guide setup content.
- **D-18-06:** `mailglass_admin/CHANGELOG.md` should stay short and coordinated with core: matching sibling version, no standalone admin migration story, no fake independent feature narrative unless the package actually changed in a user-visible way.

### Resend public docs shape
- **D-18-07:** `guides/webhooks.md` should be updated in place, not redesigned. Keep the current guide structure: shared webhook plumbing first, then explicit provider sections.
- **D-18-08:** Resend should be documented as an explicit opt-in provider, parallel to Mailgun and SES. Do not imply that `mailglass_webhook_routes "/webhooks"` mounts Resend by default.
- **D-18-09:** Add a dedicated `### Resend setup` section with:
  - explicit router snippet using `providers: [:postmark, :sendgrid, :resend]`
  - `config :mailglass, :resend` snippet
  - short explanation of Svix header verification
  - explicit `whsec_...` secret shape
  - supported normalized-event coverage
- **D-18-10:** Keep `Mailglass.Webhook.CachingBodyReader` as a shared prerequisite in the guide and reinforce that Resend verification depends on exact raw request bytes.
- **D-18-11:** The guide must remove stale wording that says SES and Resend “land later.” Any intro, route list, or provider summary must reflect that Resend is shipped now.
- **D-18-12:** Resend docs should preserve least-surprise copy-paste behavior: exact endpoint path, exact secret shape, and exact opt-in route surface should be literal in examples.

### Release proof and ceremony evidence
- **D-18-13:** Use a balanced strict release-proof bar. Reuse the existing `publish-hex.yml`, `post-publish-smoke.yml`, `mix mailglass.publish.check`, and `MAINTAINING.md` runbook rather than inventing a new release artifact or checklist system.
- **D-18-14:** The canonical evidence story for `0.3.0` is:
  - pre-publish summary reviewed before approval
  - CI green on the tagged SHA
  - successful publish to Hex.pm
  - HexDocs indexed
  - fresh-host smoke during the 60-minute window
- **D-18-15:** Do not create heavyweight release dossiers or duplicate workflow output into separate proof artifacts. That is ceremony theater for a one-maintainer Hex library and creates drift.
- **D-18-16:** Release notes and docs must not make claims that exceed the actual release proof. Claims should stay tied to what the publish gate, provider guide, and smoke path really verify.

### Decision posture for downstream agents
- **D-18-17:** Downstream planning and execution for this phase should be decisive by default. Research tradeoffs, pick the coherent default, and avoid escalating routine local choices back to the user.
- **D-18-18:** Escalate only if a decision would materially alter:
  - the public release contract
  - the publish / rollback safety story
  - the documented route / config surface for adopters
  - user-visible claims that could mislead library consumers
- **D-18-19:** Prefer boring, idiomatic Hex / Phoenix OSS patterns over clever release mechanics, docs abstractions, or marketing-heavy framing.

### the agent's Discretion
- Exact changelog prose, provided it keeps the curated maintainer voice and the additive / no-codemod story clear.
- Exact subsection names inside `guides/webhooks.md`, provided Resend remains an explicit dedicated provider section and the guide stays copy-paste safe.
- Exact wording in `MAINTAINING.md` or workflow comments, provided the release-proof story remains consistent with the existing publish and smoke paths.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone contract
- `.planning/ROADMAP.md` — Phase 18 goal, success criteria, dependency on Phase 17, and the release scope anchor.
- `.planning/PROJECT.md` — Current milestone goal, maintainer posture, brand voice, and release-engineering constraints.
- `.planning/REQUIREMENTS.md` — `DELIV-04` milestone traceability and the provider-coverage completion context.
- `.planning/STATE.md` — Current milestone execution state and recent provider milestones.

### Prior phase context that is now locked
- `.planning/phases/14-resend-webhook-provider-core-ingest/14-CONTEXT.md` — Resend signature, timestamp-tolerance, and event-mapping decisions.
- `.planning/phases/15-mailgun-webhook-provider/15-CONTEXT.md` — Mailgun explicit opt-in route surface and public-doc expectations.
- `.planning/phases/16-ses-webhook-provider-sns-cache/16-CONTEXT.md` — SES explicit opt-in route surface, provider guide posture, and agent-led recommendation preference.
- `.planning/phases/17-unblock-verify-resend/17-CONTEXT.md` — Resend wiring completion and the explicit defer of guide work to Phase 18.
- `.planning/milestones/v0.2-phases/13-v0-2-release-ceremony/13-CONTEXT.md` — Locked release-ceremony posture: curated changelog narrative, Tier 1 docs bar, decisive-by-default release planning, and boring publish mechanics.

### Release-facing docs and runbook
- `CHANGELOG.md` — Core package release story for `0.3.0`.
- `mailglass_admin/CHANGELOG.md` — Sibling package coordinated release note.
- `guides/webhooks.md` — Public adopter contract for webhook route mounting, config, and provider behavior.
- `MAINTAINING.md` — Release flow, fallback path, 60-minute smoke window, and maintainer runbook.
- `README.md` — Public project positioning and any provider-coverage / milestone claims that should stay aligned with the release story.

### Publish and smoke machinery
- `.github/workflows/publish-hex.yml` — Pre-publish summary, tagged-SHA CI gate, idempotent publish flow, and environment approval.
- `.github/workflows/post-publish-smoke.yml` — Hex / HexDocs indexing waits and fresh Phoenix-host smoke contract.
- `lib/mix/tasks/mailglass.publish.check.ex` — Tarball, allowlist, changelog, metadata, and linked-version pre-publish gate.
- `test/mailglass/install/install_first_preview_smoke_test.exs` — Repo-local proof shape for the fresh-host install / compile / boot smoke contract.

### Resend implementation and public-doc seams
- `lib/mailglass/webhook/router.ex` — Default provider route surface vs explicit opt-in provider mounting.
- `lib/mailglass/webhook/plug.ex` — Provider dispatch and `CachingBodyReader` expectation at the public webhook boundary.
- `lib/mailglass/webhook/providers/resend.ex` — Resend verification contract, secret shape, timestamp tolerance, and normalized event coverage.
- `lib/mailglass/webhook/caching_body_reader.ex` — Raw-body preservation contract that public docs must explain correctly.
- `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` — Integration proof of the Resend plug path and signature behavior.
- `test/support/webhook_case.ex` — Test helper support showing Resend is now a first-class provider in the internal test UX.
- `lib/mailglass/installer/templates.ex` — Existing installer/router snippet posture; useful for checking whether public docs and generated examples drift.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/mailglass.publish.check.ex`: already provides the release-blocking tarball / changelog / metadata gate. Phase 18 should reuse it, not replace it.
- `.github/workflows/publish-hex.yml`: already renders a pre-publish summary and enforces CI-green-on-tagged-SHA before publish.
- `.github/workflows/post-publish-smoke.yml`: already encodes the fresh-host smoke contract and Hex / HexDocs indexing waits.
- `lib/mailglass/webhook/providers/resend.ex`: already defines the public Resend verification and normalization semantics that the guide should describe.
- `lib/mailglass/webhook/caching_body_reader.ex`: already establishes the raw-body requirement; docs should point adopters here conceptually without overexplaining internals.

### Established Patterns
- mailglass release notes for meaningful minor releases should lead with maintainer-written user impact, not internal commit history.
- Provider route surfaces are explicit and conservative: zero-arg route mounting stays narrow, additional providers are opt-in.
- Provider docs use runnable Phoenix / Plug snippets rather than abstract matrices as the primary UX.
- Release engineering favors honest, boring, auditable gates over new ceremony or process novelty.

### Integration Points
- `CHANGELOG.md`, `mailglass_admin/CHANGELOG.md`, and `guides/webhooks.md` must agree on what `0.3.0` changes for adopters.
- `guides/webhooks.md` must align exactly with `router.ex`, `plug.ex`, and `providers/resend.ex` so the first copy-paste path works.
- `MAINTAINING.md` and the publish/smoke workflows must continue to tell the same release-proof story with no wording drift.
- Any Phase 18 plan should treat the publish gate and the provider-guide update as coupled: release claims should never outrun the docs users copy from.

</code_context>

<specifics>
## Specific Ideas

- The user wants research-backed, coherent defaults chosen for them rather than a menu of local tradeoffs. For this phase, downstream agents should synthesize and decide unless a choice truly changes the public release contract.
- The release should feel like “webhook coverage complete” without sounding like marketing copy or implying automatic provider enablement.
- The best public-doc shape is shared webhook plumbing first, explicit provider add-ons second. That fits Phoenix / Plug expectations and lowers copy-paste mistakes.
- Great DX here means:
  - exact snippets
  - explicit opt-in route surfaces
  - no hidden `CachingBodyReader` footgun
  - no fake migration story
  - no release-proof theater

</specifics>

<deferred>
## Deferred Ideas

- Project-wide codification of the “decisive by default, escalate only for truly high-impact choices” preference outside this phase. There is evidence this preference is broadly useful, but Phase 18 should only capture it locally unless a later workflow/config cleanup phase formalizes it safely.
- Broad redesign of `guides/webhooks.md` into a provider matrix or larger doc IA refresh. That is outside the focused `0.3.0` ship scope.
- Heavyweight release evidence artifacts or release dossiers. Current publish + smoke + runbook evidence is sufficient for a one-maintainer Hex library.

</deferred>

---

*Phase: 18-ship-v0-3-0*
*Context gathered: 2026-04-29*
