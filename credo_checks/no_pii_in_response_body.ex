defmodule Mailglass.Credo.NoPiiInResponseBody do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      included_path_prefixes: [
        "lib/mailglass/webhook/",
        "mailglass_inbound/lib/mailglass_inbound/ingress/"
      ],
      response_sinks: [:send_resp, :send_json, :put_resp_body],
      # Error-specific name fragments only. Deliberately NOT "body"/"resp"/
      # "payload": those are generic transport names used by legitimate JSON
      # encoders (e.g. `body = Jason.encode!(payload); send_resp(status, body)`),
      # and flagging a bare encoded-binary var would false-positive the safe
      # helper. The genuine leak vectors — `inspect(...)` and `%Ecto.Changeset{}`
      # literals — are caught structurally regardless of variable name; this
      # fragment list adds the bare error-term-variable case on top of that.
      #
      # "err" is layered on (Option A): the fragment is matched as a SUBSTRING of
      # the variable name (`String.contains?(var_name, fragment)`), so "err"
      # matches both `err` and `error`. This catches an error/changeset term
      # bound to a differently-named variable and used as a FIELD inside an
      # inline body map — `%{detail: err}` (WR-02) — not only `reason`/
      # `changeset`-named vars. The mandated bare-variable body-arg rule (Option
      # B, see `bare_body_variable_leak?/4`) handles the case where such a var is
      # the body arg directly, plus WR-03's two-step `payload` body var which no
      # fragment name can reach. Do NOT add a bare "e" substring (it matches
      # nearly every identifier).
      suspicious_fragments: ["reason", "changeset", "err"]
    ],
    explanations: [
      check: """
      Do not place provider/error payloads in HTTP response bodies on the webhook +
      inbound-ingress egress surfaces.

      "No PII on egress" must hold on the RESPONSE PATH, not only in logs and
      telemetry. A persist failure typically returns an `%Ecto.Changeset{}` whose
      `changes` carry recipient PII (subject/from/to/cc/bcc/reply_to/text/html
      bodies). Interpolating that via `inspect(reason)` into a `send_resp`/
      `send_json`/`put_resp_body` body leaks recipient email contents to the
      provider on a transient error.

      Return a static closed code instead — e.g.
      `send_json(conn, 500, %{status: "error", reason: "persist_failed"})` — and
      route any debuggable detail to the telemetry stop-metadata as a PII-free
      classified atom (the full-fidelity record already lives in the committed
      tenant-scoped evidence row).

      This check flags a response-body sink call when:

        * any argument contains an `inspect(...)` application,
        * any argument contains an `%Ecto.Changeset{...}` literal,
        * any argument contains a bare error-like variable whose name contains
          `reason`/`changeset`/`err` (so `err`/`error` used as an inline body
          field — `%{detail: err}` — is caught, not only `reason`-named vars), OR
        * the BODY-POSITION argument (the last positional arg of `send_resp`/
          `send_json`/`put_resp_body`) is a BARE LOCAL VARIABLE that is not the
          documented-safe Jason-encoded `body` carve-out.

      The bare-variable body-arg rule is what catches a payload assembled in a
      prior assignment and passed bare to the sink — e.g.
      `payload = %{detail: inspect(changeset)}; send_json(conn, 500, payload)`.
      A static map/binary literal is not a bare variable, so the legitimate
      closed-code body does NOT trip it, and a `body = Jason.encode!(payload)`
      binary is carved out so the JSON encoder helper stays clean.

      ## Boundary (still out of scope)

      The guard analyzes the sink-call arguments plus the body-position variable.
      It does NOT perform full intra-function dataflow across multiple hops: a
      payload assembled across several prior assignments and then transformed
      before the sink call — so the body arg is neither a bare error-named
      variable nor a directly-passed error/`inspect`/changeset term — can still
      escape. True multi-hop intra-function dataflow tracking is out of scope;
      keep the body-position arg a literal closed code or a Jason-encoded binary
      and route detail to telemetry, and this guard holds.
      """,
      params: [
        included_path_prefixes:
          "Only files in these path prefixes are linted (the webhook + ingress egress surfaces).",
        response_sinks: "Response-body call heads to inspect.",
        suspicious_fragments: "Variable-name fragments treated as error/payload hints."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      response_sinks = params |> Params.get(:response_sinks, __MODULE__) |> MapSet.new()
      suspicious_fragments = Params.get(params, :suspicious_fragments, __MODULE__)

      ast = SourceFile.ast(source_file)

      # The carve-out set: variable names bound to `Jason.encode!(...)` /
      # `Jason.encode(...)` anywhere in the file. A bare body-position variable
      # whose name is in this set is the documented-safe encoded-binary shape
      # (`body = Jason.encode!(payload); send_resp(conn, status, body)`) and is
      # NOT flagged by the bare-variable rule. Collected once over the whole AST.
      jason_encoded_vars = collect_jason_encoded_vars(ast)

      # Function-definition head signatures (`{name, line}`) for any `def`/`defp`
      # whose name collides with a response sink (e.g. `def send_json(conn,
      # status, payload)`). The head node is call-shaped, so the postwalk would
      # otherwise mistake it for a sink CALL with a bare-variable body arg. We
      # exclude these so the bare-variable rule only fires on real call sites.
      def_head_sigs = collect_def_head_sigs(ast, response_sinks)

      ctx = %{
        issue_meta: issue_meta,
        response_sinks: response_sinks,
        suspicious_fragments: suspicious_fragments,
        jason_encoded_vars: jason_encoded_vars,
        def_head_sigs: def_head_sigs
      }

      ast
      |> Macro.postwalk([], fn node, issues ->
        {node, maybe_collect_issue(node, issues, ctx)}
      end)
      |> elem(1)
      |> Enum.reverse()
    else
      []
    end
  end

  # Bare local-call form: `send_resp(conn, status, body)`.
  defp maybe_collect_issue({sink, meta, args}, issues, ctx)
       when is_atom(sink) and is_list(args) do
    collect_if_dangerous(sink, "#{sink}", meta, args, issues, ctx)
  end

  # Qualified form: `Plug.Conn.send_resp(conn, status, body)` (any module alias).
  defp maybe_collect_issue(
         {{:., _, [{:__aliases__, _, mod_path}, sink]}, meta, args},
         issues,
         ctx
       )
       when is_atom(sink) and is_list(args) do
    trigger = Enum.map_join(mod_path ++ [sink], ".", &Atom.to_string/1)
    collect_if_dangerous(sink, trigger, meta, args, issues, ctx)
  end

  defp maybe_collect_issue(_node, issues, _ctx), do: issues

  defp collect_if_dangerous(sink, trigger, meta, args, issues, ctx) do
    if MapSet.member?(ctx.response_sinks, sink) and dangerous_body?(sink, meta, args, ctx) do
      issue =
        format_issue(
          ctx.issue_meta,
          message:
            "Do not place inspect/changeset/error payloads in response bodies via " <>
              "`#{trigger}` — return a static closed code (e.g. " <>
              "%{status: \"error\", reason: \"persist_failed\"}) and route detail to telemetry.",
          trigger: trigger,
          line_no: meta[:line],
          column: meta[:column]
        )

      [issue | issues]
    else
      issues
    end
  end

  defp dangerous_body?(sink, meta, args, ctx) do
    # The body-position arg is the LAST positional arg of the sink call
    # (`send_resp(conn, status, body)` / `send_json(conn, status, body)` /
    # `put_resp_body(conn, body)`). The MANDATED bare-variable rule treats that
    # arg as suspicious when it is a bare local variable, EXCEPT the carved-out
    # Jason-encoded `body` binary. This is what catches WR-03's two-step
    # `payload` body var (assembled in a prior `=` and passed bare) and an error
    # term passed directly as the body arg (WR-02). The existing structural and
    # fragment-name checks still apply to any arg.
    bare_body_variable_leak?(sink, meta, args, ctx) or
      Enum.any?(args, fn arg ->
        contains_inspect?(arg) or
          contains_changeset_literal?(arg) or
          contains_bare_error_variable?(arg, ctx.suspicious_fragments)
      end)
  end

  # MANDATED bare-variable body-arg rule (Option B). The last positional arg is
  # the response body. If it is a bare local variable that is NOT a Jason-encoded
  # carve-out var, it is suspicious — a static map/binary literal is not a bare
  # variable, so the legitimate closed-code body stays clean. Function-definition
  # heads that share a sink's name (e.g. `def send_json(conn, status, payload)`)
  # are call-shaped but are NOT call sites, so they are excluded.
  defp bare_body_variable_leak?(sink, meta, args, ctx)
       when is_list(args) and args != [] do
    if def_head?(sink, meta, ctx.def_head_sigs) do
      false
    else
      case List.last(args) do
        {name, _meta, context}
        when is_atom(name) and (is_atom(context) or is_nil(context)) ->
          not MapSet.member?(ctx.jason_encoded_vars, name)

        _other ->
          false
      end
    end
  end

  defp bare_body_variable_leak?(_sink, _meta, _args, _ctx), do: false

  defp def_head?(sink, meta, def_head_sigs) do
    MapSet.member?(def_head_sigs, {sink, meta[:line]})
  end

  # Collect variable names bound to `Jason.encode!/encode` (the documented-safe
  # encoded-binary carve-out). Matches both `var = Jason.encode!(payload)` and
  # the qualified `var = Jason.encode(payload)` (and bare `encode!`/`encode`).
  defp collect_jason_encoded_vars(ast) do
    ast
    |> Macro.prewalk(MapSet.new(), fn
      {:=, _, [{name, _, context}, rhs]} = node, acc
      when is_atom(name) and (is_atom(context) or is_nil(context)) ->
        if jason_encode_call?(rhs), do: {node, MapSet.put(acc, name)}, else: {node, acc}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp jason_encode_call?({{:., _, [{:__aliases__, _, mod_path}, fun]}, _, [_ | _]})
       when fun in [:encode!, :encode] do
    List.last(mod_path) == :Jason
  end

  defp jason_encode_call?({fun, _, [_ | _]}) when fun in [:encode!, :encode], do: true

  defp jason_encode_call?(_), do: false

  # Collect `{name, line}` signatures of `def`/`defp` heads whose name is a
  # response sink. A function head such as `def send_json(conn, status, payload)`
  # is structurally identical to a sink call, so we record its name+line to
  # exclude it from the bare-variable rule (it is a definition, not a call).
  defp collect_def_head_sigs(ast, response_sinks) do
    ast
    |> Macro.prewalk(MapSet.new(), fn
      {def_kw, _, [head | _]} = node, acc when def_kw in [:def, :defp] ->
        {node, maybe_put_def_head(head, response_sinks, acc)}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  # Unwrap a guarded head `when` to reach the call-shaped head.
  defp maybe_put_def_head({:when, _, [head | _]}, response_sinks, acc),
    do: maybe_put_def_head(head, response_sinks, acc)

  defp maybe_put_def_head({name, meta, args}, response_sinks, acc)
       when is_atom(name) and is_list(args) do
    if MapSet.member?(response_sinks, name) do
      MapSet.put(acc, {name, meta[:line]})
    else
      acc
    end
  end

  defp maybe_put_def_head(_head, _response_sinks, acc), do: acc

  defp contains_inspect?(ast) do
    ast
    |> Macro.prewalk(false, fn
      {:inspect, _, [_ | _]} = node, acc ->
        {node, acc or true}

      {{:., _, [{:__aliases__, _, [:Kernel]}, :inspect]}, _, [_ | _]} = node, acc ->
        {node, acc or true}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp contains_changeset_literal?(ast) do
    ast
    |> Macro.prewalk(false, fn
      {:%, _, [{:__aliases__, _, mod_path}, _fields]} = node, acc ->
        {node, acc or changeset_alias?(mod_path)}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp changeset_alias?(mod_path) when is_list(mod_path) do
    List.last(mod_path) == :Changeset
  end

  defp changeset_alias?(_), do: false

  defp contains_bare_error_variable?(ast, suspicious_fragments) do
    ast
    |> Macro.prewalk(false, fn
      {name, _, context} = node, acc when is_atom(name) and (is_atom(context) or is_nil(context)) ->
        var_name = name |> Atom.to_string() |> String.downcase()

        flagged =
          Enum.any?(suspicious_fragments, fn fragment ->
            String.contains?(var_name, String.downcase(fragment))
          end)

        {node, acc or flagged}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp included_path?(%SourceFile{filename: filename}, prefixes) when is_binary(filename) do
    Enum.any?(prefixes, &String.starts_with?(filename, &1))
  end

  defp included_path?(_source_file, _prefixes), do: false
end
