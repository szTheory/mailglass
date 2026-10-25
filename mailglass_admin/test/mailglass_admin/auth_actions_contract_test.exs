defmodule MailglassAdmin.AuthActionsContractTest do
  @moduledoc """
  Keeps the library's `MailglassAdmin.Auth.authorize/3` call sites, the
  reference demo adapter, and the stable docs in agreement.

  This test lives in the admin package because `reference/demo_app/test` runs
  in no required CI lane. It compiles the demo adapter and calls it instead of
  grepping the source, because the adapter's catch-all clause made a grep
  false-green: a grant for an action the library never asks for looks fine in
  source while the real action is denied at runtime.

  A new library action must force a deliberate update to `@known_actions`,
  the demo adapter, and `docs/api_stability.md` together.
  """

  use ExUnit.Case, async: true

  @lib_dir Path.expand("../../lib", __DIR__)
  @demo_auth_path Path.expand(
                    "../../../reference/demo_app/lib/mailglass_demo_web/admin_auth.ex",
                    __DIR__
                  )
  @api_doc_path Path.expand("../../docs/api_stability.md", __DIR__)
  @known_actions [:destructive_action, :operator_access, :replay_inbound, :reveal_raw]

  @call_site ~r/(?<![A-Za-z0-9_])Auth\.authorize\(\s*[^,]+,\s*:([a-z_]+)/
  # Deliberately looser than @call_site: any `Auth.authorize(` mention, including
  # piped, variable-action, or multi-arg-expression shapes the strict scan skips.
  @any_call ~r/(?<![A-Za-z0-9_])Auth\.authorize\(/

  setup_all do
    mod = Module.concat(["MailglassDemoWeb", "AdminAuth"])

    unless Code.ensure_loaded?(mod) do
      Code.require_file(@demo_auth_path)
    end

    {:ok, demo_auth: mod}
  end

  defp lib_sources do
    @lib_dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.map(&{&1, File.read!(&1)})
  end

  # Names stay strings until compared: a brand-new action's atom may not exist
  # yet (modules load lazily), and `String.to_existing_atom/1` would raise an
  # opaque ArgumentError instead of reaching the "update @known_actions" message.
  defp called_actions do
    lib_sources()
    |> Enum.flat_map(fn {_path, src} ->
      @call_site
      |> Regex.scan(src, capture: :all_but_first)
      |> Enum.map(fn [name] -> name end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp known_action_names, do: @known_actions |> Enum.map(&Atom.to_string/1) |> Enum.sort()

  test "every Auth.authorize call site is matched by the action scan" do
    total = Enum.sum(for {_path, src} <- lib_sources(), do: length(Regex.scan(@any_call, src)))

    matched =
      Enum.sum(for {_path, src} <- lib_sources(), do: length(Regex.scan(@call_site, src)))

    assert total > 0, "no Auth.authorize call sites found at all"

    assert matched == total,
           "#{total - matched} Auth.authorize call site(s) use a shape the action scan " <>
             "cannot read (piped, variable action, or nested args); use a literal atom " <>
             "action or extend @call_site"
  end

  test "scan finds the library's authorize call sites" do
    actions = called_actions()

    refute actions == [], "call-site scan matched nothing: #{inspect(actions)}"

    assert actions == known_action_names(),
           "call-site scan returned #{inspect(actions)}, expected #{inspect(known_action_names())}; " <>
             "update @known_actions, the demo adapter, and docs/api_stability.md together"
  end

  test "demo AdminAuth grants every action the library calls", %{demo_auth: mod} do
    for name <- called_actions() do
      action = String.to_atom(name)
      result = mod.authorize(action, %{actor: %{subject_id: "operator-1"}})

      assert match?({:ok, _}, result),
             "demo AdminAuth denies #{inspect(action)}: #{inspect(result)}"
    end
  end

  defp auth_seam_stable_promise do
    [_, after_heading] = String.split(File.read!(@api_doc_path), "### Auth seam", parts: 2)

    section =
      after_heading
      |> String.split("\n")
      |> Enum.take_while(
        &(not String.starts_with?(&1, "## ") and not String.starts_with?(&1, "### "))
      )
      |> Enum.join("\n")

    case String.split(section, "Stable promise:", parts: 2) do
      [_, rest] -> rest |> String.split("Not promised:", parts: 2) |> hd()
      _ -> ""
    end
  end

  test "every called action is documented in api_stability.md" do
    block = auth_seam_stable_promise()

    assert block != "" and block =~ ":operator_access",
           "api_stability.md Auth seam Stable promise block not found"

    for name <- called_actions() do
      assert block =~ ":" <> name, "api_stability.md does not document :#{name}"
    end
  end
end
