defmodule Mailglass.Identifier do
  @moduledoc """
  Validates Postgres unquoted identifiers — the single source of truth for
  schema, prefix, and table-name checks across mailglass.

  A valid identifier is a letter or underscore followed by any combination of
  letters, digits, and underscores, and is at most 63 bytes long (Postgres'
  `NAMEDATALEN` limit — longer names are silently truncated by Postgres, which
  can alias two distinct schemas onto one, so we reject them outright).

  This grammar rejects anything that could be an injection vector — quotes,
  semicolons, whitespace, dashes. Callers with a legitimate need for a quoted
  identifier (mixed case, dashes) should pre-quote and adjust; mailglass does
  not surface such options.

  Validation failures raise `Mailglass.ConfigError` with `type: :invalid`. The
  specific cause lives in `context.key` and `context.reason` — match on the
  struct, never on the message string.
  """

  @doc since: "2.0.0"

  # Postgres unquoted-identifier grammar: letter or underscore, then any
  # combination of letters, digits, and underscores. Rejects anything that
  # could be an injection vector (quotes, semicolons, whitespace, etc.).
  # Callers with a legitimate need for a quoted identifier (mixed case,
  # dashes) should pre-quote and adjust the regex — but at v0.1 we do not
  # surface such options.
  @identifier_regex ~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/

  # Postgres NAMEDATALEN limit: identifiers longer than 63 bytes are silently
  # truncated, which can alias two distinct schemas onto one name.
  @max_identifier_bytes 63

  @doc """
  Validates `value` as a Postgres unquoted identifier, returning it unchanged.

  `key` is the configuration key name surfaced in the raised error's context
  (e.g. `:schema`, `:prefix`).

  Returns the validated string so it can be used pipe-first. Raises
  `Mailglass.ConfigError` with `type: :invalid` when `value` is not a binary,
  exceeds 63 bytes, or does not match the unquoted-identifier grammar.
  """
  @spec validate!(String.t(), atom()) :: String.t()
  def validate!(value, key) when is_binary(value) do
    cond do
      byte_size(value) > @max_identifier_bytes ->
        raise Mailglass.ConfigError.new(:invalid,
                context: %{
                  key: key,
                  reason:
                    "must be at most #{@max_identifier_bytes} bytes " <>
                      "(Postgres NAMEDATALEN limit), got #{byte_size(value)} bytes"
                }
              )

      Regex.match?(@identifier_regex, value) ->
        value

      true ->
        raise Mailglass.ConfigError.new(:invalid,
                context: %{
                  key: key,
                  reason: "must match #{inspect(@identifier_regex)}"
                }
              )
    end
  end

  def validate!(value, key) do
    raise Mailglass.ConfigError.new(:invalid,
            context: %{key: key, reason: "must be a binary, got: #{inspect(value)}"}
          )
  end
end
