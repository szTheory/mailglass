# Installer Fixture Host

This directory is the seed copied by installer integration tests into a temporary
workspace. The helper in `test/support/installer_fixture_helpers.ex` builds the
full throwaway host shape after copy.

Golden snapshots are stored in this file so updates are visible in pull requests.
Refresh both snapshots with:

`MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors`

<!-- GOLDEN_FRESH_START -->
# tree
- .gitignore sha256:aae815b9313ef60fb99d51bec324f3de1cea5256d6bbf58a660578b3e2d5815c
- .mailglass.toml sha256:c018e7b85be2d41b98e0f2979e223bd3db94278e27a236cf08dcc359cb1e203f
- config/runtime.exs sha256:560a8a287211c7b279ebd04181ffb393b1bae00fa2251262a798e7f33c73775d
- lib/example/mail.ex sha256:8d7be0b1a3300a0108b96bbcb796d49b4480030444202a7eb2712e7459057409
- lib/example/mailer/layouts/default.html.heex sha256:e59a3e339319bb49b9136df661f53135a705eb9509c074099e76443d1f6ccf88
- lib/example_web/router.ex sha256:6e094c2be4cc78908773abcb53f5012f9d06ab0b17dd2016367f8c068f07d10f
- mix.exs sha256:bac6a815dfa817a388e07ad7c2325f4ffa993e970f09c2471b61b3dfd8055ddc
- priv/repo/migrations/<MIGRATION_TS>_mailglass_install.exs sha256:fb5ea9dcdef2d6c1724f20e136cfa04ddfb7b9f2c130d6b0e6ce79ecf1eba80d

# files
@@ .gitignore
*
!.gitignore
!README.md


@@ .mailglass.toml
installer_version = "0.1.0"
migration_ts = "<MIGRATION_TS>"
secret = "<SECRET>"


@@ config/runtime.exs
import Config

config :mailglass, secret: "<SECRET>"


@@ lib/example/mail.ex
defmodule Example.Mail do
  @moduledoc false
end


@@ lib/example/mailer/layouts/default.html.heex
<main>
  <%= @inner_content %>
</main>


@@ lib/example_web/router.ex
defmodule ExampleWeb.Router do
  use ExampleWeb, :router

  scope "/", ExampleWeb do
    pipe_through :browser
  end

  # mailglass:start preview_route
  forward "/dev/mailglass", MailglassAdmin.Router
  # mailglass:end preview_route
end


@@ mix.exs
defmodule Example.MixProject do
  use Mix.Project

  def project do
    [app: :example, version: "0.1.0", elixir: "~> 1.18"]
  end
end


@@ priv/repo/migrations/<MIGRATION_TS>_mailglass_install.exs
defmodule Example.Repo.Migrations.MailglassInstall do
  use Ecto.Migration

  def change do
    create table(:mailglass_events) do
      add :tenant_id, :string
      timestamps(type: :utc_datetime_usec)
    end
  end
end


<!-- GOLDEN_FRESH_END -->

<!-- GOLDEN_NO_ADMIN_START -->
# tree
- .gitignore sha256:aae815b9313ef60fb99d51bec324f3de1cea5256d6bbf58a660578b3e2d5815c
- .mailglass.toml sha256:c018e7b85be2d41b98e0f2979e223bd3db94278e27a236cf08dcc359cb1e203f
- config/runtime.exs sha256:560a8a287211c7b279ebd04181ffb393b1bae00fa2251262a798e7f33c73775d
- lib/example/mail.ex sha256:8d7be0b1a3300a0108b96bbcb796d49b4480030444202a7eb2712e7459057409
- lib/example_web/router.ex sha256:68fe87184af413a0826a445d5eadbd895962b12efc792cfa2f64231534e1d1a4
- mix.exs sha256:bac6a815dfa817a388e07ad7c2325f4ffa993e970f09c2471b61b3dfd8055ddc
- priv/repo/migrations/<MIGRATION_TS>_mailglass_install.exs sha256:fb5ea9dcdef2d6c1724f20e136cfa04ddfb7b9f2c130d6b0e6ce79ecf1eba80d

# files
@@ .gitignore
*
!.gitignore
!README.md


@@ .mailglass.toml
installer_version = "0.1.0"
migration_ts = "<MIGRATION_TS>"
secret = "<SECRET>"


@@ config/runtime.exs
import Config

config :mailglass, secret: "<SECRET>"


@@ lib/example/mail.ex
defmodule Example.Mail do
  @moduledoc false
end


@@ lib/example_web/router.ex
defmodule ExampleWeb.Router do
  use ExampleWeb, :router

  scope "/", ExampleWeb do
    pipe_through :browser
  end
end


@@ mix.exs
defmodule Example.MixProject do
  use Mix.Project

  def project do
    [app: :example, version: "0.1.0", elixir: "~> 1.18"]
  end
end


@@ priv/repo/migrations/<MIGRATION_TS>_mailglass_install.exs
defmodule Example.Repo.Migrations.MailglassInstall do
  use Ecto.Migration

  def change do
    create table(:mailglass_events) do
      add :tenant_id, :string
      timestamps(type: :utc_datetime_usec)
    end
  end
end


<!-- GOLDEN_NO_ADMIN_END -->
