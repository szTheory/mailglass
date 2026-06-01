FROM hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git curl ca-certificates nodejs npm postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /workspace/reference/demo_app

CMD ["sh", "-lc", "mix deps.get && mix ecto.setup && mix phx.server"]
