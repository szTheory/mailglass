defmodule Mailglass.Scripts.BrandNameLintTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @script Path.join(@repo_root, "scripts/brand_name_lint.exs")

  setup_all do
    Application.put_env(:mailglass, :script_library_mode, true)
    Code.require_file(@script)
    :ok
  end

  defp findings(text, format \\ :markdown, path \\ "fixture.md") do
    lint(:scan_text, [path, text, format])
  end

  defp lint(function, args), do: apply(Mailglass.BrandNameLint, function, args)

  test "rejects headings, sentence starts and endings, possessives, split names, and platform claims" do
    text = """
    # Mailglass
    Mailglass is a library.
    This is Mailglass.
    Mailglass's package.
    Mail Glass is two words.
    MailGlass has mixed case.
    MAILGLASS is a shout.
    It is the mailglass platform.
    Mailglass-powered integrations.
    mAiLgLaSs is another capitalization variant.
    """

    matches = findings(text) |> Enum.map(& &1.match)
    assert length(matches) == 10
    assert "Mailglass" in matches
    assert "mAiLgLaSs" in matches
    assert "Mail Glass" in matches
    assert "the mailglass platform" in matches
  end

  test "keeps lowercase names and structural API, wire, URL, and code spans clean" do
    text = """
    mailglass is lowercase at every sentence start.
    `Mailglass.Config` and Mailglass.Outbound remain module names.
    Mailglass.{Adapters, Message} remains an alias.
    ```elixir
    use Mailglass.Mailable
    ```
    <code>Mailglass&#46;Runtime</code>
    Mailglass-Mailable and X-Mailglass-Foo are wire headers.
    MAILGLASS.Admin.Router and mAiLgLaSs-MaIlAbLe remain structural identifiers.
    MAILGLASS_TIMEOUT remains an environment identifier.
    See https://hex.pm/packages/Mailglass for the package.
    <!-- Mailglass is a hidden comment. -->
    """

    assert findings(text) == []
  end

  test "detects accessible labels and HTML attributes while preserving API references" do
    html = ~s|<button aria-label="Mailglass sections">Open <code>Mailglass&#46;Runtime</code></button>|
    assert [%{match: "Mailglass", line: 1}] = findings(html, :heex, "fixture.heex")
  end

  test "reads literal source strings and moduledocs, including interpolated fragments, but ignores comments" do
    source = ~S|
    # MAILGLASS comment is not adopter prose
    @moduledoc """
    Mailglass documentation.
    ```elixir
    use Mailglass.Mailable
    ```
    """
    def message(name), do: "Mailglass #{name}"
    |

    found = findings(source, :source, "lib/example.ex")
    assert Enum.map(found, & &1.match) == ["Mailglass", "Mailglass"]
    assert Enum.map(found, & &1.line) == [4, 9]
  end

  test "scans text after an installer-template comment inside a string literal" do
    source = ~S|
    @snippet """
    # Mailglass admin routes
    Mailglass owns this route.
    """
    |

    assert Enum.map(findings(source, :source, "lib/template.ex"), &{&1.line, &1.match}) ==
             [{3, "Mailglass"}, {4, "Mailglass"}]
  end

  test "scans gettext message values and skips translator comments" do
    po = """
    # TRANSLATORS: MAILGLASS is an internal comment.
    msgid "Mailglass could not read this message"
    msgstr "mailglass message"
    """

    assert [%{match: "Mailglass", line: 2}] = findings(po, :gettext, "priv/gettext/default.po")
  end

  test "scans concatenated PO continuation lines in msgid and msgstr fields" do
    po = """
    msgid ""
    "Mailglass message id"
    msgstr ""
    "Translated Mailglass message"
    """

    assert Enum.map(findings(po, :gettext, "priv/gettext/default.po"), & &1.match) ==
             ["Mailglass", "Mailglass"]
  end

  test "the casing rewrite touches only scanner-confirmed prose and keeps structural tokens byte-stable" do
    source =
      "# Mailglass\nMailglass delivers Mailglass.Config; `MailGlass` stays code. " <>
        "Mailglass-Mailable is a wire header. Mail Glass works."

    assert "# mailglass\nmailglass delivers Mailglass.Config; `MailGlass` stays code. " <>
             "Mailglass-Mailable is a wire header. mailglass works." ==
             lint(:lowercase_lines, [source, [1, 2], :markdown])
  end

  test "multiline inline code stays masked during both scanning and lowercase rewrites" do
    text = "Mailglass is the prose name.\n`deps: [\nMailglass\n]`"

    assert Enum.map(findings(text), &{&1.line, &1.match}) == [{1, "Mailglass"}]

    assert "mailglass is the prose name.\n`deps: [\nMailglass\n]`" ==
             lint(:lowercase_lines, [text, [1, 2, 3, 4], :markdown])
  end

  test "the checked-in adopter corpus stays non-vacuous and all owner/history exceptions stay live" do
    inventory = lint(:inventory, [@repo_root])
    counts = Enum.frequencies_by(inventory, &elem(&1, 2))

    assert counts.root_docs >= 8
    assert counts.guides >= 10
    assert counts.admin_lib >= 25
    assert counts.inbound_lib >= 30
    assert counts.mix == 3

    assert {:ok, used} = lint(:validate_exceptions, [@repo_root])
    assert Enum.all?(used, fn {_path, count} -> count > 0 end)
    assert Enum.all?(lint(:exceptions, []), &(String.trim(&1.reason) != ""))
    assert Enum.all?(lint(:excluded_surfaces, []), fn {_scope, reason} -> reason != "" end)
  end

  test "fails closed when the configured inventory is absent" do
    assert {:error, {:inventory_below_floor, missing, _counts}} =
             lint(:scan_repo, [Path.join(System.tmp_dir!(), "absent-mailglass-root")])

    assert Enum.any?(missing, fn {surface, _min} -> surface == :guides end)
  end

end
