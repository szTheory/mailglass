defmodule Mailglass.OptionalDeps.Mjml do
  @moduledoc """
  Gateway for the optional MJML NIF dependency (`{:mjml, "~> 5.3"}`).

  `:mjml` is the Hex package name (a Rust NIF binding to the `mrml` crate).
  The Elixir module it provides is `Mjml` — note the `:mjml` vs `:mrml`
  distinction called out in `STACK.md`. Used by `Mailglass.TemplateEngine.MJML`
  when adopters opt into MJML as an alternate rendering path (AUTHOR-05).

  HEEx is the default `Mailglass.TemplateEngine` (D-18 project-level); MJML is
  strictly opt-in. When `:mjml` is absent and an adopter configures the MJML
  engine, `Mailglass.Config.validate_at_boot!/0` raises
  `%Mailglass.ConfigError{type: :optional_dep_missing}`.
  """

  @compile {:no_warn_undefined, [Mjml]}

  @doc """
  Returns `true` when the `:mjml` NIF is loaded.

  The NIF is loaded lazily on first `Mjml` module reference;
  `Code.ensure_loaded?/1` forces the load and returns the resolved state.
  """
  @doc since: "0.1.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Mjml)
end
