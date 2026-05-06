defmodule MailglassAdmin.StabilityContractTest do
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

  defp assert_module_since(module, since) do
    %{metadata: metadata} = docs!(module)
    assert metadata[:since] == since, "#{inspect(module)} missing moduledoc since metadata"
  end

  describe "stable admin seams expose since metadata" do
    test "top-level stable modules are annotated" do
      assert_module_since(MailglassAdmin, "0.1.0")
      assert_module_since(MailglassAdmin.Router, "0.1.0")
      assert_module_since(MailglassAdmin.Auth, "0.1.0")
    end

    test "router macros are annotated" do
      assert entry_meta!(MailglassAdmin, :function, :version, 0)[:since] == "0.1.0"
      assert entry_meta!(MailglassAdmin.Router, :macro, :mailglass_admin_routes, 2)[:since] == "0.1.0"
      assert entry_meta!(MailglassAdmin.Router, :macro, :mailglass_operator_routes, 2)[:since] == "0.1.0"
    end

    test "auth callback, helper functions, and public types are annotated" do
      assert entry_meta!(MailglassAdmin.Auth, :callback, :authorize, 2)[:since] == "0.1.0"
      assert entry_meta!(MailglassAdmin.Auth, :function, :authorize, 3)[:since] == "0.1.0"
      assert entry_meta!(MailglassAdmin.Auth, :function, :session_actor, 1)[:since] == "0.1.0"

      for type_name <- [:action, :actor, :success, :failure_reason, :failure, :result] do
        assert entry_meta!(MailglassAdmin.Auth, :type, type_name, 0)[:since] == "0.1.0"
      end
    end
  end

  describe "trust doc wiring" do
    test "the package docs surface exposes the canonical trust doc" do
      mixfile = File.read!("mix.exs")
      readme = File.read!("README.md")
      trust_doc = File.read!("docs/operator-trust.md")

      assert mixfile =~ "\"docs/operator-trust.md\""
      assert readme =~ "docs/operator-trust.md"
      assert trust_doc =~ "## Stable seams"
      assert trust_doc =~ "## Intentionally internal"
      assert trust_doc =~ ":operator_access"
      assert trust_doc =~ ":destructive_action"
    end
  end
end
