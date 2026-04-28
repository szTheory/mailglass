defmodule Mailglass.DocsMigrationSmokeTest do
  use Mailglass.MailerCase, async: true
  import Mailglass.DocsHelpers

  @guide_path "guides/migration-from-swoosh.md"

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

  test "upgrade guide examples stay on the supported codemod path" do
    blocks = extract_code_blocks("guides/upgrading-from-v0_1.md")
    after_block = Enum.find(blocks, &String.contains?(&1, "# v0.2 Mailable"))
    escape_hatch_block = Enum.find(blocks, &String.contains?(&1, "put_provider_option"))

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
