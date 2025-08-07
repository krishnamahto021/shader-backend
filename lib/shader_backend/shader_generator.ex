defmodule ShaderBackend.ShaderGenerator do
  @moduledoc """
  Generates WebGL shaders using LLM API
  """
  
  require Logger

  # You can use OpenAI, Gemini, or any other LLM API
  # This example uses OpenAI API format, but you can adapt it
  @api_url "https://api.openai.com/v1/chat/completions"
  
  def generate_shader(description) do
    Logger.info("🔧 Starting shader generation process")
    Logger.debug("Input description: \"#{description}\"")
    
    prompt = build_prompt(description)
    Logger.debug("Built prompt (#{String.length(prompt)} characters)")
    
    # Get API key from environment variable
    api_key = System.get_env("OPENAI_API_KEY") || ""
    
    if api_key == "" do
      Logger.warning("⚠️  No OPENAI_API_KEY environment variable found")
      Logger.info("💡 To use LLM generation, set OPENAI_API_KEY environment variable")
      # Return error when no API key is provided
      {:error, "No OpenAI API key configured. Please set the OPENAI_API_KEY environment variable."}
    else
      Logger.info("🤖 Making LLM API request...")
      Logger.debug("API key present: #{api_key}")
      
      case make_llm_request(prompt, api_key) do
        {:ok, shader_code} -> 
          Logger.info("✅ LLM request successful")
          {:ok, shader_code}
        {:error, reason} -> 
          Logger.error("❌ LLM request failed: #{reason}")
          # Return error instead of falling back to default shader
          {:error, reason}
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

    GEOMETRY SPECIFICATION:
    You MUST add a comment line "// GEOMETRY: [type]" right after the "// Vertex Shader" line to specify what 3D shape to render.
    Available geometry types: cube, sphere, plane, cylinder, torus
    Choose the geometry type that BEST matches the user's description:
    - cube: boxes, cubes, rectangular objects, buildings, dice, crystals
    - sphere: balls, planets, round objects, marbles, bubbles, orbs, glowing objects
    - plane: flat surfaces, ground, walls, screens, floors, mirrors, water, ocean, waves
    - cylinder: tubes, pipes, pillars, cans, bottles, logs, towers, columns
    - torus: donuts, rings, tires, bagels, hoops, portals, loops
    
    IMPORTANT: Analyze the user's description carefully and pick the geometry that makes the MOST SENSE for their request.

    Standard 3D Vertex Shader Template:
    // Vertex Shader
    // GEOMETRY: [choose appropriate type based on description]
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

    Fragment Shader Requirements:
    - MUST declare: precision mediump float;
    - MUST declare these uniforms if you use them: uniform float time; uniform vec2 resolution;
    - MUST use these varyings: varying vec3 vNormal; varying vec3 vPosition;
    - Use vNormal and vPosition for lighting and visual effects
    - The geometry will be automatically generated based on your GEOMETRY specification
    
    Example Fragment Shader structure:
    // Fragment Shader
    precision mediump float;
    uniform float time;
    uniform vec2 resolution;
    varying vec3 vNormal;
    varying vec3 vPosition;
    
    void main() {
      // Your shader logic here
      gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    """
  end

  defp make_llm_request(prompt, api_key) do
    Logger.debug("🌐 Preparing HTTP request to OpenAI API")
    
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    request_body = %{
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
    }
    
    body = Jason.encode!(request_body)
    Logger.debug("📝 Request body size: #{String.length(body)} bytes")
    Logger.debug("🎯 API URL: #{@api_url}")
    Logger.debug("⏱️  Request timeout: 30 seconds")

    start_time = System.monotonic_time(:millisecond)
    
    case HTTPoison.post(@api_url, body, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        Logger.info("✅ HTTP request completed successfully in #{duration}ms")
        Logger.debug("📥 Response body size: #{String.length(response_body)} bytes")
        
        case Jason.decode(response_body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => shader_code}} | _]} = decoded_response} ->
            Logger.info("🎨 Successfully extracted shader code from LLM response")
            Logger.debug("🔍 Response structure: #{inspect(Map.keys(decoded_response))}")
            Logger.debug("📊 Generated shader length: #{String.length(shader_code)} characters")
            # Return the raw shader code regardless of whether it's valid or not
            # Frontend will handle compilation errors and display them
            {:ok, shader_code}
          {:ok, unexpected_format} ->
            Logger.error("❌ Unexpected response format from LLM API")
            Logger.debug("🔍 Received format: #{inspect(unexpected_format)}")
            {:error, "Invalid response format from LLM. Raw response: #{inspect(unexpected_format)}"}
          {:error, json_error} ->
            Logger.error("❌ Failed to parse JSON response: #{inspect(json_error)}")
            Logger.debug("📄 Raw response body: #{String.slice(response_body, 0, 500)}...")
            {:error, "Failed to parse LLM response JSON. Raw response: #{String.slice(response_body, 0, 500)}"}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        Logger.error("❌ HTTP request failed with status #{status_code} in #{duration}ms")
        Logger.debug("📄 Error response body: #{String.slice(error_body, 0, 500)}...")
        {:error, "LLM API error (#{status_code}): #{error_body}"}
      
      {:error, %HTTPoison.Error{reason: reason}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        Logger.error("❌ Network error after #{duration}ms: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end


end
