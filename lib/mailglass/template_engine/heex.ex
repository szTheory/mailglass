defmodule Mailglass.TemplateEngine.HEEx do
  @moduledoc """
  Default HEEx template engine for mailglass.

  Renders a pre-compiled Phoenix function component by calling it with the
  provided assigns and converting the result to iodata via `Phoenix.HTML.Safe`.

  ## Usage

  HEEx templates are compiled by the Phoenix tag engine at build time. Callers
  pass the already-compiled function component (a `fn assigns -> ... end` or
  `&MyModule.component/1`) directly to `render/3`. The `compile/2` callback
  returns `{:ok, :heex_native}` for API symmetry.

  ## Error Handling

  - Missing assign (`KeyError`) → `{:error, %Mailglass.TemplateError{type: :missing_assign}}`
  - Argument errors during render → `{:error, %Mailglass.TemplateError{type: :missing_assign}}`
  - Any other runtime error → `{:error, %Mailglass.TemplateError{type: :heex_compile}}`
  - Non-function `compiled` argument → `{:error, %Mailglass.TemplateError{type: :heex_compile}}`
  """

  @behaviour Mailglass.TemplateEngine

  @impl Mailglass.TemplateEngine
  def compile(_source, _opts) do
    # HEEx templates are compiled at build time by the Phoenix tag engine.
    # This callback exists for API symmetry. Runtime callers pass the
    # already-compiled function component directly to render/3.
    {:ok, :heex_native}
  end

  @impl Mailglass.TemplateEngine
  def render(component_fn, assigns, opts \\ [])

  def render(component_fn, assigns, _opts) when is_function(component_fn, 1) and is_map(assigns) do
    try do
      html =
        component_fn
        |> apply([assigns])
        |> Phoenix.HTML.Safe.to_iodata()

      {:ok, html}
    rescue
      e in KeyError ->
        {:error,
         Mailglass.TemplateError.new(:missing_assign,
           cause: e,
           context: %{assign: e.key, assigns: Map.keys(assigns)}
         )}

      e in ArgumentError ->
        {:error,
         Mailglass.TemplateError.new(:missing_assign,
           cause: e,
           context: %{assigns: Map.keys(assigns)}
         )}

      e ->
        {:error,
         Mailglass.TemplateError.new(:heex_compile,
           cause: e,
           context: %{assigns: Map.keys(assigns)}
         )}
    end
  end

  def render(compiled, _assigns, _opts) do
    {:error,
     Mailglass.TemplateError.new(:heex_compile,
       context: %{reason: "expected a function component (fn assigns -> ...), got: #{inspect(compiled)}"}
     )}
  end
end
