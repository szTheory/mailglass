defmodule Mailglass.GeneratedHost.HostTemplate do
  @moduledoc false

  @spec install!(Path.t(), String.t()) :: :ok
  def install!(host_root, schema) when is_binary(host_root) and is_binary(schema) do
    write!(host_root, "config/mailglass_generated_host.exs", config_source(schema))
    write!(host_root, "lib/generated_host/application.ex", application_source())
    write!(host_root, "lib/generated_host/repo.ex", repo_source())
    write!(host_root, "lib/generated_host/capture_store.ex", capture_store_source())
    write!(host_root, "lib/generated_host/capture_adapter.ex", capture_adapter_source())
    write!(host_root, "lib/generated_host/sample_mailable.ex", sample_mailable_source())
    write!(host_root, "lib/generated_host/proof.ex", proof_source())
    append_import!(host_root)
    :ok
  end

  defp write!(host_root, relative_path, content) do
    path = Path.join(host_root, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end

  defp config_source(schema) do
    """
    import Config

    config :mailglass,
      repo: GeneratedHost.Repo,
      schema: #{inspect(schema)},
      adapter: GeneratedHost.CaptureAdapter,
      async_adapter: :oban

    config :generated_host, Oban,
      repo: GeneratedHost.Repo,
      queues: [mailglass_outbound: 1]

    config :swoosh, :api_client, false
    """
  end

  defp append_import!(host_root) do
    path = Path.join(host_root, "config/config.exs")
    import_line = "\nimport_config \"mailglass_generated_host.exs\"\n"

    unless File.read!(path) =~ import_line do
      File.write!(path, import_line, [:append])
    end
  end

  defp proof_source do
    """
    defmodule GeneratedHost.Proof do
      @moduledoc false
      def marker, do: :generated_host
    end
    """
  end

  defp application_source do
    """
    defmodule GeneratedHost.Application do
      use Application

      @impl true
      def start(_type, _args) do
        children = [
          GeneratedHost.Repo,
          GeneratedHostWeb.Telemetry,
          {DNSCluster, query: Application.get_env(:generated_host, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: GeneratedHost.PubSub},
          GeneratedHostWeb.Endpoint,
          {GeneratedHost.CaptureStore, []},
          {Oban, Application.fetch_env!(:generated_host, Oban)}
        ]

        Supervisor.start_link(children, strategy: :one_for_one, name: GeneratedHost.Supervisor)
      end
    end
    """
  end

  defp repo_source do
    """
    defmodule GeneratedHost.Repo do
      use Ecto.Repo,
        otp_app: :generated_host,
        adapter: Ecto.Adapters.Postgres
    end
    """
  end

  defp capture_store_source do
    """
    defmodule GeneratedHost.CaptureStore do
      use Agent

      def start_link(_opts), do: Agent.start_link(fn -> [] end, name: __MODULE__)

      def record(input) when is_map(input) do
        Agent.get_and_update(__MODULE__, fn records ->
          sequence = length(records) + 1
          record = Map.put(input, :provider_message_id, "generated-host-\#{sequence}")
          {record, records ++ [record]}
        end)
      end

      def all, do: Agent.get(__MODULE__, & &1)
    end
    """
  end

  defp capture_adapter_source do
    """
    defmodule GeneratedHost.CaptureAdapter do
      @behaviour Mailglass.Adapter

      @impl true
      def deliver(%Mailglass.Message{} = message, _opts) do
        record = GeneratedHost.CaptureStore.record(canonical_input(message))

        {:ok,
         %{
           message_id: record.provider_message_id,
           provider_response: %{adapter: :generated_host_capture}
         }}
      end

      defp canonical_input(%Mailglass.Message{swoosh_email: email} = message) do
        %{
          recipient: email.to,
          from: email.from,
          reply_to: email.reply_to,
          subject: email.subject,
          headers: email.headers,
          html_body: email.html_body,
          text_body: email.text_body,
          attachments: Enum.map(email.attachments, &Map.from_struct/1),
          provider_options: Map.get(email.private, :provider_options),
          stream: message.stream,
          tags: message.tags,
          metadata: message.metadata
        }
      end
    end
    """
  end

  defp sample_mailable_source do
    """
    defmodule GeneratedHost.SampleMailable do
      use Mailglass.Mailable, stream: :transactional

      def message do
        new()
        |> Mailglass.Message.to({"Proof Recipient", "proof-recipient@example.test"})
        |> Mailglass.Message.from({"Generated Host", "sender@example.test"})
        |> Mailglass.Message.update_swoosh(&Swoosh.Email.reply_to(&1, {"Reply", "reply@example.test"}))
        |> Mailglass.Message.subject("Generated host parity")
        |> Mailglass.Message.header("X-Generated-Host", "parity")
        |> Mailglass.Message.html_body("<p>generated host parity</p>")
        |> Mailglass.Message.text_body("generated host parity")
        |> Mailglass.Message.put_tag("generated-host")
        |> Map.put(:metadata, %{proof: "async-parity"})
        |> Mailglass.Message.put_function(:message)
      end
    end
    """
  end
end
