defmodule Mailglass.Clock.System do
  @moduledoc "Production clock impl. Wraps `DateTime.utc_now/0`."

  @spec utc_now() :: DateTime.t()
  def utc_now, do: DateTime.utc_now()
end
