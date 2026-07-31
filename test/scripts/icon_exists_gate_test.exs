defmodule Mailglass.Scripts.IconExistsGateTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @gate Path.join(@repo_root, "mailglass_admin/scripts/check-conformance.sh")
  @admin_lib Path.join(@repo_root, "mailglass_admin/lib")
  @heroicons Path.join(@repo_root, "mailglass_admin/assets/vendor/heroicons-inline.js")
  @app_css Path.join(@repo_root, "mailglass_admin/assets/css/app.css")

  test "the real gate rejects missing icon values from bounded dynamic forms" do
    for {name, source} <- bounded_dynamic_sources() do
      {output, status} = run_fixture!(name, source)

      assert status != 0, "expected #{name} fixture to fail, got:\n#{output}"
      assert output =~ "hero-missing-#{name}"
      assert output =~ "FAIL: ICON-EXISTS-GATE"
    end
  end

  test "the real gate resolves a computed missing icon whose full name is not a source literal" do
    source = """
    defmodule ComputedMissingIcon do
      def render(assigns) do
        ~H\"\"\"
        <.icon name={\"hero-\" <> \"missing-computed\"} class=\"h-4 w-4\" />
        \"\"\"
      end
    end
    """

    refute source =~ "hero-missing-computed"

    {output, status} = run_fixture!("computed", source)

    assert status != 0
    assert output =~ "hero-missing-computed"
    assert output =~ "FAIL: ICON-EXISTS-GATE"
  end

  test "the real gate fails closed for a non-finite dynamic icon expression" do
    source = """
    defmodule UnboundedIcon do
      def render(assigns) do
        ~H\"\"\"
        <.icon name={\"hero-\" <> @runtime_icon} class=\"h-4 w-4\" />
        \"\"\"
      end
    end
    """

    {output, status} = run_fixture!("unbounded", source)

    assert status != 0
    assert output =~ "FAIL: ICON-EXISTS-GATE — cannot statically resolve dynamic icon expression"
    assert output =~ "unbounded.ex"
  end

  test "a copied real gate passes a clean fixture and cleanup is registered before writes" do
    root = fixture_root!("clean")
    on_exit(fn -> File.rm_rf!(root) end)

    copy_real_gate!(root)
    File.write!(Path.join([root, "lib", "clean.ex"]), "defmodule Clean, do: :ok\n")

    {output, status} = run_gate(root)

    assert status == 0, output
    assert output =~ "OK: design-system conformance clean."

    File.rm_rf!(root)
    refute File.exists?(root)
  end

  defp bounded_dynamic_sources do
    [
      {"attribute",
       """
       defmodule AttributeIcon do
         @icon "hero-missing-attribute"
         def render(assigns), do: ~H\"\"\"<.icon name={@icon} class=\"h-4 w-4\" />\"\"\"
       end
       """},
      {"map",
       """
       defmodule MapIcon do
         def render(assigns) do
           option = %{icon: "hero-missing-map"}
           ~H\"\"\"<.icon name={option.icon} class=\"h-4 w-4\" />\"\"\"
         end
       end
       """},
      {"helper",
       """
       defmodule HelperIcon do
         defp stat_severity_icon(:warning), do: "hero-missing-helper"
         def render(assigns), do: ~H\"\"\"<.icon name={stat_severity_icon(:warning)} class=\"h-4 w-4\" />\"\"\"
       end
       """}
    ]
  end

  defp run_fixture!(name, source) do
    root = fixture_root!(name)
    on_exit(fn -> File.rm_rf!(root) end)

    copy_real_gate!(root)
    File.write!(Path.join([root, "lib", "#{name}.ex"]), source)
    result = run_gate(root)

    File.rm_rf!(root)
    refute File.exists?(root)

    result
  end

  defp fixture_root!(name) do
    root =
      Path.join(
        System.tmp_dir!(),
        "mailglass-icon-gate-#{name}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    root
  end

  defp copy_real_gate!(root) do
    File.mkdir_p!(Path.join(root, "scripts"))
    File.mkdir_p!(Path.join([root, "assets", "vendor"]))
    File.mkdir_p!(Path.join([root, "assets", "css"]))
    File.cp_r!(@admin_lib, Path.join(root, "lib"))
    File.cp!(@gate, Path.join([root, "scripts", "check-conformance.sh"]))
    File.cp!(@heroicons, Path.join([root, "assets", "vendor", "heroicons-inline.js"]))
    File.cp!(@app_css, Path.join([root, "assets", "css", "app.css"]))
  end

  defp run_gate(root) do
    System.cmd("bash", [Path.join([root, "scripts", "check-conformance.sh"])],
      stderr_to_stdout: true
    )
  end
end
