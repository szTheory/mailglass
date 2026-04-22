defmodule Mailglass.SuppressionStore do
  @moduledoc """
  Behaviour for suppression-list storage backends.

  Phase 2 ships two callbacks — `check/2` (pre-send lookup) and
  `record/2` (add/update entry). Phase 3 may extend with more
  callbacks when the Outbound preflight lands. Default impl is
  `Mailglass.SuppressionStore.Ecto` (Postgres-backed).

  Adopters swap via:

      config :mailglass, suppression_store: MyApp.SuppressionStore

  ## Semantics

  `check/2` returns `{:suppressed, %Entry{}}` when the recipient is
  on the list under any matching scope (address, domain, or
  address_stream with the stream parameter). Returns `:not_suppressed`
  otherwise. Never raises except on infrastructure failure.

  `record/2` inserts an Entry; on UNIQUE collision
  `(tenant_id, address, scope, COALESCE(stream, ''))` it UPDATES
  `reason`/`source`/`expires_at`/`metadata` (admin re-adds become
  idempotent at the application layer).
  """

  alias Mailglass.Suppression.Entry

  @typedoc """
  Lookup key accepted by `c:check/2`.

  `tenant_id` and `address` are required. `stream` is required when
  the caller intends to match an `:address_stream`-scoped entry.
  """
  @type lookup_key :: %{
          required(:tenant_id) => String.t(),
          required(:address) => String.t(),
          optional(:stream) => atom() | nil
        }

  @typedoc "Attr map accepted by `c:record/2`; passes through to `Mailglass.Suppression.Entry.changeset/1`."
  @type record_attrs :: map()

  @callback check(lookup_key(), keyword()) ::
              {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}

  @callback record(record_attrs(), keyword()) ::
              {:ok, Entry.t()} | {:error, Ecto.Changeset.t() | term()}
end
