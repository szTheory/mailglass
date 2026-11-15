defmodule MailglassAdmin.ContrastContractTest do
  @moduledoc """
  Static contrast contract for the brand v2.0 tokens (BRTOK-02, D-06, D-07).

  Lane: required `support_contract_admin` (`mix verify.support_contract.admin`, the
  whole admin test directory). Nothing here runs a browser and no dependency is
  involved: the math is `MailglassAdmin.TestSupport.Contrast` (WCAG 2.2, sRGB
  threshold 0.04045) over the resolved `brandbook/tokens.json` roles.

  ## What is checked, for the light and the dark theme

    * **Book pairs.** Every `brandbook/v2/brand.json` `color.contrastPairs[]` entry
      (12 per theme) is bound, by a test-owned table, to two token roles. The role
      hexes must equal the pair's published hexes, the ratio must reach the pair's
      `minimum`, and it must sit within 0.02 of the published `contrast`. A pair
      id the table does not know is red, and so is a table entry the book dropped.
    * **Admin pairs.** A plain table of the pairs the admin CSS actually renders:
      each daisyUI `X-content` on `X`, `base-content` on both surfaces,
      `text-{success,warning,error,primary,secondary}` on both surfaces and on its
      own 10% tint composited over each, `border-input` and `focus-ring` on both
      surfaces (3:1), logo glass on the page (3:1), and role-level pairs for every
      designed or unconsumed role (link hover/active, the four `*-bg` tints,
      surface-overlay, surface-selected).
    * **Slot coverage guard.** Every one of the 20 daisyUI slots parsed from the
      `app.css` theme blocks is in a declared pair or in the exemption table with a
      reason (`base-300`, a decorative divider). A new slot with no pair is red.
    * **Designed-value coverage guard (D-05).** Every designed palette value
      resolves, through at least one role, to the foreground or background of a
      declared pair, and every role `$description` that says "unreferenced by admin
      CSS; contrast-checked as <pair id>" names a pair that exists and involves
      that role. The "unreferenced" claim itself is checked against `app.css` and
      `lib/`, so it cannot silently rot.
    * **Book `never` rules.** Logo Glass is never a text, link, accent or control
      role or an `X-content` slot; Sand Line is never `border-input`; Deep Glass is
      never a dark-theme text role.

  ## Teeth

  Every rule is a pure function returning failure strings, and the "detectors have
  teeth" block plants a violation for each one (a darker dark `text-muted`, a
  slot dropped from the pair table, the `info-text-on-info-bg` pair dropped, a
  mutated published ratio, an unknown book pair, and each `never` rule), so a pass
  is not vacuous. The mutation proof (lower one role, observe red, restore) is
  recorded in the plan summary.

  The admin pair table is a plain list of maps so later plans append composite
  rows without restructuring it.
  """

  use ExUnit.Case, async: true

  alias MailglassAdmin.TestSupport.Contrast

  @admin_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("..", @admin_root)
  @tokens_path Path.join(@repo_root, "brandbook/tokens.json")
  @brand_path Path.join(@repo_root, "brandbook/v2/brand.json")
  @css_source_path Path.join(@admin_root, "assets/css/app.css")

  @tiers ["light", "dark"]

  # Book pair id => {foreground role, background role}. A role name starting with
  # "logo-" is a --mg-logo-* role; every other name is a --mg-color-* role.
  @book_binding %{
    "body" => {"text", "background"},
    "descriptor" => {"text-muted", "background"},
    "caption" => {"text-muted", "surface"},
    "application-copy" => {"text", "surface-raised"},
    "link" => {"link", "surface"},
    "focus" => {"focus-ring", "background"},
    "artwork" => {"logo-glass", "background"},
    "status-sent" => {"text", "surface"},
    "status-delivered" => {"success-text", "surface"},
    "status-delayed" => {"warning-text", "surface"},
    "status-failed" => {"error-text", "surface"},
    "status-notsent" => {"text-muted", "surface"}
  }

  @book_tolerance 0.02

  # Operands: {:slot, daisyui_slot} | {:role, role} | {:tint, color, over, alpha}
  # (a tint is `color` at `alpha` composited over `over`).
  @solid_slots ~w(primary secondary accent neutral info success warning error)
  @text_slots ~w(success warning error primary secondary)
  @surfaces ~w(base-100 base-200)

  @admin_pairs Enum.concat([
                 # Each daisyUI X-content on its X (8 coloured pairs).
                 for(
                   x <- @solid_slots,
                   do: %{
                     id: "#{x}-content-on-#{x}",
                     fg: {:slot, "#{x}-content"},
                     bg: {:slot, x},
                     min: 4.5
                   }
                 ),
                 # Body text on both surfaces.
                 for(
                   b <- @surfaces,
                   do: %{
                     id: "base-content-on-#{b}",
                     fg: {:slot, "base-content"},
                     bg: {:slot, b},
                     min: 4.5
                   }
                 ),
                 # text-{x} on both surfaces.
                 for(
                   x <- @text_slots,
                   b <- @surfaces,
                   do: %{id: "text-#{x}-on-#{b}", fg: {:slot, x}, bg: {:slot, b}, min: 4.5}
                 ),
                 # text-{x} on its own 10% tint composited over each surface (bg-x/10).
                 for(
                   x <- @text_slots,
                   b <- @surfaces,
                   do: %{
                     id: "text-#{x}-on-#{x}-tint-over-#{b}",
                     fg: {:slot, x},
                     bg: {:tint, {:slot, x}, {:slot, b}, 0.1},
                     min: 4.5
                   }
                 ),
                 # Non-text contrast (WCAG 1.4.11).
                 for(
                   r <- ~w(border-input focus-ring),
                   b <- @surfaces,
                   do: %{id: "#{r}-on-#{b}", fg: {:role, r}, bg: {:slot, b}, min: 3.0}
                 ),
                 [
                   %{
                     id: "logo-glass-on-base-100",
                     fg: {:role, "logo-glass"},
                     bg: {:slot, "base-100"},
                     min: 3.0
                   }
                 ],
                 # Role-level pairs for the designed and unconsumed roles (D-05).
                 [
                   %{
                     id: "link-hover-on-surface",
                     fg: {:role, "link-hover"},
                     bg: {:role, "surface"},
                     min: 4.5
                   },
                   %{
                     id: "link-hover-on-background",
                     fg: {:role, "link-hover"},
                     bg: {:role, "background"},
                     min: 4.5
                   },
                   %{
                     id: "link-active-on-surface",
                     fg: {:role, "link-active"},
                     bg: {:role, "surface"},
                     min: 4.5
                   },
                   %{
                     id: "link-active-on-background",
                     fg: {:role, "link-active"},
                     bg: {:role, "background"},
                     min: 4.5
                   }
                 ],
                 for(
                   s <- ~w(success warning error info),
                   do: %{
                     id: "#{s}-text-on-#{s}-bg",
                     fg: {:role, "#{s}-text"},
                     bg: {:role, "#{s}-bg"},
                     min: 4.5
                   }
                 ),
                 [
                   %{
                     id: "text-on-surface-overlay",
                     fg: {:role, "text"},
                     bg: {:role, "surface-overlay"},
                     min: 4.5
                   },
                   %{
                     id: "text-muted-on-surface-overlay",
                     fg: {:role, "text-muted"},
                     bg: {:role, "surface-overlay"},
                     min: 4.5
                   },
                   %{
                     id: "text-on-surface-selected",
                     fg: {:role, "text"},
                     bg: {:role, "surface-selected"},
                     min: 4.5
                   },
                   %{
                     id: "text-muted-on-surface-selected",
                     fg: {:role, "text-muted"},
                     bg: {:role, "surface-selected"},
                     min: 4.5
                   },
                   %{
                     id: "border-input-on-surface-selected",
                     fg: {:role, "border-input"},
                     bg: {:role, "surface-selected"},
                     min: 3.0
                   }
                 ]
               ])

  # Slots allowed to sit in no pair, each with the reason.
  @slot_exemptions %{
    "base-300" =>
      "decorative divider; WCAG 1.4.11 exempts it and accessibility_test pins it intentionally sub-3:1"
  }

  # Roles exempt from any contrast pair, each with the reason.
  @role_exemptions %{
    "text-disabled" => "inactive controls are exempt from WCAG 1.4.3; never the only signal"
  }

  setup_all do
    tokens = Jason.decode!(File.read!(@tokens_path))

    {:ok,
     tokens: tokens,
     resolved: Contrast.resolve_tokens(tokens),
     brand: Jason.decode!(File.read!(@brand_path)),
     slots: parse_slots(File.read!(@css_source_path))}
  end

  describe "the Contrast helper" do
    test "luminance, ratio and composite match known values" do
      assert Contrast.luminance("#ffffff") == 1.0
      assert Contrast.luminance("#000000") == 0.0
      assert_in_delta Contrast.ratio("#2A1D17", "#F6F1E8"), 14.51, 0.02
      assert_in_delta Contrast.ratio("#F6F1E8", "#2A1D17"), 14.51, 0.02
      assert Contrast.composite("#1D6B3C", "#FFFFFF", 0.1) == "#e8f0ec"
      assert Contrast.composite("#B3261E", "#FFFFFF", 0.1) == "#f7e9e9"
      assert Contrast.composite("#0A6488", "#FFFFFF", 0.1) == "#e7f0f3"
    end

    test "resolve_tokens flattens 41 roles per tier and raises on a dangling alias", %{
      tokens: tokens,
      resolved: resolved
    } do
      assert map_size(resolved) == 82
      assert resolved[{"light", "--mg-color-background"}] == "#f6f1e8"
      assert resolved[{"dark", "--mg-logo-overlap"}] == "#a8e4f7"

      dangling = put_in(tokens, ["color", "light", "text", "$value"], "{palette.nope}")
      assert_raise ArgumentError, ~r/dangling alias/, fn -> Contrast.resolve_tokens(dangling) end
    end
  end

  describe "book contrast pairs (D-07)" do
    test "all 12 pairs resolve through the tokens in both themes", %{
      resolved: resolved,
      brand: brand
    } do
      assert length(brand["color"]["contrastPairs"]) == 12
      assert book_pair_failures(resolved, brand) == []
    end
  end

  describe "admin pairs (D-07)" do
    test "every declared admin pair meets its ratio in both themes", %{
      resolved: resolved,
      slots: slots
    } do
      assert admin_pair_failures(resolved, slots, @admin_pairs) == []
    end

    test "the pair ids are unique" do
      ids = Enum.map(@admin_pairs, & &1.id)
      assert ids == Enum.uniq(ids)
    end
  end

  describe "coverage guards" do
    test "every daisyUI slot is in a declared pair or exempt with a reason", %{slots: slots} do
      assert slot_coverage_failures(slots, @admin_pairs, @slot_exemptions) == []
      assert Enum.all?(@tiers, &(map_size(slots[&1]) == 20))
    end

    test "every role is exempt with a reason or in a declared pair where it matters", %{
      tokens: tokens
    } do
      for {role, reason} <- @role_exemptions do
        assert String.trim(reason) != "", "exemption for #{role} needs a reason"

        for tier <- @tiers do
          assert Map.has_key?(tokens["color"][tier], role),
                 "exempt role #{role} is not a token role in the #{tier} tier"
        end
      end
    end

    test "every designed value is covered by a declared pair (D-05)", %{
      tokens: tokens,
      slots: slots
    } do
      assert designed_coverage_failures(tokens, @admin_pairs, slots) == []
    end

    test "roles described as unreferenced by admin CSS really are", %{tokens: tokens} do
      assert unreferenced_claim_failures(tokens) == []

      claimed =
        for tier <- @tiers,
            {role, %{"$description" => d}} <- tokens["color"][tier],
            d =~ "unreferenced by admin CSS",
            do: {tier, role}

      assert length(claimed) == 16, "eight unconsumed roles x two tiers"
    end
  end

  describe "book never rules (D-07)" do
    test "logo Glass is never a text, link, accent or control role or an X-content slot", %{
      resolved: resolved,
      brand: brand,
      slots: slots
    } do
      assert never_glass_failures(resolved, brand, slots) == []
    end

    test "Sand Line is never a control border", %{resolved: resolved, brand: brand} do
      assert never_line_failures(resolved, brand) == []
    end

    test "Deep Glass is never a dark-theme text role", %{resolved: resolved, brand: brand} do
      assert never_deep_glass_failures(resolved, brand) == []
    end
  end

  describe "detectors have teeth (fail-first proof)" do
    test "a darker dark text-muted turns the descriptor book pair and an admin pair red", %{
      resolved: resolved,
      brand: brand,
      slots: slots
    } do
      key = {"dark", "--mg-color-text-muted"}
      darker = Contrast.composite(resolved[key], resolved[{"dark", "--mg-color-background"}], 0.4)
      mutated = Map.put(resolved, key, darker)

      assert Enum.any?(
               book_pair_failures(mutated, brand),
               &(&1 =~ "descriptor (dark)" and &1 =~ darker and &1 =~ "below the 4.5")
             )

      assert Enum.any?(
               admin_pair_failures(mutated, slots, @admin_pairs),
               &(&1 =~ "text-secondary-on-base-100 (dark)")
             )
    end

    test "a role that drifts from the book hex is red even when the ratio still passes", %{
      resolved: resolved,
      brand: brand
    } do
      mutated = Map.put(resolved, {"light", "--mg-color-text"}, "#000000")

      assert Enum.any?(
               book_pair_failures(mutated, brand),
               &(&1 =~ "body (light)" and &1 =~ "#2a1d17")
             )
    end

    test "a mutated published ratio and an unknown book pair are red", %{
      resolved: resolved,
      brand: brand
    } do
      wrong =
        update_in(brand, ["color", "contrastPairs"], fn pairs ->
          List.update_at(pairs, 0, &put_in(&1, ["light", "contrast"], 16.0))
        end)

      assert Enum.any?(
               book_pair_failures(resolved, wrong),
               &(&1 =~ "body (light)" and &1 =~ "published")
             )

      extra =
        update_in(brand, ["color", "contrastPairs"], fn pairs ->
          pairs ++ [%{"id" => "new-pair", "minimum" => 4.5, "light" => %{}, "dark" => %{}}]
        end)

      assert Enum.any?(
               book_pair_failures(resolved, extra),
               &(&1 =~ "new-pair" and &1 =~ "not bound")
             )
    end

    test "an X-content slot removed from the pair table turns the slot guard red", %{slots: slots} do
      pairs = Enum.reject(@admin_pairs, &(&1.id == "neutral-content-on-neutral"))
      failures = slot_coverage_failures(slots, pairs, @slot_exemptions)

      assert Enum.any?(failures, &(&1 =~ "neutral-content" and &1 =~ "no declared"))
    end

    test "a stale or reasonless slot exemption is red", %{slots: slots} do
      stale = Map.put(@slot_exemptions, "base-100", "pretend")
      assert Enum.any?(slot_coverage_failures(slots, @admin_pairs, stale), &(&1 =~ "base-100"))

      reasonless = Map.put(@slot_exemptions, "base-300", "  ")
      assert Enum.any?(slot_coverage_failures(slots, @admin_pairs, reasonless), &(&1 =~ "reason"))
    end

    test "dropping info-text-on-info-bg turns the designed-value guard red", %{
      tokens: tokens,
      slots: slots
    } do
      pairs = Enum.reject(@admin_pairs, &(&1.id == "info-text-on-info-bg"))
      failures = designed_coverage_failures(tokens, pairs, slots)

      assert Enum.any?(failures, &(&1 =~ "palette.tint-info-light"))
      assert Enum.any?(failures, &(&1 =~ "palette.tint-info-dark"))
      assert Enum.any?(failures, &(&1 =~ "info-text-on-info-bg" and &1 =~ "color.light.info-bg"))
    end

    test "a pair that falls below its ratio is red", %{resolved: resolved, slots: slots} do
      sand_line = resolved[{"light", "--mg-color-border"}]
      mutated = Map.put(resolved, {"light", "--mg-color-border-input"}, sand_line)

      assert Enum.any?(
               admin_pair_failures(mutated, slots, @admin_pairs),
               &(&1 =~ "border-input-on-base-100 (light)" and &1 =~ "below the 3.0")
             )
    end

    test "each never rule goes red on a planted violation", %{
      resolved: resolved,
      brand: brand,
      slots: slots
    } do
      glass = brand["color"]["logo"]["hex"] |> Contrast.normalize_hex()

      link_glass = Map.put(resolved, {"light", "--mg-color-link"}, glass)
      assert Enum.any?(never_glass_failures(link_glass, brand, slots), &(&1 =~ "--mg-color-link"))

      solid_glass = Map.put(resolved, {"dark", "--mg-color-info-solid"}, glass)

      assert Enum.any?(
               never_glass_failures(solid_glass, brand, slots),
               &(&1 =~ "--mg-color-info-solid")
             )

      slot_glass = put_in(slots, ["light", "primary-content"], "logo-glass")

      assert Enum.any?(
               never_glass_failures(resolved, brand, slot_glass),
               &(&1 =~ "primary-content")
             )

      sand_line =
        Contrast.normalize_hex(
          hd(brand["color"]["light"] |> Enum.filter(&(&1["name"] == "Sand Line")))["hex"]
        )

      line_input = Map.put(resolved, {"light", "--mg-color-border-input"}, sand_line)
      assert Enum.any?(never_line_failures(line_input, brand), &(&1 =~ "--mg-color-border-input"))

      deep_glass =
        Contrast.normalize_hex(
          hd(brand["color"]["light"] |> Enum.filter(&(&1["name"] == "Deep Glass")))["hex"]
        )

      dark_text = Map.put(resolved, {"dark", "--mg-color-text"}, deep_glass)
      assert Enum.any?(never_deep_glass_failures(dark_text, brand), &(&1 =~ "--mg-color-text"))
    end
  end

  # ---------------------------------------------------------------------------------------
  # Pure rule functions: inputs -> [failure string]
  # ---------------------------------------------------------------------------------------

  defp book_pair_failures(resolved, brand) do
    pairs = brand["color"]["contrastPairs"]
    ids = Enum.map(pairs, & &1["id"])

    unbound =
      for id <- ids, not Map.has_key?(@book_binding, id) do
        "book pair #{id} is not bound in the test's binding table; bind it to two token roles"
      end

    dropped =
      for id <- Map.keys(@book_binding), id not in ids do
        "binding table entry #{id} has no pair in brandbook/v2/brand.json any more"
      end

    checked =
      for pair <- pairs, Map.has_key?(@book_binding, pair["id"]), tier <- @tiers do
        {fg_role, bg_role} = Map.fetch!(@book_binding, pair["id"])
        book_pair_tier_failures(pair, tier, {fg_role, bg_role}, resolved)
      end

    unbound ++ dropped ++ List.flatten(checked)
  end

  defp book_pair_tier_failures(pair, tier, {fg_role, bg_role}, resolved) do
    want = pair[tier]
    id = "#{pair["id"]} (#{tier})"

    with {:ok, fg} <- role_hex(resolved, tier, fg_role),
         {:ok, bg} <- role_hex(resolved, tier, bg_role) do
      ratio = Contrast.ratio(fg, bg)
      minimum = pair["minimum"]

      hex_failures =
        for {label, role, have, book} <- [
              {"text", fg_role, fg, want["text"]},
              {"ground", bg_role, bg, want["ground"]}
            ],
            have != Contrast.normalize_hex(book) do
          "#{id}: #{label} role #{role} is #{have} but the book says #{String.downcase(book)}"
        end

      min_failures =
        if ratio >= minimum,
          do: [],
          else: [
            "#{id}: #{fg_role} #{fg} on #{bg_role} #{bg} is #{fmt(ratio)}:1, below the #{minimum}:1 minimum"
          ]

      published = want["contrast"]

      tolerance_failures =
        if abs(ratio - published) <= @book_tolerance,
          do: [],
          else: [
            "#{id}: #{fmt(ratio)}:1 is not within #{@book_tolerance} of the published #{published}:1"
          ]

      hex_failures ++ min_failures ++ tolerance_failures
    else
      :error -> ["#{id}: role #{fg_role} or #{bg_role} has no value in tokens.json"]
    end
  end

  defp admin_pair_failures(resolved, slots, pairs) do
    for pair <- pairs, tier <- @tiers, reduce: [] do
      acc ->
        with {:ok, fg} <- operand_hex(pair.fg, tier, resolved, slots),
             {:ok, bg} <- operand_hex(pair.bg, tier, resolved, slots) do
          ratio = Contrast.ratio(fg, bg)

          if ratio >= pair.min,
            do: acc,
            else:
              acc ++
                [
                  "#{pair.id} (#{tier}): #{fg} on #{bg} is #{fmt(ratio)}:1, below the #{pair.min}:1 minimum"
                ]
        else
          {:error, why} -> acc ++ ["#{pair.id} (#{tier}): #{why}"]
        end
    end
  end

  defp slot_coverage_failures(slots, pairs, exemptions) do
    covered =
      pairs |> Enum.flat_map(&(operand_slots(&1.fg) ++ operand_slots(&1.bg))) |> MapSet.new()

    uncovered =
      for tier <- @tiers,
          slot <- Enum.sort(Map.keys(slots[tier])),
          slot not in covered,
          not Map.has_key?(exemptions, slot) do
        "slot #{slot} (#{tier} theme) is in no declared contrast pair and has no exemption"
      end

    exemption_failures =
      for {slot, reason} <- exemptions do
        cond do
          String.trim(reason) == "" -> "exemption for slot #{slot} has no reason"
          slot in covered -> "exemption for slot #{slot} is stale: the slot is in a declared pair"
          not Map.has_key?(slots["light"], slot) -> "exemption for #{slot} names no daisyUI slot"
          true -> nil
        end
      end

    uncovered ++ Enum.reject(exemption_failures, &is_nil/1)
  end

  defp designed_coverage_failures(tokens, pairs, slots) do
    covered =
      for tier <- @tiers, into: %{} do
        book = for {_id, {fg, bg}} <- @book_binding, role <- [fg, bg], do: role

        admin =
          for pair <- pairs,
              operand <- [pair.fg, pair.bg],
              role <- operand_roles(operand, tier, slots),
              do: role

        {tier, MapSet.new(book ++ admin)}
      end

    designed =
      for {key, entry} <- tokens["palette"],
          key != "$type",
          get_in(entry, ["$extensions", "mailglass", "designed"]),
          do: key

    value_failures =
      for key <- Enum.sort(designed), tier <- @tiers do
        roles =
          for {role, %{"$value" => v}} <- tokens["color"][tier], v == "{palette.#{key}}", do: role

        if roles != [] and Enum.all?(roles, &(&1 not in covered[tier])) do
          "palette.#{key} is designed and used by #{Enum.join(roles, ", ")} in the #{tier} tier, " <>
            "but none of those roles is in a declared contrast pair"
        end
      end

    description_failures =
      for tier <- @tiers, {role, %{"$description" => desc}} <- tokens["color"][tier] do
        case Regex.run(~r/unreferenced by admin CSS; contrast-checked as ([a-z0-9-]+)$/, desc) do
          [_, id] ->
            case Enum.find(pairs, &(&1.id == id)) do
              nil ->
                "color.#{tier}.#{role} $description names pair #{id}, which is not in the admin pair table"

              pair ->
                involved = Enum.flat_map([pair.fg, pair.bg], &operand_roles(&1, tier, slots))

                if role in involved,
                  do: nil,
                  else:
                    "color.#{tier}.#{role} $description names pair #{id}, which does not involve #{role}"
            end

          nil ->
            if desc =~ "unreferenced by admin CSS",
              do: "color.#{tier}.#{role} $description has a malformed contrast-checked tag",
              else: nil
        end
      end

    Enum.reject(value_failures ++ description_failures, &is_nil/1)
  end

  # The claim "unreferenced by admin CSS" must stay true: no theme block or lib file reads
  # the role. When Phase 182 or later adds a consumer, update the description and the pair.
  defp unreferenced_claim_failures(tokens) do
    roles =
      for tier <- @tiers,
          {role, %{"$description" => d}} <- tokens["color"][tier],
          d =~ "unreferenced by admin CSS",
          uniq: true,
          do: role

    files = [@css_source_path | Path.wildcard(Path.join(@admin_root, "lib/**/*.{ex,heex}"))]
    sources = Enum.map(files, &{&1, File.read!(&1)})

    for role <- roles,
        {file, body} <- sources,
        Regex.match?(~r/--mg-color-#{Regex.escape(role)}(?![a-z0-9-])/, body) do
      "--mg-color-#{role} is described as unreferenced by admin CSS but #{Path.relative_to(file, @repo_root)} reads it"
    end
  end

  defp never_glass_failures(resolved, brand, slots) do
    glass =
      [brand["color"]["logo"]["hex"], brand["color"]["logo"]["onDark"]]
      |> Enum.map(&Contrast.normalize_hex/1)

    role_failures =
      for {{tier, "--mg-color-" <> role = var}, hex} <- resolved,
          text_like?(role) or control_like?(role),
          hex in glass do
        "never rule: logo Glass #{hex} is the #{tier} #{var} role (Glass is never text, a link, accent or a control)"
      end

    slot_failures =
      for tier <- @tiers,
          {slot, role} <- slots[tier],
          String.ends_with?(slot, "-content"),
          {:ok, hex} <- [role_hex(resolved, tier, role)],
          hex in glass do
        "never rule: logo Glass #{hex} is the #{tier} #{slot} slot (via #{role}); Glass is never text"
      end

    role_failures ++ slot_failures
  end

  defp never_line_failures(resolved, brand) do
    lines = [
      {"light", named_hex(brand["color"]["light"], "Sand Line")},
      {"dark", named_hex(brand["color"]["dark"], "Roast Line")}
    ]

    for {tier, line} <- lines,
        role <- ["border-input", "border-strong"],
        resolved[{tier, "--mg-color-#{role}"}] == line do
      "never rule: --mg-color-#{role} (#{tier}) is the divider colour #{line}; a control edge is Control Edge"
    end
  end

  defp never_deep_glass_failures(resolved, brand) do
    deep_glass = named_hex(brand["color"]["light"], "Deep Glass")

    for {{"dark", "--mg-color-" <> role = var}, hex} <- resolved,
        text_like?(role),
        hex == deep_glass do
      "never rule: Deep Glass #{hex} is the dark #{var} role; dark text is Bright Glass"
    end
  end

  # ---------------------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------------------

  defp text_like?(role) do
    String.starts_with?(role, "text") or String.ends_with?(role, "-text") or
      String.starts_with?(role, "link") or String.starts_with?(role, "accent")
  end

  defp control_like?(role) do
    role in ~w(focus-ring border-input border-strong) or String.ends_with?(role, "-solid")
  end

  defp named_hex(list, name) do
    list |> Enum.find(&(&1["name"] == name)) |> Map.fetch!("hex") |> Contrast.normalize_hex()
  end

  defp role_var("logo-" <> rest), do: "--mg-logo-" <> rest
  defp role_var(role), do: "--mg-color-" <> role

  defp role_hex(resolved, tier, role) do
    case Map.fetch(resolved, {tier, role_var(role)}) do
      {:ok, hex} -> {:ok, hex}
      :error -> :error
    end
  end

  defp operand_hex({:role, role}, tier, resolved, _slots) do
    case role_hex(resolved, tier, role) do
      {:ok, hex} -> {:ok, hex}
      :error -> {:error, "role #{role} has no value in the #{tier} tier"}
    end
  end

  defp operand_hex({:slot, slot}, tier, resolved, slots) do
    case get_in(slots, [tier, slot]) do
      nil -> {:error, "slot #{slot} is not mapped in the #{tier} theme block of app.css"}
      role -> operand_hex({:role, role}, tier, resolved, slots)
    end
  end

  defp operand_hex({:tint, color, over, alpha}, tier, resolved, slots) do
    with {:ok, color_hex} <- operand_hex(color, tier, resolved, slots),
         {:ok, over_hex} <- operand_hex(over, tier, resolved, slots) do
      {:ok, Contrast.composite(color_hex, over_hex, alpha)}
    end
  end

  defp operand_slots({:slot, slot}), do: [slot]
  defp operand_slots({:role, _role}), do: []

  defp operand_slots({:tint, color, over, _alpha}),
    do: operand_slots(color) ++ operand_slots(over)

  defp operand_roles({:role, role}, _tier, _slots), do: [role]

  defp operand_roles({:slot, slot}, tier, slots) do
    case get_in(slots, [tier, slot]) do
      nil -> []
      role -> [role]
    end
  end

  defp operand_roles({:tint, color, over, _alpha}, tier, slots),
    do: operand_roles(color, tier, slots) ++ operand_roles(over, tier, slots)

  # %{"light" => %{"base-100" => "background", ...}, "dark" => ...} from the two daisyUI
  # theme plugin blocks in assets/css/app.css.
  defp parse_slots(css_source) do
    ~r/@plugin\s+"[^"]*daisyui-theme"\s*\{(.*?)\n\}/s
    |> Regex.scan(css_source, capture: :all_but_first)
    |> Map.new(fn [block] ->
      [_, name] = Regex.run(~r/name:\s*"([^"]+)"/, block)

      slots =
        ~r/--color-([a-z0-9-]+):\s*var\(--mg-color-([a-z0-9-]+)\)/
        |> Regex.scan(block, capture: :all_but_first)
        |> Map.new(fn [slot, role] -> {slot, role} end)

      {tier_for_theme(name), slots}
    end)
  end

  defp tier_for_theme("mailglass-light"), do: "light"
  defp tier_for_theme("mailglass-dark"), do: "dark"

  defp fmt(ratio), do: ratio |> Float.round(2) |> Float.to_string()
end
