---
id: SEED-005
status: archived
updated: 2026-07-31
note: Deferred at v2.2 close; retained as compatibility-sensitive future reference only.
planted: 2026-07-19
planted_during: v2.1 archived / awaiting next milestone
trigger_when: when planning renderer APIs, Mailable ergonomics, preview assigns, or template integration
scope: medium
---

# SEED-005: Native HEEx Assigns Through the Rendering Pipeline

## Why This Matters

Mailglass presents one production renderer to delivery and preview, and its
public data model already carries `Message.assigns`. The HEEx template engine
also accepts an assigns map. Those pieces do not currently meet: the Renderer
invokes a function component with an empty map, while the default
`Mailable.render/3` ignores its template and assigns arguments. The documented
common path therefore renders dynamic HEEx in adopter code first, then passes
the resulting HTML string through Mailglass for plaintext generation, CSS
inlining, Outlook-safe output preservation, and authoring-hint cleanup.

Closing this seam would make the native authoring story match the architectural
promise: build one Message with assigns, run the same deterministic render
pipeline in preview and delivery, and persist only the provider-ready artifact
for async dispatch. It would also remove ambiguity about whether Mailglass or
the adopter owns template resolution and assign binding.

## When to Surface

**Trigger:** when planning renderer APIs, Mailable ergonomics, preview assigns,
or template integration.

Surface this seed before documenting native function-component rendering as
the primary path or changing any stable Message, Mailable, Renderer, or preview
contract.

## Scope Estimate

**Medium** — a focused phase spanning public authoring types, Renderer input
semantics, preview/production parity, compatibility tests, async snapshot
boundaries, and user-facing guides.

## Breadcrumbs

- `lib/mailglass/message.ex` — `Message.assigns` exists, while `html_body/2` is
  currently specified for strings.
- `lib/mailglass/renderer.ex` — function-component rendering currently passes
  `%{}` rather than `Message.assigns`.
- `lib/mailglass/mailable.ex` — the default `render/3` ignores its template and
  assigns arguments.
- `lib/mailglass/template_engine/heex.ex` — the HEEx engine already accepts a
  component function and assigns map.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` — preview must continue
  to use the same render truth as production delivery.
- `guides/components.md` — the current dynamic-component example renders to a
  string before calling Mailglass.
- `test/mailglass/renderer_test.exs` — covers component rendering and the
  email-specific transformation pipeline, but not Message-assign propagation.

## Notes

Future planning should decide, explicitly:

- whether `html_body/2` widens to accept a component function or a new native
  component-body setter is introduced;
- whether `Renderer.render/2` always passes `Message.assigns`, and how missing
  assigns remain typed as `Mailglass.TemplateError`;
- whether the stable `Mailable.render/3` callback becomes meaningful, is
  narrowed, or begins a deprecation path;
- how `preview_props/0` values become Message assigns without creating a second
  preview-only rendering path;
- how already-rendered HTML remains backward compatible;
- how tests prove preview and production produce identical HTML and plaintext;
  and
- how the async boundary remains post-render so jobs persist a deterministic
  artifact rather than executable template state.

Do not fold this into an architecture-doc correction. It changes runtime and
potentially stable authoring behavior and deserves its own compatibility-aware
plan.
