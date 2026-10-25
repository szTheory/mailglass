---
created: 2026-10-25
source: owner feedback while reviewing the PR #302 candidate (4ed3ada1)
area: mailglass_admin operator overview (/ops/mail?tenant_id=northstar, "Email health")
priority: next UI milestone (SEED-009); not blocking v2.9
---

# Health overview: two-column layout looks crowded and undesigned

The owner's words: "the display there kind of awkward with the two columns... a bit crowded i guess it's okay but from a graphic design pov visually it looks kind of ugly." This was at desktop width, dark theme.

Diagnosis (Claude, to be validated in the SEED-009 rubric review):
- The "Needs attention" rows span about 1000px while the content sits in the left 300px, so most of each row is an empty divider line.
- The "Recent activity" column floats with no visual relationship to the list, which causes the two-column awkwardness.
- Every row is an underlined link plus an (i) icon, at equal weight: 7 info icons and no hierarchy or severity ordering. Rows with a count of 1 look identical to severe ones.
- The meta row ("Last 7 days" vs "Last checked ... Refresh health") is split across the full width with no grouping.

Handle it as a screen story (operator/overview) with northstar/fjordline/helios data at 375/768/1280/1440 in both themes. Fix it at the lowest tier that owns the problem (the health list pattern before the page).

## Keep (the owner likes these; do not regress them)

- "Needs attention" items are specific (e.g. "2 Bounced deliveries", "1 Unrouted inbound messages"), not a generic health score.
- Each item links to the section of the UI where the operator can act on it or get the information needed to fix it.

The redesign changes the layout and hierarchy only. Every item stays specific and each keeps its deep link. Add a story or e2e check that every item's link lands on a filtered view that shows the matching records. The owner said it works "in theory", so verify that it does in practice.
