# Phase 64: Contract Verification Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-05-31T18:28:17Z
**Phase:** 64-contract-verification-hardening
**Mode:** assumptions with user-requested subagent research
**Areas analyzed:** Inbound Compiled-Doc Proof Scope, Closed Atom/Type Locking, Docs Drift Guard Tightening, Root Verification Lane

## Assumptions Presented

### Inbound Compiled-Doc Proof Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add a package-local inbound stability-contract test that mirrors root `Code.fetch_docs/1` helpers and asserts `@moduledoc since:` plus callable metadata for the inbound contract inventory. | Likely | `test/mailglass/stability_contract_test.exs`, `mailglass_admin/test/mailglass_admin/stability_contract_test.exs`, `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/mix.exs` |

### Closed Atom/Type Locking Pattern

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| PROOF-02 should be satisfied by explicit tests that compare closed `__types__/0` sets to exact documented type tokens for all three stable inbound error structs. | Confident | `mailglass_inbound/lib/mailglass_inbound/mime_error.ex`, `mailglass_inbound/lib/mailglass_inbound/signature_error.ex`, `mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex`, corresponding error tests, `mailglass_inbound/docs/api_stability.md` |

### Docs Drift Guard Tightening

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Existing inbound docs-contract tests should be extended, not replaced, to fail on stale release-line wording and semantic over-claims while preserving deferred/internal wording. | Likely | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/inbound-install.md`, `mailglass_inbound/CHANGELOG.md`, `mailglass_inbound/docs/api_stability.md` |

### Root Verification Lane Fail-Closed Wiring

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Root `mix verify.stability_contract` should delegate to a package-local inbound support-contract alias rather than hard-coding inbound test files. | Confident | `mix.exs`, `mailglass_inbound/mix.exs`, `mailglass_admin/mix.exs`, `test/mailglass/stability_contract_test.exs` |

## Corrections Made

The user asked to deepen all assumptions with subagent research, ecosystem/prior-art analysis, pros/cons/tradeoffs, prompt-corpus review, and a single cohesive recommendation set. No assumption was rejected outright; the final decisions refined the initial assumptions as follows:

### Inbound Compiled-Doc Proof Scope

- **Original assumption:** Cover only inbound `stable` inventory in compiled-doc metadata checks.
- **User-directed refinement:** Research tradeoffs and produce a more cohesive recommendation.
- **Final decision:** Include adopter-facing testing helpers in compiled-doc since proof because they ship from `lib/`, but keep them in the separate `testing` bucket rather than runtime `stable`.

### Closed Atom/Type Locking

- **Original assumption:** Normalize per-error docs-lock tests across all three stable errors.
- **User-directed refinement:** Research centralized vs per-file proof shape.
- **Final decision:** Use one centralized exact docs comparison for all three stable error modules while preserving local per-error `__types__/0` tests.

### Docs Drift Guard Tightening

- **Original assumption:** Extend package-local docs-contract tests for stale release-line wording.
- **User-directed refinement:** Include release-line truth, user-facing docs semantics, and prior-art footguns.
- **Final decision:** Use structured version comparisons for install pins/current package truth, plus scoped prose/regex guards for semantic over-claims. Do not ban deferred/internal terms globally.

### Root Verification Lane

- **Original assumption:** Root `verify.stability_contract` should include inbound compiled-doc proof.
- **User-directed refinement:** Research package-local vs root-owned lane architecture.
- **Final decision:** Add `verify.support_contract.inbound` in `mailglass_inbound/mix.exs` and have root delegate to it.

## External Research

- ExDoc and Elixir compiled docs support metadata such as `since`, accessible through compiled docs. This supports using `@moduledoc since:` and `@doc since:` as executable contract metadata.
  - Sources: `https://github.com/elixir-lang/ex_doc`, `https://hexdocs.pm/elixir/Code.html`
- Mix aliases and `mix cmd` support composing package-local verification lanes from root; `mix test` supports focused file selection and warnings-as-errors.
  - Sources: `https://hexdocs.pm/mix/Mix.html`, `https://hexdocs.pm/mix/Mix.Tasks.Test.html`
- SemVer treats public API as something that may be declared in documentation, and `0.y.z` as not stable in the same way `1.0.0` is. This supports executable release-line/docs truth.
  - Source: `https://semver.org/`
- Rails Action Mailbox shows why synthetic inbound UI and background worker details should not be implied unless shipped and supported.
  - Source: `https://guides.rubyonrails.org/action_mailbox_basics.html`
- Anymail's tracking vocabulary demonstrates the durable pattern of stable normalized events over provider-specific internals.
  - Source: `https://anymail.dev/en/stable/sending/tracking/`

## Prompt Corpus Applied

Relevant prompt corpus inputs reviewed:

- `prompts/Phoenix needs an email framework not another mailer.md`
- `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`
- `prompts/ecto-best-practices-deep-research.md`
- `prompts/elixir-best-practices-deep-research.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/mailer-domain-language-deep-research.md`
- `prompts/mailglass-brand-book.md`
- `prompts/mailglass-engineering-dna-from-prior-libs.md`
- `prompts/phoenix-best-practices-deep-research.md`

Applied themes:

- Prefer narrow honest public surfaces over brochure-style comprehensiveness.
- Push correctness into compile-time/check-time guarantees where Elixir and Phoenix make that natural.
- Keep provider internals and worker/queue details behind stable semantic seams.
- Make docs executable when they define public contract and release posture.
- Optimize maintainer and adopter DX by giving each package its own local verification command while preserving one root release gate.
