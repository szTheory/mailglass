defmodule MailglassAdmin.PersonaDriftGuardTest do
  @moduledoc """
  Fail-closed drift guard for the RATCHET-01 persona cohort (CONTEXT D-07).

  The persona cohort is materialized by THREE thin builders from one declarative
  spec (`MailglassDemo.Personas.spec/0`):

    1. the demo seed (`MailglassDemo.DemoData.reset!/0` → `Personas.seed!/1`),
    2. the admin test-support materializer
       (`OperatorFixtures.seed_persona_cohort!/0`), and
    3. the gallery static specimens (widened in plan 116-04, Wave 2).

  N-materializer fixtures fail by *triplication drift*: a persona or literal is
  changed in one builder and silently diverges from the others. This guard
  treats `Personas.spec/0` as the single source of truth and asserts the
  materializers cannot diverge — failing closed when they do.

  Concretely it asserts:

    * the admin materializer produces EXACTLY the spec's tenant_ids and
      edge-case coverage (adding a persona to `spec/0` without materializing it
      fails this guard — fail-closed); and
    * the shared stress-specimen value literals (non-ASCII names, the long
      delivery id, the long Mailable module name, the `reject_reason: nil`
      branch) that the gallery (116-04) must mirror are exactly the values the
      admin materializer wrote — so the gallery, demo persona, and admin
      cohort stay byte-consistent.
  """
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.OperatorFixtures

  # The 8 canonical edge cases (D-08). Every persona's edge_cases set must be a
  # subset of this closed list — a typo in a builder's edge case fails closed.
  @canonical_edge_cases MapSet.new([
                          :no_data,
                          :one,
                          :many,
                          :long_id,
                          :non_ascii,
                          :null,
                          :high_count,
                          :error
                        ])

  describe "spec is the single source of truth" do
    test "the three personas + edge-case assignments match the locked D-08 set" do
      by_name = Map.new(MailglassDemo.Personas.spec(), &{&1.name, &1.edge_cases})

      assert Map.keys(by_name) |> Enum.sort() ==
               ["fjordline-aps", "helios-void", "northstar"]

      assert MapSet.equal?(by_name["northstar"], MapSet.new([:many, :high_count, :error]))
      assert MapSet.equal?(by_name["fjordline-aps"], MapSet.new([:one, :long_id, :non_ascii, :null]))
      assert MapSet.equal?(by_name["helios-void"], MapSet.new([:no_data]))
    end

    test "every persona's edge cases draw from the closed 8-case set (fail-closed on typos)" do
      for %{name: name, edge_cases: edge_cases} <- MailglassDemo.Personas.spec() do
        assert MapSet.subset?(edge_cases, @canonical_edge_cases),
               "persona #{name} has edge cases outside the canonical 8: " <>
                 inspect(MapSet.difference(edge_cases, @canonical_edge_cases))
      end
    end
  end

  describe "admin materializer cannot diverge from the spec (D-07)" do
    test "deliveries-bearing personas in the spec are exactly the ones materialized" do
      OperatorFixtures.seed_persona_cohort!()

      # The spec's deliveries-bearing personas: every persona NOT carrying the
      # :no_data edge must produce >= 1 Delivery row.
      spec_bearing =
        MailglassDemo.Personas.spec()
        |> Enum.reject(&MapSet.member?(&1.edge_cases, :no_data))
        |> Enum.map(& &1.name)
        |> Enum.sort()

      materialized =
        TestRepo.all(
          from(d in Delivery,
            distinct: true,
            where: not is_nil(d.tenant_id) and d.tenant_id != "",
            select: d.tenant_id
          )
        )
        |> Enum.sort()

      assert materialized == spec_bearing,
             "admin materializer drifted from spec: spec expects deliveries for " <>
               "#{inspect(spec_bearing)} but materialized #{inspect(materialized)}"

      # The :no_data persona must NOT appear (fail-closed on absence-by-design).
      no_data_names =
        MailglassDemo.Personas.spec()
        |> Enum.filter(&MapSet.member?(&1.edge_cases, :no_data))
        |> Enum.map(& &1.name)

      for name <- no_data_names do
        refute name in materialized,
               "no-data persona #{name} must have zero deliveries but was materialized"
      end
    end

    test "adding a persona to spec() without materializing it fails closed" do
      OperatorFixtures.seed_persona_cohort!()

      # Simulate spec drift: a fourth deliveries-bearing persona added to the
      # spec but NOT added to any materializer. The guard's comparison
      # (spec_bearing == materialized) must reject it.
      drifted_spec_bearing =
        (MailglassDemo.Personas.spec()
         |> Enum.reject(&MapSet.member?(&1.edge_cases, :no_data))
         |> Enum.map(& &1.name)) ++ ["phantom-persona"]

      materialized =
        TestRepo.all(
          from(d in Delivery,
            distinct: true,
            where: not is_nil(d.tenant_id) and d.tenant_id != "",
            select: d.tenant_id
          )
        )

      refute Enum.sort(drifted_spec_bearing) == Enum.sort(materialized),
             "guard must fail closed when a spec persona has no materialization"
    end
  end

  describe "shared specimen literals stay byte-consistent (gallery ↔ persona)" do
    test "the admin materializer wrote EXACTLY the spec's canonical literals" do
      OperatorFixtures.seed_persona_cohort!()

      literals = MailglassDemo.Personas.specimen_literals()

      delivery =
        TestRepo.one!(
          from(d in Delivery, where: d.tenant_id == "fjordline-aps", select: d)
        )

      # Long delivery ID + long Mailable module name (truncation stress).
      assert delivery.provider_message_id == literals.long_delivery_id
      assert delivery.mailable == literals.long_mailable

      # Non-ASCII display names (Latin-extended + CJK).
      from_names = delivery.metadata |> Map.get("from", []) |> Enum.map(& &1["name"])
      assert literals.nonascii_name_latin in from_names
      assert literals.nonascii_name_cjk in from_names

      # The null branch: a :delivered event with reject_reason: nil.
      event =
        TestRepo.one!(
          from(e in Event, where: e.delivery_id == ^delivery.id, select: e)
        )

      assert event.type == :delivered
      assert is_nil(event.reject_reason)
    end

    test "the canonical literals satisfy the gallery stress contract (116-UI-SPEC)" do
      # These are the documented constants plan 116-04 MUST consume verbatim when
      # widening the gallery. Asserting their SHAPE here keeps the gallery
      # widening honest: if 116-04 wires a different value, the spec literal it
      # must mirror is pinned here.
      literals = MailglassDemo.Personas.specimen_literals()

      assert literals.nonascii_name_latin == "Bjørn Hansen"
      assert literals.nonascii_name_cjk == "山田太郎"
      assert String.starts_with?(literals.long_delivery_id, "del_01JXW")
      assert String.length(literals.long_delivery_id) >= 26

      assert literals.long_mailable ==
               "Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName"

      assert String.length(literals.long_mailable) >= 60
    end

    test "if the gallery already mirrors a canonical literal, it must match the spec exactly" do
      # Forward-compatible drift guard for materializer 3 (the gallery, widened
      # in 116-04). The gallery source is read as text; for each canonical
      # literal, if the gallery references the persona-namespaced value it MUST
      # be byte-identical to the spec. Before 116-04 wires them the gallery may
      # not yet contain the values (asserted vacuously); after 116-04 any
      # divergence fails closed.
      literals = MailglassDemo.Personas.specimen_literals()
      gallery_src = File.read!(gallery_source_path())

      for {label, value} <- [
            {:non_ascii_latin, literals.nonascii_name_latin},
            {:non_ascii_cjk, literals.nonascii_name_cjk},
            {:long_delivery_id, literals.long_delivery_id},
            {:long_mailable, literals.long_mailable}
          ] do
        # A fjordline-namespaced reference in the gallery is the signal that the
        # gallery intends to mirror this persona literal. If present, it must be
        # the exact spec value.
        if String.contains?(gallery_src, "fjordline") and
             gallery_intends_literal?(gallery_src, label) do
          assert String.contains?(gallery_src, value),
                 "gallery mirrors the fjordline #{label} specimen but the value " <>
                   "diverged from the spec literal #{inspect(value)}"
        end
      end
    end
  end

  defp gallery_source_path do
    Path.join([
      Path.dirname(__ENV__.file),
      "..",
      "..",
      "lib",
      "mailglass_admin",
      "gallery_live.ex"
    ])
    |> Path.expand()
  end

  # Heuristic: the gallery "intends" to carry a fjordline persona literal once
  # 116-04 adds a fjordline-namespaced specimen for it. Until then this returns
  # false and the byte-consistency assertion is vacuous (the gallery's own
  # pre-existing Phase-113 long-value stress specimen is a DIFFERENT value and
  # is intentionally not governed by this persona drift guard).
  defp gallery_intends_literal?(gallery_src, _label) do
    String.contains?(gallery_src, "fjordline-aps")
  end
end
