defmodule Populator.Mixfile do
  use Mix.Project

  def project do
    [app: :populator,
     version: "0.5.0",
     elixir: ">= 1.0.0",
     package: package(),
     deps: [{:ex_doc, ">= 0.0.0", only: :dev}],
     description: "Supervisor population control library"]
  end

  defp package do
    [maintainers: ["Rubén Caro"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/rubencaro/populator"}]
  end
end
