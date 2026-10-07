# Deferred Items

- The focused invalid-filter assertions searched the full LiveView document for `not-real`, which also appears in the embedded Phoenix client bundle. Plan 168-02 narrowed the operator assertion to the filter's actual option DOM. The equivalent inbound assertion remains to be corrected in Task 2.
- Resolved in Plan 168-02 Task 1: `.mg-stat-card-tooltip` previously caused document overflow on Health (1px at 320 CSS px; 164px at 768px). The tooltip is now constrained to its stat card. Rendered review at 320, 390, 768 and 1440 CSS px in light and dark found document and body scroll widths equal to the viewport; the 720px equivalent-width check also remained bounded. See `168-BASELINE.md` Task 1 evidence and `artifacts/plan02/` captures. Windows ledger item #37 is fixed.
