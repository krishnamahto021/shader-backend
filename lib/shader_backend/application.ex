defmodule ShaderBackend.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    require Logger
    
    # Load .env file
    Dotenv.load()
    
    Logger.info("🚀 Starting ShaderBackend application...")
    
    port = String.to_integer(System.get_env("PORT") || "4000")
    Logger.info("🔧 Using port: #{port}")
    
    children = [
      {Plug.Cowboy, scheme: :http, plug: ShaderBackend.Router, options: [port: port]}
    ]

    opts = [strategy: :one_for_one, name: ShaderBackend.Supervisor]
    
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✅ ShaderBackend server started successfully on port #{port}")
        Logger.info("🌐 Server available at: http://localhost:#{port}")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("❌ Failed to start ShaderBackend server: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
