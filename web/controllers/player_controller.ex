defmodule Elbuencoffi.PlayerController do
  use Elbuencoffi.Web, :controller
  alias Neo4j.Sips, as: Neo4j

  defp neo4j!(cypher) do
    [%{"ok" => ok}] = Neo4j.query!(Neo4j.conn, cypher)
    ok
  end

  def create(conn, %{"phone" => phone, "nickname" => nickname}) do
  	player = neo4j! """
  	CREATE (p:Player {
  		phone: "#{phone}", 
  		nickname: "#{nickname}", 
  		money: 100
    })
    RETURN p as ok
  	"""
  	json(conn, player)
  end

  def update_location(conn, %{"phone" => phone, "latitude" => latitude, "longitude" => longitude}) do
  	player = neo4j! """
  	MATCH (p:Player {phone: "#{phone}"})
  	SET p.latitude = #{latitude}, p.longitude = #{longitude}
  	RETURN p as ok
  	"""
  	json(conn, player)
  end

  def show(conn, %{"phone" => phone}) do
  	player = neo4j! """
  	MATCH (p:Player {phone: "#{phone}"})
  	RETURN p as ok
  	"""
  	json(conn, player)
  end
end
