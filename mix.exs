defmodule Populator.Mixfile do
  use Mix.Project

  def project do
    [app: :populator,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [ {:meck, "~> 0.8.3", only: [:dev,:test]} ]
  end
end
