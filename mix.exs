defmodule Populator.Mixfile do
  use Mix.Project

  def project do
    [app: :populator,
     version: "0.2.0",
     elixir: "~> 1.0",
     package: package,
     deps: deps,
     description: "Supervisor population control library"]
  end

  defp deps do
    [ {:meck, "~> 0.8.3", only: [:dev,:test]} ]
  end

  defp package do
    [contributors: ["Rubén Caro"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/rubencaro/populator"}]
  end
end
