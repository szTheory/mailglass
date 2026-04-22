defmodule Mailglass.Message do
  @moduledoc """
  A rendered or partially-rendered email message.

  `Mailglass.Message` wraps `%Swoosh.Email{}` and carries mailglass-specific
  metadata. It is the central data structure passed through the render pipeline
  and returned from `Mailglass.Renderer.render/2`.

  ## Domain Language

  A **Message** is the rendered form of a **Mailable** (a source-level definition).
  The Renderer populates `swoosh_email.html_body` and `swoosh_email.text_body`
  by transforming the HEEx template through the CSS inliner and plaintext extractor.

  Mailglass never bypasses Swoosh for content — it enriches the inner struct.
  The Message adds the metadata Swoosh doesn't model: which mailable built it,
  which tenant it belongs to, which stream it rides on, and adopter-supplied
  tags and metadata.

  ## Fields

  - `:swoosh_email` — the inner `%Swoosh.Email{}` struct. All email content
    (to, from, subject, html_body, text_body, headers, attachments) lives here.
  - `:mailable` — the adopter module that built this message (e.g.
    `MyApp.UserMailer`). Used for telemetry, the `Mailglass-Mailable` header,
    and preview auto-discovery.
  - `:tenant_id` — multi-tenant scope. Carried on every record (CORE-03, D-09
    project-level). `nil` in single-tenant mode.
  - `:stream` — message stream: `:transactional`, `:operational`, or `:bulk`.
    Auth and security emails must use `:transactional` (no tracking, per D-08
    project-level). Default: `:transactional`.
  - `:tags` — free-form string tags for filtering and analytics. Default: `[]`.
  - `:metadata` — adopter-supplied extras. **PII-free by convention** (not
    included in telemetry). Default: `%{}`.

  ## Examples

      iex> email = Swoosh.Email.new(subject: "Welcome")
      iex> msg = Mailglass.Message.new(email, mailable: MyApp.UserMailer)
      iex> msg.stream
      :transactional
      iex> msg.mailable
      MyApp.UserMailer

  """

  @type stream :: :transactional | :operational | :bulk

  @type t :: %__MODULE__{
          swoosh_email: Swoosh.Email.t(),
          mailable: module() | nil,
          tenant_id: String.t() | nil,
          stream: stream(),
          tags: [String.t()],
          metadata: %{atom() => term()}
        }

  defstruct [
    :swoosh_email,
    :mailable,
    :tenant_id,
    stream: :transactional,
    tags: [],
    metadata: %{}
  ]

  @doc """
  Creates a new `Mailglass.Message` wrapping the given `%Swoosh.Email{}`.

  ## Options

  - `:mailable` — the module that built this message
  - `:tenant_id` — tenant scope (`nil` in single-tenant mode)
  - `:stream` — `:transactional` (default), `:operational`, or `:bulk`
  - `:tags` — list of string tags
  - `:metadata` — map of adopter-supplied extras (PII-free)

  ## Examples

      iex> email = Swoosh.Email.new(subject: "Welcome")
      iex> msg = Mailglass.Message.new(email, mailable: MyApp.UserMailer)
      iex> msg.stream
      :transactional

  """
  @doc since: "0.1.0"
  @spec new(Swoosh.Email.t(), keyword()) :: t()
  def new(%Swoosh.Email{} = swoosh_email, opts \\ []) when is_list(opts) do
    %__MODULE__{
      swoosh_email: swoosh_email,
      mailable: Keyword.get(opts, :mailable),
      tenant_id: Keyword.get(opts, :tenant_id),
      stream: Keyword.get(opts, :stream, :transactional),
      tags: Keyword.get(opts, :tags, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
