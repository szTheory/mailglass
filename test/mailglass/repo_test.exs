defmodule Mailglass.RepoTest do
  use ExUnit.Case, async: true
  @moduletag :skip

  describe "Repo.transact/1" do
    test "delegates to configured repo" do
      # Implemented in Plan 03 — CORE-04. Uses Mox for the configured repo.
      flunk("not yet implemented")
    end
  end
end
