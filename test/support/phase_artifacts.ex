defmodule Mailglass.TestSupport.PhaseArtifacts do
  @moduledoc """
  Resolve a v2.7 phase artifact to wherever it physically lives.

  Completing milestone v2.7 MOVES every `.planning/phases/16N-*` directory into
  `.planning/milestones/v2.7-phases/`. The artifacts themselves are byte-identical
  either side of that move, so tests that read them as evidence must follow the move
  rather than go red the moment the milestone they describe is archived — and rather
  than be softened into "skip if missing", which would silently stop proving anything.

  Resolution is deliberately unambiguous: exactly one of the two locations must exist.
  A missing artifact and a duplicated one are both hard failures, because either means
  the archive is in a state no lifecycle step is supposed to produce.
  """

  @archive_root ".planning/milestones/v2.7-phases"

  @doc """
  Absolute path to a v2.7 phase artifact, given `repo_root` and the repo-relative
  *live* path (`.planning/phases/164-.../164-CLOSEOUT.md`).

  Raises when the artifact is absent from both locations or present in both.
  """
  @spec resolve!(binary(), binary()) :: binary()
  def resolve!(repo_root, relative) when is_binary(repo_root) and is_binary(relative) do
    repo_root
    |> candidates(relative)
    |> Enum.filter(&File.exists?/1)
    |> case do
      [path] ->
        path

      [] ->
        raise ArgumentError,
              "v2.7 phase artifact #{relative} is missing from both the live phase " <>
                "directory and the milestone archive"

      many ->
        raise ArgumentError,
              "v2.7 phase artifact #{relative} is ambiguous — present at #{Enum.join(many, " and ")}"
    end
  end

  @doc """
  The repo-relative path that `resolve!/2` selected.

  Use this where a path is handed to a subprocess that resolves it against the
  repository root itself (scripts, git pathspecs) rather than opened directly.
  """
  @spec relative!(binary(), binary()) :: binary()
  def relative!(repo_root, relative) do
    repo_root
    |> resolve!(relative)
    |> Path.relative_to(repo_root)
  end

  @doc "True when v2.7 phase artifacts have been archived out of the live phase tree."
  @spec archived?(binary()) :: boolean()
  def archived?(repo_root) when is_binary(repo_root) do
    repo_root |> Path.join(@archive_root) |> File.dir?()
  end

  @doc "The repo-relative root the v2.7 archive moves phase directories into."
  @spec archive_root() :: binary()
  def archive_root, do: @archive_root

  defp candidates(repo_root, ".planning/phases/" <> rest = relative) do
    [
      Path.join(repo_root, relative),
      Path.join([repo_root, @archive_root, rest])
    ]
  end

  defp candidates(repo_root, relative), do: [Path.join(repo_root, relative)]
end
