defmodule MailglassInbound.Internal.Doctor do
  @moduledoc """
  DNS-free pre-deploy config check runner for `mix mailglass.inbound.doctor`
  (IOPS-01, MIME-03). All checks are pure reflection — no DB, no DNS, no network
  — so the doctor is fast, offline, and CI-friendly (D-49-06).

  `run/1` returns `%{summary: %{pass, warn, fail, cannot_diagnose}, findings: [...]}`
  with the locked finding shape `%{check, status, title, observed, remediation,
  evidence}` (D-49-05). The CLI shell maps the summary to the three-state exit code.

  ## Checks (all DNS-free)

    * router configured + compiles (absent -> a `:cannot_diagnose` marker the task
      maps to exit 2);
    * `>= 1` route defined;
    * each route's mailbox is compiled + `function_exported?(mod, :process, 1)`;
    * provider signing keys are PRESENT (reads the same `:mailglass_inbound` config
      the plug reads — NEVER verifies a signature; the finding text says so);
    * MIME backend availability + version via `Mailglass.OptionalDeps.GenSmtp`
      (MIME-03, no bare optional-dep reference);
    * route-conflict detection REUSING `MailglassInbound.Router.Matcher.matches_route?/2`
      (D-49-07): structural subsumption (broad-before-narrow) -> `:fail`,
      witness-probe shadow -> `:fail`, regex-vs-regex overlap -> `:warn`. Conflict
      findings name `router.ex:LINE` via `Route.:source` (D-49-08).
  """

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Router.Matcher
  alias MailglassInbound.Router.Route

  # Provider config keys that carry a signing/secret credential. SES authenticates
  # via SNS certificate (no static signing key), so it is not listed here.
  @signing_key_checks [
    {:postmark, :basic_auth},
    {:sendgrid, :basic_auth},
    {:mailgun, :signing_key}
  ]

  @type status :: :pass | :warn | :fail

  @type finding :: %{
          check: atom(),
          status: status(),
          title: String.t(),
          observed: String.t(),
          remediation: String.t(),
          evidence: map()
        }

  @type result :: %{summary: map(), findings: [finding()]}

  @doc """
  Run all DNS-free checks against the configured (or opt-supplied) router.

  Options:

    * `:router` — the router module to reflect. Defaults to
      `Application.get_env(:mailglass_inbound, :router)`. When `nil`/absent the
      result carries a `:cannot_diagnose` finding (drives exit 2).
  """
  @spec run(keyword()) :: result()
  def run(opts \\ []) when is_list(opts) do
    router = Keyword.get(opts, :router, Application.get_env(:mailglass_inbound, :router))

    findings = check_router(router) ++ mime_findings() ++ signing_key_findings()

    %{summary: summarize(findings), findings: findings}
  end

  # ---- router + route checks ------------------------------------------------

  defp check_router(nil) do
    [
      %{
        check: :router_configured,
        status: :fail,
        title: "Inbound router is not configured",
        observed: "No `:router` configured under `:mailglass_inbound` (cannot diagnose)",
        remediation:
          "Set `config :mailglass_inbound, router: MyApp.InboundRouter` so the doctor can reflect your routes.",
        evidence: %{cannot_diagnose: true}
      }
    ]
  end

  defp check_router(router) when is_atom(router) do
    case ensure_router_compiled(router) do
      {:error, finding} ->
        [finding]

      {:ok, routes} ->
        [router_compiled_finding(router) | routes_findings(router, routes)]
    end
  end

  defp ensure_router_compiled(router) do
    cond do
      not Code.ensure_loaded?(router) ->
        {:error,
         %{
           check: :router_configured,
           status: :fail,
           title: "Inbound router does not compile",
           observed: "`#{inspect(router)}` could not be loaded (cannot diagnose)",
           remediation: "Ensure the router module compiles and is on the code path.",
           evidence: %{cannot_diagnose: true, router: inspect(router)}
         }}

      not function_exported?(router, :__mailglass_inbound_routes__, 0) ->
        {:error,
         %{
           check: :router_configured,
           status: :fail,
           title: "Module is not a MailglassInbound.Router",
           observed: "`#{inspect(router)}` does not `use MailglassInbound.Router` (cannot diagnose)",
           remediation: "Add `use MailglassInbound.Router` and declare `route/2` entries.",
           evidence: %{cannot_diagnose: true, router: inspect(router)}
         }}

      true ->
        {:ok, router.__mailglass_inbound_routes__()}
    end
  end

  defp router_compiled_finding(router) do
    %{
      check: :router_configured,
      status: :pass,
      title: "Inbound router is configured and compiles",
      observed: "`#{inspect(router)}` is loaded with a routes reflection",
      remediation: "No action needed.",
      evidence: %{router: inspect(router)}
    }
  end

  defp routes_findings(router, []) do
    [
      %{
        check: :routes_defined,
        status: :fail,
        title: "Router declares no routes",
        observed: "`#{inspect(router)}` declares zero `route/2` entries",
        remediation: "Declare at least one `route/2` so inbound mail can be routed.",
        evidence: %{}
      }
    ]
  end

  defp routes_findings(_router, routes) do
    [routes_count_finding(routes)] ++ mailbox_findings(routes) ++ conflict_findings(routes)
  end

  defp routes_count_finding(routes) do
    %{
      check: :routes_defined,
      status: :pass,
      title: "Router declares at least one route",
      observed: "#{length(routes)} route(s) declared",
      remediation: "No action needed.",
      evidence: %{count: length(routes)}
    }
  end

  # ---- mailbox behaviour check ----------------------------------------------

  defp mailbox_findings(routes) do
    routes
    |> Enum.map(& &1.mailbox)
    |> Enum.uniq()
    |> Enum.map(&mailbox_finding/1)
  end

  defp mailbox_finding(mailbox) do
    cond do
      not Code.ensure_loaded?(mailbox) ->
        %{
          check: :mailbox,
          status: :fail,
          title: "Mailbox does not compile",
          observed: "`#{inspect(mailbox)}` could not be loaded",
          remediation: "Ensure the mailbox module compiles and is on the code path.",
          evidence: %{mailbox: inspect(mailbox)}
        }

      not function_exported?(mailbox, :process, 1) ->
        %{
          check: :mailbox,
          status: :fail,
          title: "Mailbox does not implement process/1",
          observed: "`#{inspect(mailbox)}` does not export `process/1`",
          remediation:
            "Implement `@behaviour MailglassInbound.Mailbox` and define `process/1` on the mailbox.",
          evidence: %{mailbox: inspect(mailbox)}
        }

      true ->
        %{
          check: :mailbox,
          status: :pass,
          title: "Mailbox implements process/1",
          observed: "`#{inspect(mailbox)}` exports `process/1`",
          remediation: "No action needed.",
          evidence: %{mailbox: inspect(mailbox)}
        }
    end
  end

  # ---- route-conflict detection (REUSES Router.Matcher) ---------------------

  # For every ordered pair (earlier precedes later), classify how the earlier
  # route shadows the later one. We REUSE `Matcher.matches_route?/2` for the
  # witness-probe so match semantics never drift from runtime (D-49-07).
  defp conflict_findings(routes) do
    indexed = Enum.with_index(routes)

    for {earlier, ei} <- indexed,
        {later, li} <- indexed,
        ei < li,
        finding = classify_conflict(earlier, later),
        finding != nil do
      finding
    end
  end

  defp classify_conflict(%Route{} = earlier, %Route{} = later) do
    cond do
      regex_vs_regex?(earlier, later) ->
        conflict_warn(earlier, later)

      shadows?(earlier, later) ->
        conflict_fail(earlier, later)

      true ->
        nil
    end
  end

  # A regex matcher on BOTH routes for the same clause => overlap is undecidable.
  defp regex_vs_regex?(earlier, later) do
    regex_clause?(earlier.recipient, later.recipient) or
      regex_clause?(earlier.subject, later.subject)
  end

  defp regex_clause?(%Regex{}, %Regex{}), do: true
  defp regex_clause?(_, _), do: false

  # The earlier route shadows the later one when:
  #   (a) structural subsumption — earlier is a catch-all (nil recipient) or a
  #       broader regex preceding a narrower exact-string route; OR
  #   (b) witness-probe — a message synthesized from the LATER route's exact-string
  #       matchers also matches the EARLIER route (so the later route is unreachable).
  defp shadows?(earlier, later) do
    subsumes?(earlier, later) or witness_shadows?(earlier, later)
  end

  # Catch-all (nil) or regex earlier matcher preceding a concrete string matcher.
  defp subsumes?(earlier, later) do
    broader?(earlier.recipient, later.recipient) and
      compatible?(earlier.subject, later.subject) and earlier.headers == []
  end

  defp broader?(nil, later) when not is_nil(later), do: true
  defp broader?(%Regex{}, later) when is_binary(later), do: true
  defp broader?(_, _), do: false

  # The earlier clause does not exclude the later one (nil/regex earlier is lenient).
  defp compatible?(nil, _later), do: true
  defp compatible?(%Regex{}, _later), do: true
  defp compatible?(earlier, later) when is_binary(earlier), do: earlier == later
  defp compatible?(_, _), do: false

  defp witness_shadows?(earlier, later) do
    case witness_message(later) do
      nil -> false
      %InboundMessage{} = witness -> Matcher.matches_route?(earlier, witness)
    end
  end

  # Build an InboundMessage from the later route's exact-string matchers. Only a
  # concrete (string) recipient/subject is probe-able; a nil/regex later route has
  # no single witness value, so we skip it (returns nil).
  defp witness_message(%Route{} = later) do
    recipient = witness_value(later.recipient)
    subject = witness_value(later.subject)
    headers = witness_headers(later.headers)

    if recipient || subject || headers != %{} do
      %InboundMessage{
        envelope_recipient: recipient,
        subject: subject,
        headers: headers
      }
    else
      nil
    end
  end

  defp witness_value(value) when is_binary(value), do: value
  defp witness_value(_), do: nil

  defp witness_headers(headers) do
    for {name, matcher} <- headers, is_binary(matcher), into: %{}, do: {name, [matcher]}
  end

  defp conflict_fail(earlier, later) do
    %{
      check: :route_conflict,
      status: :fail,
      title: "Route is shadowed by an earlier route",
      observed:
        "The route at #{format_source(later.source)} is unreachable — an earlier route at #{format_source(earlier.source)} matches the same messages.",
      remediation:
        "Reorder the routes so the more specific route precedes the broader one, or narrow the earlier matcher.",
      evidence: %{earlier: route_summary(earlier), later: route_summary(later)}
    }
  end

  defp conflict_warn(earlier, later) do
    %{
      check: :route_conflict,
      status: :warn,
      title: "Possible regex route overlap",
      observed:
        "The routes at #{format_source(earlier.source)} and #{format_source(later.source)} both use regex matchers — overlap cannot be decided automatically; verify manually.",
      remediation: "Confirm the regex routes do not unintentionally overlap.",
      evidence: %{earlier: route_summary(earlier), later: route_summary(later)}
    }
  end

  defp route_summary(%Route{} = route) do
    %{
      mailbox: inspect(route.mailbox),
      recipient: inspect(route.recipient),
      subject: inspect(route.subject),
      source: format_source(route.source)
    }
  end

  defp format_source({file, line}) when is_binary(file) and is_integer(line) do
    "#{Path.basename(file)}:#{line}"
  end

  defp format_source(_), do: "unknown source"

  # ---- MIME backend report (MIME-03) ----------------------------------------

  defp mime_findings do
    available? = Mailglass.OptionalDeps.GenSmtp.available?()
    version = backend_version()

    {status, observed} =
      if available? do
        {:pass, "MIME backend gen_smtp (:mimemail) #{version || "available"} is loaded"}
      else
        {:warn,
         "MIME backend gen_smtp (:mimemail) is not loaded — raw MIME parsing is unavailable"}
      end

    [
      %{
        check: :mime_backend,
        status: status,
        title: "MIME backend availability",
        observed: observed,
        remediation:
          "Add `{:gen_smtp, \"~> 1.3\"}` to enable raw RFC 5322 MIME parsing for providers that deliver raw MIME.",
        evidence: %{backend: "gen_smtp (:mimemail)", version: version, available: available?}
      }
    ]
  end

  defp backend_version do
    case Application.spec(:gen_smtp, :vsn) do
      vsn when is_list(vsn) -> List.to_string(vsn)
      _ -> nil
    end
  end

  # ---- signing-key PRESENCE check (never verifies) --------------------------

  defp signing_key_findings do
    Enum.map(@signing_key_checks, fn {provider, key} ->
      config = Application.get_env(:mailglass_inbound, provider, [])
      present? = present?(config[key])

      %{
        check: :signing_keys,
        status: if(present?, do: :pass, else: :warn),
        title: "#{provider} signing credential presence",
        observed:
          if present? do
            "#{provider} `#{key}` is present (presence only — the doctor never verifies a signature)"
          else
            "#{provider} `#{key}` is not configured (presence only — not verified)"
          end,
        remediation:
          "Configure `config :mailglass_inbound, #{provider}: [#{key}: ...]` if you ingest #{provider} webhooks.",
        evidence: %{provider: provider, key: key, present: present?}
      }
    end)
  end

  defp present?(nil), do: false
  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)

  # ---- summary --------------------------------------------------------------

  defp summarize(findings) do
    base = %{pass: 0, warn: 0, fail: 0, cannot_diagnose: 0}

    Enum.reduce(findings, base, fn finding, acc ->
      acc = Map.update!(acc, finding.status, &(&1 + 1))

      if Map.get(finding[:evidence] || %{}, :cannot_diagnose) do
        Map.update!(acc, :cannot_diagnose, &(&1 + 1))
      else
        acc
      end
    end)
  end
end
