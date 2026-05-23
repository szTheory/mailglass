defmodule MailglassInbound.OptionalDeps do
  @moduledoc """
  Namespace for package-local optional dependency gateway modules.

  `mailglass_inbound` keeps optional runtime integrations behind its own
  gateway surface instead of reusing `Mailglass.OptionalDeps.*` across package
  boundaries. This preserves a coherent sibling-package contract and keeps
  `mix compile --no-optional-deps --warnings-as-errors` green.
  """
end

defmodule MailglassInbound.OptionalDeps.Oban do
  @moduledoc """
  Gateway for the optional Oban dependency (`{:oban, "~> 2.21"}`).

  Phase 39 does not ship an async execution runner. This module exists so later
  execution plans can branch on Oban availability without turning Oban into a
  mandatory install-time or runtime dependency for the package.

  The public promise in this phase is intentionally small:

  - `available?/0` reports whether `:oban` is loaded in the current runtime.
  - callers may use `runner/0` to name the future execution mode without
    referencing `Oban` directly outside this gateway.

  No `%Oban.Job{}` contract, queue names, worker modules, or execution hooks
  are part of the Phase 39 package surface.
  """

  @compile {:no_warn_undefined, [Oban, Oban.Job, Oban.Worker]}

  @doc """
  Returns `true` when `:oban` is loaded in the current runtime.
  """
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)

  @doc """
  Reports which execution seam is available for future internal runners.
  """
  @spec runner() :: :oban | :task_supervisor
  def runner do
    configured = Application.get_env(:mailglass_inbound, :async_adapter)

    cond do
      configured == :task_supervisor ->
        :task_supervisor

      available?() ->
        :oban

      true ->
        :task_supervisor
    end
  end

  @doc """
  Enqueues an internal inbound execution worker job when Oban is available.
  """
  @spec enqueue_inbound_execution(module(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def enqueue_inbound_execution(worker, attrs, opts \\ [])
      when is_atom(worker) and is_map(attrs) and is_list(opts) do
    if runner() == :oban and Code.ensure_loaded?(worker) do
      worker
      |> apply(:new, [attrs, []])
      |> Oban.insert()
    else
      {:error, :oban_unavailable}
    end
  end
end

defmodule MailglassInbound.OptionalDeps.ExAwsS3 do
  @moduledoc """
  Gateway for the optional `ex_aws` / `ex_aws_s3` dependencies
  (`{:ex_aws, "~> 2.7"}` + `{:ex_aws_s3, "~> 2.5"}`).

  Phase 46's SES inbound provider fetches the raw MIME body of a received
  message from the adopter's S3 bucket (the SES receipt-rule S3 action stores
  the message at `s3://{bucketName}/{objectKey}`). The real fetch implementation
  (`MailglassInbound.S3Fetcher.ExAwsS3`) routes **all** `ExAws`/`ExAws.S3`
  access through this gateway; the fake-adapter-first test default
  (`MailglassInbound.S3Fetcher.Fake`) needs no AWS dependency at all (D-13).

  ## STACK-lock departure (D-46-20)

  `ex_aws`/`ex_aws_s3` are the **first new optional runtime deps since the v1.0
  STACK lock** ("Optional deps: Add none"). The addition is deliberate and is
  recorded in the inbound CHANGELOG. Both deps are optional, so a default install
  carries no AWS footprint; adopters who run SES inbound add `:ex_aws`,
  `:ex_aws_s3`, an HTTP client (`:hackney`/`:req`), and `:sweet_xml` themselves
  (Phase 50 setup guide). Credentials resolve via ex_aws's standard chain
  (env → pod-identity → instance/task role) with no mailglass-specific config
  (D-46-15).

  ## Inbound-local placement (D-46-14)

  This gateway lives in `mailglass_inbound`, NOT core. `MailglassInbound`
  "keeps optional runtime integrations behind its own gateway surface instead of
  reusing `Mailglass.OptionalDeps.*` across package boundaries." SESI-04's
  literal wording `Mailglass.OptionalDeps.ExAwsS3` is an erratum — the consumer
  (`S3Fetcher.ExAwsS3`) lives in inbound, and core's `NoBareOptionalDepReference`
  is scoped to `lib/mailglass/`. The `NoBareOptionalDepReference` Credo check
  gates `ExAws`/`ExAws.S3` to this module; bare references anywhere else in
  inbound code are forbidden so `mix compile --no-optional-deps
  --warnings-as-errors` stays green.

  ## get_object/2 — never raises

  `get_object/2` wraps `ExAws.S3.get_object/2 |> ExAws.request/1` in
  `try/rescue` AND `catch :exit` so an absent dep (`:undef`), an HTTP-client
  failure, or a process exit surfaces as a tagged `{:error, {kind, reason}}`
  tuple rather than escaping. The normal degraded path is the `available?/0`
  gate; this wrapper is the defensive backstop mirroring
  `Mailglass.OptionalDeps.GenSmtp.decode/2`.
  """

  @compile {:no_warn_undefined, [ExAws, ExAws.S3]}

  @doc """
  Returns `true` when `:ex_aws_s3` (`ExAws.S3`) is loaded in the current runtime.

  Probes `ExAws.S3` as the proxy for the `ex_aws`/`ex_aws_s3` pair: the real S3
  fetch entry point is `ExAws.S3.get_object/2`, so `ExAws.S3` is the meaningful
  availability signal.
  """
  @doc since: "0.2.0"
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(ExAws.S3)

  @doc """
  Fetches an S3 object, never raising.

  Returns `{:ok, %{body: binary(), ...}}` on success (the ExAws response map —
  the caller extracts `:body`) or a tagged `{:error, {kind, reason}}` tuple
  where `kind` is `:error` (rescued exception, incl. the `:undef` backstop when
  the dep is absent) or `:exit` (a process EXIT from the HTTP client). All
  `ExAws`/`ExAws.S3` access is confined to this function.
  """
  @doc since: "0.2.0"
  @spec get_object(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_object(bucket, key) when is_binary(bucket) and is_binary(key) do
    ExAws.S3.get_object(bucket, key) |> ExAws.request()
  rescue
    e -> {:error, {:error, e}}
  catch
    :exit, reason -> {:error, {:exit, reason}}
  end
end
