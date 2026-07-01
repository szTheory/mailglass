# Phase 121: Inbound surface redesign - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 9 source + 4 test
**Analogs found:** 13 / 13 (every change has a shipped Phase 120 / in-repo counterpart)

> **Core thesis for the planner:** Inbound is "a deliberate clone of Deliveries"
> (the `InboundLive` docstring calls itself a "clone, not a refactor"). For almost
> every file changed here, the closest analog is its **already-shipped Deliveries
> counterpart from Phase 120** — mirror it verbatim, do not re-author. The only
> genuinely-new symbols are: the re-redact `handle_event`, the `reveal_raw`
> telemetry emit, and the replay-modal Tab focus-trap + double-submit lock (which
> get applied to BOTH surfaces). Everything else is a render-condition change reusing
> existing classes/primitives.

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | LiveView (render + handlers) | request-response / event-driven | `operator_live.ex:489-672` (shipped 120 shape) | exact (sibling clone) |
| `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` | component | CRUD / transform | `operator/deliveries_list.ex:39-89` | exact (parallel primitive) |
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | component | transform (disclosure UI) | itself (3-state machine) + ARIA-disclosure APG pattern | role-match (no in-repo disclosure analog) |
| `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` | component (modal) | request-response | `operator/replay_modal.ex` (lockstep sibling) | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component (modal) | request-response | `inbound/replay_modal.ex` (lockstep sibling) | exact |
| `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (`orientation_strip/1`) | component (chrome) | render-only | already shared by both surfaces; 120 changed only its *condition* | exact |
| `mailglass_admin/e2e/operator.spec.js` | test (e2e) | n/a | `operator.spec.js:402-456` (Deliveries judgment gate) + `:462-476` (paired split) | exact |
| `mailglass_admin/e2e/structural.spec.js` (~1103-1264) | test (e2e) | n/a | itself (verify-green; `1176-1177` is the locked PII boundary) | exact |
| `mailglass_admin/e2e/flows.spec.js` (inbound replay ~396) | test (e2e) | n/a | existing replay-modal flow assertions | role-match |
| `reference/demo_app/assets/e2e/persona-screenshots.spec.js:69,120-122` | test (visual) | n/a | existing `operator-inbound` cells (re-shoot, no new cells) | exact |
| `mailglass_admin/test/.../*inbound*test.exs` | test (ExUnit) | n/a | matching Deliveries ExUnit updated in 120 | role-match |

---

## Pattern Assignments

### `inbound_live.ex` — render `else` branch → top-level `cond` (D-01..D-06)

**Analog:** `operator_live.ex:488-522` (the shipped Phase 120 no-data / populated split).

**The shipped Deliveries shape to mirror onto `inbound_live.ex:382` else-branch**
(`operator_live.ex:488-510`):

```elixir
      <% else %>
        <%= cond do %>
          <% @deliveries == [] and not filters_active?(@filter_params) and @filter_errors == %{} -> %>
            <%!-- Genuine no-data: a single calm pane only — operator-empty-truly + orientation strip.
                  The filters toolbar, the Open-delivery CTA, and the entire master-detail grid (and
                  therefore the "Select a delivery…" helper nested inside it) are all withheld.
                  An in-progress invalid filter submission (@filter_errors non-empty) is NOT genuine
                  no-data — the toolbar stays so the operator sees the recovery copy and Clear-filters. --%>
            <section
              data-testid="operator-deliveries-empty-pane"
              class="card min-w-0 rounded-box border border-base-300 bg-base-200 p-0"
            >
              <DeliveriesList.deliveries_list
                deliveries={[]}
                ...
                selected_delivery={nil}
                filters_active?={false}
              />
            </section>
            <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
          <% true -> %>
            <%!-- filters toolbar + health strip + master-detail grid --%>
```

**Inbound port (verbatim mirror — the discriminator already exists):**
- Genuine no-data guard = `@records == [] and not filters_active?(@filter_params) and @filter_errors == %{}`
  (the `:truly_empty` case; `empty_state_for/2` at `inbound_live.ex:659-670`). **Keep the
  `@filter_errors == %{}` guard** — the 120 trap is misclassifying an in-flight invalid
  filter as no-data.
- No-data pane = `<RecordsList.records_list records={[]} empty_state={:truly_empty} ... selected_record={nil} />`
  inside a `data-testid="inbound-deliveries-empty-pane"`-style section, **+** the empty-pane-only
  `<MailglassAdmin.Operator.Shell.orientation_strip surface={:inbound} />`.
- **Withhold** in no-data: the `inbound-filters` section (`:383-419`), the health strip
  (`Overview.overview`, `:421-426`), and the entire `inbound-master-detail` grid (`:428-524`).
- `true ->` branch keeps filters toolbar + health strip + master-detail (current `:383-524` body).

**D-04 — remove the redundant detail-column orientation strip** (`inbound_live.ex:482-483`):

```elixir
            <% is_nil(@detail) -> %>
              <MailglassAdmin.Operator.Shell.orientation_strip surface={:inbound} />   <%!-- DELETE THIS LINE --%>
              <div
                data-testid="inbound-empty-detail"
                class="card rounded-box border border-base-300 bg-base-200 p-6"
              >
                <h2 class="text-body font-bold text-base-content">
                  Select an InboundMessage to inspect its Mailbox routing, ...
                </h2>
              </div>
```

The shipped Deliveries equivalent (`operator_live.ex:602-615`) has **no** orientation strip in its
`is_nil(@selected_delivery)` branch — it keeps only the "Select a delivery…" helper. Mirror that:
delete line `483`, **keep** the `inbound-empty-detail` helper `484-491`.

**Health-strip gating** — current always-rendered block to move inside the `true ->` branch
(`inbound_live.ex:421-426`):

```elixir
      <div class={["mt-6", @selected_record && "max-md:hidden"]}>
        <Overview.overview summary={@inbound_summary} />
      </div>
```

---

### `inbound_live.ex` — wire the dormant `data_state` (D-09)

**Analog:** `records_list.ex:43-73` (the dormant attr) — the wiring seam is identical to how
`operator_live.ex` does (or, per 120, does NOT yet) pass it. **Note for planner:** grep confirms
*neither* `operator_live.ex` nor `inbound_live.ex` currently passes `data_state=` to its list
component — the attr defaults `nil` (`records_list.ex:45`) and the empty branch falls through
`@data_state == nil and @records == []` (`records_list.ex:74`). D-09 routes
error / permission-denied / stale / disconnected through the **existing** `inbound-detail-error`
branch (`inbound_live.ex:470-481`) and the existing primitive — **verify against the matrix, do not
rebuild**. The error pane already exists:

```elixir
            <% @detail_error -> %>
              <div data-testid="inbound-detail-error"
                   class="card rounded-box border border-error bg-base-100 p-6">
                <Components.icon name="hero-exclamation-circle" class="h-5 w-5 text-error" />
                ...
              </div>
```

Already-built and verified-not-rebuilt in `records_list.ex`: responsive table↔card duality
(`md:block` table `:105` / cards <768), `mask_recipient` (`:142-144`), truncate+`title`
(`:140-145`), `aria-current`/`aria-selected` on rows (`:124-125`), `mg-focus-ring-inset min-h-11`
(`:127`).

---

### `inbound/records_list.ex` — noun copy fix (D-07)

**Analog:** Deliveries kept its copy in 120; this is a one-line noun-discipline fix at
`records_list.ex:365`:

```
- "No records have been recorded yet."
+ "No InboundMessages have been recorded yet."
```

Brandbook noun lock (`brandbook/copy/microcopy.md:48`, `brand-book.md:71`). The card header already
says "Recent InboundMessages" (`inbound_live.ex:448`). No-match copy
(`"No records match the current filters."`) + the `inbound-empty-reset` link stay frozen.

---

### `inbound/evidence_card.ex` — disclosure a11y + re-redact + aria-live (D-11)

**Analog:** the file itself (`evidence_card.ex:31-118`, full 3-state machine read into context). No
in-repo ARIA-disclosure analog exists — this is the closest thing to net-new, but it is
**attribute-only additions on the existing reveal button + one new collapse button reusing existing
classes**.

**Current reveal button** (`evidence_card.ex:42-49`) — add `aria-expanded`/`aria-controls`,
secondary copy line:

```elixir
          <button
            type="button"
            phx-click="reveal_raw"
            data-testid="inbound-evidence-reveal"
            class="btn btn-ghost min-h-11 px-md"
          >
            Reveal raw source
          </button>
```

becomes a true disclosure: `aria-expanded={@reveal_state == :revealed}`,
`aria-controls="inbound-evidence-raw"`, keep `type="button"`, `min-h-11`, `mg-focus-ring`; add the
secondary text **"Contains unredacted PII."**

**Re-redact button** — NEW additive markup in the `:revealed` branch (`evidence_card.ex:90-99`),
reusing `btn btn-ghost min-h-11 px-md` (classes already in the committed bundle):
- `phx-click="re_redact_raw"` (the ONE new `handle_event` — **no fourth state atom**, routes back to
  `:redacted`), copy **"Re-redact raw source"**, returns focus to the reveal button.

**`aria-live` status region** — NEW `role="status" aria-live="polite"` text region (planner's
placement call within `evidence_card.ex`), reusing `text-body`/`text-secondary`. Announces
**"Raw source revealed. This payload contains unredacted PII."** on grant /
**"Raw source re-redacted."** on collapse. Color is **never** the sole signal (WCAG 1.4.1).

**HARD GUARDRAIL (D-10 — do not weaken):** the redacted-by-default invariant. `reveal_state`
defaults `:redacted` and re-sets on every selection/clear — see `inbound_live.ex:100` /
`:565` / `:584`. The IA refactor must NOT hoist the `<EvidenceCard.evidence_card .../>` render
(`inbound_live.ex:517-520`) outside the per-selection reset. The `:denied`/`:redacted` copy at
`evidence_card.ex:105`/`:112` is **verbatim-frozen**.

---

### `inbound_live.ex` — re-redact handler + reveal telemetry (D-11 / D-12, NEW symbols)

**Analog for the handler:** the existing reveal handler (`inbound_live.ex:258-260`):

```elixir
  def handle_event("reveal_raw", _params, socket) do
    {:noreply, assign(socket, :reveal_state, authorize_reveal(socket))}
  end
```

**NEW** `handle_event("re_redact_raw", ...)` mirrors it but assigns `:reveal_state, :redacted`
(no auth call needed — collapsing never widens access).

**Telemetry emit (D-12, genuinely new — `mailglass_admin` has NO telemetry today):** follow the
CLAUDE.md convention `[:mailglass, :domain, :resource, :action, :stop]` and the inbound package's
documented taxonomy (`mailglass_inbound/lib/mailglass_inbound/telemetry.ex:10-31` — full
`:start`/`:stop` spans, PII-free metadata). For a fire-and-forget reveal-outcome count, emit:

```elixir
:telemetry.execute(
  [:mailglass_admin, :inbound, :reveal_raw, :stop],
  %{count: 1},
  %{tenant_id: tenant_id, record_id: record_id, outcome: :granted | :denied}
)
```

**PII rule (CLAUDE.md):** metadata is `tenant_id` / `record_id` / `outcome` ONLY — **never**
`payload` / `body` / `headers` / `recipient` / `email`. Wire the emit inside the existing
`authorize_reveal/1` result path (`inbound_live.ex:944-957`) where `:revealed`→`:granted`,
`:denied`→`:denied` is already computed. Durable persisted audit is DEFERRED.

---

### `inbound/replay_modal.ex` + `operator/replay_modal.ex` — Tab-trap + double-submit (D-14, BOTH surfaces)

**Analog:** the two modals are explicit lockstep siblings (the inbound docstring:
"Sibling of `MailglassAdmin.Operator.ReplayModal`, SIMPLIFIED"). Apply the SAME two fixes to both.

**Already APG-conformant — do NOT regress** (`inbound/replay_modal.ex:29-43`):
`role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `phx-key="Escape"
phx-window-keydown="close_replay"`, scrim (`mg-overlay-scrim`), overscroll
(`mg-overscroll-contain`), reduced-motion-safe `motion-overlay`/`motion-tab-swap`. Initial focus +
focus-restore live in the LiveView via focus sentinels (`inbound_live.ex:527-531`,
`operator_live.ex:656-660`):

```elixir
      <span
        :if={@replay_modal_open?}
        phx-mounted={JS.focus_first(to: "#inbound-replay-modal")}
        phx-remove={JS.focus(to: "#inbound-replay-open-btn")}
      />
```

**Gap 1 — Tab/Shift+Tab focus-trap** (the one unmet APG line; `JS.focus_first` sets initial focus
but does not contain Tab). Claude's discretion: LiveView.JS focus-sentinel spans vs. a scoped Tab
keydown handler — pick the least-surprise, smallest-correct-JS option, **pure Phoenix/LiveView.JS,
no new npm deps**, keep both modals in lockstep.

**Gap 2 — double-submit pending-lock** on the Confirm button. Inbound
(`inbound/replay_modal.ex:64-71`):

```elixir
            <button
              type="button"
              phx-click="confirm_replay"
              data-testid="inbound-replay-confirm"
              class="btn btn-error min-h-11 px-5"
            >
              Confirm replay
            </button>
```

Add `phx-disable-with="Replaying…"` (or `JS.set_attribute(disabled)`) — the same on
`operator/replay_modal.ex:102-110` (`operator-replay-confirm`). Pending label **"Replaying…"**.

**Frozen — do NOT touch:** the replay gate order TENANT → CAPABILITY(`:replay_inbound`) → REPLAY
(`inbound_live.ex:274-322`), the `:no_match`-can-never-replay rule, struct-matched error copy
(`replay_error_copy/1`, `inbound_live.ex:645-657`; CLAUDE.md rule 7). Background-content `inert` and
the `btn-error`-color question are DEFERRED (Phase 123+).

---

### `operator/shell.ex` `orientation_strip/1` — render-condition only (D-08)

**Analog:** the component is already shared by both surfaces; Phase 120 changed only its render
*condition* on Deliveries, never its copy. `orientation_strip/1` (`shell.ex:384-403`) emits
`data-testid="{@surface}-orientation"`. The `:inbound` copy (`shell.ex:416-425`) is **byte-frozen**:

```elixir
  defp copy_for(:inbound) do
    %{
      heading: "Inbound",
      tips: [
        "InboundMessage didn't route as expected? Inspect the routing trace.",
        "No mailbox matched? Check the no-match record.",
        "Failed ingest? Review the provider signature log."
      ]
    }
  end
```

Zero text edits. Only the *caller's* render condition changes (now empty-pane-only).

---

### Test gate — paired updates + new judgment gate (D-15, D-16)

**Paired-test SPLIT** — `operator.spec.js:462-476` ("inbound and preview surfaces render their
orientation strips") asserts `inbound-orientation` **visible on a populated** view (`:468`) → goes
RED the instant the strip is empty-pane-only. Keep the preview assertion (`:470-475`); replace the
inbound assertion.

**NEW judgment gate** — model verbatim on the shipped Deliveries gate (`operator.spec.js:402-456`):

```js
// POPULATED → strip absent, filters present
await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);
await expect(page.getByTestId("operator-filters")).toBeVisible();
// NO-DATA → empty-truly count 1, strip count 1, filters count 0 (security boundary), master-detail count 0
await expect(page.getByTestId("operator-empty-truly")).toHaveCount(1);
await expect(page.getByTestId("deliveries-orientation")).toHaveCount(1);
await expect(page.getByTestId("operator-filters")).toHaveCount(0);
await expect(page.getByTestId("operator-master-detail")).toHaveCount(0);
// NO-MATCH → filters present, strip absent
await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries&status=queued`);
await expect(page.getByTestId("operator-filters")).toBeVisible();
await expect(page.getByTestId("deliveries-orientation")).toHaveCount(0);
```

Inbound gate (mirror): POPULATED → `inbound-orientation` count 0, `inbound-filters` visible;
NO-DATA → `inbound-empty-truly` count 1, `inbound-orientation` count 1, `inbound-filters` count 0
(security boundary), `inbound-master-detail` count 0; NO-MATCH → `inbound-filters` visible,
`inbound-orientation` count 0. **Assert by `data-testid` count/presence — never pixel/CSS
visibility** (the markers are `style="display:none"` divs, e.g. `records_list.ex:100`).

**Locked PII boundary — do NOT weaken** (`structural.spec.js:1176-1177`):

```js
await expect(page.getByTestId("inbound-evidence-redacted")).toBeVisible();
await expect(page.getByTestId("inbound-evidence-raw")).toHaveCount(0);
```

**New a11y e2e** (`operator.spec.js` + `flows.spec.js`, both surfaces): Tab wraps last→first;
Confirm disabled after first click; reveal `aria-expanded` false→true; re-redact collapse;
`aria-live` region present.

**Persona re-shoot** (D-17, no new cells) — `persona-screenshots.spec.js:69,120-122`
`operator-inbound` × {northstar, fjordline-aps, helios-void} × {375,1440} × {light,dark}.

---

## Shared Patterns

### Single-calm-pane no-data gate (the ported 120 pattern)
**Source:** `operator_live.ex:489-510`
**Apply to:** the `inbound_live.ex:382` else-branch
A top-level `cond` driven by the **existing** `empty_state_for/2` truth — never a new flag.
Genuine no-data renders one pane (empty list + orientation strip) and withholds every control that
cannot act on an empty set (filters / CTA / health strip / master-detail). This is the
GOV.UK/Polaris/Stripe/Sentry pattern and the STRESS-TEST-PROMPT info-dump ban.

### Empty-pane-only orientation strip
**Source:** `operator/shell.ex:384-403` (component) + `operator_live.ex:509` (only caller in
genuine no-data)
**Apply to:** `inbound_live.ex` — render `<Shell.orientation_strip surface={:inbound} />` ONLY in
the no-data pane; remove from the `is_nil(@detail)` detail-column branch (`:483`). Copy frozen;
condition only.

### Telemetry emit (PII-free)
**Source:** convention in `mailglass_inbound/lib/mailglass_inbound/telemetry.ex:10-31` + CLAUDE.md
"Telemetry on `[:mailglass, :domain, :resource, :action, :start|:stop|:exception]` … Never PII"
**Apply to:** the new `reveal_raw` emit in `inbound_live.ex`. Metadata whitelisted to
counts/statuses/IDs only (`tenant_id`/`record_id`/`outcome`), never recipient/payload/body/headers.

### Lockstep sibling modals
**Source:** `inbound/replay_modal.ex` docstring ("Sibling of … SIMPLIFIED") + the two files'
near-identical structure
**Apply to:** any modal a11y change (Tab-trap + double-submit) goes to BOTH
`inbound/replay_modal.ex` and `operator/replay_modal.ex` identically — cross-surface coherence is a
maintained contract.

### Assert presence by data-testid count, never CSS visibility
**Source:** `operator.spec.js:438-447` + `records_list.ex:100` (`style="display:none"` markers)
**Apply to:** every new judgment-gate assertion. The empty-state markers are hidden divs; use
`.toHaveCount(n)`, matching the ExUnit `assert html =~ "inbound-empty-truly"` contract.

### Asset / TokenParity landmine (D-18)
**Source:** project memory `project_token_parity_bundle_landmine.md` + `120-CONTEXT.md` D-13
**Apply to:** the whole phase. All additive markup reuses classes already in the committed
`priv/static/app.css` (Deliveries uses them) → **no `mix assets.build`**. A fresh build emits
raw-inline daisyUI 5.5.19 theme blocks that BREAK `token_parity_test.exs`. Only commit a rebuild
that survives the gate; prefer adding zero new classes. Motion stays on existing tokens
(`motion-reveal`, no new keyframes).

---

## No Analog Found

| Symbol | Role | Data Flow | Reason / Guidance |
|--------|------|-----------|-------------------|
| `[:mailglass_admin, :inbound, :reveal_raw, :stop]` emit | telemetry | event-driven | `mailglass_admin` has NO telemetry today (grep: zero `:telemetry.execute` in admin lib). Follow the cross-package convention (`mailglass_inbound/telemetry.ex` + CLAUDE.md PII rule) — single fire-and-forget `:telemetry.execute/3`, not a full span. |
| ARIA disclosure button (`aria-expanded`/`aria-controls`) | a11y attribute | n/a | No in-repo disclosure-pattern analog. Standard WCAG/APG disclosure; attribute-only on the existing `evidence_card.ex:42-49` button. |
| Tab focus-trap JS | a11y JS | event-driven | No in-repo focus-trap exists (`JS.focus_first` sets initial focus only). Pure Phoenix/LiveView.JS, planner's discretion (sentinel spans vs. scoped keydown). |

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/` (operator_live, inbound_live,
inbound/*, operator/*), `mailglass_admin/e2e/`, `mailglass_inbound/lib/.../telemetry.ex`,
`reference/demo_app/assets/e2e/`.
**Files scanned:** 13 (9 source read in full/targeted, 4 test scouted by grep + targeted read).
**Pattern extraction date:** 2026-06-28
