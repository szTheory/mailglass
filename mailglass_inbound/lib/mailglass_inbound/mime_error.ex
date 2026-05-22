defmodule MailglassInbound.MIMEError do
  @moduledoc """
  Structured error for raw RFC 5322 MIME parse failures (`MailglassInbound.MIME`).

  Mirrors the shape of `Mailglass.ConfigError` — a closed `:type` atom set, a
  `[:type, :message, :cause, :context]` `defexception`, and a `Jason.Encoder`
  derivation that **excludes `:cause`** so raw payload fragments never leak into
  serialized output (logs, telemetry, admin). Match on the struct and `:type`,
  never on the message string.

  This struct is **package-local**: it does NOT implement the core
  `Mailglass.Error` behaviour and does NOT join `Mailglass.Error`'s `@type`
  union (that behaviour and union live in `mailglass` core). It is a plain
  `defexception` with a `__types__/0` contract helper.

  ## Types

  - `:inbound_mime_invalid` — the raw MIME source could not be parsed into a
    canonical internal representation. `:cause` carries the tagged gateway
    failure (`{:error, _}` / `{:throw, _}` / `{:exit, _}`); `:context` carries
    non-PII metadata such as `%{byte_size: n}`.
  - `:gen_smtp_unavailable` — the optional `gen_smtp` dependency is not loaded,
    so MIME parsing is unavailable (degraded fallback, MIME-02).

  See `docs/api_stability.md` for the locked `:type` atom set. Adding a value
  requires a CHANGELOG entry + `@since` annotation (minor version bump);
  removing a value requires a major version bump.
  """

  @types [:inbound_mime_invalid, :gen_smtp_unavailable]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :inbound_mime_invalid | :gen_smtp_unavailable,
          message: String.t(),
          cause: term() | nil,
          context: map()
        }

  @doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
  @doc since: "0.2.0"
  def __types__, do: @types

  @impl true
  def message(%__MODULE__{message: m}), do: m
end
