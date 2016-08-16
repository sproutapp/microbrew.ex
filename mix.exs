defmodule Microbrew.Mixfile do
  use Mix.Project

  def project do
    [app: :microbrew,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     elixirc_paths: paths(Mix.env)]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications:
      [
        :amqp,
        :xmerl,
        :exjsx
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      { :pavlov, "~> 0.2.0", only: :test },
      { :amqp, "~> 0.1.0" },
      { :exjsx, "~> 3.1.0" },
      { :uuid, "~> 0.1.5" }
    ]
  end

  defp paths(:test), do: ["lib", "test/fixtures"]
  defp paths(_), do: ["lib"]
end
