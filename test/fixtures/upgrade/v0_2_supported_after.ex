defmodule Fixture.SupportedBefore do
  def build(msg) do
    msg
    |> to("to@example.com")
    |> from("from@example.com")
    |> subject("Welcome")
    |> text_body("Plaintext")
    |> html_body("<h1>HTML</h1>")
    |> header("x-trace", "trace-123")
    |> attach("priv/static/guide.pdf")
    |> put_tag("welcome")
  end
end
