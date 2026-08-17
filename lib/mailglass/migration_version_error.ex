defmodule Mailglass.MigrationVersionError do
  @moduledoc """
  Raised when migration version metadata cannot be trusted.

  A missing package anchor is the only catalog state that represents version
  zero. Query failures and malformed metadata stop migration control flow so a
  caller cannot mistake an unavailable or corrupt database for a fresh install.
  """

  @type reason ::
          :query_failed | :missing_comment | :invalid_comment | :unexpected_result | :out_of_range

  @type t :: %__MODULE__{
          reason: reason(),
          package: :mailglass | :mailglass_inbound,
          prefix: String.t(),
          message: String.t(),
          cause: term()
        }

  defexception [:reason, :package, :prefix, :message, :cause]

  @spec new(reason(), keyword()) :: t()
  def new(reason, opts) do
    package = Keyword.fetch!(opts, :package)
    prefix = Keyword.fetch!(opts, :prefix)

    %__MODULE__{
      reason: reason,
      package: package,
      prefix: prefix,
      cause: opts[:cause],
      message:
        "Cannot determine #{package} migration version for schema #{inspect(prefix)}: " <>
          "#{reason_message(reason)}. Check the package anchor metadata and database connection before retrying."
    }
  end

  defp reason_message(:query_failed), do: "catalog query failed"
  defp reason_message(:missing_comment), do: "package anchor has no version comment"
  defp reason_message(:invalid_comment), do: "package anchor version comment is invalid"
  defp reason_message(:unexpected_result), do: "catalog query returned an unexpected result"
  defp reason_message(:out_of_range), do: "package anchor version is outside the supported range"
end
