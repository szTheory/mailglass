defmodule MailglassAdmin.Inbound.AddressList do
  @moduledoc false

  # Pure normalization of the stored contact lists on an `InboundRecord`
  # (`from`, `to`, `cc`, `reply_to`). Each list is `[%{address, name?}]`; atom keys
  # on a freshly built struct, string keys after a JSONB round-trip, and bare
  # strings are tolerated. Presentation (escaping, copy controls) lives in
  # `MailglassAdmin.Inbound.DetailHeader`; nothing here builds markup.

  @type entry :: %{
          kind: :address | :unparseable,
          address: String.t() | nil,
          name: String.t() | nil,
          spoof?: boolean(),
          original: String.t() | nil
        }

  @doc """
  Normalizes a stored address list into display entries, preserving header order.
  """
  @spec entries(list() | nil) :: [entry()]
  def entries(nil), do: []

  def entries(list) do
    list
    |> List.wrap()
    |> Enum.map(&entry/1)
    |> Enum.uniq_by(&dedupe_key/1)
  end

  @doc """
  Splits entries into the always-visible head and the overflow rest.
  """
  @spec split([entry()], non_neg_integer()) :: {[entry()], [entry()]}
  def split(entries, limit \\ 5), do: Enum.split(entries, limit)

  defp entry(raw) do
    address = raw |> read(:address) |> clean()
    name = raw |> read(:name) |> clean()

    case parse(address) do
      {:ok, addr_spec} ->
        name = display_name(name, addr_spec)

        %{
          kind: :address,
          address: addr_spec,
          name: name,
          spoof?: spoof?(name, addr_spec),
          original: nil
        }

      :error ->
        %{kind: :unparseable, address: nil, name: nil, spoof?: false, original: address || name}
    end
  end

  # Strings (a bare "user@host") act as the address; maps are read with atom keys
  # first, then the JSONB string keys.
  defp read(raw, :address) when is_binary(raw), do: raw
  defp read(raw, :name) when is_binary(raw), do: nil

  defp read(%{} = raw, key) do
    case Map.get(raw, key) do
      value when is_binary(value) -> value
      _ -> raw |> Map.get(Atom.to_string(key)) |> binary_or_nil()
    end
  end

  defp read(_raw, _key), do: nil

  defp binary_or_nil(value) when is_binary(value), do: value
  defp binary_or_nil(_value), do: nil

  defp clean(nil), do: nil

  defp clean(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  # Duplicates are exact within one field: the domain is case-insensitive, the local
  # part is byte-exact. Values are displayed as stored; nothing is normalized or
  # punycoded. Unparseable entries collapse only on their exact original.
  defp dedupe_key(%{kind: :address, address: address}), do: {:address, address_key(address)}
  defp dedupe_key(%{kind: :unparseable, original: original}), do: {:unparseable, original}

  defp address_key(address) do
    [local, domain] = String.split(address, "@")
    {local, String.downcase(domain)}
  end

  # A name that is blank or just repeats the address adds nothing to show.
  defp display_name(nil, _address), do: nil
  defp display_name(address, address), do: nil
  defp display_name(name, _address), do: name

  # A display name carrying its own address that differs from the real addr-spec can
  # make a sender look like someone else; the caller renders both plus a cue.
  @embedded_address ~r/[^\s<>"',;()\[\]]+@[^\s<>"',;()\[\]]+/u

  defp spoof?(nil, _address), do: false

  defp spoof?(name, address) do
    case Regex.run(@embedded_address, name) do
      [token] ->
        embedded = String.trim_trailing(token, ".")

        case parse(embedded) do
          {:ok, embedded} -> address_key(embedded) != address_key(address)
          :error -> false
        end

      nil ->
        false
    end
  end

  # An addr-spec needs exactly one "@" with a non-empty local part and domain.
  defp parse(nil), do: :error

  defp parse(address) do
    case String.split(address, "@") do
      [local, domain] when local != "" and domain != "" -> {:ok, address}
      _other -> :error
    end
  end
end
