defmodule Elbuencoffi.PlayerController do
  use Elbuencoffi.Web, :controller
  alias Neo4j.Sips, as: Neo4j

  def create(conn, params) do
  	cypher = """
  	CREATE (p:Player {
  		phone: "#{params[:phone]}", 
  		nickname: "#{params[:nickname]}", 
  		money: 100
  	    })
    RETURN true
  	"""
  	[true] = Neo4j.query!(Neo4j.conn, cypher)
  	json(conn, %{success: true})
  end

  def update_location(conn, params) do
  	latitude = params["latitude"]
  	longitude = params["longitude"]
  	id = params["id"]
  	cypher = """
  	MATCH (p:Player) WHERE id(p) = #{id}
  	SET p.latitude = #{latitude}, p.longitude = #{longitude}
  	RETURN p
  	"""
  	[player] = Neo4j.query!(Neo4j.conn, cypher)
  	json(conn, %{})
  end

  def show(conn, params) do
  	id = params["id"]
  	cypher = """
  	MATCH (p:Player) WHERE id(p) = #{id}
  	RETURN p
  	"""
  	[player] = Neo4j.query!(Neo4j.conn, cypher)
  	json(conn, %{
  		nickname: player["nickname"],
  		avatar_url: player["avatar_url"],
  		money: player["money"],
  		pending_matches: []
  		})
  end
end
