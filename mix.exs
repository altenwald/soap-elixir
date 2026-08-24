defmodule Soap.MixProject do
  use Mix.Project

  def project do
    [
      app: :soap,
      version: "0.1.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      # Some tests define their own Soap.Argument implementations to prove
      # the protocol is extensible from outside this library -- those need
      # to take effect without a project-wide recompile, which protocol
      # consolidation would otherwise prevent.
      consolidate_protocols: Mix.env() != :test,
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
      {:decimal, "~> 3.0"},

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
