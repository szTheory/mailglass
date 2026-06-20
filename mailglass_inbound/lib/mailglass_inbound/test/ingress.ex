defmodule MailglassInbound.Test.Ingress do
  @moduledoc since: "0.2.0"
  @moduledoc """
  The inbound test driver: drives the **real** synchronous
  persist + route + execute write path and captures the outcome in the
  current test process's mailbox.

  This is the inbound analog of outbound's `Fake.Storage` → `{:mail, _}` →
  `Mailglass.TestAssertions` triangle. Outbound has a `Fake.Storage` that
  emits `{:mail, %Message{}}` on every delivery; inbound has no delivery row,
  so the capture seam lives **here** in the driver: after `Execution.execute/2`
  returns, `Test.Ingress` does

      send(self(), {:inbound, message, outcome, route})

  so that `MailglassInbound.TestAssertions` can read the captured tuple with
  `assert_received` (the inbound mirror of `assert_mail_sent`).

  ## Why this ships in `lib/` (not `test/support/`)

  Adopters `import MailglassInbound.TestAssertions` and drive captures via this
  module from their own suites, so it ships in the `mailglass_inbound` Hex
  package via the `files: ~w(lib …)` manifest — despite the `Test` in its name,
  `lib/mailglass_inbound/test/ingress.ex` is a `lib/` path. Because it ships in
  `lib/`, it references ONLY core/runtime modules (`Persist`, `Execution`, the
  inbound providers) — never `Oban`, `ExAws`, or `Plug.Test` (Pitfall 6), so it
  compiles under `mix compile --no-optional-deps --warnings-as-errors`.

  ## Two entry points

  - `receive_inbound/2` — drive a code-built `%InboundMessage{}` straight through
    persist + execute (skips the provider parse seam; use it when you already
    have a canonical message, e.g. from `MailglassInbound.Fixtures`).
  - `receive_provider_payload/3` — run the **real** provider `verify!`/`normalize`
    seam first (the same seam the production plug drives), then the same persist +
    execute + capture chain. Use it to exercise provider parsing + verification
    end to end.

  ## SES cross-test hygiene: reset the cert cache

  `receive_provider_payload(:ses, …)` consumes an SES fixture built by
  `MailglassInbound.Fixtures.build_ses_sns_payload/1`, which primes the
  **process-global** ETS cert cache (`Mailglass.Webhook.Providers.SES.CertCache`,
  shared across concurrent async tests) with one never-evicted entry per call.
  The driver deliberately does NOT reset that cache itself (it ships in `lib/`
  and stays free of an `:ex_unit` runtime dependency). If you drive SES fixtures
  from a plain `ExUnit.Case`, reset the cache between tests:

      setup do: Mailglass.Webhook.Providers.SES.CertCache.reset()

  `MailglassInbound.MailboxCase` already resets it in its `setup`, so suites that
  `use` it need no extra step. The Postmark/SendGrid/Mailgun lanes touch no
  process-global state.

  ## The captured `outcome` slot

  The third element of the captured tuple is the **normalized `execute/2` result
  map** — the actual return value of `MailglassInbound.Execution.execute/2`
  (`%{outcome: :accept}`, `%{outcome: :reject, outcome_reason: "..."}`,
  `%{outcome: :no_match}`, `%{status: :skipped}` on a duplicate, …), NOT the raw
  `%MailglassInbound.Mailbox{}` outcome atom. Keeping the real seam's return as
  the captured value means `MailglassInbound.TestAssertions` matches on the same
  enum the persisted `ExecutionRun.outcome` carries (`:accept | :ignore |
  :reject | :bounce | :no_match | :failed`), so an assertion can never drift
  from what was actually persisted.

  ## Synchronous only — never `dispatch/2`

  The driver drives `Execution.execute/2` (SYNC) with `source: :fresh`. It NEVER
  calls `Execution.dispatch/2` (async — Oban or a detached `Task.Supervisor`
  child), which produces non-deterministic `ExecutionRun` counts (the design contract/04,
  proven by the replay-convergence property). Replaying the same message
  converges: persist dedupes (DB unique index — provider-id for Postmark,
  `md5(raw_mime)` for SendGrid/SES/Mailgun), and `execute/2` on a `:duplicate`
  persist result short-circuits to `{:ok, %{status: :skipped}}`, inserting zero
  fresh `ExecutionRun` rows.

  ## PII posture

  The driver writes to the adopter's sandboxed test DB (rolled back per test)
  and sends the capture tuple only to the current test process. It adds no
  telemetry of its own (the `Execution.execute/2` it drives emits the normal
  PII-free execution span) and adds no PII spans (T-47-09/12).
  """

  alias MailglassInbound.Execution
  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Ingress.Persist
  alias MailglassInbound.Ingress.Request
  alias MailglassInbound.Ingress.Providers.{Mailgun, Postmark, SES, Sendgrid}
  alias MailglassInbound.S3Fetcher

  @persist_opt_keys [:routes, :router, :repo]
  @default_tenant_id "fixture-tenant"

  @typedoc "The capture tuple sent to the current process on every receive."
  @type capture :: {:inbound, InboundMessage.t(), map(), map()}

  @typedoc "The success return of both entry points."
  @type result :: %{
          message: InboundMessage.t(),
          outcome: map(),
          route: map(),
          persisted: map()
        }

  @doc """
  Drives a code-built `%InboundMessage{}` through the real persist + execute
  path, captures `{:inbound, message, outcome, route}` in the current process,
  and returns `{:ok, %{message:, outcome:, route:, persisted:}}`.

  ## Options

  - `:repo` — the Ecto repo (default `MailglassInbound.Repo`; tests pass
    `MailglassInbound.TestRepo`).
  - `:router` — a compiled `use MailglassInbound.Router` module (the same router
    your endpoint mounts). This is the adopter-facing way to drive routing: define
    routes with the `route/2` DSL once and reuse the module here. Mutually
    exclusive with `:routes`.
  - `:routes` — the package-internal lower-level input: a pre-built list of route
    data. The route-data shape is `@moduledoc false` internal and is not part of
    the stable or testing contract, so prefer `:router` in adopter suites;
    `:routes` exists mainly for the package's own tests.
  - `:evidence` — the evidence map persisted alongside the record
    (default `%{raw_payload: %{}}`). For raw_mime-dedupe providers driven via
    `receive_inbound/2`, pass `evidence: %{raw_mime: ...}` so replays dedupe.

  The message carries its own `:tenant_id` and `:provider`.
  """
  @spec receive_inbound(InboundMessage.t(), keyword()) :: {:ok, result()} | {:error, term()}
  @doc since: "0.2.0"
  def receive_inbound(%InboundMessage{} = message, opts \\ []) when is_list(opts) do
    handoff = %{
      tenant_id: message.tenant_id,
      provider: message.provider,
      message: message,
      evidence: Keyword.get(opts, :evidence, %{raw_payload: %{}})
    }

    drive(handoff, message, opts)
  end

  @doc """
  Runs the **real** provider `verify!`/`normalize` seam for `provider` over a
  fixture `payload`, then drives the same persist + execute + capture chain as
  `receive_inbound/2`.

  `payload` is the raw fixture shape produced by `MailglassInbound.Fixtures`.
  The `Fixtures` builders for `:sendgrid`, `:mailgun`, and `:ses` self-sign their
  payloads against documented defaults, so those three providers verify **out of
  the box** with no extra options. `:postmark` is the one provider whose fixture
  carries no auth, so it needs an explicit `config:` + `headers:` pair (see below):

  - `:postmark` — a JSON binary (`build_postmark_payload/1`); needs `config:` +
    `headers:`.
  - `:sendgrid` — `%{raw_mime:, headers:, params:, config:}`
    (`build_sendgrid_payload/1`); the fixture self-signs an `authorization` header
    against `Fixtures.sendgrid_fixture_config/0`, and the driver defaults
    `config:` to the fixture's `:config`.
  - `:mailgun` — `%{params:, headers:, config:}` (`build_mailgun_payload/1`); the
    fixture HMAC-signs the `timestamp`/`token`/`signature` triple against
    `Fixtures.mailgun_fixture_config/0`, and the driver defaults `config:` to the
    fixture's `:config`.
  - `:ses` — `%{raw_body:, headers:, config:}` (`build_ses_sns_payload/1`); the
    fixture primes the real `CertCache` and the driver defaults `config:` to the
    fixture's `:config`.

  ## Options

  - `:tenant_id` — the tenant assigned to the normalized message. The production
    plug resolves this from the request via `Tenancy`, which needs a `%Plug.Conn{}`
    we deliberately do NOT depend on here (Pitfall 6); the driver takes it as an
    option instead (default `"fixture-tenant"`).
  - `:config` — the provider config passed straight to `verify!`. The real
    verifier is never weakened (T-47-11), so the config must satisfy it. For
    `:sendgrid`/`:mailgun`/`:ses` the driver defaults this to the fixture's own
    self-signed `:config`, so you only pass it to override (e.g. to sign against
    your own credentials/key). `:postmark` has no fixture config and requires
    `config: %{basic_auth: {user, pass}}` AND a matching `authorization` header.
    For `:ses`, `s3_fetcher:` defaults to `MailglassInbound.S3Fetcher.Fake` if absent.
  - `:headers` — request headers. For `:postmark` (the fixture JSON body carries
    none) pass the `{"authorization", "Basic …"}` header matching `:config`'s
    `basic_auth`. For `:sendgrid`/`:mailgun` the fixture already supplies the
    headers verify! needs; pass `:headers` only to override them.
  - `:repo`, `:routes`, `:router`, `:evidence` — as in `receive_inbound/2`.
  """
  @spec receive_provider_payload(atom(), term(), keyword()) ::
          {:ok, result()} | {:error, term()}
  @doc since: "0.2.0"
  def receive_provider_payload(provider, payload, opts \\ [])
      when is_atom(provider) and is_list(opts) do
    tenant_id = Keyword.get(opts, :tenant_id, @default_tenant_id)
    {request, config} = build_request(provider, payload, opts)

    facts = verify_request!(provider, request, config)
    normalized = normalize_request!(provider, request)

    message =
      normalized.message
      |> Map.put(:tenant_id, tenant_id)
      |> Map.put(:provider, provider)

    evidence =
      normalized.evidence
      |> Map.update(:verification_facts, facts, &Map.merge(&1, facts))

    handoff = %{
      tenant_id: tenant_id,
      provider: provider,
      message: message,
      evidence: evidence
    }

    drive(handoff, message, opts)
  end

  # ---- shared persist → execute → capture chain ----------------------------

  defp drive(handoff, message, opts) do
    persist_opts = Keyword.take(opts, @persist_opt_keys)

    with {:ok, persisted} <- Persist.persist(handoff, persist_opts),
         {:ok, outcome} <- Execution.execute(persisted, source: :fresh) do
      # THE CAPTURE SEAM — the inbound analog of outbound's {:mail, _} send
      # (lib/mailglass/test_assertions.ex:33-34). Sent to the current test
      # process so `MailglassInbound.TestAssertions` can `assert_received` it.
      send(self(), {:inbound, message, outcome, persisted.route})

      {:ok, %{message: message, outcome: outcome, route: persisted.route, persisted: persisted}}
    end
  end

  # ---- per-provider Request build + real verify!/normalize dispatch --------
  # Mirrors the production plug (ingress/plug.ex build_request!/verify_request!/
  # normalize_request!) without a %Plug.Conn{} — the fixture payload carries the
  # raw bytes/params the plug would otherwise read off the conn.

  defp build_request(:postmark, raw_body, opts) when is_binary(raw_body) do
    request = %Request{
      provider: :postmark,
      raw_body: raw_body,
      headers: Keyword.get(opts, :headers, []),
      params: %{}
    }

    {request, Keyword.get(opts, :config, %{})}
  end

  defp build_request(:sendgrid, %{raw_mime: raw_mime, headers: headers, params: params} = payload, opts) do
    request = %Request{
      provider: :sendgrid,
      raw_body: raw_mime,
      # Honor caller-supplied headers like the :postmark clause does (CR-01): the
      # fixture self-signs an `authorization` header into `headers`, so default to
      # that, but let the caller override to test their own credentials.
      headers: Keyword.get(opts, :headers, headers),
      params: params,
      raw_mime: raw_mime
    }

    # Default the verify! config from the fixture's self-signed `:config`
    # (mirrors the :ses clause) so the fixture verifies out of the box.
    config = Keyword.get(opts, :config, Map.get(payload, :config, %{}))
    {request, config}
  end

  defp build_request(:mailgun, %{params: params, headers: headers} = payload, opts) do
    request = %Request{
      provider: :mailgun,
      headers: Keyword.get(opts, :headers, headers),
      params: params
    }

    # Default the verify! config from the fixture's self-signed `:config`
    # (mirrors the :ses clause) so the HMAC-signed fixture verifies out of the box.
    config = Keyword.get(opts, :config, Map.get(payload, :config, %{}))
    {request, config}
  end

  defp build_request(:ses, %{raw_body: raw_body, headers: headers} = payload, opts) do
    request = %Request{provider: :ses, raw_body: raw_body, headers: headers, params: %{}}

    config =
      opts
      |> Keyword.get(:config, Map.get(payload, :config, %{}))
      |> Map.put_new(:s3_fetcher, S3Fetcher.Fake)

    {request, config}
  end

  # Postmark uses the legacy verify!/3 returning a bare facts map; the struct-
  # arity providers return {:ok, facts}. Both collapse to a plain facts map here.
  defp verify_request!(:postmark, %Request{} = request, config) do
    Postmark.verify!(request.raw_body, request.headers, config)
  end

  defp verify_request!(:sendgrid, %Request{} = request, config),
    do: unwrap_facts(Sendgrid.verify!(request, config))

  defp verify_request!(:mailgun, %Request{} = request, config),
    do: unwrap_facts(Mailgun.verify!(request, config))

  defp verify_request!(:ses, %Request{} = request, config),
    do: unwrap_facts(SES.verify!(request, config))

  defp unwrap_facts({:ok, facts}) when is_map(facts), do: facts
  defp unwrap_facts(facts) when is_map(facts), do: facts

  defp normalize_request!(:postmark, %Request{} = request),
    do: Postmark.normalize(request.raw_body, request.headers)

  defp normalize_request!(:sendgrid, %Request{} = request), do: Sendgrid.normalize(request)
  defp normalize_request!(:mailgun, %Request{} = request), do: Mailgun.normalize(request)
  defp normalize_request!(:ses, %Request{} = request), do: SES.normalize(request)
end
