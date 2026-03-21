defmodule BanyWeb.Router do
  use BanyWeb, :router

  import BanyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BanyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BanyWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Accessible without a plan (requires login)
    live_session :default,
      on_mount: [
        {BanyWeb.UserAuth, :ensure_authenticated},
        {BanyWeb.PlanContext, :default}
      ] do
      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Form, :new
      live "/categories/:id", CategoryLive.Show, :show
      live "/categories/:id/edit", CategoryLive.Form, :edit

      live "/transactions", TransactionLive.Index, :index
      live "/transactions/new", TransactionLive.Form, :new
      live "/transactions/:id", TransactionLive.Show, :show
      live "/transactions/:id/edit", TransactionLive.Form, :edit

      live "/plans", PlanLive.Index, :index
      live "/plans/new", PlanLive.Form, :new
      live "/plans/:id", PlanLive.Show, :show
      live "/plans/:id/edit", PlanLive.Form, :edit

      live "/admin", AdminLive, :admin
    end

    # Require a valid plan — redirect to /plans if missing/invalid (requires login)
    live_session :require_plan,
      on_mount: [
        {BanyWeb.UserAuth, :ensure_authenticated},
        {BanyWeb.PlanContext, :require_plan}
      ] do
      live "/accounts", AccountLive.Index, :index
      live "/accounts/new", AccountLive.Form, :new
      live "/accounts/:id", AccountLive.Show, :show
      live "/accounts/:id/edit", AccountLive.Form, :edit

      live "/plans/:plan_id/category_groups", CategoryGroupLive.Index, :index
      live "/plans/:plan_id/category_groups/new", CategoryGroupLive.Form, :new
      live "/plans/:plan_id/category_groups/:id", CategoryGroupLive.Show, :show
      live "/plans/:plan_id/category_groups/:id/edit", CategoryGroupLive.Form, :edit

      live "/plans/:plan_id/allocations", AllocationLive.Index, :index
      live "/plans/:plan_id/allocations/new", AllocationLive.Form, :new
      live "/plans/:plan_id/allocations/:id", AllocationLive.Show, :show
      live "/plans/:plan_id/allocations/:id/edit", AllocationLive.Form, :edit

      live "/plans/:plan_id/categories/with_totals/:year/:month", CategoryLive.IndexWithTotals, :index

      live "/plans/:plan_id/categories", CategoryLive.Index, :index
      live "/plans/:plan_id/categories/new", CategoryLive.Form, :new
      live "/plans/:plan_id/categories/:id", CategoryLive.Show, :show
      live "/plans/:plan_id/categories/:id/edit", CategoryLive.Form, :edit

      live "/plans/:plan_id/transactions", TransactionLive.Index, :index
      live "/plans/:plan_id/transactions/new", TransactionLive.Form, :new
      live "/plans/:plan_id/transactions/:id", TransactionLive.Show, :show
      live "/plans/:plan_id/transactions/:id/edit", TransactionLive.Form, :edit

      live "/plans/:plan_id/accounts", AccountLive.Index, :index
      live "/plans/:plan_id/accounts/new", AccountLive.Form, :new
      live "/plans/:plan_id/accounts/:id", AccountLive.Show, :show
      live "/plans/:plan_id/accounts/:id/edit", AccountLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BanyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bany, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BanyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BanyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", BanyWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", BanyWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
