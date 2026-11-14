defmodule Mailglass.Scripts.BrandPinTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/brand_pin.exs")
  @pin_path Path.join(@repo_root, "brandbook/brand.pin.json")

  # Test-owned on purpose: a pin-only edit of the zip hash fails here. A deliberate bump
  # (scripts/brand_pin.exs update) edits this constant and the pin in one chore(brand) commit.
  @expected_zip_sha256 "ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b"

  @required_assets [
    "brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt",
    "brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt",
    "brandbook/v2/OFL-FunnelDisplay.txt",
    "brandbook/v2/brand.json"
  ]

  setup_all do
    Code.require_file(@script)
    :ok
  end

  defp pin(function, args), do: apply(Mailglass.BrandPin, function, args)

  defp real_pin do
    @pin_path |> File.read!() |> Jason.decode!()
  end

  describe "the committed pin" do
    test "decodes and parses" do
      assert {:ok, parsed} = pin(:parse, [real_pin()])
      assert parsed["repo"] == "szTheory/mailglass-brand"
    end

    test "records the zip hash the test owns" do
      assert pin(:check_expected_sha256, [real_pin(), @expected_zip_sha256]) == :ok
    end

    test "pins a full commit and a commit-derived url" do
      real = real_pin()

      assert real["commit"] =~ ~r/\A[0-9a-f]{40}\z/
      assert real["url"] == pin(:zip_url, [real["repo"], real["commit"]])
    end

    test "verifies against the real tree" do
      assert pin(:verify, [
               real_pin(),
               pin(:tree_read_file, [@repo_root]),
               pin(:tree_list_dir, [@repo_root])
             ]) ==
               :ok
    end

    test "ships exactly the four required assets" do
      assert real_pin()["shipped"] |> Enum.map(& &1["to"]) |> Enum.sort() == @required_assets
    end
  end
end
