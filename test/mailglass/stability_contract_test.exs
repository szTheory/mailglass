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
    test "Outbound keeps its public verb inventory while collaborators remain internal" do
      assert Code.ensure_loaded?(Mailglass.Outbound)

      for {name, arity} <- [
            {:send, 2},
            {:deliver, 2},
            {:deliver!, 2},
            {:deliver_later, 2},
            {:deliver_many, 2},
            {:deliver_many!, 2},
            {:dispatch_by_id, 1}
          ] do
        assert function_exported?(Mailglass.Outbound, name, arity)
      end

      for collaborator <- [
            Mailglass.Outbound.Preflight,
            Mailglass.Outbound.Routes,
            Mailglass.Outbound.Persistence,
            Mailglass.Outbound.Dispatch
          ] do
        assert {:docs_v1, _, :elixir, _, :hidden, _, _} = Code.fetch_docs(collaborator)
      end
    end

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

      # The workflow syncs the inbound README `~>` pin and the inbound
      # publish-summary (the `== X.Y.Z` PINS-array sed step was removed in
      # v1.15 Phase 125 — the sibling mix.exs dep is now a hand-maintained `~>`).
      assert workflow =~ "mailglass_inbound/README.md"
      assert workflow =~ "mailglass_inbound-publish-summary.json"
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
      # The inbound MIX_PUBLISH dep is a pessimistic `~>` constraint that admits
      # core @version (not a bare `==` pin — v1.15 Phase 125 LD-2/LD-3).
      # Extract the requirement string from the MIX_PUBLISH branch and verify
      # admit-`~>`-reject-`==` using Version.match? against the derived core version.
      expected_core_version = read_at_version!("mix.exs")

      inbound_req =
        case Regex.run(~r/\{:mailglass, "([^"]+)"\}/, inbound_mix) do
          [_, req] -> req
          _ -> flunk("could not extract mailglass requirement from mailglass_inbound/mix.exs")
        end

      refute String.starts_with?(inbound_req, "=="),
             "inbound mailglass dep must be a pessimistic `~>` constraint, not a bare `==` pin"

      assert Version.match?(expected_core_version, inbound_req),
             "inbound mailglass dep `#{inbound_req}` does not admit core @version #{expected_core_version}"

      assert inbound_mix =~ ~r/@version "\d+\.\d+\.\d+"/
      assert inbound_mix =~ "\"docs/sendgrid_ingress.md\""
      assert expected =~ "docs/sendgrid_ingress.md"
      assert summary =~ "\"package\": \"mailglass_inbound\""
      # The publish summary JSON's `"mailglass_inbound"` key is updated by
      # `mix mailglass.publish.check` each run; assert it exists with any
      # SemVer-shaped value (ceremony-agnostic).
      assert summary =~ ~r/"mailglass_inbound": "\d+\.\d+\.\d+"/
    end

    test "inbound release preflight truth is internally consistent across source and publish evidence" do
      # WR-03 / WR-04: assert *internal consistency* across the artifacts
      # rather than hardcoding the literals (`1.0.0` / `1.3.0`) the artifacts
      # themselves carry. Every linked-version bump (core 1.3.0 -> 1.4.0,
      # inbound 1.0.0 -> 1.1.0) updates these files in lockstep on the
      # release-please ceremony branch; pinning literals here would red this
      # test on every ceremony even though nothing is wrong (the
      # per-release-toil pattern the neighboring SemVer-pattern tests at
      # lines ~94/105 deliberately avoid). Deriving the expected values from
      # the manifest (inbound version) and the *core* mix.exs @version
      # (publish pin) makes the test catch the real failure mode — one file
      # drifting out of step with the others — without ceremony maintenance.
      manifest = json!(".release-please-manifest.json")
      summary = json!(".planning/publish/mailglass_inbound-publish-summary.json")
      inbound_mix = File.read!("mailglass_inbound/mix.exs")
      inbound_changelog = File.read!("mailglass_inbound/CHANGELOG.md")
      inbound_readme = File.read!("mailglass_inbound/README.md")
      root_readme = File.read!("README.md")

      # Source-of-truth values, read from the artifacts (not hardcoded):
      #   * inbound package version  -> release-please manifest entry
      #   * core release line        -> core mix.exs @version (the value the
      #     inbound publish pin must track so a published inbound can resolve
      #     its sibling)
      expected_version = manifest["mailglass_inbound"]
      expected_core_version = read_at_version!("mix.exs")

      assert Regex.match?(~r/^\d+\.\d+\.\d+$/, expected_version),
             "manifest mailglass_inbound entry is not SemVer-shaped: #{inspect(expected_version)}"

      assert Regex.match?(~r/^\d+\.\d+\.\d+$/, expected_core_version),
             "core mix.exs @version is not SemVer-shaped: #{inspect(expected_core_version)}"

      # Inbound @version agrees with the manifest entry.
      assert read_at_version!("mailglass_inbound/mix.exs") == expected_version

      # WR-04: the inbound MIX_PUBLISH dep is a pessimistic `~>` constraint
      # (not a bare `==` pin — v1.15 Phase 125 LD-2/LD-3) that admits core
      # @version via Version.match?. Extract the requirement string from the
      # MIX_PUBLISH branch and assert the admit-`~>`-reject-`==` contract.
      inbound_req_for_preflight =
        case Regex.run(~r/\{:mailglass, "([^"]+)"\}/, inbound_mix) do
          [_, req] -> req
          _ -> flunk("could not extract mailglass requirement from mailglass_inbound/mix.exs")
        end

      refute String.starts_with?(inbound_req_for_preflight, "=="),
             "inbound mailglass dep must be a pessimistic `~>` constraint, not a bare `==` pin; " <>
               "update mailglass_inbound/mix.exs mailglass_dep/0"

      assert Version.match?(expected_core_version, inbound_req_for_preflight),
             "inbound mailglass dep `#{inbound_req_for_preflight}` does not admit core @version " <>
               "(#{expected_core_version}); update mailglass_inbound/mix.exs mailglass_dep/0"

      # Changelog and READMEs reflect the same inbound version. The install
      # hint tracks the current MINOR line (`~> major.minor`), which is what the
      # `release-type: "elixir"` releaser writes into the README on each bump;
      # the root-README stable-row marker tracks the MAJOR line. Both are derived
      # from the manifest version (no hardcoded literals) so this stays green
      # across linked-version ceremonies while still catching a drifting file.
      [inbound_major, inbound_minor | _] = String.split(expected_version, ".")
      inbound_minor_line = "#{inbound_major}.#{inbound_minor}"
      assert inbound_changelog =~ "## [#{expected_version}]"
      assert inbound_readme =~ ~s({:mailglass_inbound, "~> #{inbound_minor_line}"})
      assert root_readme =~ "`mailglass_inbound` | Stable `#{inbound_major}."

      # Publish summary is internally consistent with the derived values.
      assert summary["package"] == "mailglass_inbound"
      assert summary["version"] == expected_version
      assert summary["manifest_version"] == expected_version
      assert summary["source_ref"] == "v#{expected_version}"
      assert summary["source_ref_pattern"] == "mailglass_inbound-v%{version}"
      # The committed publish-summary carries the pessimistic `~>` constraint
      # (not a bare `==` pin — v1.15 Phase 125 LD-3). Assert the summary field
      # admits core @version and is not a bare `==`.
      summary_pin = summary["mailglass_inbound_publish_pin"]

      refute String.starts_with?(summary_pin, "=="),
             "publish-summary mailglass_inbound_publish_pin must be a `~>` constraint, not a bare `==` pin"

      assert Version.match?(expected_core_version, summary_pin),
             "publish-summary mailglass_inbound_publish_pin `#{summary_pin}` does not admit core @version #{expected_core_version}"

      assert summary["linked_versions"]["mailglass"] == expected_core_version
      assert summary["linked_versions"]["mailglass_admin"] == expected_core_version
      assert summary["linked_versions"]["mailglass_inbound"] == expected_version
      assert "docs/api_stability.md" in summary["extras"]
    end
  end

  # Reads the `@version "X.Y.Z"` module attribute literal out of a mix.exs so
  # tests can derive the source-of-truth version instead of hardcoding it.
  defp read_at_version!(path) do
    case Regex.run(~r/@version "(\d+\.\d+\.\d+)"/, File.read!(path)) do
      [_, version] -> version
      _ -> flunk("could not read @version from #{path}")
    end
  end
end
