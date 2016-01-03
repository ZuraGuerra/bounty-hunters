defmodule Elbuencoffi.PlayerControllerTest do
  use Elbuencoffi.ConnCase
  alias Neo4j.Sips, as: Neo4j

  @create_player_params %{
  	phone: "5515787289",
  	nickname: "lalala"
  }
  
  @update_location_params %{
  	latitude: 20.656714,
  	longitude: -103.3876229
  }


  setup do
  	clear_neo4j_db
  	:ok
  end

  defp clear_neo4j_db do
  	cypher = "MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r"
  	Neo4j.query!(Neo4j.conn, cypher)
  end

  test "POST /api/players" do
    conn = post conn(), "/api/players", @create_player_params
    assert json = json_response(conn, 200)
  end

  test "POST /api/players returns created user id" do
    conn = post conn(), "/api/players", @create_player_params
    json = json_response(conn, 200)
    assert json["id"]
  end

  test "POST /api/players persists player in Neo4j" do
    conn = post conn(), "/api/players", @create_player_params
    json = json_response(conn, 200)
    id = json["id"]
    cypher = "MATCH (p:Player) WHERE id(p) = #{id} RETURN p"
    assert [player] = Neo4j.query!(Neo4j.conn, cypher)
  end

  test "POST /api/players/:id" do
  	player = create_player
  	conn = post conn(), "/api/players/#{player["id"]}", @update_location_params
    assert json_response(conn, 200)  	
  end

  defp create_player do
  	cypher = """
  	CREATE (p:Player {
  		nickname: "Zurafiki",
  		avatar_url: "fb.com/myid/mypic.png",
  		money: 100
  		})
  	RETURN id(p) as id, 
  	    p.nickname as nickname,
  	    p.avatar_url as avatar_url,
  	    p.money as money
  	"""
	[player]  = Neo4j.query!(Neo4j.conn, cypher)
	player
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

  test "GET /api/players/:id returns a pending match" do
  	player = create_player
  	challenger = create_player
    conn = get conn(), "/api/players/#{player["id"]}"
    cypher = """
    
    MATCH (p:Player), (c:Player)
    WHERE id(p) = "#{player["id"]}", id(c) = "#{challenger["id"]}"
    
    RETURN p, c
    """
    assert [player, match, challenger] = Neo4j.query!(Neo4j.conn, cypher)
  end

end
