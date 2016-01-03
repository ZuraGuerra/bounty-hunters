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

  defp clear_neo4j_db do
  	cypher = "MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r"
  	Neo4j.query!(Neo4j.conn, cypher)
  end

  defp neo4j!(cypher) do
    [%{"ok" => result}] = Neo4j.query!(Neo4j.conn, cypher)
    result
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

  test "POST /api/players/:phone" do
  	player = create_player
  	conn = post conn(), "/api/players/#{player["id"]}", @update_location_params
    assert json_response(conn, 200)  	
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

  test "GET /api/players/:id" do
  	player = create_player
  	conn = get conn(), "/api/players/#{player["id"]}"
  	json = json_response(conn, 200)
  	assert json = %{
  		nickname: player["nickname"],
  		avatar_url: player["avatar_url"],
  		money: player["money"],
  		pending_matches: []
  	}
  end


end
