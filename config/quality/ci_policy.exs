%{
  active_required: [
    "compile_no_optional_deps",
    "installer_host_smoke",
    "mix_task_tests",
    "support_contract_core",
    "support_contract_admin",
    "trust_lane_repo_head",
    "hex_audit",
    "deps_audit_advisory"
  ],
  target_required: [
    %{id: "format_check", behavior: :formatting},
    %{id: "compile_warnings", behavior: :warning_and_no_optional_builds},
    %{id: "compile_no_optional_deps", behavior: :warning_and_no_optional_builds},
    %{id: "support_contract_core", behavior: :support_contracts},
    %{id: "support_contract_admin", behavior: :support_contracts},
    %{id: "inbound_test", behavior: :deterministic_inbound_suite},
    %{id: "core_deterministic_suite", behavior: :deterministic_core_suite},
    %{id: "mix_task_tests", behavior: :mix_tasks},
    %{id: "credo_strict", behavior: :credo_and_conformance},
    %{id: "docs_warnings_as_errors", behavior: :docs},
    %{id: "dialyzer", behavior: :core_dialyzer},
    %{id: "inbound_dialyzer", behavior: :inbound_dialyzer},
    %{id: "hex_audit", behavior: :audits},
    %{id: "deps_audit_advisory", behavior: :audits},
    %{id: "trust_lane_repo_head", behavior: :trust},
    %{id: "installer_host_smoke", behavior: :installer_proofs},
    %{id: "installer_golden_gate", behavior: :installer_proofs}
  ],
  advisory: [
    "operator_browser_gate",
    "demo_browser_evidence",
    "preview_capture_advisory",
    "provider_live",
    "core_full_suite_next_toolchain_advisory",
    "trust_lane_clean_baseline",
    "publish_hex"
  ]
}
