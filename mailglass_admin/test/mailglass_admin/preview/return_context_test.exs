defmodule MailglassAdmin.Preview.ReturnContextTest do
  use ExUnit.Case, async: true

  @moduletag :phase177

  alias MailglassAdmin.Preview.ReturnContext

  @navigation %{
    overview_path: "/ops/mail?tenant_id=browser-tenant",
    deliveries_path: "/ops/mail?tenant_id=browser-tenant&view=deliveries",
    inbound_path: "/ops/mail/inbound?tenant_id=browser-tenant"
  }

  defp params(surface, tenant_id),
    do: %{"return_surface" => surface, "return_tenant_id" => tenant_id}

  defp decode(href) do
    uri = URI.parse(href)
    {uri.path, uri.query |> Kernel.||("") |> URI.query_decoder() |> Enum.to_list()}
  end

  describe "resolve/2 closed surface set" do
    test "accepts each closed-set surface and rebuilds the href from navigation" do
      assert %{surface: "overview", href: "/ops/mail?tenant_id=t"} =
               ReturnContext.resolve(params("overview", "t"), @navigation)

      assert %{surface: "deliveries", href: "/ops/mail?tenant_id=t&view=deliveries"} =
               ReturnContext.resolve(params("deliveries", "t"), @navigation)

      assert %{surface: "inbound", href: "/ops/mail/inbound?tenant_id=t"} =
               ReturnContext.resolve(params("inbound", "t"), @navigation)
    end

    test "returns the surface and id as query pairs for Preview-internal URLs" do
      context = ReturnContext.resolve(params("overview", "t"), @navigation)

      assert context.query_pairs == [{"return_surface", "overview"}, {"return_tenant_id", "t"}]
      assert ReturnContext.query_pairs(context) == context.query_pairs
    end

    for surface <- ["evil", "", "Overview", "OVERVIEW", " overview", "overview "] do
      test "rejects unknown surface #{inspect(surface)}" do
        assert ReturnContext.resolve(params(unquote(surface), "t"), @navigation) == nil
      end
    end

    test "a 10,000-character surface returns nil without raising or creating an atom" do
      surface = String.duplicate("a", 10_000)
      assert ReturnContext.resolve(params(surface, "t"), @navigation) == nil
    end

    test "list- and map-valued params resolve to nil" do
      assert ReturnContext.resolve(params(["overview"], "t"), @navigation) == nil
      assert ReturnContext.resolve(params(%{"x" => "overview"}, "t"), @navigation) == nil
      assert ReturnContext.resolve(params("overview", ["t"]), @navigation) == nil
      assert ReturnContext.resolve(params("overview", %{"a" => "t"}), @navigation) == nil
    end

    test "missing either key resolves to nil" do
      assert ReturnContext.resolve(%{"return_surface" => "overview"}, @navigation) == nil
      assert ReturnContext.resolve(%{"return_tenant_id" => "t"}, @navigation) == nil
      assert ReturnContext.resolve(%{}, @navigation) == nil
      assert ReturnContext.resolve(nil, @navigation) == nil
    end
  end

  describe "resolve/2 configured destination" do
    for path <- [
          nil,
          "",
          "https://x.example/ops",
          "//x.example",
          "/\\x",
          "/ops\\mail",
          "javascript:alert(1)"
        ] do
      test "rejects configured path #{inspect(path)}" do
        navigation = %{overview_path: unquote(path)}
        assert ReturnContext.resolve(params("overview", "t"), navigation) == nil
      end
    end

    test "resolves to nil without a navigation map" do
      assert ReturnContext.resolve(params("overview", "t"), nil) == nil
      assert ReturnContext.resolve(params("overview", "t"), %{}) == nil
    end

    test "tolerates string-keyed navigation maps" do
      navigation = %{"overview_path" => "/ops/mail?tenant_id=browser-tenant"}

      assert %{href: "/ops/mail?tenant_id=t"} =
               ReturnContext.resolve(params("overview", "t"), navigation)
    end

    test "a surface-less navigation entry for another surface does not leak" do
      assert ReturnContext.resolve(params("inbound", "t"), %{overview_path: "/ops/mail"}) == nil
    end
  end

  describe "resolve/2 tenant id boundaries" do
    for {label, id} <- [
          {"empty", ""},
          {"whitespace only", "   "},
          {"invalid utf-8", <<0xFF>>},
          {"newline", "a\nb"},
          {"tab", "a\tb"},
          {"nul", "a\u0000b"},
          {"delete", "a\u007Fb"}
        ] do
      test "rejects #{label} id" do
        assert ReturnContext.resolve(params("overview", unquote(id)), @navigation) == nil
      end
    end

    test "rejects a 256-byte id and accepts a 255-byte id" do
      assert ReturnContext.resolve(params("overview", String.duplicate("a", 256)), @navigation) ==
               nil

      assert %{tenant_id: id} =
               ReturnContext.resolve(params("overview", String.duplicate("a", 255)), @navigation)

      assert byte_size(id) == 255
    end

    test "accepts a single-character id" do
      assert %{href: "/ops/mail?tenant_id=a"} =
               ReturnContext.resolve(params("overview", "a"), @navigation)
    end

    for id <- ["a&view=x", "#f", "\"><svg>", "x\u202Ey", "a=b", "a b", "100%"] do
      test "injection-shaped id #{inspect(id)} round-trips only as an encoded value" do
        id = unquote(id)
        assert %{href: href} = ReturnContext.resolve(params("deliveries", id), @navigation)

        {path, pairs} = decode(href)
        assert path == "/ops/mail"
        assert Enum.map(pairs, &elem(&1, 0)) == ["tenant_id", "view"]
        assert pairs == [{"tenant_id", id}, {"view", "deliveries"}]
        refute href =~ "<"
        refute href =~ "#"
        refute href =~ " "
      end
    end
  end

  describe "surface_href/3" do
    test "replaces tenant_id in place without adding a second key" do
      assert ReturnContext.surface_href(@navigation, "deliveries", "t") ==
               "/ops/mail?tenant_id=t&view=deliveries"
    end

    test "appends tenant_id when the configured entry has none" do
      navigation = %{deliveries_path: "/ops/mail?view=deliveries"}

      assert ReturnContext.surface_href(navigation, "deliveries", "t") ==
               "/ops/mail?view=deliveries&tenant_id=t"
    end

    test "adds a query to a bare configured path" do
      assert ReturnContext.surface_href(%{inbound_path: "/ops/mail/inbound"}, "inbound", "t") ==
               "/ops/mail/inbound?tenant_id=t"
    end

    test "returns nil for unknown surfaces, missing and non-local entries" do
      assert ReturnContext.surface_href(@navigation, "evil", "t") == nil
      assert ReturnContext.surface_href(%{}, "overview", "t") == nil

      assert ReturnContext.surface_href(%{overview_path: "https://x.example"}, "overview", "t") ==
               nil

      assert ReturnContext.surface_href(nil, "overview", "t") == nil
    end
  end

  describe "append_query/2" do
    test "an empty pair list returns the path byte-identical" do
      assert ReturnContext.append_query("/dev/mail/X/y?width=375", []) ==
               "/dev/mail/X/y?width=375"

      assert ReturnContext.append_query("/dev/mail", []) == "/dev/mail"
    end

    test "appends encoded pairs after an existing query" do
      assert ReturnContext.append_query("/dev/mail/X/y?width=375", [
               {"return_surface", "overview"},
               {"return_tenant_id", "a&b"}
             ]) == "/dev/mail/X/y?width=375&return_surface=overview&return_tenant_id=a%26b"
    end

    test "adds a query when the path has none" do
      assert ReturnContext.append_query("/dev/mail", [{"k", "v"}]) == "/dev/mail?k=v"
    end
  end

  describe "operator_preview_href/3" do
    test "mints the context for each surface when an Account is selected" do
      for active <- [:overview, :deliveries, :inbound] do
        href = ReturnContext.operator_preview_href("/dev/mail", active, "tenant-b")
        {"/dev/mail", pairs} = decode(href)

        assert Enum.sort(pairs) ==
                 [{"return_surface", Atom.to_string(active)}, {"return_tenant_id", "tenant-b"}]
      end
    end

    test "nil or blank tenant leaves the configured path unchanged" do
      assert ReturnContext.operator_preview_href("/dev/mail", :overview, nil) == "/dev/mail"
      assert ReturnContext.operator_preview_href("/dev/mail", :overview, "") == "/dev/mail"
    end

    test "an invalid tenant id is never minted" do
      assert ReturnContext.operator_preview_href("/dev/mail", :overview, <<0xFF>>) == "/dev/mail"

      assert ReturnContext.operator_preview_href(
               "/dev/mail",
               :overview,
               String.duplicate("a", 256)
             ) == "/dev/mail"
    end

    test "a cross-origin Preview path never receives the Account id" do
      assert ReturnContext.operator_preview_href(
               "https://preview.example/mail",
               :overview,
               "tenant-b"
             ) == "https://preview.example/mail"

      assert ReturnContext.operator_preview_href("//preview.example/mail", :overview, "t") ==
               "//preview.example/mail"
    end

    test "nil preview path stays nil" do
      assert ReturnContext.operator_preview_href(nil, :overview, "tenant-b") == nil
    end

    test "an unknown active surface leaves the path unchanged" do
      assert ReturnContext.operator_preview_href("/dev/mail", :preview, "tenant-b") ==
               "/dev/mail"
    end
  end

  describe "local_path?/1 and valid_tenant_id?/1" do
    test "local_path?/1 accepts only single-slash absolute paths" do
      assert ReturnContext.local_path?("/ops/mail")
      assert ReturnContext.local_path?("/ops/mail?tenant_id=t")

      for bad <- [nil, "", "ops", "//x", "https://x", "/a\\b", "/a\nb", <<"/", 0xFF>>, :atom, 1] do
        refute ReturnContext.local_path?(bad), inspect(bad)
      end
    end

    test "valid_tenant_id?/1 rejects non-binaries" do
      refute ReturnContext.valid_tenant_id?(nil)
      refute ReturnContext.valid_tenant_id?(:t)
      refute ReturnContext.valid_tenant_id?(["t"])
    end
  end

  describe "back_label/1" do
    test "names only the closed-set surface" do
      assert ReturnContext.back_label("overview") == "Back to Health"
      assert ReturnContext.back_label("deliveries") == "Back to Deliveries"
      assert ReturnContext.back_label("inbound") == "Back to Inbound"
    end

    test "never interpolates request text" do
      assert ReturnContext.back_label("<script>") == "Back"
      assert ReturnContext.back_label(nil) == "Back"
    end
  end

  describe "totality" do
    test "a deterministic seeded loop of random byte strings never raises" do
      :rand.seed(:exsss, {177, 1, 2})

      for _ <- 1..500 do
        surface = :rand.bytes(:rand.uniform(12))
        tenant_id = :rand.bytes(:rand.uniform(24))
        pick = Enum.random(["overview", "deliveries", "inbound", surface])

        case ReturnContext.resolve(params(pick, tenant_id), @navigation) do
          nil -> :ok
          %{href: href} -> assert ReturnContext.local_path?(href)
        end
      end
    end
  end

  describe "source guarantees" do
    @source File.read!(
              Path.expand("../../../lib/mailglass_admin/preview/return_context.ex", __DIR__)
            )

    test "contains no atom creation, logging or telemetry" do
      refute @source =~ "String.to_atom"
      refute @source =~ "Logger"
      refute @source =~ ":telemetry"
    end
  end
end
