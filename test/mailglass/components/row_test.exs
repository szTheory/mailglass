defmodule Mailglass.Components.RowTest do
  @moduledoc """
  Tests for `Mailglass.Components.row/1` and `Mailglass.Components.column/1` —
  the ghost-table VML pattern for Outlook multi-column layouts (D-11).
  """

  use ExUnit.Case, async: true

  alias Mailglass.Components

  setup do
    Mailglass.Config.validate_at_boot!()
    :ok
  end

  defp render(fun, assigns) do
    assigns
    |> fun.()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp row_assigns(inner) do
    %{
      gap: 0,
      class: nil,
      rest: %{},
      __changed__: nil,
      inner_block: [
        %{__slot__: :inner_block, inner_block: fn _, _ -> inner end}
      ]
    }
  end

  defp column_assigns(inner) do
    %{
      width: :auto,
      valign: "top",
      class: nil,
      rest: %{},
      __changed__: nil,
      inner_block: [
        %{__slot__: :inner_block, inner_block: fn _, _ -> inner end}
      ]
    }
  end

  test "<.row> emits ghost-table conditional comments for Outlook column layout" do
    html = render(&Components.row/1, row_assigns("col-content"))

    assert String.contains?(html, ~s(<!--[if mso]><table role="presentation")),
           "Missing ghost table MSO conditional opener"

    assert String.contains?(html, "<!--[if mso]></tr></table><![endif]-->"),
           "Missing ghost table MSO conditional closer"
  end

  test "<.row> renders its slot content between the MSO conditionals" do
    html = render(&Components.row/1, row_assigns("INNER-CONTENT"))

    assert String.contains?(html, "INNER-CONTENT")
  end

  test "<.column> emits ghost-td conditional comments" do
    html = render(&Components.column/1, column_assigns("cell-content"))

    assert String.contains?(html, "<!--[if mso]><td"),
           "Missing ghost td MSO conditional opener"

    assert String.contains?(html, "<!--[if mso]></td><![endif]-->"),
           "Missing ghost td MSO conditional closer"
  end

  test "<.column> carries data-mg-column marker for post-processing" do
    html = render(&Components.column/1, column_assigns("x"))
    assert String.contains?(html, ~s(data-mg-column="true"))
  end

  test "<.column> respects :width integer by setting width attribute and inline style" do
    assigns = %{column_assigns("x") | width: 300}
    html = render(&Components.column/1, assigns)

    assert String.contains?(html, ~s(width="300")),
           "Missing width attribute on ghost-td"

    assert String.contains?(html, "width:300px;"),
           "Missing inline width style on HTML fallback div"
  end
end
