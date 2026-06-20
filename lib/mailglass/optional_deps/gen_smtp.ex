defmodule Mailglass.OptionalDeps.GenSmtp do
  @moduledoc """
  Gateway for the optional gen_smtp dependency (`{:gen_smtp, "~> 1.3"}`).

  Used for SMTP relay ingress in `mailglass_inbound` (v0.5+) and for the raw
  RFC 5322 MIME parse seam (`decode/2`, the producer behind
  `MailglassInbound.MIME.parse/1` from v1.2). Not needed by `mailglass` core
  for outbound — Swoosh handles SMTP transport via its own
  `Swoosh.Adapters.SMTP` which declares `:gen_smtp` as its own optional dep.

  The `:gen_smtp` Hex package is an Erlang library. Two entry points matter
  here: `:gen_smtp_client` (the SMTP client, used for the `available?/0`
  predicate) and `:mimemail` (the MIME parser used by `decode/2`). There is no
  `GenSmtp` Elixir module — `Code.ensure_loaded?/1` accepts Erlang module atoms
  transparently. All `:mimemail` access flows through this gateway; bare
  references elsewhere are forbidden by the `NoBareOptionalDepReference` Credo
  check.

  ## MIME parse seam — never raises

  `:mimemail.decode/2` reaches its callers through **three** escape mechanisms,
  so `decode/2` wraps `try/rescue` AND `catch :throw` AND `catch :exit`:

  - `erlang:error` / `:undef` (caught by `rescue`) — raised errors
    (`no_boundary`, `missing_boundary`, `missing_last_boundary`,
    `non_mime_multipart`, `{mime_version, _}`, `unterminated_quotes`,
    `unterminated_comment`) **and** the `:undef` backstop: if `decode/2` is
    reached without the `available?/0` gate and `:mimemail` is absent, the
    call raises a class-`:error` `UndefinedFunctionError` (`:undef`), which
    `rescue` catches. Surfaced as `{:error, {:error, exception}}`. (The normal
    degraded path returns `:gen_smtp_unavailable` upstream via the availability
    gate before `decode/2` is ever called.)
  - `throw` (caught by `catch :throw`) — `bad_content_type`, `bad_disposition`,
    `badchar`. Surfaced as `{:error, {:throw, reason}}`.
  - `:exit` (caught by `catch :exit`) — the `iconv:convert/3` EXIT signal when
    `:iconv` is not installed (gen_smtp does not bundle it). Surfaced as
    `{:error, {:exit, reason}}`. This path is a defensive backstop: the
    mandatory `{:encoding, :none}` opt skips iconv entirely.

  A rescue-only wrapper would let the `throw` and `:exit` mechanisms escape,
  so all three are load-bearing for the never-raise contract.
  """

  @compile {:no_warn_undefined, [:gen_smtp_client, :mimemail]}

  @doc """
  Returns `true` when `:gen_smtp` (`:gen_smtp_client`) is loaded.

  This probes `:gen_smtp_client` as a PROXY for the `:gen_smtp` package as a
  whole; `:mimemail` (the MIME parser used by `decode/2`) is a distinct module
  from the same Hex package and is NOT probed here. A partial install where
  `:gen_smtp_client` loads but `:mimemail` does not falls through to `decode/2`'s
  `:undef` rescue rather than being caught by this predicate.
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(:gen_smtp_client)

  @doc """
  Decodes a raw RFC 5322 message into the `:mimemail` 5-tuple, never raising.

  Returns `{:ok, {type, subtype, headers, parameters, body}}` on success or a
  tagged `{:error, {kind, reason}}` tuple where `kind` is `:error`, `:throw`,
  or `:exit` (see the moduledoc for the mapping). Callers in
  `mailglass_inbound` translate the error tuple into the public
  `MailglassInbound.MIMEError` contract.

  Two opts are prepended unconditionally and must not be overridden:

  - `{:allow_missing_version, true}` — accept messages without a `MIME-Version`
    header (provider-forwarded payloads frequently omit it).
  - `{:encoding, :none}` — **mandatory**. Skips `iconv` charset transcoding,
    which gen_smtp does not bundle; without it the default path invokes
    `iconv:convert/3` and exits when `:iconv` is absent. Leaf bytes are
    therefore returned untranscoded (not normalized to UTF-8).

  Caller-supplied `opts` are appended after the defaults.
  """
  @doc since: "1.2.0"
  @spec decode(binary(), keyword()) :: {:ok, tuple()} | {:error, term()}
  def decode(raw, opts \\ []) when is_binary(raw) do
    erl_opts = [{:allow_missing_version, true}, {:encoding, :none}] ++ opts
    {:ok, :mimemail.decode(raw, erl_opts)}
  rescue
    e -> {:error, {:error, e}}
  catch
    :throw, reason -> {:error, {:throw, reason}}
    :exit, reason -> {:error, {:exit, reason}}
  end
end
