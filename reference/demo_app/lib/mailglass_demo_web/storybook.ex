defmodule MailglassDemoWeb.Storybook do
  @moduledoc """
  Dev-only PhoenixStorybook backend for the mailglass_admin component review surface.

  Hand-written per PROJECT D-07 — `mix phx.gen.storybook` is deliberately NOT run
  because the default scaffold introduces a `storybook.css`/`storybook.js` esbuild
  watcher build path. This phase reuses the already-served committed admin bundle as
  the sandbox stylesheet instead, so the zero-Node adopter guarantee and the
  `priv/static/app.css` drift gate (`mix verify.preview`) are both preserved.

  ## Sandbox styling (D-07)

  `css_path` is a REMOTE URL string — the absolute path of the served committed admin
  bundle route, `/dev/mail/css-<md5>`. PhoenixStorybook emits it as a plain `<link>` in
  the sandbox iframe; it is NOT a filesystem path and NOT a new asset build. The md5 is
  resolved at compile time from `MailglassAdmin.Controllers.Assets.css_hash/0` (the same
  hash the live admin layout uses), so the URL cache-busts whenever the bundle changes.

  `sandbox_class: "mg-admin-root"` matches the class the admin shell roots carry
  (`operator/shell.ex`, `preview_live.ex`), so component CSS scoped under `.mg-admin-root`
  resolves inside the explorer. The `data-theme` the components key off
  (`mailglass-light`/`mailglass-dark`) is set per-variation at the story template level
  (D-08) — never via a CSS class→data-theme alias, which would trip TokenParityTest.

  `js_path` is intentionally OMITTED (D-07): stories are static markup, so no esbuild
  watcher is added to `config/dev.exs`.

  This module and every `*.story.exs` live in the DEMO app, never under
  `mailglass_admin/lib/` (D-06) — the admin package's `:files` glob would otherwise
  tarball them to adopters and break their compile, since `phoenix_storybook` is a
  dev-only dep absent from the shipped package.
  """
  use PhoenixStorybook,
    otp_app: :mailglass_demo,
    content_path: Path.expand("../../storybook", __DIR__),
    # Remote URL of the served committed admin bundle (D-07). NOT a filesystem path.
    css_path: "/dev/mail/css-" <> MailglassAdmin.Controllers.Assets.css_hash(),
    # js_path OMITTED on purpose (D-07) — static stories, no esbuild watcher.
    sandbox_class: "mg-admin-root",
    title: "mailglass admin"
end
