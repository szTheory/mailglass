defmodule MailglassAdmin.Operator.FilterCommit do
  @moduledoc false

  # Pure helpers for committing Deliveries/Inbound filters to the URL.
  #
  # Every filter change is a commit: the browser event is reduced to a canonical
  # set of params, encoded into a sorted query, and patched into the URL. The
  # URL is the only owner of the Account (`tenant_id`) and of selection state;
  # nothing in a change, submit or recover payload can alter either.

  @default_window_hours "168"

  # Selection and pagination state never survives a filter commit: changing a
  # filter leaves the previous page and the previously selected record behind.
  @dropped_on_commit ~w(page delivery_id inbound_id full)

  @typedoc """
  What caused a filter commit. Drives the browser-history decision.
  """
  @type kind :: :search | :select | :enter | :clear | :page | :recover | :canonicalize

  @doc """
  Decides whether a commit adds a history entry or replaces the current one.

  One intent is one entry: the first commit of a search edit pushes and later
  commits of the same edit replace it. Enter replaces only when it finalizes an
  in-flight search edit (the previous commit was `:search`), otherwise it
  pushes. Selects, Clear and paging always push. Recovery after a reconnect and
  Account canonicalization are not user intents, so they always replace.
  """
  @spec history_kind(kind(), kind() | nil) :: :push | :replace
  def history_kind(:search, :search), do: :replace
  def history_kind(:enter, :search), do: :replace
  def history_kind(kind, _last_kind) when kind in [:recover, :canonicalize], do: :replace
  def history_kind(_kind, _last_kind), do: :push

  @doc """
  Reduces a browser filter payload to the params a commit may carry.

  The Account comes only from the server-held `tenant_id`, never from the
  payload. Search is trimmed at commit time (the draft stays untrimmed), and
  `page` plus the selection keys are dropped.
  """
  @spec commit_params(map(), String.t() | nil) :: map()
  def commit_params(filters, tenant_id) when is_map(filters) do
    filters
    |> Map.drop(@dropped_on_commit)
    |> Map.put("tenant_id", tenant_id || "")
    |> trim_search()
  end

  @doc """
  Classifies the changed form field from a `phx-change` `_target`.

  Only the Search input commits as `:search`; every other field, and a missing
  target, commits as `:select`.
  """
  @spec kind_for_target(list() | nil) :: :search | :select
  def kind_for_target(["filters", "search"]), do: :search
  def kind_for_target(_target), do: :select

  @doc """
  Encodes params into the canonical query string.

  Drops blank values and `page=1`, sorts by key so equal filter sets produce
  byte-identical URLs, then percent-encodes. `window_hours=168` is kept: it is
  part of the existing URL contract.
  """
  @spec encode_query(map() | keyword()) :: String.t()
  def encode_query(params) do
    params
    |> Enum.map(fn {key, value} -> {to_string(key), value} end)
    |> Enum.reject(fn
      {"page", "1"} -> true
      {_key, value} -> value in [nil, ""]
    end)
    |> Enum.sort()
    |> URI.encode_query()
  end

  @doc """
  Canonicalizes the query of the current location for comparison with a commit
  target.

  Entry URLs frequently carry no `window_hours` while every commit target does
  (`window_hours=168` is retained in committed URLs). Filling the default here
  lets a commit that changes nothing be recognised as the same location, while
  every other key (page > 1, selection, support state) still counts as part of
  the location.
  """
  @spec canonical_current_query(map()) :: String.t()
  def canonical_current_query(decoded_query) when is_map(decoded_query) do
    decoded_query
    |> Map.update("window_hours", @default_window_hours, fn
      value when value in [nil, ""] -> @default_window_hours
      value -> value
    end)
    |> encode_query()
  end

  defp trim_search(%{"search" => search} = params) when is_binary(search),
    do: Map.put(params, "search", String.trim(search))

  defp trim_search(params), do: params
end
