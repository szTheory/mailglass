defmodule MailglassAdmin.Operator.ShellTest do
  @moduledoc """
  Wave 0 structural stubs for Shell.orientation_strip/1 and aria-current nav
  resolution. Tests are tagged @tag :skip and will be un-skipped in Plans 75-02
  and 75-03 when the components and Overview branch are implemented.
  """

  use MailglassAdmin.LiveViewCase, async: false

  describe "orientation_strip/1" do
    @tag :skip
    test "renders deliveries-orientation testid with frozen copy" do
    end

    @tag :skip
    test "renders inbound-orientation testid with frozen copy" do
    end

    @tag :skip
    test "renders preview-orientation testid with frozen copy" do
    end

    @tag :skip
    test "uses text-label not text-sm for bullet list" do
    end
  end

  describe "aria-current nav resolution" do
    @tag :skip
    test "passes active={:deliveries} so nav_link emits aria-current=page on Overview" do
    end
  end
end
