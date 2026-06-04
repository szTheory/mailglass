defmodule MailglassAdmin.Operator.ShellTest do
  @moduledoc """
  Tests for Shell.orientation_strip/1 and aria-current nav resolution.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Operator.Shell

  describe "orientation_strip/1" do
    test "renders deliveries-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)

      assert html =~ ~s(data-testid="deliveries-orientation")
      assert html =~ "Email never arrived? Start here."
    end

    test "renders inbound-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :inbound)

      assert html =~ ~s(data-testid="inbound-orientation")
      assert html =~ "Message didn"
      assert html =~ "t route as expected? Inspect the routing trace."
    end

    test "renders preview-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :preview)

      assert html =~ ~s(data-testid="preview-orientation")
      assert html =~ "No mailables found? Define a mailable module in your app."
    end

    test "uses text-label not text-sm for bullet list" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)

      assert html =~ "text-label"
      refute html =~ ~r/class="[^"]*text-sm/
    end
  end

  describe "aria-current nav resolution" do
    @tag :skip
    test "passes active={:deliveries} so nav_link emits aria-current=page on Overview" do
    end
  end
end
