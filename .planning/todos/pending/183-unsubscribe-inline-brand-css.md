# Replace legacy inline brand CSS in the unsubscribe page

## Owner

Core maintainers when this work is scheduled. Keep the recipient-facing design
decision within the scope of a future reviewed task.

## Context

`lib/mailglass/compliance/unsubscribe_html/` still contains inline CSS using the
retired Inter font and v1 color values. The current `.impeccable/config.json`
exception is scoped only to this subtree so it does not hide Inter elsewhere.
The v2 font and color authority is `brandbook/v2/brand.json` with resolved
values in `brandbook/tokens.json`.

Leave the unsubscribe template's styling and behavior unchanged until a future
task updates this surface and its recipient-facing rendering tests together.

## Exit condition

- Replace the remaining retired font and color values with approved v2 roles or
  inherit the host application's styles where that is the documented contract.
- Verify the rendered GET page in its existing light/dark and narrow viewport
  checks without changing redirect or protocol POST behavior.
- Remove the file-scoped `overused-font` exception through the `impeccable`
  CLI and confirm the scoped detector run is clean.
