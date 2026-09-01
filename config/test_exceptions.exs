%{
  exceptions: [
    %{
      source: "mailglass_inbound/test/mailglass_inbound/async_execution_test.exs:365",
      kind: :sleep,
      owner: "inbound",
      reason: "router-registry restart polling",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/rate_limiter_supervision_test.exs:45",
      kind: :sleep,
      owner: "core",
      reason: "supervisor restart liveness",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/repo_multi_test.exs:134",
      kind: :skip,
      owner: "core",
      reason: "optional Oban integration",
      expires_on: ~D[2026-12-31],
      category: :optional_dependency
    },
    %{
      source: "test/mailglass/events/reconciler_test.exs:77",
      kind: :sleep,
      owner: "core",
      reason: "reconciler liveness",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/outbound/deliver_later_test.exs:56",
      kind: :sleep,
      owner: "core",
      reason: "sandbox teardown settlement",
      expires_on: ~D[2026-12-31],
      category: :teardown
    },
    %{
      source: "test/mailglass/outbound/deliver_later_test.exs:123",
      kind: :sleep,
      owner: "core",
      reason: "task supervisor dispatch is not externally acknowledged without runtime changes",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/webhook/ingest_test.exs:297",
      kind: :sleep,
      owner: "core",
      reason: "database statement-timeout stress primitive",
      expires_on: ~D[2026-12-31],
      category: :db_timeout
    },
    %{
      source: "test/mailglass/test_support/sandbox_ownership_test.exs:537",
      kind: :sleep,
      owner: "core",
      reason: "deliberately live ownership fixture",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/compliance/unsubscribe_test.exs:185",
      kind: :sleep,
      owner: "core",
      reason: "token TTL boundary",
      expires_on: ~D[2026-12-31],
      category: :ttl
    },
    %{
      source: "test/mailglass/suppression_store/ets_test.exs:223",
      kind: :sleep,
      owner: "core",
      reason: "ETS supervisor liveness",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/compliance/unsubscribe_controller_test.exs:163",
      kind: :sleep,
      owner: "core",
      reason: "token TTL boundary",
      expires_on: ~D[2026-12-31],
      category: :ttl
    },
    %{
      source: "test/mailglass/compliance/unsubscribe_controller_test.exs:278",
      kind: :sleep,
      owner: "core",
      reason: "token TTL boundary",
      expires_on: ~D[2026-12-31],
      category: :ttl
    },
    %{
      source: "test/mailglass/application_test.exs:60",
      kind: :skip,
      owner: "core",
      reason: "application startup fixture",
      expires_on: ~D[2026-12-31],
      category: :fixture
    },
    %{
      source: "test/mailglass/application_test.exs:105",
      kind: :skip,
      owner: "core",
      reason: "application startup fixture",
      expires_on: ~D[2026-12-31],
      category: :fixture
    },
    %{
      source: "test/mailglass/install/install_idempotency_test.exs:107",
      kind: :skip,
      owner: "core",
      reason: "legacy installer fixture",
      expires_on: ~D[2026-12-31],
      category: :fixture
    },
    %{
      source: "test/mailglass/install/install_idempotency_test.exs:144",
      kind: :skip,
      owner: "core",
      reason: "legacy installer fixture",
      expires_on: ~D[2026-12-31],
      category: :fixture
    },
    %{
      source: "test/mailglass/outbound/deliver_many_test.exs:69",
      kind: :sleep,
      owner: "core",
      reason: "fake adapter async fixture",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/adapters/fake_test.exs:130",
      kind: :sleep,
      owner: "core",
      reason: "fake adapter supervisor liveness",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/adapters/fake_test.exs:275",
      kind: :sleep,
      owner: "core",
      reason: "fake adapter supervisor liveness",
      expires_on: ~D[2026-12-31],
      category: :liveness
    },
    %{
      source: "test/mailglass/docs_contract_test.exs:482",
      kind: :skip,
      owner: "core",
      reason: "documented compatibility fixture",
      expires_on: ~D[2026-12-31],
      category: :fixture
    },
    %{
      source: "test/mailglass/tenancy_test.exs:154",
      kind: :flaky,
      owner: "core",
      reason: "legacy tenancy race under investigation",
      expires_on: ~D[2026-12-31],
      category: :liveness
    }
  ]
}
