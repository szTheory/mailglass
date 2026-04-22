defmodule Mailglass.Error do
  @moduledoc """
  Namespace and behaviour for the mailglass error hierarchy.

  Mailglass ships eight sibling `defexception` modules, each with a closed
  `:type` atom set that acts as a sub-kind discriminator. There is no parent
  struct — "hierarchy" here means the shared behaviour contract plus the
  convention that every error struct lives directly under `Mailglass.*`.

  ## Error Types

  - `Mailglass.SendError` — delivery failure (adapter, render, preflight, serialization)
  - `Mailglass.TemplateError` — HEEx compile, missing assign, undefined helper, inliner
  - `Mailglass.SignatureError` — webhook signature missing, malformed, mismatch, stale
  - `Mailglass.SuppressedError` — delivery blocked by suppression list
  - `Mailglass.RateLimitError` — rate limit exceeded (domain, tenant, stream)
  - `Mailglass.ConfigError` — configuration missing, invalid, conflicting, optional-dep absent
  - `Mailglass.EventLedgerImmutableError` — SQLSTATE 45A01 translation (D-06, Phase 2)
  - `Mailglass.TenancyError` — tenant context not stamped on the current process (Phase 2)

  ## Pattern Matching

  Always match on the struct module and `:type` field — never on `:message`.
  Message strings are a presentation concern; the closed `:type` atom set is
  the stable contract:

      case result do
        {:error, %Mailglass.SuppressedError{type: :address}} -> ...
        {:error, %Mailglass.RateLimitError{retry_after_ms: ms}} -> ...
        {:error, %Mailglass.SendError{}} -> ...
      end

  ## Serialization

  Every error struct derives `Jason.Encoder` on `[:type, :message, :context]`
  only. The `:cause` field is deliberately excluded to prevent recursive
  emission of adapter structs that may carry provider payloads with PII.

  ## Closed `:type` Atom Sets

  The closed atom set for each struct is documented in `docs/api_stability.md`
  and asserted by `Mailglass.ErrorTest` against each struct's `__types__/0`.
  Adding a value requires a CHANGELOG entry + `@since` annotation (minor
  version bump). Removing a value requires a major version bump.
  """

  @type t ::
          Mailglass.SendError.t()
          | Mailglass.TemplateError.t()
          | Mailglass.SignatureError.t()
          | Mailglass.SuppressedError.t()
          | Mailglass.RateLimitError.t()
          | Mailglass.ConfigError.t()
          | Mailglass.EventLedgerImmutableError.t()
          | Mailglass.TenancyError.t()

  @doc "Returns the error's closed `:type` atom."
  @callback type(t()) :: atom()

  @doc "Returns true if the error is retryable per mailglass retry policy."
  @callback retryable?(t()) :: boolean()

  @error_modules [
    Mailglass.SendError,
    Mailglass.TemplateError,
    Mailglass.SignatureError,
    Mailglass.SuppressedError,
    Mailglass.RateLimitError,
    Mailglass.ConfigError,
    Mailglass.EventLedgerImmutableError,
    Mailglass.TenancyError
  ]

  @doc """
  Returns `true` when the value is one of the eight mailglass error structs.

  Non-mailglass exceptions (e.g. `%RuntimeError{}`) return `false`.
  """
  @doc since: "0.1.0"
  @spec is_error?(term()) :: boolean()
  def is_error?(%{__struct__: s}) when s in @error_modules, do: true
  def is_error?(_), do: false

  @doc """
  Returns the `:type` atom from any mailglass error struct.

  Convenience helper so callers matching across error kinds can extract
  the discriminator without pattern-matching each struct individually.
  """
  @doc since: "0.1.0"
  @spec kind(t()) :: atom()
  def kind(%{type: type}), do: type

  @doc """
  Returns `true` when the error is retryable per its struct's `retryable?/1`
  callback. Per-struct policy:

  - `Mailglass.SignatureError`, `Mailglass.ConfigError` — always `false`
  - `Mailglass.SuppressedError`, `Mailglass.TemplateError` — always `false`
  - `Mailglass.EventLedgerImmutableError`, `Mailglass.TenancyError` — always `false`
  - `Mailglass.RateLimitError` — always `true` (caller uses `retry_after_ms`)
  - `Mailglass.SendError` — `true` only for `:adapter_failure`

  The inline list is the authoritative contract. `docs/api_stability.md`
  documents the per-struct `Retryable:` line verbatim.
  """
  @doc since: "0.1.0"
  @spec retryable?(t()) :: boolean()
  def retryable?(%{__struct__: s} = err), do: s.retryable?(err)

  @doc """
  Walks the `:cause` chain to the deepest non-nil cause and returns it.

  Returns the input error itself when `:cause` is nil. Terminates on any
  cause that does not have a `:cause` field (e.g. wrapping a `%RuntimeError{}`).
  """
  @doc since: "0.1.0"
  @spec root_cause(t()) :: Exception.t()
  def root_cause(%{cause: nil} = err), do: err
  def root_cause(%{cause: %{cause: _} = cause}), do: root_cause(cause)
  def root_cause(%{cause: cause}) when not is_nil(cause), do: cause
  def root_cause(err), do: err
end
