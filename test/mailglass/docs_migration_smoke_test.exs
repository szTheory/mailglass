defmodule Mailglass.DocsMigrationSmokeTest do
  use Mailglass.MailerCase, async: false
  import Mailglass.DocsHelpers

  @canonical_guide_path "guides/upgrading-to-v1_0.md"
  @guide_path "guides/migration-from-swoosh.md"
  @production_checklist_path "guides/production-go-live-checklist.md"

  test "migration guide steps are accurate" do
    code = extract_block_after_heading(@guide_path, "End-to-End Example")
    assert code
    assert code =~ "assert {:ok, _delivery} = Mailglass.deliver(email)"
    assert {:ok, _quoted} = Code.string_to_quoted(code)
  end

  test "parity smoke executes the documented raw Swoosh example" do
    code = extract_block_after_heading(@guide_path, "End-to-End Example")

    assert code =~ "Swoosh.Email.text_body(\"Migration test\")"
    assert {{:ok, _delivery}, _bindings} = Code.eval_string(code, [], __ENV__)
  end

  test "canonical upgrade guide is the single upgrade authority" do
    canonical = File.read!(@canonical_guide_path)
    older = File.read!("guides/upgrading-from-v0_1.md")
    swoosh = File.read!(@guide_path)

    assert canonical =~ "canonical latest-`0.x` to `1.0` upgrade guide"

    assert canonical =~
             "| surface | replacement | warning channel | `--warnings-as-errors` impact | support-until version | proof artifact |"

    assert canonical =~ "Mailglass.Outbound.send/2"
    assert canonical =~ "Mailglass.deliver/2"
    assert canonical =~ "mix mailglass.upgrade.v0_2"
    assert canonical =~ "mailglass_admin"
    assert canonical =~ "mix verify.docs.migration"
    assert canonical =~ "mix verify.stability_contract"
    assert canonical =~ "Mailglass.Message.new/2"
    assert canonical =~ "release-blocking for strict adopters"

    assert older =~ "subordinate codemod reference"
    assert older =~ "upgrading-to-v1_0.md"

    assert swoosh =~ "subordinate raw-Swoosh migration reference"
    assert swoosh =~ "upgrading-to-v1_0.md"
  end

  test "upgrade guide examples stay on the supported codemod path" do
    canonical_blocks = extract_code_blocks(@canonical_guide_path)

    preferred_block =
      Enum.find(canonical_blocks, fn block ->
        String.contains?(block, "defmodule MyApp.WelcomeEmail") and
          String.contains?(block, "|> attach(\"path/to/guide.pdf\")")
      end)

    parity_block = Enum.find(canonical_blocks, &String.contains?(&1, "Migration test"))
    blocks = extract_code_blocks("guides/upgrading-from-v0_1.md")
    after_block = Enum.find(blocks, &String.contains?(&1, "# v0.2 Mailable"))
    escape_hatch_block = Enum.find(blocks, &String.contains?(&1, "put_provider_option"))

    assert preferred_block
    assert preferred_block =~ "|> attach(\"path/to/guide.pdf\")"
    assert {:ok, _quoted} = Code.string_to_quoted(preferred_block)

    assert parity_block
    assert parity_block =~ "assert {:ok, _delivery} = Mailglass.deliver(email)"
    assert {:ok, _quoted} = Code.string_to_quoted(parity_block)

    assert after_block
    assert after_block =~ "|> attach(\"path/to/guide.pdf\")"
    assert {:ok, _quoted} = Code.string_to_quoted(after_block)

    assert escape_hatch_block
    assert escape_hatch_block =~ "Mailglass.Message.update_swoosh"
    assert {:ok, _quoted} = Code.string_to_quoted(escape_hatch_block)
  end

  test "authoring guide examples stay on the native setter path" do
    blocks = extract_code_blocks("guides/authoring-mailables.md")
    primary_block = Enum.find(blocks, &String.contains?(&1, "defmodule MyApp.BillingMailer"))
    escape_hatch_block = Enum.find(blocks, &String.contains?(&1, "receipt_with_template"))

    assert primary_block
    assert primary_block =~ "|> put_tag(\"billing\")"
    refute primary_block =~ "Swoosh.Email.to"
    assert {:ok, _quoted} = Code.string_to_quoted(primary_block)

    assert escape_hatch_block
    assert escape_hatch_block =~ "Swoosh.Email.put_provider_option"
    assert {:ok, _quoted} = Code.string_to_quoted(escape_hatch_block)
  end

  @tag phase_150_task: "t150_04_02"
  test "production checklist uses the canonical durable adapter and readiness preflight" do
    block =
      extract_block_after_heading(
        @production_checklist_path,
        "Durable async readiness and final preflight"
      )

    checklist = File.read!(@production_checklist_path)

    assert block
    assert block =~ "async_adapter: :oban"
    assert block =~ "queues: [mailglass_outbound: 10]"
    assert checklist =~ "mix mailglass.preflight"
    assert checklist =~ "Repo, schema"
    assert checklist =~ "never emits configured secret values"
    refute block =~ "queues: [mailglass:"

    assert "mailglass_outbound" == Atom.to_string(Mailglass.Outbound.Worker.queue())
    assert {:ok, _quoted} = Code.string_to_quoted(block)
  end

  @tag phase_150_task: "t150_04_02"
  test "production readiness rejects an empty queue fixture" do
    if Code.ensure_loaded?(Oban) do
      Application.put_env(:mailglass, :async_adapter, :oban)
      start_supervised!({Oban, testing: :disabled, repo: Mailglass.TestRepo, queues: []})

      assert {:error,
              %Mailglass.ConfigError{
                type: :invalid,
                context: %{key: :async_adapter, reason_class: :canonical_queue_unavailable}
              }} = Mailglass.Config.production_readiness()
    else
      :skip
    end
  end

  @tag phase_150_task: "t150_04_02"
  test "production readiness rejects a wrong queue fixture" do
    if Code.ensure_loaded?(Oban) do
      Application.put_env(:mailglass, :async_adapter, :oban)

      start_supervised!(
        {Oban, testing: :disabled, repo: Mailglass.TestRepo, queues: [wrong_outbound_queue: 10]}
      )

      assert {:error,
              %Mailglass.ConfigError{
                type: :invalid,
                context: %{key: :async_adapter, reason_class: :canonical_queue_unavailable}
              }} = Mailglass.Config.production_readiness()
    else
      :skip
    end
  end
end
