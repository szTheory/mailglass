defmodule MailglassAdmin.Phase182StatusMarksTest do
  @moduledoc """
  Required lane: `support_contract_admin` (runs inside `mix verify.support_contract.admin`).

  Proves the delivery-status pane marks (Phase 182, BRADM-02, D-10) without the network
  and without the brand zip. The committed truth is `brandbook/status-marks.json`,
  extracted once from the pinned book by `scripts/brand_status_marks.exs`. The component
  carries literal copies of that geometry (the Hex package ships `lib`, `priv/static` and
  `docs` only, so lib never reads the repo's brand directory), and this file fails when
  the copy and the pin differ.

  What is proven:

    * `Components.status_mark_shapes/0` equals the JSON `marks` exactly, and every rendered
      mark equals the same data: tag, x, y, width, height, `d`, fill, stroke, stroke-width.
    * Each role renders as `var(--mg-color-<token>)` per the JSON `roles` map, and those
      roles equal the book's status foregrounds bound in `contrast_contract_test.exs`.
    * Every mark is an `aria-hidden`, non-focusable SVG with the book's 100:120 viewBox,
      no `aria-label`, no `title`, and no CSS class (so the bundle does not change).
    * The five marks differ in shape, not in colour alone (WCAG 1.4.1): their shape lists
      are pairwise distinct once colours are removed.
    * Each mark's colour keeps at least 3:1 against `--mg-color-surface` in light and dark,
      and a filled pane keeps 3:1 against the check or crack drawn on it.
    * lib never reads or names the pinned JSON.

  The checks are pure `(input) -> [failure]` functions, and the "detectors have teeth"
  block plants one violation per check and one clean control. The real-source mutations
  (edit the component, watch red, restore) are recorded in the plan summary.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias MailglassAdmin.Components
  alias MailglassAdmin.TestSupport.Contrast

  @admin_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("..", @admin_root)
  @marks_path Path.join(@repo_root, "brandbook/status-marks.json")
  @tokens_path Path.join(@repo_root, "brandbook/tokens.json")
  @contrast_test Path.join(@admin_root, "test/mailglass_admin/contrast_contract_test.exs")
  @lib_dir Path.join(@admin_root, "lib")

  @classes ~w(sent delivered delayed failed not_sent)a
  @sizes %{row: {"17", "20"}, detail: {"37", "44"}}
  @tiers ["light", "dark"]

  # The book colour role each class paints with, and the book status pair it binds to
  # (contrast_contract_test.exs `@book_binding`, foreground side).
  @class_role %{
    "sent" => {"ink", "status-sent", "text"},
    "delivered" => {"ok", "status-delivered", "success-text"},
    "delayed" => {"warn", "status-delayed", "warning-text"},
    "failed" => {"bad", "status-failed", "error-text"},
    "not_sent" => {"mute", "status-notsent", "text-muted"}
  }

  setup_all do
    json = @marks_path |> File.read!() |> Jason.decode!()
    tokens = @tokens_path |> File.read!() |> Jason.decode!()

    rendered =
      for class <- @classes, size <- Map.keys(@sizes), into: %{} do
        {{class, size}, render_component(&Components.status_mark/1, class: class, size: size)}
      end

    %{json: json, marks: json["marks"], roles: json["roles"], tokens: tokens, rendered: rendered}
  end

  # -- checks: pure (input) -> [failure] --------------------------------------------

  # The component's literal copy equals the pinned shape lists, class by class.
  defp copy_failures(component_shapes, marks) do
    json_shapes = Map.new(marks, fn {class, %{"shapes" => shapes}} -> {class, shapes} end)

    component =
      Map.new(component_shapes, fn {class, shapes} -> {Atom.to_string(class), shapes} end)

    for class <- Enum.sort(Enum.uniq(Map.keys(json_shapes) ++ Map.keys(component))),
        Map.get(json_shapes, class) != Map.get(component, class) do
      "class #{class}: component copy #{inspect(Map.get(component, class))} != " <>
        "pinned #{inspect(Map.get(json_shapes, class))}"
    end
  end

  # One rendered mark: svg attributes, accessibility and shape-for-shape equality.
  defp render_failures({class, size}, html, marks, roles) do
    [{"svg", attrs, children}] = html |> Floki.parse_fragment!() |> Enum.filter(&is_tuple/1)
    attrs = Map.new(attrs)
    {width, height} = Map.fetch!(@sizes, size)
    where = "#{class}/#{size}"

    attribute_failures =
      for {name, want} <- [
            {"viewbox", "0 0 100 120"},
            {"aria-hidden", "true"},
            {"focusable", "false"},
            {"width", width},
            {"height", height}
          ],
          Map.get(attrs, name) != want do
        "#{where}: svg #{name} is #{inspect(Map.get(attrs, name))}, expected #{inspect(want)}"
      end

    forbidden_attrs =
      for name <- ["aria-label", "aria-labelledby", "title", "role", "class"],
          Map.has_key?(attrs, name) do
        "#{where}: svg must not carry #{name}"
      end

    title_elements =
      for {"title", _, _} <- children, do: "#{where}: svg must not contain a <title> element"

    forbidden_failures = forbidden_attrs ++ title_elements

    rendered =
      for {tag, shape_attrs, _} <- children,
          tag in ["rect", "path"],
          do: {tag, Map.new(shape_attrs)}

    expected =
      for shape <- get_in(marks, [Atom.to_string(class), "shapes"]) do
        {shape["tag"], expected_attrs(shape, roles)}
      end

    shape_failures =
      if rendered == expected,
        do: [],
        else: ["#{where}: rendered shapes #{inspect(rendered)} != pinned #{inspect(expected)}"]

    attribute_failures ++ forbidden_failures ++ shape_failures
  end

  defp expected_attrs(shape, roles) do
    for {key, value} <- shape, key != "tag", into: %{} do
      case key do
        "stroke_width" -> {"stroke-width", to_string(value)}
        paint when paint in ["fill", "stroke"] -> {paint, paint_value(value, roles)}
        other -> {other, to_string(value)}
      end
    end
  end

  defp paint_value("none", _roles), do: "none"
  defp paint_value(role, roles), do: "var(--mg-color-#{Map.fetch!(roles, role)})"

  # JSON roles equal the book's status foregrounds bound in contrast_contract_test.exs.
  defp role_binding_failures(roles, contrast_source) do
    class_failures =
      for {class, {role, pair, token}} <- @class_role, Map.get(roles, role) != token do
        "class #{class}: role #{role} is #{inspect(Map.get(roles, role))}, the book pair " <>
          "#{pair} binds #{inspect(token)}"
      end

    surface_failure =
      if Map.get(roles, "surf") == "surface",
        do: [],
        else: ["role surf is #{inspect(Map.get(roles, "surf"))}, expected \"surface\""]

    source_failures =
      for {_class, {_role, pair, token}} <- @class_role,
          not String.contains?(contrast_source, ~s|"#{pair}" => {"#{token}", "surface"}|) do
        "contrast_contract_test.exs no longer binds #{pair} to #{token} on surface"
      end

    class_failures ++ surface_failure ++ source_failures
  end

  # Marks differ in shape, not in colour alone: colours collapse to "paint" (or "none",
  # which is itself a shape fact: frame versus fill) before the lists are compared.
  defp distinct_shape_failures(marks) do
    signatures =
      Map.new(marks, fn {class, %{"shapes" => shapes}} ->
        {class, Enum.map(shapes, &shape_signature/1)}
      end)

    for {a, sig_a} <- signatures, {b, sig_b} <- signatures, a < b, sig_a == sig_b do
      "classes #{a} and #{b} have the same shape list; they would differ by colour alone"
    end
  end

  defp shape_signature(shape) do
    Map.new(shape, fn
      {paint, "none"} when paint in ["fill", "stroke"] -> {paint, "none"}
      {paint, _role} when paint in ["fill", "stroke"] -> {paint, "paint"}
      pair -> pair
    end)
  end

  # Every mark's colour keeps 3:1 against the surface; a filled pane keeps 3:1 against the
  # check or crack drawn on it.
  defp contrast_failures(tokens, marks, roles) do
    resolved = Contrast.resolve_tokens(tokens)

    for tier <- @tiers,
        {class, %{"shapes" => shapes}} <- marks,
        {a, b, label} <- contrast_operands(shapes) do
      ratio = Contrast.ratio(color(resolved, tier, roles, a), color(resolved, tier, roles, b))

      if ratio >= 3.0,
        do: nil,
        else: "#{class}/#{tier}: #{label} contrast #{Float.round(ratio, 2)}:1 is under 3:1"
    end
    |> Enum.reject(&is_nil/1)
  end

  defp contrast_operands(shapes) do
    used =
      shapes
      |> Enum.flat_map(&[&1["fill"], &1["stroke"]])
      |> Enum.reject(&(&1 in [nil, "none"]))
      |> Enum.uniq()

    paints = used -- ["surf"]
    [mark_role] = paints

    mark_vs_surface = {mark_role, "surf", "#{mark_role} against the surface"}

    if "surf" in used and Enum.any?(shapes, &(&1["fill"] == mark_role and &1["tag"] == "rect")),
      do: [mark_vs_surface, {"surf", mark_role, "surface stroke on the #{mark_role} pane"}],
      else: [mark_vs_surface]
  end

  defp color(resolved, tier, roles, role),
    do: Map.fetch!(resolved, {tier, "--mg-color-" <> Map.fetch!(roles, role)})

  # lib never reads or names the pinned JSON; components.ex and gallery_live.ex read no files.
  defp packaging_failures(sources) do
    json_mentions =
      for {path, source} <- sources,
          not String.starts_with?(path, "mix/tasks/"),
          String.contains?(source, "status-marks.json"),
          do: "#{path} names status-marks.json; lib must carry a literal copy instead"

    file_reads =
      for {path, source} <- sources,
          path in ["mailglass_admin/components.ex", "mailglass_admin/gallery_live.ex"],
          pattern <- ["File.read", "File.stream", "@external_resource", "Code.compile_file"],
          String.contains?(source, pattern),
          do: "#{path} uses #{pattern}; lib must not read repo files at compile time"

    json_mentions ++ file_reads
  end

  defp lib_sources do
    @lib_dir
    |> Path.join("**/*.{ex,heex}")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, @lib_dir), File.read!(&1)})
  end

  # -- the committed pin ------------------------------------------------------------

  describe "the component equals the pinned marks" do
    test "the literal copy in components.ex equals brandbook/status-marks.json", %{marks: marks} do
      assert Map.keys(Components.status_mark_shapes()) |> Enum.sort() == Enum.sort(@classes)
      assert copy_failures(Components.status_mark_shapes(), marks) == []
    end

    test "the role map equals the JSON roles", %{roles: roles} do
      assert Components.status_mark_roles() == roles
    end

    test "every class and size renders shape-for-shape what the JSON pins", ctx do
      assert map_size(ctx.rendered) == length(@classes) * map_size(@sizes)

      failures =
        for {{class, size}, html} <- ctx.rendered,
            failure <- render_failures({class, size}, html, ctx.marks, ctx.roles),
            do: failure

      assert failures == []
    end

    test "the JSON roles are the book's status foregrounds", %{roles: roles} do
      assert role_binding_failures(roles, File.read!(@contrast_test)) == []
    end

    test "the five marks differ in shape, not in colour alone", %{marks: marks} do
      assert map_size(marks) == 5
      assert distinct_shape_failures(marks) == []
    end

    test "every mark keeps 3:1 against the surface in light and dark", ctx do
      assert contrast_failures(ctx.tokens, ctx.marks, ctx.roles) == []
    end

    test "lib never reads or names the pinned JSON" do
      sources = lib_sources()

      assert length(sources) > 30,
             "the lib glob found #{length(sources)} files; the scan is vacuous"

      assert packaging_failures(sources) == []
    end

    test "a status mark adds no CSS class and no title", %{rendered: rendered} do
      for {{class, size}, html} <- rendered do
        refute html =~ "class=", "#{class}/#{size} carries a class attribute"
        refute html =~ "<title", "#{class}/#{size} carries a title element"
        refute html =~ "aria-label", "#{class}/#{size} carries an aria-label"
      end
    end
  end

  # -- detectors have teeth ---------------------------------------------------------

  describe "detectors have teeth" do
    test "the render check rejects a planted aria-label, title, class and wrong size", ctx do
      html = ctx.rendered[{:failed, :row}]

      for {planted, fragment} <- [
            {String.replace(html, "<svg", ~s|<svg aria-label="Failed"|, global: false),
             "aria-label"},
            {String.replace(html, "<svg", ~s|<svg title="Failed"|, global: false), "title"},
            {String.replace(html, "<svg", ~s|<svg class="mark"|, global: false), "class"},
            {String.replace(html, ">", "><title>Failed</title>", global: false), "<title>"},
            {String.replace(html, ~s|width="17"|, ~s|width="16"|, global: false), "width"},
            {String.replace(html, ~s|aria-hidden="true"|, ~s|aria-hidden="false"|, global: false),
             "aria-hidden"}
          ] do
        failures = render_failures({:failed, :row}, planted, ctx.marks, ctx.roles)

        assert Enum.any?(failures, &(&1 =~ fragment)),
               "planted #{fragment} was not flagged: #{inspect(failures)}"
      end

      assert render_failures({:failed, :row}, html, ctx.marks, ctx.roles) == []
    end

    test "a changed path is flagged by the copy check and by the render check", ctx do
      drifted =
        put_in(ctx.marks, ["delivered", "shapes", Access.at(1), "d"], "M24 63L43 82L77 38")

      assert copy_failures(Components.status_mark_shapes(), drifted) != []

      html = ctx.rendered[{:delivered, :row}]
      assert render_failures({:delivered, :row}, html, drifted, ctx.roles) != []
    end

    test "a swapped role is flagged by the render check and by the binding check", ctx do
      swapped = %{ctx.roles | "ok" => "error-text", "bad" => "success-text"}

      assert render_failures(
               {:delivered, :row},
               ctx.rendered[{:delivered, :row}],
               ctx.marks,
               swapped
             ) != []

      assert role_binding_failures(swapped, File.read!(@contrast_test)) != []
      assert role_binding_failures(ctx.roles, File.read!(@contrast_test)) == []
    end

    test "a binding to a drifted contrast test is flagged" do
      roles = %{
        "ink" => "text",
        "ok" => "success-text",
        "warn" => "warning-text",
        "bad" => "error-text",
        "mute" => "text-muted",
        "surf" => "surface"
      }

      failures = role_binding_failures(roles, ~s|"status-sent" => {"text", "surface"}|)
      assert Enum.any?(failures, &(&1 =~ "no longer binds status-delivered"))
    end

    test "two identical shape lists are flagged, and a colour-only difference is not enough",
         ctx do
      same = Map.put(ctx.marks, "not_sent", ctx.marks["delayed"])
      assert [failure] = distinct_shape_failures(same)
      assert failure =~ "delayed and not_sent"

      recoloured =
        update_in(ctx.marks, ["not_sent", "shapes"], fn _ ->
          Enum.map(ctx.marks["delayed"]["shapes"], fn shape ->
            Map.new(shape, fn
              {"stroke", "warn"} -> {"stroke", "mute"}
              pair -> pair
            end)
          end)
        end)

      assert [_] = distinct_shape_failures(recoloured)
      assert distinct_shape_failures(ctx.marks) == []
    end

    test "a component copy that differs from the pin is flagged", ctx do
      planted =
        Map.put(Components.status_mark_shapes(), :sent, Components.status_mark_shapes().failed)

      assert [failure] = Enum.filter(copy_failures(planted, ctx.marks), &(&1 =~ "class sent"))
      assert failure =~ "component copy"

      missing = Map.delete(Components.status_mark_shapes(), :failed)
      assert Enum.any?(copy_failures(missing, ctx.marks), &(&1 =~ "class failed"))
    end

    test "a mark under 3:1 against the surface is flagged", ctx do
      pale = put_in(ctx.roles, ["mute"], "surface")

      failures = contrast_failures(ctx.tokens, ctx.marks, pale)
      assert Enum.any?(failures, &(&1 =~ "not_sent/light"))
      assert contrast_failures(ctx.tokens, ctx.marks, ctx.roles) == []
    end

    test "the packaging check flags a file read and a named JSON in lib" do
      clean = [{"mailglass_admin/components.ex", "def logo(assigns), do: assigns"}]
      assert packaging_failures(clean) == []

      for planted <- [
            {"mailglass_admin/components.ex",
             ~s|@marks File.read!("../brandbook/status-marks.json")|},
            {"mailglass_admin/gallery_live.ex", "@external_resource Path.join(root, \"x\")"},
            {"mailglass_admin/preview_live.ex", ~s|# see brandbook/status-marks.json|}
          ] do
        assert packaging_failures([planted]) != [],
               "planted violation was not flagged: #{inspect(planted)}"
      end

      # The dev-time asset task may name brand files; it is not shipped logic.
      assert packaging_failures([{"mix/tasks/x.ex", "status-marks.json"}]) == []
    end
  end
end
