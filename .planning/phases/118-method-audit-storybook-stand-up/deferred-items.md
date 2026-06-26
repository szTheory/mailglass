# Deferred Items — Phase 118

Out-of-scope discoveries logged during execution (NOT fixed in their discovering plan).

## From Plan 118-01

### `mix verify.preview` rebuilds `priv/static/app.css` (pre-existing token-parity bundle landmine)

- **Discovered during:** Plan 118-01 verification step (the load-bearing `app.css` drift gate).
- **What happens:** `cd mailglass_admin && mix verify.preview` runs a fresh Tailwind/daisyUI
  build that emits a `priv/static/app.css` differing from the committed bundle (one line:
  the daisyUI 5.5.x raw-inline `@layer properties` block), so `git diff --exit-code priv/static/`
  reports drift and the alias fails — even with NO source change to admin CSS.
- **Why it is out of scope for 118-01:** Plan 118-01 added nothing under `mailglass_admin/`
  (`git diff ae120bb8~1 HEAD -- mailglass_admin/lib mailglass_admin/assets` is empty). The
  committed `priv/static/app.css` is byte-identical across all three Plan-01 commits — the
  Plan-01 invariant ("my changes don't rebuild/alter app.css") holds. The drift is a working-tree
  side-effect of verify.preview's own rebuild, reverted with `git checkout -- priv/static/app.css`.
- **Known issue:** This matches the documented "token-parity bundle landmine" — the committed
  `app.css` is canonical/stale; a fresh `mix assets.build` emits raw-inline theme blocks that break
  the parity/drift gate. Do NOT rebuild + commit blindly.
- **Action:** None taken in 118-01 (out of scope, milestone-wide tooling condition). A milestone
  owner should decide whether to refresh the committed bundle deliberately (coordinated, not a
  blind rebuild) in a later phase that actually touches admin CSS.
