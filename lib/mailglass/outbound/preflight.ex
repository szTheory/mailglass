defmodule Mailglass.Outbound.Preflight do
  @moduledoc false

  alias Mailglass.{Compliance, Message, RateLimiter, Renderer, Stream, Suppression, Tenancy}
  alias Mailglass.Tracking

  def run(%Message{} = message) do
    with :ok <- Tenancy.assert_stamped!(),
         :ok <- Tracking.Guard.assert_safe!(message),
         :ok <- Suppression.check_before_send(message),
         :ok <- RateLimiter.check(message),
         :ok <- Stream.policy_check(message),
         {:ok, rendered} <- Renderer.render(message) do
      {:ok, prepare(rendered)}
    end
  end

  def prepare(%Message{} = rendered) do
    delivery_id = existing_delivery_id(rendered) || Ecto.UUID.generate()

    rendered
    |> Message.put_metadata(:delivery_id, delivery_id)
    |> Compliance.apply_outbound_headers()
    |> Tracking.rewrite_if_enabled()
  end

  def delivery_id!(%Message{} = message) do
    existing_delivery_id(message) ||
      raise ArgumentError, "delivery_id missing from message metadata before persistence"
  end

  def primary_recipient(%Message{swoosh_email: %Swoosh.Email{to: [{_, address} | _]}}),
    do: String.downcase(address)

  def primary_recipient(%Message{}), do: ""

  defp existing_delivery_id(%Message{metadata: metadata}) when is_map(metadata),
    do: metadata[:delivery_id] || metadata["delivery_id"]

  defp existing_delivery_id(%Message{}), do: nil
end
