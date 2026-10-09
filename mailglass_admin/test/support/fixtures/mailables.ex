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
      welcome_enterprise: %{user_name: "Babbage", plan: :enterprise, admin?: true},
      typed_values: %{
        label: "Original",
        quantity: 3,
        ratio: 1.5,
        enabled?: true,
        due_on: ~D[2026-10-09],
        metadata: %{source: "fixture"},
        mode: :preview,
        scheduled_at: ~U[2026-10-09 12:00:00Z]
      },
      recoverable: %{response: "first"},
      welcome_überraschung_東京__with_a_deliberately_long_name: %{
        user_name: "Ada",
        plan: :free,
        admin?: false
      }
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

  def typed_values(assigns) do
    next_day = Date.add(assigns.due_on, 1)

    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject(
      "#{assigns.label} #{assigns.quantity + 1} #{:erlang.float_to_binary(assigns.ratio * 2, decimals: 6)}"
    )
    |> Mailglass.Message.html_body(
      "<p>#{assigns.label} #{assigns.quantity + 1} #{:erlang.float_to_binary(assigns.ratio * 2, decimals: 6)} #{assigns.enabled?} #{next_day}</p>"
    )
    |> Mailglass.Message.text_body(
      "#{assigns.label} #{assigns.quantity + 1} #{:erlang.float_to_binary(assigns.ratio * 2, decimals: 6)} #{assigns.enabled?} #{next_day}"
    )
    |> Mailglass.Message.put_function(:typed_values)
  end

  def recoverable(assigns) do
    if assigns.response == "fail", do: raise("deliberate recoverable preview failure")

    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject("Recoverable #{assigns.response}")
    |> Mailglass.Message.html_body("<p>Recoverable #{assigns.response}</p>")
    |> Mailglass.Message.text_body("Recoverable #{assigns.response}")
    |> Mailglass.Message.put_function(:recoverable)
  end

  def welcome_überraschung_東京__with_a_deliberately_long_name(assigns) do
    new()
    |> Mailglass.Message.from("no-reply@example.test")
    |> Mailglass.Message.to("ada@example.test")
    |> Mailglass.Message.subject("A surprising welcome for #{assigns.user_name}")
    |> Mailglass.Message.html_body("<p>Surprise, #{assigns.user_name}!</p>")
    |> Mailglass.Message.text_body("Surprise, #{assigns.user_name}!")
    |> Mailglass.Message.put_function(:welcome_überraschung_東京__with_a_deliberately_long_name)
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

defmodule MailglassAdmin.Fixtures.EmptyScenarioMailer do
  @moduledoc "Fixture Mailable whose valid preview_props/0 callback returns no scenarios."

  use Mailglass.Mailable, stream: :transactional

  def preview_props, do: []
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
