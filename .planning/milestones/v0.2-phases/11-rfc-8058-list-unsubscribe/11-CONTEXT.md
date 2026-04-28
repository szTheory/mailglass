# Phase 11: RFC 8058 List-Unsubscribe Context

This document captures the architectural alignment and decisions reached during the `/gsd-discuss-phase 11` interview. It serves as the foundation for planning the phase.

## 1. GET Confirmation Page (Browser Fallback)

**Decision:** Hybrid approach.
- **Default:** A built-in, layout-free, standalone HEEx template using `Mailglass.Components` that looks like a clean, neutral SaaS hosted page.
- **Escape Hatch:** Provide a configuration hook (`config :mailglass, :compliance, unsubscribe_redirect: "/settings/unsubscribe"`) that intercepts the GET request via a 302 redirect.

**Rationale:** The built-in template provides "magical" day-one DX and instant RFC 8058 compliance without setup. It completely avoids the massive footgun of attempting to render inside the adopter's layout (which crashes when the core controller lacks the adopter's expected assigns like `@current_user`). The redirect provides a clean eject path for production teams who demand total brand control.

## 2. Exposing the `:unsubscribed` Event (State Sync)

**Decision:** Layered Lifecycle Architecture.
- **Primary (Transactional):** Provide a `Mailglass.Lifecycle` behaviour with a `handle_event(multi, event)` callback. The core controller passes its `Ecto.Multi` to this handler *before* executing the transaction.
- **Secondary (Observability):** Retain `Phoenix.PubSub` (`Projector.broadcast_delivery_updated/3`) strictly for transient, non-durable UI updates.

**Rationale:** Adopters need to safely sync the unsubscribe state to their own systems (e.g., marking a `User` as `opted_out`). The `Mailglass.Lifecycle` hook allows them to atomically update their tables or safely enqueue an Oban job in the exact same transaction. This eliminates the "dual-write" footgun and prevents blocking the lightning-fast RFC 8058 POST request with synchronous external API calls.

## 3. Cryptographic Token Generation & Secret Rotation

**Decision:** `Phoenix.Token` with a multi-secret escape hatch.
- **Default:** Use `Phoenix.Token` backed by `Mailglass.Tracking.endpoint()` with a hardcoded salt (`"mailglass_unsubscribe_v1"`).
- **Escape Hatch:** Provide `config :mailglass, :compliance, previous_secrets: [...]` which accepts a list of raw binary secrets. If `Phoenix.Token.verify` fails against the current endpoint, the library manually iterates over `previous_secrets` to verify.

**Rationale:** *Correction to STACK.md:* Breaking in-flight unsubscribe links upon a `secret_key_base` rotation is a deliverability catastrophe (angry users click "Mark as Spam"). This approach gives 90% of adopters zero-config setup using their existing Phoenix Endpoint. For the 10% who *must* roll their `secret_key_base` in an emergency, they drop their old secret into `previous_secrets`, and `mailglass` seamlessly verifies in-flight links without breaking a sweat or incurring spam penalties. (Rotating salts, as previously suggested, does not survive a secret change because the KDF derives the key from both).

## 4. URL Generation & Routing (Multi-Tenancy)

**Decision:** Config-driven base with multi-tenant override and a compile-time router macro.
- **Configuration:** Introduce `config :mailglass, :compliance, endpoint: MyAppWeb.Endpoint, host: "...", mount_path: "/mailglass/unsubscribe"`.
- **Macro:** `import Mailglass.Router` then mount with `mailglass_router_routes "/mailglass"`, generating `GET` + `POST` routes at `/mailglass/unsubscribe/:token` from the centralized mount-path contract.
- **Multi-Tenant Override:** Add an optional `compliance_host/1` callback to the `Mailglass.Tenancy` behaviour.
- **Generator:** `mix mailglass.gen.unsubscribe` outputs a strict, terminal-based installation checklist (config snippet + router macro + UAT test recipe) and copies zero files.

**Rationale:** This mirrors the proven `Mailglass.Tracking` pattern. It completely eliminates the Phoenix Router "divergent path" footgun, solves the multi-tenancy URL problem using existing project DNA, strictly adheres to the no-copy generation rule, and guarantees the URL can be generated deterministically outside the web request cycle (where there is no `conn`), while satisfying the `< 900 bytes` RFC 8058 constraint.
