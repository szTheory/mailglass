defmodule Mailglass.Compliance.UnsubscribeController do
  @moduledoc """
  Core RFC 8058 unsubscribe controller.

  GET renders the built-in confirmation page by default or redirects to the
  configured escape hatch. POST atomically converges the canonical unsubscribe
  event and stream-scoped suppression before running best-effort host effects.
  """

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Compliance.UnsubscribeConvergence
  alias Mailglass.Compliance.UnsubscribeHTML
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Outbound.Projector
  alias Mailglass.Repo
  alias Mailglass.Tenancy

  require Logger

  @doc false
  def show(conn, %{"token" => token}) do
    with {:ok, %{delivery_id: delivery_id}} <- Unsubscribe.verify_token(token),
         %Delivery{} = delivery <- fetch_delivery(delivery_id) do
      maybe_redirect_or_render(conn, delivery)
    else
      {:error, :expired} -> failure(conn, 410, "unsubscribe token expired")
      {:error, :invalid} -> failure(conn, 404, "unsubscribe token invalid")
      nil -> failure(conn, 404, "unsubscribe token invalid")
    end
  end

  @doc false
  def unsubscribe(conn, %{"token" => token}) do
    case resolve_delivery(token) do
      {:ok, delivery} ->
        result = run_convergence(delivery)

        Tenancy.with_tenant(delivery.tenant_id, fn ->
          maybe_run_post_commit_effects(result, delivery)
        end)

        respond_to_unsubscribe(result, conn)

      {:error, :expired} ->
        send_resp(conn, 200, "")

      {:error, :invalid} ->
        send_resp(conn, 200, "")
    end
  end

  defp maybe_redirect_or_render(conn, delivery) do
    if redirect_path = Mailglass.Config.compliance_redirect() do
      redirect(conn, to: redirect_path)
    else
      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> put_view(html: UnsubscribeHTML)
      |> render(:confirm, recipient: delivery.recipient)
    end
  end

  defp failure(conn, status, message) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, "<!doctype html><html><body>#{message}</body></html>")
  end

  defp resolve_delivery(token) do
    with {:ok, %{delivery_id: delivery_id}} <- Unsubscribe.verify_token(token),
         %Delivery{} = delivery <- fetch_delivery(delivery_id) do
      {:ok, delivery}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid}
    end
  end

  defp fetch_delivery(delivery_id) do
    Tenancy.audit_unscoped_bypass(%{
      reason: :unsubscribe_token_delivery_lookup,
      resource: :delivery
    })

    Repo.get(Delivery, delivery_id, scope: :unscoped)
  end

  defp respond_to_unsubscribe({:ok, _convergence}, conn) do
    send_resp(conn, 200, "")
  end

  defp respond_to_unsubscribe({:error, _reason}, conn) do
    send_resp(conn, 500, "")
  end

  defp run_convergence(delivery) do
    Tenancy.with_tenant(delivery.tenant_id, fn -> UnsubscribeConvergence.run(delivery) end)
  rescue
    exception in [
      Postgrex.Error,
      DBConnection.ConnectionError,
      Ecto.NoResultsError,
      Mailglass.EventLedgerImmutableError
    ] ->
      log_convergence_failure(exception)
      {:error, :convergence_database_failure}
  catch
    :exit, reason ->
      if expected_repo_exit?(reason) do
        log_convergence_failure(:repository_exit)
        {:error, :convergence_database_failure}
      else
        :erlang.raise(:exit, reason, __STACKTRACE__)
      end
  end

  defp maybe_run_post_commit_effects({:ok, %{status: :created, event: event}}, delivery) do
    attrs = %{
      tenant_id: delivery.tenant_id,
      delivery_id: delivery.id,
      event_type: event.type,
      scope: :address_stream,
      stream: delivery.stream
    }

    run_lifecycle_effect(attrs)
    run_broadcast_effect(delivery, attrs)
  end

  defp maybe_run_post_commit_effects(_result, _delivery), do: :ok

  defp run_lifecycle_effect(attrs) do
    lifecycle = Mailglass.Config.compliance_lifecycle()

    with %Ecto.Multi{} = multi <- lifecycle.handle_event(Ecto.Multi.new(), attrs),
         {:ok, _changes} <- Repo.multi(multi) do
      :ok
    else
      %Ecto.Multi{} -> :ok
      invalid -> log_effect_failure(:lifecycle, invalid)
    end
  rescue
    exception -> log_effect_failure(:lifecycle, exception)
  catch
    kind, reason -> log_effect_failure(:lifecycle, {kind, reason})
  end

  defp run_broadcast_effect(delivery, attrs) do
    Projector.broadcast_delivery_updated(delivery, :unsubscribed, attrs)
  rescue
    exception -> log_effect_failure(:broadcast, exception)
  catch
    kind, reason -> log_effect_failure(:broadcast, {kind, reason})
  end

  defp log_effect_failure(effect, reason) do
    Logger.warning(
      "[mailglass] unsubscribe #{effect} effect failed after commit (#{bounded_failure_class(reason)})"
    )

    :ok
  end

  defp log_convergence_failure(reason) do
    Logger.warning("[mailglass] unsubscribe convergence failed (#{bounded_failure_class(reason)})")
  end

  defp bounded_failure_class(%Postgrex.Error{}), do: :postgrex
  defp bounded_failure_class(%DBConnection.ConnectionError{}), do: :connection
  defp bounded_failure_class(%Ecto.NoResultsError{}), do: :not_found
  defp bounded_failure_class(%Mailglass.EventLedgerImmutableError{}), do: :event_immutable
  defp bounded_failure_class(:repository_exit), do: :repository_exit
  defp bounded_failure_class(_), do: :callback_failure

  defp expected_repo_exit?(:timeout), do: true
  defp expected_repo_exit?({:timeout, _}), do: true
  defp expected_repo_exit?({:shutdown, _}), do: true
  defp expected_repo_exit?({:noproc, _}), do: true
  defp expected_repo_exit?(_), do: false
end
