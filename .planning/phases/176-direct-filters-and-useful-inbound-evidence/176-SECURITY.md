---
phase: "176"
slug: "direct-filters-and-useful-inbound-evidence"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-28"
---

# Phase 176 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register merged from the `<threat_model>` blocks of 176-01..176-10 PLAN.md plus each SUMMARY's `## Threat Flags` (all ten report "None" — no new attack surface beyond the planned register).
> ASVS L1 with a plan-time register and zero open threats after grep-depth verification, so the auditor subagent was skipped per the workflow's short-circuit rule.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser -> OperatorLive / InboundLive events | `phx-change` / `phx-submit` / `phx-auto-recover` payloads, including any `tenant_id` and selection keys, are untrusted | Filter values, Account id (authorization-relevant) |
| URL -> handle_params | `handle_params` stays the authorization gate for Account and selection; invalid filter values arrive from untrusted URLs | Query params |
| Stored provider headers -> HEEx | Display names and addresses are attacker-controlled sender input | Sender-controlled strings (XSS, spoofing) |
| Authorized operator -> detail view | Unmasked ordinary contacts are shown only on the tenant-scoped detail read | Recipient/sender addresses (PII) |
| Operator click -> reveal_raw | Authorization happens at action time on the server; the button is untrusted UI | Raw provider payload (PII) |
| Read model -> LiveView | Read exceptions are classified server-side; their messages must not reach HTML | Exception text |
| Browser history -> focused input | Back/Forward navigation changes the URL while the operator may be typing | Search draft |
| Dev-only Storybook/gallery -> reviewers | Fixtures are visible to anyone with dev access | Synthetic fixtures |
| Test suite -> merge decision | A vacuous pass would let a prohibition regress unnoticed | Test verdicts |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-176-01 | Elevation of privilege | OperatorLive commit_filters (validate/apply/recover) | high | mitigate | `FilterCommit.commit_params/2` does `Map.put("tenant_id", tenant_id \|\| "")` (`mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex:45-50`); called with `socket.assigns.selected_tenant_id` at `operator_live.ex:1342`; all three handlers (`apply_filters` :259, `recover_filters` :266, `validate_filters` :279) route through `commit_filters/3`; test "Phase 176 recover ignores a foreign tenant_id" asserts `refute path =~ "foreign-tenant"` (`operator_live_test.exs` ~3327) | closed |
| T-176-02 | Information disclosure | Selection carried across commits | medium | mitigate | `@dropped_on_commit ~w(page delivery_id inbound_id full)` dropped in `commit_params/2` (`filter_commit.ex:15,47`) | closed |
| T-176-03 | Denial of service | Long search values in URL | low | accept | See Accepted Risks AR-176-01 | closed |
| T-176-04 | Tampering | FilterSearchSync hook overwriting typed input | low | mitigate | `priv/static/hooks.js:115-126` pending flag with `setTimeout(this.clearPending, 1500)`; hook wired at `operator/filters_form.ex:34`, `inbound/filters_form.ex:39`; 176-06 SUMMARY reports the "typing after an empty Back is kept" case green on both clients | closed |
| T-176-05 | Tampering | DetailHeader address rendering (XSS) | high | mitigate | No `raw/1` in phase components (only `raw` in lib is the pre-existing `root.html.heex:26` inline JS); `inbound/components_test.exs:623-628` renders a `<script>alert(1)</script>` display name and asserts it appears only as text, `refute html =~ "<script>alert(1)</script>"` | closed |
| T-176-06 | Spoofing | Display names imitating another address | medium | mitigate | `inbound/address_list.ex` carries `spoof?: spoof?(name, addr_spec)` (:14, :49, :100) and always renders the real addr-spec; IDN/homograph detection deferred per CONTEXT | closed |
| T-176-07 | Information disclosure | Unmasking beyond ordinary authorized detail | medium | mitigate | Prohibition P2 (`phase176_prohibition_contract_test.exs:174-225`) keeps routing-trace matcher/actual masked on component and full-detail route; P3 keeps Quick view projection (Delivered to only, no To list) | closed |
| T-176-08 | Information disclosure | EvidenceCard redacted/denied states | high | mitigate | `<pre id="inbound-evidence-raw">` only in the `:revealed` case branch (`inbound/evidence_card.ex:124-126`); P4 sentinel-byte tests on redacted/denied component renders and live denied route (`phase176_prohibition_contract_test.exs:275-310`) | closed |
| T-176-09 | Elevation of privilege | Single toggle switching events | medium | mitigate | Toggle dispatches `reveal_raw` unless `:revealed` (`evidence_card.ex:72`); `handle_event("reveal_raw")` calls `authorize_reveal(socket)` at action time (`inbound_live.ex:451-452,1882`); `re_redact_raw` only collapses (:468) | closed |
| T-176-10 | Information disclosure | Reveal telemetry | medium | mitigate | Re-proved by T-176-26 (P5) | closed |
| T-176-11 | Information disclosure | Failed-read panels (Deliveries) | medium | mitigate | Failures classified by `transient_read_error?/1` (`operator_live.ex:1443,1490,1544,1571`), never by message; `operator_live_test.exs:2389` `refute html =~ "synthetic transient operator read failure"` | closed |
| T-176-12 | Repudiation | Misleading results after a failure | medium | mitigate | P7 "a failed new-query read shows no count and no empty copy" for Deliveries (`phase176_prohibition_contract_test.exs:376-400`) | closed |
| T-176-13 | Tampering | Invalid URL values | low | mitigate | Allow-list normalization unchanged (`normalize_filter_params_with_errors/1`, errors block commit in `commit_filters/3`); P8 asserts invalid filter is labelled as excluded (:429-447) | closed |
| T-176-14 | Elevation of privilege | InboundLive commit_filters (validate/apply/recover) | high | mitigate | `inbound_live.ex:2082` forces `selected_tenant_id` via `commit_params/2`; handlers `apply_filters` :262, `recover_filters` :269, `validate_filters` :282 all route through `commit_filters/3`; `inbound_live_test.exs:2740-2744` sends `"tenant_id" => "foreign-tenant"` and asserts `refute change_path =~ "foreign-tenant"` (recover variants at :2763-2826) | closed |
| T-176-15 | Information disclosure | inbound_id/full carried across commits | medium | mitigate | Same `@dropped_on_commit` list (`filter_commit.ex:15`); 176-07 SUMMARY asserts `inbound_id`, `full`, `page` absent from patched URL | closed |
| T-176-16 | Tampering | Draft retention echoing raw invalid values | low | mitigate | Values rendered only via HEEx-escaped option text; commits still pass allow-list normalization in `commit_filters/3` | closed |
| T-176-17 | Information disclosure | Story/gallery fixtures | low | mitigate | Fixture addresses added in phase 176 commits use reserved `northstar.example` / `example.com` domains (RFC 2606) | closed |
| T-176-18 | Repudiation | Stories mistaken for proof of authorization | low | mitigate | `reference/demo_app/storybook/inbound_evidence.story.exs:60` "Static rendering only. Reveal is not connected to authorization."; authorization proven on connected routes (P4/P5) | closed |
| T-176-19 | Information disclosure | Inbound failed-read panels | medium | mitigate | `inbound_live_test.exs:388,439,3274` `refute html =~ "synthetic inbound/timeline connection failure"`; ReadResult wrapper unchanged | closed |
| T-176-20 | Repudiation | Stale or empty population after failure (Inbound) | medium | mitigate | P7 Inbound case (`phase176_prohibition_contract_test.exs:402-427`) | closed |
| T-176-21 | Repudiation | Prohibition contract vacuity | medium | mitigate | "detectors have teeth (fail-first proof)" describe block P1-P8 (`phase176_prohibition_contract_test.exs:44-148`); 176-10 SUMMARY records one source mutation per prohibition | closed |
| T-176-22 | Tampering | Mutations left in library source | medium | mitigate | `git status --porcelain mailglass_admin/lib mailglass/lib mailglass_inbound/lib` empty at audit time (2026-10-28) | closed |
| T-176-23 | Repudiation | EvidenceCard facts (unknown rendered as a number) | medium | mitigate | P6 "unknown payload size and header count never render as zero" component + live tests (`phase176_prohibition_contract_test.exs:336-374`) | closed |
| T-176-24 | Information disclosure | Facts list in redacted state | low | mitigate | Facts `<dl>` exposes sizes, counts, provider, time and `safe_verification_status/1` only (`evidence_card.ex:~100-121`); raw `<pre>` `:revealed`-only (T-176-08) | closed |
| T-176-25 | Denial of service | Debounced search commits | low | accept | See Accepted Risks AR-176-02 | closed |
| T-176-26 | Information disclosure | Reveal telemetry (re-proves T-176-10 from plan 176-03) | medium | mitigate | P5 (`phase176_prohibition_contract_test.exs:312-334`) for `:granted` and `:denied`; `telemetry_violations/1` (:531) requires keys exactly `[:outcome, :record_id, :tenant_id]` and no `@` in any value | closed |
| T-176-27 | Information disclosure | `evidence_card.ex` raw_source/1 selector (gap 176-11) | medium | mitigate | `defp raw_source/1` (`inbound/evidence_card.ex:196`) keeps raw_payload first, so revealed bytes are unchanged; `<pre>` still `:revealed`-only; P4/P5 green | closed |
| T-176-28 | Tampering | Payload size fact integrity (gap 176-11) | low | mitigate | `payload_byte_size/1` and `raw_payload_text/1` both derive from `raw_source/1` (:186, :243); P9 (`phase176_prohibition_contract_test.exs:525`) mutation-proven (176-14) | closed |
| T-176-29 | Tampering | `copy_value/1` aria-label interpolation (gap 176-12) | medium | mitigate | `aria-label={"Copy #{@label}: #{@value}"}` is a HEEx-escaped attribute (`components.ex:1615`); hostile-value test (`components_test.exs:609`); P10 | closed |
| T-176-30 | Information disclosure | Address in the accessible name (gap 176-12) | low | accept | See Accepted Risks AR-176-03 | closed |
| T-176-31 | Tampering | `normalize_window_filter/2` blank branch (gap 176-13) | low | mitigate | Only blank values default to 168; positive-integer parse and `@max_window_hours` bound kept (`operator_live.ex:51,2630`); oversized-draft error asserted; P11 | closed |
| T-176-32 | Information disclosure | PubSub-driven status announcements (gap 176-13) | low | mitigate | `refresh_visible_state/1` restores `results_status_text` (`operator_live.ex:1233-1243`); PubSub status test in `operator_live_test.exs` | closed |
| T-176-33 | Repudiation | P9..P13 contract vacuity (gap 176-14) | medium | mitigate | Teeth case per detector plus one recorded red source mutation per prohibition (176-14 SUMMARY); describes at `phase176_prohibition_contract_test.exs:525-690` | closed |
| T-176-34 | Tampering | Mutations left in library source (gap 176-14) | medium | mitigate | `git status --porcelain mailglass_admin/lib` empty at audit time (2026-10-28, after the gap round) | closed |
| T-176-35 | Tampering | `enum_options/2` reflecting a raw URL value (gap 176-15) | medium | mitigate | "Not applied: " option built as HEEx option text/value (`operator/filters_form.ex:100`, `inbound/filters_form.ex:115`); encoding tests (`operator_live_test.exs:4144`, `inbound_live_test.exs:3179`) | closed |
| T-176-36 | Repudiation | URL note provenance labelling (gap 176-15) | medium | mitigate | `filter_url_invalid` assigned only in `handle_params/3` (`operator_live.ex:193`, `inbound_live.ex:226`) and drives the note (:1009, :792); P13 mutation-proven | closed |
| T-176-SC | Tampering | npm/hex installs (all plans) | high | mitigate | No `mix.lock`, `package.json` or `package-lock.json` in any `(176-NN)` commit (`git log --grep="(176-"` file sweep empty); `@axe-core/playwright` pre-existing dev dep | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-176-01 | T-176-03 | Search values round-trip unchanged per UI-SPEC; the existing tenant-scoped read model bounds the query; no new length limit added silently. Low severity, accepted at plan time (176-01-PLAN). | Plan-time disposition (176-01) | 2026-10-28 |
| AR-176-02 | T-176-25 | At most one synchronous tenant-scoped read per 300 ms debounce window per operator; D-04 removed the extra provider-options read from the change path. Low severity, accepted at plan time (176-06-PLAN). | Plan-time disposition (176-06) | 2026-10-28 |
| AR-176-03 | T-176-30 | The address in the accessible name is already the visible text on the same authorized page (INUX-05); DOM-only, no telemetry path (P5 green). Low severity, accepted at plan time (176-12-PLAN). | Plan-time disposition (176-12) | 2026-10-28 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-28 | 27 | 27 | 0 | gsd-secure-phase (execute-phase security step, L1 grep-depth; `phase176_prohibition_contract_test.exs` run: 24 tests, 0 failures) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-28

## Security Audit 2026-10-28

| Metric | Count |
|---|---|
| Threats found | 37 |
| Closed | 37 |
| Open | 0 |
