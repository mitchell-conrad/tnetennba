defmodule TnetennbaWeb.Router do
  use TnetennbaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TnetennbaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_session_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TnetennbaWeb do
    pipe_through :browser

    live "/", MainLive
  end

  defp assign_session_id(conn, _) do
    if get_session(conn, :session_id) do
      # If the session_id is already set, don't replace it.
      conn
    else
      session_id = UUID.uuid1()
      conn |> put_session(:session_id, session_id)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TnetennbaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:tnetennba, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TnetennbaWeb.Telemetry
    end
  end
end
