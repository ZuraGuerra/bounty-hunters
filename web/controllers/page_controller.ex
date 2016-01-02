defmodule Elbuencoffi.PageController do
  use Elbuencoffi.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
