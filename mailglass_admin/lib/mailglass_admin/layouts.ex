defmodule MailglassAdmin.Layouts do
  @moduledoc false

  use Phoenix.Component

  # Submodule auto-classifies into the `MailglassAdmin` root boundary
  # declared in `lib/mailglass_admin.ex`; `classify_to:` is reserved for
  # mix tasks and protocol implementations and is not used here.

  # Plan 05 ships `MailglassAdmin.Controllers.Assets`; until then the css/js
  # helpers below fall back to the "pending" placeholders via the runtime
  # `function_exported?/3` guards. Declaring the forward reference here
  # keeps `mix compile --warnings-as-errors` green.
  @compile {:no_warn_undefined, [MailglassAdmin.Controllers.Assets]}

  embed_templates "layouts/*"

  # Asset URL helpers. Phoenix.Component.embed_templates compiles templates
  # at compile time; calling MailglassAdmin.Controllers.Assets.css_hash/0
  # directly inside the HEEx template would fail Plan 03 compile because
  # Plan 05 has not shipped the controller yet. The helpers are evaluated
  # at RENDER time via `<%= css_url() %>`, so the function_exported?/3
  # guard picks up the real hash automatically once Plan 05 lands.
  #
  # Per 05-RESEARCH.md line 940, asset hrefs are RELATIVE ("css-:md5.css"
  # without leading slash) so the browser resolves them against whatever
  # mount path the adopter chose (e.g. /dev/mail -> /dev/mail/css-XX.css).
  defp css_url do
    if function_exported?(MailglassAdmin.Controllers.Assets, :css_hash, 0) do
      "css-" <> MailglassAdmin.Controllers.Assets.css_hash() <> ".css"
    else
      "css-pending.css"
    end
  end

  defp js_url do
    if function_exported?(MailglassAdmin.Controllers.Assets, :js_hash, 0) do
      "js-" <> MailglassAdmin.Controllers.Assets.js_hash() <> ".js"
    else
      "js-pending.js"
    end
  end
end
