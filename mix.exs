defmodule ShaderBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :shader_backend,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ShaderBackend.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:cors_plug, "~> 3.0"},
      {:httpoison, "~> 2.0"},
      {:dotenv, "~> 3.0"}
    ]
  end
end
