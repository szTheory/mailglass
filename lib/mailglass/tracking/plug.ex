defmodule Mailglass.Tracking.Plug do
  @moduledoc """
  Mountable Plug endpoint for open-pixel + click-redirect URLs (TRACK-03).

  ## Mount

      # In adopter's endpoint or router:
      forward "/track", Mailglass.Tracking.Plug

  ## Routes

  - `GET /o/:token.gif` — 43-byte transparent GIF89a when valid.
    **Failed verify returns HTTP 204** (not 404 — per D-39, no URL enumeration).
  - `GET /c/:token` — HTTP 302 redirect to the signed target_url.
    Failed verify returns HTTP 404.

  ## Security headers (D-34)

  Pixel response:
  - `Cache-Control: no-store, private, max-age=0`
  - `Pragma: no-cache`
  - `X-Robots-Tag: noindex`
  - `Content-Type: image/gif`

  ## Telemetry

  Emits `[:mailglass, :tracking, :open, :recorded]` and
  `[:mailglass, :tracking, :click, :recorded]` on successful event record.
  Metadata: `%{delivery_id: binary, tenant_id: binary}` — no PII (D-31).
  """

  use Plug.Router

  import Plug.Conn

  plug :match
  plug :dispatch

  # Minimal 1×1 transparent GIF89a — exactly 43 bytes.
  # GIF89a header + color table + graphic control + image descriptor + LZW data + trailer.
  @gif89a_pixel <<71, 73, 70, 56, 57, 97,
                  1, 0, 1, 0,
                  128, 0, 0,
                  255, 255, 255,
                  0, 0, 0,
                  33, 249, 4, 1, 0, 0, 0, 0,
                  44, 0, 0, 0, 0, 1, 0, 1, 0,
                  0, 2, 2, 68, 1, 0, 59>>

  get "/o/:token" do
    # Strip .gif suffix — URL shape is /o/<token>.gif (D-34)
    token_clean = String.replace_suffix(token, ".gif", "")

    case Mailglass.Tracking.Token.verify_open(Mailglass.Tracking.endpoint(), token_clean) do
      {:ok, %{delivery_id: did, tenant_id: tid}} ->
        record_open_event(did, tid)

        conn
        |> put_resp_content_type("image/gif")
        |> put_resp_header("cache-control", "no-store, private, max-age=0")
        |> put_resp_header("pragma", "no-cache")
        |> put_resp_header("x-robots-tag", "noindex")
        |> send_resp(200, @gif89a_pixel)

      :error ->
        # D-39: failed verify returns 204 (empty body) — never 404.
        # 204 reveals nothing about the URL structure or whether the token
        # was valid/invalid/expired; 404 would let an attacker enumerate.
        send_resp(conn, 204, "")
    end
  end

  get "/c/:token" do
    case Mailglass.Tracking.Token.verify_click(Mailglass.Tracking.endpoint(), token) do
      {:ok, %{delivery_id: did, tenant_id: tid, target_url: url}} ->
        record_click_event(did, tid, url)

        conn
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      :error ->
        send_resp(conn, 404, "")
    end
  end

  match _ do
    send_resp(conn, 404, "")
  end

  # --- Private helpers ---

  defp record_open_event(delivery_id, tenant_id) do
    Mailglass.Tenancy.with_tenant(tenant_id, fn ->
      result =
        Mailglass.Events.append(%{
          tenant_id: tenant_id,
          delivery_id: delivery_id,
          type: :opened,
          occurred_at: Mailglass.Clock.utc_now(),
          normalized_payload: %{source: :pixel}
        })

      :telemetry.execute(
        [:mailglass, :tracking, :open, :recorded],
        %{count: 1},
        %{delivery_id: delivery_id, tenant_id: tenant_id}
      )

      result
    end)
  rescue
    _ -> :ok
  end

  defp record_click_event(delivery_id, tenant_id, target_url) do
    Mailglass.Tenancy.with_tenant(tenant_id, fn ->
      # Hash the URL to avoid storing PII-adjacent click targets in event metadata (D-31).
      url_hash = :crypto.hash(:sha256, target_url) |> Base.encode16(case: :lower)

      result =
        Mailglass.Events.append(%{
          tenant_id: tenant_id,
          delivery_id: delivery_id,
          type: :clicked,
          occurred_at: Mailglass.Clock.utc_now(),
          normalized_payload: %{source: :click, target_url_hash: url_hash}
        })

      :telemetry.execute(
        [:mailglass, :tracking, :click, :recorded],
        %{count: 1},
        %{delivery_id: delivery_id, tenant_id: tenant_id}
      )

      result
    end)
  rescue
    _ -> :ok
  end

end
