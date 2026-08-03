defmodule Mailglass.Outbound.DispatchOutcomeTest do
  use ExUnit.Case, async: true

  @moduletag phase_151_task: :t151_02_01

  alias Mailglass.{ConfigError, SendError, SuppressedError}
  alias Mailglass.Outbound.DispatchOutcome

  describe "classify/1" do
    test "preserves accepted adapter results" do
      acceptance = %{message_id: "provider-123", provider_response: %{id: "provider-123"}}

      assert {:accepted, ^acceptance} = DispatchOutcome.classify({:ok, acceptance})
    end

    test "maps structured 4xx provider evidence to a terminal outcome" do
      error =
        SendError.new(:adapter_failure,
          context: %{provider_status: 422, reason_class: :client_error}
        )

      assert %DispatchOutcome{class: :terminal, reason_class: :provider_client_rejected} =
               DispatchOutcome.classify({:error, error})
    end

    test "maps structured 5xx provider evidence to a retryable outcome" do
      error =
        SendError.new(:adapter_failure,
          context: %{provider_status: 503, reason_class: :server_error}
        )

      assert %DispatchOutcome{class: :retryable, reason_class: :provider_server_error} =
               DispatchOutcome.classify({:error, error})
    end

    test "only retries explicit before-acceptance transport evidence" do
      error =
        SendError.new(:adapter_failure,
          context: %{reason_class: :transport, dispatch_evidence: :before_acceptance}
        )

      assert %DispatchOutcome{class: :retryable, reason_class: :transport_before_acceptance} =
               DispatchOutcome.classify({:error, error})
    end

    test "treats timeout, opaque adapter failures, and arbitrary values as uncertain" do
      timeout = SendError.new(:adapter_failure, context: %{reason_class: :transport})

      for evidence <- [{:error, timeout}, {:error, :timeout}, {:error, %{error: "opaque"}}, :exit] do
        assert %DispatchOutcome{
                 class: :uncertain,
                 reason_class: :provider_acceptance_unknown
               } = DispatchOutcome.classify(evidence)
      end
    end

    test "maps known local typed failures to terminal outcomes" do
      for error <- [
            SendError.new(:preflight_rejected, context: %{reason_class: :suppressed}),
            ConfigError.new(:missing, context: %{key: :adapter}),
            SuppressedError.new(:address, context: %{})
          ] do
        assert %DispatchOutcome{class: :terminal, reason_class: :pre_dispatch_failure} =
                 DispatchOutcome.classify({:error, error})
      end
    end
  end

  describe "constructors and safe_projection/1" do
    test "rejects invalid classes and reason classes" do
      assert_raise ArgumentError, ~r/invalid dispatch outcome class/, fn ->
        DispatchOutcome.new(:accepted, :provider_client_rejected)
      end

      assert_raise ArgumentError, ~r/invalid dispatch outcome reason class/, fn ->
        DispatchOutcome.new(:terminal, :unbounded_reason)
      end
    end

    test "projects only bounded reason and correlation facts" do
      outcome =
        DispatchOutcome.terminal(:provider_client_rejected,
          provider_status: 422,
          body_preview: "provider text that must not escape",
          cause: "exception text that must not escape",
          correlation_id: "provider-123"
        )

      assert %{
               class: :terminal,
               reason_class: :provider_client_rejected,
               correlation: %{availability: :available, identifier: "provider-123"}
             } = DispatchOutcome.safe_projection(outcome)

      projection = DispatchOutcome.safe_projection(outcome)
      refute Map.has_key?(projection, :provider_status)
      refute inspect(projection) =~ "provider text"
      refute inspect(projection) =~ "exception text"
    end

    test "marks absent correlation without exposing raw context" do
      projection =
        DispatchOutcome.safe_projection(DispatchOutcome.uncertain(:provider_acceptance_unknown))

      assert projection.correlation == %{availability: :unavailable}
      assert Map.keys(projection) |> Enum.sort() == [:class, :correlation, :reason_class]
    end
  end

  test "classifier source does not use text matching" do
    source = File.read!("lib/mailglass/outbound/dispatch_outcome.ex")

    refute source =~ "Exception.message"
    refute source =~ "inspect("
    refute source =~ "String.contains?"
    refute source =~ "Regex"
  end
end
