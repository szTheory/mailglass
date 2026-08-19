%{
  promotion_ready: true,
  active_required: [
    "format_check",
    "compile_warnings",
    "compile_no_optional_deps",
    "inbound_compile_no_optional_deps",
    "support_contract_core",
    "support_contract_admin",
    "inbound_test",
    "core_deterministic_suite",
    "mix_task_tests",
    "credo_strict",
    "conformance_gates",
    "docs_warnings_as_errors",
    "dialyzer",
    "inbound_dialyzer",
    "hex_audit",
    "deps_audit_advisory",
    "trust_lane_repo_head",
    "installer_host_smoke",
    "installer_golden_gate"
  ],
  target_required: [
    %{
      id: "format_check",
      name: "Format Check (Elixir 1.18 / OTP 27)",
      behavior: :formatting,
      local_alias: "format --check-formatted"
    },
    %{
      id: "compile_warnings",
      name: "Compile Warnings as Errors (Elixir 1.18 / OTP 27)",
      behavior: :warning_and_no_optional_builds,
      local_alias: "compile --warnings-as-errors"
    },
    %{
      id: "compile_no_optional_deps",
      name: "Compile No Optional Deps (Elixir 1.18 / OTP 27)",
      behavior: :warning_and_no_optional_builds,
      local_alias: "compile --no-optional-deps --warnings-as-errors"
    },
    %{
      id: "inbound_compile_no_optional_deps",
      name: "Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)",
      behavior: :warning_and_no_optional_builds,
      local_alias: "mailglass_inbound mix compile --no-optional-deps --warnings-as-errors"
    },
    %{
      id: "support_contract_core",
      name: "Support Contract Core (Elixir 1.18 / OTP 27)",
      behavior: :support_contracts,
      local_alias: "verify.support_contract.core"
    },
    %{
      id: "support_contract_admin",
      name: "Support Contract Admin (Elixir 1.18 / OTP 27)",
      behavior: :support_contracts,
      local_alias: "verify.support_contract.admin"
    },
    %{
      id: "inbound_test",
      name: "Inbound Test (Elixir 1.18 / OTP 27)",
      behavior: :deterministic_inbound_suite,
      local_alias: "mailglass_inbound mix test --exclude property"
    },
    %{
      id: "core_deterministic_suite",
      name: "Core Deterministic Suite (Elixir 1.18 / OTP 27)",
      behavior: :deterministic_core_suite,
      local_alias: "mix test --warnings-as-errors"
    },
    %{
      id: "mix_task_tests",
      name: "Mix Task Tests (Elixir 1.18 / OTP 27)",
      behavior: :mix_tasks,
      local_alias: "mix test --warnings-as-errors"
    },
    %{
      id: "credo_strict",
      name: "Credo Strict (Elixir 1.18 / OTP 27)",
      behavior: :credo_and_conformance,
      local_alias: "credo --strict"
    },
    %{
      id: "conformance_gates",
      name: "Design System Conformance (shell gates)",
      behavior: :credo_and_conformance,
      ci_only_reason:
        "The root parity alias intentionally has no Node/admin conformance dependency."
    },
    %{
      id: "docs_warnings_as_errors",
      name: "Docs Warnings as Errors (Elixir 1.18 / OTP 27)",
      behavior: :docs,
      local_alias: "docs --warnings-as-errors"
    },
    %{
      id: "dialyzer",
      name: "Dialyzer (Elixir 1.18 / OTP 27)",
      behavior: :core_dialyzer,
      local_alias: "mix dialyzer"
    },
    %{
      id: "inbound_dialyzer",
      name: "Inbound Dialyzer (Elixir 1.18 / OTP 27)",
      behavior: :inbound_dialyzer,
      local_alias: "mailglass_inbound mix dialyzer"
    },
    %{
      id: "hex_audit",
      name: "Hex Audit (Elixir 1.18 / OTP 27)",
      behavior: :audits,
      local_alias: "mailglass.audit --kind hex"
    },
    %{
      id: "deps_audit_advisory",
      name: "Deps Audit (Elixir 1.18 / OTP 27)",
      behavior: :audits,
      local_alias: "mailglass.audit --kind deps"
    },
    %{
      id: "trust_lane_repo_head",
      name: "Trust Lane Repo Head (Elixir 1.18 / OTP 27)",
      behavior: :trust,
      local_alias: "verify.reference_host.journey"
    },
    %{
      id: "installer_host_smoke",
      name: "Installer Host Smoke",
      behavior: :installer_proofs,
      local_alias: "consumer_install_smoke.sh"
    },
    %{
      id: "installer_golden_gate",
      name: "Installer Golden Gate (Elixir 1.18 / OTP 27)",
      behavior: :installer_proofs,
      ci_only_reason: "The golden host proof is intentionally isolated in its CI job."
    }
  ],
  advisory: [
    "operator_browser_gate",
    "demo_browser_evidence",
    "preview_capture_advisory",
    "provider_live",
    "core_full_suite_next_toolchain_advisory",
    "trust_lane_clean_baseline",
    "branch_protection_advisory",
    "publish_hex"
  ]
}
