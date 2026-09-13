defmodule Mailglass.Phase165MilestoneFinalizerTest do
  use ExUnit.Case, async: false

  @moduletag :phase_165_tracer

  test "repository and installed milestone authority lanes are separate" do
    aliases = Mix.Project.config()[:aliases]

    assert Keyword.has_key?(aliases, :"verify.phase_165.repository")
    assert Keyword.has_key?(aliases, :"verify.phase_165.installed_boundary")
  end
end
