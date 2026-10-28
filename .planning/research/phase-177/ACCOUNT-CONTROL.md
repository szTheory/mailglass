# Phase 177 Research: Compact Account Control (UXF-09)

**Question:** How should the compact Account control show that it scopes Health, Deliveries and Inbound, and what should the shell show on Preview, which renders Account-independent scenarios?
**Status:** Recommendation, ready for planning. No owner escalation needed. The decision is reversible presentation work inside the existing contracts.
**Composes with:** UXF-10 (validated return from Preview). This document assumes a validated, host-approved, local return link exists and defines only where it sits relative to the Account control and what it may display.

---

## 1. Current state (source-grounded)

| Fact | Where |
|---|---|
| The Account control sits in the **topbar `:actions` slot**, right-aligned next to the theme picker. The nav it scopes sits in the **sidebar** (desktop) or the mobile pill row. The control and the items it scopes share no visual region. | `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (`shell/1`, `account_context/1`); `admin_shell.ex` |
| Nav order is **Health, Preview, Deliveries, Inbound**. The one unscoped surface sits *between* the scoped ones, so a reader can easily conclude that the Account applies to all four. | `mailglass_admin/lib/mailglass_admin/surface_nav.ex` `@items` |
| `surface_paths/4` carries `tenant_id` to overview/deliveries/inbound only. The Preview link is a static `:preview_path` from the host's `navigation` option. | `operator/shell.ex`, `router.ex` (`@navigation_opts_schema`) |
| Preview renders **no Account control at all**. Its topbar holds only the theme picker. Its links to Health, Deliveries and Inbound are **static host paths** (the demo hardcodes `tenant_id=northstar`), and Preview has no Account context. `Preview.Mount` and `PreviewLive` never mention a tenant. | `preview_live.ex` `preview_surface_paths/1`; `reference/demo_app/lib/mailglass_demo_web/router.ex:111-146` |
| Preview data comes from each Mailable's **`preview_props/0`** scenarios, which the adopter writes, plus edits made in the assigns form. Mailglass does not own that data, so it cannot promise the data is "sample" or synthetic. An adopter's `preview_props/0` can contain anything. | `preview/discovery.ex` |
| Preview is a **separate `live_session`** with its own whitelisted `__preview_session__/2`, which has no `tenant_id` and no operator auth. Preview therefore cannot authorize an Account or resolve an Account label (`account_labels` is an operator-route option). | `router.ex:274, 364-375` |
| With **exactly one** selectable Account, the operator auto-selects it (`:canonicalize_tenant`), yet `account_context/1` still renders the `<details>` picker with a chevron and a one-item menu. That is a picker with nothing to pick, which the Cedar Rooms persona prohibits ("No account picker when there is only one selectable account"). | `operator_live.ex:233-240`; `operator/shell.ex` (`:if={@tenant_options != []}`); `.planning/research/ui-quality-engine/PERSONAS-DESIGN.md:47` |
| Upstream scoping already settled: no fake picker on Preview, no Account-aware Preview, and the static Northstar links are not dynamic return support. | `.planning/research/ui-quality-engine/UPSTREAM-SCOPE.md:62,80`; `SCOPING-PRODUCT.md:54`; `REQUIREMENTS.md:76` |

**The "inconsistent compact control" feedback has three causes:** (a) the control is detached from what it scopes, (b) Preview sits inside the scoped run of nav items, and (c) the control shows up on Preview pages in one form (absent) and on single-Account installs in another (a picker that can't pick). None of these needs new state. All three are layout, ordering and conditional rendering.

---

## 2. Recommendation

### 2.1 One idea: the Account control heads the group it scopes

Move the Account control out of the topbar and make it the **header of a bounded "scope group"** that contains exactly Health, Deliveries and Inbound. Preview sits **outside** that group, below it, separated by spacing and a hairline divider. The topbar keeps only the logo and the theme picker, which are global. The theme picker really does apply everywhere, so the topbar becomes the honest home for global things only.

```
Desktop sidebar (operator pages)          Desktop sidebar (Preview)
┌─────────────────────────────┐           ┌─────────────────────────────┐
│ ┌─────────────────────────┐ │           │ ┌─────────────────────────┐ │
│ │ ACCOUNT                 │ │           │ │ SCOPED TO AN ACCOUNT    │ │  ← static text, not focusable
│ │ Northstar Logistics   ▾ │ │  control  │ │ ○ Health                │ │
│ │ ─────────────────────── │ │           │ │ ○ Deliveries            │ │  ← host/validated-return links
│ │ ● Health                │ │           │ │ ○ Inbound               │ │
│ │ ○ Deliveries            │ │           │ └─────────────────────────┘ │
│ │ ○ Inbound               │ │           │ ─────────────────────────── │
│ └─────────────────────────┘ │           │ ● Preview                   │
│ ─────────────────────────── │           │   Not tied to an Account    │  ← caption
│ ○ Preview                   │           └─────────────────────────────┘
│   Not tied to an Account    │
└─────────────────────────────┘
```

Why this placement wins:

- **Gestalt common region and proximity.** A bounded container groups elements more strongly than proximity alone does. Putting the control inside the region it governs answers "what does this apply to?" without any words.
- **Ecosystem convention.** Linear (workspace), Sentry (organization), Vercel (team scope) and Stripe (account) all put the scope switcher at the **top-left of the navigation it scopes**, not in the right-hand utility cluster. Right-hand topbar clusters hold user and global utilities (theme, profile, help). Our current placement matches the utility idiom, which is the wrong one for a scope control.
- **Reading order.** The control comes before the items it scopes in both DOM order and visual order, so keyboard and screen-reader users meet the scope before the scoped links.
- **Reorder the nav to Health, Deliveries, Inbound, then Preview.** Preview leaves the middle of the run. It is the developer authoring surface, and it already behaves differently (separate session, separate mount).

### 2.2 Operator pages (Health, Deliveries, Inbound)

| Account situation | Group header renders | Rationale |
|---|---|---|
| ≥2 selectable Accounts, one selected | The interactive control (`<details>` + `<summary>`, existing menu and `tenant_switch_path` behavior unchanged): `Account` label, Account name, chevron | Unchanged switching contract. Only the location moves. |
| Exactly 1 selectable Account | **Static** `Account` label and name. **No chevron, no `<details>`, no menu.** | Fixes the picker-with-nothing-to-pick case. A control that offers no choice is a fake picker. |
| None selected, ≥1 available (`select_required`) | Static `Account` label with `Choose an Account` in secondary tone. Not a duplicate picker: the body's `tenant_selector` owns the choice. | One choice surface at a time. |
| No Accounts (`:none`) | Static `Account` label with `No Accounts yet`. Scoped items stay as links. | Honest empty state, matching the existing body copy. |

Long names wrap (`break-words`, at most 2 lines visible) and are never truncated with an ellipsis, so exact values stay intelligible. The menu keeps showing the mono `tenant_id` under each label.

### 2.3 Preview page

- **No Account control, no Account name, no `tenant_id` anywhere in Preview chrome.** This is not a disabled control, not a "Global" pseudo-option, and not a greyed picker. Preview has nothing to choose and no authority to display a name (see §1).
- The scope-group **frame stays**, with the static eyebrow `Scoped to an Account` in place of the control. The links inside point to the host's static paths, or, under UXF-10, to the **validated return destination**. The frame keeps the nav shape identical across surfaces, so the nav does not jump and orientation is not lost, while the eyebrow states the truth without claiming a specific Account. This mirrors AWS, which replaces the Region selector with a non-interactive `Global` label on global services such as IAM instead of disabling it.
- The Preview nav item carries the caption **`Not tied to an Account`** on every surface. On operator pages it tells the operator that switching Account will not change Preview. On Preview it confirms that nothing here is filtered.
- Preview page-header subtitle (the exact sentence is a test fixture, §5 P6):
  > Renders the scenarios in each Mailable's `preview_props/0`. Preview doesn't read Deliveries or Inbound records from any Account.

  Both clauses are true by construction. Preview has no tenant input, and mailglass never feeds stored records into `preview_props/0`. The sentence does **not** say "sample data", because the adopter owns `preview_props/0` and mailglass cannot verify that its values are synthetic.

### 2.4 Composition with UXF-10 (validated return)

- The return affordance belongs to **Preview's page body and header area**, as a plain link (e.g. `Back to Deliveries`). It is never an Account-control lookalike: no `Account` label, no chevron, no menu.
- When a return destination validates, the scoped group's links resolve to it (or the surface root on the same mount) instead of the static host paths. When it does not validate or is absent (direct entry), the links fall back to the host paths. The eyebrow stays `Scoped to an Account` in both cases.
- **Preview never renders the Account name or `tenant_id` carried in a return destination,** even a validated one. Validation proves the path is local and host-approved. It does not prove that this viewer may see that Account, because Preview has no operator auth. Rendering the name would let a crafted link print attacker-chosen text into trusted chrome (content spoofing), and would amount to an "Account-scoped Preview" claim. The operator surface re-authorizes on arrival and shows the name there.
- The operator → Preview link carries the return context as one encoded return parameter, never as a top-level `tenant_id`. A top-level `tenant_id` would look like Preview scoping, and a later change could start reading it.

### 2.5 Mobile (< `md`, sidebar hidden)

The `:mobile_nav` band becomes the scope group:

```
┌────────────────────────────────────┐
│ [logo]                     [theme] │  topbar: global only (no wrap at 320px)
├────────────────────────────────────┤
│ ┌────────────────────────────────┐ │
│ │ Account · Northstar Logistics ▾│ │  full-width control, min-h-11
│ │ [Health] [Deliveries] [Inbound]│ │  scoped pills inside the region
│ └────────────────────────────────┘ │
│ [Preview · Not tied to an Account] │  outside the region
└────────────────────────────────────┘
```

- The control spans the full band width and the menu opens full-width beneath it (`left-0 right-0`), with no off-screen right-anchored popover at 320px.
- Moving the control out of the topbar also removes the current topbar wrap at 320 and 375px, where the logo, the Account control and the theme picker compete for one row.
- On Preview the band shows the static eyebrow, the pills and the Preview pill. It has no control.
- Target size stays ≥44px (`min-h-11`), and focus rings use the existing `mg-focus-ring`.

### 2.6 Accessibility

- **Group semantics.** Wrap the scoped links in an element with `role="group"`, labelled by the header (`aria-labelledby` pointing at the visible `Account` label plus name, or at the `Scoped to an Account` eyebrow on Preview). Screen readers announce "Account Northstar Logistics, group" on entry. That gives non-visual users the same scope that the visual region gives sighted users. Keep the single `<nav aria-label="Mailglass sections">` landmark; do not add a second nav landmark per group.
- **Control name and description.** The accessible name stays `Change Account: Northstar Logistics`. It contains the visible text "Account … Northstar Logistics", which satisfies WCAG 2.5.3 Label in Name. Add `aria-describedby` pointing to a visually hidden `Applies to Health, Deliveries and Inbound.` built from the *visible* scoped items, so it drops `Inbound` when Inbound is unavailable.
- **No disabled control on Preview.** Disabled controls are a known discoverability trap. Native `disabled` removes the control from the tab order, so keyboard users never learn why it exists. `aria-disabled` keeps it focusable but invites activation attempts that do nothing. Rendering a static caption avoids both problems.
- **Switch feedback.** Keep the existing polite `Switching to {name}…` status. After the patch lands, return focus to the summary and keep the menu closed. Use non-colour cues only: the active nav item keeps `aria-current="page"` plus weight and indicator, not colour alone.
- **Reading order.** Header, then scoped links, then divider, then Preview. The DOM order matches the visual order at every width.

### 2.7 Copy (brand voice: clear, exact, warm not cute; seven nouns)

| Slot | Copy |
|---|---|
| Control eyebrow | `Account` |
| Control accessible name | `Change Account: {name}` |
| Control description (sr-only) | `Applies to Health, Deliveries and Inbound.` (derived from visible items) |
| Menu label | `Available Accounts` (unchanged) |
| Switch status | `Switching to {name}…` (unchanged) |
| Single Account (static) | `Account` / `{name}` |
| Nothing selected | `Account` / `Choose an Account` |
| No Accounts | `Account` / `No Accounts yet` |
| Preview: group eyebrow | `Scoped to an Account` |
| Preview nav caption | `Not tied to an Account` |
| Preview subtitle | `Renders the scenarios in each Mailable's preview_props/0. Preview doesn't read Deliveries or Inbound records from any Account.` |

Avoid: "workspace", "tenant" in visible chrome (Account is the UI noun; `tenant_id` appears only in mono code and the menu ID line), "Global", "All Accounts" (implies an aggregate view that doesn't exist), "sample data", "demo data", "live data", "Notification", and bare "Email" or "Status". Also note for PRVUX: the current Preview subtitle "See how your emails look…" uses bare "emails". The subtitle above replaces it. If PRVUX-06 owns that line, coordinate rather than overwrite.

---

## 3. Rejected alternatives

| Alternative | Why rejected |
|---|---|
| **Keep the control in the topbar, add a "Scope: Health, Deliveries, Inbound" label** | Adds words to compensate for broken proximity. The topbar's right cluster still reads as global utilities, and the extra label costs 320px space. |
| **Show the control on Preview, disabled, with a tooltip** | This is a fake picker by definition. It is a keyboard discoverability trap (native `disabled`) or an activation trap (`aria-disabled`), tooltips are unreliable on touch, and it still displays an Account name that Preview cannot authorize. |
| **Show the control on Preview, live, carrying the selection through** | This is global current-Account state, which is prohibited, and it implies Account-scoped Preview data (an excluded product decision). It would also need the Preview session whitelist widened (prohibited by UXF-10). |
| **Show the originating Account name read-only on Preview ("You came from Northstar")** | The name comes from an unauthenticated URL into trusted chrome, so it is spoofable. It reads as scoping, and Preview lacks `account_labels`. UXF-10's return link conveys the same navigation without the claim. |
| **Hide the scope frame entirely on Preview** | The nav shape jumps between surfaces, and nothing tells the operator that Health, Deliveries and Inbound are scoped while Preview is not. The frame plus eyebrow costs one line. |
| **`Global` / `All Accounts` pseudo-option (AWS literal copy)** | mailglass has no cross-Account view, so "All Accounts" is false. "Global" is jargon here. The *pattern* (replace the selector with a static label) is adopted, but not the word. |
| **"Preview uses sample data" banner** | It is unverifiable, because the adopter owns `preview_props/0`. A banner is also heavier than a one-line subtitle. |
| **Two separate nav landmarks ("Account" nav and "Developer" nav)** | It adds landmark noise. "Developer" is wrong because Preview may be mounted outside dev (the adopter enforces dev-only). A group plus a divider is enough. |
| **Persist the last Account in a cookie so Preview links return to it** | That is global current-Account state, which is prohibited. UXF-10's per-navigation validated return is the sanctioned seam. |

---

## 4. Adversarial pass

1. **"Moving the control into the sidebar hides it on mobile."** Refuted by §2.5: the mobile band hosts it, first in reading order. Test at 320 and 375px that the summary is visible without scrolling the band.
2. **"Scoped to an Account" on Preview with no name is vague.** It is deliberately unspecific because Preview cannot know which Account is meant. The specific name appears once the operator arrives, after re-authorization. A specific name here would be the dishonest option.
3. **Static host links still hardcode Northstar in the demo.** Under the eyebrow they may land on Northstar. This is acceptable only because the chrome makes no claim about which Account. When UXF-10 is present, the validated return replaces them. Docs must not describe the static links as return support (REQUIREMENTS.md:76).
4. **`Inbound` absent (no inbound package).** The description and group must be derived from visible items, or the copy claims a scope over a surface that doesn't exist (an Honest Surface Area violation). The test covers both builds.
5. **Single Account plus `account_labels` missing.** The name falls back to the raw `tenant_id` (`Accounts.label/2`). That is acceptable and exact. Keep the mono styling only in the menu.
6. **Hostile labels** (very long, RTL, emoji, HTML-looking strings). HEEx escapes them. Wrap without truncation. A Storybook scenario retains a long/Unicode case (Fjordline A/S) per OUTUX-06/STORY-07.
7. **"Not tied to an Account" could be false if the adopter's `preview_props/0` reads their own DB per tenant.** The claim is about mailglass's behavior: Preview passes no Account and the control does not affect it. That stays true regardless of what the adopter's function does internally. The subtitle's second sentence is scoped to "Deliveries or Inbound records", which are mailglass's stores, so it remains exact.
8. **Return parameter abuse.** Covered by the "never render" rule (§2.4) and by P2. UXF-10's validator owns the rejection of external and tampered destinations.
9. **Regression via a later "helpful" change** that adds `tenant_id` to `preview_path` or copies `account_context` into `PreviewLive`. P1 and P4 make both changes go red.

---

## 5. Prohibitions as tests

Add `mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs`, following the shape of `phase175_prohibition_contract_test.exs`: closed set of rendered states, regex or DOM refutations, and a **"detectors have teeth"** block proving each detector fails on a known violation. The test belongs in the merge-blocking admin lane (`mix verify.support_contract.admin`). Register it if that lane uses an allow-list.

| ID | Must NOT | Proof (states enumerated) | Teeth |
|---|---|---|---|
| **P1** | No Account control on Preview | Render `PreviewLive` (with and without `navigation`, with and without a return param, mailables present and absent, render-error branch). Refute any `[data-testid^="operator-account"]`, any `<details>`/`<select>`/`[role=listbox]`/`[role=combobox]` whose text matches `~r/\baccount\b/i`, and text matching `~r/(choose|change|switch|select) (an )?account/i` and `~r/\bAccount:\s*\S/`. | Feed a fragment rendered by `Shell.account_context/1`; it must be detected. |
| **P2** | Preview never echoes an Account identity | Mount Preview with a return destination containing `tenant_id=zz-canary-7f3` and a label-like `name=Canary%20Corp`. Strip `href` attribute values, then refute `zz-canary-7f3` and `Canary Corp` anywhere in the HTML. | Inject a `<span>zz-canary-7f3</span>`; it must be detected. |
| **P3** | No Account-scoped or unverifiable data claims in Preview chrome | On all P1 states, refute `~r/sample data/i`, `~r/(demo|fake|live|real|production) data/i`, `~r/account'?s? (preview|sample|scenario)/i`, `~r/(preview|scenarios?) (for|from|scoped to|filtered (to|by)) (the |this |your )?(current |selected )?account/i`, `~r/all accounts/i` and `~r/\bglobal\b/i`. (`Sample headers` in `preview/tabs.ex` is allowed: it names generated headers, not data provenance. List it as an explicit exemption so the exemption is visible.) | One violation string per regex. |
| **P4** | Operator → Preview link carries no top-level scope | For overview, deliveries and inbound with a selected tenant, parse each Preview `href`. `URI.decode_query/1` top-level keys must not include `tenant_id`. | `"/dev/mail?tenant_id=northstar"` must be detected. |
| **P5** | Preview is never inside the scope group, and the group holds exactly the visible scoped items | On operator and Preview pages, in sidebar and mobile layouts, parse `[data-account-scope]`. Its links must be exactly `{Health, Deliveries, Inbound}` (minus Inbound when unavailable), with no Preview link inside. | A fixture with Preview inside the group must fail. |
| **P6** | Preview subtitle is exactly the honest sentence | Assert equality against the §2.7 string. Any reword must be a deliberate test edit. | Not applicable (equality). |
| **P7** | No picker without a choice | Render `account_context/1` with 0 and 1 options. Refute `<details>`, the chevron icon and `[data-testid="operator-account-option"]`. With 2 options, assert they are present (positive control). | A 1-option fixture rendered through the old branch must fail. |
| **P8** | No global current-Account state | Assert that `Router.__preview_session__/2` returns a key set equal to the current whitelist (no `tenant_id`, no Account keys). Assert that Preview socket assigns contain no `:selected_tenant_id`, `:tenant_id` or `:account_labels`. Assert that no cookie or session write happens on Account switch (switching is URL-only through `tenant_switch_path/2`). | Add `"tenant_id"` to a copy of the session map; it must fail. |
| **P9** | No scope description over a missing surface | With inbound unavailable, the control's description must not match `~r/inbound/i`. | Not applicable (state toggle). |

Positive behavior (visible region, focus return, 320/375/768/1280/1440 layouts, light and dark, the menu opening full-width on mobile) belongs to the LiveView and Playwright suites and the retained Storybook scenarios (Northstar many, Fjordline long/Unicode, single-Account Cedar-style, Helios absent from the switcher). It does not belong in this prohibition file.

---

## 6. Sources

**Local (primary):** `mailglass_admin/lib/mailglass_admin/operator/shell.ex`, `surface_nav.ex`, `admin_shell.ex`, `preview_live.ex`, `preview/discovery.ex`, `router.ex`, `operator_live.ex:159-240`, `operator/accounts.ex`, `reference/demo_app/lib/mailglass_demo_web/router.ex:105-146`, `.planning/REQUIREMENTS.md` (UXF-09/10, line 76), `.planning/ROADMAP.md` Phase 177, `.planning/METHODOLOGY.md` § Honest Surface Area, `.planning/research/ui-quality-engine/{UPSTREAM-SCOPE,SCOPING-PRODUCT,PERSONAS-DESIGN,UPSTREAM-REVIEW}.md`, `brandbook/brand-book.md` § Voice, `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`, `guides/jobs.md`.

**External:**
- AWS Management Console, choosing a Region (global services such as IAM need no Region selection): https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region.html and https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/select-region-procedure.html
- AWS global services reached through a single Region, with the console returning to the selected Region: https://docs.aws.amazon.com/accounts/latest/reference/project-regions.html
- MDN, `aria-disabled` (focusability and discoverability trade-off): https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-disabled
- W3C ARIA APG minutes 2022-03-01 (default to keeping disabled items focusable for discoverability; there is no one-size-fits-all rule): https://www.w3.org/2022/03/01-aria-apg-minutes.html
- WCAG 2.2 SC 2.5.3 Label in Name: https://www.w3.org/WAI/WCAG22/Understanding/label-in-name.html
- WAI-ARIA `group` role: https://www.w3.org/TR/wai-aria-1.2/#group
- Product patterns (observed conventions, not fetched for this note): Linear workspace switcher, Sentry organization switcher, Vercel team scope and Stripe account switcher all sit top-left at the head of the navigation they scope. Postmark separates per-Server pages from account-level pages. GitHub's org/dashboard context switcher shows scope before scoped content.
