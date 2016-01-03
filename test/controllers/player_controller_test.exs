defmodule Elbuencoffi.PlayerControllerTest do
  use Elbuencoffi.ConnCase
  alias Neo4j.Sips, as: Neo4j

  @player_params %{
  	phone: "5515787289",
  	nickname: "lalala"
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
    conn = post conn(), "/api/players", @player_params
    assert json = json_response(conn, 200)
  end

  test "POST /api/players returns created user id" do
    conn = post conn(), "/api/players", @player_params
    json = json_response(conn, 200)
    assert json["id"]
  end

  test "POST /api/players persists player in Neo4j" do
    conn = post conn(), "/api/players", @player_params
    json = json_response(conn, 200)
    id = json["id"]
    cypher = "MATCH (p:Player) WHERE id(p) = #{id} RETURN p"
    assert [player] = Neo4j.query!(Neo4j.conn, cypher)
  end
end
