defmodule BanyWeb.PageController do
  use BanyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
