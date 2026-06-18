defmodule MailglassAdmin.MountPath do
  @moduledoc false

  # Recovers the absolute mount-base path the admin surface is mounted at
  # (`/dev/mail`, `/admin/preview`, …) from a request/document path, by
  # stripping the trailing live-action segments:
  #
  #   * `/dev/mail`                          -> `/dev/mail`   (:index, nothing to strip)
  #   * `/dev/mail/MyApp.Mailer/welcome`     -> `/dev/mail`   (:show, drop mailable+scenario)
  #   * `/dev/mail/MyApp.Mailer/__error__`   -> `/dev/mail`   (preview_props error)
  #   * `/dev/mail/gallery`                  -> `/dev/mail`   (gallery)
  #   * `/ops/mail/inbound`                  -> `/ops/mail`   (inbound)
  #
  # Used to build ABSOLUTE navigation/asset URLs. Relative (`./…`) URLs are
  # unsafe here: the mount path has no trailing slash, so the browser resolves
  # `./foo` against the parent directory and silently drops the final segment.

  @doc "Returns the absolute mount-base path for a request/document path."
  @spec base(String.t() | nil) :: String.t()
  def base(request_path) when is_binary(request_path) do
    segments =
      request_path
      |> String.trim("/")
      |> String.split("/", trim: true)

    "/" <> Enum.join(strip(segments), "/")
  end

  def base(_request_path), do: "/"

  defp strip([]), do: []

  defp strip(segments) do
    last = List.last(segments)

    preview_mailable? =
      segments
      |> Enum.at(-2, "")
      |> module_segment?()

    cond do
      last in ["gallery", "inbound"] -> Enum.drop(segments, -1)
      preview_mailable? -> Enum.drop(segments, -2)
      true -> segments
    end
  end

  @doc "Heuristic: does a path segment look like an Elixir module name?"
  @spec module_segment?(String.t()) :: boolean()
  def module_segment?(segment),
    do: String.contains?(segment, ".") and String.match?(segment, ~r/^(Elixir\.)?[A-Z]/)
end
