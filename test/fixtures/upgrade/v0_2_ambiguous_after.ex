# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Fixture.AmbiguousBefore do
  @moduledoc false

  def build(msg) do
    msg
    |> to("to@example.com")
    |> Swoosh.Email.put_provider_option(:template_id, "welcome-template")
  end
end
