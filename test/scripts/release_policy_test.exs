defmodule Mailglass.Scripts.ReleasePolicyTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/release_policy.exs", __DIR__)
  @packages ~w(mailglass mailglass_admin mailglass_inbound)

  setup_all do
    Code.require_file(@script)
    :ok
  end

  test "accepts a complete captured three-package candidate while inbound remains independent" do
    target = captured_target()

    assert {:ok, ^target} = policy(:validate_target, [target])

    assert policy(:expected_tags, [target]) ==
             {:ok, ["mailglass-v3.0.0", "mailglass_admin-v3.0.0", "mailglass_inbound-v2.2.0"]}
  end

  test "rejects empty, missing, duplicate, unknown, conflicting, and untrusted candidate inputs" do
    target = captured_target()

    mutations = [
      Map.put(target, "package_set", []),
      Map.put(target, "package_set", ["mailglass", "mailglass", "mailglass_inbound"]),
      Map.put(target, "package_set", ["mailglass", "mailglass_admin", "unknown"]),
      Map.delete(target, "candidate_versions"),
      put_in(target, ["candidate_versions", "unknown"], "1.0.0"),
      put_in(target, ["candidate_versions", "mailglass_inbound"], "2.1.2"),
      put_in(target, ["proposal_identity", "head_sha"], "$(touch pwned)"),
      put_in(target, ["publishable_content", "digest"], "bad\nGITHUB_OUTPUT=owned"),
      put_in(target, ["proposal_identity", "unknown"], true),
      put_in(target, ["publishable_content", "unknown"], true),
      put_in(target, ["final_identity", "unknown"], true),
      put_in(target, ["states", "unknown"], true),
      Map.put(target, "unexpected", true)
    ]

    for mutation <- mutations do
      assert {:error, _} = policy(:validate_target, [mutation])
    end
  end

  test "binds the reviewed Release Please proposal and publishable digest while final tag SHA stays separate" do
    target = captured_target()
    review = review_from(target)

    assert {:ok, ^target} = policy(:validate_candidate, [target, review])

    assert {:error, _} =
             policy(:validate_candidate, [
               target,
               put_in(review, ["proposal_identity", "source_sha"], String.duplicate("f", 40))
             ])

    assert {:error, _} =
             policy(:validate_candidate, [
               put_in(target, ["final_identity", "tag_sha"], String.duplicate("d", 40)),
               review
             ])
  end

  test "derives one deterministic authorization digest from candidate, identity, content, and evidence" do
    target = captured_target()
    assert {:ok, digest} = policy(:candidate_digest, [target])
    assert byte_size(digest) == 64

    reordered_target =
      target
      |> Map.to_list()
      |> Enum.reverse()
      |> Map.new()
      |> update_in(["required_evidence_identifiers"], fn evidence ->
        evidence |> Map.to_list() |> Enum.reverse() |> Map.new()
      end)

    assert {:ok, ^digest} = policy(:candidate_digest, [reordered_target])

    authorized =
      target
      |> Map.put("status", "authorized")
      |> put_in(["states", "authorization"], "authorized")

    assert {:ok, ^authorized} = policy(:validate_authorization_digest, [authorized, digest])

    assert {:error, %{reason: :authorization_digest_mismatch}} =
             policy(:validate_authorization_digest, [authorized, String.duplicate("0", 64)])

    changed_evidence =
      put_in(
        authorized,
        ["required_evidence_identifiers", "historical_tag_sha"],
        String.duplicate("d", 40)
      )

    assert {:error, %{reason: :authorization_digest_mismatch}} =
             policy(:validate_authorization_digest, [changed_evidence, digest])
  end

  test "authorizes only exact candidate tag refs and source versions" do
    target = captured_target()
    versions = target["candidate_versions"]

    for ref <- ["mailglass-v3.0.0", "mailglass_admin-v3.0.0", "mailglass_inbound-v2.2.0"] do
      assert {:ok, ^versions} = policy(:validate_release_ref, [target, ref, versions])
    end

    for ref <- ["mailglass-v3.0.0;echo owned", "refs/tags/mailglass-v3.0.0", "mailglass-v3.0.1"] do
      assert {:error, _} = policy(:validate_release_ref, [target, ref, versions])
    end
  end

  test "completed target carries a separately verified final tag SHA" do
    completed =
      captured_target()
      |> Map.put("status", "completed")
      |> put_in(["states", "authorization"], "authorized")
      |> put_in(["states", "publication"], "published")
      |> put_in(["final_identity", "tag_sha"], String.duplicate("d", 40))

    assert {:ok, ^completed} = policy(:validate_completed_target, [completed])

    assert {:error, _} =
             policy(:validate_completed_target, [
               put_in(completed, ["final_identity", "tag_sha"], nil)
             ])
  end

  defp captured_target do
    %{
      "schema_version" => 1,
      "status" => "captured",
      "package_set" => @packages,
      "baselines" => %{
        "mailglass" => "2.4.1",
        "mailglass_admin" => "2.4.1",
        "mailglass_inbound" => "2.1.2"
      },
      "candidate_versions" => %{
        "mailglass" => "3.0.0",
        "mailglass_admin" => "3.0.0",
        "mailglass_inbound" => "2.2.0"
      },
      "required_evidence_identifiers" => evidence(),
      "proposal_identity" => %{
        "head_sha" => String.duplicate("a", 40),
        "source_sha" => String.duplicate("b", 40)
      },
      "publishable_content" => %{
        "algorithm" => "sha256",
        "digest" => String.duplicate("c", 64),
        "excludes" => [".planning/release-target.json"]
      },
      "final_identity" => %{"tag_sha" => nil},
      "states" => %{
        "capture" => "captured",
        "authorization" => "unauthorized",
        "publication" => "not_started"
      }
    }
  end

  defp review_from(target) do
    Map.take(target, ["candidate_versions", "proposal_identity", "publishable_content"])
  end

  defp policy(function, args), do: apply(Mailglass.ReleasePolicy, function, args)

  defp evidence do
    baselines = %{
      "mailglass" => "2.4.1",
      "mailglass_admin" => "2.4.1",
      "mailglass_inbound" => "2.1.2"
    }

    %{
      "hex_package_endpoints" => Map.new(@packages, &{&1, "https://hex.pm/api/packages/#{&1}"}),
      "hex_release_endpoints" =>
        Map.new(@packages, fn package ->
          {package, "https://hex.pm/api/packages/#{package}/releases/#{baselines[package]}"}
        end),
      "hex_release_checksums" => Map.new(@packages, &{&1, String.duplicate("a", 64)}),
      "historical_tag" => "mailglass-v2.4.1",
      "historical_tag_sha" => String.duplicate("e", 40)
    }
  end
end
