defmodule ShaderBackend.ShaderGenerator do
  @moduledoc """
  Generates WebGL shaders using LLM API
  """

  # You can use OpenAI, Gemini, or any other LLM API
  # This example uses OpenAI API format, but you can adapt it
  @api_url "https://api.openai.com/v1/chat/completions"
  
  def generate_shader(description) do
    prompt = build_prompt(description)
    
    # Get API key from environment variable
    api_key = "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"
    
    if api_key == "" do
      # Return a default shader if no API key is provided
      {:ok, default_shader()}
    else
      case make_llm_request(prompt, api_key) do
        {:ok, shader_code} -> {:ok, shader_code}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp build_prompt(description) do
    """
    Generate a complete WebGL shader program for 3D rendering based on this description: #{description}

    CRITICAL Requirements:
    1. Create proper 3D vertex and fragment shaders that use matrices for 3D transformation
    2. The vertex shader MUST use these attributes: vec3 position, vec3 normal
    3. The vertex shader MUST use these uniforms: mat4 modelMatrix, mat4 viewMatrix, mat4 projectionMatrix, float time
    4. Apply proper 3D transformations using the matrices
    5. Include the vertex shader starting with "// Vertex Shader" and fragment shader starting with "// Fragment Shader"
    6. Make it visually interesting based on the description with proper lighting and colors
    7. Use time-based animation for rotation or color changes if appropriate
    8. Return ONLY the shader code, no explanations

    Standard 3D Vertex Shader Template:
    // Vertex Shader
    attribute vec3 position;
    attribute vec3 normal;
    uniform mat4 modelMatrix;
    uniform mat4 viewMatrix;
    uniform mat4 projectionMatrix;
    uniform float time;
    varying vec3 vNormal;
    varying vec3 vPosition;

    void main() {
      vec4 worldPosition = modelMatrix * vec4(position, 1.0);
      vPosition = worldPosition.xyz;
      vNormal = normalize((modelMatrix * vec4(normal, 0.0)).xyz);
      gl_Position = projectionMatrix * viewMatrix * worldPosition;
    }

    Create a fragment shader that uses vNormal and vPosition for lighting and visual effects.
    For cubes, spheres, and other 3D objects, use proper lighting calculations.
    """
  end

  defp make_llm_request(prompt, api_key) do
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      "model" => "gpt-3.5-turbo",
      "messages" => [
        %{
          "role" => "system",
          "content" => "You are a WebGL shader expert. Generate only shader code, no explanations."
        },
        %{
          "role" => "user",
          "content" => prompt
        }
      ],
      "temperature" => 0.7,
      "max_tokens" => 2000
    })

    case HTTPoison.post(@api_url, body, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => shader_code}} | _]}} ->
            {:ok, shader_code}
          _ ->
            {:error, "Invalid response format from LLM"}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "LLM API error (#{status_code}): #{error_body}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  defp default_shader do
    """
    // Vertex Shader
    attribute vec3 position;
    attribute vec3 normal;
    uniform mat4 modelMatrix;
    uniform mat4 viewMatrix;
    uniform mat4 projectionMatrix;
    uniform float time;
    varying vec3 vNormal;
    varying vec3 vPosition;

    void main() {
      vec4 worldPosition = modelMatrix * vec4(position, 1.0);
      vPosition = worldPosition.xyz;
      vNormal = normalize((modelMatrix * vec4(normal, 0.0)).xyz);
      gl_Position = projectionMatrix * viewMatrix * worldPosition;
    }

    // Fragment Shader
    precision mediump float;
    uniform float time;
    uniform vec2 resolution;
    varying vec3 vNormal;
    varying vec3 vPosition;
    
    void main() {
      // Simple lighting calculation
      vec3 lightDirection = normalize(vec3(1.0, 1.0, 1.0));
      float lightIntensity = max(dot(vNormal, lightDirection), 0.2);
      
      // Animated colors based on time and position
      vec3 baseColor = vec3(
        0.5 + 0.5 * sin(time + vPosition.x * 2.0),
        0.5 + 0.5 * cos(time * 1.3 + vPosition.y * 2.0),
        0.5 + 0.5 * sin(time * 0.7 + vPosition.z * 2.0)
      );
      
      // Apply lighting
      vec3 finalColor = baseColor * lightIntensity;
      
      gl_FragColor = vec4(finalColor, 1.0);
    }
    """
  end
end
