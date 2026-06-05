defmodule MailglassAdmin.ComponentsTest do
  @moduledoc """
  Regression tests for the unified Components.status_badge/1 atom and
  Components.normalize_inbound_outcome/1 adapter.

  Covers all 24 atoms across the four frozen taxonomy tables from
  74-UI-SPEC.md: 14 outbound delivery statuses, 6 inbound message outcomes,
  4 timeline event markers, plus the normalize_inbound_outcome/1 adapter
  (Wave 0 Nyquist requirement per 76-VALIDATION.md DS-01).

  Each atom gets its own named test with three independent assertions
  (CSS class, hero-* icon, text label). No Enum.each or comprehensions over
  atom lists — per-atom named tests prevent the Pitfall-5 failure mode where
  a loop masks divergent atoms by stopping at the first failure.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Components

  describe "status_badge/1 — outbound delivery statuses (14 atoms)" do
    test "dispatched renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :dispatched, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Dispatched"
    end

    test "queued renders badge-primary + arrow-path icon" do
      html = render_component(&Components.status_badge/1, status: :queued, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-arrow-path"
      assert html =~ "Queued"
    end

    test "sent renders badge-primary + paper-airplane icon" do
      html = render_component(&Components.status_badge/1, status: :sent, size: :sm)
      assert html =~ "badge-primary"
      assert html =~ "hero-paper-airplane"
      assert html =~ "Sent"
    end

    test "delivered renders badge-success + check-circle icon" do
      html = render_component(&Components.status_badge/1, status: :delivered, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Delivered"
    end

    test "deferred renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :deferred, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "Deferred"
    end

    test "bounced renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :bounced, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Bounced"
    end

    test "failed renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :failed, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Failed"
    end

    test "rejected renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :rejected, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Rejected"
    end

    test "complained renders badge-error + exclamation-circle icon" do
      html = render_component(&Components.status_badge/1, status: :complained, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Complained"
    end

    test "unsubscribed renders badge-warning + bell-slash icon" do
      html = render_component(&Components.status_badge/1, status: :unsubscribed, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-bell-slash"
      assert html =~ "Unsubscribed"
    end

    test "opened renders badge-success + envelope-open icon" do
      html = render_component(&Components.status_badge/1, status: :opened, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-envelope-open"
      assert html =~ "Opened"
    end

    test "clicked renders badge-success + hand-thumb-up icon" do
      html = render_component(&Components.status_badge/1, status: :clicked, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-hand-thumb-up"
      assert html =~ "Clicked"
    end

    test "autoresponded renders badge-outline + arrow-uturn-left icon" do
      html = render_component(&Components.status_badge/1, status: :autoresponded, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-arrow-uturn-left"
      assert html =~ "Autoresponded"
    end

    test "unknown renders badge-outline + question-mark-circle icon" do
      html = render_component(&Components.status_badge/1, status: :unknown, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-question-mark-circle"
      assert html =~ "Unknown"
    end
  end

  describe "status_badge/1 — inbound message outcomes (6 atoms)" do
    test "accepted renders badge-success + check-circle icon" do
      html = render_component(&Components.status_badge/1, status: :accepted, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Accepted"
    end

    test "no_match renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :no_match, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "No match"
    end

    test "rejected (inbound) renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :rejected, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Rejected"
    end

    test "bounced (inbound) renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :bounced, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Bounced"
    end

    test "ignore renders badge-outline + minus-circle icon" do
      html = render_component(&Components.status_badge/1, status: :ignore, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-minus-circle"
      assert html =~ "Ignored"
    end

    test "failed_ingest renders badge-error + exclamation-circle icon" do
      html = render_component(&Components.status_badge/1, status: :failed_ingest, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-exclamation-circle"
      assert html =~ "Ingest failed"
    end
  end

  describe "status_badge/1 — timeline event markers (4 atoms)" do
    test "webhook_replay_requested renders badge-outline + arrow-path icon" do
      html = render_component(&Components.status_badge/1, status: :webhook_replay_requested, size: :sm)
      assert html =~ "badge-outline"
      assert html =~ "hero-arrow-path"
      assert html =~ "Replay requested"
    end

    test "webhook_replay_succeeded renders badge-success + check-circle icon (conflict resolution 4)" do
      html = render_component(&Components.status_badge/1, status: :webhook_replay_succeeded, size: :sm)
      assert html =~ "badge-success"
      assert html =~ "hero-check-circle"
      assert html =~ "Replay succeeded"
    end

    test "webhook_replay_failed renders badge-error + x-circle icon" do
      html = render_component(&Components.status_badge/1, status: :webhook_replay_failed, size: :sm)
      assert html =~ "badge-error"
      assert html =~ "hero-x-circle"
      assert html =~ "Replay failed"
    end

    test "reconciled renders badge-warning + exclamation-triangle icon" do
      html = render_component(&Components.status_badge/1, status: :reconciled, size: :sm)
      assert html =~ "badge-warning"
      assert html =~ "hero-exclamation-triangle"
      assert html =~ "Reconciled"
    end
  end

  describe "normalize_inbound_outcome/1" do
    test "maps :accept to :accepted" do
      assert Components.normalize_inbound_outcome(:accept) == :accepted
    end

    test "maps :reject to :rejected" do
      assert Components.normalize_inbound_outcome(:reject) == :rejected
    end

    test "maps :bounce to :bounced" do
      assert Components.normalize_inbound_outcome(:bounce) == :bounced
    end

    test "passes :no_match through unchanged" do
      assert Components.normalize_inbound_outcome(:no_match) == :no_match
    end

    test "passes :ignore through unchanged" do
      assert Components.normalize_inbound_outcome(:ignore) == :ignore
    end

    test "passes nil through unchanged" do
      assert Components.normalize_inbound_outcome(nil) == nil
    end
  end
end
