defmodule Storybook.Foundations do
  @moduledoc false
  # Foundations page — orients a reviewer before walking the primitives.
  # A `:page` story renders custom markup (no component function), so it is the
  # right vehicle for documenting the sandbox + theme-bridge contract this
  # storybook stands up (PROJECT D-07/D-08). It carries no theme wrapper itself
  # because it documents, rather than exercises, the admin primitives.
  use PhoenixStorybook.Story, :page

  def doc, do: "Brand foundations and the storybook sandbox contract for mailglass admin."

  def render(assigns) do
    ~H"""
    <div class="psb-welcome-page">
      <p>
        This storybook is a <strong>dev-only</strong> review surface for the
        <code>mailglass_admin</code> primitives. It is mounted in the demo app at
        <code>/dev/storybook</code> and never ships to adopters.
      </p>

      <h2>Sandbox stylesheet</h2>
      <p>
        Components are styled by the <strong>committed</strong> admin bundle
        (<code>priv/static/app.css</code>), served at <code>/dev/mail/css-&lt;md5&gt;</code> and
        wired as the storybook <code>css_path</code>. There is no new Tailwind/esbuild build —
        the zero-Node adopter guarantee and the <code>priv/static</code> drift gate
        (<code>mix verify.preview</code>) are both preserved.
      </p>

      <h2>Theme bridge</h2>
      <p>
        Admin components key off <code>data-theme="mailglass-light|mailglass-dark"</code> on the
        <code>.mg-admin-root</code> shell root. phoenix_storybook only applies CSS
        <em>classes</em>, never <code>data-theme</code>, so every theme-sensitive primitive sets
        <code>data-theme</code> at the <strong>template level</strong> per variation. No
        class&rarr;data-theme CSS alias is added anywhere (that would trip TokenParityTest).
      </p>

      <h2>Brand palette</h2>
      <ul>
        <li><strong>Ink</strong> #0D1B2A &middot; <strong>Glass</strong> #277B96 &middot;
          <strong>Ice</strong> #A6EAF2</li>
        <li><strong>Mist</strong> #EAF6FB &middot; <strong>Paper</strong> #F8FBFD &middot;
          <strong>Slate</strong> #5C6B7A</li>
      </ul>
      <p>
        Type: Inter (UI/body), Inter Tight (display), IBM Plex Mono (code).
        Glass (#277B96) is the single accent and is allowlisted to active/selected/primary/focus
        surfaces only.
      </p>
    </div>
    """
  end
end
