ExUnit.start()

# TemplateEngine mock. The behaviour module lands in Plan 06; the guard keeps
# `mix test` runnable through Plans 01..05 before the behaviour exists.
if Code.ensure_loaded?(Mailglass.TemplateEngine) do
  Mox.defmock(Mailglass.MockTemplateEngine, for: Mailglass.TemplateEngine)
end
