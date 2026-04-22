defmodule Mailglass.Test.Fixtures do
  @moduledoc "Shared test fixtures for Phase 1."

  import Phoenix.Component, only: [sigil_H: 2]

  @doc "Returns a minimal HEEx assigns map for renderer tests."
  def minimal_assigns do
    %{tenant_id: "test_tenant", mailable: TestMailer}
  end

  @doc "Path to the golden VML fixture used by `vml_preservation_test.exs` (D-14)."
  def vml_golden_fixture_path do
    Path.join([__DIR__, "..", "fixtures", "vml_golden.html"])
  end

  @doc """
  Returns a minimal `%Mailglass.Message{}` wrapping a simple HEEx function
  component (`<p>Hello world</p>`). Used by Renderer tests to exercise the
  basic pipeline without invoking the full component set.
  """
  def simple_message do
    component = fn assigns ->
      ~H"""
      <html>
        <head>
          <style>p { color: red; }</style>
        </head>
        <body>
          <p>Hello world</p>
        </body>
      </html>
      """
    end

    email = %Swoosh.Email{html_body: component}
    Mailglass.Message.new(email, mailable: TestMailer, tenant_id: "test_tenant")
  end

  @doc """
  Returns a `%Mailglass.Message{}` whose component uses the full mailglass
  component set: preheader, heading, button, hr, text. Exercises every
  `data-mg-plaintext` strategy in the Renderer walker and drives the <50ms
  perf test (AUTHOR-03).
  """
  def component_message do
    component = fn assigns ->
      ~H"""
      <html>
        <head>
          <style>p { color: red; }</style>
        </head>
        <body>
          <Mailglass.Components.preheader text="Hidden preview text" />
          <Mailglass.Components.container>
            <Mailglass.Components.section>
              <Mailglass.Components.heading level={1}>Welcome</Mailglass.Components.heading>
              <Mailglass.Components.text>Body paragraph one.</Mailglass.Components.text>
              <Mailglass.Components.text>Body paragraph two.</Mailglass.Components.text>
              <Mailglass.Components.button href="https://example.com">Click me</Mailglass.Components.button>
              <Mailglass.Components.hr />
              <Mailglass.Components.text>Footer paragraph.</Mailglass.Components.text>
              <Mailglass.Components.link href="https://docs.example.com">Read docs</Mailglass.Components.link>
              <Mailglass.Components.img src="https://example.com/logo.png" alt="Example logo" />
              <Mailglass.Components.heading level={2}>Subsection</Mailglass.Components.heading>
              <Mailglass.Components.text>Closing remarks.</Mailglass.Components.text>
            </Mailglass.Components.section>
          </Mailglass.Components.container>
        </body>
      </html>
      """
    end

    email = %Swoosh.Email{html_body: component}
    Mailglass.Message.new(email, mailable: TestMailer, tenant_id: "test_tenant")
  end
end
