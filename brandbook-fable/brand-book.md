# mailglass — Brand Book

The text master of the mailglass brand system. The same system, rendered live,
is `index.html` in this folder — open it from disk in any browser. Every value
in this document is exact; every claim is carried by a number.

**Essence:** Email, made visible. Mail you can see through.

---

## Orientation & Essence

mailglass is a Phoenix-native framework for composing, previewing, delivering,
and observing email. The brand carries the same promise as the library:
clarity you can verify. Glass is the metaphor — panes, preview surfaces,
light passing through structure. Never frosted blur, never gloss, never
literal broken glass.

The composition is a well-lit workbench: left-aligned, documentation-like,
ragged-right text, generous whitespace around exact content. Every section
ends in something operable — a table, a CSS block, a rendered specimen.

### The rules

1. **Assets are outlined paths only.** No live text and no font dependencies
   inside any SVG. The wordmark renders identically everywhere, including
   font-less image sandboxes.
2. **Dark mode is demonstrated, not asserted.** A dark value no specimen
   renders does not exist. `index.html` proves the whole system live.
3. **Every contrast claim is computed.** The ratios in this document were
   produced by the WCAG 2.x formula below, run against the shipped token
   values. `index.html` recomputes them on every load.
4. **Flat color first; transparency carries meaning.** Translucency appears
   only where it expresses layered visibility. Gradients come nowhere near
   the identity.
5. **No glassmorphism.** No frosted blur, transparency stacks, or lens flares.
6. **No background plate behind the mark.** The single documented exception is
   the inherently square social avatar.
7. **Text artifacts only, zero network requests.** SVG, MD, JSON, CSS, HTML.
   Every page opens complete from `file://`.

## Voice

mailglass speaks like a thoughtful maintainer: plain English, exact nouns,
strong verbs, short sentences. Clear, exact, confident (not cocky), warm
(not cute), modern (not trendy), technical (not intimidating).

### Principles

| Principle | In practice |
|---|---|
| Clear first | Prefer the direct word over the clever one |
| Explain, don't hype | Confident understatement beats inflation |
| Calm under failure | Errors name the cause and stay composed |
| Generous with context | Copy helps the reader recover quickly |

### Say this, not that

| Say | Not |
|---|---|
| preview | experience the full rendering lifecycle |
| provider-normalized events | revolutionary observability |
| Delivery blocked: recipient is on the suppression list | Oops! Something went wrong |
| This message was skipped because the recipient previously unsubscribed | Suppressed |
| Render a real message before you send it | Beautifully effortless email magic |

### The seven nouns

**Mailable** (source-level definition), **Message** (rendered email),
**Delivery** (per-recipient send record), **Event** (observed fact, past
tense), **InboundMessage** (received email), **Mailbox** (inbound handler),
**Suppression** (policy record blocking future sends). Dispatch is not
delivery: dispatched means handed to the provider; delivered means the
destination accepted it.

## Color & Tokens

### Palette and jobs

| Color | Hex | Job |
|---|---|---|
| Ink | `#0D1B2A` | Text on light surfaces; the ground of every dark surface |
| Glass | `#277B96` | Light accent: icons, focus rings, solid fills with white text, large text |
| Ice | `#A6EAF2` | Dark accent and link — AAA on every dark surface |
| Mist | `#EAF6FB` | Sunken surfaces in light; body text in dark |
| Paper | `#F8FBFD` | Light page background |
| Slate | `#5C6B7A` | Light muted text and strong borders |
| glass-deep | `#1D637A` | Light links and body-size accent copy |
| glass-deepest | `#174E61` | Light link hover/active — contrast rises on interaction |
| amber-deep | `#96520E` | Light warning text — passes on every light surface |
| slate-soft | `#74909F` | Light input borders (at least 3:1 control boundary) |
| crimson-bright | `#E29089` | Dark error family — readable on every dark surface |
| slate-bright | `#62809A` | Dark input borders and strong borders |

### Semantic roles, light and dark

Components reference roles, never palette colors. Role names hold across
themes; only values change. The full sheet ships as `tokens.css` (custom
properties, `:root` light, `[data-theme="dark"]` plus an OS-preference media
block) and `tokens.json` (the same values with raw palette names).

| Token | Light | Dark | Job |
|---|---|---|---|
| `--mg-color-background` | `#F8FBFD` | `#0D1B2A` | Page ground |
| `--mg-color-surface` | `#FFFFFF` | `#0D1B2A` | Default component surface |
| `--mg-color-surface-raised` | `#FFFFFF` | `#152538` | Cards, raised panels |
| `--mg-color-surface-overlay` | `#FFFFFF` | `#1F3049` | Menus, dialogs |
| `--mg-color-surface-sunken` | `#EAF6FB` | `#0A1521` | Code blocks, wells |
| `--mg-color-surface-selected` | `#DDF2F7` | `#1B3E55` | Selected rows — never hosts form controls |
| `--mg-color-border` | `#C7DCE5` | `#315069` | Decorative hairlines only |
| `--mg-color-border-input` | `#74909F` | `#62809A` | Control boundaries |
| `--mg-color-border-strong` | `#5C6B7A` | `#62809A` | Emphatic separation |
| `--mg-color-text` | `#0D1B2A` | `#EAF6FB` | Body text |
| `--mg-color-text-muted` | `#5C6B7A` | `#B8CAD4` | Secondary text (AA) |
| `--mg-color-text-disabled` | `#9AA8B4` | `#6B7E8F` | Disabled labels — never the only signal |
| `--mg-color-text-inverse` | `#FFFFFF` | `#0D1B2A` | Text on accent fills |
| `--mg-color-accent` | `#277B96` | `#A6EAF2` | Icons, rings, solid fills, large text |
| `--mg-color-accent-text` | `#1D637A` | `#A6EAF2` | Body-size accent copy |
| `--mg-color-link` | `#1D637A` | `#A6EAF2` | Links at rest |
| `--mg-color-link-hover` | `#174E61` | `#D6F7FB` | Hover |
| `--mg-color-link-active` | `#174E61` | `#D6F7FB` | Active press |
| `--mg-color-focus-ring` | `#277B96` | `#A6EAF2` | One ring value per theme |
| `--mg-color-success-text` | `#166534` | `#8BB77F` | Delivered, verified |
| `--mg-color-success-bg` | `#E8F3EA` | `#142B22` | Success tint |
| `--mg-color-success-border` | `#166534` | `#8BB77F` | Success border |
| `--mg-color-success-solid` | `#166534` | `#8BB77F` | Success fill |
| `--mg-color-success-on-solid` | `#FFFFFF` | `#0D1B2A` | Text on success fill |
| `--mg-color-warning-text` | `#96520E` | `#E0A955` | Deferred, retrying |
| `--mg-color-warning-bg` | `#FFF8F0` | `#2B2314` | Warning tint |
| `--mg-color-warning-border` | `#A95F10` | `#E0A955` | Warning border |
| `--mg-color-warning-solid` | `#A95F10` | `#E0A955` | Warning fill |
| `--mg-color-warning-on-solid` | `#FFFFFF` | `#0D1B2A` | Text on warning fill |
| `--mg-color-error-text` | `#B42318` | `#E29089` | Bounced, blocked |
| `--mg-color-error-bg` | `#FAE7E5` | `#2E1B1E` | Error tint |
| `--mg-color-error-border` | `#B42318` | `#E29089` | Error border |
| `--mg-color-error-solid` | `#B42318` | `#E29089` | Error fill |
| `--mg-color-error-on-solid` | `#FFFFFF` | `#0D1B2A` | Text on error fill |
| `--mg-color-info-text` | `#1D637A` | `#A6EAF2` | Queued, notices |
| `--mg-color-info-bg` | `#EAF6FB` | `#11293A` | Info tint |
| `--mg-color-info-border` | `#277B96` | `#A6EAF2` | Info border |
| `--mg-color-info-solid` | `#1D637A` | `#A6EAF2` | Info fill |
| `--mg-color-info-on-solid` | `#FFFFFF` | `#0D1B2A` | Text on info fill |

## Typography

Three faces, three jobs. Inter is preinstalled on no major operating system
and the brand ships no font files, so the stacks below are the everyday
truth: Inter and IBM Plex Mono when installed, the system face otherwise.
The wordmark — the one place type may never fall back — is outlined paths
inside every asset.

| Role | Stack |
|---|---|
| Display | `"Inter Tight", Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif` |
| UI / body | `Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif` |
| Mono | `"IBM Plex Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` |

### Scale

| Token | Size | Use |
|---|---|---|
| `--mg-text-display` | 44px | Mastheads only — one per page |
| `--mg-text-h1` | 36px | Page titles |
| `--mg-text-h2` | 30px | Section headings |
| `--mg-text-h3` | 24px | Subsection headings |
| `--mg-text-body` | 16px | Body copy — never smaller for running text |
| `--mg-text-small` | 14px | Captions, labels, table cells |
| `--mg-text-code` | 14px | Code, values, identifiers |

### Space, radius, focus

| Token set | Values |
|---|---|
| Space | xs 4px · sm 8px · md 16px · lg 24px · xl 40px · 2xl 64px |
| Radius | sm 4px · md 8px · lg 12px · full 9999px |
| Focus ring | 2px width, 2px offset, `--mg-color-focus-ring` |

## Contrast Matrix

Computed with the WCAG 2.x formula: each sRGB 8-bit channel is divided by
255, linearized (`c/12.92` when `c <= 0.04045`, else
`((c+0.055)/1.055)^2.4`), combined as `L = 0.2126R + 0.7152G + 0.0722B`,
and the ratio is `(L_lighter + 0.05) / (L_darker + 0.05)`, shown to two
decimals. Verdicts use normal-text thresholds: AA at 4.5, AAA at 7.0.

**Anchors:** Ink `#0D1B2A` on Paper `#F8FBFD` = **16.74**. Glass `#277B96`
on white `#FFFFFF` = **4.82**. Both pass AA.

**Two standing rules distilled from the data:** body-size accent copy routes
through `accent-text` `#1D637A` (Glass itself reads 4.37 on Mist and 4.16 on
selected — both below AA), and form controls never sit on selected surfaces
(`border-input` reads 2.91 light / 2.72 dark there, below the 3:1 boundary
minimum; selected rows highlight existing content, they do not host fields).

### Light theme — text roles × surfaces

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| text | `#0D1B2A` | background | `#F8FBFD` | 16.74 | pass | pass | Any text size |
| text | `#0D1B2A` | surface | `#FFFFFF` | 17.39 | pass | pass | Any text size |
| text | `#0D1B2A` | surface-raised | `#FFFFFF` | 17.39 | pass | pass | Any text size |
| text | `#0D1B2A` | surface-overlay | `#FFFFFF` | 17.39 | pass | pass | Any text size |
| text | `#0D1B2A` | surface-sunken | `#EAF6FB` | 15.80 | pass | pass | Any text size |
| text | `#0D1B2A` | surface-selected | `#DDF2F7` | 15.01 | pass | pass | Any text size |
| text-muted | `#5C6B7A` | background | `#F8FBFD` | 5.26 | pass | fail | AA — use text where AAA matters |
| text-muted | `#5C6B7A` | surface | `#FFFFFF` | 5.47 | pass | fail | AA — use text where AAA matters |
| text-muted | `#5C6B7A` | surface-raised | `#FFFFFF` | 5.47 | pass | fail | AA — use text where AAA matters |
| text-muted | `#5C6B7A` | surface-overlay | `#FFFFFF` | 5.47 | pass | fail | AA — use text where AAA matters |
| text-muted | `#5C6B7A` | surface-sunken | `#EAF6FB` | 4.97 | pass | fail | AA — use text where AAA matters |
| text-muted | `#5C6B7A` | surface-selected | `#DDF2F7` | 4.72 | pass | fail | AA — use text where AAA matters |
| text-disabled | `#9AA8B4` | background | `#F8FBFD` | 2.34 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#9AA8B4` | surface | `#FFFFFF` | 2.43 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#9AA8B4` | surface-raised | `#FFFFFF` | 2.43 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#9AA8B4` | surface-overlay | `#FFFFFF` | 2.43 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#9AA8B4` | surface-sunken | `#EAF6FB` | 2.21 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#9AA8B4` | surface-selected | `#DDF2F7` | 2.10 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| accent | `#277B96` | background | `#F8FBFD` | 4.64 | pass | fail | Reserve for icons/borders/large text/fills |
| accent | `#277B96` | surface | `#FFFFFF` | 4.82 | pass | fail | Reserve for icons/borders/large text/fills |
| accent | `#277B96` | surface-raised | `#FFFFFF` | 4.82 | pass | fail | Reserve for icons/borders/large text/fills |
| accent | `#277B96` | surface-overlay | `#FFFFFF` | 4.82 | pass | fail | Reserve for icons/borders/large text/fills |
| accent | `#277B96` | surface-sunken | `#EAF6FB` | 4.37 | fail | fail | Fails normal text — use accent-text |
| accent | `#277B96` | surface-selected | `#DDF2F7` | 4.16 | fail | fail | Fails normal text — use accent-text |
| accent-text | `#1D637A` | background | `#F8FBFD` | 6.48 | pass | fail | AA — use text where AAA matters |
| accent-text | `#1D637A` | surface | `#FFFFFF` | 6.74 | pass | fail | AA — use text where AAA matters |
| accent-text | `#1D637A` | surface-raised | `#FFFFFF` | 6.74 | pass | fail | AA — use text where AAA matters |
| accent-text | `#1D637A` | surface-overlay | `#FFFFFF` | 6.74 | pass | fail | AA — use text where AAA matters |
| accent-text | `#1D637A` | surface-sunken | `#EAF6FB` | 6.12 | pass | fail | AA — use text where AAA matters |
| accent-text | `#1D637A` | surface-selected | `#DDF2F7` | 5.81 | pass | fail | AA — use text where AAA matters |
| link | `#1D637A` | background | `#F8FBFD` | 6.48 | pass | fail | AA; hover rises to 8.79 |
| link | `#1D637A` | surface | `#FFFFFF` | 6.74 | pass | fail | AA; hover rises to 9.14 |
| link | `#1D637A` | surface-raised | `#FFFFFF` | 6.74 | pass | fail | AA; hover rises to 9.14 |
| link | `#1D637A` | surface-overlay | `#FFFFFF` | 6.74 | pass | fail | AA; hover rises to 9.14 |
| link | `#1D637A` | surface-sunken | `#EAF6FB` | 6.12 | pass | fail | AA; hover rises to 8.30 |
| link | `#1D637A` | surface-selected | `#DDF2F7` | 5.81 | pass | fail | AA; hover rises to 7.88 |

### Light theme — feedback text on its tint

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| success-text | `#166534` | success-bg | `#E8F3EA` | 6.26 | pass | fail | AA — use text where AAA matters |
| warning-text | `#96520E` | warning-bg | `#FFF8F0` | 5.68 | pass | fail | AA — use text where AAA matters |
| error-text | `#B42318` | error-bg | `#FAE7E5` | 5.52 | pass | fail | AA — use text where AAA matters |
| info-text | `#1D637A` | info-bg | `#EAF6FB` | 6.12 | pass | fail | AA — use text where AAA matters |

### Light theme — text on solid fills

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| success-on-solid | `#FFFFFF` | success-solid | `#166534` | 7.13 | pass | pass | Any text size |
| warning-on-solid | `#FFFFFF` | warning-solid | `#A95F10` | 4.85 | pass | fail | AA — use text where AAA matters |
| error-on-solid | `#FFFFFF` | error-solid | `#B42318` | 6.57 | pass | fail | AA — use text where AAA matters |
| info-on-solid | `#FFFFFF` | info-solid | `#1D637A` | 6.74 | pass | fail | AA — use text where AAA matters |
| text-inverse | `#FFFFFF` | accent | `#277B96` | 4.82 | pass | fail | AA — use text where AAA matters |

### Dark theme — text roles × surfaces

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| text | `#EAF6FB` | background | `#0D1B2A` | 15.80 | pass | pass | Any text size |
| text | `#EAF6FB` | surface | `#0D1B2A` | 15.80 | pass | pass | Any text size |
| text | `#EAF6FB` | surface-raised | `#152538` | 14.09 | pass | pass | Any text size |
| text | `#EAF6FB` | surface-overlay | `#1F3049` | 12.09 | pass | pass | Any text size |
| text | `#EAF6FB` | surface-sunken | `#0A1521` | 16.70 | pass | pass | Any text size |
| text | `#EAF6FB` | surface-selected | `#1B3E55` | 10.22 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | background | `#0D1B2A` | 10.30 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | surface | `#0D1B2A` | 10.30 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | surface-raised | `#152538` | 9.19 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | surface-overlay | `#1F3049` | 7.89 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | surface-sunken | `#0A1521` | 10.89 | pass | pass | Any text size |
| text-muted | `#B8CAD4` | surface-selected | `#1B3E55` | 6.66 | pass | fail | AA — use text where AAA matters |
| text-disabled | `#6B7E8F` | background | `#0D1B2A` | 4.15 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#6B7E8F` | surface | `#0D1B2A` | 4.15 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#6B7E8F` | surface-raised | `#152538` | 3.70 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#6B7E8F` | surface-overlay | `#1F3049` | 3.17 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#6B7E8F` | surface-sunken | `#0A1521` | 4.38 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| text-disabled | `#6B7E8F` | surface-selected | `#1B3E55` | 2.68 | fail | fail | Exempt (SC 1.4.3) — never the only signal |
| accent | `#A6EAF2` | background | `#0D1B2A` | 12.98 | pass | pass | Any text size |
| accent | `#A6EAF2` | surface | `#0D1B2A` | 12.98 | pass | pass | Any text size |
| accent | `#A6EAF2` | surface-raised | `#152538` | 11.58 | pass | pass | Any text size |
| accent | `#A6EAF2` | surface-overlay | `#1F3049` | 9.94 | pass | pass | Any text size |
| accent | `#A6EAF2` | surface-sunken | `#0A1521` | 13.72 | pass | pass | Any text size |
| accent | `#A6EAF2` | surface-selected | `#1B3E55` | 8.40 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | background | `#0D1B2A` | 12.98 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | surface | `#0D1B2A` | 12.98 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | surface-raised | `#152538` | 11.58 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | surface-overlay | `#1F3049` | 9.94 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | surface-sunken | `#0A1521` | 13.72 | pass | pass | Any text size |
| accent-text | `#A6EAF2` | surface-selected | `#1B3E55` | 8.40 | pass | pass | Any text size |
| link | `#A6EAF2` | background | `#0D1B2A` | 12.98 | pass | pass | Any size; hover rises to 15.37 |
| link | `#A6EAF2` | surface | `#0D1B2A` | 12.98 | pass | pass | Any size; hover rises to 15.37 |
| link | `#A6EAF2` | surface-raised | `#152538` | 11.58 | pass | pass | Any size; hover rises to 13.71 |
| link | `#A6EAF2` | surface-overlay | `#1F3049` | 9.94 | pass | pass | Any size; hover rises to 11.77 |
| link | `#A6EAF2` | surface-sunken | `#0A1521` | 13.72 | pass | pass | Any size; hover rises to 16.25 |
| link | `#A6EAF2` | surface-selected | `#1B3E55` | 8.40 | pass | pass | Any size; hover rises to 9.94 |

### Dark theme — feedback text on its tint

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| success-text | `#8BB77F` | success-bg | `#142B22` | 6.56 | pass | fail | AA — use text where AAA matters |
| warning-text | `#E0A955` | warning-bg | `#2B2314` | 7.37 | pass | pass | Any text size |
| error-text | `#E29089` | error-bg | `#2E1B1E` | 6.65 | pass | fail | AA — use text where AAA matters |
| info-text | `#A6EAF2` | info-bg | `#11293A` | 11.18 | pass | pass | Any text size |

### Dark theme — text on solid fills

| Role | Hex | Surface | Hex | Ratio | AA | AAA | Rule |
|---|---|---|---|---:|---|---|---|
| success-on-solid | `#0D1B2A` | success-solid | `#8BB77F` | 7.60 | pass | pass | Any text size |
| warning-on-solid | `#0D1B2A` | warning-solid | `#E0A955` | 8.26 | pass | pass | Any text size |
| error-on-solid | `#0D1B2A` | error-solid | `#E29089` | 7.11 | pass | pass | Any text size |
| info-on-solid | `#0D1B2A` | info-solid | `#A6EAF2` | 12.98 | pass | pass | Any text size |
| text-inverse | `#0D1B2A` | accent | `#A6EAF2` | 12.98 | pass | pass | Any text size |

## Component Gallery

`index.html` renders every component live — real elements with working
hover, focus-visible, and disabled states, plus pinned-state rows that share
the same declarations. The recipes, in tokens:

| Component | Recipe |
|---|---|
| Button, primary | `accent` fill, `text-inverse` label; hover/active `link-hover`/`link-active` |
| Button, secondary | `surface` fill, `border-input` border, `text` label; hover `surface-sunken` |
| Button, quiet | transparent, `link` label; hover `link-hover` on `surface-sunken` |
| Button, disabled | `surface-sunken` fill, `text-disabled` label, `border` border, real `disabled` attribute |
| Focus ring | 2px `focus-ring`, offset 2px — visible on every surface in both themes |
| Input | `surface` fill, `border-input` border, label above, help text below in `text-muted` |
| Badge, tinted | `{kind}-bg` fill, `{kind}-text` label, `{kind}-border` border |
| Badge, solid | `{kind}-solid` fill, `{kind}-on-solid` label |
| Alert | `{kind}-bg` fill, `{kind}-border` border (3px at the left edge), `{kind}-text` copy |
| Tabs | selected tab on `surface-selected` with a 2px `accent` underline |
| Code block | `font-mono` at 14px on `surface-sunken`, hairline `border` |

Badge and alert copy uses past-tense event names — delivered, deferred,
bounced, queued — facts, not promises.

## Logo System

The mark is the back of an envelope drawn entirely in light: a landscape
pane, a lit fold descending from the top edge, and a round seal straddling
the bottom edge — lit inside the pane, solid outside it. The envelope is
never outlined; light does all the drawing. One even-odd path in mono; two
layered fills in color. Every opening is a void, so the ground shows through.

### Asset manifest

| File | What it is |
|---|---|
| `assets/logo-primary.svg` | Mark + wordmark tight lockup, light expression — the flagship |
| `assets/logo-typemark.svg` | The hand-drawn wordmark alone, currentColor-friendly |
| `assets/logo-mark.svg` | The mark alone, light expression |
| `assets/logo-monochrome.svg` | The lockup as pure currentColor — one even-odd path |
| `assets/logo-with-tagline.svg` | Primary plus tagline — the only asset carrying the subtitle |
| `assets/favicon.svg` | 16-grid redraw in two shapes; pane flips for OS dark mode |
| `assets/social-avatar.svg` | Square avatar, light expression — the plate exception |
| `assets/social-avatar-dark.svg` | Square avatar, dark expression |

### Color program

| Context | Pane | Seal (outer half) | Light regions |
|---|---|---|---|
| Light surfaces | Ink `#0D1B2A` | Glass `#277B96` | background shows through |
| Dark surfaces | Mist `#EAF6FB` | Ice `#A6EAF2` | background shows through |
| Mono / hostile contexts | currentColor, one even-odd path | — | voids |

### Usage rules

- `logo-primary.svg` belongs on light grounds only. On dark grounds use
  `logo-monochrome.svg` (inherits the surrounding text color) or the dark
  expression (Mist pane, Ice seal). Never the light primary on dark — the
  Ink pane vanishes.
- `favicon.svg` adapts on its own: the pane flips Ink to Mist under the OS
  dark preference; the Glass seal holds in both.
- The tagline ("Email, made visible." in Slate, outlined) appears only in
  `logo-with-tagline.svg`.
- Minimum sizes: the full mark holds to 24px; below that, the favicon
  redraw. Lockups hold to 20px of wordmark height. Clear space on every side
  equals the seal's visible half — one quarter of the mark's height.

### Do / Don't

| Do | Don't |
|---|---|
| Light expression on Paper, Mist, white | Light primary on any dark ground |
| Monochrome or dark expression on Ink | A background plate behind the mark (square avatars excepted) |
| Let the ground show through the voids | Outline the envelope — light does the drawing |
| Tagline via `logo-with-tagline.svg` only | Anything that reads broken, severed, or fractured |

## Specimens & Applications

| Surface | Assets | Tokens that matter most | The rule it must honor |
|---|---|---|---|
| README header | `logo-primary.svg` or a drawn banner | Ink, Glass, Paper | Outlined paths; renders without any installed font |
| Docs page | `logo-mark.svg` in the sidebar | text, link, surface-sunken | Accent text routes through `accent-text` `#1D637A` on tinted grounds |
| Landing page | `logo-primary.svg`, `logo-typemark.svg` | the full role set, both themes | Left-aligned composition; dark mode demonstrated, not promised |
| Transactional email | `logo-primary.svg` on a light ground | explicit hex equivalents, inlined | No open/click tracking on auth mail; calm, specific copy |
| Social card | `social-avatar.svg`, the 1200×630 card template | Ink, Glass, Paper | Export to PNG locally; never publish the SVG directly |
| Diagram language | pane motif, mark geometry | accent, border-strong, surfaces | Flat fills, one stroke weight, no gradients; voids read as light |

## Usage & Export Policy

| Category | What | Policy |
|---|---|---|
| Committed | SVG assets, `tokens.json`, `tokens.css`, `index.html`, this document, `README.md` | Text artifacts only — every change reads in review |
| Generated locally | PNG exports of the social card (1200×630) and avatars at platform sizes; `.ico` if a host demands one | Produce when a launch surface needs them; regenerate from SVG sources at will |
| Never ships | Binaries, font files, rasters, screenshots | If it can't be diffed, it doesn't belong here |

The social-card SVG is a template: link-preview crawlers do not render SVG,
so the published preview image is always a local PNG export. Fonts follow
the same logic — Inter and IBM Plex Mono are the brand faces when installed;
nothing is embedded or downloaded, and the wordmark is already outlined
inside every asset.
