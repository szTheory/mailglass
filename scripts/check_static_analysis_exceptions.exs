Code.require_file("static_analysis_exceptions.ex", __DIR__)

Mailglass.Quality.StaticAnalysisExceptions.check!()
IO.puts("OK: static-analysis exceptions are current, owned, expiring, and non-growing.")
