defmodule Mailglass do
  @moduledoc """
  Transactional email framework for Phoenix.

  Composes on top of Swoosh, shipping the framework layer Swoosh omits:
  HEEx-native components, LiveView preview dashboard, normalized webhook events,
  suppression lists, RFC 8058 List-Unsubscribe, multi-tenant routing, and an
  append-only event ledger.

  ## Getting Started

      config :mailglass,
        repo: MyApp.Repo,
        adapter:
          {Mailglass.Adapters.Swoosh,
           swoosh_adapter:
             {Swoosh.Adapters.Postmark, api_key: System.fetch_env!("POSTMARK_API_KEY")}}

  ## Architecture

  See `Mailglass.Config`, `Mailglass.Renderer`, `Mailglass.Components`.
  """

  # Root boundary. In Phase 1 the boundary graph is intentionally flat: a single
  # root that contains every module under `Mailglass.*`. Internal boundaries
  # (Renderer, Components, Outbound, Events, ...) are declared by the plans
  # that introduce them. This declaration exists only so the :boundary compiler
  # (wired via `compilers: [:boundary | Mix.compilers()]`) can classify modules
  # — it imposes no cross-module constraints yet.
  use Boundary, deps: [], exports: []
end
