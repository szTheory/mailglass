# Deferred Items

- `mix ci` is blocked by pre-existing formatting failures in `test/mailglass/docs_contract_test.exs` and `lib/mailglass/optional_deps/oban.ex`. Neither file was modified by Plan 153-07.
- The all-stage local generated-host command was invoked, but only its `migrate` checkpoint was left in `tmp/generated-host-proof/checkpoint.json`; a complete all-stage result was not observed in this execution environment.
- Protected CI for an immutable candidate SHA is not available: this plan did not push, dispatch, tag, or use credentials.
