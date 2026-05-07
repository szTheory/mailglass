defmodule Mix.Tasks.Mailglass.Gen.MailableTest do
  use ExUnit.Case
  import Igniter.Test

  setup do
    [
      igniter: test_project(app_module: Test)
    ]
  end

  defp assert_file_content(igniter, file_path, expected_content) do
    source = Rewrite.source!(igniter.rewrite, file_path)
    actual_content = Rewrite.Source.get(source, :content) |> String.trim()
    assert actual_content == expected_content |> String.trim()
  end

  test "generates a mailable module and template when given a simple name", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.compose_task("mailglass.gen.mailable", ["Notification"])
      |> apply_igniter!()

    assert_file_content(igniter, "lib/test/mail/notification.ex", """
    defmodule Test.Mail.Notification do
      use Mailglass.Mailable, stream: :transactional
      import Phoenix.Component

      embed_templates("notification/*")

      def notification(assigns \\\\ []) do
        new()
        |> Mailglass.Message.subject("Notification")
        |> Mailglass.Message.html_body(notification_template(assigns))
        |> Mailglass.Message.put_function(:notification)
      end
    end
    """)

    assert_file_content(igniter, "lib/test/mail/notification/notification_template.html.heex", """
    <Mailglass.Components.heading>Notification</Mailglass.Components.heading>
    """)
  end

  test "generates a mailable module and template when given a full module name", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.compose_task("mailglass.gen.mailable", ["MyApp.Mail.WelcomeEmail"])
      |> apply_igniter!()

    assert_file_content(igniter, "lib/my_app/mail/welcome_email.ex", """
    defmodule MyApp.Mail.WelcomeEmail do
      use Mailglass.Mailable, stream: :transactional
      import Phoenix.Component

      embed_templates("welcome_email/*")

      def welcome_email(assigns \\\\ []) do
        new()
        |> Mailglass.Message.subject("WelcomeEmail")
        |> Mailglass.Message.html_body(welcome_email_template(assigns))
        |> Mailglass.Message.put_function(:welcome_email)
      end
    end
    """)

    assert_file_content(
      igniter,
      "lib/my_app/mail/welcome_email/welcome_email_template.html.heex",
      """
      <Mailglass.Components.heading>WelcomeEmail</Mailglass.Components.heading>
      """
    )
  end
end
