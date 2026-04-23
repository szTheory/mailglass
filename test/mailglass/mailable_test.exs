defmodule Mailglass.MailableTest do
  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # Minimal test mailable — no tracking opts (stream: :transactional)
  # ---------------------------------------------------------------------------
  defmodule SampleMailer do
    use Mailglass.Mailable, stream: :transactional
  end

  # ---------------------------------------------------------------------------
  # Mailable with tracking opts (for Test 8)
  # ---------------------------------------------------------------------------
  defmodule TrackingEnabledMailer do
    use Mailglass.Mailable, stream: :operational, tracking: [opens: true, clicks: true]
  end

  # ---------------------------------------------------------------------------
  # Mailable that overrides deliver/2 (for Test 10)
  # ---------------------------------------------------------------------------
  defmodule OverridingMailer do
    use Mailglass.Mailable, stream: :transactional

    def deliver(msg, opts) do
      {:overridden, msg, opts}
    end
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  # Test 1: Module compiles cleanly
  test "Test 1: module using Mailglass.Mailable compiles cleanly" do
    assert Code.ensure_loaded?(SampleMailer)
  end

  # Test 2: Injected functions are exported
  test "Test 2: injected functions are exported" do
    assert function_exported?(SampleMailer, :new, 0)
    assert function_exported?(SampleMailer, :render, 3)
    assert function_exported?(SampleMailer, :deliver, 2)
    assert function_exported?(SampleMailer, :deliver_later, 2)
  end

  # Test 3: new/0 returns a %Mailglass.Message{} with correct fields
  test "Test 3: new/0 returns %Mailglass.Message{mailable: module, stream: :transactional}" do
    msg = SampleMailer.new()
    assert %Mailglass.Message{} = msg
    assert msg.mailable == SampleMailer
    assert msg.stream == :transactional
    # tenant_id from Tenancy.current/0 (may be nil in test env)
    assert msg.tenant_id == Mailglass.Tenancy.current()
  end

  # Test 4: __mailglass_opts__/0 reflects the use opts
  test "Test 4: __mailglass_opts__/0 reflects compile-time opts" do
    opts = SampleMailer.__mailglass_opts__()
    assert is_list(opts)
    assert Keyword.get(opts, :stream) == :transactional
  end

  # Test 5: __mailglass_mailable__/0 returns true
  test "Test 5: __mailglass_mailable__/0 returns true (admin discovery marker)" do
    assert SampleMailer.__mailglass_mailable__() == true
  end

  # Test 6: Module implements Mailglass.Mailable behaviour
  test "Test 6: module implements Mailglass.Mailable behaviour" do
    behaviours = SampleMailer.module_info(:attributes)[:behaviour] || []
    assert Mailglass.Mailable in behaviours
  end

  # Test 7: Injection line count ≤ 20 AST forms
  test "Test 7: __using__ macro injects ≤ 20 top-level AST forms (LIB-01 / LINT-05)" do
    # Verify all injected functions exist (proves injection happened)
    injected_fns = [
      {:new, 0},
      {:render, 3},
      {:deliver, 2},
      {:deliver_later, 2},
      {:__mailglass_opts__, 0},
      {:__mailglass_mailable__, 0}
    ]

    for {name, arity} <- injected_fns do
      assert function_exported?(SampleMailer, name, arity),
             "Expected #{name}/#{arity} to be injected by use Mailglass.Mailable"
    end

    # Count top-level forms by examining the macro body via Code.string_to_quoted.
    # We extract the quote block from the __using__ defmacro in the source and
    # count its top-level forms.
    #
    # Manual count of the quote bind_quoted block in mailable.ex:
    #  1. @behaviour Mailglass.Mailable
    #  2. @before_compile Mailglass.Mailable
    #  3. @mailglass_opts opts
    #  4. @compile {:no_warn_undefined, Mailglass.Outbound}
    #  5. import Swoosh.Email, except: [new: 0]
    #  6. import Mailglass.Components
    #  7. def __mailglass_opts__
    #  8. def new
    #  9. def render
    # 10. def deliver
    # 11. def deliver_later
    # 12. defoverridable
    # = 12 top-level forms (well within ≤20 budget)
    source = File.read!("lib/mailglass/mailable.ex")
    assert String.contains?(source, "defmacro __using__"),
           "Expected defmacro __using__ in mailable.ex"
    assert String.contains?(source, "quote bind_quoted:"),
           "Expected quote bind_quoted: in __using__"

    # Parse the full source and find the quote block inside __using__
    {:ok, ast} = Code.string_to_quoted(source)
    using_quote_forms = extract_using_quote_forms(ast)
    assert using_quote_forms <= 20,
           "Expected ≤20 top-level AST forms in __using__ quote block, got #{using_quote_forms}"
  end

  # Test 8: tracking opts are stored in @mailglass_opts
  test "Test 8: tracking opts stored in @mailglass_opts via __mailglass_opts__/0" do
    opts = TrackingEnabledMailer.__mailglass_opts__()
    tracking = Keyword.get(opts, :tracking, [])
    assert Keyword.get(tracking, :opens) == true
    assert Keyword.get(tracking, :clicks) == true
    assert Keyword.get(opts, :stream) == :operational
  end

  # Test 9: missing preview_props/0 produces no compiler warning (optional callback)
  test "Test 9: preview_props/0 is not required (optional callback)" do
    # If preview_props were a required callback, the compiler would warn.
    # We just verify it's NOT exported (adopter didn't define it).
    refute function_exported?(SampleMailer, :preview_props, 0)

    # Verify the @optional_callbacks declaration is on the behaviour via
    # behaviour_info/1 — the correct OTP API for reading optional callbacks.
    optional = Mailglass.Mailable.behaviour_info(:optional_callbacks)
    assert is_list(optional)
    assert {:preview_props, 0} in optional
  end

  # Test 10: defoverridable — module that redefines deliver/2 compiles without warnings
  test "Test 10: overriding deliver/2 compiles cleanly via defoverridable" do
    assert function_exported?(OverridingMailer, :deliver, 2)
    # The override should return {:overridden, _, _}
    msg = OverridingMailer.new()
    assert {:overridden, ^msg, []} = OverridingMailer.deliver(msg, [])
  end

  # Test 11: Mailable does NOT inject import Phoenix.Component
  test "Test 11: Phoenix.Component is NOT imported by use Mailglass.Mailable" do
    # Phoenix.Component exports component/2, attr/3, slot/3 etc.
    # If it were imported, these would be available on SampleMailer.
    refute function_exported?(SampleMailer, :component, 2),
           "Phoenix.Component must not be imported by use Mailglass.Mailable"

    # Verify the __using__ macro body does not reference Phoenix.Component
    # by parsing the source and checking only the quote block (not the moduledoc)
    source = File.read!("lib/mailglass/mailable.ex")
    {:ok, ast} = Code.string_to_quoted(source)
    using_body_str = extract_using_body_string(ast)
    refute String.contains?(using_body_str, "Phoenix.Component"),
           "use Mailglass.Mailable must not inject import Phoenix.Component"
  end

  # Test 12: deliver/2 delegates to Mailglass.Outbound.deliver/2
  @tag skip: "Plan 05 ships Mailglass.Outbound"
  test "Test 12: deliver/2 delegates to Mailglass.Outbound.deliver/2" do
    # Plan 05 ships Mailglass.Outbound — skip until then.
    # The injected deliver/2 body calls Mailglass.Outbound.deliver(msg, opts).
    :ok
  end

  # ---------------------------------------------------------------------------
  # Private helpers for AST inspection
  # ---------------------------------------------------------------------------

  # Walk the module AST and return the number of top-level forms inside the
  # `quote bind_quoted:` block of the `__using__` defmacro.
  defp extract_using_quote_forms(ast) do
    find_using_quote(ast)
    |> count_block_forms()
  end

  # Walk the module AST and return the string representation of the
  # `quote bind_quoted:` block inside the `__using__` defmacro.
  defp extract_using_body_string(ast) do
    find_using_quote(ast)
    |> Macro.to_string()
  end

  # Walk a top-level __block__ to find the defmacro __using__ node,
  # then return the quote bind_quoted block inside it.
  defp find_using_quote({:defmodule, _, [_name, [do: body]]}) do
    find_using_quote(body)
  end

  defp find_using_quote({:__block__, _, forms}) when is_list(forms) do
    Enum.find_value(forms, fn form -> find_using_quote(form) end)
  end

  defp find_using_quote({:defmacro, _, [{:__using__, _, _}, [do: body]]}) do
    # Found __using__/1 — find the quote bind_quoted: block inside
    find_quote_block(body)
  end

  defp find_using_quote(_), do: nil

  defp find_quote_block({:quote, _, [[bind_quoted: _] | _], _}), do: nil

  defp find_quote_block({:quote, _, [[bind_quoted: _], [do: body]]}) do
    body
  end

  defp find_quote_block({:quote, _meta, opts}) when is_list(opts) do
    case Keyword.get(opts, :do) do
      nil -> nil
      body -> body
    end
  end

  defp find_quote_block({:quote, _, [_bind_quoted, [do: body]]}) do
    body
  end

  defp find_quote_block({:__block__, _, forms}) do
    Enum.find_value(forms, fn form -> find_quote_block(form) end)
  end

  defp find_quote_block(_), do: nil

  defp count_block_forms(nil), do: 0
  defp count_block_forms({:__block__, _, forms}) when is_list(forms), do: length(forms)
  defp count_block_forms(_), do: 1
end
