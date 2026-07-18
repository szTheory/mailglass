defmodule MailglassAdmin.Operator.Accounts do
  @moduledoc false

  @type labels :: %{optional(String.t()) => String.t()}
  @type option :: %{id: String.t(), label: String.t()}

  @spec normalize_labels(map() | keyword() | nil) :: labels()
  def normalize_labels(nil), do: %{}

  def normalize_labels(labels) when is_map(labels) do
    labels
    |> Enum.map(fn {id, label} -> {to_string(id), clean_label(label, id)} end)
    |> Map.new()
  end

  def normalize_labels(labels) when is_list(labels) do
    labels
    |> Enum.map(fn {id, label} -> {to_string(id), clean_label(label, id)} end)
    |> Map.new()
  end

  def normalize_labels(_labels), do: %{}

  @spec label(String.t() | nil, labels() | map() | keyword() | nil) :: String.t()
  def label(nil, _labels), do: ""
  def label("", _labels), do: ""

  def label(account_id, labels) when is_binary(account_id) do
    labels = normalize_labels(labels)
    Map.get(labels, account_id, account_id)
  end

  @spec title(String.t() | nil, labels() | map() | keyword() | nil) :: String.t()
  def title(nil, _labels), do: ""
  def title("", _labels), do: ""

  def title(account_id, labels) when is_binary(account_id) do
    account_label = label(account_id, labels)

    if account_label == account_id do
      account_id
    else
      "#{account_label} (tenant_id: #{account_id})"
    end
  end

  @spec apply_labels([option()], labels() | map() | keyword() | nil) :: [option()]
  def apply_labels(options, labels) when is_list(options) do
    labels = normalize_labels(labels)

    options
    |> Enum.reject(&blank?(&1.id))
    |> Enum.map(fn option ->
      label = Map.get(labels, option.id, clean_label(option.label, option.id))
      %{id: option.id, label: label}
    end)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(&String.downcase(&1.label))
  end

  @spec field_options([option()], String.t() | nil, labels() | map() | keyword() | nil) :: [
          {String.t(), String.t()}
        ]
  def field_options(options, selected_id, labels) do
    labeled = apply_labels(options, labels)
    selected_id = blank_to_nil(selected_id)

    labeled =
      if selected_id && not Enum.any?(labeled, &(&1.id == selected_id)) do
        [%{id: selected_id, label: label(selected_id, labels)} | labeled]
      else
        labeled
      end

    Enum.map(labeled, &{&1.label, &1.id})
  end

  defp clean_label(label, fallback) do
    case label do
      value when is_binary(value) ->
        value = String.trim(value)
        if value == "", do: to_string(fallback), else: value

      nil ->
        to_string(fallback)

      value ->
        value |> to_string() |> clean_label(fallback)
    end
  end

  defp blank?(value), do: not is_binary(value) or String.trim(value) == ""
  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
