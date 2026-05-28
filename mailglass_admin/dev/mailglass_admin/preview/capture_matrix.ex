defmodule MailglassAdmin.Preview.CaptureMatrix do
  @moduledoc """
  Deterministic matrix builder for preview capture targets.
  """

  alias MailglassAdmin.Preview.CaptureState

  @type skipped_reason :: :no_previews | :discovery_error | :invalid_reflection

  @type skipped_entry :: %{
          mailable: module(),
          reason: skipped_reason(),
          details: String.t() | nil
        }

  @type result :: %{
          entries: [CaptureState.t()],
          skipped: [skipped_entry()]
        }

  @spec build_matrix([tuple()], keyword()) :: result()
  def build_matrix(discovery_results, opts \\ []) when is_list(discovery_results) do
    base_path = Keyword.get(opts, :base_path, "/dev/mail")
    widths = normalized_widths(Keyword.get(opts, :widths, CaptureState.widths()))
    themes = normalized_themes(Keyword.get(opts, :themes, CaptureState.themes()))

    {entries, skipped} =
      Enum.reduce(discovery_results, {[], []}, fn {mailable, reflection}, {entries, skipped} ->
        build_for_reflection(entries, skipped, base_path, widths, themes, mailable, reflection)
      end)

    %{
      entries: Enum.sort_by(entries, &CaptureState.sort_key/1),
      skipped: Enum.sort_by(skipped, &skipped_sort_key/1)
    }
  end

  defp build_for_reflection(entries, skipped, base_path, widths, themes, mailable, reflection)
       when is_list(reflection) and is_atom(mailable) do
    states =
      reflection
      |> Enum.sort_by(fn {scenario, _defaults} -> Atom.to_string(scenario) end)
      |> Enum.flat_map(fn {scenario, _defaults} ->
        for width <- widths, theme <- themes do
          CaptureState.new(base_path, mailable, scenario, width, theme)
        end
      end)

    {states ++ entries, skipped}
  end

  defp build_for_reflection(entries, skipped, _base_path, _widths, _themes, mailable, :no_previews)
       when is_atom(mailable) do
    {entries, [%{mailable: mailable, reason: :no_previews, details: nil} | skipped]}
  end

  defp build_for_reflection(
         entries,
         skipped,
         _base_path,
         _widths,
         _themes,
         mailable,
         {:error, reason}
       )
       when is_atom(mailable) do
    {entries,
     [%{mailable: mailable, reason: :discovery_error, details: to_string(reason)} | skipped]}
  end

  defp build_for_reflection(entries, skipped, _base_path, _widths, _themes, mailable, reflection)
       when is_atom(mailable) do
    {entries,
     [
       %{
         mailable: mailable,
         reason: :invalid_reflection,
         details: inspect(reflection)
       }
       | skipped
     ]}
  end

  defp normalized_widths(widths) do
    widths
    |> Enum.filter(&(&1 in CaptureState.widths()))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalized_themes(themes) do
    themes
    |> Enum.filter(&(&1 in CaptureState.themes()))
    |> Enum.uniq()
    |> Enum.sort_by(&Atom.to_string/1)
  end

  defp skipped_sort_key(%{mailable: mailable, reason: reason}) do
    {inspect(mailable), Atom.to_string(reason)}
  end
end
