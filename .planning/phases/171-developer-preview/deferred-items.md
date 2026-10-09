# Deferred Items

No open deferred items remain for Phase 171.

The two stale advisory assertions below were updated to match the approved Phase 171 behavior and
are covered by the passing connected browser gate documented in `171-REGRESSION.md`:

- The assigns form now renders supported scalar edits automatically, so the flow asserts a visible
  Reset action and absence of a redundant Render action.
- The compact picker intentionally exposes the full active Mailable identity on mobile, so the
  structural check asserts that full identity and the selected scenario.
