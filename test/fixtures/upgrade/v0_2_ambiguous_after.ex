defmodule Fixture.AmbiguousBefore do
  def build(msg) do
    msg
    |> to("to@example.com")
    |> Swoosh.Email.put_provider_option(:template_id, "welcome-template")
  end
end
