defmodule MailglassAdmin.Preview.CaptureMatrixTest do
  use ExUnit.Case, async: true

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
  alias MailglassAdmin.Preview.{CaptureMatrix, CaptureState}

  describe "build_matrix/2" do
    test "returns deterministic ordering with canonical scenario/width/theme/url fields" do
      discovery = [
        {HappyMailer, [welcome_enterprise: %{tier: :enterprise}, welcome_default: %{tier: :free}]}
      ]

      first =
        CaptureMatrix.build_matrix(discovery,
          base_path: "/dev/mail",
          widths: [1024, 375, 768],
          themes: [:dark, :light]
        )

      second =
        CaptureMatrix.build_matrix(discovery,
          base_path: "/dev/mail",
          widths: [1024, 375, 768],
          themes: [:dark, :light]
        )

      # deterministic ordering: same entries, same order, same bytes
      assert first.entries == second.entries
      assert :erlang.term_to_binary(first.entries) == :erlang.term_to_binary(second.entries)
      assert Enum.count(first.entries) == 12
      assert Enum.sort_by(first.entries, &CaptureState.sort_key/1) == first.entries

      assert Enum.all?(first.entries, fn %CaptureState{} = state ->
               state.scenario in [:welcome_default, :welcome_enterprise] and
                 state.width in [375, 768, 1024] and
                 state.theme in [:light, :dark] and
                 String.contains?(state.url, "?width=") and
                 String.contains?(state.url, "&theme=")
             end)
    end

    test "represents discovery errors and :no_previews as skipped metadata" do
      discovery = [
        {HappyMailer, [welcome_default: %{tier: :free}]},
        {StubMailer, :no_previews},
        {BrokenMailer, {:error, "preview_props raised"}}
      ]

      result = CaptureMatrix.build_matrix(discovery, base_path: "/dev/mail")

      assert Enum.count(result.entries) == 6
      assert %{mailable: StubMailer, reason: :no_previews, details: nil} in result.skipped

      assert Enum.any?(result.skipped, fn skipped ->
               skipped.mailable == BrokenMailer and skipped.reason == :discovery_error and
                 skipped.details =~ "preview_props"
             end)
    end
  end
end
