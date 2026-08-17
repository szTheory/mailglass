defmodule Mailglass.DocsMigrationSmokeTest do
  use Mailglass.MailerCase, async: true
  import Mailglass.DocsHelpers

  @canonical_guide_path "guides/upgrading-to-v1_0.md"
  @guide_path "guides/migration-from-swoosh.md"
  @migration_policy_path "docs/migration-policy.md"

  test "populated-table migration policy stays aligned with executable wrappers" do
    policy = File.read!(@migration_policy_path)

    for required <- [
          "mix mailglass.gen.migration --upgrade --from 5",
          "mix mailglass.inbound.gen.migration --upgrade --from 1",
          "@disable_ddl_transaction true",
          "@disable_migration_lock true",
          "non_transactional_wrapper: true",
          "CREATE INDEX CONCURRENTLY",
          "invalid indexes",
          "bounded, resumable backfill",
          "scripts/generated_ecto_host_proof.sh",
          "core and inbound migrations are independent",
          "admin/operator schema or UI"
        ] do
      assert policy =~ required, "migration policy is missing #{inspect(required)}"
    end

    refute policy =~ "DROP TABLE",
           "the forward populated-table policy must not prescribe destructive contraction"
  end

  test "migration guide steps are accurate" do
    code = extract_block_after_heading(@guide_path, "End-to-End Example")
    assert code
    assert code =~ "assert {:ok, _delivery} = Mailglass.deliver(email)"
    assert {:ok, _quoted} = Code.string_to_quoted(code)
  end

  test "parity smoke: raw Swoosh email can be delivered via Mailglass" do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to("migrated@example.com")
      |> Swoosh.Email.from("system@example.com")
      |> Swoosh.Email.subject("Migration parity check")

    assert {:ok, _delivery} = Mailglass.deliver(email)
  end

  test "canonical upgrade guide is the single upgrade authority" do
    canonical = File.read!(@canonical_guide_path)
    older = File.read!("guides/upgrading-from-v0_1.md")
    swoosh = File.read!(@guide_path)

    assert canonical =~ "canonical latest-`0.x` to `1.0` upgrade guide"

    assert canonical =~
             "| surface | replacement | warning channel | `--warnings-as-errors` impact | support-until version | proof artifact |"

    assert canonical =~ "Mailglass.Outbound.send/2"
    assert canonical =~ "Mailglass.deliver/2"
    assert canonical =~ "mix mailglass.upgrade.v0_2"
    assert canonical =~ "mailglass_admin"
    assert canonical =~ "mix verify.docs.migration"
    assert canonical =~ "mix verify.stability_contract"
    assert canonical =~ "Mailglass.Message.new/2"
    assert canonical =~ "release-blocking for strict adopters"

    assert older =~ "subordinate codemod reference"
    assert older =~ "upgrading-to-v1_0.md"

    assert swoosh =~ "subordinate raw-Swoosh migration reference"
    assert swoosh =~ "upgrading-to-v1_0.md"
  end

  test "upgrade guide examples stay on the supported codemod path" do
    canonical_blocks = extract_code_blocks(@canonical_guide_path)

    preferred_block =
      Enum.find(canonical_blocks, fn block ->
        String.contains?(block, "defmodule MyApp.WelcomeEmail") and
          String.contains?(block, "|> attach(\"path/to/guide.pdf\")")
      end)

    parity_block = Enum.find(canonical_blocks, &String.contains?(&1, "Migration test"))
    blocks = extract_code_blocks("guides/upgrading-from-v0_1.md")
    after_block = Enum.find(blocks, &String.contains?(&1, "# v0.2 Mailable"))
    escape_hatch_block = Enum.find(blocks, &String.contains?(&1, "put_provider_option"))

    assert preferred_block
    assert preferred_block =~ "|> attach(\"path/to/guide.pdf\")"
    assert {:ok, _quoted} = Code.string_to_quoted(preferred_block)

    assert parity_block
    assert parity_block =~ "assert {:ok, _delivery} = Mailglass.deliver(email)"
    assert {:ok, _quoted} = Code.string_to_quoted(parity_block)

    assert after_block
    assert after_block =~ "|> attach(\"path/to/guide.pdf\")"
    assert {:ok, _quoted} = Code.string_to_quoted(after_block)

    assert escape_hatch_block
    assert escape_hatch_block =~ "Mailglass.Message.update_swoosh"
    assert {:ok, _quoted} = Code.string_to_quoted(escape_hatch_block)
  end

  test "authoring guide examples stay on the native setter path" do
    blocks = extract_code_blocks("guides/authoring-mailables.md")
    primary_block = Enum.find(blocks, &String.contains?(&1, "defmodule MyApp.BillingMailer"))
    escape_hatch_block = Enum.find(blocks, &String.contains?(&1, "receipt_with_template"))

    assert primary_block
    assert primary_block =~ "|> put_tag(\"billing\")"
    refute primary_block =~ "Swoosh.Email.to"
    assert {:ok, _quoted} = Code.string_to_quoted(primary_block)

    assert escape_hatch_block
    assert escape_hatch_block =~ "Swoosh.Email.put_provider_option"
    assert {:ok, _quoted} = Code.string_to_quoted(escape_hatch_block)
  end
end
