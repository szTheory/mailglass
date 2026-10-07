# Deferred Items

- The focused LiveView batch `operator/shell_test.exs`, `operator_live_test.exs`, and `inbound_live_test.exs` reported two failures in existing invalid-filter tests. Both assert `refute html =~ "not-real"`, but the rendered LiveView page embeds Phoenix client JavaScript containing the same literal. The failure is unrelated to the shared Account shell edits; the other 172 tests passed. Deferred for the owning test cleanup.
- Required responsive review found document-level horizontal overflow from the existing invisible `.mg-stat-card-tooltip` on the Health overview: 1px at 320 CSS px and 164px at 768px. The toolbar/navigation fit; the tooltip issue is outside this plan's source ownership and needs correction in the overview/stat-card styling work.
