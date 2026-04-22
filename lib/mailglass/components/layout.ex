defmodule Mailglass.Components.Layout do
  @moduledoc """
  Email document layout with MSO head and CSS reset.

  Emits the `<!DOCTYPE html>` + `<head>` + `<body>` wrapper once. The head
  contains the MSO `OfficeDocumentSettings` XML block (D-12) so classic Outlook
  Windows renders images at 96 DPI, and light-only color-scheme metas so
  Outlook.com cannot partial-invert the design (D-13 defers dark mode to v0.5).

  ## Usage

      <Mailglass.Components.Layout.email_layout title="Welcome">
        <Mailglass.Components.container>
          ...
        </Mailglass.Components.container>
      </Mailglass.Components.Layout.email_layout>
  """

  use Phoenix.Component

  attr :lang, :string, default: "en"
  attr :title, :string, default: nil
  slot :inner_block, required: true

  @doc """
  Renders a full email HTML document with MSO head and CSS reset.

  Attributes:
    * `:lang`  — html `lang` attribute (default `"en"`).
    * `:title` — optional `<title>` element contents.
  """
  @doc since: "0.1.0"
  def email_layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang={@lang}
          xmlns:o="urn:schemas-microsoft-com:office:office"
          xmlns:v="urn:schemas-microsoft-com:vml">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta name="color-scheme" content="light" />
        <meta name="supported-color-schemes" content="light" />
        <!--[if gte mso 9]><xml>
          <o:OfficeDocumentSettings>
            <o:AllowPNG/>
            <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml><![endif]-->
        <title :if={@title}>{@title}</title>
        <style type="text/css">
          /* Email client resets */
          body { margin: 0; padding: 0; }
          table, td { border-collapse: collapse; mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
          img { border: 0; display: block; -ms-interpolation-mode: bicubic; }
          a { color: inherit; text-decoration: none; }
        </style>
      </head>
      <body style="margin:0;padding:0;background-color:#F8FBFD;">
        {render_slot(@inner_block)}
      </body>
    </html>
    """
  end
end
