defmodule Mailglass.Install.FirstSendSmokeTest do
  use Mailglass.MailerCase, async: true

  import Mailglass.DocsHelpers

  defmodule GettingStartedMailer do
    use Mailglass.Mailable, stream: :transactional

    def welcome(user) do
      new()
      |> to(user.email)
      |> from({"MyApp", "support@example.com"})
      |> subject("Welcome")
      |> html_body("<h1>Welcome to MyApp</h1>")
      |> text_body("Welcome to MyApp")
      |> Mailglass.Message.put_function(:welcome)
    end
  end

  test "getting-started guide keeps the ecto-backed first-send lane executable" do
    install_block = extract_block_after_heading("guides/getting-started.md", "1) Install and verify")
    first_send_block = extract_block_after_heading("guides/getting-started.md", "4) Send your first message")

    assert install_block
    assert install_block =~ "mix ecto.migrate"

    assert first_send_block
    assert first_send_block =~ "subject(\"Welcome\")"
    assert first_send_block =~ "Mailglass.deliver()"
    assert {:ok, _quoted} = Code.string_to_quoted(first_send_block)

    assert {:ok, _delivery} =
             %{email: "first-send@example.com"}
             |> GettingStartedMailer.welcome()
             |> Mailglass.deliver()
  end
end
