# Phase 172: Recipient Output and Built-in Pages — Pattern Map

**Mapped:** 2026-10-09  
**Files analyzed:** 11 likely implementation/test/doc surfaces  
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/components.ex` | component | transform/render | `lib/mailglass/components.ex` (same components) | exact |
| `lib/mailglass/renderer.ex` | utility | transform | `lib/mailglass/renderer.ex` (`to_plaintext/1`) | exact |
| `reference/demo_app/lib/mailglass_demo_web/mailers/*` (one named Mailable or an added scenario) | Mailable/example | request-response/build | `.../mailers/account_mailer.ex` plus `.../atlas_desk_email.ex` | role-match |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | controller | request-response | same controller | exact |
| `lib/mailglass/compliance/unsubscribe_html.ex` and `unsubscribe_html/*.heex` | view/template | request-response | `unsubscribe_html/confirm.html.heex` | exact |
| `test/mailglass/renderer_test.exs` | test | transform | same test | exact |
| `test/mailglass/components/*_test.exs` (as needed) | test | transform | `button_test.exs`, `row_test.exs`, `vml_preservation_test.exs` | role-match |
| `test/mailglass/compliance/unsubscribe_controller_test.exs` | test | request-response | same test | exact |
| `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` | test | request-response/build | same test | exact |
| `guides/components.md`, `guides/authoring-mailables.md`, `guides/unsubscribe.md` | documentation | batch | each existing guide | exact |
| Existing preview registry/scenario listing (if registration requires an edit) | registry/config | request-response | `reference/demo_app/lib/mailglass_demo_web/router.ex` and current Mailable registration | role-match |

Paths are candidates inferred from phase context/research; planner should keep the actual edit set to the smallest set that delivers MAILUX-01..04. All named analogs above are git-tracked source files.

## Pattern Assignments

### Public components and email markup

**Analogs:** `lib/mailglass/components.ex`; `test/mailglass/components/button_test.exs`; `test/mailglass/components/row_test.exs`; `test/mailglass/components/vml_preservation_test.exs`.

`Mailglass.Components` uses Phoenix.Component and aliases only local CSS/theme helpers (`components.ex:34-39`). Content components use declared `attr/slot` contracts and HEEx slot rendering (`components.ex:226-264,279-305`). The container is a fluid outer presentation table with a 600px inner table and `max-width:600px;width:100%` fallback (`components.ex:78-99`). Button retains VML plus ordinary HTML anchor fallback and `data-mg-plaintext="link_pair"` (`components.ex:327-378`); the link component also marks the anchor so the renderer can preserve its destination (`components.ex:437-467`). Images require `alt` and use `max-width:100%` (`components.ex:405-429`).

**Tests:** component tests initialize theme state in `setup`, render the public component function through `Phoenix.HTML.Safe.to_iodata/1`, then assert stable semantic/compatibility markers. For example, `button_test.exs:11-25,44-80` checks VML, fallback, plaintext marker, slot label, and href. `row_test.exs:11-21,48-88` checks presentation fallbacks and width semantics. Use these narrow contracts when changing structure; `vml_preservation_test.exs:31-84` guards CSS inlining and conditional-comment survival. Do not turn markup tests into claims about Gmail/Outlook delivered rendering.

### Renderer plaintext extraction

**Analog:** `lib/mailglass/renderer.ex`; **test analog:** `test/mailglass/renderer_test.exs`.

Keep the pipeline ordering: render HTML, derive plaintext from the pre-inlined logical tree, inline CSS, then strip internal markers (`renderer.ex:63-84,109-138`). The current walker dispatches strategy markers in one place and recurses for the default case (`renderer.ex:141-227`); whitespace is normalized centrally (`renderer.ex:229-234`). Preserve marked button/link `Label (url)` behavior (`renderer.ex:177-187`), heading formatting, image-alt text and the skip strategy. The gap is default anchor traversal: it visits descendants but never emits the enclosing `href`; `text` strategy flattens descendants using `Floki.text/1`, so it also bypasses nested links. Make the smallest traversal change that can retain descendant reading order and emit each useful destination once; avoid adding parallel HTML parsing or changing the renderer pipeline.

`renderer_test.exs:1-13` provides shared theme setup; `:61-101` asserts end-to-end generated message text and marker stripping. The focused `to_plaintext/1` tests at `:182-235` use small HTML strings and direct assertions for strategy behavior. Extend this table-driven/direct style for nested anchors in text, ordinary unmarked anchors, marked component links, empty `href`, URL-once behavior, paragraph/heading order, Unicode, and image alternative content. Generated `text_body` ownership is explicitly renderer-defined in this phase; preserve it.

### Public-component demo Mailable beside AtlasDesk

**Analogs:** `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`; `.../mailers/atlas_desk_email.ex`; `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs`.

The existing Mailable declares its stream, aliases `Mailglass.Message`, publishes deterministic preview props, builds from/to/subject/body, and finishes with `Message.put_function/2` (`account_mailer.ex:1-23,25-47`). AtlasDesk's bespoke HTML function is plainly separated and escapes dynamic strings before interpolation (`atlas_desk_email.ex:15-28,30-77,80-90,118-145`). Keep that path unchanged and name/label the new public-component scenario so its source is inspectable. Use Phoenix.Component/HEEx and `Mailglass.Components` for that scenario; reuse the AtlasDesk identity, not the HTML helper. Use `Message.html_body/2` with the supported function-component path rather than building a second renderer; `Mailglass.Renderer` accepts a one-arity HEEx function (`renderer.ex:40-58,87-97`).

The current preview test checks deterministic scenario keys, Mailable function, sender, recipient, subject, and realistic content (`mailer_preview_scenarios_test.exs:8-42,128-145`). Add parallel assertions for the new scenario plus rendered component-specific long/narrow, non-ASCII, alt text and link destination evidence. The router's Mailable list is explicit (`reference/demo_app/lib/mailglass_demo_web/router.ex:77-92`); only edit it if required for discoverability. Avoid converting the existing AtlasDesk examples to components.

### Unsubscribe pages and protocol preservation

**Analogs:** `lib/mailglass/compliance/unsubscribe_controller.ex`; `lib/mailglass/compliance/unsubscribe_html.ex`; `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex`; `test/mailglass/compliance/unsubscribe_controller_test.exs`.

`show/2` verifies the token and fetches the delivery, then chooses valid render/redirect or distinct expired/invalid responses (`unsubscribe_controller.ex:24-33`). Valid GET uses the configured redirect as an escape hatch and otherwise renders the embedded HEEx view (`:52-61`). Preserve this dispatch and response status boundary; render state-specific content in HEEx instead of concatenating strings in `failure/3` (`:64-68`). The existing page gives the basic standalone document structure, viewport, inline page colors, narrow max-width main panel and a single heading (`confirm.html.heex:1-19`). Replace misleading confirmation copy and avoid recipient/token details for error states; all dynamic values that remain should stay as ordinary HEEx interpolation and be escaped.

Do not merge GET with POST: `unsubscribe/2` is the separate mutation path (`unsubscribe_controller.ex:36-50,80-115`), and idempotent response behavior is handled later (`:133-152`). Existing tests establish default GET, configured redirect, 410 expired, 404 invalid/tampered (`unsubscribe_controller_test.exs:124-185`). POST tests establish single event/idempotency, replay behavior and invalid/expired no-write behavior (`:187-315`). Add GET assertions for informational copy, no form, no sensitive values on recovery pages, and unchanged status/redirects; preserve the POST tests as regression coverage rather than rewriting their fixtures/semantics.

### Guides and demo integration

**Analogs:** `guides/components.md`; `guides/authoring-mailables.md`; `guides/unsubscribe.md`; demo router and preview test above.

Guides use a concise task-oriented heading, runnable Elixir examples, and explicit code path. Components guide shows `use Phoenix.Component`, imports `Mailglass.Components`, composes nested components in `~H`, then wires the component through a Mailable (`components.md:10-47`). Authoring guide uses `Mailglass.Mailable` and common `Mailglass.Message` setters (`authoring-mailables.md:11-55`). Follow those existing contracts and ensure examples match actual registered demo code; do not introduce a guide-only fake template. Unsubscribe guide should state GET/POST distinction exactly as implemented.

## Shared Patterns

### Escaped rendering

Keep dynamic user/demo data in HEEx interpolation (`{value}` or `<%= @value %>` in embedded templates), not `Phoenix.HTML.raw/1` or interpolated HTML strings. The component library composes slots through HEEx (`components.ex:246-263,302-305,376-378`); the page template uses HEEx interpolation (`confirm.html.heex:15`). AtlasDesk's older bespoke helper demonstrates manual escaping for the distinct legacy path (`atlas_desk_email.ex:80-90,118-145`), but should not be copied for the new public-component example or new failure pages.

### Email output and access semantics

Keep layout tables `role="presentation"`, essential copy as live text, component-provided `alt`, fluid table width with max-width fallback, and natural content height. Preserve inline style and existing VML/MSO branches; verify conditional preservation using the golden fixture pattern. Component output checks demonstrate the library's output, not third-party recipient-client rendering.

### Test scope and CI

Prefer existing ExUnit owners: `renderer_test.exs`, `unsubscribe_controller_test.exs`, focused component tests, and the reference demo preview test. Current CI lane boundaries and regression script are documented in `.github/workflows/ci.yml` and `scripts/gsd-regression-gate.sh`; do not add a dependency or promote preview evidence into a new required lane. Keep output assertions specific to observable contracts: generated HTML/text, status/body/redirect, absence of mutation on GET, and idempotent POST.

## No Analog Found

No missing role-level analog. The phase has no existing state-specific invalid/expired HEEx page template; use the current embedded confirmation template as the document-shell analog, with controller status selection retained. A public-component Mailable is also not currently present in the demo; combine the account Mailable construction with the existing public component usage shown in `guides/components.md` and `renderer_test.exs:107-117`.

## Metadata

**Analog search scope:** `lib/mailglass`, `test/mailglass`, `guides`, `reference/demo_app/lib`, `reference/demo_app/test`  
**Tracked-source check:** all named analogs verified by `git ls-files`  
**Pattern extraction date:** 2026-10-09
