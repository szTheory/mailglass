defmodule Mailglass.RateLimiter.AtomicBucket do
  @moduledoc false

  @scale 1_000_000
  @minute_us 60_000_000
  @max_retries 32

  @spec consume(keyword()) :: :ok | {:error, :denied}
  def consume(opts) do
    table = Keyword.fetch!(opts, :table)
    owner = Keyword.fetch!(opts, :owner)
    key = Keyword.fetch!(opts, :key)
    capacity = Keyword.fetch!(opts, :capacity)
    per_minute = Keyword.fetch!(opts, :per_minute)
    now_us = Keyword.fetch!(opts, :now_us)

    with :ok <- ensure_admitted(table, owner, key, capacity, now_us),
         do: consume_existing(table, owner, key, capacity, per_minute, now_us, 0)
  end

  defp ensure_admitted(table, owner, key, capacity, now_us) do
    case :ets.lookup(table, key) do
      [] ->
        initial = {key, capacity * @scale, now_us, 0, now_us}

        try do
          GenServer.call(owner, {:admit, key, initial, now_us})
        catch
          :exit, _reason -> {:error, :denied}
        end

      _ ->
        :ok
    end
  end

  defp consume_existing(_table, _owner, _key, _capacity, _per_minute, _now_us, @max_retries),
    do: {:error, :denied}

  defp consume_existing(table, owner, key, capacity, per_minute, now_us, attempt) do
    case :ets.lookup(table, key) do
      [{^key, tokens, last_us, remainder, last_seen}] ->
        {available, next_remainder} =
          refill(tokens, last_us, remainder, capacity, per_minute, now_us)

        allowed? = available >= @scale
        next_tokens = if allowed?, do: available - @scale, else: available
        replacement = {key, next_tokens, now_us, next_remainder, now_us}

        if replace_exact(table, {key, tokens, last_us, remainder, last_seen}, replacement) do
          if allowed?, do: :ok, else: {:error, :denied}
        else
          consume_existing(table, owner, key, capacity, per_minute, now_us, attempt + 1)
        end

      [] ->
        # The owner can restart between admission and lookup. Re-admit once through
        # the owner; contention exhaustion remains fail-closed.
        case ensure_admitted(table, owner, key, capacity, now_us) do
          :ok -> consume_existing(table, owner, key, capacity, per_minute, now_us, attempt + 1)
          {:error, :denied} -> {:error, :denied}
        end
    end
  end

  defp refill(tokens, last_us, remainder, capacity, per_minute, now_us) do
    elapsed_us = max(now_us - last_us, 0)
    numerator = elapsed_us * per_minute * @scale + remainder
    added = div(numerator, @minute_us)
    next_remainder = rem(numerator, @minute_us)
    available = min(tokens + added, capacity * @scale)

    # At capacity elapsed time cannot buy an additional future burst.
    if available == capacity * @scale, do: {available, 0}, else: {available, next_remainder}
  end

  defp replace_exact(table, observed, replacement) do
    {key, tokens, last_us, remainder, last_seen} = observed
    {_replacement_key, next_tokens, next_last_us, next_remainder, next_last_seen} = replacement

    # The table is a set and the caller performed a key lookup, so "$1" is the
    # sole matching key. The remaining complete observed state is guarded before
    # building a replacement tuple; this is the compare-and-swap boundary.
    match_spec = [
      {{:"$1", :"$2", :"$3", :"$4", :"$5"},
       [
         {:==, :"$1", {:const, key}},
         {:==, :"$2", tokens},
         {:==, :"$3", last_us},
         {:==, :"$4", remainder},
         {:==, :"$5", last_seen}
       ], [{{:"$1", next_tokens, next_last_us, next_remainder, next_last_seen}}]}
    ]

    :ets.select_replace(table, match_spec) == 1
  end
end
