#!/usr/bin/env bash
set -euo pipefail

registry="${TEST_EXCEPTIONS_REGISTRY:-config/test_exceptions.exs}"

test -f "$registry" || { echo "missing exception registry: $registry" >&2; exit 1; }

registry_sources="$(elixir -e '
  {registry, _} = Code.eval_file(System.argv() |> hd())
  today = Date.utc_today()
  Enum.each(registry.exceptions, fn entry ->
    for key <- [:source, :kind, :owner, :reason, :expires_on, :category], not Map.has_key?(entry, key),
      do: raise("missing #{key} in #{inspect(entry)}")
    if entry.expires_on < today, do: raise("expired test exception: #{entry.source}")
    IO.puts(entry.source)
  end)
' "$registry" | sort)"

found_sources="$(rg -n '^[[:space:]]*@tag :(skip|flaky)|Process\.sleep\(|pg_sleep\(' test/mailglass mailglass_inbound/test | sed -E 's/^([^:]+:[0-9]+):.*/\1/' | sort)"

test "$registry_sources" = "$found_sources" || {
  echo "test exception registry drift" >&2
  diff -u <(printf '%s\n' "$registry_sources") <(printf '%s\n' "$found_sources") >&2 || true
  exit 1
}

echo "OK: test exception registry is complete and unexpired."
