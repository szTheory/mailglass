# credo:disable-for-this-file Credo.Check.Readability.ModuleNames
defmodule Fixture.SupportedBefore do
  @moduledoc false

  def build(msg) do
    msg
    |> Swoosh.Email.to("to@example.com")
    |> Swoosh.Email.from("from@example.com")
    |> Swoosh.Email.subject("Welcome")
    |> Swoosh.Email.text_body("Plaintext")
    |> Swoosh.Email.html_body("<h1>HTML</h1>")
    |> Swoosh.Email.header("x-trace", "trace-123")
    |> Swoosh.Email.attachment("priv/static/guide.pdf")
    |> Swoosh.Email.put_tag("welcome")
  end
end
