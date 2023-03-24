defmodule Soap.MixProject do
  use Mix.Project

  def project do
    [
      app: :soap,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        check: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp deps do
    [
      {:proximal, "~> 0.2"},
      {:decimal, "~> 2.0"},

      # only for dev
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
