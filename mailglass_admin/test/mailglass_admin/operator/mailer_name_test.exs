defmodule MailglassAdmin.Operator.MailerNameTest do
  @moduledoc """
  BRADM-05 (D-13, C-9): the plain mailer name is derived only from the stored
  `Delivery.mailable` text, in both shapes the database holds, and it never creates an atom.

  Production persistence writes the module alone (`inspect(rendered.mailable)`), while seeded
  data carries `Module.function`. Both must read as a plain name, and neither may be
  invented: a nil or blank value has no name.
  """

  # The atom-count checks read a VM-wide counter, so this module runs alone.
  use ExUnit.Case, async: false

  alias MailglassAdmin.Operator.MailerName

  @source Path.expand("../../../lib/mailglass_admin/operator/mailer_name.ex", __DIR__)

  describe "plain_name/1 over the two stored shapes" do
    test "Module.function reads as the humanized function name" do
      assert MailerName.plain_name("MyApp.AccountMailer.password_reset") == "Password reset"

      assert MailerName.plain_name("MailglassAdmin.Fixtures.WelcomeMailer.welcome_default") ==
               "Welcome default"

      assert MailerName.plain_name("MyApp.AccountMailer.confirm") == "Confirm"
    end

    test "a module alone (what production stores) reads as the humanized module leaf" do
      assert MailerName.plain_name("MyApp.AccountMailer") == "Account mailer"
      assert MailerName.plain_name("Mailglass.Example.BrowserMailer") == "Browser mailer"
      assert MailerName.plain_name("Mailer") == "Mailer"
      assert MailerName.plain_name("MyApp.HTTPNotifier") == "Http notifier"
    end

    test "an Elixir. prefix, a trailing arity and trailing dots are stripped" do
      assert MailerName.plain_name("Elixir.MyApp.AccountMailer") == "Account mailer"
      assert MailerName.plain_name("MyApp.AccountMailer.password_reset/1") == "Password reset"
      assert MailerName.plain_name("MyApp.AccountMailer.password_reset/12") == "Password reset"
      assert MailerName.plain_name("MyApp.AccountMailer.") == "Account mailer"
      assert MailerName.plain_name("MyApp.AccountMailer...") == "Account mailer"
      assert MailerName.plain_name("Elixir.MyApp.AccountMailer.welcome/2") == "Welcome"
    end

    test "surrounding whitespace is ignored" do
      assert MailerName.plain_name("  MyApp.AccountMailer  ") == "Account mailer"
      assert MailerName.plain_name("\tMyApp.AccountMailer.password_reset\n") == "Password reset"
    end

    test "a lower-case name with no module path keeps its single word" do
      assert MailerName.plain_name("accountmailer") == "Accountmailer"
      assert MailerName.plain_name("password_reset") == "Password reset"
    end

    test "non-ASCII characters pass through unchanged" do
      assert MailerName.plain_name("MyApp.ÜberMailer") == "Über mailer"

      assert MailerName.plain_name("MyApp.ÜberMailer.passwort_zurücksetzen") ==
               "Passwort zurücksetzen"

      assert MailerName.plain_name("MyApp.メーラー") == "メーラー"
    end
  end

  describe "plain_name/1 never invents a name" do
    test "nil and blank values have no name" do
      assert MailerName.plain_name(nil) == nil
      assert MailerName.plain_name("") == nil
      assert MailerName.plain_name("   ") == nil
      assert MailerName.plain_name("\n\t") == nil
    end

    test "a value with nothing to name has no name" do
      # Nothing here is a name: no letter or digit survives the derivation.
      for odd <- [".", "...", "/1", ".../2", "_", "__", "._.", "-", "/"] do
        assert MailerName.plain_name(odd) == nil,
               "#{inspect(odd)} produced #{inspect(MailerName.plain_name(odd))}"
      end

      # The module is called Elixir, so that is the only name there is.
      assert MailerName.plain_name("Elixir.") == "Elixir"
    end

    test "a value that is not text has no name, and bytes that are not UTF-8 have none" do
      assert MailerName.plain_name(<<0xFF, 0xFE, 0xFD>>) == nil
      assert MailerName.plain_name("MyApp.Mailer" <> <<0xFF>>) == nil
      assert MailerName.plain_name(:an_atom) == nil
      assert MailerName.plain_name(42) == nil
    end

    test "every input returns text or nil and never raises" do
      :rand.seed(:exsss, {182, 4, 5})

      for _ <- 1..500 do
        value = random_text()
        result = MailerName.plain_name(value)
        assert is_nil(result) or is_binary(result), "#{inspect(value)} -> #{inspect(result)}"
        assert is_nil(result) or String.valid?(result)
        assert is_nil(MailerName.identity(value)) or is_binary(MailerName.identity(value))
      end

      long = String.duplicate("a_", 5_000) <> "Mailer"
      assert is_binary(MailerName.plain_name(long))
    end
  end

  describe "identity/1" do
    test "is the trimmed stored value, shown in full" do
      assert MailerName.identity("MyApp.AccountMailer.password_reset") ==
               "MyApp.AccountMailer.password_reset"

      assert MailerName.identity("  MyApp.AccountMailer  ") == "MyApp.AccountMailer"
      assert MailerName.identity("Elixir.MyApp.AccountMailer") == "Elixir.MyApp.AccountMailer"
    end

    test "is nil for nil, blank and values that are not text" do
      assert MailerName.identity(nil) == nil
      assert MailerName.identity("") == nil
      assert MailerName.identity("   ") == nil
      assert MailerName.identity(:an_atom) == nil
      assert MailerName.identity(<<0xFF>>) == nil
    end
  end

  describe "no atoms are created from a stored value (T-182-09)" do
    test "the source never calls an atom constructor, logs or emits telemetry" do
      source = File.read!(@source)

      refute source =~ "String.to_atom"
      refute source =~ "String.to_existing_atom"
      refute source =~ "binary_to_atom"
      refute source =~ "Logger"
      refute source =~ ":telemetry"
    end

    test "the VM atom count is unchanged across 1000 calls with random strings" do
      :rand.seed(:exsss, {182, 4, 6})
      values = for _ <- 1..1000, do: random_text()

      # Warm up: loading a module the first time can create atoms of its own.
      for value <- Enum.take(values, 20), do: MailerName.plain_name(value)

      before_count = :erlang.system_info(:atom_count)
      for value <- values, do: {MailerName.plain_name(value), MailerName.identity(value)}
      after_count = :erlang.system_info(:atom_count)

      # Another process may create a handful of atoms while this runs; a per-input leak
      # would add about a thousand, as the control below shows.
      assert after_count - before_count <= 8,
             "plain_name/1 and identity/1 created #{after_count - before_count} atoms"
    end

    test "the instrument sees atom creation: a control that does create atoms raises the count" do
      :rand.seed(:exsss, {182, 4, 7})
      values = for _ <- 1..200, do: "control_" <> random_text()

      before_count = :erlang.system_info(:atom_count)
      _atoms = for value <- values, do: String.to_atom(value)
      after_count = :erlang.system_info(:atom_count)

      assert after_count - before_count >= 150
    end
  end

  # Random text over a small alphabet that includes the characters the derivation treats
  # specially (dots, slashes, underscores, digits, upper and lower case, non-ASCII), so the
  # inputs reach every branch.
  defp random_text do
    alphabet = ~c"abcXYZ019_./ \tÜé東"
    count = :rand.uniform(40) - 1

    for _ <- 1..count//1, into: "" do
      <<Enum.at(alphabet, :rand.uniform(length(alphabet)) - 1)::utf8>>
    end
  end
end
