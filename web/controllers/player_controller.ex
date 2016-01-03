defmodule Elbuencoffi.PlayerController do
  use Elbuencoffi.Web, :controller
  alias Neo4j.Sips, as: Neo4j
  alias Elbuencoffi.M2x

  defp neo4j!(cypher) do
    [%{"ok" => ok}] = Neo4j.query!(Neo4j.conn, cypher)
    ok
  end

  def create(conn, %{"phone" => phone, "nickname" => nickname}) do
    device_id = M2x.create_player_device(phone, nickname)
  	player = neo4j! """
  	CREATE (p:Player {
      id: "#{device_id}",
  		phone: "#{phone}", 
  		nickname: "#{nickname}", 
  		money: 100
    })
    RETURN p as ok
  	"""
  	json(conn, player)
  end

  def update_location(conn, %{"id" => id, "latitude" => latitude, "longitude" => longitude}) do
  	player = neo4j! """
  	MATCH (p:Player {id: "#{id}"})
  	SET p.latitude = #{latitude}, p.longitude = #{longitude}
  	RETURN p as ok
  	"""
  	json(conn, player)
  end

  def show(conn, %{"id" => id}) do
  	player = neo4j! """
  	MATCH (p:Player {id: "#{id}"})
  	RETURN p as ok
  	"""
  	json(conn, player)
  end
end
