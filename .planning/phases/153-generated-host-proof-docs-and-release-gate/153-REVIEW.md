---
phase: 153-generated-host-proof-docs-and-release-gate
reviewed: 2026-08-04T12:31:00Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - .github/workflows/post-publish-smoke.yml
  - .github/workflows/publish-hex.yml
  - .github/workflows/release-please.yml
  - README.md
  - dev/mailglass/generated_host/checkpoint.ex
  - dev/mailglass/generated_host/host_template.ex
  - dev/mailglass/generated_host/journey.ex
  - guides/authoring-mailables.md
  - guides/compatibility-and-deprecations.md
  - guides/getting-started.md
  - guides/multi-tenancy.md
  - guides/production-go-live-checklist.md
  - guides/rate-limiting.md
  - lib/mailglass/config.ex
  - lib/mailglass/production_preflight.ex
  - lib/mix/tasks/mailglass.gen.migration.ex
  - lib/mix/tasks/mailglass.preflight.ex
  - mailglass_admin/README.md
  - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
  - mix.exs
  - reference/demo_app/mix.lock
  - scripts/check_generated_host_proof.sh
  - scripts/consumer_install_smoke.sh
  - scripts/generated_host_proof.sh
  - scripts/resolve_release_packages.exs
  - test/generated_host/http_journey_test.exs
  - test/generated_host/journey_contract_test.exs
  - test/generated_host/negative_controls_test.exs
  - test/generated_host/readiness_operator_test.exs
  - test/generated_host/sync_async_parity_test.exs
  - test/mailglass/demo_data_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/install/install_first_preview_smoke_test.exs
  - test/mailglass/mix_tasks/preflight_test.exs
  - test/mailglass/production_preflight_test.exs
  - test/mailglass/publish/post_publish_smoke_contract_test.exs
  - test/mailglass/shipped_migration_divergence_test.exs
  - test/scripts/linked_release_concurrency_test.exs
  - test/scripts/release_package_resolver_test.exs
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 153: Code Review Report

**Reviewed:** 2026-08-04T12:31:00Z
**Depth:** standard
**Files Reviewed:** 39
**Status:** issues_found

## Summary

The generated-host release gate, preflight checks, release workflows, scripts, documentation, and scoped tests were reviewed. The release proof currently destroys the shared GitHub runner temporary directory, and its negative-control evidence can pass without executing the prerequisite failures it claims to prove. Production preflight can also report ready while some mounted webhook routes lack verification credentials.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Post-publish proof recursively deletes GitHub's shared temporary directory

**File:** `.github/workflows/post-publish-smoke.yml:376`; `scripts/generated_host_proof.sh:50`

**Issue:** The post-publish workflow sets `WORK_DIR` to `${{ runner.temp }}`, but `generated_host_proof.sh` unconditionally runs `rm -rf "$WORK_DIR"` from its EXIT trap. In `--stage all` mode the parent process itself has no generated host, so it still removes the entire runner-owned temporary directory after its child stages complete. This can delete GitHub Actions command files and artifacts needed by later steps, and the script is similarly unsafe for any caller that supplies an existing directory.

**Fix:** Always allocate and own a dedicated child directory before destructive cleanup. For example, pass `WORK_DIR: ${{ runner.temp }}/mailglass-generated-host-${{ github.run_id }}` and require the script to create it with `mktemp -d` beneath an explicitly supplied parent; record an ownership marker and only remove a directory carrying that marker.

### CR-02: Queue/schema negative controls do not test any negative condition

**File:** `dev/mailglass/generated_host/journey.ex:91-108`

**Issue:** Every queue/schema control merely maps its name to a hardcoded `{reason, "rejected"}` tuple. It neither changes the dependency/Oban/schema/migration condition nor calls the public delivery entrypoint. Consequently, the checkpoint's successful negative-controls stage is emitted even if every claimed prerequisite regression would allow a queue insert or delivery. This creates false release evidence.

**Fix:** For each control, create an isolated host configuration that actually violates that one prerequisite, invoke `Mailglass.Outbound.deliver_later/1`, assert the expected typed rejection, and then assert the before/after effect snapshot is unchanged.

### CR-03: Input negative controls all exercise only the zero-recipient case

**File:** `dev/mailglass/generated_host/host_template.ex:338-344`; `dev/mailglass/generated_host/journey.ex:110-124`

**Issue:** `input_message/1` uses `control_name` only in the subject; it builds the identical message with no recipient for every control. Thus controls labelled `to_cc`, `duplicate_recipient`, `multiple_recipients`, `unsupported_attachment`, `unsupported_payload`, `unsupported_provider_options`, and `oversized_json` never supply those malformed inputs. `assert_input_rejected!/2` additionally accepts any error rather than the corresponding failure class. The proof can therefore pass while all of those validations are broken.

**Fix:** Build a distinct malformed message for each control and assert the expected `%Mailglass.SendError{type: :preflight_rejected}` reason/context before recording its zero-effect snapshot.

### CR-04: Production preflight accepts a single credential for multiple mounted webhook providers

**File:** `lib/mailglass/production_preflight.ex:210-223`

**Issue:** `signing_configured?/0` returns true when *any* of Postmark, SendGrid, Mailgun, or Resend has a nonempty credential. A host that mounts, for example, both `:postmark` and `:sendgrid` passes `mix mailglass.preflight` with only Postmark Basic Auth configured, despite the preflight remediation and go-live guide promising signing material for every mounted provider route. That gives an unsafe ready result for a route which will reject all legitimate callbacks (or has not been deliberately secured).

**Fix:** Make the preflight receive or discover the exact providers mounted by `mailglass_webhook_routes`, then require a valid credential for every selected provider. If mounted routes cannot be reliably discovered, fail this check with explicit configuration that lists the intended providers rather than treating any credential as sufficient.

## Warnings

### WR-01: Compatibility guide contradicts its advertised release line

**File:** `guides/compatibility-and-deprecations.md:1-4, 102-107, 176-191, 209-213`

**Issue:** The guide calls itself the canonical policy for the `2.x` line, but its release guarantees, support matrix, and sibling policy repeatedly state `1.x` as the supported contract. This is release-facing documentation used as a source of compatibility truth, so adopters cannot determine which major line the stated guarantees apply to.

**Fix:** Decide the intended supported line and update all policy headings, release guarantees, support-matrix labels, sibling policy, and horizons consistently. Add a docs-contract assertion that rejects mixed `1.x`/`2.x` policy text unless it is in an explicitly labelled historical section.

---

_Reviewed: 2026-08-04T12:31:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
