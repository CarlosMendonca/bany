defmodule BanyWeb.Router do
  use BanyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BanyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BanyWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/categories/with_totals/:year/:month", CategoryLive.IndexWithTotals, :index
    live "/categories", CategoryLive.Index, :index
    live "/categories/new", CategoryLive.Form, :new
    live "/categories/:id", CategoryLive.Show, :show
    live "/categories/:id/edit", CategoryLive.Form, :edit

    live "/transactions", TransactionLive.Index, :index
    live "/transactions/new", TransactionLive.Form, :new
    live "/transactions/:id", TransactionLive.Show, :show
    live "/transactions/:id/edit", TransactionLive.Form, :edit

    live "/accounts", AccountLive.Index, :index
    live "/accounts/new", AccountLive.Form, :new
    live "/accounts/:id", AccountLive.Show, :show
    live "/accounts/:id/edit", AccountLive.Form, :edit

    live "/plans", PlanLive.Index, :index
    live "/plans/new", PlanLive.Form, :new
    live "/plans/:id", PlanLive.Show, :show
    live "/plans/:id/edit", PlanLive.Form, :edit

    live "/category_groups", CategoryGroupLive.Index, :index
    live "/category_groups/new", CategoryGroupLive.Form, :new
    live "/category_groups/:id", CategoryGroupLive.Show, :show
    live "/category_groups/:id/edit", CategoryGroupLive.Form, :edit

    live "/allocations", AllocationLive.Index, :index
    live "/allocations/new", AllocationLive.Form, :new
    live "/allocations/:id", AllocationLive.Show, :show
    live "/allocations/:id/edit", AllocationLive.Form, :edit

    live "/admin", AdminLive, :admin
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
end
