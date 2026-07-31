defmodule Mix.Tasks.Mailglass.Gen.MailableTest do
  use ExUnit.Case
  import Igniter.Test

  setup do
    [
      igniter: test_project(app_module: Test)
    ]
  end

  # NOTE: `igniter` must be the COMPOSED igniter, not the result of
  # `apply_igniter!/1`. As of Igniter 0.8.0 `apply_igniter!/1` returns an
  # igniter whose `rewrite` holds ZERO sources — applying materialises the
  # sources and drops them from the struct — so `Rewrite.source!/2` on a
  # post-apply igniter always raises `no source found`. Igniter's own
  # `assert_content_equals/3` has the same constraint (verified against
  # igniter 0.8.1). Assert on the composed igniter; call `apply_igniter!/1`
  # separately to keep its "applies without issues" guarantee.
  defp assert_file_content(igniter, file_path, expected_content) do
    source = Rewrite.source!(igniter.rewrite, file_path)
    actual_content = Rewrite.Source.get(source, :content) |> String.trim()
    assert actual_content == expected_content |> String.trim()
  end

  test "generates a mailable module and template when given a simple name", %{igniter: igniter} do
    igniter =
      igniter
      |> Igniter.compose_task("mailglass.gen.mailable", ["Notification"])

    apply_igniter!(igniter)

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

    apply_igniter!(igniter)

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
