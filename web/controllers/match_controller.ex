defmodule Elbuencoffi.MatchController do
  use Elbuencoffi.Web, :controller

  alias Neo4j.Sips, as: Neo4j

  def update(conn, %{"id" => match_id, "score" => score, "user_id" => user_id}) do
    neo4j! """
    MATCH (a:Player {id: "#{user_id}"})-[m:Match {id: "#{match_id}"}]->(b:Player)
    SET m.score_a = #{score}
    RETURN a.id as ok

    UNION

    MATCH (b:Player {id: "#{user_id}"})<-[m:Match {id: "#{match_id}"}]-(a:Player)
    SET m.score_b = #{score}
    RETURN b.id as ok
    """

    winner = neo4j! """
    MATCH (a:Player)-[m:Match {id: "#{match_id}"}]->(b:Player)
    WHERE m.score_a >= m.score_b
    CREATE UNIQUE (a)-[w:Beats {bounty: (b.money * 0.1)}]->(b)
    SET b.money = b.money - w.bounty
    SET a.money = a.money + w.bounty
    RETURN a.id as ok LIMIT 1

    UNION

    MATCH (a:Player)-[m:Match {id: "#{match_id}"}]->(b:Player)
    WHERE m.score_a < m.score_b
    CREATE UNIQUE (a)<-[w:Beats {bounty: (a.money * 0.1)}]-(b)
    SET a.money = a.money - w.bounty
    SET b.money = b.money + w.bounty    
    RETURN b.id as ok LIMIT 1

    UNION

    MATCH (a:Player)-[m:Match {id: "#{match_id}"}]-(b:Player)
    WHERE NOT(has(m.score_a)) OR NOT(has(m.score_b))
    RETURN "pending" as ok LIMIT 1
    """

    cond do
     winner == "pending" ->
      result = "pending"
     winner == user_id ->
      result = "wins"
     :else ->
      result = "loses"
    end

    json conn, %{result: result}
  end

  defp neo4j!(cypher) do
    [%{"ok" => ok}] = Neo4j.query!(Neo4j.conn, cypher)
    ok
  end

  defp neo4j_ok(cypher) do
    Neo4j.query!(Neo4j.conn, cypher)
    |> case do
      [%{"ok" => ok}] -> ok 
      _ -> nil
    end
  end

end
