defmodule Mailglass.Install.FirstPreviewSmokeTest do
  use ExUnit.Case, async: false

  import Mailglass.Test.InstallerFixtureHelpers

  @tag timeout: 300_000
  test "installer + first preview scaffold matches the release-day smoke contract" do
    started_ms = System.monotonic_time(:millisecond)
    fixture_root = new_fixture_root!("first-preview-smoke")
    run_install!(fixture_root, [])
    mailable_path = apply_minimal_mailable_scaffold!(fixture_root)

    router_path = Path.join(fixture_root, "lib/example_web/router.ex")
    layout_path = Path.join(fixture_root, "lib/example_web/components/layouts/mailglass.html.heex")
    workflow_path = Path.expand("../../../.github/workflows/post-publish-smoke.yml", __DIR__)

    assert File.read!(router_path) =~ ~s(mailglass_admin_routes "/mail")
    assert File.exists?(layout_path)
    assert File.exists?(mailable_path)

    workflow = File.read!(workflow_path)
    assert workflow =~ "Run mix mailglass.install"
    assert workflow =~ "Compile, fail on warnings"
    assert workflow =~ "Boot endpoint and curl /dev/mail/"
    assert workflow =~ "GET /dev/mail/ → HTTP ${STATUS}"

    elapsed_ms = System.monotonic_time(:millisecond) - started_ms
    assert elapsed_ms < 300_000
  end

  defp apply_minimal_mailable_scaffold!(fixture_root) do
    mailable_path = Path.join(fixture_root, "lib/example/mailers/first_preview_mail.ex")

    mailable_source = """
    defmodule Example.Mailers.FirstPreviewMail do
      use Mailglass.Mailable

      def deliverable(assigns) do
        %{subject: "First preview", body: inspect(assigns)}
      end
    end
    """

    File.mkdir_p!(Path.dirname(mailable_path))
    File.write!(mailable_path, mailable_source)

    mailable_path
  end
end
