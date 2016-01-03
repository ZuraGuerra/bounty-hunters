defmodule Elbuencoffi.PageController do
  use Elbuencoffi.Web, :controller

  def index(conn, _params) do
  	Elbuencoffi.RandomAvatar.generate("bounty")
    render conn, "index.html"
  end
end
