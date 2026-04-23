defmodule Mailglass.Mailable do
  @moduledoc """
  Behaviour + `use` macro for adopter-defined mailable modules (AUTHOR-01).

  ## Usage

      defmodule MyApp.UserMailer do
        use Mailglass.Mailable, stream: :transactional

        def welcome(user) do
          new()
          |> Mailglass.Message.update_swoosh(fn e ->
               e
               |> Swoosh.Email.from({"MyApp", "hello@example.com"})
               |> Swoosh.Email.to(user.email)
               |> Swoosh.Email.subject("Welcome, \#{user.name}!")
               |> Swoosh.Email.text_body("Welcome!")
             end)
          |> Mailglass.Message.put_function(:welcome)
        end
      end

      # Adopter sends:
      user |> MyApp.UserMailer.welcome() |> MyApp.UserMailer.deliver()

  ## `use` opts (D-11 — compile-time tier)

  - `:stream` — `:transactional | :operational | :bulk` (default
    `:transactional`). Compile-time known; Phase 6 LINT-checks read via AST.
  - `:tracking` — `[opens: boolean, clicks: boolean]` (default all false).
    Off by default (TRACK-01 / D-08 project-level). Phase 6
    `TRACK-02 NoTrackingOnAuthStream` enforces at compile time; Phase 3
    `Mailglass.Tracking.Guard.assert_safe!/1` enforces at runtime (D-38).
  - `:from_default` — `{name, address}` tuple for the `from` header. Applied
    at `new/0` time; per-call `Swoosh.Email.from/2` overrides.
  - `:reply_to_default` — same shape as `:from_default` for Reply-To.

  ## Adopter convention (D-10)

  `new/0` returns a `%Mailglass.Message{}`. Use `Mailglass.Message.update_swoosh/2`
  to pipe into Swoosh builder functions and `Mailglass.Message.put_function/2` to
  stamp the `:mailable_function` field (required by D-38 runtime Guard).

  ## Runtime tier (D-11)

  The injected `new/0` returns a `%Mailglass.Message{}`; adopters pipe
  through `Mailglass.Message.update_swoosh/2` and Swoosh builder functions.
  Compile-time opts seed initial values; per-call calls override.

  ## Default `render/3`

  The injected `render/3` is a thin pass-through to `Mailglass.Renderer.render/1`.
  It ignores the `template` and `assigns` arguments — template resolution is an
  adopter-owned concern. Adopters who need template resolution override via
  `defoverridable render: 3`.

  Phase 5 admin preview calls `Mailglass.Renderer.render/1` directly on the
  already-built `%Message{}`; no template resolution happens at render time.

  ## Injection budget (LINT-05, D-09)

  The `__using__/1` macro injects ≤20 top-level AST forms (target: 15). Phase 6
  `NoOversizedUseInjection` enforces; a runtime AST-counting test in this
  phase asserts the budget.

  ## Does NOT inject

  - `Phoenix.Component` — adopters opt in per-mailable by importing it
    themselves. Avoids HEEx collision risk with adopter-defined components.
  - Default `preview_props/0` — optional callback; adopters who want Phase 5
    admin discovery define it themselves.
  - Module attributes like `@subject` or `@from` — compile-time interpolation
    does not work the way adopters expect; the builder-function tier is the
    only correct place (D-11 rationale).

  ## defoverridable surface

  `new/0`, `render/3`, `deliver/2`, `deliver_later/2` — all four injected
  functions are overridable. Adopters who bypass `Mailglass.Outbound` via
  `deliver/2` override lose telemetry + projection writes (T-3-04-04 accepted).

  See `docs/api_stability.md §Mailable` for the locked contract.
  """

  # Mailglass.Outbound is shipped in Plan 05 — suppress undefined-module warnings
  # until then. The injected deliver/2 and deliver_later/2 reference it.
  @compile {:no_warn_undefined, Mailglass.Outbound}

  @type opts :: [
          stream: :transactional | :operational | :bulk,
          tracking: [opens: boolean(), clicks: boolean()],
          from_default: {String.t(), String.t()} | nil,
          reply_to_default: {String.t(), String.t()} | nil
        ]

  # ---------------------------------------------------------------------------
  # Behaviour callbacks (RESEARCH §8.2)
  # ---------------------------------------------------------------------------

  @callback new() :: Mailglass.Message.t()

  @callback render(Mailglass.Message.t(), atom(), map()) ::
              {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t()}

  @callback deliver(Mailglass.Message.t(), keyword()) ::
              {:ok, term()} | {:error, Mailglass.Error.t()}

  @callback deliver_later(Mailglass.Message.t(), keyword()) ::
              {:ok, term()} | {:error, Mailglass.Error.t()}

  @optional_callbacks preview_props: 0
  @callback preview_props() :: [{atom(), map()}]

  # ---------------------------------------------------------------------------
  # __using__/1 macro — ≤20 top-level AST forms (LINT-05 / D-09)
  # ---------------------------------------------------------------------------

  @doc """
  Injects the mailable boilerplate. ≤20 top-level AST forms (LINT-05 enforces
  at Phase 6).
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Mailglass.Mailable
      @before_compile Mailglass.Mailable
      @mailglass_opts opts
      @compile {:no_warn_undefined, Mailglass.Outbound}
      import Swoosh.Email, except: [new: 0]
      import Mailglass.Components

      @doc false
      def __mailglass_opts__, do: @mailglass_opts

      def new, do: Mailglass.Message.new_from_use(__MODULE__, @mailglass_opts)

      def render(msg, _template, _assigns), do: Mailglass.Renderer.render(msg)

      def deliver(msg, opts \\ []), do: Mailglass.Outbound.deliver(msg, opts)

      def deliver_later(msg, opts \\ []), do: Mailglass.Outbound.deliver_later(msg, opts)

      defoverridable new: 0, render: 3, deliver: 2, deliver_later: 2
    end
  end

  # ---------------------------------------------------------------------------
  # @before_compile — Phase 5 admin discovery marker
  # ---------------------------------------------------------------------------

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def __mailglass_mailable__, do: true
    end
  end
end
