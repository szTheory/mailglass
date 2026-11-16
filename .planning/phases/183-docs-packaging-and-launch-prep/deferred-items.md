# Deferred Items

- The Task 2 Admin suite emitted the existing warning that `MailglassDemo.QuickViewScenarios` is not included in any boundary (`reference/persona_spec/quick_view_scenarios.ex:0`). No related source was changed; assign its boundary ownership in a separate cleanup.
- The required root docs suite still reports the existing skipped Phase 38 prepublish-proof contract (`test/mailglass/docs_contract_test.exs:812`). Its original artifact was archived and the current release record has a different section structure; keep the test skip until its assertions are intentionally re-pinned.
- The best-effort `gsd windows append` for that skipped test could not update `.planning/WINDOWS.md` because its rendered table and fenced JSON disagree for existing row 48. The ledger was left untouched; repair that pre-existing inconsistency before retrying the append.
