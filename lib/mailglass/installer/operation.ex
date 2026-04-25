defmodule Mailglass.Installer.Operation do
  @moduledoc """
  Typed operation contract used by the installer planner and apply engine.
  """

  @typedoc "Supported deterministic installer operation kinds."
  @type kind :: :create_file | :ensure_snippet | :ensure_block | :run_task

  @typedoc "Classified apply outcome for a single operation."
  @type status :: :create | :update | :unchanged | :conflict

  @type t :: %__MODULE__{
          kind: kind(),
          path: String.t() | nil,
          payload: term(),
          status: status() | nil,
          reason: term()
        }

  defstruct [:kind, :path, :payload, :status, :reason]
end
