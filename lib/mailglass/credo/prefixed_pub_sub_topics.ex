defmodule Mailglass.Credo.PrefixedPubSubTopics do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [required_prefix: "mailglass:"],
    explanations: [
      check: """
      `Phoenix.PubSub` topics used by mailglass must use the `mailglass:`
      namespace prefix.
      """,
      params: [
        required_prefix: "Required topic prefix for literal PubSub topic strings."
      ]
    ]

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    required_prefix = Params.get(params, :required_prefix, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk(&1, &2, ctx, required_prefix), ctx)
    result.issues
  end

  defp walk(
         {{:., _, [{:__aliases__, _, [:Phoenix, :PubSub]}, function_name]}, meta, args} = ast,
         ctx,
         issue_meta,
         required_prefix
       )
       when function_name in [:broadcast, :broadcast!, :subscribe] and is_list(args) do
    topic = topic_arg(function_name, args)

    if is_binary(topic) and not String.starts_with?(topic, required_prefix) do
      issue =
        format_issue(
          issue_meta,
          message: "PubSub topic must start with `#{required_prefix}`.",
          trigger: topic,
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, put_issue(ctx, issue)}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx, _issue_meta, _required_prefix), do: {ast, ctx}

  defp topic_arg(:broadcast, [_pubsub, topic, _payload]), do: topic
  defp topic_arg(:broadcast!, [_pubsub, topic, _payload]), do: topic
  defp topic_arg(:subscribe, [_pubsub, topic]), do: topic
  defp topic_arg(_function_name, _args), do: nil
end
