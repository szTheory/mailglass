defmodule MailglassDemoWeb.Mailers.AtlasDeskEmail do
  @moduledoc false

  @brand "AtlasDesk"
  @domain "atlasdesk.example"
  @demo_account "Northstar Logistics"
  @demo_account_domain "northstar.example"

  def brand, do: @brand
  def demo_account, do: @demo_account

  def address(local_part), do: local_part <> "@" <> @domain
  def account_address(local_part), do: local_part <> "@" <> @demo_account_domain

  def html(assigns) when is_map(assigns) do
    assigns =
      Map.merge(
        %{
          eyebrow: "AtlasDesk",
          preheader: "",
          title: "",
          paragraphs: [],
          metrics: [],
          cta: nil,
          note: nil
        },
        assigns
      )

    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>#{escape(assigns.title)}</title>
      </head>
      <body style="margin:0; padding:0; background:#f4f7fb; color:#14242b; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
        <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:transparent;">
          #{escape(assigns.preheader)}
        </div>
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse; background:#f4f7fb;">
          <tr>
            <td align="center" style="padding:32px 16px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse; max-width:640px;">
                <tr>
                  <td style="padding:0 0 14px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse;">
                      <tr>
                        <td style="font-size:22px; line-height:1.2; font-weight:800; color:#14242b; letter-spacing:0;">
                          #{@brand}
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td data-brand="#{@brand}" style="background:#ffffff; border:1px solid #dbe4ea; border-radius:8px; padding:32px; box-shadow:0 18px 42px rgba(20,36,43,.08);">
                    <p style="margin:0 0 12px; font-size:12px; line-height:1.4; font-weight:800; text-transform:uppercase; color:#0f766e; letter-spacing:.08em;">
                      #{escape(assigns.eyebrow)}
                    </p>
                    <h1 style="margin:0 0 18px; font-size:28px; line-height:1.18; color:#14242b; font-weight:800; letter-spacing:0;">
                      #{escape(assigns.title)}
                    </h1>
                    #{paragraphs(assigns.paragraphs)}
                    #{metrics(assigns.metrics)}
                    #{cta(assigns.cta)}
                    #{note(assigns.note)}
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp paragraphs(paragraphs) do
    paragraphs
    |> Enum.map(fn paragraph ->
      """
      <p style="margin:0 0 16px; font-size:16px; line-height:1.6; color:#2f424b;">
        #{escape(paragraph)}
      </p>
      """
    end)
    |> Enum.join("")
  end

  defp metrics([]), do: ""

  defp metrics(rows) do
    row_html =
      rows
      |> Enum.map(fn {label, value} ->
        """
        <tr>
          <td style="padding:12px 14px; border-top:1px solid #dbe4ea; font-size:12px; line-height:1.4; font-weight:800; text-transform:uppercase; letter-spacing:.08em; color:#63717a;">
            #{escape(label)}
          </td>
          <td align="right" style="padding:12px 14px; border-top:1px solid #dbe4ea; font-size:15px; line-height:1.4; font-weight:700; color:#14242b;">
            #{escape(value)}
          </td>
        </tr>
        """
      end)
      |> Enum.join("")

    """
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse; margin:22px 0; background:#f8fafb; border:1px solid #dbe4ea; border-radius:8px;">
      #{row_html}
    </table>
    """
  end

  defp cta(nil), do: ""

  defp cta({label, href}) do
    """
    <p style="margin:24px 0 0;">
      <a href="#{escape(href)}" style="display:inline-block; background:#0f766e; color:#ffffff; text-decoration:none; font-size:15px; line-height:1.2; font-weight:800; border-radius:6px; padding:13px 18px;">
        #{escape(label)}
      </a>
    </p>
    """
  end

  defp note(nil), do: ""

  defp note(text) do
    """
    <p style="margin:22px 0 0; padding:14px 16px; border-left:4px solid #d49a1e; background:#fff8e8; color:#5b4a1f; font-size:14px; line-height:1.5;">
      #{escape(text)}
    </p>
    """
  end

  defp escape(value) do
    value
    |> to_string()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
