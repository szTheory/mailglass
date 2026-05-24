# Conditionally compiled — the entire `defmodule` is elided when
# `:mailglass_inbound` is absent (the `mix compile --no-optional-deps` lane), so
# `MailglassAdmin.OptionalDeps.MailglassInbound` does not exist at all without the
# dep. Callers MUST guard via
# `Code.ensure_loaded?(MailglassAdmin.OptionalDeps.MailglassInbound)` (or call
# `available?/0` through that guard) before referencing it. This mirrors
# `optional_deps/phoenix_live_reload.ex` and the core Oban call-site gate
# (lib/mailglass.ex:55-60).
#
# CONTEXT D-48-02: the `MailglassAdmin` Boundary decl in `lib/mailglass_admin.ex`
# is INTENTIONALLY left unchanged (`deps: [Mailglass]`). Listing an absent app in
# `deps:` emits `unknown_dep` and breaks the no-optional-deps lane; all inbound
# access therefore crosses a RUNTIME `apply/3` edge here, never a compile-time /
# Boundary edge (D-48-03 — `available?/0` gates the whole surface).
if Code.ensure_loaded?(MailglassInbound) do
  defmodule MailglassAdmin.OptionalDeps.MailglassInbound do
    @moduledoc """
    Runtime gateway for all `mailglass_inbound` access from `mailglass_admin`
    (CONTEXT D-48-02 / D-48-03).

    The admin LiveView never references `MailglassInbound.*` directly — it calls
    these wrappers, which `apply/3` into the inbound read-models
    (`Internal.Operator.{Records,Timeline,Detail}`), the routing-trace reflection
    (`Router.Matcher.explain/2`), and the replay seam (`Internal.Replay`). When
    `mailglass_inbound` is absent (prod-admin without inbound, or the
    `--no-optional-deps` compile lane), this whole module is elided and
    `available?/0` is unreachable — callers guard with
    `Code.ensure_loaded?(__MODULE__)` and degrade by hiding the inbound surface.

    Boundary classification: submodule auto-classifies into the `MailglassAdmin`
    root boundary; `classify_to:` is reserved for mix tasks and protocol
    implementations and is not used here.
    """

    # Declared once so the bare `MailglassInbound.*` references in the apply/3
    # wrappers below compile cleanly on every lane.
    @compile {:no_warn_undefined,
              [
                MailglassInbound,
                MailglassInbound.Internal.Operator.Records,
                MailglassInbound.Internal.Operator.Timeline,
                MailglassInbound.Internal.Operator.Detail,
                MailglassInbound.Router.Matcher,
                MailglassInbound.Internal.Replay
              ]}

    @doc """
    Returns `true`. Because this module is conditionally compiled, its mere
    existence implies `mailglass_inbound` is loaded. Callers should still
    `Code.ensure_loaded?(__MODULE__)` before calling.
    """
    @doc since: "0.2.0"
    @spec available?() :: boolean()
    def available?, do: true

    @doc "Recent inbound records for a tenant — routes to the inbound read-model."
    @doc since: "0.2.0"
    @spec list_records(map() | keyword(), keyword()) :: [map()]
    def list_records(filters, opts \\ []) do
      apply(MailglassInbound.Internal.Operator.Records, :list_records, [filters, opts])
    end

    @doc "Execution-lineage timeline for one inbound record."
    @doc since: "0.2.0"
    @spec timeline(map() | keyword(), keyword()) :: [map()]
    def timeline(filters, opts \\ []) do
      apply(MailglassInbound.Internal.Operator.Timeline, :list_runs, [filters, opts])
    end

    @doc "Detail (record + evidence + matched outcome) for one inbound record."
    @doc since: "0.2.0"
    @spec detail(map() | keyword(), keyword()) :: map() | nil
    def detail(filters, opts \\ []) do
      apply(MailglassInbound.Internal.Operator.Detail, :fetch, [filters, opts])
    end

    @doc "Per-clause routing-trace verdicts for a route against a message (IADM-04)."
    @doc since: "0.2.0"
    @spec explain(struct(), struct()) :: [tuple()]
    def explain(route, message) do
      apply(MailglassInbound.Router.Matcher, :explain, [route, message])
    end

    @doc """
    Replays a stored inbound record by id. The caller MUST tenant-gate first
    (via `detail/2`) — `Internal.Replay` loads by id only (D-48-05).
    """
    @doc since: "0.2.0"
    @spec replay(Ecto.UUID.t(), keyword()) :: {:ok, map()} | {:error, term()}
    def replay(inbound_record_id, opts \\ []) do
      apply(MailglassInbound.Internal.Replay, :replay, [inbound_record_id, opts])
    end
  end
end
