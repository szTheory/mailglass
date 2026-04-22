defmodule Mailglass.RendererTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [sigil_H: 2]

  alias Mailglass.Test.Fixtures

  setup do
    # Populate the :persistent_term theme cache so Mailglass.Components
    # render with real brand tokens.
    Mailglass.Config.validate_at_boot!()
    :ok
  end

  describe "render/2" do
    test "returns {:ok, %Message{}} with html_body and text_body populated" do
      message = Fixtures.simple_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      assert %Mailglass.Message{} = rendered
      assert is_binary(rendered.swoosh_email.html_body)
      assert is_binary(rendered.swoosh_email.text_body)
      assert String.contains?(rendered.swoosh_email.html_body, "Hello world")
      assert String.contains?(rendered.swoosh_email.text_body, "Hello world")
    end

    test "html_body has CSS inlined (Premailex ran)" do
      component = fn assigns ->
        ~H"""
        <html>
          <head>
            <style>p { color: red; }</style>
          </head>
          <body>
            <p>Hi</p>
          </body>
        </html>
        """
      end

      email = %Swoosh.Email{html_body: component}
      message = Mailglass.Message.new(email, tenant_id: "t")

      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      # Premailex inlines the <style> rule into a style="color:..." on <p>.
      html = rendered.swoosh_email.html_body

      assert String.contains?(html, ~s(style=)) and
               (String.contains?(html, "color:red") or String.contains?(html, "color: red")),
             "Expected inlined color on <p>, got:\n#{html}"
    end

    test "plaintext excludes preheader text (D-15 — data-mg-plaintext='skip')" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      text_body = rendered.swoosh_email.text_body

      refute String.contains?(text_body, "Hidden preview text"),
             "Preheader text must be excluded from plaintext (data-mg-plaintext='skip')"
    end

    test "button plaintext produces 'Label (url)' format (D-22 link_pair strategy)" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      text_body = rendered.swoosh_email.text_body

      assert String.contains?(text_body, "Click me (https://example.com)"),
             "Expected 'Label (url)' format for button plaintext; got:\n#{text_body}"
    end

    test "link plaintext produces 'Label (url)' format (D-22 link_pair strategy)" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      text_body = rendered.swoosh_email.text_body

      assert String.contains?(text_body, "Read docs (https://docs.example.com)"),
             "Expected 'Label (url)' format for link plaintext; got:\n#{text_body}"
    end

    test "hr component produces '---' divider in plaintext" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)

      assert String.contains?(rendered.swoosh_email.text_body, "---"),
             "Expected '---' divider from <.hr>; got:\n#{rendered.swoosh_email.text_body}"
    end

    test "heading level 1 plaintext is uppercase (heading_block_1 strategy)" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)

      assert String.contains?(rendered.swoosh_email.text_body, "WELCOME"),
             "Expected uppercase heading level 1 in plaintext; got:\n#{rendered.swoosh_email.text_body}"
    end

    test "data-mg-plaintext attributes are stripped from final HTML wire (D-22)" do
      message = Fixtures.component_message()
      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      html = rendered.swoosh_email.html_body

      refute String.contains?(html, "data-mg-plaintext"),
             "data-mg-plaintext attribute must be stripped from HTML wire"
    end

    test "data-mg-column attributes are stripped from final HTML wire (D-22)" do
      # Build a message that uses the .row/.column components so data-mg-column
      # markers appear in the intermediate HTML before the strip pass.
      component = fn assigns ->
        ~H"""
        <html><body>
          <Mailglass.Components.row>
            <Mailglass.Components.column width={300}>
              <Mailglass.Components.text>Col A</Mailglass.Components.text>
            </Mailglass.Components.column>
            <Mailglass.Components.column width={300}>
              <Mailglass.Components.text>Col B</Mailglass.Components.text>
            </Mailglass.Components.column>
          </Mailglass.Components.row>
        </body></html>
        """
      end

      email = %Swoosh.Email{html_body: component}
      message = Mailglass.Message.new(email, tenant_id: "t")

      assert {:ok, rendered} = Mailglass.Renderer.render(message)
      html = rendered.swoosh_email.html_body

      refute String.contains?(html, "data-mg-column"),
             "data-mg-column attribute must be stripped from HTML wire"
    end

    test "render completes in under 50ms for a 10-component template (AUTHOR-03)" do
      message = Fixtures.component_message()

      # Warm up (5 iterations to let BEAM JIT/page-cache settle).
      Enum.each(1..5, fn _ -> Mailglass.Renderer.render(message) end)

      {elapsed_us, {:ok, _rendered}} = :timer.tc(fn -> Mailglass.Renderer.render(message) end)
      elapsed_ms = elapsed_us / 1000

      assert elapsed_ms < 50,
             "Render took #{Float.round(elapsed_ms, 2)}ms — must complete in under 50ms (AUTHOR-03)"
    end

    test "invalid html_body (not function or string) returns {:error, %TemplateError{}}" do
      email = %Swoosh.Email{html_body: :not_renderable}
      message = Mailglass.Message.new(email, tenant_id: "t")

      assert {:error, err} = Mailglass.Renderer.render(message)
      assert err.__struct__ == Mailglass.TemplateError
      assert err.type == :heex_compile
    end

    test "emits render telemetry span (start + stop)" do
      handler_id = "renderer-test-#{:erlang.unique_integer()}"
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :render, :message, :start],
          [:mailglass, :render, :message, :stop]
        ],
        fn event, _measurements, metadata, _ ->
          send(test_pid, {:telemetry, event, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      {:ok, _} = Mailglass.Renderer.render(Fixtures.simple_message())

      assert_received {:telemetry, [:mailglass, :render, :message, :start], meta_start}
      assert meta_start.tenant_id == "test_tenant"
      assert meta_start.mailable == TestMailer

      assert_received {:telemetry, [:mailglass, :render, :message, :stop], meta_stop}
      assert meta_stop.tenant_id == "test_tenant"
    end
  end

  describe "to_plaintext/1" do
    test "extracts text from a simple HTML document" do
      html = "<html><body><p>Hello world</p></body></html>"
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "Hello world")
    end

    test "skips data-mg-plaintext='skip' elements" do
      html = ~s|<div data-mg-plaintext="skip">Hidden</div><p>Visible</p>|
      result = Mailglass.Renderer.to_plaintext(html)
      refute String.contains?(result, "Hidden")
      assert String.contains?(result, "Visible")
    end

    test "link_pair produces 'Label (url)' format" do
      html = ~s|<a href="https://example.com" data-mg-plaintext="link_pair">Click</a>|
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "Click (https://example.com)")
    end

    test "divider produces '---'" do
      html = ~s|<td data-mg-plaintext="divider">&nbsp;</td>|
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "---")
    end

    test "heading_block_1 uppercases the heading text" do
      html = ~s|<h1 data-mg-plaintext="heading_block_1">Welcome</h1>|
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "WELCOME")
    end

    test "heading_block_2 preserves case" do
      html = ~s|<h2 data-mg-plaintext="heading_block_2">Subsection</h2>|
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "Subsection")
      refute String.contains?(result, "SUBSECTION")
    end

    test "img with alt emits the alt text" do
      html = ~s|<img src="x.png" alt="Logo" data-mg-plaintext="text" />|
      result = Mailglass.Renderer.to_plaintext(html)
      assert String.contains?(result, "Logo")
    end

    test "strips script and style contents" do
      html =
        ~s|<html><head><style>p{color:red}</style><script>alert('x')</script></head><body><p>Visible</p></body></html>|

      result = Mailglass.Renderer.to_plaintext(html)
      refute String.contains?(result, "color:red")
      refute String.contains?(result, "alert")
      assert String.contains?(result, "Visible")
    end
  end
end
