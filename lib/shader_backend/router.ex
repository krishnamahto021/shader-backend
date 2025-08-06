defmodule ShaderBackend.Router do
  use Plug.Router

  plug CORSPlug, origin: ["http://localhost:5173", "http://localhost:5174"]
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  post "/api/generate-shader" do
    # Use conn.body_params instead of manually reading/decoding
    case conn.body_params do
      %{"description" => description} when is_binary(description) ->
        case ShaderBackend.ShaderGenerator.generate_shader(description) do
          {:ok, shader_code} ->
            send_resp(conn, 200, Jason.encode!(%{
              "success" => true,
              "shaderCode" => shader_code
            }))
          
          {:error, reason} ->
            send_resp(conn, 400, Jason.encode!(%{
              "success" => false,
              "error" => reason
            }))
        end
      
      _ ->
        send_resp(conn, 400, Jason.encode!(%{
          "success" => false,
          "error" => "Invalid request format"
        }))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end