defmodule Mailglass.Outbound.Dispatch do
  @moduledoc false

  alias Mailglass.{Message, Telemetry}

  def call_adapter(%Message{} = rendered, {adapter_module, adapter_opts}) do
    Telemetry.dispatch_span(
      %{
        tenant_id: rendered.tenant_id,
        mailable: rendered.mailable,
        provider: adapter_module
      },
      fn -> adapter_module.deliver(rendered, adapter_opts) end
    )
  end
end
