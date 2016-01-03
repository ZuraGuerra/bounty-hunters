defmodule Elbuencoffi.PlayerControllerTest do
  use Elbuencoffi.ConnCase

  alias Neo4j.Sips, as: Neo4j
  alias Elbuencoffi.M2x
  alias M2X.Client
  alias M2X.Device

  @create_player_params %{
  	phone: "5515787289",
  	nickname: "lalala"
  }
  
  @update_location_params %{
  	latitude: 20.656714,
  	longitude: -103.3876229
  }


  setup do
    M2x.delete_all_devices!
  	clear_neo4j_db
  	:ok
  end

  test "POST /api/players" do
    conn = post conn(), "/api/players", @create_player_params
    assert json = json_response(conn, 200)
  end

  test "POST /api/players returns created user id" do
    conn = post conn(), "/api/players", @create_player_params
    assert json_response(conn, 200)["id"]
  end

  test "POST /api/players persists player in Neo4j" do
    conn = post conn(), "/api/players", @create_player_params
    id = json_response(conn, 200)["id"]
    assert neo4j! """
    MATCH (p:Player {id: "#{id}"}) RETURN p as ok
    """
  end

  test "POST /api/players persists device in M2X" do
    conn = post conn(), "/api/players", @create_player_params
    id = json_response(conn, 200)["id"]
    assert M2x.client |> Device.fetch(id)
  end

  test "POST /api/players/:id" do
  	player = create_player
  	conn = post conn(), "/api/players/#{player["id"]}", @update_location_params
    assert json_response(conn, 200)  	
  end


  test "GET /api/players/:id" do
  	player = create_player
  	conn = get conn(), "/api/players/#{player["id"]}"
  	json = json_response(conn, 200)
    assert json["id"]
    assert json["avatar_url"]
    assert json["money"]
    assert json["nickname"]
    assert json["phone"]
    assert json["pending_matches"]
  end

  test "POST /api/players/:id when a place is found, it adds money to player" do
    player = create_player
    place = create_place
    conn = post conn(), "/api/players/#{player["id"]}", @update_location_params
    assert 350 = neo4j! """
    MATCH (a:Player {id: "#{player["id"]}"})-[:Looths]->(b:Place)
    RETURN a.money as ok
    """
  end 

  defp clear_neo4j_db do
    cypher = "MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r"
    Neo4j.query!(Neo4j.conn, cypher)
  end

  defp neo4j!(cypher) do
    [%{"ok" => result}] = Neo4j.query!(Neo4j.conn, cypher)
    result
  end

  defp create_player(phone \\ "12345", nickname \\ "zura") do
    id = M2x.create_player_device(phone, nickname)
    neo4j! """
    CREATE (p:Player {
      id: "#{id}",
      nickname: "#{nickname}",
      avatar_url: "fb.com/myid/mypic.png",
      money: 100,
      phone: "#{phone}"
    })
    RETURN p as ok
    """
  end

  defp create_place(name \\ "palacio", location \\ @update_location_params) do
    %{latitude: latitude, longitude: longitude} = location
    id = M2x.create_place_device(name, latitude, longitude)
    place = neo4j! """
    CREATE (p:Place {
      id: "#{id}",
      name: "#{name}",
      avatar_url: "some/place.png",
      bounty: 250,
      latitude: #{latitude},
      longitude: #{longitude}
    })
    RETURN p as ok
    """
  end


end
