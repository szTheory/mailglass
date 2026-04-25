defmodule Mailglass.Components.ButtonTest do
  @moduledoc """
  Tests for `Mailglass.Components.button/1` — the SURGICAL VML flagship (D-10).

  The <.button> emits a `<v:roundrect>` wrapped in `<!--[if mso]>` for classic
  Outlook and a plain `<a>` with `mso-hide:all` for every other client. We
  render the component via its public function (no ~H sigil in the test
  module) so the tests stay independent of Phoenix.Component's import context.
  """

  use ExUnit.Case, async: true

  alias Mailglass.Components

  setup do
    # Ensure :persistent_term theme cache is populated for Theme.color/1.
    Mailglass.Config.validate_at_boot!()
    :ok
  end

  defp render_button(assigns) do
    assigns
    |> Components.button()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp base_assigns do
    %{
      variant: "primary",
      tone: "glass",
      class: nil,
      rest: %{href: "https://example.com"},
      __changed__: nil,
      inner_block: [
        %{
          __slot__: :inner_block,
          inner_block: fn _, _ -> "Click me" end
        }
      ]
    }
  end

  test "<.button> renders v:roundrect VML wrapper inside MSO conditional comment" do
    html = render_button(base_assigns())

    assert String.contains?(html, "<!--[if mso]>"), "Missing MSO conditional comment"
    assert String.contains?(html, "v:roundrect"), "Missing v:roundrect VML element"
    assert String.contains?(html, "w:anchorlock"), "Missing w:anchorlock"
    assert String.contains?(html, "<![endif]-->"), "Missing endif comment"
  end

  test "<.button> HTML fallback has data-mg-plaintext='link_pair' for plaintext walker" do
    html = render_button(base_assigns())

    assert String.contains?(html, ~s(data-mg-plaintext="link_pair")),
           "Missing data-mg-plaintext='link_pair' on <a> fallback"
  end

  test "<.button> HTML fallback has mso-hide:all so Outlook shows VML version" do
    html = render_button(base_assigns())

    assert String.contains?(html, "mso-hide:all"), "Missing mso-hide:all on HTML <a> fallback"
  end

  test "<.button> inner-slot content appears in both VML and HTML branches" do
    html = render_button(base_assigns())

    # Expect the label to appear twice: once inside <center> for VML, once inside <a>.
    occurrences = html |> String.split("Click me") |> length() |> Kernel.-(1)

    assert occurrences >= 2,
           "Expected label 'Click me' in both VML and HTML branches (got #{occurrences})"
  end

  test "<.button> respects the :href in rest attrs" do
    html = render_button(base_assigns())

    assert String.contains?(html, "https://example.com"),
           "Missing href value in rendered button"
  end
end
