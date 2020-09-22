defmodule ExLaunchpad.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_launchpad,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [:portmidi]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      applications: [:portmidi]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:typed_struct, "~> 0.2.0"},
      {:portmidi, path: "../../github/ex-portmidi/"}
    ]
  end
end
