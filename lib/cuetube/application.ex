defmodule Cuetube.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CuetubeWeb.Telemetry,
      Cuetube.Repo,
      {DNSCluster, query: Application.get_env(:cuetube, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cuetube.PubSub},
      # Start a worker by calling: Cuetube.Worker.start_link(arg)
      # {Cuetube.Worker, arg},
      # Start to serve requests, typically the last entry
      CuetubeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cuetube.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CuetubeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
