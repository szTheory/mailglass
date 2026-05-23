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
      suspicious_fragments: ["reason", "changeset"]
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

      This check flags a response-body sink call whose argument head contains:

        * an `inspect(...)` application,
        * an `%Ecto.Changeset{...}` literal, or
        * a bare error-like variable (name contains `reason`/`changeset`).

      Static map/binary literals (the legitimate closed-code body) do NOT trip it.
      Generic transport variables such as a JSON-encoded `body` binary are NOT
      flagged — the `inspect`/changeset checks catch the real leak vectors.
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

      source_file
      |> SourceFile.ast()
      |> Macro.postwalk([], fn node, issues ->
        {node, maybe_collect_issue(node, issues, issue_meta, response_sinks, suspicious_fragments)}
      end)
      |> elem(1)
      |> Enum.reverse()
    else
      []
    end
  end

  # Bare local-call form: `send_resp(conn, status, body)`.
  defp maybe_collect_issue(
         {sink, meta, args},
         issues,
         issue_meta,
         response_sinks,
         suspicious_fragments
       )
       when is_atom(sink) and is_list(args) do
    collect_if_dangerous(sink, "#{sink}", meta, args, issues, issue_meta, response_sinks, suspicious_fragments)
  end

  # Qualified form: `Plug.Conn.send_resp(conn, status, body)` (any module alias).
  defp maybe_collect_issue(
         {{:., _, [{:__aliases__, _, mod_path}, sink]}, meta, args},
         issues,
         issue_meta,
         response_sinks,
         suspicious_fragments
       )
       when is_atom(sink) and is_list(args) do
    trigger = Enum.map_join(mod_path ++ [sink], ".", &Atom.to_string/1)
    collect_if_dangerous(sink, trigger, meta, args, issues, issue_meta, response_sinks, suspicious_fragments)
  end

  defp maybe_collect_issue(_node, issues, _issue_meta, _response_sinks, _suspicious_fragments),
    do: issues

  defp collect_if_dangerous(sink, trigger, meta, args, issues, issue_meta, response_sinks, suspicious_fragments) do
    if MapSet.member?(response_sinks, sink) and dangerous_body?(args, suspicious_fragments) do
      issue =
        format_issue(
          issue_meta,
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

  defp dangerous_body?(args, suspicious_fragments) do
    Enum.any?(args, fn arg ->
      contains_inspect?(arg) or
        contains_changeset_literal?(arg) or
        contains_bare_error_variable?(arg, suspicious_fragments)
    end)
  end

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
