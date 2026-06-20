defmodule MailglassInbound.MIME do
  @moduledoc """
  Standalone, never-raising RFC 5322 MIME parser.

  `parse/1` turns a canonical raw MIME body into a stable internal
  representation, or returns a structured `MailglassInbound.MIMEError`. It
  **never raises**: the underlying gen_smtp `mimemail` decoder
  escapes through three mechanisms (`erlang:error`, `throw`, and
  `:exit`/`:undef` from iconv), all of which are absorbed by the
  `Mailglass.OptionalDeps.GenSmtp` gateway seam and translated into
  `{:error, %MailglassInbound.MIMEError{}}`.

  ## Contract

      @spec parse(binary()) :: {:ok, repr} | {:error, MailglassInbound.MIMEError.t()}

  - `{:ok, repr}` — `repr` is `%{headers: ..., parts: ..., attachments: ...,
    inline: ...}` (see *Internal representation* below).
  - `{:error, %MIMEError{type: :inbound_mime_invalid}}` — the raw source could
    not be parsed (any of the three escape mechanisms, or the representation
    exceeded `:max_depth`). `:cause` carries the tagged gateway failure;
    `:context` carries `%{byte_size: byte_size(raw)}`.
  - `{:error, %MIMEError{type: :gen_smtp_unavailable}}` — the optional
    `gen_smtp` dependency is not loaded; MIME parsing is unavailable
    (degraded fallback).

  > #### Note {: .info}
  >
  > The `:max_depth` option bounds the depth of the **internal representation
  > walk** — `collect_leaves/3` re-walking the already-decoded tree — and gives
  > a deterministic structured ceiling on what the pipeline iterates. It does
  > **not** limit the underlying `:mimemail` decoder recursion: `decode_and_build/2`
  > calls the decoder *first*, which fully parses to any depth before the guard
  > ever runs. So `:max_depth` does **not** by itself defend against
  > provider-fed deep-nesting (boundary-bomb) DoS.
  >
  > Provider-fed DoS hardening — a real decoder-level recursion limit — is a
  > **this milestone phase** concern that will plug into this same seam. The guard is kept
  > because it is that seam and because it bounds the representation the
  > pipeline iterates.

  ## Internal representation

  `parse/1` returns a map with four keys:

  - `:headers` — the top-level decoded header proplist (`[{binary, binary}]`).
  - `:parts` — a flattened list of non-attachment, non-inline leaf parts. Each
    part is `%{type, subtype, headers, params, body}` where `body` is the raw
    (untranscoded) leaf bytes.
  - `:attachments` — leaf parts whose `Content-Disposition` is `attachment`.
    Each carries a resolved `:filename`
    (`disposition_params["filename"] || content_type_params["name"]`).
  - `:inline` — leaf parts whose `Content-Disposition` is explicitly `inline`
    *and* which carry a filename (typically `Content-ID` images). Inline text
    leaves without a filename land in `:parts`.

  ## Standalone — not wired into any provider path

  This parser is the **producer only** (`the design contract`). It is NOT wired into the
  working JSON-based Postmark/SendGrid normalize paths in this phase. this milestone phase
  (Mailgun/SES raw-MIME ingress) is the first consumer.

  ## Encoding note

  The gateway passes `{:encoding, :none}` to the decoder (gen_smtp does not
  bundle iconv), so leaf `:body` bytes are **not** transcoded to UTF-8. A consumer
  that needs UTF-8 text must transcode using the part's declared charset
  (`content_type_params["charset"]`). Flagged for this milestone phase.
  """

  # Aliased with a distinct root segment (not `GenSmtp`) so the
  # NoBareOptionalDepReference Credo check — which keys on the call-site root
  # alias — recognizes this as a sanctioned gateway call rather than a bare
  # optional-dep reference (mirrors the `OptionalOban` alias idiom in
  # MailglassInbound.Execution).
  alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp
  alias MailglassInbound.MIMEError

  @default_max_depth 100

  @typedoc "A single decoded leaf or container part in the internal representation."
  @type part :: %{
          type: binary(),
          subtype: binary(),
          headers: [{binary(), binary()}],
          params: map(),
          body: term()
        }

  @typedoc "The stable internal representation returned by `parse/1`."
  @type repr :: %{
          headers: [{binary(), binary()}],
          parts: [part()],
          attachments: [part()],
          inline: [part()]
        }

  # Sentinel thrown when the recursion depth guard trips. Caught locally in
  # parse/2 so it never escapes the module (the never-raise contract holds).
  @depth_exceeded :mailglass_inbound_mime_depth_exceeded

  @doc """
  Parses a raw RFC 5322 MIME body. See the moduledoc for the full contract.

  Equivalent to `parse(raw, [])`.
  """
  @doc since: "0.2.0"
  @spec parse(binary()) :: {:ok, repr()} | {:error, MIMEError.t()}
  def parse(raw) when is_binary(raw), do: parse(raw, [])

  @doc """
  Parses a raw RFC 5322 MIME body with options.

  ## Options

  - `:max_depth` — maximum multipart nesting depth before the
    representation-depth guard trips and returns `:inbound_mime_invalid`
    (default `#{@default_max_depth}`). See the moduledoc note on what this
    guard does and does not bound.
  - `:gen_smtp_available?` — overrides the gateway availability check (testing
    seam for the degraded path). Defaults to
    `Mailglass.OptionalDeps.GenSmtp.available?/0`.
  """
  @doc since: "0.2.0"
  @spec parse(binary(), keyword()) :: {:ok, repr()} | {:error, MIMEError.t()}
  def parse(raw, opts) when is_binary(raw) and is_list(opts) do
    available? = Keyword.get(opts, :gen_smtp_available?, OptionalGenSmtp.available?())

    if available? do
      decode_and_build(raw, opts)
    else
      {:error,
       %MIMEError{
         type: :gen_smtp_unavailable,
         message: "gen_smtp optional dependency is not loaded",
         cause: nil,
         context: %{}
       }}
    end
  end

  defp decode_and_build(raw, opts) do
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)

    case OptionalGenSmtp.decode(raw) do
      {:ok, decoded} ->
        try do
          {:ok, to_internal(decoded, max_depth)}
        catch
          :throw, @depth_exceeded ->
            {:error,
             %MIMEError{
               type: :inbound_mime_invalid,
               message: "MIME nesting exceeds the maximum depth (#{max_depth})",
               cause: :max_depth_exceeded,
               context: %{byte_size: byte_size(raw), max_depth: max_depth}
             }}
        end

      {:error, cause} ->
        {:error,
         %MIMEError{
           type: :inbound_mime_invalid,
           message: "MIME parse failed",
           cause: cause,
           context: %{byte_size: byte_size(raw)}
         }}
    end
  end

  # Build the stable representation from the decoded top-level 5-tuple. The
  # top-level headers are surfaced verbatim; leaf parts are flattened and
  # classified into :parts / :attachments / :inline.
  defp to_internal({_type, _subtype, headers, _params, _body} = top, max_depth) do
    leaves = collect_leaves(top, 0, max_depth)
    {attachments, rest} = Enum.split_with(leaves, &attachment?/1)
    {inline, parts} = Enum.split_with(rest, &inline_with_filename?/1)

    %{
      headers: headers,
      parts: parts,
      attachments: attachments,
      inline: inline
    }
    |> Map.update!(:attachments, fn list -> Enum.map(list, &put_filename/1) end)
    |> Map.update!(:inline, fn list -> Enum.map(list, &put_filename/1) end)
  end

  # Depth guard: throw the sentinel (caught in decode_and_build) on overflow.
  defp collect_leaves(_node, depth, max_depth) when depth > max_depth,
    do: throw(@depth_exceeded)

  # multipart: Body is a list of child tuples — recurse one level deeper.
  defp collect_leaves({_t, _st, _h, _p, body}, depth, max_depth) when is_list(body) do
    Enum.flat_map(body, fn child -> collect_leaves(child, depth + 1, max_depth) end)
  end

  # message/rfc822: Body is a single nested tuple — recurse one level deeper.
  defp collect_leaves({_t, _st, _h, _p, body}, depth, max_depth) when is_tuple(body) do
    collect_leaves(body, depth + 1, max_depth)
  end

  # leaf: Body is binary — emit the part record.
  defp collect_leaves({type, subtype, headers, params, body}, _depth, _max_depth)
       when is_binary(body) do
    [%{type: type, subtype: subtype, headers: headers, params: params, body: body}]
  end

  # Defensive: anything else (e.g. nil body) yields no leaves rather than crashing.
  defp collect_leaves(_other, _depth, _max_depth), do: []

  defp attachment?(%{params: params}),
    do: Map.get(params, :disposition) == "attachment"

  defp inline_with_filename?(%{params: params} = part) do
    Map.get(params, :disposition) == "inline" and not is_nil(resolve_filename(part))
  end

  defp put_filename(part), do: Map.put(part, :filename, resolve_filename(part))

  defp resolve_filename(%{params: params}) do
    disposition_params = Map.get(params, :disposition_params, [])
    content_type_params = Map.get(params, :content_type_params, [])

    proplist_get(disposition_params, "filename") ||
      proplist_get(content_type_params, "name")
  end

  defp proplist_get(proplist, key) when is_list(proplist) do
    case List.keyfind(proplist, key, 0) do
      {^key, value} -> value
      _ -> nil
    end
  end

  defp proplist_get(_other, _key), do: nil
end
