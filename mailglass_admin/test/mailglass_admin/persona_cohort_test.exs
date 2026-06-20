defmodule MailglassAdmin.PersonaCohortTest do
  @moduledoc """
  Integration assertion for the RATCHET-01 persona stress cohort (CONTEXT D-06).

  Asserts that the admin-side materializer `seed_persona_cohort!/0` produces the
  three personas from the single declarative spec, that the two
  deliveries-bearing personas are selectable in `list_tenants/2`, that the
  zero-delivery persona (`helios-void`) is correctly absent, and that
  navigating a `helios-void`-scoped surface by direct URL renders the empty
  state rather than crashing (threat T-116-03).
  """
  use MailglassAdmin.LiveViewCase, async: false

  import Ecto.Query

  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.Operator.Tenants
  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @base_path "/ops/mail"

  # The cohort context: list_tenants/2 is reached through the authenticated
  # actor (a context map), NOT a raw admin Repo query (PHASE112-SHELL-GATE).
  @actor %{subject_id: "operator-1"}

  describe "persona cohort materialization (RATCHET-01)" do
    test "seeds exactly the three spec personas" do
      OperatorFixtures.seed_persona_cohort!()

      spec_names = MailglassDemo.Personas.spec() |> Enum.map(& &1.name) |> Enum.sort()
      assert spec_names == ["fjordline-aps", "helios-void", "northstar"]

      seeded_tenants =
        TestRepo.all(
          from(d in Delivery,
            distinct: true,
            where: not is_nil(d.tenant_id) and d.tenant_id != "",
            select: d.tenant_id
          )
        )
        |> Enum.sort()

      # northstar + fjordline-aps bear deliveries; helios-void does not.
      assert seeded_tenants == ["fjordline-aps", "northstar"]
    end

    test "fjordline-aps carries the canonical stress literals (single Delivery, null branch)" do
      OperatorFixtures.seed_persona_cohort!()

      literals = MailglassDemo.Personas.specimen_literals()

      fjordline_deliveries =
        TestRepo.all(
          from(d in Delivery, where: d.tenant_id == "fjordline-aps", select: d)
        )

      assert [delivery] = fjordline_deliveries
      assert delivery.provider_message_id == literals.long_delivery_id
      assert delivery.mailable == literals.long_mailable
      assert String.length(delivery.provider_message_id) >= 26
      assert String.length(delivery.mailable) >= 60

      from_names =
        delivery.metadata |> Map.get("from", []) |> Enum.map(& &1["name"])

      assert literals.nonascii_name_latin in from_names
      assert literals.nonascii_name_cjk in from_names

      # The null branch: one :delivered event with reject_reason: nil.
      events =
        TestRepo.all(
          from(e in Mailglass.Events.Event,
            where: e.delivery_id == ^delivery.id,
            select: e
          )
        )

      assert [event] = events
      assert event.type == :delivered
      assert is_nil(event.reject_reason)
    end
  end

  describe "tenant selectability (>=2 picker reason; no-data absent)" do
    test "list_tenants/2 returns >=2 selectable tenants incl northstar + fjordline-aps" do
      OperatorFixtures.seed_persona_cohort!()

      ids = Tenants.list_tenants(@actor, []) |> Enum.map(& &1.id)

      assert length(ids) >= 2
      assert "northstar" in ids
      assert "fjordline-aps" in ids
    end

    test "list_tenants/2 excludes helios-void (zero Delivery rows)" do
      OperatorFixtures.seed_persona_cohort!()

      ids = Tenants.list_tenants(@actor, []) |> Enum.map(& &1.id)

      refute "helios-void" in ids
    end
  end

  describe "helios-void direct-URL surface (T-116-03)" do
    test "bare URL renders the no-data overview without crashing", %{conn: conn} do
      OperatorFixtures.seed_persona_cohort!()

      conn = operator_conn(conn)

      # Direct navigation to the zero-delivery tenant must render the scoped
      # no-data state (the overview's all-clear health), not crash or leak
      # another tenant's data.
      {:ok, _view, html} =
        live(conn, @base_path <> "?" <> URI.encode_query(%{"tenant_id" => "helios-void"}))

      assert html =~ "helios-void"
      assert html =~ "All clear"
    end

    test "deliveries view renders the empty-state copy", %{conn: conn} do
      OperatorFixtures.seed_persona_cohort!()

      conn = operator_conn(conn)

      {:ok, _view, html} =
        live(
          conn,
          @base_path <>
            "?" <> URI.encode_query(%{"tenant_id" => "helios-void", "view" => "deliveries"})
        )

      # 116-UI-SPEC: helios-void direct-URL empty state copy.
      assert html =~ "No deliveries have been recorded yet."
    end
  end

  # Mirrors the authenticated operator session shape used across the operator
  # suite (current_user_id + tenant_id + recent password auth).
  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    conn
    |> Plug.Test.init_test_session(%{
      "current_user_id" => "operator-1",
      "tenant_id" => "helios-void",
      "auth_method" => "password",
      "recent_auth_at" => now
    })
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.configure_session(renew: false)
  end
end
