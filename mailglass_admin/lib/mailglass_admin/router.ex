defmodule MailglassAdmin.Router do
  @moduledoc """
  Public router macro — stub at Plan 02.

  The `mailglass_admin_routes/2` macro + whitelisted `__session__/2`
  callback land in Phase 5 Plan 03. This module exists as an empty
  placeholder so two invariants hold before Plan 03 ships:

    1. `MailglassAdmin`'s `use Boundary, exports: [Router]` declaration
       compiles cleanly under `--warnings-as-errors`.
    2. The synthetic `MailglassAdmin.TestAdopter.Router` (Plan 01's test
       harness at `test/support/endpoint_case.ex`) can compile — it calls
       `mailglass_admin_routes "/mail"` at module-build time, so the macro
       name must resolve even if it expands to a no-op.

  Plan 03 replaces this file wholesale with the real macro expansion
  (4 asset + 2 LiveView routes, NimbleOptions-validated opts, session
  whitelist callback). Plan 03's RED router tests fail against this stub
  because the stub expands to zero routes — that is the intended RED bar.

  Do NOT add router logic here; the no-op macro is load-bearing.
  """

  @doc """
  Plan 02 no-op stub. Plan 03 replaces this with the real macro.

  Expands to an empty `do` block so the adopter's router compiles but no
  mailglass_admin routes are registered. Plan 03's `router_test.exs`
  asserts the real post-Plan-03 route set — this stub intentionally does
  not satisfy those assertions.
  """
  defmacro mailglass_admin_routes(_path, _opts \\ []) do
    quote do
    end
  end
end
