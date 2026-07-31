# mailglass — the GATING toolchain, reproduced locally.
#
# Every required and advisory CI lane for core runs Elixir 1.18.4 / OTP 27
# (`.tool-versions`, and the `elixir: "1.18" / otp: "27"` matrix rows in
# .github/workflows/ci.yml and advisory-matrix.yml). A maintainer's own machine
# is frequently on a newer line — 1.19 / OTP 28 — and version-dependent code has
# already shipped green locally and failed every gating lane once in this repo
# (see `test/support/sandbox_ownership.ex`, "Why the context, and not a process
# label"). This image exists so that class of mistake is catchable before push.
#
# Base image is the SAME pin `reference/demo_app/Dockerfile` already uses, so the
# repo has exactly one gating-toolchain string to keep current, not two.
FROM hexpm/elixir:1.18.4-erlang-27.3.4-debian-bookworm-20250520-slim

# git: hex/rebar fetches and any git-sourced dep. build-essential: NIF-bearing
# deps. postgresql-client: `pg_isready` for the same readiness wait the CI job
# performs before `mix ecto.create`.
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git ca-certificates postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /workspace

CMD ["sh", "-lc", "elixir --version"]
