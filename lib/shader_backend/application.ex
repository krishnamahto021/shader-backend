defmodule ShaderBackend.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: ShaderBackend.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: ShaderBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
