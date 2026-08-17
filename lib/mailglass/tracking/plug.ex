defmodule Mailglass.Tracking.Plug do
  @moduledoc """
  Mountable Plug endpoint for open-pixel + click-redirect URLs.

  ## Mount

      # In adopter's endpoint or router:
      forward "/track", Mailglass.Tracking.Plug

  ## Routes

  - `GET /o/:token.gif` — 43-byte transparent GIF89a when valid.
    **Failed verify returns HTTP 204** (not 404 — per , no URL enumeration).
  - `GET /c/:token` — HTTP 302 redirect to the signed target_url.
    Failed verify returns HTTP 404.

  ## Security headers

  Pixel response:
  - `Cache-Control: no-store, private, max-age=0`
  - `Pragma: no-cache`
  - `X-Robots-Tag: noindex`
  - `Content-Type: image/gif`

  ## Telemetry

  Emits `[:mailglass, :tracking, kind, :recorded]` only after a successful
  event-ledger append. Returned or raised ledger failures emit
  `[:mailglass, :tracking, kind, :failed]` while retaining the GIF/redirect
  response. Metadata is `%{delivery_id: binary, tenant_id: binary}` plus a
  finite `:failure_class` on failed events — no PII.
  """

  use Plug.Router

  import Plug.Conn

  plug(:match)
  plug(:dispatch)

  # Minimal 1×1 transparent GIF89a — exactly 43 bytes.
  # GIF89a header + color table + graphic control + image descriptor + LZW data + trailer.
  @gif89a_pixel <<71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 255, 255, 255, 0, 0, 0, 33, 249, 4,
                  1, 0, 0, 0, 0, 44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 68, 1, 0, 59>>

  get "/o/:token" do
    # Strip .gif suffix — URL shape is /o/<token>.gif
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
        # : failed verify returns 204 (empty body) — never 404.
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
    record_event(:open, delivery_id, tenant_id, %{
      tenant_id: tenant_id,
      delivery_id: delivery_id,
      type: :opened,
      occurred_at: Mailglass.Clock.utc_now(),
      normalized_payload: %{source: :pixel}
    })
  end

  defp record_click_event(delivery_id, tenant_id, target_url) do
    # Hash the URL to avoid storing PII-adjacent click targets in event metadata.
    url_hash = :crypto.hash(:sha256, target_url) |> Base.encode16(case: :lower)

    record_event(:click, delivery_id, tenant_id, %{
      tenant_id: tenant_id,
      delivery_id: delivery_id,
      type: :clicked,
      occurred_at: Mailglass.Clock.utc_now(),
      normalized_payload: %{source: :click, target_url_hash: url_hash}
    })
  end

  defp record_event(kind, delivery_id, tenant_id, attrs) do
    result =
      Mailglass.Tenancy.with_tenant(tenant_id, fn ->
        event_ledger().append(attrs)
      end)

    case result do
      {:ok, _event} ->
        emit_recorded(kind, delivery_id, tenant_id)

      {:error, _reason} ->
        emit_failed(kind, delivery_id, tenant_id, :append_error)

      _other ->
        emit_failed(kind, delivery_id, tenant_id, :unexpected_result)
    end
  rescue
    _ -> emit_failed(kind, delivery_id, tenant_id, :exception)
  end

  defp event_ledger do
    Application.get_env(:mailglass, :tracking_event_ledger, Mailglass.Events)
  end

  defp emit_recorded(kind, delivery_id, tenant_id) do
    :telemetry.execute(
      [:mailglass, :tracking, kind, :recorded],
      %{count: 1},
      %{delivery_id: delivery_id, tenant_id: tenant_id}
    )
  end

  defp emit_failed(kind, delivery_id, tenant_id, failure_class) do
    :telemetry.execute(
      [:mailglass, :tracking, kind, :failed],
      %{count: 1},
      %{delivery_id: delivery_id, tenant_id: tenant_id, failure_class: failure_class}
    )
  end
end
