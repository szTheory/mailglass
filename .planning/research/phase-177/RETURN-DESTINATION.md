# Phase 177 — UXF-10 Preview return destination

**Requirement:** UXF-10. An operator who enters Preview can return to the Account they came from through a validated, host-approved local destination, with a clear fallback for direct entry.
**Locked constraints:** REQUIREMENTS.md "Navigation decision" and ROADMAP Phase 177 SC-3. The capability is navigation-only. It must work under custom mount prefixes, reject tampered and external destinations, refuse to honor unauthorized Account targets, give direct entry a clear fallback, and grant no authority. It must not widen the Preview session/auth whitelists, add global current-Account state, or break host configuration, Browser Back or independent Preview rendering.
**Status:** research complete. This is a recommendation for the planner. It is not committed.

---

## 1. What the code does today (grounding)

| Fact | Where |
|---|---|
| Preview and operator are **separate `live_session`s**. Preview has no actor, no auth seam and no tenant. Its session callback `__preview_session__/2` whitelists only `mailables`, `live_session_name` and `navigation`. | `mailglass_admin/lib/mailglass_admin/router.ex:354-400` |
| Navigating between `live_session`s **always forces a full page load**, so the link must be a plain `<a href>`. `SurfaceNav` already renders with `navigate={false}`. | `deps/phoenix_live_view/lib/phoenix_live_view/router.ex:141-142`; `surface_nav.ex:34-48` |
| The Account is carried as **`?tenant_id=`** on operator URLs (Health/Deliveries at the operator mount, Inbound at `<mount>/inbound`). | `operator_live.ex:174`, `inbound_live.ex:207` |
| Hosts already approve **static** cross-surface paths through `:navigation`: Preview gets `overview_path`/`deliveries_path`/`inbound_path`, and operator gets `preview_path`. The type is `{:or, [:string, nil]}` with no locality check. | `router.ex:105-126` |
| The demo's Preview navigation links are static `"/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar"`. They are hard-wired to Northstar, so they prove nothing about returning to the same Account (the requirement says this explicitly). | `reference/demo_app/lib/mailglass_demo_web/router.ex:111-116` |
| The operator selector list is **actor-scoped through the tenancy seam**: `Operator.Tenants.list_tenants(operator_actor)` leads to `Mailglass.Operator.Tenants`, which applies `Tenancy.scope(context)`. | `operator/tenants.ex`, `lib/mailglass/operator/tenants.ex:20-29` |
| **A direct `?tenant_id=` load is honored whether or not the id is in the actor's list.** `tenant_state(_selected, _, _) -> :selected` on both surfaces, and delivery reads scope by the *selected id* (`Tenancy.scope(tenant_id)`), not by the actor. Phase 176 stopped foreign ids arriving through form *events* (`operator_live_test.exs:2826`), but not through the URL. | `operator_live.ex:1203`, `inbound_live.ex:1056`, `lib/mailglass/operator/deliveries.ex:38-41` |
| Preview's internal URLs **drop unknown query params**. `build_capture_url/2` is `base_path <> "?width=" <> w`, and the sidebar patches rebuild paths from scratch. The theme round-trip keeps them: `append_query_without_theme` strips only `theme`/`frame`, and `ThemeController.sanitized_return_to/2` accepts paths under the mount. | `preview_live.ex:797-850`, `controllers/theme_controller.ex:49-61` |

## 2. Recommended design (one coherent set)

### 2.1 Carrier: a derived reference in the URL, not a URL

The operator surface mints the Preview link. It appends two query params to its configured `preview_path`:

```
/dev/mail?return_surface=deliveries&return_tenant_id=northstar
```

- `return_surface` is a **closed set**: `"overview" | "deliveries" | "inbound"`. It is compared as a string and never passed to `String.to_atom`.
- `return_tenant_id` is an **opaque value**. It is only ever written back out with `URI.encode_query` and is never used to scope, read or label anything in Preview.

Preview **never accepts a URL**. It derives the return href from host configuration it already has:

> href = the host-configured `navigation[:<surface>_path]` with its `tenant_id` query key set to `return_tenant_id`.

This follows OWASP's strongest recommendation, "use an identifier mapped to a destination, not the destination itself". Because no user-supplied string ever becomes a path, scheme or host, an open redirect is impossible **by construction**. The whole class of `//evil`, `/\evil`, `%2F%2F`, control-character and `javascript:` attacks has nothing to act on.

Why not `tenant_id` as the param name in Preview? On a Preview URL it would read as "Preview is scoped to this Account", which contradicts UXF-09 and the rule against using the Account to scope sample rendering. The `return_` prefix says what the value is for: navigation context, nothing else. It also avoids `return_to`, which the theme controller already uses with full-path semantics.

### 2.2 Minting rule (operator side: OperatorLive / InboundLive / Shell)

The operator appends the two params to `preview_path` **only when all of these hold**:
1. `tenant_state == :selected`, and the selected id is a member of the actor-scoped `tenant_options` (see 2.4).
2. `preview_path` passes the local-path predicate in 2.3, step 1. Otherwise the configured link renders exactly as today.

The params are merged into any query the host already put on `preview_path`; existing keys are replaced, not duplicated. `return_surface` is the live surface: `overview`, `deliveries` when `view=deliveries`, or `inbound`.

### 2.3 Validation algorithm (Preview side, one pure function)

`MailglassAdmin.Preview.ReturnContext.resolve(params, navigation) :: nil | %{surface: String.t(), tenant_id: String.t(), href: String.t()}` (`@moduledoc false`). It runs in `handle_params/3`, so it re-derives on every patch, reconnect and remount, and it never writes to the session.

0. Read `s = params["return_surface"]` and `t = params["return_tenant_id"]`. Both must be binaries. A list or map, such as `?return_tenant_id[]=x`, returns `nil`.
1. **Surface:** `s in ~w(overview deliveries inbound)`, otherwise `nil`.
2. **Host-approved path:** `p = navigation["#{s}_path"]` (string- or atom-keyed, as `navigation_path/2` already allows). If it is missing or blank, return `nil`.
3. **Local predicate on `p`.** The host configured it, but check it defensively because the router opt has never been locality-checked:
   - `p` starts with exactly one `/`. It is not `//` and not `/\`, and it contains no `\` anywhere.
   - `URI.new(p)` returns `{:ok, %URI{scheme: nil, host: nil, userinfo: nil}}`.
   - `p` has no ASCII control or whitespace bytes (`<<c>>` with `c < 0x21` or `c == 0x7F`).

   If any check fails, return `nil`. A host with an off-origin operator, such as `https://ops.example.com/mail`, keeps its static nav link and simply gets no return affordance. That path still works and fails safe; the router contract is not tightened.
4. **Tenant id:** `t` must be valid UTF-8, 1–255 bytes (the `tenant_id` column is `:string`), and contain no control characters (C0, DEL, C1) and no leading or trailing whitespace. Otherwise return `nil`. Do **not** check authorization here: Preview has no actor, and must not get one.
5. **Build:** `uri = URI.parse(p)`, then set `query = uri.query |> URI.decode_query() |> Map.put("tenant_id", t) |> URI.encode_query()`. Keep the host path and fragment verbatim and output `URI.to_string(uri)`. Because `t` is percent-encoded as a query *value*, input such as `a&view=x` or `#frag` cannot add keys or change the path.
6. **Never** call `String.to_atom`, never log `t`, never put it in telemetry, never flash it, and never render it as text (see 2.6).

A failed validation **drops the params silently** and shows the direct-entry fallback. There is no error banner, so tampered input is never reflected back and stray old links cause no alarm.

### 2.4 Authorization: enforced at the destination, through the existing tenancy seam

Preview cannot authorize anything. It has no actor, and giving it one would widen the whitelist, which is forbidden. A signed token minted by the operator does not help either: the landing page must re-authorize anyway, because the grant may be stale. So the guarantee is placed where authority already lives:

> **On operator and Inbound `handle_params`, a URL `tenant_id` is honored only if it is a member of `tenant_options`, the actor-scoped list from `MailglassAdmin.Operator.Tenants.list_tenants(operator_actor, …)`, which goes through `Mailglass.Tenancy.scope/2`.** A non-member gets `:select_required` plus one notice. This applies to every arrival, not just to return links. A check keyed on a "came from Preview" marker would be security theater, because an attacker would just drop the marker.

- **Copy:** "The Account in this link isn't available. Choose an Account." The same wording covers both "doesn't exist" and "not yours", so it gives no enumeration oracle.
- **The tenant list read is unavailable:** fail closed. Show the existing read-unavailable/select state and do not honor the id.
- **Consequences:**
  - An Account with no activity, which is therefore absent from the list (Helios is "empty by absence"), can no longer be deep-linked. This matches the locked statement that "Helios … is not assumed selectable".
  - The minting rule (2.2) already refuses to mint return links for non-members, so the defence holds on both ends.
- This is **the only behavior change outside Preview**. See §4, "Strategic fork".

### 2.5 Keeping the context while the user moves around Preview (custom mounts)

The return context lives **only in the URL**. Every Preview-internal URL builder appends `ReturnContext.query_pairs(ctx)` (an empty list when the context is nil): sidebar scenario patches, `build_capture_url`, the gallery link and error-card links. The theme round-trip already keeps the params, and its sanitizer accepts any path under the mount. All builders already start from `@mount_path` (the `MountPathHook`), so custom prefixes such as `/admin/preview` or `/support/mail/preview` work with no new logic. This is what makes reload, share and Back faithful. A socket-only assign would be lost on the theme remount and on reload.

### 2.6 Affordance and fallback copy (brand voice, ux-writing)

| State | What renders in the Preview Account-context slot (UXF-09 compact control) |
|---|---|
| **Valid return context** | A link at the top of the Preview nav column: `← Back to Deliveries` (or `Back to Health` / `Back to Inbound`). Its `href` is the derived destination. The visible text names the **surface, not the Account**: Preview cannot verify or label the Account, and naming it next to sample data would suggest the samples belong to it. The Health/Deliveries/Inbound nav items also take the same derived `tenant_id`, so the whole nav stays on one Account. |
| **Direct entry, invalid, or tampered** | No back link. The quiet slot text reads **"Previews use sample data and aren't tied to an Account."** The configured nav links render as today; the Account is chosen on arrival. |
| **Accessibility** | A real `<a>` with the accessible name "Back to Deliveries", a ≥44px target and visible focus, first in reading order inside the nav landmark. Do not use `history.back()`: on direct entry it can leave the app entirely, and it makes the link's behavior depend on the referrer. |

**Browser Back is unaffected.** The return link is ordinary forward navigation. Back from Preview still restores the exact operator URL with its filters, page and quick view. The return link deliberately restores only the surface and Account; the filters are a job for Back.

### 2.7 Public surface (flag)

- **No new router option and no new behaviour callback.** Everything is derived from the existing `:navigation` paths plus the existing `tenant_id` URL key. The host config contract does not change.
- **The new query params are internal.** Mark them `@moduledoc false` and leave them out of the docs, so hosts are not promised that their own pages can link into Preview with return context. Promote them later if someone asks. Adding them later is easy; removing them would be hard.
- **Doc-only change:** the admin guide should say that Preview's `:navigation` paths must point at the operator surfaces (`/ops/mail`, `/ops/mail?view=deliveries`, `/ops/mail/inbound`) for return-to-Account to work. A login hop belongs in the host's auth plug (the phx.gen.auth `user_return_to` idiom), not inside the nav path.
- **Behavior change (operator):** URL `tenant_id` membership (2.4). Record it in the CHANGELOG under the admin package.
- **Demo host:** change the Preview `navigation` to the plain `/ops/mail…` paths. Add a small `/ops` pipeline plug that sends an unauthenticated GET to `/demo/login?return_to=<current_path>`; the existing `safe_return_to/1` already handles that. This replaces the static Northstar strings, which would otherwise keep sending everyone to Northstar.

## 3. Rejected alternatives

| Alternative | Why rejected |
|---|---|
| Full `?return_to=<url>` validated against an allowlist (Rails `url_from`, Django `url_has_allowed_host_and_scheme`) | Puts a parser-confusion attack surface (`/\`, `%2F%2F`, `\t//`, mixed encodings) on a boundary that needs none, and it still needs the same allowlist. A derived reference is strictly smaller. |
| Session `user_return_to` (phx.gen.auth / Laravel `intended()`) | LiveView cannot write the Plug session without a controller hop. It would widen the Preview session whitelist (forbidden), act as global per-browser state across tabs (forbidden "global current-Account"), and go stale. |
| Signed token (`Phoenix.Token`) carrying the Account | Signing proves the operator minted the link, not that the grant is still valid. The destination must re-authorize anyway. It adds key handling and stale-token UX for no security gain. |
| `history.back()` / `Referer` | Breaks on direct entry, can leave the app, the referrer is stripped by `strict-origin-when-cross-origin`, and the destination can't be tested. |
| New router option such as `:return_paths` or `return_to: {M, F, A}` (cf. Oban Web `:logo_path`) | `:navigation` already is the host-approved path set. A second option would duplicate it and grow the stable contract. |
| Showing the Account label in Preview ("Back to Northstar Logistics") | Preview has no `account_labels` and no actor. It would echo unverified URL text and suggest sample data belongs to the Account (UXF-09). |
| Preview authorizes the Account itself | Needs an actor in the Preview session, which widens the whitelist (locked out). |
| Membership check only on arrivals marked as return links | Bypassed by deleting the marker. Authority must not depend on how the user navigated. |
| Prefix allowlist (`starts_with?(path, nav_path)`) | Sibling-prefix confusion (`/ops/mailx`). Exact derivation avoids the comparison entirely. |
| Keep context only in a socket assign | Lost on the theme-toggle remount, reload and share. The URL must be the carrier. |

## 4. Adversarial pass (attacking the design above)

1. **"`return_tenant_id` is attacker-controlled and flows into an href."** It is only ever a percent-encoded query *value* in a host-configured path, and HEEx attribute-escapes it as well. *Test:* `a&view=x`, `#x`, `%00`, `"><script>`, RTL override `U+202E`, a 256-byte value.
2. **"A malicious host config path (`//evil.com`) becomes an open redirect."** It is host-authored, so it is not an open redirect in CWE-601 terms. Step 3 refuses it anyway and the affordance simply disappears. *Test* the predicate against `//x`, `/\x`, `\\x`, `https://x`, `javascript:x`, ` /x`, `/x\n`, `mailto:`.
3. **"An attacker crafts a Preview link with a victim's Account to phish an operator into viewing a foreign Account."** The link lands on the operator surface, and the membership check (2.4) refuses non-members with an enumeration-neutral notice. **Found and fixed:** before this design, a direct `?tenant_id=` was honored without membership (`tenant_state/3` catch-all). Without 2.4, UXF-10's "unauthorized targets must not be honored" would be false for *any* link, so 2.4 is required, not optional.
4. **"Membership becomes an existence oracle."** The same copy and the same state for nonexistent and unauthorized ids. *Test* both paths render identical HTML in the notice region.
5. **"Fail-open when the tenant list read fails."** Fixed: fail closed (2.4).
6. **"Params lost on internal patch, then Back to the wrong place."** Fixed by URL threading (2.5). *Connected test:* patch scenario, change width, toggle theme (full remount), and the back href stays identical.
7. **"Telemetry/log leak."** `tenant_id` is an id, not PII, but the rule is still never to log or emit the raw param. A validation miss emits nothing.
8. **"Referer leaks tenant id to email assets loaded in the Preview iframe."** Phoenix `put_secure_browser_headers` sets `referrer-policy: strict-origin-when-cross-origin`, so cross-origin requests see only the origin. Operator URLs already carry the id, so this is no worse than today. Verify the header in the demo endpoint.
9. **"Atom exhaustion via `return_surface`."** String compare against a closed set, never `to_atom`. *Test* with a 10k-char surface.
10. **"Collision with the theme controller's `return_to`."** Distinct names. The theme sanitizer keeps our params because the path stays under the mount. *Test* the round-trip.
11. **"Preview rendering now depends on Account."** `ReturnContext` is consulted only by nav rendering. *Test:* the rendered email frame HTML is byte-identical with and without return params (independent rendering).
12. **Pre-existing finding (not UXF-10 scope, worth a todo):** `ThemeController.sanitized_return_to/2` uses `String.starts_with?(path, mount_path)`, which accepts the sibling prefix `/dev/mailbox/...` (same-origin, low severity). Prefer a segment-boundary check: `path == mount or starts_with?(path, mount <> "/")`.

## 5. Test matrix (cheapest proof per row; admin lanes)

| # | Kind | Case | Expect |
|---|---|---|---|
| T1 | unit (pure) | `resolve/2` table: valid overview, deliveries (query merged with `view=deliveries`), inbound | exact href; `tenant_id` replaced, not duplicated |
| T2 | unit | surface `admin`, `Overview`, `""`, list, 10k chars | `nil` |
| T3 | unit | tenant id: `""`, 256 bytes, `\n`, `\u0000`, `\u0085`, invalid UTF-8, leading space, list/map | `nil` |
| T4 | unit | injection values `a&view=x`, `#f`, `"><svg>`, `U+202E` | `nil` (control) or encoded with exactly one `tenant_id` key and the path unchanged |
| T5 | unit | host path predicate: `//e`, `/\e`, `\\e`, `https://e/x`, `javascript:x`, `/x\t`, `mailto:a` | `nil` |
| T6 | seeded generative (no new dep: `:rand.seed` loop, about 2k cases; `stream_data` is core-only and is **not** added to admin) | random bytes for both params | `nil` or an href satisfying: starts with the configured path, `URI.parse(href).host == nil`, exactly one `tenant_id`, which round-trips to the input |
| T7 | connected LiveView | operator Deliveries `?tenant_id=northstar` | Preview nav href has `return_surface=deliveries&return_tenant_id=northstar` |
| T8 | connected | operator `:select_required` / no tenant | Preview href unchanged (no return params) |
| T9 | connected, **custom mounts** | Preview at `/admin/preview`, operator at `/support/mail` (test router) | back href = `/support/mail?view=deliveries&tenant_id=…`; internal patches stay under `/admin/preview` with params kept |
| T10 | connected | param persistence: sidebar scenario patch, width change, theme toggle via `/theme/dark?return_to=…` then follow redirect | back href identical after each step |
| T11 | connected | **direct entry** `/dev/mail` | no back link; fallback text present; nav = configured static paths |
| T12 | connected | **tampered** `?return_surface=evil` / host path not local | same DOM as T11 |
| T13 | connected | **unauthorized target**: operator `?tenant_id=foreign` with a tenancy stub scoping the actor to `northstar` | `:select_required` and notice; no foreign data read; no PubSub subscription to the foreign topic |
| T14 | connected | nonexistent vs unauthorized | identical notice region (no oracle) |
| T15 | connected | tenant list read unavailable and URL id present | fails closed |
| T16 | connected | Preview frame HTML with and without return params | identical (independent rendering) |
| T17 | contract | `__preview_session__/2` key set unchanged (snapshot of keys) | no whitelist widening |
| T18 | Playwright (demo, existing browser lane) | Ops Deliveries (Fjordline) → Preview → Back to Deliveries | lands on Fjordline Deliveries; Browser Back from Preview restores the exact prior URL. Proves Fjordline, so not static Northstar. |
| T19 | mutation proof (D-52) | remove the membership check / the control-char check / the local predicate | T13 / T3 / T5 go red |

Retained Storybook scenarios for the area: the Preview nav column in the "return context" and "direct entry" states, using the production component.

## 6. Sources

- OWASP, *Unvalidated Redirects and Forwards Cheat Sheet* ("map to an ID, don't accept the URL"; allowlist; avoid user input): https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html
- MITRE CWE-601, URL Redirection to Untrusted Site: https://cwe.mitre.org/data/definitions/601.html
- Phoenix LiveView `live_session` docs: "Redirecting between `live_session`s will always force a full page reload" (local `deps/phoenix_live_view/lib/phoenix_live_view/router.ex:141-142`); https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3
- phx.gen.auth `maybe_store_return_to/1` → session `:user_return_to` for GET (generated `UserAuth`): https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- Rails `url_from` / `redirect_back_or_to` / `raise_on_open_redirects`: https://api.rubyonrails.org/classes/ActionController/Redirecting.html
- Django `url_has_allowed_host_and_scheme` (rejects leading control chars, backslash/scheme-relative tricks): https://github.com/django/django/blob/main/django/utils/http.py
- Laravel `redirect()->intended()` (session `url.intended`): https://laravel.com/docs/redirects
- Oban Web `:logo_path` (host-configured static link out of the dashboard; validated only as a non-empty binary): local `oban_web-2.12.6` `lib/oban/web/router.ex:151,284-290`
- Phoenix LiveDashboard `:home_app` is a name/version display, **not** a back link (verified locally: `phoenix_live_dashboard/lib/phoenix/live_dashboard/router.ex:33`). The precedent is cited as negative.
- Sidekiq Web `Sidekiq::Web.app_url` "Back to App" (static host config): https://github.com/sidekiq/sidekiq/wiki/Monitoring
- Repo: `router.ex`, `mount_path.ex`, `mount_path_hook.ex`, `preview_live.ex:730-850`, `controllers/theme_controller.ex`, `operator_live.ex:160-243,1199-1203`, `inbound_live.ex:1053-1056`, `lib/mailglass/operator/{tenants,deliveries}.ex`, `reference/demo_app/lib/mailglass_demo_web/router.ex`.
