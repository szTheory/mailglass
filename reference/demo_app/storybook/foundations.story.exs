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
        CSS alias from <code>class</code> to <code>data-theme</code> is added anywhere (that would
        trip TokenParityTest).
      </p>

      <h2>Brand palette</h2>
      <ul>
        <li><strong>Espresso</strong> #2A1D17 &bull; <strong>Deep Glass</strong> #0A6488 &bull;
          <strong>Bright Glass</strong> #6CC6F0</li>
        <li><strong>Sand</strong> #F6F1E8 &bull; <strong>Sunken Sand</strong> #ECE5D8 &bull;
          <strong>Roast</strong> #1D1713</li>
      </ul>
      <p>
        Type: Atkinson Hyperlegible Next (UI/body), Funnel Display (display), Atkinson Hyperlegible
        Mono (code). Deep Glass (#0A6488) is the single accent and is allowlisted to
        active/selected/primary/focus surfaces only.
      </p>
    </div>
    """
  end
end
