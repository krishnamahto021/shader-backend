defmodule ShaderBackend.Router do
  use Plug.Router
  require Logger

  plug CORSPlug, origin: ["http://localhost:5173", "http://localhost:5174"]
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  post "/api/generate-shader" do
    Logger.info("📨 Incoming POST request to /api/generate-shader")
    Logger.debug("Request body params: #{inspect(conn.body_params)}")
    Logger.debug("Request headers: #{inspect(conn.req_headers)}")
    
    # Use conn.body_params instead of manually reading/decoding
    case conn.body_params do
      %{"description" => description} when is_binary(description) ->
        Logger.info("🎨 Generating shader for description: \"#{String.slice(description, 0, 100)}#{if String.length(description) > 100, do: "...", else: ""}\"")
        
        case ShaderBackend.ShaderGenerator.generate_shader(description) do
          {:ok, shader_code} ->
            Logger.info("✅ Shader generated successfully (#{String.length(shader_code)} characters)")
            Logger.debug("Generated shader code preview: #{String.slice(shader_code, 0, 200)}...")
            
            response = Jason.encode!(%{
              "success" => true,
              "shaderCode" => shader_code
            })
            Logger.debug("📤 Sending successful response (#{String.length(response)} bytes)")
            send_resp(conn, 200, response)
          
          {:error, reason} ->
            Logger.error("❌ Shader generation failed: #{reason}")
            
            response = Jason.encode!(%{
              "success" => false,
              "error" => reason
            })
            Logger.debug("📤 Sending error response: #{response}")
            send_resp(conn, 400, response)
        end
      
      _ ->
        Logger.warning("⚠️  Invalid request format received")
        Logger.debug("Invalid body params: #{inspect(conn.body_params)}")
        
        response = Jason.encode!(%{
          "success" => false,
          "error" => "Invalid request format"
        })
        Logger.debug("📤 Sending invalid format response: #{response}")
        send_resp(conn, 400, response)
    end
  end

  match _ do
    Logger.warning("🔍 404 - Route not found: #{conn.method} #{conn.request_path}")
    Logger.debug("Available routes: POST /api/generate-shader")
    send_resp(conn, 404, "Not found")
  end
end