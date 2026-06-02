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

  defp json!(path), do: path |> File.read!() |> Jason.decode!()

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
      assert_module_since(Mix.Tasks.Mailglass.Repo.Hygiene, "1.3.0")
    end
  end

  describe "stability proof wiring" do
    test "mix.exs exposes verify.stability_contract as the semantic proof entrypoint" do
      mixfile = File.read!("mix.exs")

      assert mixfile =~ "\"verify.stability_contract\""
      assert mixfile =~ "\"verify.support_contract.core\""
      assert mixfile =~ "cmd --cd mailglass_admin mix verify.support_contract.admin"
      assert mixfile =~ "cmd --cd mailglass_inbound mix verify.support_contract.inbound"

      assert mixfile =~ "compile --no-optional-deps --warnings-as-errors"
    end

    test "root docs proof explicitly include mailglass_inbound" do
      docs_check = File.read!("lib/mix/tasks/mailglass.docs.check.ex")
      maintaining = File.read!("MAINTAINING.md")

      assert docs_check =~ "\"mailglass_inbound/README.md\""
      assert docs_check =~ "\"mailglass_inbound/docs/api_stability.md\""
      assert docs_check =~ "\"mailglass_inbound/docs/sendgrid_ingress.md\""
      assert maintaining =~ "mailglass_inbound"
      assert maintaining =~ "mix verify.stability_contract"
    end

    test "release automation and publish proof keep mailglass_inbound in sibling-package truth" do
      workflow = File.read!(".github/workflows/release-please.yml")
      config = File.read!("release-please-config.json")
      manifest = File.read!(".release-please-manifest.json")
      publish_check = File.read!("lib/mix/tasks/mailglass.publish.check.ex")
      inbound_mix = File.read!("mailglass_inbound/mix.exs")
      expected = File.read!(".planning/publish/mailglass_inbound-files.expected")
      summary = File.read!(".planning/publish/mailglass_inbound-publish-summary.json")

      assert workflow =~ "\"mailglass_inbound/mix.exs:mailglass\""
      assert config =~ "\"mailglass_inbound\""
      # The manifest's `mailglass_inbound` entry is `0.0.0` on `main` (the
      # release-please first-publish sentinel from Phase 044.5 Plan 01) and
      # gets bumped on the release-please PR head (`0.1.0` for v1.0/1.1
      # ceremony). Either form is valid; the contract is that the entry
      # exists with a SemVer-shaped value so release-please can compute
      # the next bump.
      assert manifest =~ ~r/"mailglass_inbound": "\d+\.\d+\.\d+"/

      assert publish_check =~
               "defp packages(nil), do: [:mailglass, :mailglass_admin, :mailglass_inbound]"

      assert publish_check =~ "defp packages(\"mailglass_inbound\"), do: [:mailglass_inbound]"
      assert publish_check =~ "defp package_dir(repo_root, :mailglass_inbound)"
      # The release-please sync step bumps the inbound's pinned mailglass dep
      # and the inbound @version on the release-please PR branch each ceremony.
      # Use SemVer-pattern assertions (ceremony-agnostic) so the test does not
      # need updating per release, mirroring the manifest check above.
      assert inbound_mix =~ ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/
      assert inbound_mix =~ ~r/@version "\d+\.\d+\.\d+"/
      assert inbound_mix =~ "\"docs/sendgrid_ingress.md\""
      assert expected =~ "docs/sendgrid_ingress.md"
      assert summary =~ "\"package\": \"mailglass_inbound\""
      # The publish summary JSON's `"mailglass_inbound"` key is updated by
      # `mix mailglass.publish.check` each run; assert it exists with any
      # SemVer-shaped value (ceremony-agnostic).
      assert summary =~ ~r/"mailglass_inbound": "\d+\.\d+\.\d+"/
    end

    test "inbound 1.0 release preflight truth is exact across source and publish evidence" do
      manifest = json!(".release-please-manifest.json")
      summary = json!(".planning/publish/mailglass_inbound-publish-summary.json")
      inbound_mix = File.read!("mailglass_inbound/mix.exs")
      inbound_changelog = File.read!("mailglass_inbound/CHANGELOG.md")
      inbound_readme = File.read!("mailglass_inbound/README.md")
      root_readme = File.read!("README.md")
      expected_version = "1.0.0"
      expected_core_version = "1.3.0"

      assert manifest["mailglass_inbound"] == expected_version
      assert Regex.match?(~r/@version "#{expected_version}"/, inbound_mix)
      assert inbound_changelog =~ "## [#{expected_version}]"
      assert inbound_readme =~ ~s({:mailglass_inbound, "~> 1.0"})
      assert root_readme =~ "`mailglass_inbound` | Stable `1.0`"

      assert Regex.match?(
               ~r/\{:mailglass, "== #{Regex.escape(expected_core_version)}"\}/,
               inbound_mix
             )

      assert summary["package"] == "mailglass_inbound"
      assert summary["version"] == expected_version
      assert summary["manifest_version"] == expected_version
      assert summary["source_ref"] == "v#{expected_version}"
      assert summary["mailglass_inbound_publish_pin"] == "== #{expected_core_version}"
      assert summary["linked_versions"]["mailglass"] == expected_core_version
      assert summary["linked_versions"]["mailglass_admin"] == expected_core_version
      assert summary["linked_versions"]["mailglass_inbound"] == expected_version
      assert "docs/api_stability.md" in summary["extras"]
    end
  end
end
