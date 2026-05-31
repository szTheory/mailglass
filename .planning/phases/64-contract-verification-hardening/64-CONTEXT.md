# Phase 64: Contract Verification Hardening - Context

**Gathered:** 2026-05-31 (assumptions mode with subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the inbound stability contract executable through compiled-doc metadata,
docs drift checks, closed atom/type proof, and root verification wiring.

This phase covers PROOF-01, PROOF-02, and PROOF-03. It hardens proof for the
Phase 63 canonical inbound inventory; it does not broaden the public contract,
add inbound features, or promote internal provider, replay, worker, queue, or
operator UI implementation details.
</domain>

<decisions>
## Implementation Decisions

### Package-Local Compiled-Doc Proof

- **D-01:** Add `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` as the authoritative compiled-doc proof for `mailglass_inbound`.
- **D-02:** The package-local stability test should assert `@moduledoc since:` for stable runtime modules, stable structured error modules, stable Mix task modules, and adopter-facing testing helper modules.
- **D-03:** The package-local stability test should assert `@doc since:`, macro metadata, and callback metadata for stable public functions, macros, and callbacks that adopters call directly. It must not assert metadata for internal helpers, generated implementation functions, `@doc false` entries, worker modules, provider modules, replay internals, queue names, direct Oban job shapes, or operator UI details.
- **D-04:** Include adopter-facing testing helpers in compiled-doc since checks because they ship from `lib/` and are part of the package API. Keep them in the separate `testing` contract bucket; do not promote them into runtime `stable`.
- **D-05:** Root `test/mailglass/stability_contract_test.exs` should prove wiring only. Root tests should assert that the aggregate stability lane runs the inbound package contract lane, not duplicate the full inbound inventory.

### Closed Inbound Error Type Set Lock

- **D-06:** Use a centralized inbound docs-contract assertion as the Phase 64 lock for stable inbound structured-error `:type` sets. It should cover `MailglassInbound.MIMEError`, `MailglassInbound.SignatureError`, and `MailglassInbound.S3FetchError`.
- **D-07:** The centralized assertion should parse each error module section in `mailglass_inbound/docs/api_stability.md`, extract the `Closed :type set` bullet list, and compare it exactly, in order, to that module's `__types__/0` return value rendered as backticked atom tokens.
- **D-08:** Keep the per-error unit tests that assert each module's exact `__types__/0` list. Those tests own local struct semantics; the centralized docs-contract assertion owns code/docs drift.
- **D-09:** Add an explicit `Closed :type set` list for `MailglassInbound.MIMEError` in `mailglass_inbound/docs/api_stability.md` so MIME receives the same docs lock as Signature and S3.
- **D-10:** Do not generate docs from code or code from docs in this phase. `mailglass_inbound/docs/api_stability.md` remains the canonical contract inventory; executable tests enforce drift.

### Docs Drift Guard Tightening

- **D-11:** Extend package-local inbound docs-contract tests as the primary guard for PROOF-03. Root `mailglass.docs.check` may mirror broad Tier-1 rules, but release-line truth and inbound over-claim detection belong first in `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`.
- **D-12:** Version and install-pin truth should use structured comparisons against `mailglass_inbound/mix.exs` where possible. At minimum, README and inbound install-guide `{:mailglass_inbound, "~> X.Y"}` pins must match the package current major/minor.
- **D-13:** Stale release-line prose should be guarded in current adoption and release-position docs, especially `README.md`, `docs/inbound-install.md`, `docs/api_stability.md`, and the `CHANGELOG.md` Unreleased section. Released historical changelog sections may mention old versions.
- **D-14:** Semantic over-claim guards should combine exact known-forbidden phrases with scoped regex checks. Stable/adoption docs must fail on public replay API claims, stable worker/queue claims, provider-module extension claims, replay-as-fresh wording, synthetic/operator UI shipped claims, and stale inbound `1.x` stability claims.
- **D-15:** Deferred/internal wording remains allowed when it clearly frames the capability as not promised. Tests should inspect contract sections where possible so phrases such as `public replay API` are allowed in `deferred` but forbidden in `stable` and adoption prose.

### Root Verification Lane

- **D-16:** Make `mailglass_inbound` own its support-contract verification through a package-local `verify.support_contract.inbound` alias.
- **D-17:** Root `mix verify.stability_contract` should call `cmd --cd mailglass_inbound mix verify.support_contract.inbound` rather than listing inbound test files directly.
- **D-18:** The inbound support-contract lane should run the docs-contract test, the compiled-doc stability metadata test, and focused closed-set contract proof in one `mix test ... --warnings-as-errors` invocation.
- **D-19:** `mailglass_inbound/mix.exs` should define `cli/0` preferred envs for `verify.support_contract.inbound` and may expose package-local `verify.stability_contract` as a delegate to `verify.support_contract.inbound` for maintainer DX.
- **D-20:** Keep `verify.docs.contract.inbound` docs-only unless a later phase explicitly changes its meaning. The broader support-contract lane should stay distinct.

### the agent's Discretion

- Planner may decide whether closed-set proof lives inside `docs_contract_test.exs` or a focused `closed_contract_sets_test.exs`, as long as the inbound support-contract alias includes it and failures remain diagnostic.
- Planner may decide the exact helper names for compiled-doc assertions by mirroring root/admin style.
- Planner should fix existing stale inbound install/release-line wording discovered during discussion if tests expose it, but only within the Phase 64 proof scope.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/ROADMAP.md` - Phase 64 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - PROOF-01, PROOF-02, PROOF-03 and v1.4 out-of-scope table.
- `.planning/PROJECT.md` - v1.4 stability-lock intent and convergence posture.
- `.planning/STATE.md` - current v1.4 preflight locks and prior trust-contract decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface, recommendation-first, and compatibility-contract lenses.
- `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md` - locked Phase 63 decisions for stable/testing/internal/deferred inventory.

### Stability Contract Targets

- `mailglass_inbound/docs/api_stability.md` - canonical inbound stable/testing/internal/deferred inventory.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - existing package-local docs-contract assertions and over-claim guards.
- `mailglass_inbound/mix.exs` - package-local aliases, docs grouping, version truth, and current lack of inbound support-contract alias.
- `mix.exs` - root `verify.stability_contract` aggregate gate.
- `test/mailglass/stability_contract_test.exs` - root/core compiled-doc helper precedent and root wiring assertions.
- `mailglass_admin/mix.exs` - sibling package support-contract alias precedent.
- `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` - sibling package compiled-doc metadata proof precedent.

### Stable Inbound Modules And Error Sets

- `mailglass_inbound/lib/mailglass_inbound.ex` - stable package identity helper.
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` - stable canonical inbound value object.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - stable provider ingress seam.
- `mailglass_inbound/lib/mailglass_inbound/ingress/caching_body_reader.ex` - stable `Plug.Parsers` body-reader helper.
- `mailglass_inbound/lib/mailglass_inbound/router.ex` - stable router authoring seam.
- `mailglass_inbound/lib/mailglass_inbound/mailbox.ex` - stable mailbox callback contract.
- `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex` - stable PubSub topic builder.
- `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` - stable raw MIME structured error and `__types__/0`.
- `mailglass_inbound/lib/mailglass_inbound/signature_error.ex` - stable signature structured error and `__types__/0`.
- `mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex` - stable SES S3 structured error and `__types__/0`.
- `mailglass_inbound/test/mailglass_inbound/mime_error_test.exs` - existing MIME error closed-set unit test.
- `mailglass_inbound/test/mailglass_inbound/signature_error_test.exs` - existing signature error closed-set/docs test.
- `mailglass_inbound/test/mailglass_inbound/s3_fetch_error_test.exs` - existing S3 error closed-set/docs test.

### Adopter-Facing Testing Helpers

- `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` - adopter-facing test fixtures.
- `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` - adopter-facing ingress driver.
- `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` - adopter-facing assertion macros.
- `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` - adopter-facing ExUnit case template.

### Current Docs Drift Inputs

- `mailglass_inbound/README.md` - install pin and adoption wording.
- `mailglass_inbound/docs/inbound-install.md` - install pin and adoption path wording.
- `mailglass_inbound/CHANGELOG.md` - Unreleased/current release-line wording.
- `lib/mix/tasks/mailglass.docs.check.ex` - root Tier-1 docs drift checker.
- `test/mailglass/docs_contract_test.exs` - root docs-contract precedent.

### External References Used During Discussion

- `https://github.com/elixir-lang/ex_doc` - ExDoc metadata support, including `since`.
- `https://hexdocs.pm/elixir/Code.html` - `Code.fetch_docs/1` compiled-doc metadata access.
- `https://hexdocs.pm/mix/Mix.html` - Mix aliases and `cmd` composition.
- `https://hexdocs.pm/mix/Mix.Tasks.Test.html` - `mix test` file selection and warnings-as-errors gate.
- `https://semver.org/` - public API declared in docs and 0.x/1.0 release semantics.
- `https://guides.rubyonrails.org/action_mailbox_basics.html` - Action Mailbox prior-art and synthetic UI/worker footguns.
- `https://anymail.dev/en/stable/sending/tracking/` - normalized event vocabulary over provider internals.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Root `test/mailglass/stability_contract_test.exs` already has `Code.fetch_docs/1` helpers for module metadata and function metadata.
- `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` provides the closest sibling-package pattern for compiled-doc stability proof.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` already contains Phase 63 section parsing, inventory token assertions, and over-claim refutations.
- `mailglass_inbound/docs/api_stability.md` already lists the stable/testing/internal/deferred contract buckets and explicit stable error modules.
- Signature and S3 error docs already have explicit `Closed :type set` lists; MIME currently needs the same explicit list.

### Established Patterns

- Stability is semantics-first and defined by the canonical inventory, not by generated docs visibility or source reachability.
- Package-local support-contract aliases own package-local contract proof; root aliases aggregate sibling package proof.
- Docs-contract tests are appropriate for prose drift and forbidden claims; compiled-doc tests are appropriate for ExDoc metadata.
- Closed atom/type sets should be stable machine-readable contracts; human message strings remain non-contractual.
- Testing helpers can be adopter-facing without becoming runtime-stable APIs.

### Integration Points

- Add or update inbound package aliases in `mailglass_inbound/mix.exs`.
- Update root `mix.exs` `verify.stability_contract` to delegate to `verify.support_contract.inbound`.
- Update root stability-contract test expectations to assert alias delegation rather than hard-coded inbound docs test file.
- Add package-local compiled-doc metadata proof and route it through the inbound support-contract alias.
- Extend inbound docs-contract proof for exact closed error type docs, install/release-line truth, and scoped semantic over-claim guards.
</code_context>

<specifics>
## Specific Ideas

The user requested deeper one-shot recommendation synthesis rather than a shallow assumption confirmation. Four research tracks were run for:

- compiled-doc proof scope,
- closed atom/type set locking,
- docs drift guard tightening,
- root verification lane architecture.

The resulting recommendation set is intentionally cohesive: keep the canonical contract in docs, add executable proof at package-local boundaries, keep root as aggregate gate, and avoid freezing internal reachability.
</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 64 contract-verification scope.

The following remain explicitly out of scope for v1.4 feature work unless a future milestone separately promotes them: matcher expansion beyond recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`, public replay API, public provider extension API, public worker/queue contract, synthetic inbound development UI, `gen_smtp` listener work, and ecosystem integrations.
</deferred>

---

*Phase: 64-contract-verification-hardening*
*Context gathered: 2026-05-31*
