#!/usr/bin/env bash
# Assert reference/host_app/mix.lock resolves mailglass siblings via :hex source only.
# Run from reference/host_app/ working directory.

set -euo pipefail

LOCK_PATH="${1:-mix.lock}"

if [[ ! -s "$LOCK_PATH" ]]; then
  echo "Clean-baseline Hex-first check blocked: missing or empty $LOCK_PATH" >&2
  exit 1
fi

# The lockfile path is passed via the environment, never interpolated into the
# Elixir source, and -e is single-quoted so the shell performs no expansion on
# it. This stops a path containing shell metacharacters from being executed.
MAILGLASS_LOCK_PATH="$LOCK_PATH" elixir -e '
  defmodule MailglassCleanBaselineLock do
    def read!(lock_path) do
      lock_path
      |> File.read!()
      |> Code.string_to_quoted!(emit_warnings: false)
      |> literal_from_ast!()
    rescue
      error ->
        IO.puts(:stderr, "Clean-baseline Hex-first check blocked: invalid #{lock_path}: #{Exception.message(error)}")
        System.halt(1)
    end

    defp literal_from_ast!({:%{}, _meta, pairs}) when is_list(pairs) do
      Map.new(pairs, fn {key, value} -> {literal_from_ast!(key), literal_from_ast!(value)} end)
    end

    defp literal_from_ast!({:{}, _meta, values}) when is_list(values) do
      values
      |> Enum.map(&literal_from_ast!/1)
      |> List.to_tuple()
    end

    defp literal_from_ast!(values) when is_list(values) do
      Enum.map(values, &literal_from_ast!/1)
    end

    defp literal_from_ast!({key, value}) do
      {literal_from_ast!(key), literal_from_ast!(value)}
    end

    defp literal_from_ast!(value)
         when is_atom(value) or is_binary(value) or is_boolean(value) or is_integer(value) do
      value
    end

    defp literal_from_ast!(other) do
      raise ArgumentError, "unsupported lock literal: #{Macro.to_string(other)}"
    end
  end

  lock_path = System.fetch_env!("MAILGLASS_LOCK_PATH")
  lock = MailglassCleanBaselineLock.read!(lock_path)

  required = ["mailglass", "mailglass_admin", "mailglass_inbound"]

  expected_versions = %{
    "mailglass" => System.get_env("MAILGLASS_EXPECTED_CORE_VERSION"),
    "mailglass_admin" => System.get_env("MAILGLASS_EXPECTED_ADMIN_VERSION"),
    "mailglass_inbound" => System.get_env("MAILGLASS_EXPECTED_INBOUND_VERSION")
  }

  exact_mode? = Enum.any?(expected_versions, fn {_name, version} -> version not in [nil, ""] end)

  if exact_mode? and Enum.any?(expected_versions, fn {_name, version} -> version in [nil, ""] end) do
    IO.puts(:stderr, "Exact Hex lock check requires expected versions for all three packages")
    System.halt(1)
  end

  Enum.each(required, fn name ->
    case Map.get(lock, String.to_atom(name)) do
      tuple when is_tuple(tuple) and tuple_size(tuple) < 8 ->
        IO.puts(:stderr, "Hex-first violation: #{name} lock tuple malformed")
        System.halt(1)
      tuple
      when is_tuple(tuple) and tuple_size(tuple) >= 8 and elem(tuple, 0) == :hex and
             is_binary(elem(tuple, 2)) and elem(tuple, 2) != "" ->
        version = elem(tuple, 2)
        package_checksum = elem(tuple, 3)
        registry_checksum = elem(tuple, 7)

        unless is_binary(package_checksum) and
                 Regex.match?(~r/\A[0-9a-f]{64}\z/, package_checksum) do
          IO.puts(
            :stderr,
            "Hex-first violation: #{name} checksum is not a 64-character lowercase hex digest"
          )

          System.halt(1)
        end

        unless is_binary(registry_checksum) and
                 Regex.match?(~r/\A[0-9a-f]{64}\z/, registry_checksum) do
          IO.puts(
            :stderr,
            "Hex-first violation: #{name} registry checksum is not a 64-character lowercase hex digest"
          )

          System.halt(1)
        end

        if exact_mode? and version != expected_versions[name] do
          IO.puts(
            :stderr,
            "Hex-first violation: #{name} exact version mismatch: expected #{expected_versions[name]}, got #{version}"
          )

          System.halt(1)
        end

        IO.puts(
          "Hex-first OK: #{name} resolved via :hex (version: #{version}; checksums: verified)"
        )
      tuple when is_tuple(tuple) and tuple_size(tuple) > 2 and elem(tuple, 0) == :hex ->
        IO.puts(:stderr, "Hex-first violation: #{name} version is not a well-formed string: #{inspect(elem(tuple, 2))}")
        System.halt(1)
      tuple when is_tuple(tuple) ->
        IO.puts(:stderr, "Hex-first violation: #{name} resolved via #{inspect(elem(tuple, 0))}, expected :hex")
        System.halt(1)
      nil ->
        IO.puts(:stderr, "Hex-first violation: #{name} missing from #{lock_path}")
        System.halt(1)
      other ->
        IO.puts(:stderr, "Hex-first violation: #{name} lock entry has invalid type: #{inspect(other)}")
        System.halt(1)
    end
  end)
'
