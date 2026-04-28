defmodule MailglassAdmin.MixConfigTest do
  @moduledoc """
  Asserts the Hex-publish dep pin lock from CONTEXT D-02 / PREV-01 /
  DIST-01: `mailglass_admin/mix.exs` flips between a local path dep
  (`{:mailglass, path: "..", override: true}`) for contributors and a
  pinned Hex dep (`{:mailglass, "== <version>"}`) when `MIX_PUBLISH=true`.

  Plan 02 makes these assertions green by landing `mailglass_admin/mix.exs`
  with the conditional `mailglass_dep/0` helper from 05-PATTERNS.md.
  """

  use ExUnit.Case, async: true

  @mix_exs Path.expand("../../mix.exs", __DIR__)

  describe "app metadata" do
    test "app name is :mailglass_admin" do
      assert Mix.Project.config()[:app] == :mailglass_admin
    end

    test "version matches the @version attribute in mix.exs" do
      version = Mix.Project.config()[:version]
      assert is_binary(version)
      assert version =~ ~r/^\d+\.\d+\.\d+/
      # `@version` attribute is the source; Mix.Project.config()[:version]
      # reads from it.
      source = File.read!(@mix_exs)
      assert source =~ ~s|@version "#{version}"|
    end
  end

  describe "mailglass dep switch (CONTEXT D-02)" do
    setup do
      original = System.get_env("MIX_PUBLISH")
      on_exit(fn ->
        case original do
          nil -> System.delete_env("MIX_PUBLISH")
          val -> System.put_env("MIX_PUBLISH", val)
        end
      end)

      {:ok, original_env: original}
    end

    test "MIX_PUBLISH=true pins mailglass to the exact current version" do
      System.put_env("MIX_PUBLISH", "true")
      version = Mix.Project.config()[:version]
      dep_tuple = evaluate_mailglass_dep()

      assert {:mailglass, pin} = dep_tuple
      assert pin == "== #{version}",
             "expected pinned Hex dep `== #{version}`, got #{inspect(dep_tuple)}"
    end

    test "MIX_PUBLISH unset falls back to path: \"..\" dep with override: true" do
      System.delete_env("MIX_PUBLISH")
      dep_tuple = evaluate_mailglass_dep()

      assert {:mailglass, opts} = dep_tuple
      assert opts[:path] == ".."
      assert opts[:override] == true
    end
  end

  # Re-evaluates the mailglass_dep/0 function from mix.exs by parsing the
  # mix.exs source with Code.string_to_quoted/1 and finding the function
  # body. Avoids calling Mix.Project.config() (cached across test runs).
  defp evaluate_mailglass_dep do
    source = File.read!(@mix_exs)
    # Extract and eval the mailglass_dep/0 function body.
    # Plan 02 ships the function per 05-PATTERNS.md §mix.exs.
    {:ok, quoted} = Code.string_to_quoted(source)
    dep_fn_body = extract_function_body(quoted, :mailglass_dep, 0)

    assert dep_fn_body, "mailglass_dep/0 not found in #{@mix_exs}"

    {result, _binding} =
      Code.eval_quoted(dep_fn_body, [],
        requires: [],
        aliases: [],
        functions: [{Kernel, [==: 2]}]
      )

    result
  end

  describe "release-please sed-anchor regex stability (REL-05)" do
    # The sed step in .github/workflows/release-please.yml anchors on the
    # literal `{:mailglass, "== <semver>"}` shape. Renaming the dep tuple,
    # or changing the version-pin format, would silently break the no-op fix
    # documented in CONTRIBUTING.md "Why we sed mix.exs after release-please
    # runs". This test fails LOUDLY before the workflow silently becomes a
    # no-op again.
    setup do
      original = System.get_env("MIX_PUBLISH")

      on_exit(fn ->
        case original do
          nil -> System.delete_env("MIX_PUBLISH")
          val -> System.put_env("MIX_PUBLISH", val)
        end
      end)

      {:ok, original_env: original}
    end

    test "MIX_PUBLISH=true emits dep tuple matching the sed regex literal" do
      System.put_env("MIX_PUBLISH", "true")
      source = File.read!(@mix_exs)

      # Same regex shape as the sed step:
      # sed -E 's/\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}/.../'
      sed_anchor = ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/

      assert Regex.match?(sed_anchor, source),
             """
             release-please.yml sed step anchors on the literal
             `{:mailglass, "== <semver>"}` form. The current mix.exs no longer
             emits this form. Either update the sed regex (and CONTRIBUTING.md
             REL-05 section) or restore the literal pin shape.
             """
    end
  end

  defp extract_function_body(ast, name, arity) do
    {_, acc} =
      Macro.prewalk(ast, nil, fn
        {:defp, _, [{^name, _, args}, [do: body]]} = node, _acc
        when is_list(args) and length(args) == arity ->
          {node, body}

        {:defp, _, [{^name, _, nil}, [do: body]]} = node, _acc when arity == 0 ->
          {node, body}

        node, acc ->
          {node, acc}
      end)

    acc
  end
end
