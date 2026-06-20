defmodule MailglassAdmin.GroupNestingTest do
  @moduledoc """
  Authoritative box-nesting depth proof for the three composed component groups
  (Phase 114, GROUP-02 / D-07).

  Renders each PUBLIC composed-group function (`composed_support_triage/1`,
  `composed_routing_evidence/1`, `composed_detail_timeline/1` — the SAME tree the
  gallery route and the operator/inbound detail columns render, plan 02) and
  proves that within its `data-region` no chain of "elevation surfaces" nests
  deeper than 2. This is the depth authority; the GROUP-GATE grep tripwire
  (plan 01 / `check-conformance.sh`) is only a cheap signal.

  An elevation surface is any node carrying ANY of `bg-base-200 | bg-base-100 |
  shadow-raised`. A node counts ONCE regardless of how many of those classes it
  carries (so the outer raised card with both `bg-base-200` and `shadow-raised`
  is depth 1, not 2 — `support_cards` post box-prison fix is section(raised) ->
  inset(bg-base-100) = depth 2).

  Floki 0.38.4 has NO parent API (Pitfall 3) — depth is counted TOP-DOWN by
  recursing the `{tag, attrs, children}` tuple tree, never via `Floki.parent`.
  """

  use MailglassAdmin.LiveViewCase, async: false

  # `~H` + `assigns` for the populated-state wrapper component below.
  import Phoenix.Component

  # Surface classes that count as one elevation step. Co-located here alongside
  # the depth proof that owns the rule (D-07 discretion item).
  @elevation_classes ~w(bg-base-200 bg-base-100 shadow-raised)

  describe "composed-group nesting depth (GROUP-02, depth <= 2)" do
    test "support-triage composed group nests at most 2 elevation surfaces" do
      html = render_component(&MailglassAdmin.GalleryLive.composed_support_triage/1, %{})
      assert max_elevation_depth(html) <= 2
    end

    test "routing-evidence composed group nests at most 2 elevation surfaces" do
      html = render_component(&MailglassAdmin.GalleryLive.composed_routing_evidence/1, %{})
      assert max_elevation_depth(html) <= 2
    end

    test "detail-timeline composed group nests at most 2 elevation surfaces" do
      html = render_component(&MailglassAdmin.GalleryLive.composed_detail_timeline/1, %{})
      assert max_elevation_depth(html) <= 2
    end

    # The composed_* specimens above carry zero counts, so the three Tier-1
    # `bg-base-100` insets inside `support_cards` are gated off by `:if={count > 0}`
    # and never render — the data-free proof only measures depth 1. This populated
    # render forces all three insets present so the regression guard actually
    # exercises the section(bg-base-200) -> inset(bg-base-100) nesting the
    # box-prison fix governs (GROUP-02 / D-07).
    test "support-cards group nests exactly 2 elevation surfaces with insets populated" do
      html =
        render_component(&populated_support_cards/1, %{
          support_summary: %{
            failed_ingest: %{count: 3, latest: nil},
            orphan_backlog: %{count: 5, oldest: nil},
            replay_outcomes: %{counts: %{failed: 2, noop: 1, replayed: 4}, latest: nil},
            reconcile_facts: %{
              reconciled_count: 0,
              still_unmatched_count: 0,
              latest_reconciled: nil
            }
          },
          support_state: %{focused_card: nil, drilldown_banner: nil},
          suppression_count: 7
        })

      # The three Tier-1 insets must actually render in the populated state
      # (parse top-down like `max_elevation_depth`, never via a raw-string selector).
      {:ok, doc} = Floki.parse_fragment(html)
      assert length(Floki.find(doc, "article.bg-base-100")) == 3

      # section (raised card, bg-base-200) -> inset (bg-base-100) = depth 2, no deeper.
      assert max_elevation_depth(html) == 2
    end
  end

  # Wraps `support_cards` in the `data-region` shell the depth helper scopes to,
  # mirroring how the composed_* group functions wrap their group modules. Takes
  # the populated assigns directly so the Tier-1 `bg-base-100` insets render.
  defp populated_support_cards(assigns) do
    ~H"""
    <div data-region class="space-y-4">
      <MailglassAdmin.Operator.SupportCards.support_cards
        support_summary={@support_summary}
        support_state={@support_state}
        suppression_count={@suppression_count}
      />
    </div>
    """
  end

  # The deepest chain of elevation surfaces within ANY data-region subtree.
  defp max_elevation_depth(html) do
    {:ok, doc} = Floki.parse_fragment(html)

    doc
    |> Floki.find("[data-region]")
    |> Enum.map(&deepest_chain/1)
    |> Enum.max(fn -> 0 end)
  end

  # Recurse the tuple tree top-down (no Floki.parent — it does not exist in
  # 0.38.4). Increment by 1 when a node is an elevation surface; count once per
  # node, never once per class.
  defp deepest_chain({_tag, attrs, children}) do
    bump = if elevation?(attrs), do: 1, else: 0

    child_max =
      children
      |> Enum.filter(&is_tuple/1)
      |> Enum.map(&deepest_chain/1)
      |> Enum.max(fn -> 0 end)

    bump + child_max
  end

  defp deepest_chain(_text_node), do: 0

  defp elevation?(attrs) do
    class = attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1)
    Enum.any?(@elevation_classes, &String.contains?(class, &1))
  end
end
