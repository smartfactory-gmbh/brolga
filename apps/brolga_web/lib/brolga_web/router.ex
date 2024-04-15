defmodule BrolgaWeb.Router do
  use BrolgaWeb, :router

  import BrolgaWeb.UserAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BrolgaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", BrolgaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:brolga_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BrolgaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{BrolgaWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/admin/", BrolgaWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_dashboard "/_dashboard", metrics: BrolgaWeb.Telemetry

    live_session :require_authenticated_user,
      on_mount: [{BrolgaWeb.UserAuth, :ensure_authenticated}] do
      resources "/dashboards", DashboardController
      put "/dashboards/:id/set-default", DashboardController, :set_default
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/monitors", MonitorLive.Index, :index
      live "/monitors/new", MonitorLive.Index, :new
      live "/monitors/import", MonitorLive.Index, :import
      live "/monitors/:id/edit", MonitorLive.Index, :edit

      live "/monitors/:id", MonitorLive.Show, :show
      live "/monitors/:id/show/edit", MonitorLive.Show, :edit

      live "/monitor-results", MonitorResultLive, :index
      live "/monitor-results/:id", MonitorResultLive, :index

      live "/monitor-tags", MonitorTagLive.Index, :index
      live "/monitor-tags/new", MonitorTagLive.Index, :new
      live "/monitor-tags/:id/edit", MonitorTagLive.Index, :edit

      live "/monitor-tags/:id", MonitorTagLive.Show, :show
      live "/monitor-tags/:id/show/edit", MonitorTagLive.Show, :edit
    end
  end

  scope "/admin/", BrolgaWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/export", MonitorController, :export

    live_session :current_user,
      on_mount: [{BrolgaWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/", BrolgaWeb do
    pipe_through [:browser]

    live_session :public, root_layout: false do
      live "/", PublicMonitorLive
      live "/dashboard/:id", PublicMonitorLive
    end
  end
end
