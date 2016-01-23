defmodule Populator.Mixfile do
  use Mix.Project

  def project do
    [app: :populator,
     version: "0.5.0",
     elixir: "~> 1.0",
     package: package,
     deps: deps,
     description: "Supervisor population control library"]
  end

  defp deps do
    []
  end

  defp package do
    [contributors: ["Rubén Caro","Juan Miguel Mora"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/rubencaro/populator"}]
  end
end
