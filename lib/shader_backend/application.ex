defmodule ShaderBackend.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    require Logger
    
    Logger.info("🚀 Starting ShaderBackend application...")
    
    children = [
      {Plug.Cowboy, scheme: :http, plug: ShaderBackend.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: ShaderBackend.Supervisor]
    
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✅ ShaderBackend server started successfully on port 4000")
        Logger.info("🌐 Server available at: http://localhost:4000")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("❌ Failed to start ShaderBackend server: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
