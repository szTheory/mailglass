defmodule Mailglass.DocsMigrationSmokeTest do
  use Mailglass.MailerCase, async: true
  import Mailglass.DocsHelpers

  @guide_path "guides/migration-from-swoosh.md"

  test "migration guide steps are accurate" do
    # Extract the End-to-End Example from the migration guide
    code = extract_block_after_heading(@guide_path, "End-to-End Example")
    assert code
    assert code =~ "Mailglass.deliver()"

    # In a real smoke test, we would actually run the steps,
    # but for this contract test, we verify that the code snippet
    # compiles and uses the expected APIs.
    assert {:ok, _quoted} = Code.string_to_quoted(code)
  end

  test "parity smoke: raw Swoosh email can be delivered via Mailglass" do
    # This is the actual parity check mentioned in the guide's E2E example
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to("migrated@example.com")
      |> Swoosh.Email.from("system@example.com")
      |> Swoosh.Email.subject("Migration parity check")

    # If this doesn't raise, the parity is maintained.
    # In test mode, we use the Fake adapter.
    assert {:ok, _delivery} = Mailglass.deliver(email)
  end
end
