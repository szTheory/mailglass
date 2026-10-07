# Deferred Items

- The focused LiveView batch `operator/shell_test.exs`, `operator_live_test.exs`, and `inbound_live_test.exs` reported two failures in existing invalid-filter tests. Both assert `refute html =~ "not-real"`, but the rendered LiveView page embeds Phoenix client JavaScript containing the same literal. The failure is unrelated to the shared Account shell edits; the other 172 tests passed. Deferred for the owning test cleanup.
