defmodule Mailglass.StabilityContractTest do
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

  describe "stable core entrypoints expose since metadata" do
    test "Mailglass root delegates are annotated" do
      assert_module_since(Mailglass, "0.1.0")

      for {name, arity} <- [
            {:deliver, 2},
            {:deliver_later, 2},
            {:deliver_many, 2},
            {:deliver!, 2},
            {:deliver_many!, 2}
          ] do
        assert entry_meta!(Mailglass, :function, name, arity)[:since] == "0.1.0"
      end
    end

    test "stable public Mix tasks are annotated at the module level" do
      assert_module_since(Mix.Tasks.Mailglass.Install, "0.1.0")
      assert_module_since(Mix.Tasks.Mailglass.Reconcile, "0.3.0")
      assert_module_since(Mix.Tasks.Mail.Doctor, "0.4.0")
      assert_module_since(Mix.Tasks.Mailglass.Publish.Check, "0.2.0")
      assert_module_since(Mix.Tasks.Mailglass.Docs.Check, "0.3.0")
      assert_module_since(Mix.Tasks.Mailglass.Stability.Check, "0.3.0")
    end
  end

  describe "stability proof wiring" do
    test "mix.exs exposes verify.stability_contract as the semantic proof entrypoint" do
      mixfile = File.read!("mix.exs")

      assert mixfile =~ "\"verify.stability_contract\""
      assert mixfile =~ "\"verify.support_contract.core\""
      assert mixfile =~ "cmd --cd mailglass_admin mix verify.support_contract.admin"
      assert mixfile =~ "compile --no-optional-deps --warnings-as-errors"
    end
  end
end
