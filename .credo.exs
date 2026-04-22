%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      }
      # Phase 6 adds custom LINT-01..LINT-12 checks here.
    }
  ]
}
