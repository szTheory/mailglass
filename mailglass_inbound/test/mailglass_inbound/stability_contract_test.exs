defmodule MailglassInbound.StabilityContractTest do
  use ExUnit.Case, async: true

  defp docs!(module) do
    assert {:docs_v1, _, :elixir, _, _, metadata, docs} = Code.fetch_docs(module)
    %{metadata: metadata, docs: docs}
  end

  defp entry_meta!(module, kind, name, arity) do
    %{docs: docs} = docs!(module)

    case Enum.find(docs, fn
           {{^kind, ^name, ^arity}, _, _, _, _} -> true
           _ -> false
         end) do
      {{^kind, ^name, ^arity}, _, _, _, meta} -> meta
      nil -> flunk("missing #{inspect(kind)} #{inspect(module)}.#{name}/#{arity} in compiled docs")
    end
  end

  defp has_entry?(module, kind, name, arity) do
    %{docs: docs} = docs!(module)

    Enum.any?(docs, fn
      {{^kind, ^name, ^arity}, _, _, _, _} -> true
      _ -> false
    end)
  end

  defp assert_module_since(module, since) do
    %{metadata: metadata} = docs!(module)
    assert metadata[:since] == since, "#{inspect(module)} missing moduledoc since metadata"
  end

  describe "stable runtime, error, and task modules expose moduledoc since metadata" do
    test "stable runtime modules are annotated" do
      assert_module_since(MailglassInbound, "0.1.0")
      assert_module_since(MailglassInbound.InboundMessage, "0.1.0")
      assert_module_since(MailglassInbound.Ingress.CachingBodyReader, "0.1.0")
      assert_module_since(MailglassInbound.Router, "0.1.0")
      assert_module_since(MailglassInbound.Mailbox, "0.1.0")
      assert_module_since(MailglassInbound.PubSub.Topics, "0.2.0")
    end

    test "stable structured error modules are annotated" do
      assert_module_since(MailglassInbound.MIMEError, "0.2.0")
      assert_module_since(MailglassInbound.SignatureError, "0.2.0")
      assert_module_since(MailglassInbound.S3FetchError, "0.2.0")
    end

    test "stable inbound operator mix task modules are annotated" do
      assert_module_since(Mix.Tasks.Mailglass.Inbound.Doctor, "0.2.0")
      assert_module_since(Mix.Tasks.Mailglass.Inbound.Replay, "0.2.0")
      assert_module_since(Mix.Tasks.Mailglass.Inbound.Prune, "0.2.0")
    end
  end

  describe "adopter-facing entrypoints expose since metadata" do
    test "stable runtime function and macro entrypoints are annotated" do
      assert entry_meta!(MailglassInbound, :function, :version, 0)[:since] == "0.1.0"

      assert entry_meta!(MailglassInbound.InboundMessage, :function, :suppression_flagged?, 1)[:since] ==
               "0.2.0"

      assert entry_meta!(MailglassInbound.Ingress.CachingBodyReader, :function, :read_body, 2)[:since] ==
               "0.1.0"

      assert entry_meta!(MailglassInbound.Router, :macro, :__using__, 1)[:since] == "0.1.0"
      assert entry_meta!(MailglassInbound.Router, :macro, :route, 2)[:since] == "0.1.0"
      assert entry_meta!(MailglassInbound.Mailbox, :callback, :process, 1)[:since] == "0.1.0"

      assert entry_meta!(MailglassInbound.PubSub.Topics, :function, :inbound_record_inserted, 1)[:since] ==
               "0.2.0"
    end

    test "stable structured error closed-set functions are annotated" do
      assert entry_meta!(MailglassInbound.MIMEError, :function, :__types__, 0)[:since] == "0.2.0"
      assert entry_meta!(MailglassInbound.SignatureError, :function, :__types__, 0)[:since] == "0.2.0"
      assert entry_meta!(MailglassInbound.S3FetchError, :function, :__types__, 0)[:since] == "0.2.0"
    end

    test "testing helper modules and direct helper entrypoints are annotated" do
      assert_module_since(MailglassInbound.Fixtures, "0.2.0")
      assert_module_since(MailglassInbound.Test.Ingress, "0.2.0")
      assert_module_since(MailglassInbound.TestAssertions, "0.2.0")
      assert_module_since(MailglassInbound.MailboxCase, "0.2.0")

      for {name, arity} <- [
            {:build_inbound_message, 1},
            {:build_postmark_payload, 1},
            {:build_sendgrid_payload, 1},
            {:sendgrid_fixture_config, 0},
            {:build_mailgun_payload, 1},
            {:mailgun_fixture_config, 0},
            {:build_ses_sns_payload, 1}
          ] do
        assert entry_meta!(MailglassInbound.Fixtures, :function, name, arity)[:since] == "0.2.0"
      end

      assert entry_meta!(MailglassInbound.Test.Ingress, :function, :receive_inbound, 2)[:since] == "0.2.0"

      assert entry_meta!(MailglassInbound.Test.Ingress, :function, :receive_provider_payload, 3)[:since] ==
               "0.2.0"

      for {name, arity} <- [
            {:assert_inbound_received, 0},
            {:assert_inbound_received, 1},
            {:assert_inbound_accepted, 0},
            {:assert_inbound_ignored, 0},
            {:assert_inbound_rejected, 0},
            {:assert_inbound_bounced, 0},
            {:assert_inbound_routed_to, 1},
            {:assert_inbound_no_match, 0},
            {:assert_no_inbound_received, 0}
          ] do
        assert entry_meta!(MailglassInbound.TestAssertions, :macro, name, arity)[:since] == "0.2.0"
      end
    end
  end

  describe "explicitly excludes internal and non-contract entrypoints" do
    test "internal helpers, provider modules, workers, and task run/* stay out of direct metadata assertions" do
      assert has_entry?(MailglassInbound.Router, :macro, :__before_compile__, 1)
      assert has_entry?(MailglassInbound.Router, :function, :validate_matcher, 1)
      assert has_entry?(MailglassInbound.TestAssertions, :macro, :__assert_outcome__, 1)
      assert has_entry?(MailglassInbound.TestAssertions, :function, :__match_keyword__, 2)

      refute entry_meta!(MailglassInbound.Router, :macro, :__before_compile__, 1)[:since]
      refute entry_meta!(MailglassInbound.Router, :function, :validate_matcher, 1)[:since]
      refute entry_meta!(MailglassInbound.TestAssertions, :macro, :__assert_outcome__, 1)[:since]
      refute entry_meta!(MailglassInbound.TestAssertions, :function, :__match_keyword__, 2)[:since]

      refute entry_meta!(Mix.Tasks.Mailglass.Inbound.Doctor, :function, :run, 1)[:since]
      refute entry_meta!(Mix.Tasks.Mailglass.Inbound.Replay, :function, :run, 2)[:since]
      refute entry_meta!(Mix.Tasks.Mailglass.Inbound.Prune, :function, :run, 2)[:since]
    end
  end
end
