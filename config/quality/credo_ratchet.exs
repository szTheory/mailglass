%{
  configs: [
    %{
      name: "default",
      strict: true,
      color: false,
      files: %{
        included: ["lib/", "test/", "mailglass_inbound/lib/", "mailglass_inbound/test/"],
        excluded: []
      },
      checks: %{
        enabled: [
          {Credo.Check.Refactor.Nesting, [max_nesting: 2]},
          {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 9]}
        ],
        disabled: []
      }
    }
  ]
}
