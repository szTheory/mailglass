defmodule MailglassDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :mailglass_demo,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      mod: {MailglassDemo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # RATCHET-01 / CONTEXT D-06: the canonical persona cohort spec
  # (`MailglassDemo.Personas`) lives in the shared `../persona_spec` directory
  # so BOTH the demo app and the admin TEST build can compile the single
  # source-of-truth file without a circular path dep (the demo app already
  # depends on `mailglass_admin`, so admin cannot depend back on the whole demo
  # app). The spec is a pure module (core schemas only) — see
  # `reference/persona_spec/personas.ex`.
  @persona_spec_dir Path.expand("../persona_spec", __DIR__)
  defp elixirc_paths(:test), do: ["lib", "test/support", @persona_spec_dir]
  defp elixirc_paths(_), do: ["lib", @persona_spec_dir]

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:bandit, "~> 1.6"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      # Dev-only interactive component review surface (PROJECT D-06). Never
      # ships to adopters: the dep is absent from mailglass_admin's :files glob
      # and is mounted strictly inside the demo router's dev-only /dev scope.
      {:phoenix_storybook, "~> 1.2", only: :dev},
      mailglass_dep(),
      mailglass_admin_dep(),
      mailglass_inbound_dep()
    ]
  end

  # Wide 2.x floor in hex mode on purpose: the exact baseline version is pinned by
  # mix.lock. A major crosses the tilde boundary, so the 2.0 advance is a deliberate
  # coordinated mix.exs + mix.lock edit (D-06).
  defp mailglass_dep do
    if hex_deps?(), do: {:mailglass, "~> 1.0"}, else: {:mailglass, path: "../..", override: true}
  end

  defp mailglass_admin_dep do
    if hex_deps?(),
      do: {:mailglass_admin, "~> 1.0"},
      else: {:mailglass_admin, path: "../../mailglass_admin", override: true}
  end

  defp mailglass_inbound_dep do
    if hex_deps?(),
      do: {:mailglass_inbound, "~> 1.0"},
      else: {:mailglass_inbound, path: "../../mailglass_inbound", override: true}
  end

  defp hex_deps?, do: System.get_env("MAILGLASS_DEMO_DEPS") == "hex"

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm --prefix assets ci --no-audit --no-fund"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "demo.reset": ["run priv/repo/seeds.exs"],
      "demo.e2e": ["cmd npm --prefix assets run test:e2e"]
    ]
  end
end
