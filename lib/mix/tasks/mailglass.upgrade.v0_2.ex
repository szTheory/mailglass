# credo:disable-for-this-file Credo.Check.Readability.ModuleNames

# Compile-guarded on Igniter so a fresh `mix mailglass.install` stays
# HTTP-client-agnostic: Igniter is an optional dep (it pulls req/finch/mint),
# so consumers who don't run this codemod never compile this module. Mirrors
# the `Mailglass.Oban.TenancyMiddleware` Oban guard. When Igniter is absent the
# whole task (including its Sourceror/Igniter references) is elided, keeping the
# `mix compile --no-optional-deps --warnings-as-errors` lane green.
if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.Mailglass.Upgrade.V0_2 do
    use Boundary, classify_to: Mailglass

    @migration_guide_url "https://hexdocs.pm/mailglass/guides/upgrading-to-v1_0.html"

    @shortdoc "Transitional codemod for the Mailglass.Message setter upgrade path"

    @moduledoc """
    Transitional codemod that upgrades adopter code from raw `Swoosh.Email`
    usage to native `Mailglass.Message` setters.

    Use this task as one step in the canonical `0.x -> 1.0` migration path, not
    as the whole compatibility contract by itself. The authoritative guide lives
    at `guides/upgrading-to-v1_0.md`.

    ## Options

      * `--apply` - actually apply the changes to the files. Default is a dry-run.
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        schema: [apply: :boolean],
        aliases: [a: :apply]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # Force dry-run if --apply is not passed
      igniter =
        if igniter.args.options[:apply] do
          igniter
        else
          Igniter.assign(igniter, :dry_run?, true)
        end

      Igniter.update_all_elixir_files(igniter, &upgrade_swoosh_calls/1)
    end

    defp upgrade_swoosh_calls(zipper) do
      pred = fn z ->
        node = Sourceror.Zipper.node(z)
        # Skip strings
        if Igniter.Code.String.string?(z) do
          false
        else
          case node do
            {{:., _, [{:__aliases__, _, [:Swoosh, :Email]}, fun]}, _, _} when is_atom(fun) -> true
            _ -> false
          end
        end
      end

      fun = fn z ->
        node = Sourceror.Zipper.node(z)
        {{:., meta1, [{:__aliases__, _meta2, [:Swoosh, :Email]}, function_name]}, _meta3, args} = node

        new_node =
          case function_name do
            f when f in [:to, :from, :subject, :text_body, :html_body, :header, :put_tag] ->
              {f, meta1, args}

            :attachment ->
              {:attach, meta1, args}

            _ ->
              IO.warn(
                "Skipping unknown Swoosh.Email function: #{function_name}/#{length(args || [])}. " <>
                  "Review #{@migration_guide_url} for ambiguous-case migration guidance and " <>
                  "the Mailglass.Message.update_swoosh/2 escape hatch."
              )

              node
          end

        {:ok, Sourceror.Zipper.replace(z, new_node)}
      end

      case Igniter.Code.Common.update_all_matches(zipper, pred, fun) do
        {:ok, new_zipper} -> {:ok, new_zipper}
        :error -> {:ok, zipper}
      end
    end
  end
end
