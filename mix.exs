defmodule Populator.Mixfile do
  use Mix.Project

  def project do
    [app: :populator,
     version: "0.5.0",
     elixir: ">= 1.0.0",
     package: package(),
     deps: deps(),
     description: "Supervisor population control library",
     test_coverage: [tool: Populator.Helpers.Cover, verbose: false, ignored: []],
     aliases: aliases()]
  end

  defp package do
    [maintainers: ["Rubén Caro"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/rubencaro/populator"}]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev},
     {:credo, "~> 0.4", only: [:dev, :test]}]
  end

  defp aliases do
    [test: ["test --cover", "credo"]]
  end
end
