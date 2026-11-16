defmodule Mailglass.Scripts.BrandDesignMdTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @design_path Path.join(@repo_root, "DESIGN.md")
  @guide_path Path.join(@repo_root, "mailglass_admin/docs/design-system.md")
  @todo_path Path.join(@repo_root, ".planning/todos/pending/183-unsubscribe-inline-brand-css.md")
  @owner_dir Path.join(@repo_root, ".planning/research/brand-v2-adoption/owner-signoff")
  @claude_patch Path.join(@owner_dir, "CLAUDE.md.patch")
  @product_patch Path.join(@owner_dir, "PRODUCT.md.patch")
  @signoff_path Path.join(@owner_dir, "SIGNOFF.md")
  @status_path Path.join(@owner_dir, "STATUS")

  @sections [
    "Overview",
    "Colors",
    "Typography",
    "Layout",
    "Elevation & Depth",
    "Shapes",
    "Components",
    "Do's and Don'ts"
  ]

  @color_tokens %{
    "background" => ["color", "light", "background"],
    "surface" => ["color", "light", "surface"],
    "text" => ["color", "light", "text"],
    "text-muted" => ["color", "light", "text-muted"],
    "accent" => ["color", "light", "accent"],
    "border" => ["color", "light", "border"],
    "status-delivered" => ["color", "light", "success-text"],
    "status-delayed" => ["color", "light", "warning-text"],
    "status-failed" => ["color", "light", "error-text"],
    "logo-glass" => ["logo", "light", "glass"]
  }

  @dark_color_tokens %{
    "background" => ["color", "dark", "background"],
    "surface" => ["color", "dark", "surface"],
    "text" => ["color", "dark", "text"],
    "text-muted" => ["color", "dark", "text-muted"],
    "accent" => ["color", "dark", "accent"],
    "border" => ["color", "dark", "border"],
    "status-delivered" => ["color", "dark", "success-text"],
    "status-delayed" => ["color", "dark", "warning-text"],
    "status-failed" => ["color", "dark", "error-text"],
    "logo-glass" => ["logo", "dark", "glass"]
  }

  @dos [
    "Use the matching light or dark typemark and keep one quarter of its height clear on every side.",
    "Keep the product name lowercase in prose and write the delivery status beside its mark.",
    "Use the logo unchanged to refer to mailglass; use by others does not imply endorsement or certification."
  ]

  @donts [
    "Do not use logo Glass for text, links or controls, and do not put a shape behind the typemark.",
    "Do not add a tagline or descriptor inside the logo, recolor the mark or make patterns from its arches.",
    "Do not use the retired sealed-flap identity or imply that a status mark replaces its word."
  ]

  test "root DESIGN.md has the canonical sections and documents the v2 authority" do
    design = read_design!()
    frontmatter = frontmatter!(design)

    assert frontmatter["name"] == "mailglass"
    assert frontmatter["description"] == "See your email before it ships. Trace it after."

    assert section_headings(design) == @sections
    assert design =~ "brandbook/v2/brand.json"
    assert design =~ "brandbook/tokens.json"
    assert design =~ "Two Panes, One Email"
    assert design =~ "the tagline outside the logo"
    assert design =~ "does not imply endorsement or certification"

    refute design =~ "brandbook/brand-book.md owns"
    refute design =~ "clarity through panes"
    refute design =~ "Mail you can see through."
    refute design =~ "sealed-flap identity as canonical"
    refute design =~ "Inter Tight"
    refute design =~ "IBM Plex Mono"
    refute design =~ ~r/[←-↓]/

    assert File.read!(@status_path) == "pending\n"
    assert design =~ "the palette, type, tagline and mark wait for owner sign-off"
  end

  test "DESIGN.md color, type, radius and spacing values resolve to the token authorities" do
    design = read_design!()
    frontmatter = frontmatter!(design)
    tokens = json!("brandbook/tokens.json")
    brand = json!("brandbook/v2/brand.json")

    for {role, token_path} <- @color_tokens do
      assert frontmatter["colors"][role] == resolve_token(tokens, token_path),
             "#{role} must match #{Enum.join(token_path, ".")}"
    end

    type_roles = %{
      "display" => {"font", "display", "text", "h1", "Heading"},
      "body" => {"font", "ui", "text", "body", "Body"},
      "mono" => {"font", "mono", "text", "code", "Code and ids"}
    }

    for {role, {font_token, font_name, size_token, size_name, hierarchy_role}} <- type_roles do
      type = frontmatter["typography"][role]
      assert type["fontFamily"] == resolve_token(tokens, [font_token, font_name])
      assert type["fontSize"] == resolve_token(tokens, [size_token, size_name])
      assert type["fontWeight"] == hierarchy_weight(brand, hierarchy_role)
    end

    assert frontmatter["rounded"] == direct_tokens(tokens, "radius")
    assert frontmatter["spacing"] == direct_tokens(tokens, "space")

    palette_hexes = tokens["palette"] |> Map.values() |> Enum.map(& &1["$value"]) |> MapSet.new()

    for [hex] <- Regex.scan(~r/#[0-9A-Fa-f]{6}/, design) do
      assert MapSet.member?(palette_hexes, String.upcase(hex)),
             "#{hex} is not a color from brandbook/tokens.json"
    end

    refs = Regex.scan(~r/\{(colors|typography|rounded|spacing)\.([A-Za-z0-9_-]+)\}/, design)

    for [_, group, key] <- refs do
      assert Map.has_key?(frontmatter[group], key),
             "dangling design token reference {#{group}.#{key}}"
    end
  end

  test "sidecar dark counterparts, motion and narrative stay bound to DESIGN.md" do
    design = read_design!()
    frontmatter = frontmatter!(design)
    sidecar = json!(".impeccable/design.json")
    color_meta = sidecar["extensions"]["colorMeta"]

    assert sidecar["schemaVersion"] == 2
    assert Map.keys(color_meta) |> Enum.sort() == Map.keys(frontmatter["colors"]) |> Enum.sort()

    for {role, light_token} <- frontmatter["colors"] do
      meta = color_meta[role]
      assert meta["canonical"] == light_token
      assert meta["dark"] == resolve_token(json!("brandbook/tokens.json"), @dark_color_tokens[role])
    end

    motions = sidecar["extensions"]["motion"]

    assert Enum.map(motions, & &1["name"]) == [
             "reveal",
             "timeline-in",
             "tab-swap",
             "overlay",
             "row-state",
             "flash"
           ]

    assert Enum.all?(
             motions,
             &(String.contains?(&1["purpose"], "ease-out") or &1["name"] == "timeline-in")
           )

    narrative = sidecar["narrative"]
    assert narrative["northStar"] == "Two Panes, One Email"
    assert narrative["overview"] == section_body!(design, "Overview")
    assert narrative["dos"] == @dos
    assert narrative["donts"] == @donts
    assert Enum.count(sidecar["components"]) in 2..4
    assert Enum.all?(sidecar["components"], &(&1["html"] && &1["css"] && &1["refersTo"]))
  end

  test "Admin guide uses v2 sources, typography, status words and logo rules" do
    guide = File.read!(@guide_path)

    assert guide =~ "brandbook/v2/brand.json and brandbook/tokens.json define identity and voice"
    assert guide =~ "Funnel Display at 600 for headings"
    assert guide =~ "Atkinson Hyperlegible Next at 400 or 600 for body and interface text"
    assert guide =~ "Atkinson Hyperlegible Mono for ids, addresses, headers and code"
    assert guide =~ "brandbook/status-marks.json"
    assert guide =~ "Sent, Delivered, Delayed, Failed and Not sent"
    assert guide =~ "one quarter of the typemark height"
    assert guide =~ "does not imply endorsement or certification"
    assert guide =~ "brandbook/tokens.css mirrors the resolved token source"
    assert guide =~ "Historical screenshots and visual scores"
    assert guide =~ "resolved and proven in v2.1 Phase 139"

    refute guide =~ "brandbook/brand-book.md owns identity and voice"
    refute guide =~ "Inter Tight"
    refute guide =~ "IBM Plex Mono"
    refute guide =~ "clarity through panes"
    refute guide =~ "Mailglass Admin"
  end

  test "the Inter exception is scoped to the legacy unsubscribe page and has a follow-up" do
    config = json!(".impeccable/config.json")
    ignores = config["detector"]["ignoreValues"]
    assert length(ignores) == 1
    [ignore] = ignores
    assert ignore["rule"] == "overused-font"
    assert ignore["value"] == "inter"
    assert ignore["files"] == ["lib/mailglass/compliance/unsubscribe_html/**"]
    assert ignore["reason"] =~ "brandbook/v2/brand.json"
    assert ignore["reason"] =~ "retired"
    assert ignore["reason"] =~ ".planning/todos/pending/183-unsubscribe-inline-brand-css.md"

    todo = File.read!(@todo_path)
    assert todo =~ "Owner"
    assert todo =~ "Exit condition"
    assert todo =~ "lib/mailglass/compliance/unsubscribe_html/"
  end

  test "paired owner patches apply-check together while canonical files remain pending" do
    claude = File.read!(Path.join(@repo_root, "CLAUDE.md"))
    product = File.read!(Path.join(@repo_root, "PRODUCT.md"))

    for path <- [@status_path, @signoff_path, @claude_patch, @product_patch] do
      assert File.regular?(path),
             "owner handoff artifact must exist: #{Path.relative_to(path, @repo_root)}"
    end

    status = File.read!(@status_path)
    signoff = File.read!(@signoff_path)

    assert status == "pending\n"
    assert owner_state_consistent?(status, claude, product)
    assert signoff =~ ".planning/research/brand-v2-adoption/owner-signoff/CLAUDE.md.patch"
    assert signoff =~ ".planning/research/brand-v2-adoption/owner-signoff/PRODUCT.md.patch"
    assert signoff =~ "git apply --check"
    assert signoff =~ "STATUS"

    assert signoff =~
             "https://github.com/szTheory/mailglass/blob/main/.planning/research/brand-v2-adoption/owner-signoff/SIGNOFF.md"

    for patch <- [@claude_patch, @product_patch] do
      {output, 0} =
        System.cmd("git", ["-C", @repo_root, "apply", "--check", patch], stderr_to_stdout: true)

      assert output == ""
    end

    temporary =
      Path.join(System.tmp_dir!(), "brand-owner-patches-#{System.unique_integer([:positive])}")

    File.mkdir_p!(temporary)
    File.cp!(Path.join(@repo_root, "CLAUDE.md"), Path.join(temporary, "CLAUDE.md"))
    File.cp!(Path.join(@repo_root, "PRODUCT.md"), Path.join(temporary, "PRODUCT.md"))
    on_exit(fn -> File.rm_rf!(temporary) end)

    {output, 0} =
      System.cmd(
        "git",
        [
          "-C",
          @repo_root,
          "apply",
          "--check",
          "--directory",
          temporary,
          @claude_patch,
          @product_patch
        ],
        stderr_to_stdout: true
      )

    assert output == ""

    {output, 0} =
      System.cmd(
        "git",
        ["-C", @repo_root, "apply", "--directory", temporary, @claude_patch, @product_patch],
        stderr_to_stdout: true
      )

    assert output == ""

    assert owner_state_consistent?(
             "applied",
             File.read!(Path.join(temporary, "CLAUDE.md")),
             File.read!(Path.join(temporary, "PRODUCT.md"))
           )

    half_applied =
      Path.join(System.tmp_dir!(), "brand-owner-half-#{System.unique_integer([:positive])}")

    File.mkdir_p!(half_applied)
    File.cp!(Path.join(@repo_root, "CLAUDE.md"), Path.join(half_applied, "CLAUDE.md"))
    File.cp!(Path.join(@repo_root, "PRODUCT.md"), Path.join(half_applied, "PRODUCT.md"))
    on_exit(fn -> File.rm_rf!(half_applied) end)

    {output, 0} =
      System.cmd("git", ["-C", @repo_root, "apply", "--directory", half_applied, @claude_patch],
        stderr_to_stdout: true
      )

    assert output == ""
    half_claude = File.read!(Path.join(half_applied, "CLAUDE.md"))
    half_product = File.read!(Path.join(half_applied, "PRODUCT.md"))
    refute owner_state_consistent?("pending", half_claude, half_product)
    refute owner_state_consistent?("applied", half_claude, half_product)
  end

  defp read_design! do
    assert File.regular?(@design_path), "root DESIGN.md must document the pinned v2 design system"
    File.read!(@design_path)
  end

  defp json!(relative_path) do
    @repo_root
    |> Path.join(relative_path)
    |> File.read!()
    |> Jason.decode!()
  end

  defp section_headings(design) do
    Regex.scan(~r/^## (.+)$/m, design, capture: :all_but_first)
    |> List.flatten()
  end

  defp section_body!(design, heading) do
    pattern = Regex.compile!("^## #{Regex.escape(heading)}\\n(.*?)(?=^## |\\z)", "ms")
    [_, body] = Regex.run(pattern, design)
    String.trim(body)
  end

  defp frontmatter!(design) do
    assert [_, yaml] = Regex.run(~r/\A---\n(.*?)\n---\n/s, design)

    lines =
      yaml
      |> String.split("\n")
      |> Enum.reject(&(String.trim(&1) == "" or String.starts_with?(String.trim(&1), "#")))
      |> Enum.map(fn line ->
        [_, indent, key, value] = Regex.run(~r/^( *)([^:]+):(?:\s+(.*))?$/, line) ++ [""]
        {String.length(indent), String.trim(key), value |> to_string() |> String.trim()}
      end)

    {parsed, _stack} =
      Enum.reduce(lines, {%{}, []}, fn {indent, key, value}, {acc, stack} ->
        parents = Enum.take_while(stack, fn {level, _parent} -> level < indent end)
        path = Enum.map(parents, &elem(&1, 1)) ++ [key]

        if value == "" do
          {put_path(acc, path, %{}), [{indent, key} | parents]}
        else
          {put_path(acc, path, parse_scalar(value)), parents}
        end
      end)

    parsed
  end

  defp parse_scalar(value) do
    cond do
      String.starts_with?(value, "\"") -> Jason.decode!(value)
      Regex.match?(~r/\A-?\d+\z/, value) -> String.to_integer(value)
      Regex.match?(~r/\A-?\d+\.\d+\z/, value) -> String.to_float(value)
      true -> value
    end
  end

  defp put_path(map, [key], value), do: Map.put(map, key, value)

  defp put_path(map, [key | rest], value) do
    Map.put(map, key, put_path(Map.get(map, key, %{}), rest, value))
  end

  defp resolve_token(tokens, path) do
    value = get_in(tokens, path ++ ["$value"])

    case value do
      "{palette." <> rest ->
        key = String.trim_trailing(rest, "}")
        get_in(tokens, ["palette", key, "$value"])

      other ->
        other
    end
  end

  defp direct_tokens(tokens, group) do
    tokens[group]
    |> Enum.reject(fn {key, _value} -> key == "$type" end)
    |> Map.new(fn {key, value} -> {key, value["$value"]} end)
  end

  defp hierarchy_weight(brand, role) do
    brand["type"]["hierarchy"]
    |> Enum.find(&(&1["role"] == role))
    |> Map.fetch!("weight")
  end

  defp owner_state_consistent?("pending", claude, product) do
    String.contains?(claude, "#0D1B2A") and
      String.contains?(claude, "Inter Tight") and
      String.contains?(product, "Mail you can see through.") and
      not String.contains?(claude, "Atkinson Hyperlegible Next") and
      not String.contains?(product, "See your email before it ships. Trace it after.")
  end

  defp owner_state_consistent?("applied", claude, product) do
    String.contains?(claude, "Atkinson Hyperlegible Next") and
      String.contains?(claude, "Deep Glass") and
      String.contains?(product, "See your email before it ships. Trace it after.") and
      not String.contains?(claude, "#0D1B2A") and
      not String.contains?(claude, "Inter Tight") and
      not String.contains?(product, "Mail you can see through.")
  end

  defp owner_state_consistent?(_status, _claude, _product), do: false
end
