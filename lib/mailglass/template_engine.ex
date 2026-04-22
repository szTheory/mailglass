defmodule Mailglass.TemplateEngine do
  @moduledoc """
  Behaviour for mailglass template engines.

  The default implementation is `Mailglass.TemplateEngine.HEEx`, which renders
  function components compiled by the Phoenix tag engine at build time.

  To use MJML as an alternate rendering path, add `{:mjml, "~> 5.3"}` to your
  deps and configure:

      config :mailglass, renderer: [engine: Mailglass.TemplateEngine.MJML]

  See AUTHOR-05 in REQUIREMENTS.md. The MJML implementation ships separately
  after the v0.1 release.

  ## Callbacks

  - `compile/2` — compile a template source string to an intermediate form.
    For HEEx, templates are compiled at build time by the Phoenix tag engine;
    this callback exists for API symmetry and returns `{:ok, :heex_native}`.
  - `render/3` — render the compiled form with assigns to HTML iodata.
  """

  @doc "Compile a template source string. Returns an opaque compiled form."
  @callback compile(source :: String.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, Mailglass.TemplateError.t()}

  @doc "Render a compiled template with assigns. Returns HTML iodata."
  @callback render(compiled :: term(), assigns :: map(), opts :: keyword()) ::
              {:ok, iodata()} | {:error, Mailglass.TemplateError.t()}
end
