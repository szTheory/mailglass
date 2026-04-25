defmodule Mailglass.Tracking.DefaultOffTest do
  use ExUnit.Case, async: true

  alias Mailglass.FakeFixtures.TestMailer

  # Test 11: Tracking off by default — rendered TestMailer message has no tracking pixel
  test "Test 11: rendered TestMailer message has no tracking pixel (tracking off by default)" do
    # Build a simple message using TestMailer
    msg = TestMailer.welcome("user@example.com")

    # Inject a plain HTML body so Renderer.render/1 can work
    html_body = "<html><body><p>Welcome!</p></body></html>"

    msg_with_html =
      Mailglass.Message.update_swoosh(msg, fn e ->
        %{e | html_body: html_body}
      end)

    {:ok, rendered} = Mailglass.Renderer.render(msg_with_html)

    # No tracking pixel — no <img width="1" height="1"> in rendered html_body
    refute String.contains?(rendered.swoosh_email.html_body, ~s(width="1" height="1")),
           "Expected no tracking pixel in html_body when tracking is off by default"

    # No rewritten hrefs — no tracking redirect URLs
    refute String.contains?(rendered.swoosh_email.html_body, "/mailglass/track/"),
           "Expected no rewritten hrefs when tracking is off by default"

    # Baseline: rendered HTML should still contain the original content
    assert String.contains?(rendered.swoosh_email.html_body, "Welcome!")
  end
end
