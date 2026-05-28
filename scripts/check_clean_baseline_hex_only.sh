#!/usr/bin/env bash
# Assert reference/host_app/mix.lock resolves mailglass siblings via :hex source only.
# Run from reference/host_app/ working directory.

set -euo pipefail

LOCK_PATH="${1:-mix.lock}"

if [[ ! -s "$LOCK_PATH" ]]; then
  echo "Clean-baseline Hex-first check blocked: missing or empty $LOCK_PATH" >&2
  exit 1
fi

elixir -e "
  lock = File.read!(\"$LOCK_PATH\") |> Code.eval_string() |> elem(0)

  required = [
    {\"mailglass\", :hex},
    {\"mailglass_admin\", :hex},
    {\"mailglass_inbound\", :hex}
  ]

  Enum.each(required, fn {name, expected_source} ->
    case Map.get(lock, String.to_atom(name)) do
      tuple when is_tuple(tuple) and elem(tuple, 0) == expected_source ->
        IO.puts(\"Hex-first OK: #{name} resolved via :hex (version: #{elem(tuple, 2)})\")
      tuple when is_tuple(tuple) ->
        IO.puts(:stderr, \"Hex-first violation: #{name} resolved via #{inspect(elem(tuple, 0))}, expected :hex\")
        System.halt(1)
      nil ->
        IO.puts(:stderr, \"Hex-first violation: #{name} missing from #{\"$LOCK_PATH\"}\")
        System.halt(1)
    end
  end)
"
