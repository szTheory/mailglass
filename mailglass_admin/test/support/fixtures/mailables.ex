defmodule MailglassAdmin.Fixtures.HappyMailer do
  @moduledoc """
  Fixture mailable with a healthy `preview_props/0` callback returning two
  scenarios. Discovery tests assert this produces the expected scenario
  keyword list (CONTEXT D-11); LiveView tests mount the `:welcome_default`
  scenario to drive sidebar/tabs/assigns-form coverage.
  """

  use Mailglass.Mailable, stream: :transactional

  def preview_props do
    [
      welcome_default: %{user_name: "Ada", plan: :free, admin?: false},
      welcome_enterprise: %{user_name: "Babbage", plan: :enterprise, admin?: true}
    ]
  end

  def welcome_default(assigns) do
    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject("Welcome #{assigns.user_name}")
    |> Mailglass.Message.html_body("<p>Hi #{assigns.user_name}</p>")
    |> Mailglass.Message.text_body("Hi #{assigns.user_name}")
    |> Mailglass.Message.put_function(:welcome_default)
  end

  def welcome_enterprise(assigns) do
    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("babbage@example.test")
    |> Mailglass.Message.subject("Welcome #{assigns.user_name} (enterprise)")
    |> Mailglass.Message.html_body("<p>Hi #{assigns.user_name} — enterprise plan</p>")
    |> Mailglass.Message.text_body("Hi #{assigns.user_name} — enterprise plan")
    |> Mailglass.Message.put_function(:welcome_enterprise)
  end
end

defmodule MailglassAdmin.Fixtures.StubMailer do
  @moduledoc """
  Fixture mailable that uses `Mailglass.Mailable` but deliberately does NOT
  define `preview_props/0`. Discovery tests assert this surfaces as the
  `:no_previews` sentinel (CONTEXT D-13); LiveView tests assert the sidebar
  renders the "No previews defined" stub card.
  """

  use Mailglass.Mailable, stream: :transactional

  # Deliberately no preview_props/0.
end

defmodule MailglassAdmin.Fixtures.BrokenMailer do
  @moduledoc """
  Fixture mailable whose `preview_props/0` raises. Discovery tests assert
  the reflector returns `{:error, formatted_stacktrace}` rather than
  propagating the raise (CONTEXT D-13); LiveView tests assert the sidebar
  shows a warning badge and the main pane renders an error card.
  """

  use Mailglass.Mailable, stream: :transactional

  def preview_props do
    raise "boom — deliberate fixture raise for Discovery test coverage"
  end
end
