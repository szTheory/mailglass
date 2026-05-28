defmodule MailglassAdmin.Preview.CaptureState do
  @moduledoc """
  Canonical capture-state value for deterministic preview screenshot targets.
  """

  @enforce_keys [:mailable, :scenario, :width, :theme, :url]
  defstruct [:mailable, :scenario, :width, :theme, :url]

  @type theme :: :light | :dark

  @type t :: %__MODULE__{
          mailable: module(),
          scenario: atom(),
          width: 375 | 768 | 1024,
          theme: theme(),
          url: String.t()
        }

  @widths [375, 768, 1024]
  @themes [:light, :dark]

  @spec widths() :: [375 | 768 | 1024]
  def widths, do: @widths

  @spec themes() :: [theme()]
  def themes, do: @themes

  @spec new(String.t(), module(), atom(), 375 | 768 | 1024, theme()) :: t()
  def new(base_path, mailable, scenario, width, theme) do
    %__MODULE__{
      mailable: mailable,
      scenario: scenario,
      width: width,
      theme: theme,
      url: build_url(base_path, mailable, scenario, width, theme)
    }
  end

  @spec build_url(String.t(), module(), atom(), 375 | 768 | 1024, theme()) :: String.t()
  def build_url(base_path, mailable, scenario, width, theme)
      when is_binary(base_path) and is_atom(mailable) and is_atom(scenario) and
             width in @widths and theme in @themes do
    trimmed_base_path = String.trim_trailing(base_path, "/")
    theme_param = Atom.to_string(theme)

    trimmed_base_path <>
      "/" <>
      inspect(mailable) <>
      "/" <>
      Atom.to_string(scenario) <>
      "?width=" <>
      Integer.to_string(width) <>
      "&theme=" <>
      theme_param
  end

  @spec sort_key(t()) :: {String.t(), String.t(), 375 | 768 | 1024, String.t()}
  def sort_key(%__MODULE__{} = state) do
    {inspect(state.mailable), Atom.to_string(state.scenario), state.width,
     Atom.to_string(state.theme)}
  end
end
