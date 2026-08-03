#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temp_root=$(mktemp -d "${TMPDIR:-/tmp}/mailglass-no-optional.XXXXXX")
build_root="$temp_root/build"
run_root="$temp_root/run"
denylist="$temp_root/optional-apps"
manifest="$temp_root/ebins"
probe="$repo_root/test/runtime/no_optional_deps_public_send.exs"

cleanup() {
  rm -rf "$temp_root"
}
trap cleanup EXIT INT TERM

[[ -f "$probe" ]] || { echo "missing runtime probe: $probe" >&2; exit 1; }
mkdir -p "$build_root/lib" "$run_root"
build_root=$(cd "$build_root" && pwd -P)
run_root=$(cd "$run_root" && pwd -P)

# This controller invocation reads the source-controlled dependency declaration.
# It is deliberately separate from the proof process, which launches Elixir directly.
cd "$repo_root"
MIX_ENV=test mix run --no-start -e '
  Mailglass.MixProject.project()[:deps]
  |> Enum.filter(fn
    {_app, _requirement, opts} when is_list(opts) -> Keyword.get(opts, :optional, false)
    {_app, opts} when is_list(opts) -> Keyword.get(opts, :optional, false)
    _ -> false
  end)
  |> Enum.map(fn {app, _rest} -> app; {app, _requirement, _opts} -> app end)
  |> Enum.map(&Atom.to_string/1)
  |> Enum.sort()
  |> Enum.each(&IO.puts/1)
' > "$denylist"

[[ -s "$denylist" ]] || { echo "optional dependency denylist was empty" >&2; exit 1; }
grep -qx 'oban' "$denylist" || { echo "optional dependency denylist omitted oban" >&2; exit 1; }

# Reuse only required production dependency artifacts under the temporary root.
# This preserves dependency-owned compile-time assets (for example Premailex's
# entities file) while Mailglass itself is separately compiled there. The direct
# proof process still sees only this temporary manifest, never normal build paths.
for source_app in "$repo_root"/_build/prod/lib/*; do
  [[ -d "$source_app" ]] || continue
  app=$(basename "$source_app")
  grep -qx "$app" "$denylist" && continue
  [[ "$app" == "mailglass" ]] && continue
  cp -R "$source_app" "$build_root/lib/$app"
done

MIX_ENV=prod MIX_BUILD_PATH="$build_root" mix compile --no-optional-deps --warnings-as-errors

artifact_root="$build_root"
artifact_lib="$artifact_root/lib"
[[ -d "$artifact_lib" ]] || { echo "isolated artifact has no lib directory: $artifact_lib" >&2; exit 1; }

while IFS= read -r app; do
  if [[ -d "$artifact_lib/$app" ]]; then
    echo "isolated artifact includes optional application root: $app" >&2
    exit 1
  fi
done < "$denylist"

: > "$manifest"
while IFS= read -r -d '' ebin; do
  resolved=$(cd "$ebin" && pwd -P)
  case "$resolved" in
    "$artifact_root"/*) ;;
    *) echo "isolated ebin escapes build root: $resolved" >&2; exit 1 ;;
  esac
  printf '%s\n' "$resolved" >> "$manifest"
done < <(find "$artifact_lib" -mindepth 2 -maxdepth 2 -type d -name ebin -print0 | sort -z)

[[ -s "$manifest" ]] || { echo "isolated artifact ebin manifest was empty" >&2; exit 1; }

launcher_args=()
while IFS= read -r ebin; do
  launcher_args+=(-pa "$ebin")
done < "$manifest"

cd "$run_root"
env -u ERL_LIBS -u ERL_AFLAGS -u ERL_FLAGS -u ELIXIR_ERL_OPTIONS -u MIX_BUILD_PATH -u MIX_DEPS_PATH \
  MAILGLASS_NO_OPTIONAL_BUILD_ROOT="$artifact_root" \
  MAILGLASS_NO_OPTIONAL_REPO_ROOT="$repo_root" \
  MAILGLASS_NO_OPTIONAL_EBINS="$(paste -sd: "$manifest")" \
  MAILGLASS_NO_OPTIONAL_APPS="$(paste -sd, "$denylist")" \
  elixir "${launcher_args[@]}" "$probe"
