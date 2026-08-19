FROM hexpm/elixir:1.18.4-erlang-27.3.4.13-debian-bookworm-20260623-slim@sha256:ca09419f742ec4040ccb4d9949324f73d3d2c364cacad56686d68d6327eb45f2

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git curl ca-certificates nodejs npm postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

COPY reference/demo_app/assets/package*.json /tmp/mailglass-demo-assets/
RUN npm --prefix /tmp/mailglass-demo-assets ci --no-audit --no-fund \
  && npx --prefix /tmp/mailglass-demo-assets playwright install --with-deps chromium \
  && rm -rf /tmp/mailglass-demo-assets

WORKDIR /workspace/reference/demo_app

CMD ["sh", "-lc", "mix deps.get && mix ecto.setup && mix phx.server"]
