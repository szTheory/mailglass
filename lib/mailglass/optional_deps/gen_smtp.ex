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

  - `erlang:error` (caught by `rescue`) — `no_boundary`, `missing_boundary`,
    `missing_last_boundary`, `non_mime_multipart`, `{mime_version, _}`,
    `unterminated_quotes`, `unterminated_comment`. Surfaced as
    `{:error, {:error, exception}}`.
  - `throw` (caught by `catch :throw`) — `bad_content_type`, `bad_disposition`,
    `badchar`. Surfaced as `{:error, {:throw, reason}}`.
  - `:exit`/`:undef` (caught by `catch :exit`) — `iconv:convert/3` when
    `:iconv` is not installed (gen_smtp does not bundle it). Surfaced as
    `{:error, {:exit, reason}}`. This path is a defensive backstop: the
    mandatory `{:encoding, :none}` opt skips iconv entirely.

  A rescue-only wrapper would let the `throw` and `:exit` mechanisms escape,
  so all three are load-bearing for the never-raise contract (`MIME-04`).
  """

  @compile {:no_warn_undefined, [:gen_smtp_client, :mimemail]}

  @doc """
  Returns `true` when `:gen_smtp` (`:gen_smtp_client`) is loaded.
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
