defmodule Elbuencoffi.Router do
  use Elbuencoffi.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Elbuencoffi do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", Elbuencoffi do
    pipe_through :api

    post "/players", PlayerController, :create

    post "/players/:id", PlayerController, :update_location
    get "/players/:id", PlayerController, :show

    post "/matches/:id", MatchController, :update

    get "/leaderboard", MatchController, :index

    post "/avatars", PlayerController, :generate_avatar

  end
end
