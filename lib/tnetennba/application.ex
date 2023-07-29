defmodule Tnetennba.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  def downloadS3Object(client, objectKey) do
    path = Path.relative_to_cwd(objectKey)

    case File.stat(path) do
      {:ok, _} ->
        Logger.info("Got #{objectKey} already, skipping s3 download.")
        {:ok}

      {:error, _} ->
        Logger.info("Don't got #{objectKey}, downloading from s3...")

        startTime = System.monotonic_time()

        case AWS.S3.get_object(client, "tnetennba-site-data", objectKey) do
          {:ok, _, %{body: body}} ->
            File.write(path, body)
            # Hard fail here if download fails
        end

        endTime = System.monotonic_time()
        diff = System.convert_time_unit(endTime - startTime, :native, :millisecond)

        Logger.info("Finished s3 download in #{diff}ms")

        {:ok}
    end
  end

  @impl true
  def start(_type, _args) do
    s3Client = AWS.Client.create("us-west-2")

    downloadS3Object(s3Client, "real_words.txt")
    downloadS3Object(s3Client, "filtered_dictionary.txt")

    children = [
      # Start the Telemetry supervisor
      TnetennbaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tnetennba.PubSub},
      # Start the Endpoint (http/https)
      TnetennbaWeb.Endpoint
      # Start a worker by calling: Tnetennba.Worker.start_link(arg)
      # {Tnetennba.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tnetennba.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TnetennbaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
