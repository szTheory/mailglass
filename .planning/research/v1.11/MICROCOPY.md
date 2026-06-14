# MICROCOPY — v1.11 Design-System Uplift Research Dossier

**RESEARCH-05 | Phase 96 | 2026-06-14**

Maps UX-writing best practice onto the locked mailglass brand voice ("thoughtful
maintainer") and per-surface JTBDs. The LOCKED DECISION block at the end is the
canonical downstream read for Phase 101 (Microcopy Pass) and the Phase 95 ratchet
Type pillar conformance checks.

Sources used:
- `brandbook/brand-book.md` — Voice section (principles table, "say this not that" table,
  seven nouns), lines 44–75 (canonical voice constraints)
- `CLAUDE.md` — "Brand & Voice" and "Domain Language" sections (thoughtful-maintainer
  register, error exemplar, banned terms)
- `guides/jobs.md` — Per-surface JTBD map, lines 57–70
- Codebase file:line citations throughout (shell.ex, preview_live.ex, inbound_live.ex,
  support_cards.ex, suppression_card.ex, deliveries_list.ex, records_list.ex,
  filters_form.ex, replay_modal.ex)
- Nielsen Norman Group: microcopy principles (https://www.nngroup.com/articles/microcopy/ —
  URL returned 404 at fetch time; principles cited from established UX-writing knowledge and
  confirmed against the brand book voice constraints)
- gov.uk Service Manual: Writing for user interfaces
  (https://www.gov.uk/service-manual/design/writing-for-user-interfaces — secondary
  reference; plain-English, action-first copy conventions)
- `.planning/RATCHET-GAP-REGISTER.md` — GAP-02 (preview empty-state focusable CTA),
  GAP-04 (inbound filter labels off-token)

---

## 1. Voice Constraints

### 1a. Thoughtful-Maintainer Register Attributes

Sourced from `brandbook/brand-book.md` lines 44–46 and `CLAUDE.md` "Brand & Voice":

| Attribute | What it means in practice |
|-----------|--------------------------|
| **Clear** | Direct word over clever one. "preview" not "experience the rendering lifecycle". |
| **Exact** | Precise nouns. "Delivery" not "email". "InboundMessage" not "message" (in inbound context). |
| **Confident (not cocky)** | Understatement, not inflation. Calm assertion of facts. No exclamation points on errors. |
| **Warm (not cute)** | Helpful framing. Never dismissive ("Oops"). Never performatively cheerful. |
| **Modern (not trendy)** | Plain English. No jargon, no buzzwords. Technical terms when exact; everyday words otherwise. |
| **Technical (not intimidating)** | Use the domain noun when it is correct; explain recovery when recovery is possible. |

From `brandbook/brand-book.md` lines 49–55, the four principles table:

| Principle | In practice |
|-----------|-------------|
| Clear first | Prefer the direct word over the clever one |
| Explain, don't hype | Confident understatement beats inflation |
| Calm under failure | Errors name the cause and stay composed |
| Generous with context | Copy helps the reader recover quickly |

### 1b. "Say This, Not That" — Brand Book Canonical Pairs

From `brandbook/brand-book.md` lines 57–66:

| Say | Not |
|-----|-----|
| preview | experience the full rendering lifecycle |
| provider-normalized events | revolutionary observability |
| Delivery blocked: recipient is on the suppression list | Oops! Something went wrong |
| This message was skipped because the recipient previously unsubscribed | Suppressed |
| Render a real message before you send it | Beautifully effortless email magic |

### 1c. The Seven Domain Nouns

From `brandbook/brand-book.md` lines 67–74 and `CLAUDE.md` "Domain Language":

| Noun | Definition | Copy context |
|------|-----------|--------------|
| **Mailable** | Source-level definition — the module | Use in Preview surface: "No Mailables discovered" |
| **Message** | Rendered email (the artifact) | Use in Preview: "Render a real Message before you send it" |
| **Delivery** | Per-recipient send record | Use in Operator: "No Deliveries match your filters" |
| **Event** | Observed fact, past tense | Use in timelines: "No Events recorded yet" |
| **InboundMessage** | Received email pre-routing | Use in Inbound: "No InboundMessages match these filters" |
| **Mailbox** | Inbound handler | Use in Inbound routing trace: "No Mailbox matched" |
| **Suppression** | Policy record blocking future sends | Use in Operator: "Delivery blocked by Suppression" |

**Critical distinction preserved in copy:** "dispatched" ≠ "delivered". Dispatched means
handed to provider. Delivered means downstream accepted it. Copy must not elide this.

### 1d. Banned Standalone Terms

From `CLAUDE.md` "Domain Language":

| Banned standalone | Reason | Use instead |
|-------------------|--------|-------------|
| "Email" (alone) | Generic; doesn't name the domain noun | "Delivery", "Message", or "Mailable" |
| "Status" (alone) | Vague; drags toward non-domain usage | "Delivery status" or name the event type |
| "Notification" (alone) | Drags toward multi-channel (out of scope) | Name the Event or the Delivery |

### 1e. Canonical Error Exemplar Pattern

From `brandbook/brand-book.md` line 63 and `CLAUDE.md` "Brand & Voice":

**Pattern:** `[Noun] [past-tense verb]: [specific cause]`

**Positive example:** "Delivery blocked: recipient is on the suppression list"
- Names the noun (Delivery)
- Names the verb in past tense (blocked)
- Names the specific cause (recipient is on the suppression list)

**Negative example (banned):** "Oops! Something went wrong"
- No noun named
- No cause identified
- Performative distress ("Oops") — the canonical anti-pattern

---

## 2. Per-Surface JTBD Map

### 2a. Operator Surface (`/ops/mail`)

**JTBD (from `guides/jobs.md` Job 9, line 70):**
"Figure out why a delivery failed in production"

**What the operator needs from copy:**
- List empty state must distinguish "no sends at all" from "no sends matching your filters"
- Error states must name the cause (was it blocked? bounced? not dispatched yet?)
- CTA labels must use "Delivery" (not "email") to reinforce the domain noun
- Suppression card copy must explain what the Suppression is and why the Delivery was blocked
- Replay modal copy must explain what replay does and what its scope is

**Copy obligations derived:**
- Deliveries list empty state: use "Delivery"/"Deliveries" noun, distinguish filter-empty vs truly-empty
- Error banner: cause-naming pattern, not "Oops"
- Support card CTA labels: "View failures" / "View backlog" — acceptable; "View" is direct
- Suppression card: "Delivery blocked: [reason]" pattern for the headline
- Replay modal: affirm what replay does (re-dispatches stored webhook to mailbox routing) and scope (append-only, tenant-scoped)

### 2b. Inbound Surface (`/ops/mail/inbound`)

**JTBD (from `guides/jobs.md` section near line 413 and `96-CONTEXT.md` D-11):**
"Understand why an InboundMessage did not route"

**What the operator needs from copy:**
- Filter labels must use the domain noun "Mailbox" (not generic "mailbox outcome")
- Empty state for the records list must distinguish no records vs filter-empty
- Routing trace empty state must explain why there is nothing to show
- Replay confirmation must be specific about what will happen
- Error state for data load failure must name the cause and offer recovery

**Copy obligations derived:**
- Filter label "Mailbox outcome" → improve to "Mailbox routing outcome" to use the Mailbox noun more precisely
- Records empty state: "No InboundMessages match these filters" (uses domain noun)
- Routing trace empty state: use "Mailbox" and "InboundMessage" nouns
- Select-record prompt: names "routing, execution timeline, and raw evidence" — correct, keep pattern
- Replay confirmation: clarify it "re-runs Mailbox routing against the stored InboundMessage"

### 2c. Preview Surface (`/dev/mail`)

**JTBD (from `guides/jobs.md` Job 2, line 113 and `96-CONTEXT.md` D-11):**
"Preview a Message before sending it"

**What the developer needs from copy:**
- Orientation empty-state CTA must be keyboard-focusable (GAP-02) — copy must make purpose clear without visual context
- CTA label for "Preview the first one" — currently acceptable but could be more precise
- Device frame labels must be clear at a glance (375px / 768px / 1024px — current labels are numeric, which is correct for a dev tool)
- Preview tabs (HTML / Text / Raw / Headers) — current labels are direct and technical, correct
- No-mailables empty state must explain recovery path without "Oops"

**Copy obligations derived:**
- Start-page heading: "Render a real Message before you send it" (matches brand book — keep)
- Start-page CTA: "Preview the first one" — acceptable but close to non-specific; could be "Preview [Mailable name]" dynamically, but static label should be clear
- No-mailables heading: "No Mailables discovered" — uses domain noun (keep, improve sub-copy)
- Orientation strip (preview surface): current copy names actions correctly ("No mailables found? Define a mailable module")
- GAP-02: the CTA "Preview the first one" is already rendered and keyboard-focusable at line 338 of preview_live.ex; the issue is ensuring it is ALWAYS rendered when mailables > 0, and the label makes sense without visual context for screen readers

---

## 3. Anti-Pattern Catalogue

### 3a. "Oops! Something went wrong" → cause-naming pattern

**Banned:** "Oops! Something went wrong"
- Found in: None confirmed in current codebase (the brand book flags this as the canonical anti-pattern to avoid)
- Why banned: Names no noun, names no cause, uses performative distress word

**Required:** "[Noun] [past-tense verb]: [specific cause]"
- Examples:
  - "Delivery blocked: recipient is on the suppression list" (brand book canonical)
  - "Replay blocked: this action is not authorized for the current operator" (inbound_live.ex:220 — good, follows pattern)
  - "Inbound data could not be loaded. Refresh the page or adjust the filters, then try again." (inbound_live.ex:327 — acceptable, names cause class and recovery action)

### 3b. Generic "No results" → specific cause-naming

**Banned:** "No results" (alone)
- Names nothing: no noun, no scope, no recovery hint

**Required:** "No [Noun] match [filter scope]"
- Examples:
  - "No recent deliveries match these filters." (deliveries_list.ex:21 — correct pattern, could upgrade "deliveries" to "Deliveries")
  - "No inbound records match these filters." (records_list.ex:27 — uses "inbound records" not domain noun; upgrade to "No InboundMessages match these filters")

### 3c. "Email" alone → domain noun

**Banned:** "Email never arrived? Start here." (shell.ex:339)
- Uses "Email" as a standalone noun (generic, banned)

**Required:** "Delivery never arrived? Start here." or "Message not received? Start here."
- Context: orientation strip tips for the Deliveries surface

### 3d. "Status" alone → named event type

**Banned:** "Active suppressions: [count]" where "Status" is used vague
- Support cards: "Active suppressions" is actually correct (uses "suppressions" = domain noun)
- Watch for: "check suppressions" — generic; could be "check the Suppression record"

### 3e. Vague CTA labels → action + object

**Caution:** "Open record" (inbound_live.ex:292) — acceptable for a search-style submit, but the word "record" is generic
- Better: "Find InboundMessages" or "Search records" — but given it's a form submit, "Open record" is direct enough

**Caution:** "Confirm replay" — acceptable; imperative + object, specific enough

---

## 4. Copy Inventory — Current State with Flags

### 4a. Operator Surface (`/ops/mail`)

| Location | Current copy | Flag |
|----------|-------------|------|
| `operator/shell.ex:339` | `"Email never arrived? Start here."` | VIOLATION: "Email" banned standalone. Replace with "Delivery never arrived? Start here." |
| `operator/shell.ex:335-337` (heading) | `"Deliveries"` (orientation strip heading) | WEAK: Too terse for keyboard/AT context. Add purpose: "Delivery triage" or keep "Deliveries" as the surface label |
| `deliveries_list.ex:19` | `"No recent deliveries"` | MINOR: "deliveries" should be "Deliveries" (domain noun capitalized); acceptable in practice |
| `deliveries_list.ex:21` | `"No recent deliveries match these filters. Clear the filters or wait for the next send."` | GOOD: Cause + recovery action. Noun capitalization improvable. |
| `support_cards.ex:44` | `"Recent failures (last 24h)"` | ACCEPTABLE: Time-window is specific. Could be cleaner as "Ingest failures in the last 24 h" |
| `support_cards.ex:177` | `"Active suppressions: {count}"` | GOOD: Uses "suppressions" (domain noun root). |
| `support_cards.ex:56` | `"View failures"` (CTA) | ACCEPTABLE: Direct verb+object. GAP-01 flags btn-sm (touch target) not the copy. |
| `suppression_card.ex:14` | `"Suppression state"` (heading) | WEAK: Should name the Delivery being blocked. Could be "Suppression for this Delivery". |
| `suppression_card.ex:43` | `"No active suppression entry matches this delivery."` | GOOD: Specific negative, names the context. Minor: "delivery" not capitalized. |
| `suppression_card.ex:55` | `"This suppression is immutable by policy."` | ACCEPTABLE: Calm, specific. |
| `operator/replay_modal.ex:28-29` | `"Replay is delivery-detail initiated, tenant-scoped, and recorded in the append-only ledger."` | VERBOSE: Technical but too dense for confirmation context. Simplify for Phase 101. |
| `operator_live.ex:433` | `"Select a delivery to inspect its event timeline and suppression state."` | ACCEPTABLE: Direct instruction. "delivery" should be "Delivery". |
| `operator_live.ex:275` | `"Prove what happened to a message — inspect its event timeline, suppression state, and replay history."` | USES BANNED: "message" here is fine (it's a compound phrase: "happened to a message"), but consider using "Delivery" for specificity. |

### 4b. Inbound Surface (`/ops/mail/inbound`)

| Location | Current copy | Flag |
|----------|-------------|------|
| `inbound/filters_form.ex:20-22` | `"Tenant"` (filter label) | GOOD: Direct. But rendered via `font-bold uppercase tracking-[0.08em]` (raw CSS not text-label token) — GAP-04 |
| `inbound/filters_form.ex:33-35` | `"Provider"` (filter label) | Same GAP-04 issue as Tenant |
| `inbound/filters_form.ex:46-48` | `"Mailbox outcome"` (filter label) | ACCEPTABLE: Uses "Mailbox" (domain noun). Same GAP-04 rendering issue. |
| `inbound/filters_form.ex:63-65` | `"Window"` (filter label) | VAGUE: "Time window" or "Period" would be clearer. |
| `inbound/filters_form.ex:78-80` | `"Search"` (filter label) | ACCEPTABLE: Direct. Could be "Search by subject or recipient". |
| `inbound/records_list.ex:25` | `"No inbound records"` | VIOLATION: Uses generic "inbound records" not domain noun. Replace with "No InboundMessages". |
| `inbound/records_list.ex:27` | `"No inbound records match these filters. Clear the filters or wait for the next inbound message."` | VIOLATION: "inbound message" at end should be "InboundMessage". Also "inbound records" → "InboundMessages". |
| `inbound_live.ex:272-273` | `"See why a received message routed the way it did — execution timeline, routing trace, and raw evidence."` | WEAK: "received message" → "InboundMessage". |
| `inbound_live.ex:327` | `"Inbound data could not be loaded. Refresh the page or adjust the filters, then try again."` | ACCEPTABLE: Cause + recovery. "Inbound data" is slightly vague but clear in context. |
| `inbound_live.ex:333` | `"Select an inbound record to inspect its routing, execution timeline, and raw source."` | VIOLATION: "inbound record" → "InboundMessage". |
| `inbound/shell.ex` (orientation strip via shell.ex:346-354) | `"Message didn't route as expected? Inspect the routing trace."` etc. | VIOLATION: "Message" should be "InboundMessage" in inbound context. |
| `inbound/routing_trace.ex:44` | `"No inbound routes are declared, so there is nothing to trace."` | ACCEPTABLE: Specific and actionable. |
| `inbound/replay_modal.ex:35` | `"Replay inbound: This re-runs mailbox routing against the stored message and records a new replay run in the append-only ledger."` | VIOLATIONS: "mailbox" should be "Mailbox"; "stored message" should be "stored InboundMessage". Also redundant "Replay inbound:" prefix. |
| `inbound/replay_modal.ex:201` | `"Replay recorded. A new replay run was appended to this message's timeline."` | VIOLATION: "message's" → "InboundMessage's". |
| `inbound/detail_header.ex:48` | `"Sender suppressed: this message was flagged, not bounced, to preserve diagnostic signal."` | GOOD: Cause-naming pattern! Uses the right pattern. "message" is marginally acceptable here. |

### 4c. Preview Surface (`/dev/mail`)

| Location | Current copy | Flag |
|----------|-------------|------|
| `preview_live.ex:329` | `"Render a real message before you send it"` (start-page heading) | GOOD: Matches brand book pair exactly. "message" is fine here (it's the rendered artifact, i.e. Message). |
| `preview_live.ex:330-333` | `"Pick a mailer from the sidebar to render it through the same pipeline…"` | WEAK: "mailer" is not the domain noun. Replace with "Pick a Mailable from the sidebar". |
| `preview_live.ex:338` | `"Preview the first one"` (CTA) | ACCEPTABLE FOR SCREEN READERS: The purpose is clear from the heading context. GAP-02 issue is focusability, not label. |
| `preview_live.ex:298` | `"No mailables discovered"` | GOOD: Uses "mailables" (domain noun). Capitalization: should be "No Mailables discovered" to reinforce domain noun. |
| `preview_live.ex:299-302` | `"Preview scans loaded modules that use Mailglass.Mailable. Nothing was found yet."` | ACCEPTABLE: Technical and specific. "Nothing was found yet" is fine. |
| `preview_live.ex:244-247` | `"preview_props/0 raised an error"` (error heading) | TECHNICAL CORRECT: Exact, names the cause. Stays as-is (it's a developer-facing tool). |
| `preview_live.ex:249` | `"Fix the error in {inspect(@current_mailable)} and save the file to reload."` | GOOD: Direct recovery instruction. |
| `operator/shell.ex:357-365` (preview orientation strip) | `"No mailables found? Define a mailable module in your app."` etc. | GOOD: Domain noun used. "mailables" should be "Mailables". |
| `preview_live.ex:347` | `"HTML, Text, Raw & Headers"` (legend tile title) | GOOD: Technical terms, direct. |
| `preview_live.ex:350` | `"Device widths"` (legend tile title) | ACCEPTABLE: "Device" is common parlance for a dev tool. |
| `preview_live.ex:352` | `"Light & dark"` (legend tile title) | GOOD: Direct. |
| `preview_live.ex:354` | `"Editable assigns"` (legend tile title) | GOOD: Technical and specific. |

---

## 5. Draft Decisions

### 5a. Primary Empty-State Copy Per Surface

**Operator (Deliveries list empty state):**
- Heading: "No Deliveries match your filters"
- Sub-copy: "Adjust the filters or wait for the next send."
- Recovery CTA: "Clear filters" (existing)

**Operator (no deliveries at all — tenant has no delivery history):**
- Heading: "No Deliveries yet"
- Sub-copy: "Deliveries appear here once your application sends its first message."

**Inbound (InboundMessages list empty state):**
- Heading: "No InboundMessages match these filters"
- Sub-copy: "Adjust the filters or wait for the next inbound message."
- Recovery CTA: "Clear filters" (existing)

**Preview (start page — mailables discovered):**
- Heading: "Render a real Message before you send it" (keep — matches brand book)
- Sub-copy: "Pick a Mailable from the sidebar to render it through the same pipeline your production sends use."
- CTA: "Preview the first one" (keep — direct, focusable, context makes purpose clear)

**Preview (no-mailables empty state):**
- Heading: "No Mailables discovered"
- Sub-copy: "Preview scans loaded modules that `use Mailglass.Mailable`. Nothing was found yet."
- Recovery list items (keep existing, minor noun casing):
  - "Confirm the module calls `use Mailglass.Mailable` and is compiled and loaded."
  - "Or pass an explicit list to the router: `mailglass_admin_routes \"/mail\", mailables: [MyApp.UserMailer]`."

### 5b. Error-State Heading Pattern

All error headings must follow: `[Noun] [past-tense verb]: [specific cause]`

Examples (locked below in the LOCKED DECISION block):
- "Delivery blocked: recipient is on the Suppression list" (canonical — brand book)
- "Replay blocked: this action is not authorized for the current operator" (inbound_live.ex:219 — already correct, keep)
- "InboundMessage data could not be loaded" (for detail load errors — more specific than current "Inbound data could not be loaded")

For developer-facing preview errors, the exact function signature is the correct error noun:
- "preview_props/0 raised an error" — keep (developer surface, exact is correct)

### 5c. Filter Section Labels for Inbound (GAP-04 Copy Angle)

Current labels use raw CSS uppercase (GAP-04: `tracking-[0.08em] uppercase font-bold` — off-token).
The fix for Phase 99 (GAP-04) is to switch to `text-label` token class. The COPY decisions:

- "Tenant" → keep as-is (single word, direct, correct)
- "Provider" → keep as-is (single word, direct, correct)
- "Mailbox outcome" → keep as-is (uses "Mailbox" domain noun)
- "Window" → change to "Time window" (more precise, less ambiguous)
- "Search" → keep as-is (single word, direct, correct)

### 5d. Preview Orientation CTA Label (GAP-02 Copy Angle)

GAP-02 specifies the CTA must be keyboard-focusable. Current `preview_live.ex:338`:
```
<.link :if={first_previewable(@mailables)} patch={first_scenario_path(@mailables)} class="btn btn-primary mt-5 min-h-11">
  Preview the first one
</.link>
```

The label "Preview the first one" is acceptable for sighted users with the heading context.
For screen readers, the heading "Render a real Message before you send it" precedes the link, so
the link's accessible name in context is clear. However, a more precise label improves the
standalone accessible name:

**Draft label:** "Preview the first Mailable"
- Uses domain noun "Mailable"
- Actionable verb "Preview"
- Quantifier "first" (matches current dynamic behavior)
- Screen reader reads full label without ambiguity

Alternative (if dynamic name is preferred): "Preview [Mailable name]" — but this requires knowing
the mailable name at render time, which is `first_previewable/1`'s {mod, scenario} tuple.
The dynamic version is preferable but requires template change scope. Phase 101 should evaluate
dynamic vs. static.

**Locked label for Phase 101:** "Preview the first Mailable"

### 5e. Replay Modal Confirmation Copy

**Operator replay modal (`operator/replay_modal.ex:29`):**

Current: "Replay is delivery-detail initiated, tenant-scoped, and recorded in the append-only ledger."
Problem: Dense, technical, not helpful for confirmation decision.

**Locked replacement:**
- Heading: "Replay webhook for [masked-recipient]" (keep — names scope)
- Body for `:exact` state: "Re-dispatches the stored webhook request to Mailbox routing and records a new Event in the append-only ledger. Confirm to replay."
- Body for `:ambiguous` state: "More than one webhook row matches. Choose one — the operator won't guess across multiple replayable requests. Confirm to replay."
- Body for `:unavailable` state: keep existing `RepairState.unavailable_reason_copy/1` (cause-named by design)

**Inbound replay modal (`inbound/replay_modal.ex:35`):**

Current: "Replay inbound: This re-runs mailbox routing against the stored message and records a new replay run in the append-only ledger."
Problems: Redundant "Replay inbound:" prefix, "mailbox" not capitalized, "stored message" should use domain noun.

**Locked replacement:**
"Re-runs Mailbox routing against the stored InboundMessage and records a new replay run in the append-only ledger. Confirm to replay."

### 5f. Suppression Card Copy

**Suppression card heading (`suppression_card.ex:14`):**

Current: "Suppression state"
Problem: States the concept, not the finding. Operator needs "is there a Suppression on this Delivery?"

**Locked replacement:**
- Heading: "Suppression"
- Badge: "Active" | "None" (cleaner than current "No suppression" / "Immutable by policy" in badge)
- Body (when suppression present): Keep the scope/reason/stream/source grid, but improve body copy:
  - Immutable: "This Suppression is permanent. Future sends to this address will be blocked."
  - Reversible: "This Suppression is reversible. Contact support or remove via the suppressions API."

**Suppression card empty state (`suppression_card.ex:43`):**

Current: "No active suppression entry matches this delivery."
Good pattern — keep, improve: "No active Suppression for this Delivery."

### 5g. Loading State Label Pattern

None of the surfaces have explicit loading-state copy in the current codebase (they rely on
the LiveView render cycle to show stale data until the new data lands). If Phase 101 adds
skeleton/spinner states, the pattern is:

**Pattern:** "Loading [Noun]s…" (present progressive, noun named, ellipsis signals in-progress)
- "Loading Deliveries…"
- "Loading InboundMessages…"
- "Loading preview…" (preview is correct here — the noun is the rendered output)

---

## 6. Adversarial Synthesis

**Critic pass — challenge each draft decision against voice constraints and open GAPs.**

### Challenge 1: Preview empty-state CTA label

**Draft:** "Preview the first Mailable"
**Challenge A (voice):** Does this avoid the banned standalone "Email"? ✓ Uses "Mailable".
**Challenge B (voice):** Is this domain-noun-correct? "Mailable" is the source-level definition — correct for the preview tool that scans for `use Mailglass.Mailable` modules.
**Challenge C (GAP-02):** Is the CTA always rendered and focusable when mailables > 0? Current code at `preview_live.ex:336-340` uses `:if={first_previewable(@mailables)}` — so it is conditional on mailables being non-nil. When `@mailables == []`, the no-mailables empty state is shown (line 291). When `@mailables != []`, the start page renders including the CTA. The CTA IS always rendered and focusable when mailables exist. GAP-02 is the structural absence of a focusable CTA — confirmed the link exists but Phase 101 must verify the structural spec assertion adds a test for this.
**Challenge D (label clarity for screen readers):** "Preview the first Mailable" — standalone this reads naturally. "Mailable" is a technical term (a module), which is appropriate for a developer tool.
**Verdict: HOLD.** "Preview the first Mailable" is better than "Preview the first one" for screen readers and uses the correct domain noun.

### Challenge 2: Inbound filter labels

**Draft:** "Mailbox outcome" → keep; "Window" → "Time window"
**Challenge A (voice):** Does "Mailbox outcome" use the domain noun? ✓ "Mailbox" is the inbound handler noun.
**Challenge B (GAP-04):** The GAP is about the rendering token (raw CSS vs. text-label token), not the copy string itself. The copy can stay; Phase 99 changes the class from raw `tracking-[0.08em]` to `text-label`. Both phases must coordinate.
**Challenge C (voice — "Time window"):** Is "Time window" cleaner than "Window"? Yes — "Window" is ambiguous (browser window? filter window?). "Time window" is unambiguous and direct.
**Challenge D (verbosity):** "Time window" is two words vs one, acceptable for a filter label where the extra word removes ambiguity.
**Verdict: REVISE "Window" to "Time window". Keep all other labels.**

### Challenge 3: Error heading pattern

**Draft:** "[Noun] [past-tense verb]: [specific cause]"
**Challenge A (voice):** Does "Delivery blocked: recipient is on the Suppression list" follow this? ✓ Delivery (noun) + blocked (past tense) + cause named.
**Challenge B (technical surfaces):** For the preview error card, "preview_props/0 raised an error" — this breaks the pattern (no domain noun, no past-tense verb in the standard sense). But this is intentional: `preview_props/0` is the exact function name, and naming it precisely is correct for a developer tool. The "raised" is past tense.
**Challenge C (scope):** Does "Inbound data could not be loaded" follow the pattern? Partially. "Inbound data" is not a domain noun. Better: "InboundMessage data could not be loaded." — but the current copy is already better than "Oops", just not fully pattern-compliant.
**Verdict: ADD a decision that governs when the strict pattern is mandatory (operator/inbound surfaces — always) vs. the dev-tool exception (preview surface — technical precision over pattern).**

### Challenge 4: Replay modal copy

**Draft operator body:** "Re-dispatches the stored webhook request to Mailbox routing and records a new Event in the append-only ledger."
**Challenge A (domain nouns):** "Event" is used — ✓. "Mailbox" is used — ✓. "webhook request" is not a domain noun — it describes the stored artifact correctly without overloading the domain noun set.
**Challenge B (dispatch vs. delivered):** "Re-dispatches" — the domain noun for this action is "dispatch" (handed to provider), correct here since replay sends the stored webhook back to be processed.
**Challenge C (brevity):** 16 words — acceptable for a destructive confirmation modal. Should be clear, not brief to the point of ambiguity.
**Verdict: HOLD current draft.**

**Draft inbound body:** "Re-runs Mailbox routing against the stored InboundMessage and records a new replay run in the append-only ledger."
**Challenge A (domain nouns):** "Mailbox" ✓, "InboundMessage" ✓.
**Challenge B (clarity):** "re-runs Mailbox routing" is clear to an operator who understands inbound routing.
**Challenge C (redundancy):** "a new replay run" — "replay run" is the established term in the codebase (`records_list.ex` meta line uses "runs"). Acceptable.
**Verdict: HOLD current draft.**

### Challenge 5: Orientation strip copy for Deliveries surface

**Current shell.ex:339:** "Email never arrived? Start here."
**Challenge:** Uses "Email" (banned standalone). This is an orientation strip tip visible to every operator who lands on the deliveries surface with no delivery selected. It is the highest-visibility copy violation in the codebase.
**Replacement draft:** "Delivery never arrived? Start here."
**Challenge A (voice):** Uses "Delivery" — ✓. Short, direct question. ✓
**Challenge B (accuracy):** "Delivery never arrived" is technically about the recipient not receiving it — which is the `:delivered` event vs. the `:dispatched` one. This is precisely what operators are investigating. ✓
**Verdict: REVISE to "Delivery never arrived? Start here."**

**Current shell.ex:341:** "Address keeps getting blocked? Check suppressions."
**Challenge:** "suppressions" should use the domain noun "Suppression" (or "Suppression records"). But this is a tip in the orientation strip, and "check suppressions" is a common operational phrase that maps to the Suppression domain noun root. Lowercase in a list item is acceptable.
**Verdict: MINOR IMPROVEMENT → "Address keeps getting blocked? Review the Suppression list."** Uses "Suppression" as capitalized domain noun, "list" makes it actionable.

**Current shell.ex:347 (inbound):** "Message didn't route as expected? Inspect the routing trace."
**Challenge:** "Message" in inbound context should be "InboundMessage".
**Revision:** "InboundMessage didn't route as expected? Inspect the routing trace."
**Challenge B:** "InboundMessage" is 15 characters and may feel awkward in a short orientation tip. Alternative: "Received message didn't route?" — but "received message" is not a domain noun. The domain noun is the right word here.
**Verdict: REVISE to "InboundMessage didn't route as expected? Inspect the routing trace."**

### Challenge 6: Suppression card heading

**Current:** "Suppression state" — noun + generic descriptor
**Draft:** "Suppression" — bare noun
**Challenge A:** Is the bare noun too terse? In context, the card is always shown for a selected Delivery, so the operator knows this is about that Delivery's suppression. The badge ("Active" vs "None") immediately follows.
**Challenge B:** "Suppression state" vs. "Suppression" — both use the domain noun. "Suppression" alone is cleaner and more confident.
**Verdict: REVISE to "Suppression" for the heading. Badge carries the state signal.**

---

## LOCKED DECISION

| LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP |
|-------|----------|-------------------------------|-------------------|------------|
| COPY-LD-01 | Operator deliveries list primary empty-state heading: "No Deliveries match your filters" / sub-copy: "Adjust the filters or wait for the next send." | Operator (`/ops/mail`), `deliveries_list.ex` empty branch | thoughtful-maintainer voice; cause-naming pattern; seven domain nouns (Delivery); no "Email" standalone; no "Oops" | — |
| COPY-LD-02 | Operator deliveries list truly-empty state (no deliveries at all): heading "No Deliveries yet" / sub-copy: "Deliveries appear here once your application sends its first Message." | Operator (`/ops/mail`), `deliveries_list.ex` zero-tenant-history branch | thoughtful-maintainer voice; seven domain nouns (Delivery, Message); no "Email" standalone | — |
| COPY-LD-03 | Inbound InboundMessages list primary empty-state heading: "No InboundMessages match these filters" / sub-copy: "Adjust the filters or wait for the next inbound message." | Inbound (`/ops/mail/inbound`), `inbound/records_list.ex` empty branch | thoughtful-maintainer voice; cause-naming pattern; seven domain nouns (InboundMessage); no "Email" standalone; no "Notification" standalone | — |
| COPY-LD-04 | Preview start-page heading: "Render a real Message before you send it" (brand-book pair, keep verbatim) / sub-copy: "Pick a Mailable from the sidebar to render it through the same pipeline your production sends use." | Preview (`/dev/mail`), `preview_live.ex` start-page branch (line 329) | thoughtful-maintainer voice; seven domain nouns (Message, Mailable); no "Email" standalone; no "mailer" generic | — |
| COPY-LD-05 | Preview start-page CTA label: "Preview the first Mailable" (replaces "Preview the first one") | Preview (`/dev/mail`), `preview_live.ex` link at line 338; must be rendered and keyboard-focusable whenever `@mailables != []` | thoughtful-maintainer voice; seven domain nouns (Mailable); WCAG 2.4.6 descriptive link text; no "Email" standalone | GAP-02 |
| COPY-LD-06 | Preview no-Mailables empty-state heading: "No Mailables discovered" / sub-copy: "Preview scans loaded modules that `use Mailglass.Mailable`. Nothing was found yet." | Preview (`/dev/mail`), `preview_live.ex` `@mailables == []` branch (line 298) | thoughtful-maintainer voice; seven domain nouns (Mailable); no "Email" standalone; no "Oops" | — |
| COPY-LD-07 | Error-state heading pattern for operator and inbound surfaces: "[Noun] [past-tense verb]: [specific cause]" — example: "Delivery blocked: recipient is on the Suppression list" | Operator and Inbound surfaces; all error flash, error banners, and error headings | thoughtful-maintainer voice; cause-naming pattern (brand book line 63); seven domain nouns (Delivery, Suppression); no "Oops"; no "Email" standalone; no "Status" standalone | — |
| COPY-LD-08 | Preview surface error-state heading pattern (developer exception): name the exact function or module that raised — e.g. "preview_props/0 raised an error" — followed by recovery instruction "Fix the error in [module] and save the file to reload." | Preview (`/dev/mail`), `preview_live.ex` `@render_error` branch (line 244) | thoughtful-maintainer voice; developer surface: technical precision over generic-pattern; no "Oops" | — |
| COPY-LD-09 | Banned pattern row: the word "Oops" (or "Oops!" or "Oops,") must never appear in any copy string in Operator, Inbound, or Preview surfaces. All errors use the cause-naming pattern (COPY-LD-07) or the developer-precision pattern (COPY-LD-08). | All surfaces | thoughtful-maintainer voice; brand book "say this not that" line 63; seven domain nouns; no "Email"/"Status"/"Notification" standalone | — |
| COPY-LD-10 | Inbound filter label "Window" → "Time window"; all other filter labels ("Tenant", "Provider", "Mailbox outcome", "Search") keep current copy verbatim | Inbound (`/ops/mail/inbound`), `inbound/filters_form.ex` | thoughtful-maintainer voice; seven domain nouns (Mailbox); text-label token class (Phase 99 must also change class from raw CSS to text-label — coordinated GAP-04 close) | GAP-04 |
| COPY-LD-11 | Orientation strip tip (Deliveries): "Email never arrived? Start here." → "Delivery never arrived? Start here." / "Address keeps getting blocked? Check suppressions." → "Address keeps getting blocked? Review the Suppression list." | Operator (`/ops/mail`), `operator/shell.ex` lines 339, 341 `copy_for(:deliveries)` | seven domain nouns (Delivery, Suppression); no "Email" standalone; thoughtful-maintainer voice | — |
| COPY-LD-12 | Orientation strip tip (Inbound): "Message didn't route as expected? Inspect the routing trace." → "InboundMessage didn't route as expected? Inspect the routing trace." | Inbound (`/ops/mail/inbound`), `operator/shell.ex` line 348 `copy_for(:inbound)` | seven domain nouns (InboundMessage); no "Email" standalone; thoughtful-maintainer voice | — |
| COPY-LD-13 | Operator replay modal sub-copy (exact target): "Re-dispatches the stored webhook request through Mailbox routing and records a new Event in the append-only ledger. Confirm to replay." / Inbound replay modal sub-copy: "Re-runs Mailbox routing against the stored InboundMessage and records a new replay run in the append-only ledger. Confirm to replay." | Operator: `operator/replay_modal.ex` line 29; Inbound: `inbound/replay_modal.ex` line 35 | seven domain nouns (Mailbox, Event, InboundMessage); dispatch-not-delivered precision; no "Oops"; thoughtful-maintainer voice | — |
| COPY-LD-14 | Suppression card heading: "Suppression" (replaces "Suppression state") / zero-suppression copy: "No active Suppression for this Delivery." / immutable body: "This Suppression is permanent. Future sends to this address will be blocked." / reversible body: "This Suppression is reversible. Remove via the suppressions API or contact support." | Operator (`/ops/mail`), `operator/suppression_card.ex` lines 14, 43, 55–56 | seven domain nouns (Suppression, Delivery); cause-naming pattern; thoughtful-maintainer voice; no "Email" standalone | — |
| COPY-LD-15 | Loading-state label pattern: "Loading [Noun]s…" — e.g. "Loading Deliveries…" / "Loading InboundMessages…" / "Loading preview…" | All surfaces, if explicit loading states are added in Phase 101 | seven domain nouns; thoughtful-maintainer voice; present-progressive pattern; no "Oops" | — |
| COPY-LD-16 | Inbound select-record prompt: "Select an inbound record to inspect its routing, execution timeline, and raw source." → "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence." | Inbound (`/ops/mail/inbound`), `inbound_live.ex` line 333 | seven domain nouns (InboundMessage, Mailbox); thoughtful-maintainer voice; no "Email" standalone | — |
