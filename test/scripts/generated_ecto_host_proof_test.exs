defmodule Mailglass.Scripts.GeneratedEctoHostProofTest do
  use ExUnit.Case, async: true

  @script_path Path.expand("../../scripts/generated_ecto_host_proof.sh", __DIR__)
  @ci_yml_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

  @required_script_snippets [
    "mix phx.new host --module Host --app host",
    "config :mailglass, repo: Host.Repo",
    "config :mailglass_inbound, repo: Host.Repo",
    "mailglass.gen.migration --repo Host.Repo",
    "mailglass.inbound.gen.migration --repo Host.Repo",
    "mix ecto.migrate -r Host.Repo",
    "Host.Repo.insert(Delivery.changeset",
    "Host.Repo.get!(Delivery, delivery.id, prefix: \"mailglass\")",
    "mix ecto.rollback -r Host.Repo",
    "assert_relations_absent!"
  ]

  test "generated Ecto host proof pins the public generator-to-Postgres journey" do
    source = File.read!(@script_path)

    Enum.each(@required_script_snippets, fn snippet ->
      assert String.contains?(source, snippet),
             "generated-host proof is missing required journey anchor: #{inspect(snippet)}"
    end)

    refute String.contains?(source, "--no-ecto"),
           "the proof must generate a real Ecto host, not a compile-only host"

    refute String.contains?(source, "Mailglass.TestRepo"),
           "the proof must use only the generated host's Repo"

    refute Regex.match?(~r/create table\(:mailglass_|CREATE TABLE\s+mailglass_/i, source),
           "the proof must exercise generated package wrappers, not hand-write package DDL"
  end

  test "negative controls prove every public host-proof anchor is load-bearing" do
    source = File.read!(@script_path)

    Enum.each(@required_script_snippets, fn snippet ->
      mutated = String.replace(source, snippet, "")

      refute Enum.all?(@required_script_snippets, &String.contains?(mutated, &1)),
             "removing #{inspect(snippet)} must invalidate the proof contract"
    end)
  end

  test "Installer Host Smoke retains its identity and runs both adopter proofs" do
    ci_source = File.read!(@ci_yml_path)
    installer_job = extract_job_block(ci_source, "installer_host_smoke")

    assert installer_job != "", "installer_host_smoke job parser returned an empty block"
    assert String.contains?(installer_job, "name: Installer Host Smoke")
    assert String.contains?(installer_job, "bash scripts/consumer_install_smoke.sh")
    assert String.contains?(installer_job, "bash scripts/generated_ecto_host_proof.sh")
    assert String.contains?(installer_job, "postgres:16-alpine")
    assert String.contains?(installer_job, "DATABASE_URL")
    refute Regex.match?(~r/generated_ecto_host_proof\.sh\s*\n?\s*if:/, installer_job)
  end

  defp extract_job_block(source, job_key) do
    marker = "  #{job_key}:\n"

    case String.split(source, marker, parts: 2) do
      [_, rest] -> marker <> (rest |> String.split(~r/\n  [a-z_][a-z_-]*:\n/, parts: 2) |> hd())
      _ -> ""
    end
  end
end
